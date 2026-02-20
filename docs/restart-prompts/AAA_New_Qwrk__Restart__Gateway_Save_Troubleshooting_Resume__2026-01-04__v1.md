# Restart — Resume Troubleshooting: Gateway artifact.save → Save Subworkflow (Restart INSERT)
**Timestamp (CST):** 2026-01-04 17:12:11 UTC-06:00  
**Status:** In progress (partial success)  
**Goal:** Make `artifact.save` for `artifact_type="restart"` return a fully populated, schema-aligned response (and ensure no regression to Query/List).

---

## 1) What is working (confirmed)
- Gateway routes `gw_action="artifact.save"` to the Save subworkflow correctly.
- Save subworkflow successfully performs an **INSERT** and returns a real `artifact_id`:
  - `1947d3b5-b5e8-44be-bfb6-7c05b229a52f`

---

## 2) Current symptom (what is NOT right yet)
The final Gateway response is **incomplete** (fields are coming back as `null` when they should be populated from request + DB):
- `artifact_type` is `null` (should be `"restart"`)
- `workspace_id` is `null` (should equal `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`)
- `extension.payload` is `{}` (should include the request payload)

### Latest Gateway final response (as observed)
```json
{
  "ok": true,
  "gw_action": "artifact.save",
  "artifact_id": "1947d3b5-b5e8-44be-bfb6-7c05b229a52f",
  "artifact_type": null,
  "workspace_id": null,
  "operation": "INSERT",
  "lifecycle_stage": null,
  "operational_state": null,
  "state_reason": null,
  "extension": {
    "payload": {}
  },
  "timestamp": "2026-01-04T23:05:21.181Z"
}
```

---

## 3) Last known good request into Save path
### The last “merge” node before Save trigger output
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "restart",
  "title": "System Restart \u2014 Gateway Test",
  "summary": "Gateway test: restart INSERT through Save workflow.",
  "tags": [],
  "content": {},
  "extension": {
    "payload": {
      "kind": "gateway_test",
      "note": "Restart payload must be an object; this confirms validation + DB write."
    }
  },
  "artifact_id": null,
  "selector": {},
  "req_artifact_type": "restart",
  "req_artifact_id": null,
  "_gw_debug": {
    "received_shape": "flat",
    "has_authorization": false,
    "request_method": null,
    "request_url": null
  },
  "ok": true,
  "_gw_route": "ok"
}
```

---

## 4) High-probability root cause (hypothesis)
We are likely **losing request fields** (artifact_type/workspace_id/extension.payload) in the Save workflow when a downstream DB node overwrites `$json` with a row payload that does not contain the same keys, and our final “Respond” node is responding from the wrong object shape.

In short: **the INSERT happens, but the response builder is reading from the wrong place** (or from a truncated object that no longer carries request intent).

---

## 5) Next build cycle plan (do in order, stop after each verified pass)
### Step A — Confirm what the Save workflow’s *final* responder is actually using
- Identify the node that shapes the final response in the Save workflow.
- Inspect what fields it reads from (`$json`, `$node[...]`, merged object, etc.).
- Ensure request intent survives DB nodes by storing:
  - `_normalized_request` (or equivalent) early and referencing that for response fields.

### Step B — Lock the response contract for `artifact.save`
- Implement the minimal stable response fields that must always return for INSERT:
  - `ok`, `gw_action`, `artifact_id`, `artifact_type`, `workspace_id`, `operation`, `timestamp`
- For restart/snapshot:
  - `extension.payload` should echo back (recommended: yes)

### Step C — Regression check (do not skip)
- Re-run known-good `artifact.query` and `artifact.list` tests to ensure no regressions.

---

## 6) Notes / Guardrails
- Do **not** change the shared Gateway Normalize / Gatekeeper nodes in a way that breaks Query/List.
- Prefer “freeze request intent” patterns (e.g., `req_*` fields) and reference them for responders.
- Treat Supabase nodes as “dumb writers” and do not rely on them preserving payload shape.

---

## 7) Desired end state (acceptance)
A restart INSERT returns (example):
```json
{
  "ok": true,
  "gw_action": "artifact.save",
  "artifact_id": "<uuid>",
  "artifact_type": "restart",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "operation": "INSERT",
  "extension": {"payload": { "...": "..." }},
  "timestamp": "<iso>"
}
```
