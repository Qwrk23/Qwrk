# Behavioral Role Layer (Platform Semantic Lock v1)
## Revised Execution Plan — Post‑T64 Clearance

**Sapling UUID:** 621d7dba-351c-4b84-a7a1-80eb0db5e82e  
**Lifecycle State:** sapling  
**Execution Status:** Structured. Awaiting T64 resolution.  
**Objective:** Introduce `behavior_role` as a required semantic lens on all top‑level artifacts with full governance alignment, kernel consistency, and migration safety.

---

# Executive Summary

This plan incorporates all structural corrections identified in review:

- NOT NULL enforcement moved post‑backfill
- T64 dependency acknowledged and sequenced first
- Normalize_Request forwarding explicitly included
- Governance housekeeping leaves added
- Enum replaced with text + CHECK constraint (kernel consistency)
- "Top‑level types" explicitly defined
- Phase 2C certification included
- Oak readiness gated after documentation + certification

Execution of this plan must not begin until **T64 (Spine‑Field Update Path)** is resolved and deployed.

---

# Semantic Invariant (v1)

All top‑level artifacts must include a required field:

`behavior_role TEXT NOT NULL CHECK (value in defined set)`

Behavior role:
- Required on artifact.save
- Visible in list/query/registry export
- Mutable via artifact.update
- Mutation requires reason string + audit event

---

# Definition: Top‑Level Artifact Types

The following artifact types require behavior_role:

- project
- snapshot
- restart
- journal

Excluded:
- branch
- limb
- leaf
- instruction_pack
- any execution anatomy types

This classification must be used identically in:
- Backfill mapping
- Save validation
- Update validation
- Surface rendering

---

# Behavior Role Value Set (v1)

Using TEXT + CHECK constraint (NOT PostgreSQL ENUM).

Allowed values:
- governance
- milestone
- architecture
- feature
- refactor
- experiment
- alignment
- external

Rationale for TEXT + CHECK:
- Kernel precedent consistency
- Rollback‑friendly migrations
- Easier evolution in v2
- Avoid ENUM rigidity

---

# Execution Tree (Revised)

## Phase 0 — Hard Dependency

### B0 — T64 Resolution (Precondition)
- Spine‑field update routing must exist
- artifact.update must support spine‑level field mutation deterministically
- Audit event pipeline must exist

No further execution allowed until B0 complete.

---

## Phase 1 — Schema Introduction (Non‑Breaking)

### B1 — Schema DDL Introduction

L1.1 — Add behavior_role TEXT column (nullable)
- ALTER TABLE qxb_artifact ADD COLUMN behavior_role TEXT;

L1.2 — Add CHECK constraint (value set)
- CHECK (behavior_role IN (...))

L1.3 — DDL Version Bump (v2.4 → v2.5)
- Migration file created
- Schema reference updated
- Co‑commit documentation

No NOT NULL constraint yet.

---

## Phase 2 — Backfill & Constraint Finalization

### B2 — Retroactive Classification & Data Backfill

L2.1 — Generate deterministic classification mapping
- Rule‑based from artifact_registry
- Must explicitly include all top‑level types

L2.2 — Manual review of ambiguous artifacts
- Resolve blend cases
- Default to structural function

L2.3 — Bulk update behavior_role for historical artifacts
- All top‑level artifacts populated

L2.4 — Enforce NOT NULL constraint (moved from Phase 1)
- ALTER TABLE ... SET NOT NULL
- Only after successful backfill validation

---

## Phase 3 — Gateway Enforcement (Post‑Backfill)

### B3 — Gateway Contract & Boundary Hardening

L3.1 — Normalize_Request Forwarding
- Add behavior_role extraction
- Ensure pass‑through to Save sub‑workflow
- Regression test for silent drop prevention

L3.2 — Require behavior_role on artifact.save (top‑level only)
- Deterministic rejection if missing
- No defaulting allowed

L3.3 — Audited Mutability (Post‑T64)
- behavior_role change requires:
  - reason string
  - audit event record
- Must use T64 spine update path

---

## Phase 4 — Surface & Registry Visibility

### B4 — Surface Rendering

L4.1 — QSB list/query display behavior_role
- Visible in summary cards
- Visible in hydrate view

L4.2 — artifact_registry export includes behavior_role
- Registry JSON export updated

---

## Phase 5 — Governance Hardening & Certification

### B5 — Certification & Documentation

L5.1 — End‑to‑End Regression Test
- save → promote → query → list → update → export
- Confirm constraint enforcement

L5.2 — Phase 2C Certification Run
- Required after Gateway mutation
- Validate no regression across Save/Update flows

L5.3 — Documentation Updates
- CLAUDE.md updated (new spine column)
- Instruction pack references updated
- Schema reference documentation complete

L5.4 — Governance Snapshot (for‑q)
- Record semantic invariant introduction
- Lock value set v1

L5.5 — Oak Readiness Review & Sapling→Tree Promotion
- Only after:
  - All branches complete
  - Certification passed
  - Documentation finalized
  - Explicit owner confirmation

---

# Dependency Map

Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5

Critical sequencing:
- NOT NULL only after backfill
- Save enforcement only after backfill
- Mutability only after T64
- Oak only after documentation + certification

---

# Risk Controls

1. Silent Drop Risk — mitigated via Normalize_Request leaf
2. Constraint Failure Risk — mitigated by delayed NOT NULL
3. Kernel Drift Risk — mitigated by DDL version + Schema Reference update
4. Update Path Coupling Risk — mitigated by T64 precondition
5. ENUM Rigidity Risk — avoided via TEXT + CHECK

---

# Relationship to Phase 2C Behavioral Type System (58667e8e)

Clarification:
- This sapling introduces structural semantic classification (spine‑level lens).
- Phase 2C Behavioral Type System may extend this into higher‑order category modeling.
- No schema overlap unless explicitly unified later.

Future consolidation may occur but is not assumed.

---

# Execution Readiness Gate

This tree is considered execution‑ready when:

- T64 deployed and verified
- Revised structure accepted
- No unresolved governance drift issues
- Owner explicitly authorizes Phase 1 execution

Until then: structured, not executable.

---

# Structural Rating (Post‑Revision Projection)

Macro sequencing: 10/10  
Dependency integrity: 9/10  
Governance completeness: 10/10  
Kernel consistency: 10/10  

This version is execution‑credible once T64 clears.

---

End of Plan.

