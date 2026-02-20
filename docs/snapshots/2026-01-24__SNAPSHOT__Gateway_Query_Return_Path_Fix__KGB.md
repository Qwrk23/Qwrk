# SNAPSHOT — Gateway Query Return Path Fix (instruction_pack) — KGB

**Date:** 2026-01-24
**Status:** KGB (Known-Good Baseline)
**Phase:** Integration boundary debugging → Resolved

---

## Current objective

Fix `artifact.query` end-to-end so **instruction_pack** returns a **single canonical envelope** (no double-wrapping) from Gateway → Query subworkflow → Gateway response.

---

## Decisions locked

1. **Query subworkflow returns RAW artifact on success**

   * The Query subworkflow (`NQxb_Artifact_Query_v1`) must return a **raw artifact object** (no `{ok,_gw_route,data}` envelope) so Gateway controls final wrapping.

2. **Gateway must be idempotent about envelopes**

   * Gateway shaping must **pass through** canonical envelopes and errors unchanged.

3. **Respond node must not re-wrap canonical envelopes**

   * Final response expression must detect an already-canonical success envelope and return it as-is.

---

## Root cause (proven by receipts)

* `NQxb_Artifact_Query_v1` for instruction_pack was producing/propagating shapes that led to Gateway wrapping an already-wrapped object.
* Gateway had **two wrapping layers**:

  * `NQxb_Gateway_v1__Shape_Query_Response` (wrap)
  * Respond node expression (wrap again)
* Result: `data.artifact` contained an **inner envelope** (`ok/_gw_route/data`) instead of the raw artifact.

---

## Changes applied (authoritative)

### A) Query workflow: `NQxb_Artifact_Query_v1`

1. **`NQxb_Artifact_Query_v1__Shape_Return`**

   * Success path changed to return **RAW artifact**:
   * **Now returns:** `return [{ json: j }];`
   * Error branches preserved (fail-closed + error envelope).

2. **`NQxb_Artifact_Query_v1__Return_Instruction_Pack`**

   * Normalizes instruction_pack spine and returns raw artifact with:
   * `extension: null` (because instruction_pack extension fetch is not yet wired in this workflow).

---

### B) Gateway workflow: `NQxb_Gateway_v1`

3. **`NQxb_Gateway_v1__Shape_Query_Response`**

   * Updated to be **idempotent** and to unwrap raw artifact safely:

     * Pass through error envelopes unchanged
     * Pass through canonical success envelopes unchanged
     * Otherwise wrap raw artifact once using:

       * `j.artifact` if present
       * else `j.data.artifact` if present
       * else `j` as last resort

4. **Respond node (final response expression)**

   * Replaced expression to avoid re-wrapping:

     * Pass through canonical success envelopes (`ok:true`, `_gw_route:"ok"`, `data.artifact`)
     * Pass through errors
     * Wrap only if upstream is raw

---

## Known-good test (KGB)

### PowerShell (canonical)

```powershell
$securePassword = Read-Host "Enter Gateway password" -AsSecureString
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

$authBytes = [System.Text.Encoding]::ASCII.GetBytes("qwrk-gateway:$password")
$authHeader = "Basic " + [Convert]::ToBase64String($authBytes)

$body = @{
    gw_action       = "artifact.query"
    gw_workspace_id = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
    artifact_type   = "instruction_pack"
    artifact_id     = "f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779"
} | ConvertTo-Json -Depth 5

$r = Invoke-RestMethod `
    -Uri "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1" `
    -Method Post `
    -Headers @{ Authorization = $authHeader } `
    -ContentType "application/json" `
    -Body $body

$r | ConvertTo-Json -Depth 30
```

### Expected output (single wrap)

```json
{
  "ok": true,
  "_gw_route": "ok",
  "data": {
    "artifact": {
      "artifact_id": "f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779",
      "artifact_type": "instruction_pack",
      ...
    }
  }
}
```

### Observed output (KGB)

Matches expected: **single canonical envelope** with raw artifact inside `data.artifact`.

---

## Known-good anchors

| Anchor | Value |
|--------|-------|
| Workspace | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |
| Instruction pack artifact_id | `f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779` |
| Control artifact (restart) | `ac1d6294-2bd7-4a9d-823e-827562b56e26` |

---

## Open questions (intentionally left open)

1. Should `instruction_pack` query attach `extension` from `qxb_artifact_instruction_pack` (currently `null` by design in this workflow)?
2. Should Gateway standardize wrapping so `Shape_Query_Response` is the only wrapper for query responses (recommended), and Respond node stays pass-through + fallback only?

---

## Invariants

* Gateway returns **exactly one** envelope:

  * Success: `{ ok:true, _gw_route:"ok", data:{...} }`
  * Error: `{ ok:false, _gw_route:"error", error:{...} }`
* `data.artifact` must contain **raw artifact**, never an inner envelope.
* Query workflow must be fail-closed if artifact spine is missing / malformed.

---

## Failure modes & quick checks

* If double-wrapping returns:

  * Check Respond node is passing through canonical envelopes.
  * Check `Shape_Query_Response` wraps `raw` not `j`.
* If `data.artifact` becomes `{}`:

  * Check Query `Shape_Return` fail-closed guard fired (should produce error).

---

## Next 1-2 actions

1. Decide whether to **fetch instruction_pack extension** in Query workflow and attach as `extension` (schema exists, row exists).
2. Optional hardening: ensure **all query artifact types** follow the same raw-return contract and use the same gateway idempotent shaping.

**Recommendation:** Option 2 for MVP (leave as-is), Option 1 as a deliberate follow-up once we define the canonical extension shape for instruction packs.

---

**End of Snapshot**
