# T69 — Phase 3: Workflow Enforcement Specification

**Date:** 2026-03-03
**Version:** v2
**Thread:** T69 — Behavioral Role Layer / Semantic Type Registry
**Author:** CC (Claude Code) — approved by Joel
**Status:** SPEC-ONLY — No implementation until Joel approves

---

## CHANGELOG

### v2 (2026-03-03) — Governance clarification pass

- Section 5.7: Replaced `DELETE` cleanup for H03 test registry entry with `UPDATE SET active = false` (registry entries must never be deleted; deactivation only)
- Section 5.8: Added Inactive Semantic Type Behavior Clarification (deactivation prevents future assignment; existing references remain valid; no automatic migration; reassignment is future scope)
- No workflow logic, test definitions, deployment sequence, or version numbers changed
- Previous version: `Archive/T69__Phase_3__Workflow_Spec__v1__2026-03-03.md`

### v1 (2026-03-03) — Initial specification

- Full deterministic specification for Phase 3 workflow enforcement
- Canonical Payload v3 delta defined
- Save, Update, Gateway node-level specifications
- H-series test matrix with exact expected shapes
- Source: CC Execution Prompt — T69 Phase 3

---

## Preconditions (Verified)

| Condition | State |
|-----------|-------|
| DDL v2.6 deployed | ✅ |
| `semantic_type_id` column on `qxb_artifact` | ✅ Live, nullable uuid |
| FK `qxb_artifact_semantic_type_fk` ON DELETE RESTRICT | ✅ |
| Index `idx_qxb_artifact_semantic_type` (partial, WHERE NOT NULL) | ✅ |
| `qxb_semantic_type_registry` seeded (9 values, all active) | ✅ |
| `qxb_semantic_type_audit` append-only (triggers block UPDATE/DELETE) | ✅ |
| `update_semantic_type()` RPC (SECURITY DEFINER, atomic, version++) | ✅ |
| Backfill complete (848 top-level → exploratory) | ✅ |
| Conditional CHECK `qxb_artifact_semantic_type_required_for_top_level` | ✅ |
| `artifact.update` does NOT currently touch `semantic_type_id` | ✅ |

---

## Scope Boundary

Phase 3 modifies ONLY:

- Gateway `Normalize_Request` (forwarding)
- Save sub-workflow (validation + INSERT field)
- Update sub-workflow (block + dedicated RPC route)
- Canonical Payload doc (v2 → v3)
- Test files (H-series)

Phase 3 does NOT:

- Modify DDL or schema
- Add tables, columns, functions, or constraints
- Change RLS policies
- Modify Promote, Query, List, Delete, or Restore workflows
- Add new Gateway actions
- Change registry seed data

---

# 1. Canonical Payload v3 Delta (v2 → v3)

## 1.1 artifact.save — New Required Field

### Top-Level Types (project, snapshot, journal, restart)

`semantic_type_id` is **REQUIRED** on INSERT.

| Field | Type | Constraint |
|-------|------|-----------|
| `semantic_type_id` | uuid | REQUIRED. Must be a valid UUID. Must exist in `qxb_semantic_type_registry`. Must have `active = true`. |

No fallback to exploratory. No silent defaulting. No inference.

### Non-Top-Level Types (branch, leaf, limb, instruction_pack, forest, thicket, flower)

`semantic_type_id` **MUST NOT** be provided.

If present → `VALIDATION_ERROR` with code `SEMANTIC_TYPE_NOT_APPLICABLE`.

### Save UPDATE Path

`semantic_type_id` is **IGNORED** on the save UPDATE path. The save UPDATE path does not touch `semantic_type_id`. To change semantic type, use the dedicated `artifact.update` RPC route (Section 3).

## 1.2 artifact.update — New Paths

### Block Rule

`semantic_type_id` in the `extension` object triggers dedicated routing. It is **never** passed through the normal extension update path.

### Dedicated Semantic Type Update

If `extension` contains **only** `semantic_type_id` + `reason` (no other keys):
→ Route to `update_semantic_type()` RPC

### Mixed Update Block

If `extension` contains `semantic_type_id` + **any other key** (excluding `reason`):
→ `MIXED_UPDATE_NOT_ALLOWED`

If `extension` contains `semantic_type_id` AND `tags` is also present:
→ `MIXED_UPDATE_NOT_ALLOWED`

### No Reason

If `extension` contains `semantic_type_id` without `reason`:
→ `VALIDATION_ERROR` (reason required)

## 1.3 artifact.query / artifact.list — No Changes

`semantic_type_id` is already on the spine. Query and List return it automatically as part of the spine row. No workflow changes needed.

## 1.4 Payload Examples

### Valid Save — Top-Level (project)

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "title": "New Project",
  "semantic_type_id": "<valid-active-registry-uuid>",
  "extension": {
    "lifecycle_stage": "seed"
  }
}
```

### Valid Save — Top-Level (snapshot)

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "title": "Decision Snapshot",
  "semantic_type_id": "<valid-active-registry-uuid>",
  "extension": {
    "payload": { "decision": "Use REST over GraphQL" }
  }
}
```

### Invalid Save — Missing semantic_type_id (top-level)

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "title": "Missing Semantic Type",
  "extension": {
    "lifecycle_stage": "seed"
  }
}
```

Response:

```json
{
  "ok": false,
  "_gw_route": "error",
  "gw_action": "artifact.save",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed for artifact.save operation (INSERT)",
    "details": {
      "validation_errors": [
        { "field": "semantic_type_id", "reason": "required for top-level artifact types (project, snapshot, journal, restart)" }
      ],
      "artifact_type": "project",
      "operation": "INSERT"
    }
  }
}
```

### Invalid Save — Non-top-level with semantic_type_id

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "title": "Branch with semantic type",
  "semantic_type_id": "<any-uuid>",
  "parent_artifact_id": "<parent-uuid>"
}
```

Response:

```json
{
  "ok": false,
  "_gw_route": "error",
  "gw_action": "artifact.save",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed for artifact.save operation (INSERT)",
    "details": {
      "validation_errors": [
        { "field": "semantic_type_id", "reason": "not allowed for non-top-level artifact types" }
      ],
      "artifact_type": "branch",
      "operation": "INSERT"
    }
  }
}
```

### Invalid Save — Non-existent UUID

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "title": "Bad UUID",
  "semantic_type_id": "00000000-0000-0000-0000-000000000000",
  "extension": {
    "lifecycle_stage": "seed"
  }
}
```

Response:

```json
{
  "ok": false,
  "_gw_route": "error",
  "gw_action": "artifact.save",
  "error": {
    "code": "INVALID_SEMANTIC_TYPE",
    "message": "semantic_type_id not found in registry",
    "details": {
      "semantic_type_id": "00000000-0000-0000-0000-000000000000"
    }
  }
}
```

### Invalid Save — Inactive semantic_type_id

Response:

```json
{
  "ok": false,
  "_gw_route": "error",
  "gw_action": "artifact.save",
  "error": {
    "code": "SEMANTIC_TYPE_INACTIVE",
    "message": "Target semantic type is inactive in registry",
    "details": {
      "semantic_type_id": "<inactive-uuid>"
    }
  }
}
```

### Valid Update — Dedicated Semantic Type Change

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<project-uuid>",
  "extension": {
    "semantic_type_id": "<new-active-registry-uuid>",
    "reason": "Reclassifying from exploratory to governance"
  }
}
```

Response (success — from RPC):

```json
{
  "ok": true,
  "gw_action": "artifact.update",
  "artifact_id": "<project-uuid>",
  "operation": "SEMANTIC_TYPE_UPDATE",
  "old_semantic_type_id": "<old-uuid>",
  "new_semantic_type_id": "<new-uuid>",
  "version": 3,
  "timestamp": "<ISO 8601>"
}
```

Response (noop — same value):

```json
{
  "ok": true,
  "gw_action": "artifact.update",
  "artifact_id": "<project-uuid>",
  "operation": "SEMANTIC_TYPE_UPDATE",
  "noop": true,
  "message": "semantic_type_id unchanged",
  "timestamp": "<ISO 8601>"
}
```

### Invalid Update — Missing Reason

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<project-uuid>",
  "extension": {
    "semantic_type_id": "<uuid>"
  }
}
```

Response:

```json
{
  "ok": false,
  "_gw_route": "error",
  "gw_action": "artifact.update",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "reason is required for semantic_type_id update",
    "details": {
      "field": "reason",
      "hint": "Provide extension.reason when updating semantic_type_id"
    }
  }
}
```

### Invalid Update — Mixed (semantic_type_id + other fields)

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<project-uuid>",
  "extension": {
    "semantic_type_id": "<uuid>",
    "reason": "...",
    "operational_state": "paused"
  }
}
```

Response:

```json
{
  "ok": false,
  "_gw_route": "error",
  "gw_action": "artifact.update",
  "error": {
    "code": "MIXED_UPDATE_NOT_ALLOWED",
    "message": "semantic_type_id update cannot be combined with other extension fields",
    "details": {
      "semantic_type_id_present": true,
      "other_fields": ["operational_state"],
      "hint": "Submit semantic_type_id + reason as a standalone update, then update other fields separately"
    }
  }
}
```

### Invalid Update — Mixed (semantic_type_id + tags)

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<project-uuid>",
  "extension": {
    "semantic_type_id": "<uuid>",
    "reason": "..."
  },
  "tags": {
    "add": ["governance"]
  }
}
```

Response:

```json
{
  "ok": false,
  "_gw_route": "error",
  "gw_action": "artifact.update",
  "error": {
    "code": "MIXED_UPDATE_NOT_ALLOWED",
    "message": "semantic_type_id update cannot be combined with tags update",
    "details": {
      "semantic_type_id_present": true,
      "tags_present": true,
      "hint": "Submit semantic_type_id + reason as a standalone update, then update tags separately"
    }
  }
}
```

## 1.5 New Error Codes (v3 additions)

| Code | Source | Trigger |
|------|--------|---------|
| `INVALID_SEMANTIC_TYPE` | Save | `semantic_type_id` UUID not found in `qxb_semantic_type_registry` |
| `SEMANTIC_TYPE_INACTIVE` | Save | UUID found but `active = false` |
| `MIXED_UPDATE_NOT_ALLOWED` | Update | `semantic_type_id` combined with other extension fields or tags |

Existing codes reused:

| Code | New Trigger |
|------|------------|
| `VALIDATION_ERROR` | Missing `semantic_type_id` for top-level save; `semantic_type_id` present for non-top-level save; missing `reason` for semantic type update |

## 1.6 Mutation Invariants (v3 additions)

| Operation | semantic_type_id Behavior | Version |
|-----------|--------------------------|---------|
| Save INSERT (top-level) | Written from payload (REQUIRED) | DB default (1) |
| Save INSERT (non-top-level) | NULL (REJECTED if provided) | DB default (1) |
| Save UPDATE path | IGNORED (not touched) | No change from semantic_type |
| Update tags-only | Not touched | +1 (existing behavior) |
| Update extension (project) | BLOCKED if present | No semantic_type version change |
| Update semantic_type (dedicated) | Changed via RPC | +1 (RPC increments) |
| Update semantic_type (noop) | Unchanged | No change |
| Promote | Not touched | +1 (existing behavior) |
| Delete/Restore | Not touched | No change |

## 1.7 Spine Field Mutability (v3 addition)

Add to Canonical v2 Section 10.3:

| Field | Mutable Via |
|-------|-------------|
| `semantic_type_id` | `update_semantic_type()` RPC via dedicated `artifact.update` path ONLY |

---

# 2. Save Workflow Specification

## 2.1 Overview — Affected Nodes

| Node | Change Type | Description |
|------|------------|-------------|
| `NQxb_Artifact_Save_v1__Normalize_Request` | MODIFY | Forward `semantic_type_id` from request |
| `NQxb_Artifact_Save_v1__Validate_Request` | MODIFY | Add presence/rejection validation |
| **`NQxb_Artifact_Save_v1__Lookup_Semantic_Type`** | NEW | Supabase GET: registry lookup |
| **`NQxb_Artifact_Save_v1__Guard_Semantic_Type`** | NEW | Code: validate existence + active |
| `NQxb_Artifact_Save_v1__DB_Insert_Spine` | MODIFY | Add `semantic_type_id` field mapping |

## 2.2 Normalize_Request Changes

**Current code (line in canonical output section):**

```javascript
const canonical = {
  // ... existing fields ...
  execution_status: req.execution_status ?? null,

  // Extension
  extension: extension_obj,
  // ...
};
```

**Add after `execution_status` line:**

```javascript
  semantic_type_id: req.semantic_type_id ?? null,
```

Full addition — one line in the canonical output object. No other changes.

**Rationale:** `semantic_type_id` is a top-level spine field (like `execution_status`), not an extension field. It is forwarded as-is. No normalization, no defaulting.

## 2.3 Validate_Request Changes

**Insertion point:** After the existing type-specific validation blocks (project, snapshot/restart, instruction_pack, journal) and before the final error/success return.

**Add this block (INSERT operations only, after all existing type-specific checks):**

```javascript
// ----- semantic_type_id validation (T69 — Canonical v3) -----
const TOP_LEVEL_TYPES = ['project', 'snapshot', 'journal', 'restart'];

if (!is_update) {
  if (TOP_LEVEL_TYPES.includes(artifact_type)) {
    // REQUIRED for top-level INSERT
    if (!isNonEmptyString(req.semantic_type_id)) {
      errors.push({
        field: 'semantic_type_id',
        reason: 'required for top-level artifact types (project, snapshot, journal, restart)'
      });
    }
  } else {
    // REJECTED for non-top-level INSERT
    if (req.semantic_type_id !== null && req.semantic_type_id !== undefined) {
      errors.push({
        field: 'semantic_type_id',
        reason: 'not allowed for non-top-level artifact types'
      });
    }
  }
}
```

**Validation order (deterministic):**

1. Global required fields (`gw_workspace_id`, `artifact_type`) — existing
2. Priority range validation — existing
3. Operation-specific requirements (INSERT/UPDATE) — existing
4. Type-specific extension validation (project, snapshot, journal, etc.) — existing
5. **`semantic_type_id` presence/rejection** — NEW (this block)
6. Return errors or pass-through — existing

**No UUID format validation here.** UUID format is validated implicitly by the registry lookup (Section 2.4). If the string is not a valid UUID, the Supabase GET will return 0 rows, and the Guard will reject it.

**No registry lookup here.** Validate_Request is a pure Code node with no DB access. Registry validation happens in the new Lookup + Guard nodes (Section 2.4).

## 2.4 New Nodes: Semantic Type Registry Lookup + Guard

### Node: `NQxb_Artifact_Save_v1__Lookup_Semantic_Type`

**Type:** `n8n-nodes-base.supabase` (GET)
**Position:** Between Type_Registry_Guard ok-path and `Switch_InsertOrUpdate`
**Connection:** Receives from Type Registry Guard ok output → outputs to Guard_Semantic_Type

**Configuration:**

| Setting | Value |
|---------|-------|
| Operation | Get |
| Table | `qxb_semantic_type_registry` |
| Filter | `semantic_type_id` = `={{ $json.semantic_type_id }}` |
| `alwaysOutputData` | `true` |
| Credentials | `Qwrk Supabase – Kernel v1` (id: `n4R4JdOIV9zrCGIT`) |

**Behavior:** Returns 0 or 1 row. If `semantic_type_id` is null (non-top-level types that passed validation), the filter returns 0 rows.

### Node: `NQxb_Artifact_Save_v1__Guard_Semantic_Type`

**Type:** `n8n-nodes-base.code` (v2)
**Position:** After Lookup_Semantic_Type → outputs to Switch_InsertOrUpdate
**Connection:** Receives from Lookup_Semantic_Type → outputs to existing Switch_InsertOrUpdate

**Full code:**

```javascript
// NQxb_Artifact_Save_v1__Guard_Semantic_Type
// T69: Validate semantic_type_id against registry
// Only applies to top-level INSERT operations
// Non-top-level types pass through (semantic_type_id is null, already validated)

const TOP_LEVEL_TYPES = ['project', 'snapshot', 'journal', 'restart'];

// Get original validated request from upstream
const req = $node['NQxb_Artifact_Save_v1__Validate_Request'].json;
const registryRow = $json;
const artifact_type = (req.artifact_type ?? '').trim();
const is_update = req.is_update === true;

// Pass-through: UPDATE operations (semantic_type_id not touched on UPDATE)
if (is_update) {
  return [{ json: req }];
}

// Pass-through: non-top-level types (semantic_type_id is null, validated by Validate_Request)
if (!TOP_LEVEL_TYPES.includes(artifact_type)) {
  return [{ json: req }];
}

// Top-level INSERT: registry row must exist
if (!registryRow || !registryRow.semantic_type_id) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: req.gw_action ?? 'artifact.save',
      gw_workspace_id: req.gw_workspace_id ?? null,
      artifact_type: artifact_type,
      error: {
        code: 'INVALID_SEMANTIC_TYPE',
        message: 'semantic_type_id not found in registry',
        details: {
          semantic_type_id: req.semantic_type_id
        }
      },
      timestamp: new Date().toISOString()
    }
  }];
}

// Top-level INSERT: registry entry must be active
if (registryRow.active === false) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: req.gw_action ?? 'artifact.save',
      gw_workspace_id: req.gw_workspace_id ?? null,
      artifact_type: artifact_type,
      error: {
        code: 'SEMANTIC_TYPE_INACTIVE',
        message: 'Target semantic type is inactive in registry',
        details: {
          semantic_type_id: req.semantic_type_id
        }
      },
      timestamp: new Date().toISOString()
    }
  }];
}

// Registry validated — pass through original request
return [{ json: req }];
```

### Routing After Guard

The Guard outputs either:
- `ok: false` (error) — must route to error output (existing error merge node)
- `ok: true` (pass) — continues to `Switch_InsertOrUpdate`

**Implementation option A (preferred):** Add an IF node after `Guard_Semantic_Type` that checks `$json.ok === false` → error path, else → `Switch_InsertOrUpdate`.

**Implementation option B:** Add the Guard output to the existing `Switch_InsertOrUpdate` error detection (if the Switch already handles ok/error branching for upstream nodes).

**Recommended:** Option A — add `NQxb_Artifact_Save_v1__Switch_Semantic_Type_Result` (Switch node, same pattern as `Switch_Type_Registry` in Update workflow).

| Case | Condition | Output |
|------|-----------|--------|
| Error | `$json.ok === false` | → Error merge/response node |
| OK | `$json.ok === true` | → `Switch_InsertOrUpdate` |

## 2.5 DB_Insert_Spine Changes

**Current field list (from Save v40):**

```
workspace_id, owner_user_id, artifact_type, title, summary,
priority, tags, content, parent_artifact_id, lifecycle_status,
execution_status
```

**Add one field:**

| Field ID | Field Value |
|----------|-------------|
| `semantic_type_id` | `={{ $json.semantic_type_id }}` |

**Position:** After `execution_status` (last field before closing).

**Behavior:**
- Top-level types: `$json.semantic_type_id` contains the validated UUID
- Non-top-level types: `$json.semantic_type_id` is `null` (from Normalize_Request default)
- Supabase node writes `null` as SQL NULL — correct behavior

**No conditional logic needed.** The field is always mapped. For non-top-level types, the value is null, which the DB allows (CHECK constraint only requires NOT NULL for top-level types).

## 2.6 Save Workflow — Complete Node Flow (INSERT path)

```
Normalize_Request
  → Validate_Request
    → [existing ok/error IF]
      → error → response
      → ok → [existing Type_Registry_Lookup]
        → [existing Type_Registry_Guard]
          → [existing Switch_Type_Registry]
            → error → response
            → ok → Lookup_Semantic_Type (NEW)
              → Guard_Semantic_Type (NEW)
                → Switch_Semantic_Type_Result (NEW)
                  → error → response
                  → ok → Switch_InsertOrUpdate
                    → INSERT → DB_Insert_Spine (MODIFIED: +semantic_type_id)
                      → ... (existing downstream)
```

---

# 3. Update Workflow Specification

## 3.1 Overview — Affected Nodes

| Node | Change Type | Description |
|------|------------|-------------|
| `NQxb_Artifact_Update_v1__Check_Mutability_Rules` | MODIFY | Add semantic_type_id detection (new check #2.5) |
| `NQxb_Artifact_Update_v1__Switch_Update_Mode` | MODIFY | Add `semantic_type` case |
| **`NQxb_Artifact_Update_v1__RPC_Update_Semantic_Type`** | NEW | HTTP Request: call RPC |
| **`NQxb_Artifact_Update_v1__Guard_Semantic_Type_Result`** | NEW | Code: format RPC response |

## 3.2 Check_Mutability_Rules Changes

**Insertion point:** After check #2 (tags-only bypass) and before check #3 (immutability check for snapshot/restart/instruction_pack).

**New check #2.5 — full code block to insert:**

```javascript
// 2.5 semantic_type_id detection (T69)
// If extension contains semantic_type_id, route to dedicated path.
// This check runs BEFORE type-specific immutability checks because
// semantic_type_id update is valid even for immutable types (snapshot, restart).
const extensionObj = normalizeNode.extension || {};
const extensionKeyList = Object.keys(extensionObj);

if ('semantic_type_id' in extensionObj) {
  const topLevelTypes = ['project', 'snapshot', 'journal', 'restart'];

  // 2.5.1 Mixed update guard: semantic_type_id + tags
  if (normalizedTags !== null) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'MIXED_UPDATE_NOT_ALLOWED',
          message: 'semantic_type_id update cannot be combined with tags update',
          details: {
            semantic_type_id_present: true,
            tags_present: true,
            hint: 'Submit semantic_type_id + reason as a standalone update, then update tags separately'
          }
        },
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_type: artifact_type,
        artifact_id: existing.artifact_id,
      }
    }];
  }

  // 2.5.2 Mixed update guard: semantic_type_id + other extension fields
  const otherExtKeys = extensionKeyList.filter(k => k !== 'semantic_type_id' && k !== 'reason');
  if (otherExtKeys.length > 0) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'MIXED_UPDATE_NOT_ALLOWED',
          message: 'semantic_type_id update cannot be combined with other extension fields',
          details: {
            semantic_type_id_present: true,
            other_fields: otherExtKeys,
            hint: 'Submit semantic_type_id + reason as a standalone update, then update other fields separately'
          }
        },
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_type: artifact_type,
        artifact_id: existing.artifact_id,
      }
    }];
  }

  // 2.5.3 Top-level type check
  if (!topLevelTypes.includes(artifact_type)) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'SEMANTIC_TYPE_NOT_APPLICABLE',
          message: 'semantic_type_id applies only to top-level artifact types',
          details: {
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            allowed_types: topLevelTypes
          }
        },
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_type: artifact_type,
        artifact_id: existing.artifact_id,
      }
    }];
  }

  // 2.5.4 Reason validation
  const semanticReason = (extensionObj.reason ?? '').toString().trim();
  if (!semanticReason) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: 'reason is required for semantic_type_id update',
          details: {
            field: 'reason',
            hint: 'Provide extension.reason when updating semantic_type_id'
          }
        },
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_type: artifact_type,
        artifact_id: existing.artifact_id,
      }
    }];
  }

  // 2.5.5 Route to dedicated semantic type update
  return [{
    json: {
      ok: true,
      _gw_route: 'ok',
      _update_mode: 'semantic_type',
      gw_action: normalizeNode.gw_action ?? 'artifact.update',
      gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
      artifact_id: existing.artifact_id,
      workspace_id: existing.workspace_id,
      artifact_type: artifact_type,
      _semantic_type_update: {
        new_semantic_type_id: extensionObj.semantic_type_id,
        reason: semanticReason,
      },
      _normalized_request: normalizeNode,
      _existing_artifact: existing,
      _gw_debug: {
        ...(normalizeNode._gw_debug ?? {}),
        mutability: 'semantic_type_dedicated',
        operation: 'UPDATE',
      }
    }
  }];
}
```

**No other changes to Check_Mutability_Rules.** The existing checks #3–#7 are unaffected because the new check #2.5 returns early when `semantic_type_id` is present.

## 3.3 Switch_Update_Mode Changes

**Current cases:**

| Case | Value | Output |
|------|-------|--------|
| 0 | `tags_only` | → Tags update path |
| 1 | `spine_fields` | → Spine update path (T64) |
| 2 | `noop` | → Noop response |
| fallback | (extra) | → Extension update path |

**Add case 3:**

| Case | Value | Output |
|------|-------|--------|
| 3 | `semantic_type` | → RPC update path (NEW) |

**Switch condition for case 3:**

```
leftValue: ={{ $json._update_mode }}
rightValue: semantic_type
operator: string / equals
```

## 3.4 New Node: RPC_Update_Semantic_Type

**Type:** `n8n-nodes-base.httpRequest` (typeVersion 4.2)
**Position:** After Switch_Update_Mode case 3 output
**Connection:** Receives from Switch_Update_Mode `semantic_type` case → outputs to Guard_Semantic_Type_Result

**Configuration:**

| Setting | Value |
|---------|-------|
| Method | POST |
| URL | `https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/rpc/update_semantic_type` |
| Authentication | `predefinedCredentialType` |
| Credential Type | `supabaseApi` |
| Credential | `Qwrk Supabase – Kernel v1` (id: `n4R4JdOIV9zrCGIT`) |
| Send Headers | Yes |
| Header 1 | `Content-Type` = `application/json` |
| Header 2 | `Prefer` = `return=representation` |
| Send Body | Yes |
| Body Content Type | JSON |
| Body (JSON) | See below |
| `alwaysOutputData` | `true` |
| `onError` | `continueErrorOutput` |

**Body JSON (using expressions):**

```json
{
  "p_artifact_id": "={{ $json.artifact_id }}",
  "p_new_semantic_type_id": "={{ $json._semantic_type_update.new_semantic_type_id }}",
  "p_reason": "={{ $json._semantic_type_update.reason }}",
  "p_actor_id": null
}
```

**Response shape from PostgREST:**

PostgREST wraps the RPC's `jsonb` return in the HTTP response body. Because the function returns `jsonb`, PostgREST returns:

```json
{"ok": true, "artifact_id": "...", "old_semantic_type_id": "...", "new_semantic_type_id": "...", "version": 3}
```

Or on error:

```json
{"ok": false, "error": {"code": "INVALID_SEMANTIC_TYPE", "message": "...", "details": {...}}}
```

Or noop:

```json
{"ok": true, "noop": true, "message": "semantic_type_id unchanged"}
```

## 3.5 New Node: Guard_Semantic_Type_Result

**Type:** `n8n-nodes-base.code` (v2)
**Position:** After RPC_Update_Semantic_Type
**Connection:** Receives from RPC_Update_Semantic_Type → outputs to response merge

**Full code:**

```javascript
// NQxb_Artifact_Update_v1__Guard_Semantic_Type_Result
// T69: Format RPC response into Gateway response envelope

const rpcResult = $json;
const upstream = $node['NQxb_Artifact_Update_v1__Switch_Update_Mode'].json;

// RPC returned error
if (rpcResult.ok === false) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: upstream.gw_action ?? 'artifact.update',
      gw_workspace_id: upstream.gw_workspace_id ?? null,
      artifact_type: upstream.artifact_type ?? null,
      artifact_id: upstream.artifact_id ?? null,
      error: rpcResult.error ?? {
        code: 'INTERNAL_ERROR',
        message: 'RPC returned error without envelope'
      },
      timestamp: new Date().toISOString()
    }
  }];
}

// RPC returned noop
if (rpcResult.noop === true) {
  return [{
    json: {
      ok: true,
      _gw_route: 'ok',
      gw_action: upstream.gw_action ?? 'artifact.update',
      artifact_id: upstream.artifact_id,
      artifact_type: upstream.artifact_type,
      operation: 'SEMANTIC_TYPE_UPDATE',
      noop: true,
      message: rpcResult.message ?? 'semantic_type_id unchanged',
      timestamp: new Date().toISOString()
    }
  }];
}

// RPC returned success
return [{
  json: {
    ok: true,
    _gw_route: 'ok',
    gw_action: upstream.gw_action ?? 'artifact.update',
    artifact_id: rpcResult.artifact_id ?? upstream.artifact_id,
    artifact_type: upstream.artifact_type,
    operation: 'SEMANTIC_TYPE_UPDATE',
    old_semantic_type_id: rpcResult.old_semantic_type_id ?? null,
    new_semantic_type_id: rpcResult.new_semantic_type_id ?? null,
    version: rpcResult.version ?? null,
    timestamp: new Date().toISOString()
  }
}];
```

## 3.6 Update Workflow — Complete Node Flow (semantic_type path)

```
Normalize_Request
  → Validate_Request
    → Guard_Error_ShortCircuit
      → error → response
      → ok → Lookup_Type_Registry
        → Type_Registry_Guard
          → Switch_Type_Registry
            → error → response
            → ok → Fetch_Existing_Spine
              → Check_Mutability_Rules (MODIFIED: +check #2.5)
                → Switch_Mutability_Result
                  → error → response
                  → ok → Switch_Update_Mode (MODIFIED: +semantic_type case)
                    → tags_only → [existing tags path]
                    → spine_fields → [existing spine path]
                    → noop → [existing noop path]
                    → semantic_type (NEW) → RPC_Update_Semantic_Type (NEW)
                      → Guard_Semantic_Type_Result (NEW)
                        → response merge
                    → fallback → [existing extension path]
```

## 3.7 Version Semantics

| Path | Version Behavior |
|------|-----------------|
| `semantic_type` via RPC | RPC increments version (+1) — the workflow does NOT increment version |
| `semantic_type` noop | No version change — RPC detects same value and skips |

**Critical:** The existing tags-only and extension paths increment version in their own DB UPDATE nodes. The semantic_type path MUST NOT duplicate this. The RPC handles version increment internally.

---

# 4. Gateway Behavior Specification

## 4.1 Normalize_Request Changes

**Current code (relevant section):**

```javascript
return [{
  json: {
    // ...existing fields...
    execution_status: raw.execution_status ?? null,

    // --- Owner / auth passthrough ---
    auth_username: raw.auth_username ?? raw.owner_username ?? raw.created_by ?? null,
    // ...
  }
}];
```

**Add after `execution_status` line:**

```javascript
    semantic_type_id: raw.semantic_type_id ?? null,
```

**One line. No other changes.**

## 4.2 Gateway Invariants

| Rule | Enforcement |
|------|-------------|
| Gateway forwards `semantic_type_id` unchanged | `raw.semantic_type_id ?? null` — no transformation |
| Gateway does NOT inject default | `?? null` — not `?? 'exploratory'` |
| Gateway does NOT infer from artifact_type | No conditional logic |
| Gateway does NOT validate registry | Validation is in sub-workflows |

## 4.3 Gatekeeper — No Changes

The Gatekeeper (`NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly`) does NOT need changes. It validates `gw_action`, `gw_workspace_id`, `artifact_type`, and `artifact_id`. It does not inspect `semantic_type_id`.

## 4.4 Gateway Version

Gateway version bump: v58 → v59

Canonical Payload version bump: v2 → v3

Both must be documented in the Canonical Payload v3 header when the file is created.

---

# 5. Test Matrix Specification (H-Series)

## 5.1 Test Infrastructure

### Setup: Capture Exploratory UUID

Before H01, a setup test queries the KGB project to capture the `exploratory` semantic_type_id UUID:

| Test | Action | Purpose |
|------|--------|---------|
| H00 | `artifact.query` KGB project | Capture `SEMANTIC_EXPLORATORY_ID` from `data.artifact.semantic_type_id` |

KGB project ID: `668bd18f-4424-41e6-b2f9-393ecd2ec534`
KGB project type: `project`
KGB project semantic_type_id after backfill: the UUID for `exploratory` key

### Setup: Manual SQL Steps

| File | Purpose | When to Run |
|------|---------|-------------|
| `H03_SETUP_SQL.sql` | Insert inactive registry entry; query governance UUID | After H00-H02 pass, before H03 |
| `H07_SETUP_SQL.sql` | Query governance UUID for RPC test | After H06, before H07 |

These follow the G04 precedent: SQL files are documentation for manual steps. The harness SKIPs tests with unresolved placeholders.

## 5.2 Test Definitions

### H00 — Setup: Query KGB Project (Capture Semantic Type UUID)

| Field | Value |
|-------|-------|
| Action | `artifact.query` |
| Target | KGB project `668bd18f-4424-41e6-b2f9-393ecd2ec534` |
| Expected | `ok: true` |
| Capture | `SEMANTIC_EXPLORATORY_ID` ← `data.artifact.semantic_type_id` |
| DB State | No change |

### H01 — Save Top-Level Without semantic_type_id → FAIL

| Field | Value |
|-------|-------|
| Action | `artifact.save` |
| Type | `project` |
| Payload | Valid project save payload WITHOUT `semantic_type_id` |
| Expected HTTP | 200 |
| Expected ok | `false` |
| Expected error_code | `VALIDATION_ERROR` |
| Expected error detail | `field: "semantic_type_id", reason: "required for top-level artifact types ..."` |
| DB State | No row created |

### H02 — Save Top-Level With Invalid UUID → FAIL

| Field | Value |
|-------|-------|
| Action | `artifact.save` |
| Type | `project` |
| Payload | Valid project save payload WITH `semantic_type_id: "00000000-0000-0000-0000-000000000000"` |
| Expected HTTP | 200 |
| Expected ok | `false` |
| Expected error_code | `INVALID_SEMANTIC_TYPE` |
| Expected error detail | `semantic_type_id: "00000000-0000-0000-0000-000000000000"` |
| DB State | No row created |

### H03 — Save Top-Level With Inactive UUID → FAIL

| Field | Value |
|-------|-------|
| Action | `artifact.save` |
| Type | `project` |
| Payload | Valid project save payload WITH `semantic_type_id: "{{SEMANTIC_INACTIVE_ID}}"` |
| Expected HTTP | 200 |
| Expected ok | `false` |
| Expected error_code | `SEMANTIC_TYPE_INACTIVE` |
| DB State | No row created |
| **Prerequisite** | `H03_SETUP_SQL.sql` must be run first (inserts inactive registry entry) |
| **Harness behavior** | SKIP if `SEMANTIC_INACTIVE_ID` not in captured vars |

### H04 — Save Non-Top-Level With semantic_type_id → FAIL

| Field | Value |
|-------|-------|
| Action | `artifact.save` |
| Type | `branch` |
| Payload | Branch save payload WITH `semantic_type_id: "{{SEMANTIC_EXPLORATORY_ID}}"` |
| Expected HTTP | 200 |
| Expected ok | `false` |
| Expected error_code | `VALIDATION_ERROR` |
| Expected error detail | `field: "semantic_type_id", reason: "not allowed for non-top-level artifact types"` |
| DB State | No row created |

### H05 — Update: semantic_type_id Without Reason → FAIL

| Field | Value |
|-------|-------|
| Action | `artifact.update` |
| Type | `project` |
| Target | KGB project `668bd18f-4424-41e6-b2f9-393ecd2ec534` |
| Payload | `extension: { "semantic_type_id": "{{SEMANTIC_EXPLORATORY_ID}}" }` (no reason) |
| Expected HTTP | 200 |
| Expected ok | `false` |
| Expected error_code | `VALIDATION_ERROR` |
| Expected error detail | `field: "reason", hint: "Provide extension.reason ..."` |
| DB State | No change to KGB project |

### H06 — Mixed Update: semantic_type_id + Tags → FAIL

| Field | Value |
|-------|-------|
| Action | `artifact.update` |
| Type | `project` |
| Target | KGB project `668bd18f-4424-41e6-b2f9-393ecd2ec534` |
| Payload | `extension: { "semantic_type_id": "{{SEMANTIC_EXPLORATORY_ID}}", "reason": "test" }` + `tags: { "add": ["h06-test"] }` |
| Expected HTTP | 200 |
| Expected ok | `false` |
| Expected error_code | `MIXED_UPDATE_NOT_ALLOWED` |
| Expected error detail | `semantic_type_id_present: true, tags_present: true` |
| DB State | No change to KGB project. No tag added. |

### H07 — Valid RPC Semantic Type Update → PASS

| Field | Value |
|-------|-------|
| Action | `artifact.update` |
| Type | `project` |
| Target | KGB project `668bd18f-4424-41e6-b2f9-393ecd2ec534` |
| Payload | `extension: { "semantic_type_id": "{{SEMANTIC_GOVERNANCE_ID}}", "reason": "H07 certification test — reclassify to governance" }` |
| Expected HTTP | 200 |
| Expected ok | `true` |
| Expected fields | `operation: "SEMANTIC_TYPE_UPDATE"`, `old_semantic_type_id: {{SEMANTIC_EXPLORATORY_ID}}`, `new_semantic_type_id: {{SEMANTIC_GOVERNANCE_ID}}`, `version: (previous + 1)` |
| DB State | KGB project `semantic_type_id` changed to governance UUID. `version` incremented by 1. One row inserted in `qxb_semantic_type_audit`. |
| **Prerequisite** | `H07_SETUP_SQL.sql` must be run first (to get governance UUID) |
| **Harness behavior** | SKIP if `SEMANTIC_GOVERNANCE_ID` not in captured vars |
| **Cleanup** | After test run, operator should revert KGB project to exploratory (manual RPC call or SQL) |

### H08 — RPC Noop: Same Value → PASS

| Field | Value |
|-------|-------|
| Action | `artifact.update` |
| Type | `project` |
| Target | KGB project `668bd18f-4424-41e6-b2f9-393ecd2ec534` |
| Payload | `extension: { "semantic_type_id": "{{SEMANTIC_EXPLORATORY_ID}}", "reason": "H08 noop test — same value" }` |
| Expected HTTP | 200 |
| Expected ok | `true` |
| Expected fields | `operation: "SEMANTIC_TYPE_UPDATE"`, `noop: true`, `message: "semantic_type_id unchanged"` |
| DB State | No change. Version NOT incremented. No audit row. |
| **Note** | Uses `SEMANTIC_EXPLORATORY_ID` which matches the KGB project's current value (from backfill). If H07 ran and changed the value, this test will produce a real change instead of noop. Run H08 BEFORE H07, or run H08 independently. |

## 5.3 Test Execution Order

**Automated (no manual SQL needed):**

| Test | Depends On | Expected |
|------|-----------|----------|
| H00 | — | PASS (captures UUID) |
| H01 | — | FAIL (VALIDATION_ERROR) |
| H02 | — | FAIL (INVALID_SEMANTIC_TYPE) |
| H04 | H00 (uses SEMANTIC_EXPLORATORY_ID) | FAIL (VALIDATION_ERROR) |
| H05 | H00 (uses SEMANTIC_EXPLORATORY_ID) | FAIL (VALIDATION_ERROR) |
| H06 | H00 (uses SEMANTIC_EXPLORATORY_ID) | FAIL (MIXED_UPDATE_NOT_ALLOWED) |
| H08 | H00 (uses SEMANTIC_EXPLORATORY_ID) | PASS (noop) |

**Manual SQL required (will SKIP in automated run):**

| Test | Depends On | Expected |
|------|-----------|----------|
| H03 | H03_SETUP_SQL.sql | FAIL (SEMANTIC_TYPE_INACTIVE) |
| H07 | H07_SETUP_SQL.sql | PASS (real change) |

## 5.4 Expected Harness Summary

**Automated run (no manual SQL):**

| Metric | Count |
|--------|-------|
| Total | 9 |
| PASS | 7 (H00, H01, H02, H04, H05, H06, H08) |
| FAIL | 0 |
| SKIP | 2 (H03, H07 — unresolved placeholders) |

**Full run (after manual SQL):**

| Metric | Count |
|--------|-------|
| Total | 9 |
| PASS | 9 |
| FAIL | 0 |
| SKIP | 0 |

## 5.5 H03_SETUP_SQL.sql Specification

```sql
-- H03 — Setup: Insert inactive semantic type registry entry
-- Run in Supabase SQL Editor AFTER H00-H02 pass.
-- Record the returned semantic_type_id as SEMANTIC_INACTIVE_ID.

INSERT INTO public.qxb_semantic_type_registry (
  key, description, active, created_by
) VALUES (
  'h03_test_inactive',
  'Phase 2C certification — inactive type for H03 test',
  false,
  'phase2c_cert'
)
RETURNING semantic_type_id;

-- Copy the returned UUID and set as SEMANTIC_INACTIVE_ID in the test harness
-- (or manually substitute in H03 test payload).
```

## 5.6 H07_SETUP_SQL.sql Specification

```sql
-- H07 — Setup: Get governance semantic_type_id
-- Run in Supabase SQL Editor BEFORE H07.
-- Record the returned semantic_type_id as SEMANTIC_GOVERNANCE_ID.

SELECT semantic_type_id, key, active
FROM public.qxb_semantic_type_registry
WHERE key = 'governance' AND active = true;

-- Copy the returned UUID and set as SEMANTIC_GOVERNANCE_ID.
```

## 5.7 Post-Test Cleanup

After H-series execution, the operator should:

1. **If H07 ran:** Revert KGB project semantic_type_id back to exploratory:

```sql
SELECT public.update_semantic_type(
  '668bd18f-4424-41e6-b2f9-393ecd2ec534'::uuid,
  (SELECT semantic_type_id FROM public.qxb_semantic_type_registry WHERE key = 'exploratory'),
  'H07 cleanup — revert to exploratory',
  NULL
);
```

2. **Deactivate H03 test entry:**

```sql
-- Deactivate test registry entry (registry entries must never be deleted)
UPDATE public.qxb_semantic_type_registry
SET active = false
WHERE key = 'h03_test_inactive';
```

## 5.8 Inactive Semantic Type Behavior Clarification

- Deactivating a semantic type (`active = false`) prevents future assignment.
- Existing artifacts referencing the inactive type remain valid.
- No automatic migration occurs.
- Migration or reassignment from inactive types is a future governance workflow (out of scope for Phase 3).

---

# 6. Deployment Sequence

| Step | Action | Prerequisite |
|------|--------|-------------|
| 1 | Deploy Gateway v59 (Normalize_Request + semantic_type_id forwarding) | None |
| 2 | Deploy Save v42 (Normalize + Validate + Lookup + Guard + DB_Insert_Spine) | Gateway v59 live |
| 3 | Deploy Update v38 (Check_Mutability + Switch_Update_Mode + RPC + Guard) | Gateway v59 live |
| 4 | Update Gateway EW nodes to reference Save v42 + Update v38 | Save v42 + Update v38 live |
| 5 | Run H-series automated tests (H00-H08, expect 7 PASS, 2 SKIP) | All workflows deployed |
| 6 | Run H03_SETUP_SQL, then rerun H03 manually | H-series automated run complete |
| 7 | Run H07_SETUP_SQL, then rerun H07 manually | H03 done |
| 8 | Write Canonical Payload v3 document | All tests pass |
| 9 | Update LIVE DDL header (v2.6, no schema change) | Documentation only |
| 10 | Update MEMORY.md (Gateway v59, Save v42, Update v38) | All complete |

---

# 7. Scope Confirmation — No Other Mutation Surface

| Surface | semantic_type_id Behavior | Change Required |
|---------|--------------------------|----------------|
| artifact.save INSERT (top-level) | Written from payload | YES (this spec) |
| artifact.save INSERT (non-top-level) | NULL | YES (this spec — reject if provided) |
| artifact.save UPDATE | Ignored | NO (not touched) |
| artifact.update tags-only | Not touched | NO |
| artifact.update extension | Blocked if present | YES (this spec — check #2.5) |
| artifact.update semantic_type (dedicated) | Changed via RPC | YES (this spec — new path) |
| artifact.promote | Not touched | NO |
| artifact.delete | Not touched | NO |
| artifact.restore | Not touched | NO |
| artifact.list_deleted | Not touched | NO |
| Direct SQL | Via `update_semantic_type()` RPC | Already deployed (Phase 1) |

**Confirmed:** No uncontrolled mutation path exists after this spec is implemented. The only write paths for `semantic_type_id` are:

1. Save INSERT (workflow-validated, registry-checked)
2. RPC `update_semantic_type()` (SECURITY DEFINER, atomic, fail-closed)

---

**End of Specification**
