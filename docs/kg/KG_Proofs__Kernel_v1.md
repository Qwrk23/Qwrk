# KG Proofs — Kernel v1

## Thorn Proof Gate — PASS
- Date (UTC): 2026-01-04 12:05:55.754339+00
- Template version: Kernel_v1__NoFail_Inserts__v1.1
- Artifact ID: cf7e3447-8c42-445d-a925-83add6f30617
- Verified:
  - Insert succeeded (spine + thorn extension)
  - Joined retrieval returned expected fields:
    - qxb_artifact.artifact_type = thorn
    - qxb_artifact_thorn.severity = 3 (INT)
    - qxb_artifact_thorn.status = open
    - details_json populated; resolution_notes NULL

---

## KG Proof — Gateway v1 artifact.query (KGB type)

**Date (UTC)**: 2026-01-04
**Workflow**: NQxb_Gateway_v1 → artifact.query endpoint
**Test Artifact**: KGB project (seed-stage)

### Request Envelope
```json
{
  "gw_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "gw_action": "artifact.query",
  "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
  "artifact_type": "project"
}
```

### Response Envelope
```json
{
  "artifact": {
    "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
    "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
    "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
    "artifact_type": "project",
    "title": "KGB Project Test",
    "summary": "Known-Good Baseline project artifact",
    "lifecycle_status": "active",
    "created_at": "2025-12-30T...",
    "updated_at": "2025-12-30T...",
    "lifecycle_stage": "seed",
    "operational_state": { /* JSONB payload */ }
  }
}
```

### Verified
- ✅ Spine-first pattern: fetches qxb_artifact by workspace_id + artifact_id
- ✅ Type validation: requested artifact_type matches stored type
- ✅ Type branching: routes to qxb_artifact_project extension table
- ✅ Response merging: spine + extension fields merged correctly
- ✅ No redundant artifact_type in extension payload
- ✅ All artifact types tested: project, journal, snapshot, restart

### Notes
- Timestamp: Query executed during KGB validation run
- RLS enforced: Only workspace members can query artifacts
- Contract compliance: Response matches Gateway v1 envelope structure
## KG Proof — Gateway v1 artifact.query (PASS)
- Date (UTC): 2026-01-04 12:xx:xx+00  (use your PowerShell timestamp if you want)
- Endpoint: https://n8n.halosparkai.com/webhook/nqxb/gateway/v1
- Auth: Basic (credential: "Qwrk Ingest Basic Auth"; user: qwrk-gateway)
- Request:
  - gw_action: artifact.query
  - gw_workspace_id: be0d3a48-c764-44f9-90c8-e846d9dbbd0a
  - artifact_type: snapshot
  - artifact_id: 95f0ba11-27d5-4c8b-88f4-08f1fbcf9672
- Response:
  - ok: true
  - _gw_route: ok
  - data.artifact hydrated:
    - spine fields present (title, tags, lifecycle_status, timestamps)
    - extension.payload present and populated
- Notes:
  - Initial 403 resolved after correcting Basic Auth username + resetting password.
  - Confirms Gateway v1 query contract + orchestration is stable (KGB).
