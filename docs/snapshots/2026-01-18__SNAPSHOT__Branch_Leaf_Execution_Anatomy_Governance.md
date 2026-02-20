## SNAPSHOT — Branch / Leaf Execution Anatomy Governance Lock

**Date:** 2026-01-18
**Applies To:** Qwrk V2
**Snapshot Type:** Governance + Semantics Lock
**Author:** Master Joel
**Status:** LOCKED

---

### Purpose

This snapshot permanently records the canonical governance decision introducing **Branch** and **Leaf** as first-class artifact types used exclusively for **project execution anatomy**.

It exists to prevent semantic drift, enforce lineage correctness, and ensure Flowers never contaminate project execution trees.

---

### Decisions Locked (Binding)

1. **Branch and Leaf are first-class artifact types**
   - They belong to the Structure Layer
   - They are governed independently from Kernel v1 MVP scope

2. **Canonical execution anatomy (non-negotiable)**

Tree / Sapling (project)
→ Branch
→ Leaf

yaml
Copy code

3. **Semantic definitions**
   - **Branch:** Structural execution module under a Project
   - **Leaf:** Executable action item under a Branch

4. **Parent / child rules (invalid states forbidden)**
   - Branch MUST parent only to Project
   - Leaf MUST parent only to Branch
   - Branch MUST NOT parent Branch or Leaf
   - Leaf MUST NOT parent any artifact

5. **Flower exclusion (binding)**
   - Flowers are NOT part of project execution trees
   - Flowers MUST NOT appear under Projects, Branches, or Leaves
   - Flowers remain lightweight, non-execution artifacts under Thickets only

6. **Lifecycle integrity preserved**
   - Branch and Leaf introduce no lifecycle stages
   - Snapshot semantics remain lifecycle-only for Projects
   - No dilution of Snapshot or Restart meaning is permitted

---

### Documents Updated

- **North Star v0.2**
- **Kernel Semantics Lock (Phase 1–3)**
  `docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md`

---

### Traceability Anchors

- **DB Constraint:** qxb_artifact_artifact_type_check_v4
- **Structural Snapshot:** f587939c-ed35-4db4-ab1c-3873e5677a25
- **North Star Version:** v0.2

---

### Explicit Non-Changes

This snapshot does NOT:
- Change Kernel v1 artifact scope
- Introduce Gateway behavior
- Modify schemas or RLS
- Alter lifecycle rules

This snapshot is **governance and semantics only**.

---

### Governance Rule

Any future modification requires:
- A versioned North Star update
- A superseding governance snapshot
