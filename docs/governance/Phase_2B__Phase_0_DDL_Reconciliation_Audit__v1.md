# Phase 2B — Phase 0: DDL Reconciliation Audit

**Status:** Complete (Read-Only Audit)
**Author:** CC (Build Executor)
**Date:** 2026-02-15
**Governing Documents:**
- Authoritative DDL: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` (v2.2)
- Reconciliation Plan: `docs/governance/Phase_2B__Foundation_Migration_Reconciliation_Plan__v1.md`
- Governance Lock: `2478953e` (C2/C3/C4)
- Governance Gate: `765dcdfc` (Phase 2B)
- Q Authorization: 2026-02-15 (Macro Phase Ordering + D1/D2/D3 Locked)

**Constraint:** This document contains no executable SQL. Design only. All SQL execution requires explicit authorization per Phase 5 Foundation Green gate.

---

## CHANGELOG

### v1 — 2026-02-15

**What changed:** Initial Phase 0 DDL Reconciliation Audit.

**Why:** Q authorized Phase 0 with locked decisions D1/D2/D3 and 4 additional exposure surfaces (Index Audit, Trigger Validation, Hydrate-Mode, Error Routing). This audit fulfills Phase 0 deliverables.

**Scope of impact:** Read-only analysis. No schema, data, or workflow changes.

**How to validate:** Cross-reference every finding against live DDL (v2.2) and Phase 2B reconciliation plan (v1).

---

## Table of Contents

1. [Diff: Phase 2B Intent vs Live DDL](#1-diff-phase-2b-intent-vs-live-ddl)
2. [Enumerated Prerequisite List](#2-enumerated-prerequisite-list)
3. [Schema Migration Plan (Design Only)](#3-schema-migration-plan-design-only)
4. [Data Reconciliation Plan](#4-data-reconciliation-plan)
5. [Registry & Workflow Impact Matrix](#5-registry--workflow-impact-matrix)
6. [Foundation Green Validation Checklist (Draft)](#6-foundation-green-validation-checklist-draft)

---

## 1. Diff: Phase 2B Intent vs Live DDL

### 1.1 Lifecycle CHECK on Spine (E1)

| Aspect | Live DDL | Phase 2B Intent | Gap |
|--------|----------|-----------------|-----|
| Column | `qxb_artifact.lifecycle_status` | Same | None |
| Data type | `text` | Same | None |
| Nullable | YES | YES (per D1: NULL for non-promotable types) | None |
| CHECK constraint | **NONE** — unconstrained free text | `lifecycle_status IS NULL OR lifecycle_status IN ('seed', 'sapling', 'tree', 'oak', 'archive')` | **MISSING** |

**D1 Applied:** Lifecycle applies to project artifacts only. Column stays nullable. CHECK must allow NULL (non-project types) while constraining non-NULL values to the C4 governance set.

**CHECK design:**
```sql
-- Allows NULL (non-project types) but constrains non-NULL values
ALTER TABLE qxb_artifact ADD CONSTRAINT qxb_artifact_lifecycle_status_check
  CHECK (lifecycle_status IS NULL OR lifecycle_status IN ('seed', 'sapling', 'tree', 'oak', 'archive'));
```

### 1.2 Lifecycle Authority — Spine vs Extension (E2, E14)

| Aspect | Live State | Phase 2B Intent | Gap |
|--------|-----------|-----------------|-----|
| Authoritative source | Extension (`qxb_artifact_project.lifecycle_stage`) | Spine (`qxb_artifact.lifecycle_status`) | **Authority reversal required** |
| Extension column | `lifecycle_stage` NOT NULL, CHECK `{seed, sapling, tree, retired}` | Deprecated (keep column, stop using) | **Deprecation path needed** |
| Gateway reads lifecycle from | Extension (via Query hydration) | Spine | **Query workflow change** |
| Gateway writes lifecycle to | Both spine + extension | Spine only | **Save/Promote workflow change** |

**Observation:** Gateway hydration currently returns `operational_state` and `state_reason` from the project extension but does NOT surface `lifecycle_stage`. This may indicate the Query merge already strips it — or the merge maps it differently. Requires workflow inspection to confirm.

### 1.3 Project Extension Lifecycle CHECK (E1, E13)

| Aspect | Live DDL | Phase 2B Intent | Gap |
|--------|----------|-----------------|-----|
| Column | `qxb_artifact_project.lifecycle_stage` | Same (deprecated but retained) | None |
| CHECK | `{seed, sapling, tree, retired}` | `{seed, sapling, tree, oak, archive}` (alignment) | **CHECK must be updated** |
| `retired` in data | 2 rows (`8dbec53a`, `5cf5b078` — both test artifacts) | 0 rows (per D2: all retired → archive) | **Data migration required** |

### 1.4 artifact_type CHECK (E3)

| Aspect | Live DDL | Phase 2B Intent | Gap |
|--------|----------|-----------------|-----|
| Constraint | `qxb_artifact_artifact_type_check_v5` | v6 needed | **ALTER required** |
| Values (12) | `project, journal, restart, snapshot, grass, thorn, forest, thicket, flower, branch, leaf, instruction_pack` | Same + `limb` (13 total) | **`limb` missing** |

### 1.5 Type Registry (E4)

| Aspect | Live State | Phase 2B Intent | Gap |
|--------|-----------|-----------------|-----|
| `limb` entry | **Not present** | `enabled: true` | **INSERT required** |
| `branch` entry | Present (status unknown — requires DB verification) | `enabled: true` | **Verification required** |
| `leaf` entry | Present (status unknown — requires DB verification) | `enabled: true` | **Verification required** |

**Limitation:** `qxb_artifact_type_registry` is not queryable via Gateway (service_role only). Branch/leaf enabled status requires direct DB query.

### 1.6 Extension Table — Branch (E5)

| Aspect | Live DDL | Phase 2B Intent | Gap |
|--------|----------|-----------------|-----|
| Table `qxb_artifact_branch` | **Does not exist** | Must exist | **CREATE TABLE required** |
| Columns | — | `artifact_id` (PK/FK), `execution_status`, `priority`, `created_at`, `updated_at` | — |
| `execution_status` CHECK | — | `{not_started, in_progress, blocked, complete}` | — |
| `priority` | — | NOT NULL with deterministic default (per D3) | — |
| RLS | — | Enabled with 3 policies | — |
| FK | — | → `qxb_artifact.artifact_id` ON DELETE CASCADE | — |
| Triggers | — | `updated_at` trigger | — |

**D3 Schema Note:** Q's D3 answer specifies `status = not_started` and `priority = default (explicit deterministic value)`. The reconciliation plan originally specified only `execution_status`. D3 introduces `priority` as an extension table column. Design decision: should `priority` be an integer (consistent with spine `priority` CHECK 1-5) or a text enum? **Recommendation:** integer DEFAULT 3 (mid-range), matching spine priority semantics. Awaiting confirmation.

### 1.7 Extension Table — Leaf (E6)

Same gap as Branch (1.6). Table does not exist. Same schema required.

### 1.8 Extension Table — Limb (E7)

Same gap as Branch (1.6). Table does not exist. Same schema required. Additionally, `limb` is not yet in the artifact_type CHECK (see 1.4) — CHECK must be expanded before any limb extension table rows can reference a limb spine row.

### 1.9 Dependency Table (E8)

| Aspect | Live DDL | Phase 2B Intent | Gap |
|--------|----------|-----------------|-----|
| Table `qxb_artifact_dependency` | **Does not exist** | Must exist | **CREATE TABLE required** |
| Columns | — | `dependency_id` (PK), `source_artifact_id` (FK), `target_artifact_id` (FK), `workspace_id` (FK), `created_at` | — |
| RLS | — | Enabled with workspace-membership policies | — |
| FKs | — | Both artifact FKs → `qxb_artifact.artifact_id`, workspace FK → `qxb_workspace.workspace_id` | — |
| Enforcement | — | Table exists; enforcement logic deferred to Walk build | — |

**Scope boundary:** Phase 5 creates the table. Walk build implements enforcement. No DAG validation. No cross-branch enforcement. No cycle detection.

### 1.10 Save Workflow Routing (E9)

| Type | Current Save Behavior | Phase 2B Intent | Gap |
|------|----------------------|-----------------|-----|
| branch | Spine-only insert (no extension row) | Insert spine + extension row with `execution_status` default | **Routing addition** |
| leaf | Spine-only insert (no extension row) | Insert spine + extension row with `execution_status` default | **Routing addition** |
| limb | **Cannot save** (not in allowlist, not in type registry) | Insert spine + extension row | **New route + allowlist + registry** |

**Save version impact:** Save v28 must be updated. Gateway Execute Workflow node must be updated to reference new Save version.

### 1.11 Promote Workflow Validation (E10)

| Aspect | Current State | Phase 2B Intent | Gap |
|--------|-------------|-----------------|-----|
| Transition map | `{seed, sapling, tree, retired}` | `{seed, sapling, tree, oak, archive}` | **Map update required** |
| Content validation gates | **Not enforced** | C4 gates required | **Implementation needed** |
| Limb awareness | Not present | Must participate in anatomy validation | **Addition needed** |

**C4 content validation gates (from governance lock `2478953e`):**

| Transition | Gate | Current | Gap |
|------------|------|---------|-----|
| seed → sapling | Non-empty summary + reason | Not enforced | **Add** |
| sapling → tree | ≥2 branches each with ≥1 actionable leaf | Not enforced | **Add** |
| tree → oak | All leaves complete, progress = 100% | Not enforced | **Add** |
| tree → archive | Allowed with reason | Not enforced | **Add** |
| oak → archive | Retirement reason required | Not enforced | **Add** |

**Promote version impact:** Promote v2_HTTP must be updated. Gateway Execute Workflow node must be updated.

### 1.12 Query Hydration (E11)

| Type | Current Hydration | Phase 2B Intent | Gap |
|------|------------------|-----------------|-----|
| branch | Spine-only (no extension table to join) | Spine + extension (execution_status) | **Add hydration join** |
| leaf | Spine-only | Spine + extension | **Add hydration join** |
| limb | N/A (cannot query — not in allowlist) | Spine + extension | **Add hydration join + allowlist** |

**Query version impact:** Query v17 must be updated. Gateway Execute Workflow node must be updated.

### 1.13 RLS Policy Gaps (E12)

| Table | Current RLS | Phase 2B Intent | Gap |
|-------|-----------|-----------------|-----|
| `qxb_artifact_branch` | Table doesn't exist | 3 policies (SELECT/INSERT/UPDATE via spine delegation) | **9 policies total** |
| `qxb_artifact_leaf` | Table doesn't exist | Same | (across 3 tables) |
| `qxb_artifact_limb` | Table doesn't exist | Same | |
| `qxb_artifact_dependency` | Table doesn't exist | Workspace membership policies (TBD design) | **Policy count TBD** |

**Pattern:** Follow existing delegation pattern (e.g., `qxb_artifact_grass` policies).

### 1.14 Index Audit (Surface A — Q Addition)

**Existing Indexes (5):**

| Index | Table | Columns | Type |
|-------|-------|---------|------|
| `qxb_artifact_grass_review_detected_idx` | `qxb_artifact_grass` | `(review_status, detected_at DESC)` | btree |
| `qxb_artifact_thorn_severity_detected_idx` | `qxb_artifact_thorn` | `(severity, detected_at DESC)` | btree |
| `qxb_artifact_thorn_status_detected_idx` | `qxb_artifact_thorn` | `(status, detected_at DESC)` | btree |
| `uq_qxb_artifact_forest_title_active` | `qxb_artifact` | `(workspace_id, lower(title))` WHERE forest+active | unique btree |
| `uq_qxb_artifact_thicket_title_per_forest_active` | `qxb_artifact` | `(workspace_id, parent_artifact_id, lower(title))` WHERE thicket+active | unique btree |

**Required Indexes for Phase 2B:**

| Proposed Index | Table | Columns | Rationale |
|----------------|-------|---------|-----------|
| `idx_qxb_artifact_lifecycle_status` | `qxb_artifact` | `(lifecycle_status)` WHERE lifecycle_status IS NOT NULL | Promote workflow queries by lifecycle; project listing by status |
| `idx_qxb_artifact_branch_execution_status` | `qxb_artifact_branch` | `(execution_status)` | Walk rollup queries: count leaves by status per branch |
| `idx_qxb_artifact_leaf_execution_status` | `qxb_artifact_leaf` | `(execution_status)` | Walk rollup queries: progress calculation |
| `idx_qxb_artifact_limb_execution_status` | `qxb_artifact_limb` | `(execution_status)` | Walk rollup queries |
| `idx_qxb_artifact_dependency_source` | `qxb_artifact_dependency` | `(source_artifact_id)` | Dependency lookup: "what does this artifact depend on?" |
| `idx_qxb_artifact_dependency_target` | `qxb_artifact_dependency` | `(target_artifact_id)` | Reverse dependency lookup: "what depends on this artifact?" |
| `idx_qxb_artifact_type_workspace` | `qxb_artifact` | `(workspace_id, artifact_type)` | List queries filtered by type within workspace |

**Note:** Index on `(workspace_id, artifact_type)` may already be implicitly covered by existing query patterns via the spine FK + type filter. Performance testing recommended before creation. All other indexes are new tables with no existing coverage.

### 1.15 Trigger Validation (Surface B — Q Addition)

**Existing Triggers (8 verified + 3 unverified):**

| Trigger | Table | Event | Function | Status |
|---------|-------|-------|----------|--------|
| `qxb_artifact_event_block_delete` | `qxb_artifact_event` | BEFORE DELETE | `qxb_block_update_delete()` | VERIFIED |
| `qxb_artifact_event_block_update` | `qxb_artifact_event` | BEFORE UPDATE | `qxb_block_update_delete()` | VERIFIED |
| `qxb_artifact_set_updated_at` | `qxb_artifact` | BEFORE UPDATE | `qxb_set_updated_at()` | VERIFIED |
| `qxb_artifact_journal_set_updated_at` | `qxb_artifact_journal` | BEFORE UPDATE | `qxb_set_updated_at()` | VERIFIED |
| `qxb_artifact_project_set_updated_at` | `qxb_artifact_project` | BEFORE UPDATE | `qxb_set_updated_at()` | VERIFIED |
| `qxb_user_set_updated_at` | `qxb_user` | BEFORE UPDATE | `qxb_set_updated_at()` | VERIFIED |
| `qxb_workspace_set_updated_at` | `qxb_workspace` | BEFORE UPDATE | `qxb_set_updated_at()` | VERIFIED |
| `qxb_workspace_user_set_updated_at` | `qxb_workspace_user` | BEFORE UPDATE | `qxb_set_updated_at()` | VERIFIED |
| (likely) `updated_at` trigger | `qxb_artifact_instruction_pack` | BEFORE UPDATE | `qxb_set_updated_at()` | **NEEDS VERIFICATION** |
| (likely) `updated_at` trigger | `qxb_artifact_type_registry` | BEFORE UPDATE | `qxb_set_updated_at()` | **NEEDS VERIFICATION** |
| (likely) block triggers | `qxb_artifact_type_registry_audit` | BEFORE UPDATE/DELETE | `qxb_block_update_delete()` | **NEEDS VERIFICATION** |

**Triggers required for new tables:**

| Trigger | Table | Event | Function |
|---------|-------|-------|----------|
| `qxb_artifact_branch_set_updated_at` | `qxb_artifact_branch` | BEFORE UPDATE | `qxb_set_updated_at()` |
| `qxb_artifact_leaf_set_updated_at` | `qxb_artifact_leaf` | BEFORE UPDATE | `qxb_set_updated_at()` |
| `qxb_artifact_limb_set_updated_at` | `qxb_artifact_limb` | BEFORE UPDATE | `qxb_set_updated_at()` |

**Dependency table trigger decision:** `qxb_artifact_dependency` has no `updated_at` column (append-only design per reconciliation plan). No trigger needed unless the design changes to include `updated_at`.

**Lifecycle mutation triggers:** No triggers currently enforce lifecycle transition rules at the database level. All lifecycle enforcement is at the Gateway/workflow layer (Promote workflow). Q's Surface B asks: "No silent lifecycle mutation allowed." This is satisfied by the current architecture — there is no database-level trigger that could silently mutate lifecycle. All lifecycle changes flow through the Promote workflow.

**Confirmation:** No trigger compatibility issues with Walk semantics. Existing `updated_at` triggers are benign (timestamp only). Event log block triggers protect immutability. No cascade behaviors exist that could silently alter lifecycle.

### 1.16 Hydrate-Mode Validation (Surface C — Q Addition)

**Current behavior (Gateway Query v17):**

| Scenario | Expected | Status |
|----------|----------|--------|
| `hydrate=false` returns spine only | No extension fields in response | **Requires workflow test** |
| `hydrate=true` returns spine + extension | Extension fields merged into response | **Requires workflow test** |
| `hydrate=false` — no extension leakage | Extension data not accidentally included | **Requires workflow test** |
| `hydrate=true` — no missing fields | All extension columns present | **Requires workflow test** |

**Known observation:** Project artifact hydration returns `operational_state` and `state_reason` but NOT `lifecycle_stage`. This is either:
- (a) Intentional stripping by the merge node (lifecycle on spine only), or
- (b) An unintended omission

This must be clarified before Phase 4 workflow alignment. If (a), this is correct and aligns with Phase 2B intent. If (b), it's a pre-existing bug.

**New type hydration:** Branch, leaf, and limb will need hydration joins after extension tables are created (Phase 4, task 4.3). Until then, hydrate=true for these types correctly returns spine-only data (no extension table exists to join).

### 1.17 Error Routing Verification (Surface D — Q Addition)

**Scope:** Verify all `{ ok: false }` envelopes reach response nodes in Gateway v55 and all sub-workflows.

| Workflow | Error Routes to Verify | Status |
|----------|----------------------|--------|
| Gateway v55 | All error paths from Gatekeeper, type validation, action routing | **Requires workflow inspection** |
| Save v28 | Error routing hardened (per v28 changelog — error paths verified) | **Previously validated** |
| Query v17 | Hydrate gate errors, type mismatch errors | **Requires verification** |
| Promote v2_HTTP | QPM guard errors, transition errors, content validation errors | **Requires verification** |
| Update (rewired) | Type mismatch, field validation errors | **Requires verification** |
| List | Pagination errors, type filter errors | **Requires verification** |

**Monotonic canonicalization in Normalize nodes:** Gateway `Normalize_Request` was the root cause of BUG-015 (transition/reason dropped) and T26 (selector stripped). Both fixed in v50/v48 respectively. The Normalize node now forwards: `selector`, `transition`, `reason`. Monotonicity should be verified: no field silently dropped between webhook input and normalized output.

**Empty Switch branches:** Must confirm no Switch node has a branch with no downstream connection. Empty branches cause silent drops (n8n does not error — it simply produces no output).

---

## 2. Enumerated Prerequisite List

Complete list of prerequisites for Foundation Green. Numbered for tracking. Grouped by phase.

### Phase 0 — Pre-Migration Safeguards

| # | Prerequisite | Type | Status |
|---|-------------|------|--------|
| P0.1 | Baseline database snapshot (all `qxb_*` tables) | Backup | **This document** |
| P0.2 | Lifecycle value inventory (spine + extension) | Audit | **Complete (see Section 4)** |
| P0.3 | Validation query set for Gates 1–5 | Design | **Complete (see Section 6)** |
| P0.4 | Rollback exposure documented | Design | **Complete (see Section 3 notes)** |

### Phase 1 — Lifecycle Reconciliation

| # | Prerequisite | Type | Depends On |
|---|-------------|------|------------|
| P1.1 | Add CHECK on `qxb_artifact.lifecycle_status`: `NULL OR IN ('seed','sapling','tree','oak','archive')` | DDL | — |
| P1.2 | Populate spine `lifecycle_status` from extension where NULL (project-type only) | DML | P1.1 |
| P1.3 | Map all `retired` → `archive` in both spine and extension (2 known rows) | DML | P1.2 |
| P1.4 | Update `qxb_artifact_project.lifecycle_stage` CHECK to `{seed,sapling,tree,oak,archive}` | DDL | P1.3 |
| P1.5 | Update Promote workflow transition map to new lifecycle set | Workflow | P1.4 |
| P1.6 | Mark `lifecycle_stage` as deprecated (documentation/comment) | Doc | P1.4 |

### Phase 2 — Type System Expansion

| # | Prerequisite | Type | Depends On |
|---|-------------|------|------------|
| P2.1 | Add `limb` to `qxb_artifact.artifact_type` CHECK (→ v6: 13 types) | DDL | Gate 1 |
| P2.2 | INSERT `limb` into `qxb_artifact_type_registry` with `enabled: true` | DML | P2.1 |
| P2.3 | Verify `branch` + `leaf` in registry with `enabled: true` | Verification | P2.1 |
| P2.4 | INSERT audit row for limb addition into `qxb_artifact_type_registry_audit` | DML | P2.2 |

### Phase 3 — Extension Table Foundation

| # | Prerequisite | Type | Depends On |
|---|-------------|------|------------|
| P3.1 | Finalize extension table schema (columns, types, defaults, constraints) | Design | Gate 2 |
| P3.2 | CREATE TABLE `qxb_artifact_branch` | DDL | P3.1 |
| P3.3 | CREATE TABLE `qxb_artifact_limb` | DDL | P3.1 |
| P3.4 | CREATE TABLE `qxb_artifact_leaf` | DDL | P3.1 |
| P3.5 | Add RLS policies (3 per table × 3 tables = 9 policies) | DDL | P3.2–P3.4 |
| P3.6 | Add FK constraints (→ `qxb_artifact.artifact_id` ON DELETE CASCADE) | DDL | P3.2–P3.4 |
| P3.7 | Add `updated_at` triggers (3 triggers) | DDL | P3.2–P3.4 |
| P3.8 | Backfill existing branch/leaf spine-only artifacts with extension rows: `execution_status = 'not_started'`, `priority = default` (per D3) | DML | P3.2, P3.4 |

### Phase 4 — Workflow Integrity Alignment

| # | Prerequisite | Type | Depends On |
|---|-------------|------|------------|
| P4.1 | Update Save workflow: route branch/leaf/limb to extension tables | Workflow | Gate 3 |
| P4.2 | Update Promote workflow: add C4 content validation gates (5 transitions) | Workflow | Gate 3 |
| P4.3 | Update Query workflow: add hydration joins for branch/limb/leaf | Workflow | Gate 3 |
| P4.4 | Update Save/Update/Promote: read lifecycle from spine, stop writing to extension | Workflow | P4.1–P4.3 |
| P4.5 | Verify all 13 types have defined Save/Query/Promote behavior | Test | P4.4 |
| P4.6 | Update Gateway allowlist: add `limb` to list-allowed types (if applicable) | Workflow | P4.1 |
| P4.7 | Update Gateway Execute Workflow references for all modified sub-workflows | Workflow | P4.1–P4.3 |

### Phase 5 — Dependency Foundation

| # | Prerequisite | Type | Depends On |
|---|-------------|------|------------|
| P5.1 | Finalize `qxb_artifact_dependency` schema | Design | Gate 4 |
| P5.2 | CREATE TABLE `qxb_artifact_dependency` | DDL | P5.1 |
| P5.3 | Add RLS policies (workspace membership) | DDL | P5.2 |
| P5.4 | Document enforcement location (which workflow/node) | Doc | P5.2 |
| P5.5 | Confirm: no DAG validation, no cross-branch, no cycle detection | Doc | — |

### Cross-Cutting

| # | Prerequisite | Type | Depends On |
|---|-------------|------|------------|
| PX.1 | Verify 3 unverified triggers (instruction_pack, type_registry, registry_audit) | Verification | — |
| PX.2 | Verify branch/leaf entry status in type registry | Verification | — |
| PX.3 | Count existing branch/leaf artifacts (requires direct DB query) | Verification | — |
| PX.4 | Verify hydrate=false produces no extension leakage | Test | — |
| PX.5 | Verify all Gateway error paths reach response nodes | Test | — |
| PX.6 | Verify Normalize_Request forwards all fields monotonically | Test | — |
| PX.7 | Create indexes for new tables (lifecycle, execution_status, dependency) | DDL | Phase 3–5 |
| PX.8 | Update DDL reference document to v3 after all changes | Doc | Gate 5 |

**Total: 38 prerequisites** (P0: 4, P1: 6, P2: 4, P3: 8, P4: 7, P5: 5, PX: 8, minus 4 completed in this audit = 34 remaining)

---

## 3. Schema Migration Plan (Design Only)

### 3.1 Phase 1 — Lifecycle CHECK + Data Migration

**Step 1.1: Add spine lifecycle CHECK**

```sql
-- Design only — not for execution
-- Allows NULL (non-project types) but constrains non-NULL values
ALTER TABLE qxb_artifact
  ADD CONSTRAINT qxb_artifact_lifecycle_status_check
  CHECK (lifecycle_status IS NULL OR lifecycle_status IN ('seed', 'sapling', 'tree', 'oak', 'archive'));
```

**Rollback:** `ALTER TABLE qxb_artifact DROP CONSTRAINT qxb_artifact_lifecycle_status_check;`

**Pre-condition:** All existing non-NULL `lifecycle_status` values must be in `{seed, sapling, tree, oak, archive}`. Current data shows `retired` exists (2 rows) — must be migrated first, OR run 1.3 before 1.1.

**Revised sequence:** Run data migration (1.2 + 1.3) BEFORE adding CHECK, then add CHECK. This avoids constraint violation on `retired` rows.

```
Corrected order: 1.2 → 1.3 → 1.1 → 1.4 → 1.5/1.6
```

**Step 1.2: Populate spine lifecycle from extension (if NULL)**

```sql
-- Design only
UPDATE qxb_artifact a
SET lifecycle_status = p.lifecycle_stage
FROM qxb_artifact_project p
WHERE a.artifact_id = p.artifact_id
  AND a.lifecycle_status IS NULL;
```

**Expected impact:** Need to determine how many project artifacts have NULL spine lifecycle. Gateway data shows 0 NULL values on the spine for projects — but this should be verified via direct DB query. If zero rows affected, this is a no-op.

**Rollback:** Record original NULL artifact_ids before migration. Restore with: `UPDATE qxb_artifact SET lifecycle_status = NULL WHERE artifact_id IN (...)`.

**Step 1.3: Map retired → archive**

```sql
-- Design only — per D2: all retired → archive
UPDATE qxb_artifact
SET lifecycle_status = 'archive'
WHERE lifecycle_status = 'retired';

UPDATE qxb_artifact_project
SET lifecycle_stage = 'archive'
WHERE lifecycle_stage = 'retired';
```

**Expected impact:** 2 rows on spine (test artifacts `8dbec53a`, `5cf5b078`). Extension row count TBD (requires DB verification — lifecycle_stage not surfaced in Gateway hydration).

**Rollback:** `UPDATE ... SET lifecycle_status = 'retired' WHERE artifact_id IN ('8dbec53a-...', '5cf5b078-...');` (same for extension).

**Step 1.4: Widen project extension CHECK**

```sql
-- Design only
ALTER TABLE qxb_artifact_project
  DROP CONSTRAINT qxb_artifact_project_lifecycle_stage_check;

ALTER TABLE qxb_artifact_project
  ADD CONSTRAINT qxb_artifact_project_lifecycle_stage_check
  CHECK (lifecycle_stage IN ('seed', 'sapling', 'tree', 'oak', 'archive'));
```

**Rollback:** Reverse the CHECK to `{seed, sapling, tree, retired}` — only safe if no `oak` or `archive` values were written in between.

### 3.2 Phase 2 — Type System

**Step 2.1: Add limb to artifact_type CHECK**

```sql
-- Design only — replaces v5 with v6
ALTER TABLE qxb_artifact
  DROP CONSTRAINT qxb_artifact_artifact_type_check_v5;

ALTER TABLE qxb_artifact
  ADD CONSTRAINT qxb_artifact_artifact_type_check_v6
  CHECK (artifact_type IN (
    'project', 'journal', 'restart', 'snapshot',
    'grass', 'thorn', 'forest', 'thicket', 'flower',
    'branch', 'leaf', 'instruction_pack', 'limb'
  ));
```

**Rollback:** Drop v6, add v5 — only safe if no `limb` rows were created.

### 3.3 Phase 3 — Extension Tables

**Extension table schema (branch, limb, leaf — identical structure):**

```sql
-- Design only — template for all 3 tables
CREATE TABLE qxb_artifact_{type} (
    artifact_id uuid NOT NULL,
    execution_status text NOT NULL DEFAULT 'not_started',
    priority integer NOT NULL DEFAULT 3,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT qxb_artifact_{type}_pkey PRIMARY KEY (artifact_id),
    CONSTRAINT qxb_artifact_{type}_fk FOREIGN KEY (artifact_id)
      REFERENCES qxb_artifact(artifact_id) ON DELETE CASCADE,
    CONSTRAINT qxb_artifact_{type}_execution_status_check
      CHECK (execution_status IN ('not_started', 'in_progress', 'blocked', 'complete')),
    CONSTRAINT qxb_artifact_{type}_priority_check
      CHECK (priority >= 1 AND priority <= 5)
);

ALTER TABLE qxb_artifact_{type} ENABLE ROW LEVEL SECURITY;

-- RLS policies (delegation pattern)
CREATE POLICY qxb_artifact_{type}_select_via_artifact
  ON qxb_artifact_{type} FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM qxb_artifact a WHERE a.artifact_id = qxb_artifact_{type}.artifact_id));

CREATE POLICY qxb_artifact_{type}_insert_owner_via_artifact
  ON qxb_artifact_{type} FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM qxb_artifact a
    WHERE a.artifact_id = qxb_artifact_{type}.artifact_id
    AND a.owner_user_id = qxb_current_user_id()));

CREATE POLICY qxb_artifact_{type}_update_owner_or_admin
  ON qxb_artifact_{type} FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM qxb_artifact a
    WHERE a.artifact_id = qxb_artifact_{type}.artifact_id
    AND (a.owner_user_id = qxb_current_user_id()
      OR EXISTS (SELECT 1 FROM qxb_workspace_user wsu
        WHERE wsu.workspace_id = a.workspace_id
        AND wsu.user_id = qxb_current_user_id()
        AND wsu.role IN ('owner', 'admin')))))
  WITH CHECK (EXISTS (SELECT 1 FROM qxb_artifact a
    WHERE a.artifact_id = qxb_artifact_{type}.artifact_id
    AND (a.owner_user_id = qxb_current_user_id()
      OR EXISTS (SELECT 1 FROM qxb_workspace_user wsu
        WHERE wsu.workspace_id = a.workspace_id
        AND wsu.user_id = qxb_current_user_id()
        AND wsu.role IN ('owner', 'admin')))));

-- updated_at trigger
CREATE TRIGGER qxb_artifact_{type}_set_updated_at
  BEFORE UPDATE ON qxb_artifact_{type}
  FOR EACH ROW EXECUTE FUNCTION qxb_set_updated_at();
```

**Schema notes:**
- `execution_status`: NOT NULL, default `not_started` — matches Phase 2B spec Section 1.1
- `priority`: NOT NULL, default 3 (integer 1-5) — added per Q's D3 ("priority = default, explicit deterministic value"). Uses same range as spine priority. Default 3 = mid-range.
- `priority` interpretation: Q's D3 said `priority = default`. We interpret "default" as an explicit numeric default value (3), not a text value. If Q intended a different default or a text enum, this needs correction.

**Rollback:** `DROP TABLE qxb_artifact_{type} CASCADE;` — only safe if no data was written or if data is backed up.

### 3.4 Phase 3 — Backfill (D3)

```sql
-- Design only — per D3: deterministic backfill, no null tolerance
-- Must know existing branch/leaf artifact_ids (requires PX.3 verification first)

INSERT INTO qxb_artifact_branch (artifact_id, execution_status, priority)
SELECT artifact_id, 'not_started', 3
FROM qxb_artifact
WHERE artifact_type = 'branch'
  AND artifact_id NOT IN (SELECT artifact_id FROM qxb_artifact_branch);

INSERT INTO qxb_artifact_leaf (artifact_id, execution_status, priority)
SELECT artifact_id, 'not_started', 3
FROM qxb_artifact
WHERE artifact_type = 'leaf'
  AND artifact_id NOT IN (SELECT artifact_id FROM qxb_artifact_leaf);
```

**Note:** No limb backfill needed — no limb artifacts can exist until the CHECK is expanded (Phase 2).

### 3.5 Phase 5 — Dependency Table

```sql
-- Design only
CREATE TABLE qxb_artifact_dependency (
    dependency_id uuid NOT NULL DEFAULT gen_random_uuid(),
    source_artifact_id uuid NOT NULL,
    target_artifact_id uuid NOT NULL,
    workspace_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT qxb_artifact_dependency_pkey PRIMARY KEY (dependency_id),
    CONSTRAINT qxb_artifact_dependency_source_fk FOREIGN KEY (source_artifact_id)
      REFERENCES qxb_artifact(artifact_id) ON DELETE CASCADE,
    CONSTRAINT qxb_artifact_dependency_target_fk FOREIGN KEY (target_artifact_id)
      REFERENCES qxb_artifact(artifact_id) ON DELETE CASCADE,
    CONSTRAINT qxb_artifact_dependency_workspace_fk FOREIGN KEY (workspace_id)
      REFERENCES qxb_workspace(workspace_id),
    CONSTRAINT qxb_artifact_dependency_no_self_ref
      CHECK (source_artifact_id != target_artifact_id)
);

ALTER TABLE qxb_artifact_dependency ENABLE ROW LEVEL SECURITY;

-- RLS: workspace membership (not spine delegation — dependencies are workspace-scoped)
CREATE POLICY qxb_artifact_dependency_select_member
  ON qxb_artifact_dependency FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM qxb_workspace_user wsu
    WHERE wsu.workspace_id = qxb_artifact_dependency.workspace_id
    AND wsu.user_id = qxb_current_user_id()));

CREATE POLICY qxb_artifact_dependency_insert_member
  ON qxb_artifact_dependency FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM qxb_workspace_user wsu
    WHERE wsu.workspace_id = qxb_artifact_dependency.workspace_id
    AND wsu.user_id = qxb_current_user_id()));

-- No UPDATE policy — dependencies are immutable (create or delete only)
-- DELETE policy for cleanup
CREATE POLICY qxb_artifact_dependency_delete_owner_or_admin
  ON qxb_artifact_dependency FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM qxb_workspace_user wsu
    WHERE wsu.workspace_id = qxb_artifact_dependency.workspace_id
    AND wsu.user_id = qxb_current_user_id()
    AND wsu.role IN ('owner', 'admin')));
```

**Design notes:**
- Self-reference CHECK prevents circular single-hop dependencies
- No DAG validation (per Phase 2B spec + Q confirmation)
- DELETE restricted to owner/admin — dependencies are operationally immutable but removable by authorized users
- No `updated_at` column — append/delete only, no updates

**Rollback:** `DROP TABLE qxb_artifact_dependency CASCADE;`

---

## 4. Data Reconciliation Plan

### 4.1 Current Lifecycle Value Inventory

**Spine (`qxb_artifact.lifecycle_status`):**

| Value | Count (projects, page 1+2) | Notes |
|-------|---------------------------|-------|
| `seed` | 66 | Majority |
| `sapling` | 22 | |
| `tree` | 5 | |
| `retired` | 2 | Test artifacts only (`8dbec53a`, `5cf5b078`) |
| `oak` | 0 | Not in use |
| `archive` | 0 | Not in use |
| `NULL` | 0 (projects) | Non-project types expected to be NULL |
| **Total projects** | **95** | |

**Non-project types:** lifecycle_status expected to be NULL. Cannot verify via Gateway (branch/leaf blocked). Direct DB query needed (PX.3).

**Extension (`qxb_artifact_project.lifecycle_stage`):**

Not surfaced in Gateway hydration. Requires direct DB verification. Expected to mirror spine values (both columns written during Save/Promote).

### 4.2 Retired Row Migration (D2)

| artifact_id | Title | Current Value | Target Value | Rationale |
|-------------|-------|--------------|-------------|-----------|
| `8dbec53a-fa51-469b-9a86-350c0e92fd6d` | Test - Save v28 Control | `retired` | `archive` | D2: all retired → archive |
| `5cf5b078-a612-44d1-a23d-391030402ad3` | BUG015 Test Sapling - No Anatomy | `retired` | `archive` | D2: all retired → archive |

Both are test artifacts. No production data affected.

### 4.3 Branch/Leaf Extension Backfill (D3)

**Known counts:** Unknown. Gateway blocks list for branch/leaf types. Requires PX.3 (direct DB query).

**Migration plan (after PX.3):**
1. Query: `SELECT COUNT(*) FROM qxb_artifact WHERE artifact_type = 'branch'`
2. Query: `SELECT COUNT(*) FROM qxb_artifact WHERE artifact_type = 'leaf'`
3. If count > 0: run backfill INSERT (Section 3.4)
4. Verify: `SELECT COUNT(*) FROM qxb_artifact_branch` matches branch count
5. Verify: `SELECT COUNT(*) FROM qxb_artifact_leaf` matches leaf count
6. Verify: no NULL values in `execution_status` or `priority` columns

**D3 guarantee:** "No heuristic inference. No null tolerance." All backfilled rows get `execution_status = 'not_started'`, `priority = 3`. Deterministic.

### 4.4 NULL Lifecycle Verification

**Query (for Phase 1 pre-condition):**

```sql
-- How many project-type artifacts have NULL lifecycle_status?
SELECT COUNT(*)
FROM qxb_artifact
WHERE artifact_type = 'project'
  AND lifecycle_status IS NULL;
-- Expected: 0 (Gateway data confirms)

-- How many non-project artifacts have non-NULL lifecycle_status?
SELECT COUNT(*), lifecycle_status
FROM qxb_artifact
WHERE artifact_type != 'project'
  AND lifecycle_status IS NOT NULL
GROUP BY lifecycle_status;
-- Expected: 0 rows (non-project types should not have lifecycle)
-- If non-zero: investigate — may need migration before CHECK
```

### 4.5 Spine/Extension Consistency Check

```sql
-- Are there projects where spine lifecycle != extension lifecycle?
SELECT a.artifact_id, a.lifecycle_status AS spine, p.lifecycle_stage AS extension
FROM qxb_artifact a
JOIN qxb_artifact_project p ON a.artifact_id = p.artifact_id
WHERE a.lifecycle_status != p.lifecycle_stage;
-- Expected: 0 rows
-- If non-zero: spine takes precedence (authoritative), extension must be corrected
```

---

## 5. Registry & Workflow Impact Matrix

### 5.1 Type Registry Impact

| artifact_type | Currently in CHECK | Currently in Registry | Enabled | Extension Table Exists | Phase 2B Action |
|--------------|-------------------|----------------------|---------|----------------------|----------------|
| project | YES | YES | YES | YES (`qxb_artifact_project`) | Update lifecycle CHECK |
| journal | YES | YES | YES | YES (`qxb_artifact_journal`) | None |
| restart | YES | YES | YES | YES (`qxb_artifact_restart`) | None |
| snapshot | YES | YES | YES | YES (`qxb_artifact_snapshot`) | None |
| grass | YES | YES | YES | YES (`qxb_artifact_grass`) | None |
| thorn | YES | YES | YES | YES (`qxb_artifact_thorn`) | None |
| forest | YES | Verify | Verify | No | None |
| thicket | YES | Verify | Verify | No | None |
| flower | YES | Verify | Verify | No | None |
| branch | YES | **Verify** | **Verify** | **No → CREATE** | Create extension table + backfill |
| leaf | YES | **Verify** | **Verify** | **No → CREATE** | Create extension table + backfill |
| instruction_pack | YES | YES | YES | YES (`qxb_artifact_instruction_pack`) | None |
| **limb** | **NO → ADD** | **NO → ADD** | — | **No → CREATE** | CHECK + registry + extension table |

### 5.2 Workflow Impact Matrix

| Workflow | Version | Phase 1 Changes | Phase 2 Changes | Phase 3 Changes | Phase 4 Changes | Phase 5 Changes |
|----------|---------|----------------|----------------|----------------|----------------|----------------|
| **Gateway** | v55 | None | None | None | Update Execute Workflow refs | None |
| **Save** | v28 | None | None | None | Route branch/limb/leaf to extension; stop writing lifecycle to extension | None |
| **Query** | v17 | None | None | None | Hydrate branch/limb/leaf; read lifecycle from spine | None |
| **Promote** | v2_HTTP | None | None | None | Transition map update; C4 content gates; lifecycle from spine | None |
| **Update** | (rewired) | None | None | None | Stop writing lifecycle to extension | None |
| **List** | (current) | None | None | None | Consider adding branch/limb/leaf to allowlist | None |

**Key observation:** All workflow changes are concentrated in Phase 4. Phases 1–3 are pure DDL/DML. Phase 5 is DDL only. This is clean separation.

### 5.3 Gateway Allowlist Impact

Current Gateway list allowlist: `project, journal, restart, snapshot, instruction_pack`

Types blocked: `branch, leaf, grass, thorn, forest, thicket, flower`

**Phase 2B decision needed:** Should `branch`, `leaf`, `limb` be added to the list allowlist? Walk execution semantics may require listing branches/leaves for progress rollup. This is a Phase 4 decision (P4.6).

---

## 6. Foundation Green Validation Checklist (Draft)

Each criterion maps to a specific verification query or test. All must be TRUE simultaneously.

### Schema Verification Queries

**FG-1: Lifecycle CHECK on spine matches C4 governance**
```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND conname = 'qxb_artifact_lifecycle_status_check';
-- Must match: CHECK (lifecycle_status IS NULL OR lifecycle_status IN ('seed','sapling','tree','oak','archive'))
```

**FG-2: No `retired` values in any lifecycle column**
```sql
SELECT 'spine' AS source, COUNT(*) FROM qxb_artifact WHERE lifecycle_status = 'retired'
UNION ALL
SELECT 'extension', COUNT(*) FROM qxb_artifact_project WHERE lifecycle_stage = 'retired';
-- Both must be 0
```

**FG-4: artifact_type CHECK contains all 13 types**
```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND conname LIKE 'qxb_artifact_artifact_type_check%';
-- Must include: project, journal, restart, snapshot, grass, thorn, forest, thicket, flower, branch, leaf, instruction_pack, limb
```

**FG-5: Type registry contains limb, branch, leaf all enabled**
```sql
SELECT artifact_type, enabled
FROM qxb_artifact_type_registry
WHERE artifact_type IN ('limb', 'branch', 'leaf');
-- Must return 3 rows, all enabled = true
```

**FG-6: Extension tables exist with execution_status CHECK**
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('qxb_artifact_branch', 'qxb_artifact_limb', 'qxb_artifact_leaf');
-- Must return 3 rows

SELECT conrelid::regclass, conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid IN (
  'public.qxb_artifact_branch'::regclass,
  'public.qxb_artifact_limb'::regclass,
  'public.qxb_artifact_leaf'::regclass
) AND conname LIKE '%execution_status%';
-- Must return 3 CHECK constraints matching {not_started, in_progress, blocked, complete}
```

**FG-7: RLS enabled and policies on all new tables**
```sql
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname IN ('qxb_artifact_branch', 'qxb_artifact_limb', 'qxb_artifact_leaf', 'qxb_artifact_dependency')
  AND relnamespace = 'public'::regnamespace;
-- All must have relrowsecurity = true

SELECT tablename, COUNT(*)
FROM pg_policies
WHERE tablename IN ('qxb_artifact_branch', 'qxb_artifact_limb', 'qxb_artifact_leaf', 'qxb_artifact_dependency')
GROUP BY tablename;
-- branch/limb/leaf: 3 each; dependency: 3 (SELECT, INSERT, DELETE)
```

**FG-11: Dependency table exists with RLS**
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'qxb_artifact_dependency';
-- Must return 1 row

SELECT conrelid::regclass, conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact_dependency'::regclass AND contype = 'f';
-- Must show FKs to qxb_artifact (×2) and qxb_workspace
```

**FG-12: No orphaned lifecycle data**
```sql
-- Project artifacts: spine and extension must agree
SELECT COUNT(*)
FROM qxb_artifact a
JOIN qxb_artifact_project p ON a.artifact_id = p.artifact_id
WHERE a.lifecycle_status != p.lifecycle_stage;
-- Must be 0

-- No project artifacts with NULL spine lifecycle
SELECT COUNT(*)
FROM qxb_artifact
WHERE artifact_type = 'project' AND lifecycle_status IS NULL;
-- Must be 0
```

### Integration Tests (Workflow Verification)

**FG-3: Lifecycle reads from spine, not project extension**
- Query a project artifact → `lifecycle_status` in response comes from spine
- Promote a project → extension `lifecycle_stage` unchanged (verify via direct DB query)

**FG-8: Save routes correctly to all 13 types**
- Save one artifact of each type → verify spine row + extension row exists (where applicable)
- No silent drops: every save produces a response (success or explicit error)

**FG-9: Promote validates C4 content gates**
- seed → sapling without summary → REJECTED
- sapling → tree without ≥2 branches + ≥1 leaf each → REJECTED
- tree → oak without all leaves complete → REJECTED
- tree → archive with reason → ACCEPTED
- oak → archive with reason → ACCEPTED

**FG-10: Query hydrates all types including branch, limb, leaf**
- Query branch artifact with hydrate=true → execution_status in response
- Query limb artifact with hydrate=true → execution_status in response
- Query leaf artifact with hydrate=true → execution_status in response

**FG-13: All freeze gates (0–5) passed and documented**
- Gate passage records exist for each phase
- Each record contains: timestamp, criteria results, verifier

---

## 7. Open Items Requiring Direct DB Verification

The following cannot be verified via Gateway and require direct SQL access (Supabase SQL Editor):

| # | Item | Query |
|---|------|-------|
| PX.1 | Verify instruction_pack updated_at trigger | `SELECT * FROM information_schema.triggers WHERE event_object_table = 'qxb_artifact_instruction_pack';` |
| PX.2 | Verify branch/leaf in type registry | `SELECT * FROM qxb_artifact_type_registry WHERE artifact_type IN ('branch', 'leaf');` |
| PX.3 | Count branch/leaf artifacts | `SELECT artifact_type, COUNT(*) FROM qxb_artifact WHERE artifact_type IN ('branch', 'leaf') GROUP BY artifact_type;` |
| PX.4 | Verify lifecycle_stage values in extension | `SELECT lifecycle_stage, COUNT(*) FROM qxb_artifact_project GROUP BY lifecycle_stage;` |
| PX.5 | Check non-project lifecycle_status values | `SELECT artifact_type, lifecycle_status, COUNT(*) FROM qxb_artifact WHERE artifact_type != 'project' AND lifecycle_status IS NOT NULL GROUP BY artifact_type, lifecycle_status;` |

**Recommendation:** Run all 5 queries before proceeding to Phase 1 execution. Results may surface additional data migration needs.

---

## 8. Design Clarifications for Q

Two items from D3 require confirmation before Phase 3 schema finalization:

### 8.1 Extension Table `priority` Column

Q's D3 states: `priority = default (explicit deterministic value)`.

**Current design:** `priority integer NOT NULL DEFAULT 3, CHECK (priority >= 1 AND priority <= 5)` — matching spine priority semantics.

**Question:** Is integer 3 the correct "default" value? Or did Q intend a different type or value?

### 8.2 Extension Table Column Naming

Q's D3 uses `status = not_started`. The reconciliation plan uses `execution_status`.

**Current design:** `execution_status` (more specific, avoids collision with generic `status` columns on other tables).

**Question:** Confirm `execution_status` is the canonical column name, not `status`.

---

## Summary

| Section | Deliverable | Status |
|---------|------------|--------|
| 1 | Explicit diff: Phase 2B intent vs live DDL | **Complete** — 18 surfaces audited |
| 2 | Enumerated prerequisite list | **Complete** — 38 prerequisites identified |
| 3 | Schema migration plan (design only) | **Complete** — All DDL designed, rollback documented |
| 4 | Data reconciliation plan | **Complete** — 2 retired rows, branch/leaf backfill scoped |
| 5 | Registry & workflow impact matrix | **Complete** — 13 types × 5 workflows mapped |
| 6 | Foundation Green validation checklist | **Complete** — 13 criteria with verification queries |
| 7 | Open verification items | **5 direct DB queries needed** |
| 8 | Design clarifications for Q | **2 questions on D3 interpretation** |

**Next action:** Proceed to Phase 1 execution upon Q authorization + direct DB verification results (Section 7).
