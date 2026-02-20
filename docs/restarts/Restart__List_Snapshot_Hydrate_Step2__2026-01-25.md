# RESTART — Snapshot Hydrated List Completeness (Gateway v1 / artifact.list / Step 2)

**Date:** 2026-01-25
**System:** Qwrk Gateway v1 + n8n
**Mode / Governance:** AAA_New_Qwrk under Qwrk V2 Constitution
Design-first, build-later. One step at a time. Receipts required. No silent blending.
No multi-step batching. Every change must be single-step and immediately tested.

---

## Goal (Single Objective)

Make `artifact.list` for `artifact_type = snapshot` with `selector.hydrate=true` return **full hydrated artifacts** (spine + extension) for the **entire page (up to limit)** — not just a single extension stub.

"Full hydrated artifact" means returning the canonical artifact spine fields (at least: `artifact_id`, `workspace_id`, `owner_user_id`, `artifact_type`, `title`, `summary`, `priority`, `lifecycle_status`, `tags`, `content`, `parent_artifact_id`, `version`, `deleted_at`, `created_at`, `updated_at`) plus snapshot extension payload where applicable.

---

## What is Known-Good (LOCKED)

### 1. The blocker crash is fixed (Step 1 complete)

The `snapshot` hydrate path previously crashed with:

> `invalid input syntax for type uuid: "undefined"`

Fix applied:

* Node: `NQxb_Artifact_List_v1__DB_Get_Snapshot_Extension`
* Condition value changed to:
  * `{{ $json._page_items[0].artifact_id }}`

### 2. After Step 1, snapshot hydrate now returns a non-empty canonical envelope

PowerShell receipt (authoritative):

```json
{
  "ok": true,
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "hydrate": true,
    "offset": 0,
    "limit": 5,
    "as_of": "2026-01-25T22:52:15.740Z"
  },
  "data": {
    "artifacts": [
      {
        "artifact_id": "e1b29eaf-da3d-4a55-8715-86feec2b2ff1",
        "payload": {},
        "created_at": "2026-01-04T22:08:32.370316+00:00"
      }
    ]
  },
  "meta": {
    "count": 1,
    "limit": 5,
    "offset": 0,
    "has_more": false,
    "as_of": "2026-01-25T22:52:15.740Z"
  },
  "timestamp": "2026-01-25T22:52:16.530Z"
}
```

This proves:

* Response is no longer empty
* Canonical envelope is being returned
* But the artifact objects are incomplete (extension stub only)

### 3. `artifact.list` for `project` is already healthy (control case)

Project list returns a full canonical envelope and hydrated spine fields.

---

## What is still broken (the actual Step 2 issue)

For `artifact_type="snapshot"` + `hydrate=true`, `data.artifacts` contains only the **snapshot extension row** shape (e.g., `{ artifact_id, payload, created_at }`) rather than the full artifact spine + extension.

In other words, snapshot "hydrate" is not truly hydrating a page of artifacts.

---

## Hypothesis (Design Constraint, Not Yet Executed)

The current hydrate flow is still operating on a **wrapper object** that contains `_page_items` and `_meta`, and the snapshot extension fetch is effectively single-item / first-item oriented.

Step 2 likely requires introducing a **page-item explode → per-item extension fetch → merge → format** pattern, but must be done one step at a time with immediate PowerShell receipts.

---

## Current Files / References

* Workflow: `NQxb_Artifact_List_v1`
* Workflow JSON: `NQxb_Artifact_List_v1 (9).json`

---

## Known-Good PowerShell Test Format (DO NOT CHANGE)

```powershell
$GatewayUrl = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1"
$Username   = "qwrk-gateway"

$SecurePassword = Read-Host "Enter Gateway password" -AsSecureString
$BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
$PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

$pair  = "{0}:{1}" -f $Username, $PlainPassword
$basic = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$Headers = @{ "Content-Type"="application/json"; "Authorization"="Basic $basic" }
$PlainPassword = $null

$WorkspaceId = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"

$body = @{
  gw_action       = "artifact.list"
  gw_workspace_id = $WorkspaceId
  artifact_type   = "snapshot"
  selector        = @{ hydrate = $true; limit = 5; offset = 0 }
} | ConvertTo-Json -Depth 6

$resp = Invoke-WebRequest -UseBasicParsing -Method Post -Uri $GatewayUrl -Headers $Headers -Body $body

"`n--- STATUS ---"
$resp.StatusCode
"`n--- RAW LENGTH ---"
($resp.Content | Measure-Object -Character).Characters
"`n--- BODY ---"
$resp.Content
```

---

## Completion Criteria (LOCK)

After Step 2:

- [ ] `artifact.list` snapshot hydrate returns canonical envelope
- [ ] `data.artifacts` contains **full artifact spine objects** (not just extension stub)
- [ ] Up to `limit` artifacts are returned for the page (page-size correct)
- [ ] No `200 + empty body`
- [ ] PowerShell test passes unchanged

---

## First Action After Restart (Single Step Only)

Assistant must:

1. Inspect the currently active `NQxb_Artifact_List_v1` flow for snapshot hydrate and identify the **single smallest change** that moves us from "extension stub only" toward "full spine + extension for the page".
2. Propose exactly **one** change (node edit or one new node or one wiring change), and provide:
   * node name(s)
   * exact code or parameter replacement
   * why it is the smallest safe step
3. Stop and request the PowerShell receipt immediately after that one change.

---

*Restart prompt created — 2026-01-25*
