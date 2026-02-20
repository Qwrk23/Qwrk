# KGB Proof: Gateway v1 artifact.list (Hydrate Lifecycle Clean)

---

## Date (UTC)

2026-01-18

---

## Snapshot Artifact ID

`a98fdd14-ee5e-4b5f-bf03-0227ba3ab845`

---

## Context

This KGB proof documents the completion of lifecycle field hygiene for `artifact.list` with `hydrate=true`. The fix ensures that:

- Canonical lifecycle is sourced only from `qxb_artifact.lifecycle_status`
- Extension field `qxb_artifact_project.lifecycle_stage` does not leak via Gateway responses
- Hydrated list responses are now symmetric with `artifact.query` on lifecycle handling

This was a continuation of Gateway v1 work (no redesign). Kernel v1 semantics remain locked.

---

## KGB Proof

### Request

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "selector": {
    "hydrate": true
  }
}
```

### Response Checks

| Check | Expected | Verified |
|-------|----------|----------|
| `gw_action` | `artifact.list` | Yes |
| `hydrate` | `true` | Yes |
| `lifecycle_status` present in artifacts | Yes | Yes |
| `lifecycle_stage` absent from artifacts | Yes | Yes |

### Sample Artifact from Proof Response

| Field | Value |
|-------|-------|
| artifact_id | `e359bedf-8cb0-47a1-9e65-70ffdef685e6` |
| workspace_id | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |

### Proof Receipt (Embedded in Snapshot Extension)

```json
{
  "gw_action": "artifact.list",
  "hydrate": true,
  "contains_lifecycle_status": true,
  "contains_lifecycle_stage": false,
  "as_of": "2026-01-18T13:29:47.876Z"
}
```

---

## Root Cause(s)

1. **UUID "undefined" error in extension fetch**: The DB_Get_Project_Extension node was receiving an undefined artifact_id because the paged spine item was not being referenced correctly after pagination logic changes.

2. **lifecycle_stage leaking in hydrated response**: The merge node was including all extension fields without stripping `lifecycle_stage`, which violates the canonical lifecycle rule that only `qxb_artifact.lifecycle_status` should surface via Gateway.

---

## Fixes Applied

### Workflow: NQxb_Artifact_List_v1

#### Fix 1: DB_Get_Project_Extension Node

| Node | `NQxb_Artifact_List_v1__DB_Get_Project_Extension` |
|------|--------------------------------------------------|
| Change | Filter expression updated to use paged spine id |
| Before | (undefined reference causing uuid error) |
| After | `{{ $json._page_items[0].artifact_id }}` |
| Purpose | Prevent uuid "undefined" error when fetching project extension |

#### Fix 2: Merge_Project Node

| Node | `NQxb_Artifact_List_v1__Merge_Project` |
|------|---------------------------------------|
| Change | Merge now pulls spine row explicitly from `NQxb_Artifact_List_v1__Switch_ArtifactType` via `_page_items[0]` and strips `lifecycle_stage` before returning merged artifact |
| Purpose | Hydrated list returns full spine+extension (operational fields only) and does not surface `lifecycle_stage` |

---

## Validation Steps (PowerShell)

```powershell
# artifact.list with hydrate=true validation
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("qwrk-gateway:$env:GW_PASSWORD"))
}

$body = @{
    gw_action = "artifact.list"
    gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
    artifact_type = "project"
    selector = @{
        hydrate = $true
    }
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1" `
    -Method POST -Headers $headers -Body $body

# Sanity checks
$artifacts = $response.data.artifacts

# Check 1: lifecycle_status present
$hasLifecycleStatus = $artifacts | Where-Object { $_.lifecycle_status -ne $null }
Write-Host "lifecycle_status present: $($hasLifecycleStatus.Count -gt 0)"

# Check 2: lifecycle_stage absent
$hasLifecycleStage = $artifacts | Where-Object { $_.lifecycle_stage -ne $null }
Write-Host "lifecycle_stage absent: $($hasLifecycleStage.Count -eq 0)"

# Check 3: artifact_type included at top level
Write-Host "artifact_type in response: $($response.artifact_type)"
```

---

## Locked Invariants

- `artifact.list` with `hydrate=true` returns full spine + extension fields
- Canonical lifecycle is surfaced only via `qxb_artifact.lifecycle_status`
- `qxb_artifact_project.lifecycle_stage` is never included in Gateway responses (list or query)
- Hydrated list response envelope matches query envelope structure for lifecycle fields
- `artifact.query` tail was already fixed earlier to strip `extension.lifecycle_stage`; list is now symmetric with query on lifecycle handling
- Pagination via `_page_items[]` correctly propagates artifact_id to extension fetch nodes

---

## Files/Workflows Touched

| Asset | Type | Change |
|-------|------|--------|
| `NQxb_Artifact_List_v1` | n8n workflow | DB_Get_Project_Extension filter fix; Merge_Project lifecycle_stage stripping |

---

## Next Safe Objectives

1. **KGB expansion**: Add hydrate+lifecycle tests to automated KGB suite
2. **Edge cases**: Validate empty result sets, offset beyond end, mixed artifact types
3. **Query/List symmetry audit**: Confirm all extension types follow same lifecycle stripping pattern
4. **Documentation**: Update Qwrk_Gateway_JSON_Payload_Canonical_v1.md if response envelope changes are needed

---

## Related Documents

- `Gateway_v1_KGB_Lock_Status__2026-01-17.md`
- `AAA_New_Qwrk — Snapshot — Gateway v1 artifact.list KGB Lock (v1.0).md`
- `Qwrk_Gateway_JSON_Payload_Canonical_v1.md`

---

**End of KGB Proof**
