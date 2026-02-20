# AAA_New_Qwrk__Snapshot__Gateway_Internal_Normalization_Plan_Activated__2026-01-05__v1

**Snapshot Type:** snapshot
**Status:** LOCKED
**Date:** 2026-01-05
**Build Phase:** Planning → Execution-Ready (gated)

---

## Current objective
Lock the transition from governance alignment to execution readiness for the Gateway internal normalization initiative.

---

## Decisions locked
1. **Option B executed**: Conflicting plan archived as SUPERSEDED due to governance conflict; new aligned plan created as ACTIVE.
2. **Governing authority**: Snapshot `AAA_New_Qwrk__Snapshot__Gateway_Internal_Canonical_Lock__2026-01-05__v1` remains binding for contract/normalization decisions.
3. **Public contract immutable**: Gateway Contract v1.0 remains the public interface (flat `gw_*`, `gw_action`, `artifact_payload`, `selector`).
4. **Strategy confirmed**: Internal canonical normalization is permitted inside Gateway, but not exposed publicly.

---

## Artifacts created / updated
### Archived (SUPERSEDED)
- `workflows/Archive/Gateway_Canonical_Contract_v1__SUPERSEDED__Governance_Conflict__2026-01-05.md`
  - Reason: Proposed replacing Gateway Contract v1.0 with a new nested envelope (`request_type`, nested `artifact {}`, separate update, added `video`).

### New plan created (ACTIVE)
- `docs/workflows/specs/Gateway_Internal_Normalization__Implementation_Plan__v1.md`
  - Status: ACTIVE (governance-aligned)
  - Governing Authority: `AAA_New_Qwrk__Snapshot__Gateway_Internal_Canonical_Lock__2026-01-05__v1`

---

## Execution gate (non-negotiable)
**Before editing any existing n8n workflow, upload the current workflow export first.**
First target export: **Gateway workflow**.

---

## Next 1–2 actions
1. Upload the current **Gateway** n8n workflow export.
2. Begin Phase 1 execution per ACTIVE plan:
   - Add `Gateway__Normalize_To_Internal_Canonical_v1`
   - Remove "merge stuff"
   - Update Gatekeeper validation
   - Run pinned-payload test, then capture KG proof

---

## Known-good invariants
- No public contract drift (no `request_type`, no nested public `artifact {}`, no new Kernel v1 types).
- Single write action remains `artifact.save` (create vs update determined by `artifact_id` presence).
- Downstream workflows trust Gateway normalization; no internal normalization remains.

---
