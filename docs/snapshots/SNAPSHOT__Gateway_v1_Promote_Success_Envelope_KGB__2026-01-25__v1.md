# SNAPSHOT — Gateway v1 Promote Success Envelope (KGB)

**Date:** 2026-01-25 (CST)
**System:** Qwrk Gateway v1 + n8n
**Artifact Type:** snapshot
**Scope:** Promote success response shaping only (no lifecycle/db logic changes)
**Workflow:** NQxb_Artifact_Promote_v1
**Workflow JSON file:** NQxb_Artifact_Promote_v1 (15).json
**n8n workflow id:** OXxickY3S5Fxtv5F
**versionId:** 9659e6c5-3104-44b0-a47c-aea012f1f383

---

## Goal

Wrap Promote success responses in a canonical success envelope so Promote is contract-consistent with Save and Update.

---

## Non-goals (LOCKED)

- Do NOT change lifecycle rules
- Do NOT change DB writes
- Do NOT change transitions
- Do NOT change Gateway routing
- Do NOT re-debug promote logic

---

## Implementation (LOCKED)

- Terminal success path must be:
  `NQxb_Artifact_Promote_v1__DB_Insert_Event` → `NQxb_Artifact_Promote_v1__Shape_Response`
- Response-shaping code lives only in:
  `NQxb_Artifact_Promote_v1__Shape_Response`

---

## Canonical Success Envelope (LOCKED)

```json
{
  "ok": true,
  "gw_action": "artifact.promote",
  "workspace_id": "<uuid>",
  "artifact_type": "<string>",
  "artifact_id": "<uuid>",
  "event_id": "<uuid>",
  "operation": "PROMOTE",
  "from_state": "<string>",
  "to_state": "<string>",
  "transition": "<string>",
  "timestamp": "<ISO8601>",
  "data": {
    "event": { ... }
  }
}
```

---

## KGB Receipt (Observed Response)

```json
{
  "ok": true,
  "gw_action": "artifact.promote",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "7a0492cb-7fc5-4bca-b29c-17040803ddd7",
  "event_id": "0223bae1-4b37-4d25-a39e-7aaa19a48e38",
  "operation": "PROMOTE",
  "from_state": "retired",
  "to_state": "tree",
  "transition": "retired_to_tree",
  "timestamp": "2026-01-25T22:33:54.508+00:00",
  "data": {
    "event": {
      "event_id": "0223bae1-4b37-4d25-a39e-7aaa19a48e38",
      "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
      "artifact_id": "7a0492cb-7fc5-4bca-b29c-17040803ddd7",
      "actor_user_id": null,
      "event_type": "lifecycle_promote",
      "event_ts": "2026-01-25T22:33:54.508+00:00",
      "payload": {
        "reason": "Promote success envelope verification",
        "to_state": "tree",
        "gw_action": "artifact.promote",
        "from_state": "retired",
        "request_id": "a9829f0b-5550-4026-b089-0895cf69dfad",
        "transition": "retired_to_tree",
        "artifact_type": "project"
      },
      "created_at": "2026-01-25T22:33:54.834585+00:00"
    }
  }
}
```

---

## Completion Criteria (LOCKED)

- Promote returns `ok: true`
- Promote returns `gw_action: "artifact.promote"`
- Promote returns `event_id` (top-level)
- PowerShell test format remains unchanged

---

## Suggested Restart Prompt

**RESTART — Promote Envelope Regression Check (Gateway v1)**

If Promote tests P1/P2 fail after future changes, use this restart:

1. Run the PowerShell Promote test suite:
   ```powershell
   $env:QWRK_GATEWAY_BASEURL = "https://n8n.halosparkai.com/webhook"
   $env:QWRK_GATEWAY_PASSWORD = "<password>"
   . ".\docs\testing\Qwrk.Gateway.TestHarness.ps1"
   Initialize-QwrkGateway
   Invoke-QwrkPromoteTests
   ```

2. Verify success envelope contains these keys:
   - `ok: true`
   - `gw_action: "artifact.promote"`
   - `event_id` (top-level UUID)
   - `operation: "PROMOTE"`
   - `from_state`, `to_state`, `transition`
   - `data.event` (full event record)

3. Confirm terminal success path in workflow:
   - `NQxb_Artifact_Promote_v1__DB_Insert_Event` → `NQxb_Artifact_Promote_v1__Shape_Response`

4. If Shape_Response node is missing or bypassed, re-wire the success path.

5. Do NOT modify lifecycle rules, DB writes, or transitions during envelope debugging.

---

*Snapshot created by Claude Code — 2026-01-25*
