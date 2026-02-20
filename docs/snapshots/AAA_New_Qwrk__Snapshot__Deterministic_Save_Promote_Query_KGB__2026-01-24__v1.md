# Snapshot: Deterministic Save → Promote → Query KGB

**Snapshot ID:** (generated on insert)
**Created:** 2026-01-24
**Type:** snapshot / kgb / governance
**Parent Project:** `8111bff3-16f6-4381-943f-f451b7536715`

---

## 1. Current Objective

Establish a **Known-Good Baseline (KGB)** for the deterministic artifact lifecycle flow:

```
artifact.save → artifact.promote → artifact.query
```

This flow is now **proven end-to-end** with real IDs and DB-confirmed state transitions.

---

## 2. Decisions Locked

| Decision | Status | Notes |
|----------|--------|-------|
| Gateway `call_save` must point to active Save workflow | **LOCKED** | Was pointing to deactivated workflow |
| `artifact.save` returns `artifact_id` in response envelope | **LOCKED** | Fixed via correct workflow pointer |
| `artifact.promote` requires `transition` at **top-level** | **LOCKED** | NOT nested under `artifact_payload` |
| `artifact.promote` requires `reason` at **top-level** | **LOCKED** | 1-280 chars |
| `artifact.query` requires `artifact_type` | **LOCKED** | Validation rejects without it |
| Lifecycle event captures `from_state` and `to_state` | **LOCKED** | Stored in `qxb_artifact_event.payload` |

---

## 3. Open Questions

| Question | Status | Notes |
|----------|--------|-------|
| Should Gateway normalize `transition` from nested to top-level? | OPEN | Currently requires caller discipline |
| Should `artifact.query` infer `artifact_type` from `artifact_id`? | OPEN | Would require pre-lookup |

---

## 4. Current Phase

**Phase:** Gateway v1 Stabilization
**Status:** KGB Proven for Save/Promote/Query on `project` type

---

## 5. Known-Good Payloads (Validator Expectations)

### 5a. artifact.save (CREATE)

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "title": "Project Title",
  "summary": "Project summary",
  "extension": {
    "lifecycle_stage": "seed"
  }
}
```

**Response contains:** `artifact_id` (UUID of created artifact)

---

### 5b. artifact.promote

```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "8111bff3-16f6-4381-943f-f451b7536715",
  "transition": "seed_to_sapling",
  "reason": "Initial planning complete"
}
```

**Critical:** `transition` and `reason` must be **top-level keys**, NOT nested under `artifact_payload`.

---

### 5c. artifact.query

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "8111bff3-16f6-4381-943f-f451b7536715"
}
```

**Critical:** `artifact_type` is **required** — validation rejects without it.

---

## 6. Receipts (Proof of Execution)

| Item | Value |
|------|-------|
| **Workspace ID** | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |
| **Project artifact_id** | `8111bff3-16f6-4381-943f-f451b7536715` |
| **Promote event_id** | `a590e518-051a-4f9d-a352-b83248a90a99` |
| **Transition executed** | `seed_to_sapling` |
| **Final lifecycle_status** | `sapling` |
| **DB-confirmed** | Yes (via artifact.query) |

---

## 7. Files Changed / Operational Fix

### Root Cause
Gateway workflow node `Call 'NQxb_Artifact_Save_v1'` was pointing to a **deactivated/old** Save workflow, causing `artifact_id: null` in responses.

### Fix Applied
Repointed `call_save` node to the **correct active** `NQxb_Artifact_Save_v1` workflow.

### Affected Workflow
- **Gateway:** `NQxb_Gateway_v1` (n8n ID: `D1NWfUWZ9IFDVqNB`)
- **Node fixed:** `Call 'NQxb_Artifact_Save_v1'`

---

## 8. Next Actions

1. **Update test harness** — Add KGB payloads as regression tests
2. **Document Gateway contract** — Formalize top-level `transition`/`reason` requirement in schema

---

## 9. Summary

The deterministic flow `artifact.save → artifact.promote → artifact.query` is now **proven KGB**. Key learnings:

- Gateway workflow pointers must reference **active** workflows
- `artifact.promote` expects `transition` and `reason` at **top-level**
- `artifact.query` requires `artifact_type` (no inference from artifact_id)
- Lifecycle events capture full transition metadata in `payload`

This snapshot serves as the authoritative reference for Gateway v1 request shapes.
