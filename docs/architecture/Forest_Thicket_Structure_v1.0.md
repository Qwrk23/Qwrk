# AAA_New_Qwrk — Forest / Thicket Structure Lock (v1.0)

**Date:** 2025-12-30
**Owner:** Master Joel
**Status:** LOCKED (Option 1)

---

## Purpose

Lock Forests and Thickets as first-class structural containers above Projects (Trees) in New Qwrk, aligned with the canonical `Qxb_Artifact` spine and `parent_artifact_id` lineage model.

---

## Decision Locked

**Option 1 is locked:** Forest and Thicket are modeled as first-class artifacts.

- New `artifact_type` values will be added: `forest`, `thicket`
- **Forests** represent major life domains (e.g., Work, Business, Qwrk, Personal)
- **Thickets** represent groupings within a Forest (e.g., Partner Demos, Opportunity Tracking, PoVs)
- **Trees (Projects)** live inside Thickets

---

## Canonical Structure (Binding)

**Hierarchy:**

```
forest → thicket → tree
```

**Lineage rules:**

- `forest.parent_artifact_id = NULL`
- `thicket.parent_artifact_id = forest.artifact_id`
- `project.parent_artifact_id = thicket.artifact_id`

---

## Invariants (Must Hold Everywhere)

- Forests and Thickets are **structural containers**, not tags
- Lineage is enforced via `Qxb_Artifact.parent_artifact_id` (no special-case foreign keys)
- All Forest/Thicket/Project records remain workspace-scoped (`workspace_id` required)
- Forest and Thicket are long-lived; lifecycle semantics are minimal (to be defined in Phase 2)
- This change must **not** dilute Snapshot semantics (snapshots remain lifecycle-only for projects in Kernel v1)

---

## Flowers (To-Do Items) — Structure Layer Addition (v1.0)

### Definition

**Flowers** are lightweight "to-do" execution items. They represent tasks that need to be accomplished and may or may not have due dates. Flowers are **not** Trees (Projects) and therefore do **not** participate in Project lifecycle governance or Snapshot semantics.

### Canonical Structure (Binding)

**Hierarchy (expanded):**

```
forest → thicket → tree (project)
forest → thicket → flower (to-do)
```

**Lineage rules (binding):**

- `forest.parent_artifact_id = NULL`
- `thicket.parent_artifact_id = forest.artifact_id`
- `project.parent_artifact_id = thicket.artifact_id`
- `flower.parent_artifact_id = thicket.artifact_id`

**Optional linkage (non-binding, recommended):**

- A Flower may optionally reference a related Project (Tree) for context, but does not require one

### Invariants (Must Hold Everywhere)

- Flowers are first-class artifacts (structural execution items), not tags and not embedded-only checklist JSON
- Flowers do not dilute Project meaning: they are not lifecycle-governed and do not require Snapshots
- Flowers are allowed under Thickets only (no direct Forest → Flower in v1)
- All Flowers are workspace-scoped (`workspace_id` required) and follow the same tenancy boundaries as other artifacts
- Forests and Thickets remain long-lived containers; Flowers are typically short-lived execution items

### Scope and Phase

Flowers are part of the **Structure Layer** (Phase 2) work.

This change must not alter Kernel v1 execution gates or Snapshot semantics (snapshots remain lifecycle-only for projects in Kernel v1).

### Required Follow-on Updates (Gated)

- Update Type Registry allow-list to include: `flower`
- Define minimal type table schema: `Qxb_Artifact_Flower` (PK=FK to `Qxb_Artifact`)
- Define governance rules: allowed parent types (thicket only), allowed operations, and mutability rules
- Add selector/query patterns for listing Flowers by Forest/Thicket and optionally by related Project
- Add RLS policies consistent with workspace-first and owner/membership access
- Add contract tests:
  - create forest
  - create thicket under forest
  - create flower under thicket
  - deny invalid lineage (e.g., flower under forest or under project)

---

## Scope and Phase

This is a structural model decision. Implementation work (schema/type registry/RLS/Gateway allow-list updates) should be scheduled as **Phase 2 (Structure Layer)** work so Kernel v1 execution gates remain deterministic.

---

## Required Follow-on Updates (Gated)

1. Update Type Registry allow-list to include: `forest`, `thicket`
2. Define minimal type table schemas: `Qxb_Artifact_Forest` and `Qxb_Artifact_Thicket` (PK=FK to `Qxb_Artifact`)
3. Define governance rules: allowed parent types, allowed operations, immutability rules (if any)
4. Add selector filters for forest/thicket scoping in `artifact.list`/`query` patterns
5. Add RLS policies consistent with workspace-first and owner/membership access
6. Add contract tests:
   - create forest
   - create thicket under forest
   - create project under thicket
   - deny invalid lineage

---

## Query Semantics Examples (Non-Binding Examples)

- "Show me all active saplings in Work" → list projects where `lifecycle_status="sapling"` AND `operational_state="active"` AND lineage `forest="Work"`
- "Show me my thickets in Work" → list thicket artifacts where parent is `forest="Work"`

---

## Change Narrative

This structure is required to match Master Joel's mental model (Forest → Thicket → Tree) and to preserve deterministic organization, list defaults, and AI reasoning. Tags are insufficient as a primary organizing axis.

---

**End of Forest/Thicket Structure Lock v1.0**
