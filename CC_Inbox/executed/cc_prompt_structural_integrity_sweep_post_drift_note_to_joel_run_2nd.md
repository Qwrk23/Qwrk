# CC Execution Prompt — Structural Integrity Sweep (Items 2–8)

You are executing a post-stabilization structural sweep. This is a governance + architectural coherence pass following schema regeneration and workflow hygiene hardening.

This task handles remaining structural items 2 through 8 from the audit.

No feature expansion. No speculative design. Preserve runtime stability.

---

# OVERALL OBJECTIVE

Seal residual governance inconsistencies, prevent future drift, and formally validate Phase 2B (Walk) integrity.

You are not building new capabilities.
You are tightening the bolts.

---

# PART 1 — Migration File Annotation (Item 2)

## Context
Phase 2 structural migration file contains references to `oak` lifecycle stage.
Deployed DDL excludes `oak`.

## Required Actions

1. Locate migration file:
   2026-02-16__phase_2_completion__structural_migration__v1.sql

2. Add an inline annotation block at the top:

   - State that `oak` existed in planning but was excluded from deployed DDL v2.3
   - Confirm canonical lifecycle is: seed, sapling, tree, archive
   - Mark `oak` references as historical

3. DO NOT alter historical SQL statements.
4. DO NOT retroactively rewrite migration logic.

Purpose: Preserve historical truth while preventing future confusion.

---

# PART 2 — Phase 0 DDL Audit Alignment (Item 3)

## Input
Phase_2B__Phase_0_DDL_Reconciliation_Audit__v1.md

## Required Actions

1. Add a v2.4 alignment note at top:
   - State that DDL has progressed from v2.2 → v2.4
   - Identify which previously listed "gaps" are now resolved
   - Mark remaining open items clearly

2. Do NOT rewrite history.
3. Do NOT remove original findings.

Purpose: Convert document from active drift source to historical audit record.

---

# PART 3 — QUICK_REFERENCE Update Payload Shape Fix (Item 4)

## Input
QUICK_REFERENCE.md

## Required Actions

1. Locate Update example section.
2. Ensure tag updates reflect deployed Update v12 structure.
3. Confirm no nested incorrect wrapper examples remain.
4. Minimal diff only.

No wording expansion.
No stylistic rewrites.

---

# PART 4 — Promotion Enforcement Decision Implementation (Item 5)

## Context
Instruction pack asserts seed→sapling requires execution child.
Gateway does not enforce.

## Required Behavior

Implement Option C:

Add a documented preflight advisory layer WITHOUT runtime enforcement.

Actions:
1. Update instruction pack to:
   - Clarify that enforcement is advisory at governance layer
   - State Gateway does not enforce child existence
   - Recommend manual preflight check

2. Do NOT modify Promote workflow.
3. Do NOT add validation nodes.

Purpose: Maintain integrity without expanding Phase scope.

---

# PART 5 — Gateway-Blocked Types Boundary Clarification (Item 6)

## Context
Types exist in CHECK but are blocked in registry:
grass, thorn, forest, thicket, flower

## Required Decision

Implement Option B:

Document registry boundary explicitly.

Actions:
1. Create governance note in appropriate architecture doc:
   - State these types are intentionally blocked pending Phase 2C
   - Confirm registry is authoritative phase boundary

2. Do NOT modify CHECK constraint.
3. Do NOT activate types.

Purpose: Make intentional boundary explicit.

---

# PART 6 — Rename Mutability Registry File (Item 7)

## Required Actions

1. Rename:
   Mutability_Registry_v1.md → Mutability_Registry_v2.md

2. Ensure internal header version matches filename.
3. Update any file references if necessary.

No content expansion.

---

# PART 7 — Phase 2B Walk Completion Validation (Item 8)

## Input
PHASE_2B__QPM_Execution_Semantics.md

## Required Actions

Perform formal validation against "Definition of Walk Complete":

Confirm:
- execution_status exists on spine
- leaf completion works
- rollup percentage queryable
- dependency blocking works (minimal)
- end-to-end project trackable

If all conditions satisfied:

1. Add section at top:
   "Phase 2B Walk — COMPLETE (Validated YYYY-MM-DD)"

2. Summarize validation evidence.

If any condition not satisfied:

1. List precise gap.
2. Do NOT implement new features.
3. Mark Walk as "Pending — Gaps Identified".

No ambiguity.

---

# PART 8 — Drift Prevention Governance Rule (Item 9)

Implement Option A:

Add governance rule:

"Any DDL version change requires corresponding Schema Reference update in same commit."

Add to:
- Core governance documentation
- Schema Reference header

Purpose: Prevent recurrence of 7-week drift.

---

# VALIDATION CHECKLIST

Before commit:
- No runtime behavior changed
- No lifecycle values altered
- No registry types activated
- No workflow logic expanded
- All changes documentation-only except filename rename

---

# COMMIT MESSAGE

"Structural integrity sweep: migration annotation, audit alignment, promotion advisory clarification, registry boundary documentation, mutability registry rename, Phase 2B validation, drift-prevention rule"

Stop after commit.