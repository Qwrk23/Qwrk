# NQxb_Artifact_List_v1 Workflow — Phase 3 Contract

## Overview

This workflow implements the `artifact.list` operation for the Qwrk Gateway v1 with **Phase 3 semantics**:

- **Base-only by default**: Returns spine fields only from `qxb_artifact` table
- **Optional hydration**: Set `selector.hydrate: true` to include type-specific extension fields
- **Flexible filtering**: Filter by artifact_type, parent_artifact_id, or list all artifacts in a workspace
- **Pagination support**: limit (default 50, max 100) and offset
- **Phase 3 response envelope**: Uses `items` + `meta` structure

---

## Trigger Type

- **Type**: Execute Workflow Trigger
- **Usage**: Called from other workflows or gateway
- **Action**: `artifact.list`

---

## Request Schema

### Required Fields

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "uuid (required)"
}
```

### Optional Selector Fields

```json
{
  "selector": {
    "artifact_type": "string (optional: project, journal, restart, snapshot)",
    "parent_artifact_id": "uuid (optional)",
    "limit": "number (optional, default 50, max 100)",
    "offset": "number (optional, default 0)",
    "hydrate": "boolean (optional, default false)"
  }
}
```

**Selector Behavior:**

- **artifact_type**: If omitted or empty, lists ALL artifact types in the workspace
- **parent_artifact_id**: If provided, filters to child artifacts only
- **limit**: Controls max results returned (capped at 100)
- **offset**: For pagination, skips first N results
- **hydrate**: Controls whether extension fields are included

---

## Request Examples

### Example 1: Base-Only List (No Hydration)

Returns spine fields only (fastest):

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "artifact_type": "project",
    "limit": 10
  }
}
```

**Result**: Returns up to 10 project artifacts with spine fields only (artifact_id, workspace_id, artifact_type, title, summary, priority, lifecycle_status, tags, content, parent_artifact_id, version, owner_user_id, created_at, updated_at, deleted_at).

### Example 2: Hydrated List (With Extensions)

Returns spine + type-specific extension fields:

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "artifact_type": "project",
    "limit": 10,
    "hydrate": true
  }
}
```

**Result**: Returns up to 10 project artifacts with spine fields PLUS project extension fields (lifecycle_stage, operational_state, state_reason).

### Example 3: List All Types (No Filter)

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "limit": 50
  }
}
```

**Result**: Returns up to 50 artifacts of ANY type in the workspace.

### Example 4: List Child Artifacts (Thicket Pattern)

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "parent_artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
    "limit": 20
  }
}
```

**Result**: Returns up to 20 child artifacts under the specified parent.

### Example 5: Paginated Query

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "artifact_type": "journal",
    "limit": 25,
    "offset": 25
  }
}
```

**Result**: Returns journals 26-50 (second page).

---

## Response Schema

### Success Response (Base-Only)

```json
{
  "ok": true,
  "_gw_route": "ok",
  "items": [
    {
      "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
      "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
      "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
      "artifact_type": "project",
      "title": "Feature Implementation",
      "summary": "Implement the user dashboard",
      "priority": 3,
      "lifecycle_status": null,
      "tags": {},
      "content": {},
      "parent_artifact_id": null,
      "version": 1,
      "deleted_at": null,
      "created_at": "2026-01-01T10:00:00Z",
      "updated_at": "2026-01-01T10:00:00Z"
    }
  ],
  "meta": {
    "count": 1,
    "limit": 10,
    "offset": 0
  }
}
```

### Success Response (Hydrated)

```json
{
  "ok": true,
  "_gw_route": "ok",
  "items": [
    {
      "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
      "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
      "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
      "artifact_type": "project",
      "title": "Feature Implementation",
      "summary": "Implement the user dashboard",
      "priority": 3,
      "lifecycle_status": null,
      "tags": {},
      "content": {},
      "parent_artifact_id": null,
      "version": 1,
      "deleted_at": null,
      "created_at": "2026-01-01T10:00:00Z",
      "updated_at": "2026-01-01T10:00:00Z",

      "lifecycle_stage": "sapling",
      "operational_state": "active",
      "state_reason": null
    }
  ],
  "meta": {
    "count": 1,
    "limit": 10,
    "offset": 0
  }
}
```

**Note**: Extension fields are merged at the root level, not nested. The spine field `artifact_type` is ALWAYS populated and comes from the spine table.

### Validation Error Response

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "gw_workspace_id is required for artifact.list operation",
    "details": {
      "missing_field": "gw_workspace_id",
      "received_value": null
    }
  }
}
```

---

## Filtering and Pagination Behavior

### Filtering

**workspace_id** (required):
- Always filters by the provided workspace_id
- Validation error returned if missing

**artifact_type** (optional):
- If provided and non-empty: filters to that specific type
- If omitted or empty string: returns ALL types
- Trim-safe: whitespace is normalized

**parent_artifact_id** (optional):
- If provided: filters to artifacts where `parent_artifact_id = <value>`
- If omitted: no parent filter applied
- Useful for thicket/tree queries

### Pagination

**Implementation**: Manual (code-based slicing)

Due to limitations in the n8n Supabase node, pagination is implemented in the `Apply_Filters_And_Pagination` node using JavaScript:

1. Fetch all matching artifacts from DB (Supabase node applies workspace_id filter + limit)
2. Apply artifact_type and parent_artifact_id filters in code
3. Slice results using `items.slice(offset, offset + limit)`
4. Return paginated subset

**Defaults**:
- `limit`: 50 (max 100)
- `offset`: 0 (min 0)

**Meta Response**:
- `meta.count`: Number of items returned in current page
- `meta.limit`: Applied limit value
- `meta.offset`: Applied offset value

**Known Limitation**: The workflow does NOT return a total count of all matching artifacts (only the count of returned items). A future enhancement could add a separate COUNT query.

---

## Workflow Node Map

### Key Nodes and Flow

```
1. NQxb_Artifact_List_v1__In
   ↓ Receives request payload

2. NQxb_Artifact_List_v1__Normalize_Request
   ↓ Extracts and validates selector fields
   ↓ Sets defaults (limit: 50, offset: 0, hydrate: false)

3. NQxb_Artifact_List_v1__Validate_Request
   ↓ Checks workspace_id is present
   ↓ Returns VALIDATION_ERROR if missing

4. NQxb_Artifact_List_v1__Build_Filters
   ↓ Prepares dynamic filter conditions

5. NQxb_Artifact_List_v1__DB_List_Artifacts_Spine
   ↓ Queries qxb_artifact table (spine only)

6. NQxb_Artifact_List_v1__Apply_Filters_And_Pagination
   ↓ Applies artifact_type, parent_artifact_id filters
   ↓ Slices results by limit + offset

7. NQxb_Artifact_List_v1__If_Hydrate
   ├─ FALSE (hydrate=false or missing)
   │  ↓
   │  8a. Format_Base_Response
   │     Returns spine-only items
   │
   └─ TRUE (hydrate=true)
      ↓
      8b. Switch_ArtifactType
         ├─ Project → Get_Project_Extension → Merge_Project
         ├─ Journal → Get_Journal_Extension → Merge_Journal
         ├─ Restart → Get_Restart_Extension → Merge_Restart
         └─ Snapshot → Get_Snapshot_Extension → Merge_Snapshot
         ↓
      9. Combine_Hydrated_Results
         ↓
      10. Format_Hydrated_Response
          Returns merged spine + extension items
```

### Critical Nodes

**NQxb_Artifact_List_v1__If_Hydrate**:
- Gates hydration logic
- Checks: `$node['NQxb_Artifact_List_v1__Normalize_Request'].json.hydrate === true`
- TRUE output → hydration path
- FALSE output → base-only path

**Merge Nodes (Merge_Project, Merge_Journal, etc.)**:
- Preserve spine fields using `$input.item.json` (before extension query)
- Merge extension fields from `$json` (current node output)
- **CRITICAL**: Spine fields (artifact_type, artifact_id, etc.) take precedence
- Prevents `artifact_type: ''` bug by using explicit spine preservation

**Format_Base_Response / Format_Hydrated_Response**:
- Both use Phase 3 envelope: `{ ok, _gw_route, items, meta }`
- Remove internal metadata (`_list_meta`, `_gw_debug`)
- Calculate meta.count from returned items

---

## Canonical Field Names

The workflow uses **Kernel v1 canonical schema** field names:

- Spine table: `qxb_artifact`
- Spine field for lifecycle: **`lifecycle_status`** (text, nullable)
- Project extension field: **`lifecycle_stage`** (enum: seed, sapling, tree, retired)

**Important**: The spine table uses `lifecycle_status` (generic text field), while the project extension table uses `lifecycle_stage` (specific enum). Both are surfaced in hydrated responses:

- `lifecycle_status` from spine (may be null)
- `lifecycle_stage` from project extension (required for projects)

---

## Pinned Data Note

This workflow includes **pinned sample data** for testing:

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "artifact_type": "project",
    "limit": 10
  }
}
```

**IMPORTANT**: The pinned data MUST be preserved byte-for-byte when importing/exporting the workflow. Do not modify or remove pinned data.

---

## Manual Test Checklist

Execute these tests to validate Phase 3 contract compliance:

### ✅ Test 1: Base-Only Returns Spine Fields with artifact_type Populated

**Request**:
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "artifact_type": "project",
    "limit": 5
  }
}
```

**Expected**:
- Response has `items` array
- Each item has `artifact_type: "project"` (NOT empty string)
- Each item has spine fields: artifact_id, workspace_id, title, summary, priority, lifecycle_status, tags, content, parent_artifact_id, version, owner_user_id, created_at, updated_at
- NO extension fields (lifecycle_stage, operational_state)
- `meta.count` matches items length
- `meta.limit: 5, meta.offset: 0`

---

### ✅ Test 2: Hydrate=true Returns Merged Objects with artifact_type

**Request**:
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "artifact_type": "project",
    "limit": 5,
    "hydrate": true
  }
}
```

**Expected**:
- Response has `items` array
- Each item has `artifact_type: "project"` (NOT empty string)
- Each item has spine fields PLUS extension fields:
  - `lifecycle_stage` (from qxb_artifact_project)
  - `operational_state` (from qxb_artifact_project)
  - `state_reason` (from qxb_artifact_project)
- Extension fields are at root level (not nested)

---

### ✅ Test 3: lifecycle_status Appears (Not lifecycle_stage in Base)

**Request**:
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "artifact_type": "project"
  }
}
```

**Expected (Base-Only)**:
- Each item has `lifecycle_status` field (from spine, may be null)
- NO `lifecycle_stage` field in base-only mode

**Request (Hydrated)**:
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "artifact_type": "project",
    "hydrate": true
  }
}
```

**Expected (Hydrated)**:
- Each item has `lifecycle_status` (from spine)
- Each item has `lifecycle_stage` (from project extension)
- Both fields coexist

---

### ✅ Test 4: Limit/Offset Affect Returned Items and Meta

**Request (Page 1)**:
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "limit": 3,
    "offset": 0
  }
}
```

**Expected**:
- `items` length ≤ 3
- `meta.limit: 3, meta.offset: 0`
- `meta.count` matches items.length

**Request (Page 2)**:
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "limit": 3,
    "offset": 3
  }
}
```

**Expected**:
- Different items than page 1
- `meta.limit: 3, meta.offset: 3`

---

### ✅ Test 5: Missing workspace_id Returns VALIDATION_ERROR

**Request**:
```json
{
  "gw_action": "artifact.list",
  "selector": {
    "artifact_type": "project"
  }
}
```

**Expected**:
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "gw_workspace_id is required for artifact.list operation",
    "details": {
      "missing_field": "gw_workspace_id",
      "received_value": null
    }
  }
}
```

---

## Compatibility with Gateway Hard Rules

✅ **Expression syntax**: NO leading `=` in expressions (n8n adds automatically)
✅ **Supabase flattening**: Manual code-based filtering (Build_Filters, Apply_Filters_And_Pagination)
✅ **Node naming**: All nodes use `NQxb_Artifact_List_v1__` prefix
✅ **Switch trim safety**: All artifact_type comparisons use `.trim()`
✅ **No schema guessing**: Uses verified Kernel v1 schema from SQL bundle
✅ **Spine preservation**: Merge logic explicitly preserves spine fields

---

## Known Limitations

1. **Pagination is manual**: Supabase node limitations require code-based slicing
2. **No total count**: Response does not include total matching artifacts (only returned count)
3. **Fetch limit**: Currently fetches up to `limit` rows from DB, then filters/slices
   - For large workspaces, consider adding a hard fetch limit in the DB node
4. **No sorting**: Results return in DB default order (creation order typically)
   - Future enhancement: Add `selector.sort` field

---

## Future Enhancements

### Phase 4 Candidates

- [ ] Add `selector.sort` (e.g., `created_at DESC`, `title ASC`)
- [ ] Add total count query (separate COUNT(*) query)
- [ ] Support additional filters: `lifecycle_status`, `priority`, `tags`
- [ ] Optimize DB query to use native Supabase filters instead of code-based
- [ ] Add cursor-based pagination for large datasets
- [ ] Support multi-type hydration when artifact_type filter is omitted

---

## Version History

- **v1.0** (2026-01-01): Initial implementation with always-hydrate behavior
- **v1.1** (2026-01-01): **Phase 3 update**
  - Added base-only mode (default)
  - Added `selector.hydrate` flag
  - Changed response envelope to `items + meta`
  - Made `artifact_type` optional (list all types)
  - Added `parent_artifact_id` filter support
  - Fixed artifact_type preservation in merge logic
  - Added validation for workspace_id

---

## Related Workflows

- **NQxb_Artifact_Query_v1**: Query single artifact by ID
- **NQxb_Artifact_Save_v1**: Create or update artifacts
- **NQxb_Gateway_v1**: Parent gateway that routes to list workflow
