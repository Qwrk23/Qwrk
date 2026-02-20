# Gateway Internal Normalization — Implementation Plan v1

**Date**: 2026-01-05
**Status**: ACTIVE (Governance-Aligned)
**Governing Authority**: Snapshot `AAA_New_Qwrk__Snapshot__Gateway_Internal_Canonical_Lock__2026-01-05__v1`
**Gateway Contract**: v1.0 (IMMUTABLE for this implementation)

---

## Executive Summary

**Goal**: Make Gateway the **single normalization layer** while preserving Gateway Contract v1.0 as the immutable public interface.

**Core Principle:**
> Gateway owns input chaos. Downstream workflows assume order.

**Governance Lock:**
- External contract remains flat, n8n-friendly (`gw_*` fields)
- Internal canonical normalization approved (not exposed publicly)
- Single write action: `gw_action = artifact.save` (handles create + update)
- Downstream workflows trust Gateway completely (zero internal normalization)

---

## Governing Snapshot (Authority)

**Snapshot ID**: `AAA_New_Qwrk__Snapshot__Gateway_Internal_Canonical_Lock__2026-01-05__v1`

**Decisions Locked:**
1. ✅ Gateway = single normalization layer
2. ✅ External Gateway Contract v1.0 preserved (flat `gw_*` envelope)
3. ✅ Single write action: `gw_action = artifact.save` (create + update)
4. ✅ Internal canonical allowed (not exposed as public contract)
5. ✅ Kernel v1 types: project, journal, snapshot, restart (NO video)
6. ✅ Downstream workflows simplified (trust Gateway, no normalization)

**Conflicts Explicitly Rejected:**
- ❌ `request_type` field (use `gw_action` instead)
- ❌ Nested public `artifact: {}` envelope
- ❌ Separate `update` action/workflow
- ❌ Adding `video` to Kernel v1 type allow-list

---

## Gateway Contract v1.0 (Immutable)

### Public Request Envelope (Locked)

```javascript
{
  // === ROUTING ===
  gw_action: "artifact.save" | "artifact.query" | "artifact.list",

  // === IDENTITY & AUTHORIZATION ===
  gw_workspace_id: "uuid",  // REQUIRED
  gw_user_id: "uuid",  // REQUIRED (or owner_user_id - both accepted)

  // === ARTIFACT ROUTING ===
  artifact_type: "project" | "journal" | "restart" | "snapshot",
  artifact_id: "uuid",  // REQUIRED for query; optional for save (presence = update)

  // === PAYLOAD ===
  artifact_payload: {
    // Spine fields
    title: "string",
    summary: "string",
    tags: ["array"],
    lifecycle_status: "active" | "archived",

    // Extension fields (type-specific JSONB)
    // project: lifecycle_stage, operational_state
    // journal: content, moment_timestamp
    // restart: payload
    // snapshot: payload
  },

  // === LIST SPECIFIC ===
  selector: {
    limit: 50,
    offset: 0,
    sort_by: "created_at",
    sort_order: "desc",
    filters: {}
  }
}
```

**Contract Rules (Locked):**
- **artifact.save**: CREATE if no `artifact_id`; UPDATE if `artifact_id` present
- **artifact.query**: Requires `artifact_type` + `artifact_id`
- **artifact.list**: Requires `artifact_type` + optional `selector`
- **Type allow-list**: `["project", "journal", "restart", "snapshot"]`
- **Action allow-list**: `["artifact.save", "artifact.query", "artifact.list"]`

---

## Current State (Problems to Fix)

### Gateway Issues
1. **Normalize_Request node is incomplete** - Only extracts routing fields, not full payload
2. **"merge stuff" band-aid** - Partial normalization before Save, still causes missing fields
3. **No source tracking** - Can't distinguish webhook vs CustomGPT vs internal calls
4. **Inconsistent payload extraction** - Sometimes `body.artifact_payload`, sometimes flat

### Downstream Issues
1. **Save workflow guesses payload shape** - Has internal normalization logic
2. **Query workflow re-normalizes** - Redundant with Gateway
3. **List workflow re-normalizes** - Redundant with Gateway
4. **Missing fields happen silently** - No single source of truth for "what fields are present"

### Result
- Fields disappear between Gateway and Save
- CustomGPT integration will compound the problem
- Testing is unreliable (works in GUI, fails via webhook)

---

## Solution: Internal Canonical Normalization

### What Changes

**Gateway:**
- Add single normalization node: `Gateway__Normalize_To_Internal_Canonical_v1`
- Remove "merge stuff" band-aid
- Produce stable internal shape for all downstream workflows

**Downstream Workflows:**
- Remove all internal normalization logic
- Trust Gateway output completely
- Focus exclusively on DB operations

### What Stays the Same

**Gateway Contract v1.0:**
- Public envelope unchanged (flat `gw_*` fields)
- Action semantics unchanged (`artifact.save` = create or update)
- Type allow-list unchanged
- Response envelope unchanged

**Downstream Logic:**
- DB insert/update/query patterns unchanged
- Hydration logic unchanged
- Error handling unchanged

---

## Internal Canonical Shape (Gateway Output)

**Purpose**: Single stable shape consumed by all downstream workflows

**Structure:**
```javascript
{
  // === CONTRACT METADATA (internal only) ===
  _canonical_version: 1,  // Internal versioning
  _source: "webhook" | "customgpt" | "internal",  // Request origin
  _received_at: "2026-01-05T12:00:00Z",  // Gateway timestamp

  // === PUBLIC CONTRACT FIELDS (preserved exactly) ===
  gw_action: "artifact.save" | "artifact.query" | "artifact.list",
  gw_workspace_id: "uuid",
  gw_user_id: "uuid",
  artifact_type: "project" | "journal" | "restart" | "snapshot",
  artifact_id: "uuid" | null,  // null for create; uuid for update/query

  // === NORMALIZED PAYLOAD (guaranteed shape) ===
  payload: {
    // Spine fields (guaranteed present or null)
    title: "string" | null,
    summary: "string" | null,
    tags: ["array"],  // always array, defaults to []
    lifecycle_status: "active" | "archived",  // defaults to "active"

    // Extension fields (type-specific, guaranteed present or {})
    extension: {
      // project: lifecycle_stage, operational_state
      // journal: content, moment_timestamp
      // restart: payload
      // snapshot: payload
    }
  },

  // === LIST SPECIFIC (guaranteed shape) ===
  selector: {
    limit: 50,  // INT, validated 1-100
    offset: 0,  // INT, validated >=0
    sort_by: "created_at",  // defaults
    sort_order: "desc",  // defaults
    filters: {}  // JSONB, defaults to {}
  },

  // === DEBUG METADATA (internal only) ===
  _debug: {
    raw_headers: {},
    unmapped_fields: {},  // Capture unknown fields for discovery
    validation_passed: true
  }
}
```

**Key Guarantees:**
- `payload.tags` is ALWAYS an array (never undefined)
- `payload.lifecycle_status` is ALWAYS a string (never undefined)
- `payload.extension` is ALWAYS an object (never undefined)
- `selector.limit` is ALWAYS validated (1-100)
- `artifact_id` is explicitly null for creates (not undefined)

---

## Implementation Plan

### Phase 1: Gateway Normalization (Session 1)

#### Step 1A: Create Normalization Node

**New Node**: `Gateway__Normalize_To_Internal_Canonical_v1`

**Location**: Replace `NQxb_Gateway_v1__Normalize_Request`

**Logic**:
```javascript
// Gateway__Normalize_To_Internal_Canonical_v1
// Accept ANY inbound format, produce stable internal canonical shape
// PUBLIC CONTRACT: Gateway Contract v1.0 (flat gw_* fields)
// INTERNAL OUTPUT: Canonical shape with guaranteed field presence

const raw = $json ?? {};
const body = raw.body?.constructor === Object ? raw.body : null;
const req = body ?? raw;

// Detect source
const userAgent = raw.headers?.['user-agent'] ?? '';
const source = req._source ?? (userAgent.includes('CustomGPT') ? 'customgpt' : 'webhook');

// Extract public contract fields (Gateway Contract v1.0)
const gw_action = req.gw_action ?? null;
const gw_workspace_id = req.gw_workspace_id ?? req.workspace_id ?? null;
const gw_user_id = req.gw_user_id ?? req.owner_user_id ?? null;
const artifact_type = req.artifact_type ?? null;
const artifact_id = req.artifact_id ?? null;

// Extract artifact_payload (may be nested or flat)
const artifact_payload = req.artifact_payload ?? req.payload ?? {};

// Normalize payload to guaranteed shape
const payload = {
  title: artifact_payload.title ?? req.title ?? null,
  summary: artifact_payload.summary ?? req.summary ?? null,
  tags: Array.isArray(artifact_payload.tags) ? artifact_payload.tags
        : Array.isArray(req.tags) ? req.tags
        : [],
  lifecycle_status: artifact_payload.lifecycle_status ?? req.lifecycle_status ?? "active",
  extension: artifact_payload.extension ?? req.extension ?? {}
};

// Normalize selector (for list operations)
const rawSelector = req.selector ?? {};
const selector = {
  limit: Math.min(Math.max(parseInt(rawSelector.limit) || 50, 1), 100),
  offset: Math.max(parseInt(rawSelector.offset) || 0, 0),
  sort_by: rawSelector.sort_by ?? "created_at",
  sort_order: rawSelector.sort_order ?? "desc",
  filters: rawSelector.filters ?? {}
};

// Build canonical internal shape
const canonical = {
  // Internal metadata
  _canonical_version: 1,
  _source: source,
  _received_at: new Date().toISOString(),

  // Public contract fields (preserved exactly)
  gw_action,
  gw_workspace_id,
  gw_user_id,
  artifact_type,
  artifact_id,

  // Normalized payload (guaranteed shape)
  payload,

  // Normalized selector (guaranteed shape)
  selector,

  // Debug metadata
  _debug: {
    raw_headers: {
      authorization: !!raw.headers?.authorization,
      user_agent: userAgent || null
    },
    unmapped_fields: {},  // TODO: capture unknown fields if needed
    validation_passed: false  // Will be set by Gatekeeper
  }
};

return [{ json: canonical }];
```

#### Step 1B: Update Gatekeeper Node

**Node**: `Gateway__Gatekeeper_MVP_OwnerOnly`

**Changes**:
1. Validate canonical shape (not raw request)
2. Set `_debug.validation_passed = true` on success
3. Keep existing validation logic (workspace lock, action/type allow-lists)

**Updated Validation**:
```javascript
// Gateway__Gatekeeper_MVP_OwnerOnly
// Validate canonical internal shape
// Preserve Gateway Contract v1.0 semantics

const OWNER_WORKSPACE_ID = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a";
const ACTION_ALLOWLIST = new Set(["artifact.query", "artifact.list", "artifact.save"]);
const TYPE_ALLOWLIST = new Set(["project", "journal", "restart", "snapshot"]);

function fail(code, message, details = {}) {
  return [{
    json: {
      ok: false,
      error: { code, message, details },
      _gw_route: "error",
      // Preserve canonical for debugging
      ...$json,
      _debug: {
        ...($json?._debug ?? {}),
        validation_passed: false
      }
    }
  }];
}

// Canonical shape should already exist
const gw_action = $json?.gw_action;
const gw_workspace_id = $json?.gw_workspace_id;
const gw_user_id = $json?.gw_user_id;
const artifact_type = $json?.artifact_type;
const artifact_id = $json?.artifact_id;
const payload = $json?.payload ?? {};

// Required fields
if (!gw_action || typeof gw_action !== "string") {
  return fail("VALIDATION_ERROR", "Missing or invalid gw_action", {
    expected: "string",
    got: typeof gw_action
  });
}
if (!gw_workspace_id || typeof gw_workspace_id !== "string") {
  return fail("VALIDATION_ERROR", "Missing or invalid gw_workspace_id", {
    expected: "uuid string",
    got: typeof gw_workspace_id
  });
}

// Allow-lists
if (!ACTION_ALLOWLIST.has(gw_action)) {
  return fail("ACTION_NOT_ALLOWED", "gw_action not allowed", {
    gw_action,
    allowed: Array.from(ACTION_ALLOWLIST)
  });
}

// MVP workspace lock
if (gw_workspace_id !== OWNER_WORKSPACE_ID) {
  return fail("WORKSPACE_FORBIDDEN", "Workspace not permitted in MVP owner-only mode", {
    gw_workspace_id,
    allowed_workspace_id: OWNER_WORKSPACE_ID
  });
}

// Action-specific validation
if (gw_action === "artifact.query") {
  if (!artifact_type || typeof artifact_type !== "string") {
    return fail("VALIDATION_ERROR", "Missing or invalid artifact_type for artifact.query");
  }
  if (!TYPE_ALLOWLIST.has(artifact_type)) {
    return fail("ARTIFACT_TYPE_NOT_ALLOWED", "artifact_type not allowed", {
      artifact_type,
      allowed: Array.from(TYPE_ALLOWLIST)
    });
  }
  if (!artifact_id || typeof artifact_id !== "string") {
    return fail("VALIDATION_ERROR", "Missing or invalid artifact_id for artifact.query");
  }
}

if (gw_action === "artifact.list") {
  if (!artifact_type || typeof artifact_type !== "string") {
    return fail("VALIDATION_ERROR", "Missing or invalid artifact_type for artifact.list");
  }
  if (!TYPE_ALLOWLIST.has(artifact_type)) {
    return fail("ARTIFACT_TYPE_NOT_ALLOWED", "artifact_type not allowed", {
      artifact_type,
      allowed: Array.from(TYPE_ALLOWLIST)
    });
  }
}

if (gw_action === "artifact.save") {
  if (!artifact_type || typeof artifact_type !== "string") {
    return fail("VALIDATION_ERROR", "Missing or invalid artifact_type for artifact.save");
  }
  if (!TYPE_ALLOWLIST.has(artifact_type)) {
    return fail("ARTIFACT_TYPE_NOT_ALLOWED", "artifact_type not allowed", {
      artifact_type,
      allowed: Array.from(TYPE_ALLOWLIST)
    });
  }
  if (!payload.title || typeof payload.title !== "string") {
    return fail("VALIDATION_ERROR", "Missing or invalid title for artifact.save", {
      expected: "string",
      got: typeof payload.title
    });
  }
  // Note: artifact_id optional for save (null = create; uuid = update)
}

// Pass validation
return [{
  json: {
    ...$json,
    ok: true,
    _gw_route: "ok",
    _debug: {
      ...($json._debug ?? {}),
      validation_passed: true
    }
  }
}];
```

#### Step 1C: Remove "merge stuff" Band-Aid

**Action**: Delete the `merge stuff` node from Gateway workflow

**Reason**: Normalization now happens in single node; band-aid no longer needed

**Wiring Change**:
- **Before**: Switch_Action → merge stuff → Call Save
- **After**: Switch_Action → Call Save (direct)

#### Step 1D: Update Switch_Action Node

**Node**: `NQxb_Gateway_v1__Switch_Action`

**No logic changes needed** - Switch still routes on `gw_action`:
- `artifact.query` → output 0
- `artifact.list` → output 1
- `artifact.save` → output 2

**Wiring**:
- Output 0 → Call 'NQxb_Artifact_Query_v1'
- Output 1 → Call 'NQxb_Artifact_List_v1'
- Output 2 → Call 'NQxb_Artifact_Save_v1' (direct, no merge stuff)

#### Step 1E: Test Gateway Normalization

**Test with pinned data:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "gw_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "project",
  "artifact_payload": {
    "title": "Test Project",
    "summary": "Testing internal canonical normalization",
    "tags": ["test", "canonical"],
    "extension": {
      "lifecycle_stage": "seed",
      "operational_state": {}
    }
  }
}
```

**Expected canonical output after Normalize node:**
```javascript
{
  _canonical_version: 1,
  _source: "webhook",
  _received_at: "2026-01-05T...",
  gw_action: "artifact.save",
  gw_workspace_id: "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  gw_user_id: "c52c7a57-74ad-433d-a07c-4dcac1778672",
  artifact_type: "project",
  artifact_id: null,
  payload: {
    title: "Test Project",
    summary: "Testing internal canonical normalization",
    tags: ["test", "canonical"],
    lifecycle_status: "active",
    extension: {
      lifecycle_stage: "seed",
      operational_state: {}
    }
  },
  selector: { limit: 50, offset: 0, sort_by: "created_at", sort_order: "desc", filters: {} },
  _debug: { ... }
}
```

---

### Phase 2: Downstream Workflow Simplification (Session 2)

#### Step 2A: Update NQxb_Artifact_Save_v1

**Current State**: Has internal normalization logic guessing payload shape

**New State**: Trusts Gateway canonical completely

**Changes:**

1. **Add first node after trigger**: `Extract_Canonical_Payload`
   ```javascript
   // Extract_Canonical_Payload
   // Trust Gateway canonical normalization completely
   // No guessing, no fallbacks, no re-normalization

   const canonical = $json;
   const payload = canonical.payload ?? {};

   // Extract for DB operations
   return [{
     json: {
       // Identity
       workspace_id: canonical.gw_workspace_id,
       owner_user_id: canonical.gw_user_id,
       artifact_type: canonical.artifact_type,
       artifact_id: canonical.artifact_id,  // null = create; uuid = update

       // Spine fields (guaranteed present)
       title: payload.title,
       summary: payload.summary,
       tags: payload.tags,
       lifecycle_status: payload.lifecycle_status,

       // Extension (type-specific)
       extension: payload.extension,

       // Metadata
       _source: canonical._source
     }
   }];
   ```

2. **Remove all normalization nodes**:
   - Delete any nodes that extract/flatten/guess payload shape
   - Delete any nodes with fallback logic (`req.title ?? body.title ?? ...`)

3. **Simplify validation**:
   - Gateway already validated; Save only checks DB constraints
   - Example: "Does artifact_id exist for update?"

4. **Update decision logic**:
   - **CREATE path**: `artifact_id === null`
   - **UPDATE path**: `artifact_id !== null`
   - Use Switch node based on `artifact_id` presence

**New Save Workflow Structure**:
```
1. Execute Workflow Trigger
2. Extract_Canonical_Payload (trust Gateway)
3. Switch: CREATE or UPDATE?
   ├─ CREATE (artifact_id === null)
   │  ├─ Insert_Spine (qxb_artifact)
   │  ├─ Insert_Extension (qxb_artifact_{type})
   │  └─ Fetch_Hydrated
   └─ UPDATE (artifact_id !== null)
      ├─ Validate_Exists (query spine by artifact_id + workspace_id)
      ├─ Update_Spine (UPDATE qxb_artifact SET ...)
      ├─ Update_Extension (UPDATE qxb_artifact_{type} ...)
      └─ Fetch_Hydrated
4. Return artifact
```

#### Step 2B: Update NQxb_Artifact_Query_v1

**Changes:**

1. **Add first node**: `Extract_Canonical_Query`
   ```javascript
   // Extract_Canonical_Query
   const canonical = $json;

   return [{
     json: {
       workspace_id: canonical.gw_workspace_id,
       artifact_type: canonical.artifact_type,
       artifact_id: canonical.artifact_id
     }
   }];
   ```

2. **Remove internal normalization logic**

3. **Rest of workflow unchanged** (DB query patterns stay same)

#### Step 2C: Update NQxb_Artifact_List_v1

**Changes:**

1. **Add first node**: `Extract_Canonical_List`
   ```javascript
   // Extract_Canonical_List
   const canonical = $json;
   const selector = canonical.selector;

   return [{
     json: {
       workspace_id: canonical.gw_workspace_id,
       artifact_type: canonical.artifact_type,
       limit: selector.limit,
       offset: selector.offset,
       sort_by: selector.sort_by,
       sort_order: selector.sort_order,
       filters: selector.filters
     }
   }];
   ```

2. **Remove internal normalization logic**

3. **Rest of workflow unchanged**

---

### Phase 3: Testing & Validation (Session 3)

#### Test Matrix

| Operation | Source     | Test Case                        | Expected Result         |
|-----------|------------|----------------------------------|-------------------------|
| save      | webhook    | No artifact_id → CREATE          | INSERT success          |
| save      | webhook    | With artifact_id → UPDATE        | UPDATE success          |
| save      | customgpt  | Tool call → CREATE               | INSERT success          |
| query     | webhook    | artifact_id → Query              | Artifact returned       |
| list      | webhook    | selector → List                  | Array + pagination      |
| save      | webhook    | Missing title → Gatekeeper       | 403 VALIDATION_ERROR    |
| save      | webhook    | Unknown artifact_type            | 403 TYPE_NOT_ALLOWED    |

#### KG Proofs Required

**After implementation:**
1. ✅ artifact.save (CREATE) via Gateway → DB
2. ✅ artifact.save (UPDATE) via Gateway → DB
3. ✅ artifact.query via Gateway
4. ✅ artifact.list via Gateway

**Success Criteria:**
- Zero missing fields in DB
- Identical behavior across webhook and CustomGPT sources
- No downstream normalization logic remains
- All tests pass without payload debugging

---

### Phase 4: CustomGPT Integration (Session 4)

#### OpenAPI Action Schema (Gateway Contract v1.0)

**Example: artifact.save**
```yaml
paths:
  /nqxb/gateway/v1:
    post:
      operationId: qwrk_save_artifact
      summary: Save a new artifact or update an existing one
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - gw_action
                - gw_workspace_id
                - gw_user_id
                - artifact_type
                - artifact_payload
              properties:
                gw_action:
                  type: string
                  enum: [artifact.save]
                gw_workspace_id:
                  type: string
                  format: uuid
                gw_user_id:
                  type: string
                  format: uuid
                artifact_type:
                  type: string
                  enum: [project, journal, restart, snapshot]
                artifact_id:
                  type: string
                  format: uuid
                  description: "Optional. If provided, updates existing artifact. If omitted, creates new artifact."
                artifact_payload:
                  type: object
                  required: [title]
                  properties:
                    title:
                      type: string
                      maxLength: 500
                    summary:
                      type: string
                    tags:
                      type: array
                      items:
                        type: string
                    lifecycle_status:
                      type: string
                      enum: [active, archived]
                    extension:
                      type: object
                      description: "Type-specific extension fields"
```

**Benefits:**
- CustomGPT tool calls match Gateway Contract v1.0 exactly
- Gateway normalization handles both webhook and tool call formats
- No translation layer needed

---

## Implementation Order (Recommended)

### Session 1: Gateway Normalization ⏱️ 45-60 minutes
1. Create `Gateway__Normalize_To_Internal_Canonical_v1` node
2. Update `Gateway__Gatekeeper_MVP_OwnerOnly` validation
3. Remove "merge stuff" node
4. Update wiring (Switch_Action → Save direct)
5. Test with pinned data (verify canonical shape)

### Session 2: Update Save Workflow ⏱️ 60-90 minutes
1. Add `Extract_Canonical_Payload` node
2. Remove all internal normalization nodes
3. Add Switch: CREATE vs UPDATE logic
4. Update CREATE path (spine + extension inserts)
5. Add UPDATE path (spine + extension updates)
6. Test: Gateway → Save (both CREATE and UPDATE)
7. Verify: All fields present in DB

### Session 3: Update Query & List Workflows ⏱️ 30-45 minutes
1. Add `Extract_Canonical_Query` to Query_v1
2. Add `Extract_Canonical_List` to List_v1
3. Remove internal normalization from both
4. Test: All operations end-to-end
5. Create KG proofs for all operations

### Session 4: CustomGPT Integration ⏱️ 60-90 minutes
1. Define OpenAPI action schemas (save, query, list)
2. Configure CustomGPT with Gateway endpoint
3. Test tool calls → Gateway → Workflows
4. Verify identical behavior (webhook vs CustomGPT)
5. **Qwrk Lives!** 🎉

---

## Key Benefits

1. **Single Source of Truth**: Gateway normalizes once; downstream trusts completely
2. **No Missing Fields**: Internal canonical guarantees field presence (tags always array, etc.)
3. **Simpler Downstream**: Save/Query/List become pure DB operations
4. **Clean CustomGPT**: Action schemas match public contract exactly
5. **Contract Stability**: External Gateway Contract v1.0 unchanged (no breaking changes)
6. **Source Tracking**: `_source` field distinguishes webhook vs CustomGPT vs internal
7. **Debuggable**: `_debug` metadata captures validation state and unmapped fields

---

## Risks & Mitigations

### Risk: Breaking existing webhook integrations
**Mitigation**: Gateway normalization is backward-compatible
- Accepts both `gw_user_id` and `owner_user_id`
- Accepts both nested `artifact_payload` and flat fields
- Public contract unchanged

### Risk: Downstream workflows break if canonical shape changes
**Mitigation**: Version the canonical shape (`_canonical_version: 1`)
- Future changes increment version
- Downstream can detect and handle version transitions

### Risk: CustomGPT sends unexpected formats
**Mitigation**: `_debug.unmapped_fields` captures unknown fields
- Learn what CustomGPT sends without breaking
- Iterate canonical normalization if needed

---

## Success Criteria

✅ Gateway produces identical canonical shape for same logical request (webhook vs CustomGPT)
✅ Save workflow receives all fields, zero missing data
✅ Save workflow handles both CREATE (no artifact_id) and UPDATE (with artifact_id)
✅ Query & List unchanged functionally (just simpler code)
✅ CustomGPT tool calls work first try (no payload debugging)
✅ KG proofs pass for all operations (save, query, list)
✅ No downstream normalization logic remains

---

## Appendix A: Gateway Contract v1.0 Semantics (Locked)

### artifact.save Semantics

**CREATE (artifact_id absent or null):**
- Insert new record into `qxb_artifact` (spine)
- Insert new record into `qxb_artifact_{type}` (extension)
- Return hydrated artifact with generated `artifact_id`

**UPDATE (artifact_id present):**
- Validate artifact exists in `qxb_artifact` by `workspace_id` + `artifact_id`
- Update `qxb_artifact` SET title, summary, tags, updated_at = NOW()
- Update `qxb_artifact_{type}` extension fields
- Return hydrated artifact

**No separate `artifact.update` action** - Single `artifact.save` handles both.

---

## Appendix B: Type-Specific Extension Schemas (Kernel v1)

### project
```javascript
extension: {
  lifecycle_stage: "seed" | "sapling" | "tree",
  operational_state: {}  // JSONB
}
```

### journal
```javascript
extension: {
  content: {},  // JSONB rich content
  moment_timestamp: "2026-01-05T12:00:00Z"
}
```

### restart
```javascript
extension: {
  payload: {}  // JSONB restart state
}
```

### snapshot
```javascript
extension: {
  payload: {}  // JSONB snapshot data
}
```

**Note**: Extension validation is type-specific and handled by Save workflow, not Gateway.

---

## Appendix C: Migration Notes (Backward Compatibility)

### Accepting Legacy Formats

Gateway normalization handles multiple input formats:

**Flat format (legacy):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "...",
  "owner_user_id": "...",
  "artifact_type": "project",
  "title": "...",
  "summary": "...",
  "tags": [...],
  "extension": {...}
}
```

**Nested format (new):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "...",
  "gw_user_id": "...",
  "artifact_type": "project",
  "artifact_payload": {
    "title": "...",
    "summary": "...",
    "tags": [...],
    "extension": {...}
  }
}
```

Both produce identical internal canonical shape:
```javascript
{
  gw_action: "artifact.save",
  gw_workspace_id: "...",
  gw_user_id: "...",
  artifact_type: "project",
  artifact_id: null,
  payload: {
    title: "...",
    summary: "...",
    tags: [...],
    lifecycle_status: "active",
    extension: {...}
  },
  ...
}
```

---

**End of Implementation Plan**

**Governing Authority**: Snapshot `AAA_New_Qwrk__Snapshot__Gateway_Internal_Canonical_Lock__2026-01-05__v1`

**Status**: ACTIVE (Ready for execution)

**Next Step**: Session 1 — Gateway Normalization
