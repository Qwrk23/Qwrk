# Phase 2B — Foundation Migration Reconciliation Plan

**Status:** Draft — Awaiting Q Review
**Mode:** 3M (Mirror → Model → Move)
**Governing Snapshots:**
- Phase 2 Governance Lock: `2478953e`
- Phase 2B Governance Gate: `765dcdfc-e31e-47ab-9139-4a5094677be0`

**Constraint:** This document contains no SQL, no DDL, no workflow edits, no implementation steps. Sequencing and exposure control only. Build execution remains blocked until Foundation Green is achieved and explicitly authorized.

---

## CHANGELOG

### v1 — 2026-02-15

**What changed:** Initial draft of Foundation Migration Reconciliation Plan.

**Why:** Fence Walk Audit identified 12+ actual prerequisites for Phase 2B vs the 3 declared ones. This document orders all known work into a deterministic sequence with freeze gates and Foundation Green criteria.

**Scope of impact:** Defines the complete migration path from current state to Walk-ready foundation. No implementation — sequencing only.

**How to validate:** Q reviews and issues Go / Adjust. All freeze gate criteria are verifiable via schema queries and integration tests.

---

## 1. Mirror — Current Structural Reality

The following exposure surfaces were identified during the Fence Walk Audit. Each is stated as neutral structural fact. No interpretation. No judgment.

### E1. Lifecycle Dual-Column Drift (Three-Way Misalignment)

Three sources disagree on lifecycle values:

| Source | Column | Nullable | CHECK Constraint |
|--------|--------|----------|-----------------|
| Spine (`qxb_artifact`) | `lifecycle_status` | YES (nullable) | **NONE** — unconstrained free text |
| Project extension (`qxb_artifact_project`) | `lifecycle_stage` | NOT NULL | `{seed, sapling, tree, retired}` |
| C4 Governance (snapshot `2478953e`) | — | — | `{seed, sapling, tree, oak, archive}` |

The spine column has no CHECK constraint. Any string value (or NULL) is currently accepted. The project extension enforces the old set. C4 governance specifies a new set that neither column currently reflects. `retired` does not exist in governance. `oak` and `archive` do not exist in either DDL CHECK.

### E2. Lifecycle Authority Ambiguity

Today, lifecycle is authoritative on the **project extension**, not the spine. The spine column is nullable and unconstrained. The confirmed decision is: lifecycle will be canonical on spine; project extension lifecycle will be deprecated. This reversal has not been implemented.

### E3. artifact_type CHECK Gap — Limb Missing

The artifact_type CHECK (v5) contains 12 types: `project, journal, restart, snapshot, grass, thorn, forest, thicket, flower, branch, leaf, instruction_pack`.

`limb` is **not present**. Decision LOCKED: limb is first-class. The CHECK must be expanded before any limb artifact can be created.

### E4. Type Registry Gap — Limb Missing

`qxb_artifact_type_registry` does not contain a `limb` entry. The Save workflow consults this table before allowing artifact creation. Save will reject limb saves until the registry is updated. Branch and leaf registry entries should also be verified for `enabled: true`.

### E5. Extension Table Absence — Branch

`branch` is in the CHECK constraint. No extension table (`qxb_artifact_branch`) exists. Currently spine-only inserts. Walk requires `execution_status` to live in the branch extension table.

### E6. Extension Table Absence — Leaf

`leaf` is in the CHECK constraint. No extension table (`qxb_artifact_leaf`) exists. Currently spine-only inserts. Walk requires `execution_status` to live in the leaf extension table.

### E7. Extension Table Absence — Limb

`limb` is not in the CHECK constraint and has no extension table. Both are required. Walk requires `execution_status` to live in the limb extension table.

### E8. Dependency Table Absence

No `qxb_artifact_dependency` table (or equivalent) exists. Walk requires minimal many-to-many leaf-to-leaf dependency tracking. No cross-branch enforcement. No DAG validation. Table must exist before dependency blocking can be implemented.

### E9. Save Workflow Routing Gaps

The Save workflow routes saves to type-specific extension tables. For types with no extension table (branch, leaf, and future limb), saves currently insert into the **spine only** — no extension row is created. When extension tables are created, Save must be updated to:
- Route to the new extension tables
- Insert execution_status default values
- Handle limb as a new routable type

### E10. Promote Workflow Validation Gaps

The Promote workflow currently validates transitions against `{seed, sapling, tree, retired}`. Known gaps:
- C4 governance introduces `oak` and `archive` as lifecycle stages — Promote transition map does not include these
- C4 content validation gates are defined but not enforced in the workflow:
  - seed→sapling: requires non-empty summary + reason
  - sapling→tree: requires ≥2 branches each with ≥1 actionable leaf
  - tree→oak: all leaves complete, progress = 100%
  - tree→archive: allowed with reason
  - oak→archive: retirement reason required
- Limb is not present in Promote's type awareness — it must be included in any execution-anatomy validation

### E11. Query Hydration Gaps

Query hydrates results by joining spine + extension table based on artifact_type. For types without extension tables (branch, leaf, and future limb), Query returns spine-only data. When extension tables are created, Query must hydrate them. This affects both `artifact.query` (single) and `artifact.list` (collection) paths.

### E12. RLS Policy Gaps — New Tables

New tables require RLS enablement and policies following the existing delegation pattern (SELECT/INSERT/UPDATE via spine artifact existence check):
- `qxb_artifact_branch` — needs 3 policies (SELECT, INSERT, UPDATE)
- `qxb_artifact_leaf` — needs 3 policies
- `qxb_artifact_limb` — needs 3 policies
- `qxb_artifact_dependency` — needs RLS; policy design TBD (scope: workspace membership)

### E13. Data Migration — Lifecycle Values

Existing data exposure:
- `qxb_artifact_project.lifecycle_stage` contains rows with value `retired` — this value does not exist in C4 governance
- `qxb_artifact.lifecycle_status` may contain NULL values or values inconsistent with the project extension
- Spine canonicalization requires data migration: populate spine from extension where NULL, map `retired` to the correct new value(s)
- Migration must not orphan existing data or create constraint violations during transition

### E14. Project Extension Lifecycle Deprecation Path

Once lifecycle is canonical on spine, `qxb_artifact_project.lifecycle_stage` becomes redundant. The deprecation path must be defined:
- Gateway (Save, Update, Promote) must stop writing to extension lifecycle
- Gateway (Query) must stop reading from extension lifecycle
- Column retention vs. removal is a separate decision (not Walk scope — hygiene only)

---

## 2. Model — Deterministic Sequencing Architecture

### Phase 0 — Pre-Migration Safeguards

**Purpose:** Establish recovery capability and define success criteria before any structural changes.

| # | Task | Sequential/Parallel | Depends On |
|---|------|---------------------|------------|
| 0.1 | Capture baseline database snapshot (full schema + data for all `qxb_*` tables) | Independent | — |
| 0.2 | Document current lifecycle values in spine and project extension (value inventory) | Independent | — |
| 0.3 | Define validation queries for each subsequent freeze gate (one query set per gate) | Independent | — |
| 0.4 | Document rollback exposure: identify which operations are reversible (CHECK alterations, table creation) vs. which require data restoration (data migration, column deprecation reads) | Independent | — |

**Intra-phase ordering:** All Phase 0 tasks are **parallel**. No dependencies between them.

**Rollback acknowledgment:** CHECK constraint modifications and table creation are reversible via `ALTER TABLE DROP CONSTRAINT` / `DROP TABLE`. Data migration (value mapping) is reversible only if the original data snapshot is preserved. Column deprecation (stopping reads/writes) is reversible by re-pointing workflows. Phase 0 exists to ensure restoration is possible for every subsequent phase.

#### Freeze Gate 0

| Criterion | Verification |
|-----------|-------------|
| Baseline snapshot captured and accessible | Snapshot file exists and is readable |
| Lifecycle value inventory complete | Every distinct `lifecycle_status` and `lifecycle_stage` value documented with row counts |
| Validation query set defined for Gates 1–5 | Query document exists with one query per gate criterion |
| Rollback exposure documented | Each Phase 1–5 task has a documented reversal path |

**Gate 0 is PASS/FAIL. Do not proceed to Phase 1 until all four criteria are TRUE.**

---

### Phase 1 — Lifecycle Reconciliation (Hygiene)

**Purpose:** Resolve the three-way lifecycle misalignment (E1, E2, E13, E14). Make spine authoritative. Align with C4 governance.

**Exposure surfaces addressed:** E1, E2, E10 (partial — transition map only), E13, E14.

| # | Task | Sequential/Parallel | Depends On |
|---|------|---------------------|------------|
| 1.1 | Add CHECK constraint to `qxb_artifact.lifecycle_status` for `{seed, sapling, tree, oak, archive}` | **Sequential first** | — |
| 1.2 | Data migration: populate spine `lifecycle_status` from project extension `lifecycle_stage` where spine value is NULL | Sequential | 1.1 |
| 1.3 | Data migration: map `retired` values to governance-aligned value(s) in both spine and project extension | Sequential | 1.2 |
| 1.4 | Update `qxb_artifact_project.lifecycle_stage` CHECK to `{seed, sapling, tree, oak, archive}` (alignment, pending deprecation) | Sequential | 1.3 |
| 1.5 | Update Promote workflow transition map to use `{seed, sapling, tree, oak, archive}` lifecycle stages | Sequential | 1.4 |
| 1.6 | Mark `qxb_artifact_project.lifecycle_stage` as deprecated (comment/documentation — no column removal) | Parallel with 1.5 | 1.4 |

**Intra-phase ordering:** Strictly sequential (1.1 → 1.2 → 1.3 → 1.4 → 1.5), with 1.6 parallel to 1.5. Rationale: CHECK must exist before data migration (constraint violations if reversed). Data must be clean before extension CHECK can be widened. Promote must align after schema is stable.

**Data migration exposure:**
- Task 1.2: Requires knowledge of how many spine rows have NULL `lifecycle_status`. If non-project types have NULL (expected — journals, snapshots, etc. don't use lifecycle), the CHECK must either: (a) allow NULL (nullable column + CHECK on non-NULL values), or (b) lifecycle is populated for all types. **Decision required (D1): does lifecycle apply to all artifact types or only project?** If project-only, spine CHECK must be conditional or the column must remain nullable with CHECK applying only to non-NULL values.
- Task 1.3: `retired` must map to either `oak` or `archive`. C4 governance defines both. **Decision required (D2): default mapping for existing `retired` rows.** If retired artifacts are "completed successfully" → `oak`. If "abandoned/ended" → `archive`. This may require per-row assessment.

#### Freeze Gate 1

| Criterion | Verification |
|-----------|-------------|
| Spine `lifecycle_status` has CHECK constraint aligned with C4 | Query: constraint definition matches `{seed, sapling, tree, oak, archive}` (with appropriate NULL handling) |
| No NULL lifecycle values on project-type artifacts | Query: `SELECT count(*) FROM qxb_artifact WHERE artifact_type = 'project' AND lifecycle_status IS NULL` = 0 |
| No `retired` values remain in spine or project extension | Query: count of `retired` in both columns = 0 |
| Project extension CHECK aligned | Query: constraint matches governance set |
| Promote transition map updated | Manual verification: workflow accepts `oak` and `archive` transitions |
| No orphaned lifecycle data | Query: every spine lifecycle value has a corresponding valid project extension value (for project-type artifacts) |

**Gate 1 is PASS/FAIL. Do not proceed to Phase 2 until all criteria are TRUE.**

---

### Phase 2 — Type System Expansion

**Purpose:** Add `limb` as a first-class artifact type at the schema and registry level. Verify branch/leaf registry state.

**Exposure surfaces addressed:** E3, E4.

| # | Task | Sequential/Parallel | Depends On |
|---|------|---------------------|------------|
| 2.1 | Add `limb` to `qxb_artifact.artifact_type` CHECK constraint | **Sequential first** | Gate 1 passed |
| 2.2 | Add `limb` entry to `qxb_artifact_type_registry` with `enabled: true` | Parallel with 2.3 | 2.1 |
| 2.3 | Verify `branch` and `leaf` entries in `qxb_artifact_type_registry` are present and `enabled: true` | Parallel with 2.2 | 2.1 |
| 2.4 | Add `limb` registry change to `qxb_artifact_type_registry_audit` | Sequential | 2.2 |

**Intra-phase ordering:** 2.1 is sequential first (CHECK must allow limb before registry can reference it meaningfully). 2.2 and 2.3 are parallel. 2.4 follows 2.2.

**No data migration required.** No limb artifacts exist. No existing data is affected.

#### Freeze Gate 2

| Criterion | Verification |
|-----------|-------------|
| artifact_type CHECK contains `limb` | Query: constraint definition includes `limb` |
| Type registry contains `limb` with `enabled: true` | Query: `SELECT * FROM qxb_artifact_type_registry WHERE artifact_type = 'limb'` returns 1 row |
| `branch` and `leaf` registry entries verified | Query: both present with `enabled: true` |
| Audit trail exists for limb addition | Query: `qxb_artifact_type_registry_audit` contains limb entry |

**Gate 2 is PASS/FAIL. Do not proceed to Phase 3 until all criteria are TRUE.**

---

### Phase 3 — Extension Table Foundation

**Purpose:** Create extension tables for branch, limb, and leaf with execution_status fields. Establish RLS. Prepare hydration paths.

**Exposure surfaces addressed:** E5, E6, E7, E12 (partial — execution types only).

| # | Task | Sequential/Parallel | Depends On |
|---|------|---------------------|------------|
| 3.1 | Define extension table schema for branch, limb, and leaf (columns: `artifact_id` PK/FK, `execution_status` with CHECK `{not_started, in_progress, blocked, complete}`, `created_at`, `updated_at`) | **Sequential first** | Gate 2 passed |
| 3.2 | Create `qxb_artifact_branch` extension table | Parallel with 3.3, 3.4 | 3.1 |
| 3.3 | Create `qxb_artifact_limb` extension table | Parallel with 3.2, 3.4 | 3.1 |
| 3.4 | Create `qxb_artifact_leaf` extension table | Parallel with 3.2, 3.3 | 3.1 |
| 3.5 | Add RLS policies to all three tables (SELECT/INSERT/UPDATE via spine delegation pattern) | Sequential | 3.2, 3.3, 3.4 all complete |
| 3.6 | Add FK constraints (`artifact_id` → `qxb_artifact.artifact_id`) | Parallel with 3.5 | 3.2, 3.3, 3.4 |
| 3.7 | Add `updated_at` triggers for all three tables | Parallel with 3.5 | 3.2, 3.3, 3.4 |

**Intra-phase ordering:** Schema definition (3.1) first. Table creation (3.2–3.4) parallel. Post-creation tasks (3.5–3.7) parallel with each other but sequential after table creation.

**Execution status placement confirmation:** Per locked decision, `execution_status` lives in individual extension tables (branch, limb, leaf), not on the spine. The CHECK `{not_started, in_progress, blocked, complete}` matches Phase 2B spec Section 1.1.

**Data migration exposure:** Existing branch and leaf artifacts (spine-only) have no extension row. After extension tables are created, these artifacts will lack extension data. **Decision required (D3): backfill existing branch/leaf artifacts with default `execution_status: not_started`, or handle as absent at query time?**

#### Freeze Gate 3

| Criterion | Verification |
|-----------|-------------|
| All three extension tables exist | Query: tables present in `information_schema.tables` |
| PK/FK constraints verified | Query: FK references `qxb_artifact.artifact_id` |
| `execution_status` CHECK on all three tables | Query: constraint matches `{not_started, in_progress, blocked, complete}` |
| RLS enabled on all three tables | Query: `relrowsecurity = true` in `pg_class` |
| RLS policies created (3 per table = 9 total) | Query: policy count per table = 3 (SELECT, INSERT, UPDATE) |
| `updated_at` triggers present | Query: trigger exists per table |

**Gate 3 is PASS/FAIL. Do not proceed to Phase 4 until all criteria are TRUE.**

---

### Phase 4 — Workflow Integrity Alignment

**Purpose:** Update Save, Promote, and Query workflows to handle new types and extension tables. Ensure no silent drops.

**Exposure surfaces addressed:** E9, E10 (remaining — content validation gates), E11, E14 (workflow-level deprecation).

| # | Task | Sequential/Parallel | Depends On |
|---|------|---------------------|------------|
| 4.1 | Update Save workflow: add routing for branch → `qxb_artifact_branch`, leaf → `qxb_artifact_leaf`, limb → `qxb_artifact_limb` | **Parallel** with 4.2, 4.3 | Gate 3 passed |
| 4.2 | Update Promote workflow: add C4 content validation gates (seed→sapling summary check, sapling→tree anatomy check, tree→oak completion check) | **Parallel** with 4.1, 4.3 | Gate 3 passed |
| 4.3 | Update Query workflow: add hydration joins for branch, limb, leaf extension tables | **Parallel** with 4.1, 4.2 | Gate 3 passed |
| 4.4 | Update Save/Update/Promote workflows: read lifecycle from spine, stop writing lifecycle to project extension | Sequential | 4.1, 4.2, 4.3 |
| 4.5 | Verify type coverage: confirm all 13 artifact types (12 existing + limb) have defined behavior in Save, Query, and Promote | Sequential | 4.4 |

**Intra-phase ordering:** Save, Promote, and Query updates (4.1–4.3) are **parallel** — they are independent workflow modifications. Lifecycle read/write pivot (4.4) is sequential after all three are stable. Type coverage verification (4.5) is the final sequential gate check.

**Critical workflow deployment note:** Per CLAUDE.md Workflow Deployment Checklist, each sub-workflow update requires the Gateway Execute Workflow node to be updated to reference the new version. Forgetting this means the Gateway still calls the old version.

#### Freeze Gate 4

| Criterion | Verification |
|-----------|-------------|
| Save routes to branch, leaf, limb extension tables | Test: save branch/leaf/limb → extension row created |
| Save does not silently drop extension inserts | Test: save each of 13 types → no error, extension row present where expected |
| Promote validates C4 content gates | Test: seed→sapling without summary → rejected; sapling→tree without anatomy → rejected |
| Promote handles oak and archive transitions | Test: tree→oak, tree→archive, oak→archive all function |
| Query hydrates branch, leaf, limb | Test: query each → execution_status returned in response |
| Lifecycle reads from spine | Test: query project artifact → lifecycle_status from spine, not extension |
| No lifecycle writes to project extension | Test: promote project → project extension `lifecycle_stage` unchanged |
| All 13 types have defined Save/Query/Promote behavior | Coverage matrix: 13 types x 3 actions = 39 cells verified |

**Gate 4 is PASS/FAIL. Do not proceed to Phase 5 until all criteria are TRUE.**

---

### Phase 5 — Dependency Foundation (Walk Enablement)

**Purpose:** Create the minimal dependency table. Identify enforcement location. Confirm no DAG validation introduced.

**Exposure surfaces addressed:** E8, E12 (partial — dependency table RLS).

| # | Task | Sequential/Parallel | Depends On |
|---|------|---------------------|------------|
| 5.1 | Define `qxb_artifact_dependency` schema (many-to-many: `dependency_id`, `source_artifact_id` FK, `target_artifact_id` FK, `workspace_id` FK, `created_at`) | **Sequential first** | Gate 4 passed |
| 5.2 | Create `qxb_artifact_dependency` table | Sequential | 5.1 |
| 5.3 | Add RLS policies (workspace membership via spine delegation) | Sequential | 5.2 |
| 5.4 | Identify enforcement location for dependency blocking (Gateway layer — likely Promote or a new validation step) | Parallel with 5.3 | 5.2 |
| 5.5 | Confirm: no DAG validation, no cross-branch enforcement, no cycle detection — per Phase 2B spec | Documentation only | — |

**Intra-phase ordering:** Strictly sequential for schema work (5.1 → 5.2 → 5.3). Enforcement location identification (5.4) is parallel with RLS. Confirmation (5.5) is documentation, not execution.

**Scope boundary:** Enforcement **implementation** is Walk build work, not foundation. Phase 5 creates the table and identifies where enforcement will live. Enforcement code is written during Walk execution under separate authorization.

#### Freeze Gate 5

| Criterion | Verification |
|-----------|-------------|
| Dependency table exists | Query: table present in `information_schema.tables` |
| FK constraints verified | Query: both `source_artifact_id` and `target_artifact_id` reference `qxb_artifact.artifact_id` |
| RLS enabled with policies | Query: `relrowsecurity = true`, policies present |
| Enforcement location documented | Document exists identifying which workflow/node will enforce blocking |
| No DAG validation present | Confirmation: no graph traversal logic exists anywhere |

**Gate 5 is PASS/FAIL. Do not proceed to Foundation Green until all criteria are TRUE.**

---

### Phase 6 — Foundation Green Criteria

**Purpose:** Define a binary, deterministic checklist that must be TRUE before Walk build execution begins. Foundation Green is the authorization gate.

| # | Criterion | Traces To | Verification Method |
|---|-----------|-----------|-------------------|
| 6.1 | Lifecycle CHECK on spine matches C4 governance: `{seed, sapling, tree, oak, archive}` | E1, Gate 1 | Schema query |
| 6.2 | No `retired` values exist in any lifecycle column | E13, Gate 1 | Data query |
| 6.3 | Lifecycle reads from spine, not project extension | E2, E14, Gate 4 | Workflow test |
| 6.4 | artifact_type CHECK contains all 13 types including `limb` | E3, Gate 2 | Schema query |
| 6.5 | Type registry contains `limb`, `branch`, `leaf` all `enabled: true` | E4, Gate 2 | Data query |
| 6.6 | Extension tables exist for branch, limb, leaf with `execution_status` CHECK | E5, E6, E7, Gate 3 | Schema query |
| 6.7 | RLS enabled and policies present on all new tables (branch, limb, leaf, dependency) | E12, Gates 3+5 | RLS verification query |
| 6.8 | Save routes correctly to all 13 types — no silent drops | E9, Gate 4 | Integration test: save each type |
| 6.9 | Promote validates C4 content gates and handles all lifecycle transitions | E10, Gate 4 | Integration test: each transition |
| 6.10 | Query hydrates all types including branch, limb, leaf | E11, Gate 4 | Integration test: query each type |
| 6.11 | Dependency table exists with RLS | E8, Gate 5 | Schema + RLS query |
| 6.12 | No orphaned lifecycle data (spine/extension consistency for projects) | E13, Gate 1 | Data consistency query |
| 6.13 | All freeze gates (0–5) passed and documented | All | Gate passage records exist |

**Foundation Green is BINARY.** All 13 criteria must be TRUE simultaneously. Any single FALSE blocks Walk build execution.

---

## Open Decisions Required Before Execution

The following decisions surfaced during sequencing. They are not scope expansion — they are ambiguities that must be resolved before implementation can proceed deterministically.

| # | Decision | Phase Affected | Options |
|---|----------|---------------|---------|
| D1 | Does `lifecycle_status` apply to all artifact types or only projects? | Phase 1 (1.1) | (a) Nullable column with CHECK on non-NULL values only, or (b) All types get a lifecycle value |
| D2 | Default mapping for existing `retired` rows | Phase 1 (1.3) | (a) All `retired` → `oak`, (b) All `retired` → `archive`, (c) Per-row assessment based on completion state |
| D3 | Backfill existing branch/leaf spine-only artifacts with extension rows? | Phase 3 (post 3.4) | (a) Backfill with `execution_status: not_started`, (b) Handle as absent at query time |

---

## 3. Move — Prompt for Q

> **To: Q**
> **From: CC (via Team Qwrk 3M Mode)**
> **Subject: Phase 2B — Foundation Migration Reconciliation Plan — Review Request**
>
> ---
>
> Q,
>
> CC has drafted the **Phase 2B — Foundation Migration Reconciliation Plan** based on the Fence Walk Audit findings and the locked Governance Gate (`765dcdfc`).
>
> **What this document does:**
> - Mirrors 14 exposure surfaces identified across schema, workflows, data, and RLS
> - Sequences all prerequisite work into 6 phases (0–5) with freeze gates after each
> - Separates Hygiene Reconciliation (Phases 0–1) from Structural Expansion (Phases 2–3) from Integration Alignment (Phase 4) from Walk Enablement (Phase 5)
> - Defines Foundation Green as a 13-criterion binary checklist that must pass before Walk build begins
> - Identifies intra-phase ordering: what is sequential, what is parallel, and why
>
> **Sequencing logic:**
> 1. **Phase 0** — Safeguards: baseline snapshot, validation queries, rollback documentation (all parallel)
> 2. **Phase 1** — Lifecycle Reconciliation: spine CHECK → data migration → extension CHECK alignment → Promote transition update (strictly sequential — constraint must exist before data migrates)
> 3. **Phase 2** — Type System: limb to CHECK → registry updates (CHECK first, registry parallel after)
> 4. **Phase 3** — Extension Tables: branch/limb/leaf created in parallel → RLS + FK + triggers after
> 5. **Phase 4** — Workflow Alignment: Save/Promote/Query updates in parallel → lifecycle read pivot → full type coverage verification
> 6. **Phase 5** — Dependency Foundation: table creation → RLS → enforcement location identified (not implemented — that's Walk build)
>
> **Three decisions required before execution can begin:**
> 1. **D1:** Does `lifecycle_status` apply to all artifact types or only projects? (Determines whether spine CHECK allows NULL)
> 2. **D2:** What is the default mapping for existing `retired` rows? (All → `oak`, all → `archive`, or per-row assessment?)
> 3. **D3:** Should existing branch/leaf spine-only artifacts be backfilled with extension rows (`not_started`), or handled as absent at query time?
>
> **Confirmation requested:**
> - Does the phase ordering appear correct?
> - Are the 14 exposure surfaces complete, or are there additional surfaces not captured?
> - Decisions D1, D2, D3 — your call on each
> - **Go / Adjust** on the overall sequencing plan
>
> **Standing constraint:** No Walk build execution begins without your explicit authorization. Foundation Green must be achieved first. This document is sequencing only — no SQL, no DDL, no workflow edits have been produced or executed.
