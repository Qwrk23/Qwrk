# Instruction Pack — Qwrk@Work Execution Patterns v2

**Workspace:** Qwrk@Work
**Workspace UUID:** 635bb8d7-7b93-4bea-8ca6-ee2c924c9557
**Purpose:** Structural guidance for how work evolves from idea to execution within Qwrk@Work.
**Version:** v2
**Supersedes:** Execution Patterns v1

---

## CHANGELOG

### v2 (2026-03-04) — T69 Alignment

- Added semantic classification guidance per artifact type (Section 2)
- Documented which types require vs forbid `semantic_type_id`
- Updated tag discipline section with structured update format
- Corrected priority from mandatory explicit to optional with default
- Previous version: `Archive/instruction_pack_qwrk_work_execution_patterns_v_1__2026-03-04.md`

---

## 1. Structural Philosophy

Work should move through clear stages:

Idea → Seed → Sapling → Tree → Archive

Structure reduces cognitive load and prevents ADHD drift.

---

## 2. When to Use Each Artifact Type

### Seed (project, lifecycle_stage: seed)
Use when:
- A new idea emerges
- A sales opportunity is identified
- A potential initiative needs validation

Do NOT overdefine. Capture lightly.

**Semantic type:** Choose based on domain. Common: `execution-core` (task), `sales` (opportunity), `product` (feature idea), `exploratory` (investigation).

---

### Journal
Use when:
- Thinking through positioning
- Preparing for a demo
- Clarifying strategy
- Exploring ambiguity

Journals are for cognition, not execution.

**Semantic type:** Choose based on content. Common: `alignment` (reflection/planning), `governance` (rule/decision thinking), `exploratory` (open exploration).

---

### Snapshot
Use when:
- A decision is finalized
- A configuration is locked
- A meeting outcome needs immutability

Snapshots are historical anchors.

**Semantic type:** Common: `governance` (decisions/policies), `infrastructure` (config locks), `product` (feature decisions).

---

### Restart
Use when:
- Saving conversation context for continuation
- Preserving thread state across sessions

**Semantic type:** Default to `execution-core`.

---

### Branch / Limb / Leaf (Execution Anatomy)

These are non-top-level types. `semantic_type_id` is **FORBIDDEN** — do not include it.

- Branch = major execution stream
- Limb = structured execution container
- Leaf = atomic task

---

### Project — Sapling
Promote seed to sapling when:
- Clear objective exists
- Success criteria defined
- Execution is expected

Sapling = active commitment.

---

### Project — Tree
Promote sapling to tree when:
- Multi-cycle execution required
- Cross-functional coordination exists
- Ongoing tracking needed

Tree = durable initiative.

---

## 3. Promotion Discipline

- Never skip stages.
- Promotion requires explicit reason.
- Snapshot recommended at sapling_to_tree transition.
- Archive only when execution is complete or abandoned.

---

## 4. Execution Anatomy (North Star Alignment)

Project → Branch → Limb → Leaf

- Branch = major execution stream
- Limb = structured execution container
- Leaf = atomic task

Never:
- Branch → Branch
- Limb → Limb
- Leaf → parent anything

---

## 5. Sales Opportunity Modeling (Pre-Manager Phase)

For now, capture opportunities as:
- project (seed)
- `semantic_type_id`: `sales`
- tags: ["sales", "opportunity"]

Minimum structure:
- Account
- Stakeholder
- Problem
- Next Action

Do not prematurely build pipeline mechanics.

---

## 6. Tag Discipline

Tags should be:
- Lowercase
- Specific
- Reusable
- Not verbose

Avoid tag sprawl.

**Tag update format:** Use structured `{ "add": [...], "remove": [...] }`. Flat arrays are NOT supported.

---

## 7. Anti-Patterns

- Saving everything as journal
- Promoting too early
- Skipping lifecycle
- Using snapshot for thinking
- Creating branches without tree-level clarity
- Omitting `semantic_type_id` on top-level saves
- Including `semantic_type_id` on branch/leaf/limb saves

---

## 8. Governance Rules

- `priority` defaults to 3 if omitted. Explicit recommended.
- `semantic_type_id` REQUIRED for top-level, FORBIDDEN for non-top-level.
- Lifecycle must be linear.
- Instruction packs are immutable.
- New structural rules require new version.

---

**Version:** v2
**Immutability:** Future revisions require new artifact save (v3).
