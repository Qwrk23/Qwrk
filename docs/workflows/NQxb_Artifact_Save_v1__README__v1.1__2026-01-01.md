# NQxb_Artifact_Save_v1 Workflow

## Overview

This workflow implements the `artifact.save` operation for Qwrk Gateway v1. It handles both **INSERT** (create) and **UPDATE** operations for all 4 artifact types, maintaining the spine + extension architecture with **PATCH semantics**, **comprehensive validation**, and **immutability enforcement**.

## Trigger Type

- **Type**: Execute Workflow Trigger
- **Usage**: Call from other workflows or gateway
- **Action**: `artifact.save`

---

## Input Contract

### Required Fields (All Operations)

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "uuid (required)",
  "artifact_type": "string (required: project, journal, restart, snapshot)",
  "title": "string (required)"
}
```

### INSERT vs UPDATE Detection

The workflow automatically detects the operation based on `artifact_id`:
- **INSERT**: `artifact_id` is `null` or not provided
- **UPDATE**: `artifact_id` is provided (UUID)

### INSERT-Specific Required Fields

```json
{
  "owner_user_id": "uuid (required for INSERT, ignored for UPDATE)"
}
```

### Optional Spine Fields

```json
{
  "summary": "string",
  "priority": 1-5,
  "lifecycle_status": "string",
  "tags": {} (jsonb object, persisted to qxb_artifact),
  "content": {} (jsonb object, persisted to qxb_artifact),
  "parent_artifact_id": "uuid"
}
```

### Extension Fields (Type-Specific)

Extension fields are passed in the `extension` object:

#### Project Extension

```json
{
  "extension": {
    "lifecycle_stage": "seed|sapling|tree|retired (required for INSERT)",
    "operational_state": "active|paused|blocked|waiting (optional)",
    "state_reason": "string (optional)"
  }
}
```

#### Journal Extension

```json
{
  "extension": {
    "entry_text": "string (optional)",
    "payload": {} (optional jsonb object - NOT stringified)
  }
}
```

#### Restart Extension (INSERT ONLY - Immutable)

```json
{
  "extension": {
    "payload": {} (required jsonb object for INSERT - NOT stringified)
  }
}
```

#### Snapshot Extension (INSERT ONLY - Immutable)

```json
{
  "extension": {
    "payload": {} (required jsonb object for INSERT - NOT stringified)
  }
}
```

---

## Validation Rules

### Comprehensive Validation Gate

The workflow validates all requests **before** any database operations. Validation errors return immediately with a `VALIDATION_ERROR` envelope.

### INSERT Validation Rules

**All Types:**
- ✅ `gw_workspace_id` must be valid UUID
- ✅ `artifact_type` must be one of: project, journal, restart, snapshot
- ✅ `title` must be non-empty string
- ✅ `owner_user_id` must be valid UUID (required for INSERT)

**Project-Specific (INSERT):**
- ✅ `extension.lifecycle_stage` required (must be: seed, sapling, tree, or retired)

**Restart-Specific (INSERT):**
- ✅ `extension.payload` required (must be object, not string)

**Snapshot-Specific (INSERT):**
- ✅ `extension.payload` required (must be object, not string)

### UPDATE Validation Rules

**All Types:**
- ✅ `gw_workspace_id` must be valid UUID
- ✅ `artifact_id` must be valid UUID
- ✅ `artifact_type` must be one of: project, journal, restart, snapshot
- ✅ `title` must be non-empty string (if provided)
- ✅ **Immutability check**: restart and snapshot types **cannot** be updated

**No Required Extension Fields for UPDATE** - All extension fields are optional. PATCH semantics apply.

---

## PATCH Semantics for UPDATE

**Key Feature:** UPDATE operations only modify **explicitly provided fields**. Fields not included in the request are **preserved** from the existing artifact.

### How PATCH Works

1. **Field Tracking**: The workflow tracks which fields were explicitly provided using `'field' in request` checks
2. **Fetch Existing**: For UPDATE, the workflow fetches the current artifact state (both spine and extension)
3. **Merge Logic**: Provided fields overwrite existing values; omitted fields retain existing values
4. **No Null Overwriting**: Missing fields are **NOT** set to null

### PATCH Example

**Existing Project in Database:**
```json
{
  "artifact_id": "abc-123",
  "title": "Original Title",
  "summary": "Original summary",
  "priority": 3,
  "lifecycle_status": "active",
  "tags": {"category": "backend"},
  "content": {"notes": "Some notes"},
  "extension": {
    "lifecycle_stage": "seed",
    "operational_state": "active",
    "state_reason": "Just started"
  }
}
```

**UPDATE Request (Partial):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "workspace-uuid",
  "artifact_id": "abc-123",
  "artifact_type": "project",
  "title": "Updated Title",
  "priority": 5,
  "extension": {
    "lifecycle_stage": "sapling"
  }
}
```

**Resulting Artifact After UPDATE:**
```json
{
  "artifact_id": "abc-123",
  "title": "Updated Title",           // ✅ Updated (provided)
  "summary": "Original summary",       // ✅ Preserved (not provided)
  "priority": 5,                       // ✅ Updated (provided)
  "lifecycle_status": "active",        // ✅ Preserved (not provided)
  "tags": {"category": "backend"},     // ✅ Preserved (not provided)
  "content": {"notes": "Some notes"},  // ✅ Preserved (not provided)
  "extension": {
    "lifecycle_stage": "sapling",      // ✅ Updated (provided)
    "operational_state": "active",     // ✅ Preserved (not provided)
    "state_reason": "Just started"     // ✅ Preserved (not provided)
  }
}
```

### PATCH Applies to Both Spine and Extension

- **Spine fields** (title, summary, priority, tags, content, etc.): PATCH semantics
- **Extension fields** (lifecycle_stage, operational_state, entry_text, etc.): PATCH semantics

---

## Immutability Enforcement

### Immutable Artifact Types

**Restart** and **Snapshot** artifacts are **immutable** and follow insert-only semantics:

- ✅ **INSERT** allowed
- ❌ **UPDATE** blocked (returns error envelope)

### Why Immutable?

These types store point-in-time snapshots via the `payload` jsonb field. Allowing updates would violate their semantic purpose as historical records.

### Immutability Error Response

If attempting to UPDATE a restart or snapshot:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "IMMUTABILITY_ERROR",
    "message": "Artifact type 'snapshot' is immutable and cannot be updated. Only INSERT operations are allowed."
  }
}
```

---

## Input Examples

### Example 1: INSERT New Project

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "project",
  "title": "New Feature Implementation",
  "summary": "Implement the user dashboard",
  "priority": 3,
  "tags": {"team": "frontend", "sprint": "2026-01"},
  "content": {"spec_url": "https://docs.example.com/dashboard"},
  "extension": {
    "lifecycle_stage": "seed",
    "operational_state": "active"
  }
}
```

### Example 2: UPDATE Existing Project (PATCH Semantics)

**Only updates title and lifecycle_stage. All other fields preserved.**

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
  "artifact_type": "project",
  "title": "Updated Feature Implementation",
  "extension": {
    "lifecycle_stage": "sapling"
  }
}
```

### Example 3: UPDATE Project with Tags and Content

**Demonstrates tags and content persistence.**

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
  "artifact_type": "project",
  "title": "Dashboard with Analytics",
  "tags": {"team": "frontend", "sprint": "2026-02", "status": "in-progress"},
  "content": {"spec_url": "https://docs.example.com/dashboard-v2", "design_url": "https://figma.com/..."}
}
```

### Example 4: INSERT New Journal Entry

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "journal",
  "title": "Daily Standup Notes",
  "parent_artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
  "extension": {
    "entry_text": "Completed API integration. Next: frontend work.",
    "payload": {"mood": "productive", "blockers": []}
  }
}
```

### Example 5: INSERT Snapshot (Immutable)

**Note: payload is stored as jsonb object, NOT stringified.**

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "snapshot",
  "title": "Project State - 2026-01-01",
  "parent_artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
  "extension": {
    "payload": {
      "completed_tasks": 15,
      "pending_tasks": 7,
      "blockers": [],
      "velocity": 2.3
    }
  }
}
```

### Example 6: INSERT Restart (Immutable)

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "restart",
  "title": "Weekly Reset - 2026-01-06",
  "extension": {
    "payload": {
      "focus_areas": ["reduce technical debt", "improve test coverage"],
      "reflections": "Last week was productive but need better planning"
    }
  }
}
```

---

## Response Format

The workflow calls `NQxb_Artifact_Query_v1` at the end to return the complete saved artifact.

### Success Response

```json
{
  "artifact_id": "uuid",
  "workspace_id": "uuid",
  "owner_user_id": "uuid",
  "artifact_type": "project",
  "title": "...",
  "summary": "...",
  "priority": 3,
  "lifecycle_status": null,
  "tags": {"team": "frontend"},
  "content": {"spec_url": "https://..."},
  "parent_artifact_id": null,
  "version": 1,
  "deleted_at": null,
  "created_at": "2026-01-01T12:00:00Z",
  "updated_at": "2026-01-01T12:00:00Z",

  "extension": {
    "lifecycle_stage": "seed",
    "operational_state": "active",
    "state_reason": null
  }
}
```

### Error Response Formats

All errors follow a consistent envelope structure:

#### 1. Validation Error

Returned when required fields are missing or invalid:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "validation_errors": [
      {
        "field": "gw_workspace_id",
        "reason": "required field missing"
      },
      {
        "field": "extension.lifecycle_stage",
        "reason": "required for project INSERT"
      }
    ]
  }
}
```

#### 2. Immutability Error

Returned when attempting to UPDATE restart or snapshot:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "IMMUTABILITY_ERROR",
    "message": "Artifact type 'snapshot' is immutable and cannot be updated. Only INSERT operations are allowed."
  }
}
```

#### 3. NOT_FOUND Error

Returned when UPDATE references a non-existent artifact_id:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "NOT_FOUND",
    "message": "Artifact not found for UPDATE operation",
    "artifact_id": "fake-uuid-that-does-not-exist"
  }
}
```

---

## Workflow Logic Flow

```
1. NQxb_Artifact_Save_v1__In (Trigger)
   ↓
2. NQxb_Artifact_Save_v1__Normalize_Request
   - Extracts all fields
   - Detects INSERT vs UPDATE (is_update flag)
   - Tracks which fields were explicitly provided (_provided_fields)
   ↓
3. NQxb_Artifact_Save_v1__Validate_Request
   - Validates required fields per operation type
   - Validates type-specific extension requirements
   - Returns VALIDATION_ERROR envelope if invalid
   ↓
4. NQxb_Artifact_Save_v1__Switch_InsertOrUpdate
   ├── UPDATE Path (output 0)
   │   ↓
   │   5a. Check_Immutability (returns IMMUTABILITY_ERROR if restart/snapshot)
   │   ↓
   │   6a. Fetch_Existing_Spine (SELECT from qxb_artifact)
   │   ↓
   │   7a. Merge_PATCH_Spine (merge provided fields with existing)
   │   ↓
   │   8a. DB_Update_Spine (UPDATE qxb_artifact with merged data)
   │   ↓
   │   9a. Switch_Type_For_Update
   │   ├── Project Path:
   │   │   ↓
   │   │   10a-p1. Fetch_Existing_Project_Extension
   │   │   ↓
   │   │   10a-p2. Merge_PATCH_Project_Extension
   │   │   ↓
   │   │   10a-p3. DB_Update_Project_Extension
   │   │
   │   └── Journal Path:
   │       ↓
   │       10a-j1. Fetch_Existing_Journal_Extension
   │       ↓
   │       10a-j2. Merge_PATCH_Journal_Extension
   │       ↓
   │       10a-j3. DB_Update_Journal_Extension
   │
   └── INSERT Path (output 1)
       ↓
       5b. DB_Insert_Spine (INSERT qxb_artifact, returns new artifact_id)
       ↓
       6b. Switch_Type_For_Insert
       ├── Project → DB_Insert_Project_Extension
       ├── Journal → DB_Insert_Journal_Extension
       ├── Restart → DB_Insert_Restart_Extension
       └── Snapshot → DB_Insert_Snapshot_Extension
   ↓
7. Prepare_Query_Call (extracts artifact_id for query)
   ↓
8. Call_Query_To_Return_Artifact (executes NQxb_Artifact_Query_v1)
   ↓
9. Returns complete merged artifact
```

---

## Key Features

### 1. **Automatic INSERT/UPDATE Detection**

No need to specify operation type - workflow detects based on `artifact_id` presence.

### 2. **PATCH Semantics for UPDATE (Phase 3 ✅)**

UPDATE operations only modify explicitly provided fields:
- Tracks field presence via `_provided_fields` object
- Fetches existing artifact state before update
- Merges provided fields with existing values
- Preserves omitted fields (no null overwriting)

**Applies to both spine and extension tables.**

### 3. **Comprehensive Validation (Phase 2 ✅)**

Validates all requests **before** database operations:
- Required fields per operation type
- UUID format validation
- Type-specific extension requirements
- Returns standardized `VALIDATION_ERROR` envelope

### 4. **Immutability Enforcement**

Snapshot and Restart artifacts are **immutable**:
- ✅ INSERT allowed
- ❌ UPDATE blocked (returns `IMMUTABILITY_ERROR` envelope)

This aligns with the schema design where these types store immutable `payload` jsonb fields.

### 5. **Tags and Content Persistence**

`tags` and `content` fields are properly persisted to `qxb_artifact`:
- Stored as **jsonb** objects (not stringified)
- Support PATCH semantics on UPDATE
- Queryable via PostgreSQL jsonb operators

### 6. **JSONB Payload Handling**

Extension payloads (journal, restart, snapshot) are stored as **native jsonb objects**:
- ❌ **NOT** stringified with `JSON.stringify()`
- ✅ Passed directly to Supabase as objects
- Maintains queryability and schema flexibility

### 7. **NOT_FOUND Detection (Phase 2 ✅)**

UPDATE operations detect non-existent artifacts:
- Fetches existing artifact before update
- Returns `NOT_FOUND` envelope if artifact doesn't exist
- Prevents silent failures

### 8. **Spine + Extension Coordination**

The workflow maintains referential integrity:
- **INSERT**: Creates spine first, then extension (using returned artifact_id)
- **UPDATE**: Fetches existing → merges PATCH → updates both spine and extension

### 9. **Query Integration**

After save, the workflow calls `NQxb_Artifact_Query_v1` to:
- Validate the save succeeded
- Return the complete merged artifact
- Ensure consistent response format

### 10. **Standardized Error Envelopes (Phase 2 ✅)**

All errors follow consistent format:
- `ok: false` flag
- `_gw_route: "error"` for gateway routing
- `error.code` for programmatic handling
- `error.message` for human-readable description

---

## Operation Matrix

| Artifact Type | INSERT | UPDATE | Notes |
|--------------|--------|--------|-------|
| **project** | ✅ | ✅ | Full CRUD support with PATCH semantics |
| **journal** | ✅ | ✅ | Owner-private (enforced by RLS), PATCH semantics |
| **restart** | ✅ | ❌ | Immutable - UPDATE returns IMMUTABILITY_ERROR |
| **snapshot** | ✅ | ❌ | Immutable - UPDATE returns IMMUTABILITY_ERROR |

---

## Important Notes

### RLS Policy Compliance

- **INSERT**: User must be a member of the workspace
- **UPDATE**: User must be owner OR admin (except journals = owner-only)
- **Journal**: Always owner-private regardless of operation
- RLS policies are enforced at the database level (Supabase RLS)

### owner_user_id Behavior

- **INSERT**: `owner_user_id` is **required** and set during creation
- **UPDATE**: `owner_user_id` is **immutable** (not updated, ignored if provided)

### Version Control

The spine table has a `version` field (currently defaults to 1). Future enhancements could:
- Increment version on UPDATE
- Store version history
- Implement optimistic locking

### JSONB Field Storage

The following fields are stored as **native jsonb** in PostgreSQL:
- `tags` (qxb_artifact spine table)
- `content` (qxb_artifact spine table)
- `payload` (qxb_artifact_journal, qxb_artifact_restart, qxb_artifact_snapshot)

**Do NOT stringify these fields in requests.** Pass them as JavaScript objects.

---

## Performance Considerations

### Database Operations per Save

**INSERT:**
- 1 × INSERT qxb_artifact (returns artifact_id)
- 1 × INSERT qxb_artifact_{type}
- 1 × SELECT qxb_artifact (via Query workflow)
- 1 × SELECT qxb_artifact_{type} (via Query workflow)
- **Total: 4 DB calls**

**UPDATE:**
- 1 × SELECT qxb_artifact (fetch existing spine for PATCH merge)
- 1 × UPDATE qxb_artifact (with merged data)
- 1 × SELECT qxb_artifact_{type} (fetch existing extension for PATCH merge)
- 1 × UPDATE qxb_artifact_{type} (with merged data)
- 1 × SELECT qxb_artifact (via Query workflow)
- 1 × SELECT qxb_artifact_{type} (via Query workflow)
- **Total: 6 DB calls**

**UPDATE (with NOT_FOUND):**
- 1 × SELECT qxb_artifact (fetch existing, returns empty)
- Workflow terminates early with NOT_FOUND error
- **Total: 1 DB call**

### Why More DB Calls for UPDATE?

PATCH semantics require fetching existing values to merge with provided fields. This is the trade-off for preventing accidental null overwrites.

### Optimization Opportunities

1. **Database Function**: Implement PATCH merge logic as a PostgreSQL function (reduce round trips)
2. **Skip Query Call**: Return DB write result directly (loses merge logic consistency)
3. **Batch Saves**: Add support for array of artifacts
4. **Event Log**: Add automatic event creation (1 additional INSERT)

---

## Error Handling

### Validation Errors

The workflow validates requests **before** database operations and returns:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "validation_errors": [...]
  }
}
```

**Validation Checks:**
- Required fields per operation type
- UUID format for workspace_id, artifact_id, owner_user_id
- artifact_type must be valid (project, journal, restart, snapshot)
- Type-specific extension requirements
- title must be non-empty string

### Immutability Errors

Attempting to UPDATE restart or snapshot returns:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "IMMUTABILITY_ERROR",
    "message": "Artifact type 'snapshot' is immutable..."
  }
}
```

### NOT_FOUND Errors

UPDATE on non-existent artifact_id returns:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "NOT_FOUND",
    "message": "Artifact not found for UPDATE operation",
    "artifact_id": "..."
  }
}
```

### Database Errors

Database constraint violations or RLS policy denials will return Supabase errors:
- **RLS Policy Denial**: User lacks permission (not workspace member, not owner, etc.)
- **Foreign Key Violation**: parent_artifact_id references non-existent artifact
- **Unique Constraint Violation**: Depends on future unique indexes

---

## Testing Scenarios

### Test 1: INSERT New Project (Valid)

```json
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","owner_user_id":"c52c7a57-74ad-433d-a07c-4dcac1778672","artifact_type":"project","title":"Test Project","extension":{"lifecycle_stage":"seed"}}
```

**Expected:** New project created with artifact_id returned.

### Test 2: INSERT Project Missing lifecycle_stage (Invalid)

```json
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","owner_user_id":"c52c7a57-74ad-433d-a07c-4dcac1778672","artifact_type":"project","title":"Test Project","extension":{}}
```

**Expected:** VALIDATION_ERROR - "extension.lifecycle_stage required for project INSERT"

### Test 3: UPDATE Project with PATCH Semantics

**Existing project has: title="Old", summary="Original summary", priority=3**

```json
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_id":"668bd18f-4424-41e6-b2f9-393ecd2ec534","artifact_type":"project","title":"New Title"}
```

**Expected:** Only title updated to "New Title". Summary and priority preserved from existing artifact.

### Test 4: INSERT Snapshot (Valid)

```json
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","owner_user_id":"c52c7a57-74ad-433d-a07c-4dcac1778672","artifact_type":"snapshot","title":"Snapshot","extension":{"payload":{"data":"value"}}}
```

**Expected:** Snapshot created with payload stored as jsonb object.

### Test 5: Attempt UPDATE Snapshot (Invalid - Immutability)

```json
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_id":"snapshot-uuid","artifact_type":"snapshot","title":"Updated"}
```

**Expected:** IMMUTABILITY_ERROR - "Artifact type 'snapshot' is immutable and cannot be updated."

### Test 6: UPDATE Non-existent Artifact (NOT_FOUND)

```json
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_id":"00000000-0000-0000-0000-000000000000","artifact_type":"project","title":"Ghost"}
```

**Expected:** NOT_FOUND - "Artifact not found for UPDATE operation"

### Test 7: UPDATE Project with tags and content

```json
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_id":"668bd18f-4424-41e6-b2f9-393ecd2ec534","artifact_type":"project","title":"Tagged Project","tags":{"sprint":"2026-01","priority":"high"},"content":{"notes":"Important project"}}
```

**Expected:** Project updated with tags and content persisted as jsonb to qxb_artifact.

### Test 8: INSERT Restart with Complex Payload

```json
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","owner_user_id":"c52c7a57-74ad-433d-a07c-4dcac1778672","artifact_type":"restart","title":"Weekly Reset","extension":{"payload":{"focus_areas":["goal1","goal2"],"reflections":"Good week"}}}
```

**Expected:** Restart created with payload stored as jsonb object (NOT stringified).

---

## Migration from Manual DB Operations

**Before (Direct DB - Overwrites with null):**

```javascript
// UPDATE overwrites all fields
await supabase.from('qxb_artifact').update({
  title: "New Title",
  summary: null,  // ❌ Accidentally overwrites existing summary
  priority: null  // ❌ Accidentally overwrites existing priority
}).eq('artifact_id', id);
```

**After (Save Workflow - PATCH Semantics):**

```javascript
const result = await callWorkflow('NQxb_Artifact_Save_v1', {
  gw_action: "artifact.save",
  gw_workspace_id: workspaceId,
  artifact_id: id,
  artifact_type: "project",
  title: "New Title"
  // ✅ summary and priority preserved automatically
});
// Returns complete merged artifact with validation and error handling
```

---

## Compatibility with Gateway Hard Rules

✅ **Expression syntax**: No leading `=` in expressions
✅ **Node naming**: All nodes use `NQxb_Artifact_Save_v1__` prefix
✅ **Switch trim safety**: All artifact_type comparisons use `.trim()`
✅ **No schema guessing**: Uses known table schemas
✅ **JSONB handling**: Objects passed directly, not stringified
✅ **Flatten compliance**: Direct field references (no flatten node needed for INSERT)

---

## Implemented Features (Phase 2 & 3)

### ✅ Phase 2 (Validation & Safety) - COMPLETE

- ✅ Required field validation before DB operations
- ✅ Extension schema validation per artifact type
- ✅ Existence check for UPDATE operations (NOT_FOUND detection)
- ✅ Standardized error response envelope

### ✅ Phase 3 (Advanced Features) - PARTIAL

- ✅ **PATCH semantics for UPDATE** (only update provided fields)
- ⏳ Version increment and history tracking (not implemented)
- ⏳ Automatic event log creation (not implemented)
- ⏳ Batch save operations (not implemented)
- ⏳ Optimistic locking with version check (not implemented)

---

## Future Enhancements

### Phase 4 (Optimization)

- [ ] Database function for PATCH merge (reduce DB round trips from 6 to 2 for UPDATE)
- [ ] Skip Query call option (direct return for performance)
- [ ] Conditional extension UPDATE (only if extension fields changed)

### Phase 5 (Advanced Features)

- [ ] Version increment on UPDATE (auto-increment version field)
- [ ] Version history tracking (store previous versions in audit table)
- [ ] Automatic event log creation (1 additional INSERT to event table)
- [ ] Batch save operations (accept array of artifacts)
- [ ] Optimistic locking (check version before update, fail if mismatch)

---

## Version History

- **v1.0** (2026-01-01): Initial implementation
  - INSERT and UPDATE operations
  - All 4 artifact types supported
  - Immutability enforcement (error throwing)
  - Query integration for response

- **v1.1** (2026-01-01): Phase 2 & 3 Improvements
  - ✅ **PATCH semantics for UPDATE** (field tracking, fetch existing, merge logic)
  - ✅ **Comprehensive validation** (gate before DB operations)
  - ✅ **Standardized error envelopes** (VALIDATION_ERROR, IMMUTABILITY_ERROR, NOT_FOUND)
  - ✅ **tags and content persistence** to qxb_artifact
  - ✅ **JSONB payload handling** (no stringification)
  - ✅ **NOT_FOUND detection** for UPDATE operations
  - ✅ **Immutability returns error envelope** (not JavaScript error)
  - ✅ **Simplified merge flow** (removed complex multi-branch merge node)

---

## Related Workflows

- **NQxb_Artifact_Query_v1**: Called at the end to return saved artifact
- **NQxb_Artifact_List_v1**: Can be used after save to refresh lists
- **NQxb_Gateway_v1**: Parent gateway that routes to save workflow

---

## Quick Reference: Field Persistence

| Field | Table | Type | INSERT | UPDATE (PATCH) |
|-------|-------|------|--------|----------------|
| artifact_id | qxb_artifact | uuid | Auto-generated | Immutable |
| workspace_id | qxb_artifact | uuid | Required | Immutable |
| owner_user_id | qxb_artifact | uuid | Required | Immutable |
| artifact_type | qxb_artifact | text | Required | Immutable |
| title | qxb_artifact | text | Required | Optional (PATCH) |
| summary | qxb_artifact | text | Optional | Optional (PATCH) |
| priority | qxb_artifact | integer | Optional | Optional (PATCH) |
| lifecycle_status | qxb_artifact | text | Optional | Optional (PATCH) |
| **tags** | qxb_artifact | **jsonb** | Optional | Optional (PATCH) |
| **content** | qxb_artifact | **jsonb** | Optional | Optional (PATCH) |
| parent_artifact_id | qxb_artifact | uuid | Optional | Optional (PATCH) |
| version | qxb_artifact | integer | Default: 1 | Not updated (yet) |
| lifecycle_stage | qxb_artifact_project | text | Required | Optional (PATCH) |
| operational_state | qxb_artifact_project | text | Optional | Optional (PATCH) |
| state_reason | qxb_artifact_project | text | Optional | Optional (PATCH) |
| entry_text | qxb_artifact_journal | text | Optional | Optional (PATCH) |
| **payload** (journal) | qxb_artifact_journal | **jsonb** | Optional | Optional (PATCH) |
| **payload** (restart) | qxb_artifact_restart | **jsonb** | **Required** | Immutable (no UPDATE) |
| **payload** (snapshot) | qxb_artifact_snapshot | **jsonb** | **Required** | Immutable (no UPDATE) |

**Note:** All **jsonb** fields are stored as native objects, NOT stringified.
