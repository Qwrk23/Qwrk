# NQxb_Gateway_v1 — Unified Artifact API Gateway

**Version**: v1.3 (artifact.save enabled)
**Date**: 2026-01-04
**Status**: Active (Production)
**Endpoint**: `POST https://n8n.halosparkai.com/webhook/nqxb/gateway/v1`

---

## Overview

NQxb_Gateway_v1 is the **unified API gateway** for all artifact operations in the Qwrk Kernel. It provides a single webhook endpoint that accepts standardized Gateway envelope requests and routes them to specialized subworkflows for execution.

**Key Features:**
- Single webhook endpoint for all artifact operations
- Standardized request/response envelope format
- MVP owner-only workspace enforcement
- Action and artifact type allow-listing
- Detailed validation and error handling
- Automatic routing to specialized subworkflows

---

## Supported Operations

### 1. artifact.query ✅
**Purpose**: Fetch a single artifact by ID
**Subworkflow**: `NQxb_Artifact_Query_v1`
**Status**: Stable (KGB-tested)

### 2. artifact.list ✅
**Purpose**: List artifacts with filtering and pagination
**Subworkflow**: `NQxb_Artifact_List_v1`
**Status**: Stable (KGB-tested)

### 3. artifact.save ✅
**Purpose**: Save (insert) new artifacts
**Subworkflow**: `NQxb_Artifact_Save_v1`
**Status**: Active (INSERT only; UPDATE not yet implemented)
**Added**: 2026-01-04

---

## Request Envelope Format

### Common Fields (All Actions)

```json
{
  "gw_action": "artifact.query | artifact.list | artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project | journal | restart | snapshot"
}
```

### artifact.query (Get Single Artifact)

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534"
}
```

**Required Fields:**
- `gw_action`: Must be `"artifact.query"`
- `gw_workspace_id`: UUID (MVP locked to owner workspace)
- `artifact_type`: One of `["project", "journal", "restart", "snapshot"]`
- `artifact_id`: UUID of artifact to retrieve

---

### artifact.list (List Artifacts)

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "selector": {
    "limit": 50,
    "offset": 0,
    "sort_by": "created_at",
    "sort_order": "desc",
    "filters": {
      "lifecycle_status": "active",
      "tags": ["important"]
    }
  }
}
```

**Required Fields:**
- `gw_action`: Must be `"artifact.list"`
- `gw_workspace_id`: UUID (MVP locked to owner workspace)
- `artifact_type`: One of `["project", "journal", "restart", "snapshot"]`

**Optional Fields:**
- `selector.limit`: 1-100 (default: 50)
- `selector.offset`: Starting index (default: 0)
- `selector.sort_by`: Field to sort by (default: `created_at`)
- `selector.sort_order`: `"asc"` or `"desc"` (default: `desc`)
- `selector.filters`: JSONB filter criteria

---

### artifact.save (Save New Artifact)

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "project",
  "title": "New Project Title",
  "summary": "Project description",
  "tags": ["tag1", "tag2"],
  "extension": {
    "lifecycle_stage": "seed",
    "operational_state": {
      "custom_field": "value"
    }
  }
}
```

**Required Fields (INSERT):**
- `gw_action`: Must be `"artifact.save"`
- `gw_workspace_id`: UUID (MVP locked to owner workspace)
- `owner_user_id`: UUID of artifact owner
- `artifact_type`: One of `["project", "journal", "restart", "snapshot"]`
- `title`: Artifact title (max 500 chars)

**Optional Fields:**
- `summary`: Brief description
- `tags`: Array of tag strings
- `extension`: Type-specific extension fields (JSONB)
- `content`: Rich content JSONB (journal type)

**Note**: UPDATE operations (with `artifact_id`) are **not yet implemented** in Save subworkflow.

---

## Response Envelope Format

### Success Response

```json
{
  "ok": true,
  "_gw_route": "ok",
  "data": {
    "artifact": {
      "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
      "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
      "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
      "artifact_type": "project",
      "title": "New Project Title",
      "summary": "Project description",
      "lifecycle_status": "active",
      "created_at": "2026-01-04T12:00:00Z",
      "updated_at": "2026-01-04T12:00:00Z",
      "tags": ["tag1", "tag2"],
      "lifecycle_stage": "seed",
      "operational_state": { ... }
    }
  }
}
```

**Success Fields:**
- `ok`: Always `true` for successful operations
- `_gw_route`: Always `"ok"` for successful routing
- `data.artifact`: Hydrated artifact object (spine + extension merged)

---

### Error Response

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Missing or invalid gw_action",
    "details": {
      "expected": "string",
      "got": "undefined"
    }
  }
}
```

**HTTP Status Codes:**
- `200`: Success (all operations)
- `403`: Forbidden (validation errors, workspace lockout, action not allowed)

**Error Codes:**
- `VALIDATION_ERROR`: Missing or invalid required fields
- `ACTION_NOT_ALLOWED`: gw_action not in ACTION_ALLOWLIST
- `ARTIFACT_TYPE_NOT_ALLOWED`: artifact_type not in TYPE_ALLOWLIST
- `WORKSPACE_FORBIDDEN`: workspace_id not permitted in MVP mode
- `NOT_FOUND`: Artifact not found (from subworkflow)
- `TYPE_MISMATCH`: Requested artifact_type doesn't match stored type (from subworkflow)

---

## Workflow Architecture

### Node Flow

```
1. Webhook_In (POST /nqxb/gateway/v1)
   ↓
2. Normalize_Request (flatten body, extract canonical fields)
   ↓
3. Gatekeeper_MVP_OwnerOnly (validation + allow-lists + workspace lock)
   ↓
4. Switch_Route_OK_or_Error
   ├─ error → Error Response (403)
   └─ ok → Switch_Action
              ├─ artifact.query → Call NQxb_Artifact_Query_v1 → Respond_Query_Success
              ├─ artifact.list → Call NQxb_Artifact_List_v1 → Respond_Query_Success
              └─ artifact.save → merge stuff → Call NQxb_Artifact_Save_v1 → Respond_Query_Success
```

### Key Nodes

**1. NQxb_Gateway_v1__Webhook_In**
- Type: Webhook (POST)
- Auth: Basic Auth (credential: "Qwrk Ingest Basic Auth")
- Endpoint: `/nqxb/gateway/v1`
- Response Mode: `responseNode` (uses Respond to Webhook nodes downstream)

**2. NQxb_Gateway_v1__Normalize_Request**
- Type: Code (JavaScript)
- Purpose: Extract canonical contract fields from request body
- Output: Standardized `$json` with `gw_action`, `gw_workspace_id`, `artifact_type`, `artifact_id`, `selector`
- Preserves all original request fields (pass-through + canonical overlay)

**3. NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly**
- Type: Code (JavaScript)
- Purpose: Validate envelope + enforce allow-lists + MVP workspace lock
- Allow-lists:
  - `ACTION_ALLOWLIST`: `["artifact.query", "artifact.list", "artifact.save"]`
  - `TYPE_ALLOWLIST`: `["project", "journal", "restart", "snapshot"]`
- MVP Workspace Lock: `OWNER_WORKSPACE_ID = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"`
- Output on error: `{ ok: false, _gw_route: "error", error: {...} }`
- Output on success: `{ ok: true, _gw_route: "ok", ...canonical fields }`

**4. NQxb_Gateway_v1__Switch_Route_OK_or_Error**
- Type: Switch
- Condition: `$json._gw_route === "error"` → output 0 (Error Response)
- Condition: `$json._gw_route === "ok"` → output 1 (Switch_Action)

**5. NQxb_Gateway_v1__Switch_Action**
- Type: Switch
- Condition: `$json.gw_action === "artifact.query"` → output 0 (Call Query)
- Condition: `$json.gw_action === "artifact.list"` → output 1 (Call List)
- Condition: `$json.gw_action === "artifact.save"` → output 2 (merge stuff → Call Save)

**6. merge stuff**
- Type: Code (JavaScript)
- Purpose: Flatten webhook body before passing to Save subworkflow
- Ensures subworkflow receives clean, flat payload structure
- **Added**: 2026-01-04 for artifact.save routing

**7. Call 'NQxb_Artifact_Query_v1'**
- Type: Execute Workflow
- Workflow ID: `IsLBYjXJ5R2Djfrv`
- Wait for completion: Yes

**8. Call 'NQxb_Artifact_List_v1'**
- Type: Execute Workflow
- Workflow ID: `Wbg4ciSwUSSTrO3C`

**9. Call 'NQxb_Artifact_Save_v1'**
- Type: Execute Workflow
- Workflow ID: `g0zpVK0sesavO4JA`
- **Added**: 2026-01-04

**10. NQxb_Gateway_v1__Respond_Query_Success**
- Type: Respond to Webhook
- Response: `{ ok: true, _gw_route: "ok", data: { artifact: $json } }`
- HTTP 200

**11. Error Response**
- Type: Respond to Webhook
- Response: `$json` (contains error envelope)
- HTTP 403

---

## Recent Changes (v1.3 — 2026-01-04)

### Added artifact.save Support

**Changes:**
1. **Updated ACTION_ALLOWLIST** in Gatekeeper node
   - Added `"artifact.save"` to allowed actions

2. **Added third routing rule** in Switch_Action node
   - New condition: `$json.gw_action === "artifact.save"`
   - Routes to output 2

3. **Added "merge stuff" preprocessing node**
   - Flattens webhook body before calling Save subworkflow
   - Ensures clean payload structure for Save_v1

4. **Added "Call 'NQxb_Artifact_Save_v1'" node**
   - Execute Workflow node calling NQxb_Artifact_Save_v1
   - Workflow ID: `g0zpVK0sesavO4JA`

5. **Wired connections**
   - Switch_Action output 2 → merge stuff → Call Save → Respond_Query_Success

**Testing:**
- Pinned test data added for artifact.save (restart type)
- KG proof template added to `docs/kg/KG_Proofs__Kernel_v1.md`

**Limitations:**
- Save subworkflow currently supports **INSERT only**
- UPDATE operations (with artifact_id) not yet implemented
- Extension validation varies by artifact_type

---

## MVP Constraints

### Workspace Lock (Owner-Only Mode)

The Gateway is currently locked to a single workspace for MVP testing:

**Allowed Workspace:**
- `workspace_id`: `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`

Any request with a different `gw_workspace_id` will be rejected with:
```json
{
  "ok": false,
  "error": {
    "code": "WORKSPACE_FORBIDDEN",
    "message": "Workspace not permitted in MVP owner-only mode"
  }
}
```

**Future**: Multi-workspace support will be added post-MVP.

---

## Authentication

**Method**: HTTP Basic Auth
**Credential**: "Qwrk Ingest Basic Auth" (configured in n8n)
**Username**: `qwrk-gateway`
**Password**: [Managed in n8n credential store]

### PowerShell Example

```powershell
$credential = Get-Credential -Message "qwrk-gateway"

$body = @{
    gw_action = "artifact.query"
    gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
    artifact_type = "project"
    artifact_id = "668bd18f-4424-41e6-b2f9-393ecd2ec534"
} | ConvertTo-Json

$response = Invoke-RestMethod `
    -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1" `
    -Method Post `
    -Headers @{ "Content-Type" = "application/json" } `
    -Body $body `
    -Credential $credential

$response | ConvertTo-Json -Depth 10
```

---

## Testing & Validation

### KG Proofs

**Documented Tests:**
- ✅ artifact.query (KGB-tested; snapshot artifact; 2026-01-04)
- ✅ artifact.list (testing in progress)
- ⏳ artifact.save (pending; test template ready in KG_Proofs__Kernel_v1.md)

**KG Proof Location**: `docs/kg/KG_Proofs__Kernel_v1.md`

### Pin Data (Test Fixture)

The workflow includes pinned test data for `artifact.save`:

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "restart",
  "title": "System Restart — Gateway Test",
  "summary": "Gateway test: restart INSERT through Save workflow.",
  "tags": [],
  "content": {},
  "extension": {
    "payload": {
      "kind": "gateway_test",
      "note": "Restart payload must be an object; confirms validation + DB write."
    }
  }
}
```

---

## Subworkflow Integration

### NQxb_Artifact_Query_v1
- **Trigger**: Execute Workflow
- **Input**: Full Gateway envelope (canonical fields)
- **Output**: Single artifact object (spine + extension merged)
- **Errors**: NOT_FOUND, TYPE_MISMATCH

### NQxb_Artifact_List_v1
- **Trigger**: Execute Workflow
- **Input**: Full Gateway envelope with `selector` JSONB
- **Output**: Array of artifact objects + pagination metadata
- **Filters**: lifecycle_status, tags, full-text search (title/summary)

### NQxb_Artifact_Save_v1
- **Trigger**: Execute Workflow
- **Input**: Full Gateway envelope with spine + extension fields
- **Output**: Saved artifact object (spine + extension merged)
- **Operations**: INSERT only (UPDATE not implemented)
- **Errors**: VALIDATION_ERROR, TYPE_SPECIFIC validation errors

---

## File Locations

**Workflow JSON**: `workflows/NQxb_Gateway_v1.json`
**Docs Copy**: `docs/workflows/NQxb_Gateway_v1.json`
**README**: `docs/workflows/NQxb_Gateway_v1__README.md` (this file)
**KG Proofs**: `docs/kg/KG_Proofs__Kernel_v1.md`

---

## Version History

| Version | Date       | Changes                                      |
|---------|------------|----------------------------------------------|
| v1.3    | 2026-01-04 | Added artifact.save routing to Save_v1       |
| v1.2    | 2026-01-04 | Added artifact.list routing to List_v1       |
| v1.1    | 2026-01-03 | Added artifact.query routing to Query_v1     |
| v1.0    | 2025-12-30 | Initial Gateway implementation (query only)  |

---

## Known Limitations

1. **Single workspace only** (MVP owner-only mode)
2. **artifact.save supports INSERT only** (no UPDATE yet)
3. **No retry logic** for transient failures in subworkflows
4. **No rate limiting** (relies on n8n server-level limits)
5. **No request ID tracking** (no correlation ID in envelope)
6. **artifact.delete not implemented** (DELETE operations deferred to future)

---

## Next Steps

**Immediate:**
- [ ] Execute KG proof for artifact.save (project INSERT)
- [ ] Test UPDATE path in Save_v1 subworkflow
- [ ] Verify error propagation from Save_v1 to Gateway response

**Future Enhancements:**
- [ ] Multi-workspace support (remove MVP workspace lock)
- [ ] Add correlation ID to envelope for request tracking
- [ ] Implement artifact.delete action + routing
- [ ] Add gw_user_id to envelope for RLS enforcement
- [ ] Add request/response logging for audit trail

---

**End of README**
