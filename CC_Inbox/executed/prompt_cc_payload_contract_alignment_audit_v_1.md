# PROMPT TO CC — Payload Contract Alignment & Extension Pack Audit (v1)

## Objective

Conduct a full contract alignment audit between:

1. All current **extension_pack(s)** that provide payload instructions or examples
2. The live **KGB / Gateway behavior** as implemented in workflows
3. Canonical documentation including (but not limited to):
   - Gateway JSON Canonical Reference
   - Quick Reference
   - Payload Examples
   - Lifecycle Guide
   - Governance Hardening Amendments
   - LIVE DDL

Then design the next authoritative version of payload instructions/examples for Q and all clones.

This is an architecture alignment task — not a cosmetic rewrite.

---

# Phase 1 — Behavioral Truth Extraction (Source of Record)

You must treat live workflow behavior as authoritative over documentation.

## 1.1 Inspect Live Workflow Behavior

For each Gateway action:
- artifact.save
- artifact.update
- artifact.list
- artifact.query
- artifact.promote

Document:

- Required fields (actual runtime enforcement)
- Optional fields
- Forbidden fields
- Server-generated fields
- Version increment behavior
- Lifecycle transition enforcement
- QPM guards (journal/execution checks)
- Extension write semantics per artifact_type
- Tag update semantics
- Priority handling
- Error envelope structure
- Selector normalization behavior
- Transition normalization behavior
- Any dual-shape handling in Normalize nodes

This must reflect runtime reality — not assumed contract.

Output: "Behavioral Contract — As Implemented"

---

# Phase 2 — Documentation Drift Audit

Compare Phase 1 findings against:

- Gateway Canonical Reference
- Quick Reference
- Payload Examples
- Demo Mode payload rules
- Any extension_pack(s) containing payload examples

Identify:

- Missing required fields
- Deprecated fields still documented
- Examples that would fail at runtime
- Incorrect transition examples
- Incorrect update examples (e.g., outdated `changes` shape)
- Any payload using obsolete topology assumptions
- Any example that violates Raw JSON invariant rules
- Any inconsistency around `priority`
- Any inconsistency around `artifact_type` requirement in query

Output: "Drift Report"

Categorize drift severity:
- Critical (would cause runtime failure)
- Major (misleading but not failing)
- Minor (style or clarity issue)

---

# Phase 3 — Canonical Payload Contract vNext Design

Design the next authoritative payload instruction set.

Constraints:

- Must match live runtime behavior
- Must not invent future features
- Must not assume schema not yet implemented
- Must honor Phase 2 Governance Lock
- Must preserve Raw JSON invariant
- Must preserve sequential execution discipline

Deliverables:

## 3.1 Unified Contract Section

Single definitive section describing:

- Global rules
- Required fields by action
- Required fields by artifact_type
- Mutation invariants (version behavior)
- Lifecycle invariants
- Tag semantics
- Extension semantics

## 3.2 Minimal Valid Payload Templates

For each action, produce:

- Minimal passing payload
- Common variant payload
- One intentionally failing example (with explanation of why)

## 3.3 Promote Semantics Clarification

Explicitly clarify:

- transition is REQUIRED
- reason requirements
- actor_user_id behavior
- QPM guard enforcement logic
- Hydration selector behavior

## 3.4 Update Semantics Clarification

Clarify:

- Tags-only shape
- Extension update shape
- Spine mutation rules
- Version increment rules under Option B

## 3.5 Save Semantics Clarification

Clarify:

- Priority mandate
- Extension requirements per artifact_type
- Lifecycle initialization rules
- Server-generated fields

---

# Phase 4 — Deliverable Format

Output must be:

1. A new consolidated markdown document:
   `Qwrk_Gateway_Payload_Canonical_vNext.md`

2. A short migration note explaining:
   - Which existing docs should be deprecated
   - Which sections can be preserved
   - Which examples must be removed

3. No workflow changes in this task.

This is documentation alignment only.

---

# Guardrails

- Do NOT modify workflows.
- Do NOT modify DDL.
- Do NOT propose architectural refactors.
- Do NOT change lifecycle semantics.
- Do NOT introduce new artifact types.

If behavioral ambiguity is discovered, flag it explicitly instead of assuming.

---

# Definition of Done

This task is complete when:

- All documented payload examples can be copy-pasted and succeed.
- No documented payload shape conflicts with live workflow enforcement.
- All required fields are explicitly documented.
- All forbidden fields are explicitly documented.
- All mutation invariants are explicitly stated.
- Drift between docs and runtime is eliminated.

Clarity > brevity.
Determinism > elegance.
Behavioral truth > legacy documentation.

