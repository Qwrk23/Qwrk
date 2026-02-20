# CC Prompt — T32 Step 5 — Update v10 (Branch/Limb/Leaf Routing)

## Outcome
Update Gateway v10 workflows to properly route execution types (`branch`, `limb`, `leaf`) in accordance with the approved Phase 2B plan.

**Definition of Done:**
1. `branch`, `limb`, and `leaf` are correctly handled in all relevant routing Switch nodes.
2. No schema changes.
3. No lifecycle rule changes.
4. No promotion semantics changes.
5. All error routing remains deterministic and compliant with Phase 2 Governance Hardening Amendments.
6. Validation checklist (below) passes.

---

## Context

We are executing **T32 — Phase 2B Gateway Type Registry Expansion**, Step 5 only.

Reference sources (authoritative):
- Phase 2B — QPM Execution Semantics ("Walk")
- North Star v0.4 — Execution Anatomy (Project → Branch → Limb (optional) → Leaf)
- Phase 2 Governance Hardening Amendments (v1)

Phase boundaries are locked. This task is **routing only**.

Execution types were unlocked via governance decision. Registry enforcement already permits these types. We are now wiring v10 to support them deterministically.

---

## Scope (Strict)

IN SCOPE:
- Update routing in:
  - `Switch_Type_For_Insert`
  - `Switch_Type_For_Update`
  - Any other type-based routing nodes that must handle execution types
- Ensure canonical envelope fields are preserved
- Ensure deterministic error routing remains intact

OUT OF SCOPE (DO NOT TOUCH):
- Database schema
- Type registry expansion beyond branch/limb/leaf
- Lifecycle transition logic
- Promotion validation
- Aggregation/rollup logic
- Dependency logic
- Any Phase 2C structure work
- Any refactor unrelated to routing

If scope creep appears necessary, STOP and report.

---

## Execution Instructions

1. Inspect current v10 workflow.
2. Produce a minimal diff plan showing:
   - Which Switch nodes require new cases
   - Where execution types should flow
   - Confirmation that no existing types are altered
3. Confirm error paths for:
   - Unknown type
   - Missing required fields
   - Validation failure
4. After approval, implement only the approved diff.

---

## Constraints (Binding)

- Gateway defines canonical envelope shape.
- Normalize nodes must remain monotonic and single-return.
- No new early returns.
- No dead-end Switch branches.
- Every `{ ok: false }` must route to response shaping.
- No UUID invention.
- No silent field stripping.

If any node violates governance amendments, report before proceeding.

---

## Validation Checklist

Before marking complete:

1. Insert `branch` → routes to correct insert sub-workflow.
2. Insert `limb` → routes correctly.
3. Insert `leaf` → routes correctly.
4. Update `branch` → routes correctly.
5. Update `limb` → routes correctly.
6. Update `leaf` → routes correctly.
7. Existing types (project, journal, snapshot, restart, instruction_pack, grass, thorn) still route unchanged.
8. Unknown type still triggers deterministic error envelope.
9. No Switch node has empty connection arrays.
10. All error envelopes reach `Return_Response`.

---

## Output Contract

Respond with:

1. Summary
2. Minimal Diff Plan
3. Risks (if any)
4. Explicit "Ready to Implement" confirmation

Do NOT implement until plan is confirmed.

---

Proceed with plan proposal only.

