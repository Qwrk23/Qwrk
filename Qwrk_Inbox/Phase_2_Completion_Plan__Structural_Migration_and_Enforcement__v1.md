# Phase 2 Completion Plan — Structural Migration & Enforcement

**Status:** Plan — Awaiting Q1-Q3 Answers + Block Order Confirmation
**Author:** CC (Build Executor)
**Date:** 2026-02-16
**Governing Documents:**
- Authoritative DDL: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` (v2.2)
- Reconciliation Plan: `docs/governance/Phase_2B__Foundation_Migration_Reconciliation_Plan__v1.md`
- Phase 0 Audit: `docs/governance/Phase_2B__Phase_0_DDL_Reconciliation_Audit__v1.md`
- Limb PRD: `docs/prd/PRD__North_Star_v0.4__Limbs__v1.0.md`
- Governance Lock: `2478953e` (C2/C3/C4)
- Governance Gate: `765dcdfc` (Phase 2B)
- Phase 1 Sealed Snapshot: `a5dcf3bb`

**Constraint:** This document contains no executable SQL. Plan only. All SQL execution requires explicit authorization.

---

## CHANGELOG

### v1 — 2026-02-16

**What changed:** Initial Phase 2 Completion Plan.

**Why:** Phase 1 is sealed. Phase 2 is partial (execution_status column on spine, branch/leaf backfilled). This plan identifies remaining structural work to complete Phase 2 and close the gap between locked governance, live DDL, and Gateway type registry.

**Scope of impact:** Defines migration blocks A–D with ordering, risk assessment, data safety plan, verification checklist, and explicit non-goals. No implementation.

**How to validate:** Cross-reference every finding against live DDL (v2.2), MEMORY.md, OPEN_THREADS.md, and Phase 2B governance documents.

---

## Table of Contents

1. [Current State Audit](#1-current-state-audit)
2. [Blocking Questions](#2-blocking-questions)
3. [Migration Blocks (Ordered)](#3-migration-blocks-ordered)
4. [Data Safety Plan](#4-data-safety-plan)
5. [Gateway / Registry Impact](#5-gateway--registry-impact)
6. [Verification Checklist](#6-verification-checklist)
7. [Explicit Non-Goals](#7-explicit-non-goals)
8. [Proposed Migration Order](#8-proposed-migration-order)

---

## 1. Current State Audit

### 1.1 Phase 1 Sealed Work (Applied to Live DB, NOT Reflected in DDL File)

Per MEMORY.md drift log (2026-02-15) and Phase 1 sealed snapshot `a5dcf3bb`:

| Change | Live DB Status | DDL File Status |
|--------|---------------|-----------------|
| Spine `lifecycle_status` CHECK: `IS NULL OR IN (seed, sapling, tree, oak, archive)` | **APPLIED** | **NOT REFLECTED** — DDL shows no CHECK |
| 2 `retired` rows migrated to `archive` (test artifacts `8dbec53a`, `5cf5b078`) | **APPLIED** | N/A (data) |
| Branch/leaf `lifecycle_status` set to NULL | **APPLIED** | N/A (data) |

**UNVERIFIED (requires direct DB query):**

| Item | DDL File Shows | Possibly Updated Live? |
|------|---------------|----------------------|
| `qxb_artifact_project.lifecycle_stage` CHECK | `{seed, sapling, tree, retired}` | Unknown — T1 says "extension aligned" but no confirmation of CHECK update |
| `retired` in project extension data | 2 rows expected migrated | Unknown — extension `lifecycle_stage` values not surfaced by Gateway hydration |

### 1.2 Phase 2 Partial Work (Applied to Live DB, NOT Reflected in DDL File)

Per MEMORY.md and OPEN_THREADS T1:

| Change | Live DB Status | DDL File Status |
|--------|---------------|-----------------|
| `execution_status` column added to **spine** (`qxb_artifact`) | **EXISTS** (nullable, no CHECK) | **NOT REFLECTED** — column absent from DDL |
| Branch/leaf rows backfilled to `execution_status = 'not_started'` | **APPLIED** (on spine) | N/A (data) |
| `lifecycle_status` nullified for execution types (branch/leaf) | **APPLIED** | N/A (data) |

### 1.3 Current Constraints — What DDL Enforces vs. What Governance Requires

| Constraint | DDL File (v2.2) | Live DB (best knowledge) | Governance Target | Gap |
|-----------|----------------|--------------------------|-------------------|-----|
| Spine `lifecycle_status` CHECK | **NONE** | `IS NULL OR IN (seed,sapling,tree,oak,archive)` | Same as live | DDL lag only |
| Spine `execution_status` CHECK | **Column absent** | Column exists, **NO CHECK** | `{not_started, in_progress, blocked, complete}` | **CHECK MISSING** |
| Spine `priority` | nullable, range 1-5, no DEFAULT | Same as DDL | NOT NULL, DEFAULT 3, range 1-5 | **DEFAULT + NOT NULL MISSING** |
| Spine `artifact_type` CHECK v5 | 12 types (no `limb`) | Same as DDL | 13 types (+`limb`) | **`limb` MISSING** |
| Project ext `lifecycle_stage` CHECK | `{seed, sapling, tree, retired}` | **UNVERIFIED** — may still have `retired` | `{seed, sapling, tree, oak, archive}` or deprecated | **POSSIBLY STALE** |
| `qxb_artifact_limb` table | Does not exist | Does not exist | Must exist + RLS | **TABLE MISSING** |
| `limb` in type registry | Not present | Not present | `enabled: true` | **ENTRY MISSING** |
| DDL file reflects live state | v2.2 (2026-02-11) | Behind by Phase 1 + Phase 2 partial work | Must be current | **DDL FILE STALE** |

### 1.4 Architectural Finding — execution_status Location

**Critical divergence from Reconciliation Plan:**

The Reconciliation Plan (Phase 3, sections E5-E7) designed `execution_status` as a column on **extension tables** (branch/limb/leaf). The actual Phase 2 partial implementation placed `execution_status` on the **spine**.

| Aspect | Reconciliation Plan Design | Actual Implementation |
|--------|---------------------------|----------------------|
| `execution_status` location | Extension tables (branch, limb, leaf) | **Spine** (`qxb_artifact`) |
| NULL handling | NOT NULL on extension (only execution types have rows) | Nullable on spine (non-execution types are NULL) |
| Hydration impact | Query must join extension tables | Already on spine — no join needed |
| Dual-write risk | None (single source per type) | None (single column on spine) |

**Assessment:** Moving execution_status from spine to extension tables would require:
- Column removal from spine (data migration)
- Extension table creation with the column
- Backfill from spine to extension tables
- Workflow updates (Save writes to extension, Query joins extension)

This is the **same class of dual-column problem** that Phase 1 lifecycle reconciliation resolved (spine vs. project extension). Creating it again would be architectural regression.

**Recommendation:** Keep `execution_status` on spine. This mirrors the lifecycle_status pattern (NULL for non-applicable types, constrained values for applicable types). Add CHECK constraint to spine.

---

## 2. Blocking Questions

Before finalizing migration order, answers needed on **3 items**:

### Q1. Project Extension CHECK — Current Live State?

Was `qxb_artifact_project.lifecycle_stage` CHECK updated during Phase 1 sealed work?

- If **YES**: Block A is verification-only (confirm, update DDL file)
- If **NO**: Block A includes a live CHECK update (`{seed, sapling, tree, retired}` → `{seed, sapling, tree, oak, archive}`)

**Verification query (requires Supabase SQL Editor):**
```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact_project'::regclass AND contype = 'c';
```

### Q2. Limb Extension Table — Scope Confirmation

Since execution_status and priority are on the **spine** (not extension tables), the limb extension table would be a **minimal shell**:

```
qxb_artifact_limb: artifact_id (PK/FK), created_at, updated_at
```

**Question:** Is a shell extension table acceptable, or must the limb table carry execution-specific columns? If execution_status moves to extension tables (contradicting current spine-based implementation), that changes Block C significantly.

**Recommendation:** Shell table. Execution_status stays on spine. Extension table exists for class-table inheritance compliance and future limb-specific fields.

### Q3. Branch/Leaf Extension Tables — In Scope?

The Reconciliation Plan includes branch and leaf extension tables (Phase 3, P3.2 and P3.4). The user's requirements mention only limb. However:

- If execution_status is on the spine, branch/leaf extension tables would also be shells
- Creating all three maintains symmetry across execution types
- The Phase 2B containment tree includes "Phase 3 — Extension Tables" as a distinct branch

**Question:** Should this plan include branch and leaf extension tables, or only limb?

---

## 3. Migration Blocks (Ordered)

Presented in dependency order. Final ordering contingent on Q1-Q3 answers.

### Block A: Lifecycle Residual Verification & Alignment

**Purpose:** Confirm Phase 1 sealed work is fully applied. Close any remaining lifecycle gaps.

**Scope:** Verification-first. DDL changes only if Q1 reveals the project extension CHECK was not updated.

| Step | Action | Type | Risk |
|------|--------|------|------|
| A.1 | Verify spine `lifecycle_status` CHECK exists in live DB | Verification | None |
| A.2 | Verify project extension `lifecycle_stage` CHECK values in live DB (Q1) | Verification | None |
| A.3 | Verify 0 `retired` values in spine AND extension | Verification | None |
| A.4 | If A.2 reveals old CHECK: update project extension CHECK to `{seed, sapling, tree, oak, archive}` | DDL (conditional) | LOW |
| A.5 | If A.2 reveals old CHECK: verify no `retired` values in extension before constraint change | Pre-flight | None |

**Data reconciliation:** None expected (Phase 1 sealed). Verification only.

**Order of operations:** A.1 → A.2 → A.3 → (A.5 → A.4 if needed)

**Rollback:** A.4 can be reversed by restoring the old CHECK. No data changes.

**RLS impact:** None. No new tables or policies.

**Risk level:** **LOW** — Verification-primary. Conditional DDL is additive (widening a CHECK).

---

### Block B: Artifact Type Expansion (limb)

**Purpose:** Add limb as a recognized artifact type at schema, registry, and table level.

| Step | Action | Type | Risk |
|------|--------|------|------|
| B.1 | Add `limb` to spine `artifact_type` CHECK (v5 → v6, 13 types) | DDL | LOW |
| B.2 | INSERT `limb` into `qxb_artifact_type_registry` with `enabled: true` | DML | LOW |
| B.3 | Verify `branch` and `leaf` registry entries exist with `enabled: true` | Verification | None |
| B.4 | INSERT audit row into `qxb_artifact_type_registry_audit` for limb addition | DML | LOW |
| B.5 | CREATE TABLE `qxb_artifact_limb` (shell: artifact_id PK/FK, created_at, updated_at) | DDL | LOW |
| B.6 | Add FK constraint: `artifact_id` → `qxb_artifact.artifact_id` ON DELETE CASCADE | DDL | LOW |
| B.7 | Enable RLS on `qxb_artifact_limb` | DDL | LOW |
| B.8 | Create 3 RLS policies (SELECT/INSERT/UPDATE via spine delegation pattern) | DDL | LOW |
| B.9 | Create `updated_at` trigger | DDL | LOW |

**Data reconciliation:** None. No limb artifacts exist. No existing data affected.

**Order of operations:** B.1 → (B.2 ∥ B.3) → B.4 → B.5 → (B.6 ∥ B.7 ∥ B.9) → B.8

B.1 must be first (CHECK must allow `limb` before any limb-related operations). B.5 must precede B.6-B.9. B.2 and B.3 are independent and can run in parallel after B.1.

**Rollback considerations:**
- B.1: DROP v6 constraint, ADD v5 — safe only if no limb rows exist
- B.5-B.9: `DROP TABLE qxb_artifact_limb CASCADE;` — safe if no data written
- B.2: `DELETE FROM qxb_artifact_type_registry WHERE artifact_type = 'limb';`

**RLS impact:** New table follows existing delegation pattern (SELECT via artifact existence, INSERT via owner check, UPDATE via owner-or-admin check). No novel policy design.

**Risk level:** **LOW** — Fully additive. No existing data modified. No existing constraints altered (artifact_type CHECK is replaced but superset of previous).

**Extension table schema (recommended):**
```sql
CREATE TABLE qxb_artifact_limb (
    artifact_id uuid NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT qxb_artifact_limb_pkey PRIMARY KEY (artifact_id),
    CONSTRAINT qxb_artifact_limb_fk FOREIGN KEY (artifact_id)
      REFERENCES qxb_artifact(artifact_id) ON DELETE CASCADE
);
```

**Note:** If Q3 answer includes branch/leaf extension tables, identical shells would be created for `qxb_artifact_branch` and `qxb_artifact_leaf` with matching RLS and triggers.

---

### Block C: Execution Enforcement (status + priority)

**Purpose:** Add CHECK constraints and defaults to execution_status and priority on the spine. Backfill existing data.

**Architectural decision:** execution_status stays on **spine** (see Section 1.4 finding). This mirrors lifecycle_status: NULL for non-applicable types, constrained values for applicable types.

| Step | Action | Type | Risk |
|------|--------|------|------|
| C.1 | **Pre-flight:** Count rows where `execution_status NOT IN ('not_started','in_progress','blocked','complete') AND execution_status IS NOT NULL` | Verification | None |
| C.2 | **Pre-flight:** Count rows where `priority IS NULL` | Verification | None |
| C.3 | **Pre-flight:** Count rows where `priority NOT BETWEEN 1 AND 5 AND priority IS NOT NULL` | Verification | None |
| C.4 | Add `execution_status` CHECK: `IS NULL OR IN ('not_started','in_progress','blocked','complete')` | DDL | MEDIUM |
| C.5 | Backfill `priority` NULLs → 3 | DML | MEDIUM |
| C.6 | Add `priority` DEFAULT 3 | DDL | LOW |
| C.7 | Add `priority` NOT NULL | DDL | MEDIUM |

**Data reconciliation:**

- **C.1 pre-flight:** If any rows have invalid execution_status values (not NULL and not in the allowed set), they MUST be corrected before C.4. Phase 2 partial work backfilled branch/leaf to `not_started`; other types should be NULL. If C.1 returns > 0 rows, **ABORT and investigate**.

- **C.2/C.3 pre-flight:** Expect many NULL priority rows (journals, snapshots, restarts, branches, leaves, etc.). Range violations should be 0 (existing CHECK prevents out-of-range non-NULL values). NULL count determines backfill scope.

- **C.5 backfill:** `UPDATE qxb_artifact SET priority = 3 WHERE priority IS NULL;` — Affects potentially hundreds of rows. Safe because DEFAULT 3 is the governance-specified value. **Must run BEFORE C.7** (NOT NULL will reject NULLs).

**Order of operations:** C.1 → C.2 → C.3 → (ABORT if violations found) → C.4 → C.5 → C.6 → C.7

C.4 (execution_status CHECK) is independent of C.5-C.7 (priority enforcement). Could run in parallel, but sequential is safer.

C.5 MUST precede C.7 (backfill before NOT NULL).
C.6 can run before or after C.5 (DEFAULT only affects future INSERTs).

**Rollback considerations:**
- C.4: `DROP CONSTRAINT` — safe, no data changed
- C.5: Requires recording which artifact_ids had NULL priority before backfill. Reversible with: `UPDATE qxb_artifact SET priority = NULL WHERE artifact_id IN (...)`
- C.6: `ALTER TABLE qxb_artifact ALTER COLUMN priority DROP DEFAULT;`
- C.7: `ALTER TABLE qxb_artifact ALTER COLUMN priority DROP NOT NULL;` — safe but re-allows NULLs

**RLS impact:** None. No new tables or policies. CHECK constraints and DEFAULT don't affect RLS.

**Risk level:** **MEDIUM**

Risk factors:
1. **C.5 (priority backfill):** Mass UPDATE across all artifact types. Sets priority=3 on journals, snapshots, restarts, etc. — types that may not semantically need priority. This is irreversible without pre-migration artifact_id snapshots.
2. **C.7 (priority NOT NULL):** Permanent constraint. All future artifact inserts MUST provide priority (or accept DEFAULT 3). If any code path creates artifacts without priority, it will fail.
3. **C.4 (execution_status CHECK):** Should be safe IF Phase 2 partial backfill was complete. C.1 pre-flight catches violations.

**Design consideration — scoped NOT NULL:**

Making priority NOT NULL on the spine means governance types (snapshots, restarts) always have priority=3. Alternative: scoped CHECK that only requires NOT NULL for certain types:

```sql
CHECK (
  CASE
    WHEN artifact_type IN ('branch', 'leaf', 'limb', 'project') THEN priority IS NOT NULL
    ELSE TRUE
  END
)
```

This is more precise but introduces artifact_type coupling into the constraint. **Recommendation: follow the stated requirement (NOT NULL, DEFAULT 3 for all)** and flag the scope question. Universal priority is simpler and forward-compatible (any type can later use priority for sorting/filtering).

---

### Block D: Registry & Gateway Alignment (Plan Only — No Implementation)

**Purpose:** Define what must change in workflows after schema changes. No workflow edits in this plan.

#### D.1 Type Registry

| Type | Currently Registered | Action After Block B |
|------|---------------------|---------------------|
| `limb` | No | INSERT with `enabled: true` |
| `branch` | Present (enabled status unknown) | Verify `enabled: true` |
| `leaf` | Present (enabled status unknown) | Verify `enabled: true` |

Registry is consulted by Save workflow before allowing artifact creation. Until `limb` is in the registry, Save will reject limb artifacts regardless of CHECK constraint.

#### D.2 Gateway Workflow Impact Matrix

| Workflow | Current Version | Changes Required | When |
|----------|----------------|-----------------|------|
| **Save** (v28) | Routes to extension tables by type | Add limb route (insert shell extension row) | After Block B |
| **Query** (v17) | Hydrates by joining spine + extension | Add limb hydration join (shell — minimal fields) | After Block B |
| **Promote** (v2_HTTP) | Validates transitions against lifecycle map | Add `oak` and `archive` transitions if not already present; limb awareness for anatomy validation | After Block A verification |
| **Update** (rewired) | Writes to spine + extension by type | Add limb route | After Block B |
| **List** (current) | Allowlist: project, journal, restart, snapshot, instruction_pack | Consider adding branch, leaf, limb to allowlist | Phase 4 decision |
| **Gateway** (v55) | Execute Workflow references | Update all sub-workflow references after version bumps | After all sub-workflow updates |

#### D.3 Promote Validation — Transition Map

Current Promote v2_HTTP supports: `seed → sapling → tree` + `retired` (which should now be dead code).

Required additions for governance alignment:

| Transition | Gate | Priority |
|-----------|------|----------|
| `tree → oak` | All leaves complete, progress = 100% | Phase 4 (Walk) |
| `tree → archive` | Reason required | Phase 4 (Walk) |
| `oak → archive` | Retirement reason required | Phase 4 (Walk) |
| `seed → sapling` | Non-empty summary + reason | Phase 4 (Walk) — may already be enforced |

**Note:** These are C4 content validation gates. They are Phase 4 (Workflow Integrity) work per the Reconciliation Plan. Block D documents them but does NOT implement them.

#### D.4 Normalize Contract Risk

Gateway `Normalize_Request` has historically been the root cause of field-dropping bugs (T26: selector stripped; BUG-015: transition/reason dropped). Any new fields that must flow through the Gateway (e.g., `execution_status` on save/update) must be added to the normalizer.

**Required normalizer additions (Phase 4):**
- `execution_status: raw.execution_status ?? null` — for Save and Update operations on execution types
- No priority addition needed if priority is already forwarded (it's a spine field)

---

## 4. Data Safety Plan

### 4.1 Pre-Flight Queries (Must Pass Before Migration Proceeds)

Run these in Supabase SQL Editor BEFORE any DDL changes:

**PF-1: Spine lifecycle_status CHECK exists**
```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND conname LIKE '%lifecycle_status%';
-- EXPECTED: constraint with IS NULL OR IN (seed, sapling, tree, oak, archive)
-- IF MISSING: Phase 1 was not fully applied — ABORT and investigate
```

**PF-2: Project extension lifecycle_stage CHECK values (answers Q1)**
```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact_project'::regclass
  AND conname LIKE '%lifecycle_stage%';
-- EXPECTED: either {seed, sapling, tree, oak, archive} (Phase 1 updated)
--   OR: {seed, sapling, tree, retired} (Phase 1 did not update extension)
```

**PF-3: No retired values anywhere**
```sql
SELECT 'spine' AS source, lifecycle_status AS value, COUNT(*)
FROM qxb_artifact WHERE lifecycle_status = 'retired'
GROUP BY lifecycle_status
UNION ALL
SELECT 'extension', lifecycle_stage, COUNT(*)
FROM qxb_artifact_project WHERE lifecycle_stage = 'retired'
GROUP BY lifecycle_stage;
-- EXPECTED: 0 rows returned
-- IF > 0: Block A must include data migration before CHECK changes
```

**PF-4: execution_status column exists and has no invalid values**
```sql
-- Column existence
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'qxb_artifact' AND column_name = 'execution_status';
-- EXPECTED: 1 row (text, nullable)

-- Invalid values
SELECT execution_status, COUNT(*)
FROM qxb_artifact
WHERE execution_status IS NOT NULL
  AND execution_status NOT IN ('not_started', 'in_progress', 'blocked', 'complete')
GROUP BY execution_status;
-- EXPECTED: 0 rows
-- IF > 0: ABORT — invalid execution_status values must be corrected first
```

**PF-5: Priority value inventory**
```sql
SELECT
  COUNT(*) FILTER (WHERE priority IS NULL) AS null_count,
  COUNT(*) FILTER (WHERE priority IS NOT NULL) AS non_null_count,
  COUNT(*) FILTER (WHERE priority < 1 OR priority > 5) AS out_of_range_count
FROM qxb_artifact;
-- EXPECTED: out_of_range_count = 0
-- null_count tells us backfill scope
-- IF out_of_range > 0: ABORT — existing CHECK should prevent this, but verify
```

**PF-6: Non-project lifecycle_status contamination**
```sql
SELECT artifact_type, lifecycle_status, COUNT(*)
FROM qxb_artifact
WHERE artifact_type != 'project'
  AND lifecycle_status IS NOT NULL
GROUP BY artifact_type, lifecycle_status;
-- EXPECTED: 0 rows (only projects should have lifecycle_status)
-- IF > 0: investigate — may need cleanup before Block C
```

**PF-7: Branch/leaf artifact counts (for backfill awareness)**
```sql
SELECT artifact_type, COUNT(*)
FROM qxb_artifact
WHERE artifact_type IN ('branch', 'leaf')
GROUP BY artifact_type;
-- INFORMATIONAL: no abort condition, but needed for backfill planning
```

**PF-8: Branch/leaf in type registry**
```sql
SELECT artifact_type, enabled
FROM qxb_artifact_type_registry
WHERE artifact_type IN ('branch', 'leaf', 'limb');
-- EXPECTED: branch and leaf present with enabled=true
-- limb should be absent (added in Block B)
```

### 4.2 Abort Conditions

| Pre-Flight | Abort If | Reason |
|-----------|---------|--------|
| PF-1 | Spine lifecycle CHECK not found | Phase 1 sealed state not verified — cannot proceed |
| PF-3 | Any `retired` values remain | Block A must handle migration first |
| PF-4 | Invalid execution_status values exist | Constraint would reject existing data |
| PF-5 | Out-of-range priority values exist | Should be impossible (existing CHECK), but verify |
| PF-6 | Non-project types have lifecycle_status | Cross-contamination — must clean before execution_status CHECK |

### 4.3 Rollback Strategy

| Block | Reversible? | Method | Data Risk |
|-------|------------|--------|-----------|
| A (lifecycle verification) | Yes | DROP/ADD constraint | None — verification only |
| B (limb type expansion) | Yes | DROP constraint v6, ADD v5; DROP TABLE limb; DELETE registry rows | None if no limb data written |
| C.4 (execution_status CHECK) | Yes | DROP CONSTRAINT | None — no data changed |
| C.5 (priority backfill) | **Conditional** | Requires pre-backfill snapshot of NULL artifact_ids | **Lost original NULL state** without snapshot |
| C.6 (priority DEFAULT) | Yes | DROP DEFAULT | None |
| C.7 (priority NOT NULL) | Yes | DROP NOT NULL | None |

**Critical rollback dependency:** C.5 (priority backfill) is the ONLY step that modifies existing data irreversibly. A snapshot of `SELECT artifact_id FROM qxb_artifact WHERE priority IS NULL` must be captured BEFORE execution.

---

## 5. Gateway / Registry Impact

### 5.1 Workflows That Will Break if Constraints Change

| Change | Workflow Risk | Breakage Mode |
|--------|-------------|---------------|
| `limb` added to CHECK | None (additive) | N/A — no existing workflow creates limbs |
| `execution_status` CHECK added | **Save** — if Save sets invalid execution_status | Constraint violation on INSERT |
| `priority` NOT NULL | **Save** — if Save doesn't set priority | NOT NULL violation on INSERT |
| `priority` DEFAULT 3 | None (DEFAULT handles missing values) | N/A |

**Risk assessment:** Save v28 currently inserts artifacts. If Save does not explicitly set `priority`, the DEFAULT 3 will handle it. If Save explicitly sets `priority = NULL`, the NOT NULL constraint will reject. Need to verify Save workflow behavior.

**Mitigation:** Add `priority` DEFAULT 3 (C.6) BEFORE NOT NULL (C.7). This way, any Insert that omits priority gets the default. Only explicit NULL would fail.

### 5.2 What Must Be Updated After DDL

| Component | Update Required | Block Dependency |
|-----------|----------------|-----------------|
| Save v28 | Add limb route (extension table insert); ensure priority is never NULL | After Block B + C |
| Query v17 | Add limb hydration join | After Block B |
| Promote v2_HTTP | Verify transition map includes oak/archive; add limb to anatomy awareness | After Block A verification |
| Update (rewired) | Add limb route | After Block B |
| Gateway v55 | Update Execute Workflow references after sub-workflow version bumps | After all sub-workflow updates |
| Type registry | Add limb entry | Block B step B.2 |
| DDL file | Update to v2.3 (or v3) reflecting all live changes including Phase 1 sealed work | After all blocks complete |

### 5.3 Promote Validation Alignment

Current Promote reads lifecycle_status from the spine (Phase 1 sealed). Key considerations:

- Promote must NOT write to `qxb_artifact_project.lifecycle_stage` if that column is deprecated
- Promote transition map must include `oak` and `archive` as valid destinations
- Limb artifacts should not be promotable (limbs don't have lifecycle) — Promote should reject or ignore execution types

### 5.4 Normalize Contract Risk

If the Gateway normalizer does not forward `execution_status` on save/update operations, the value will be silently dropped (same bug class as T26 and BUG-015). This is a Phase 4 concern but must be documented now.

---

## 6. Verification Checklist

Concrete SQL queries that must pass AFTER migration:

**V-1: Lifecycle CHECK on spine (Phase 1 sealed — confirm still intact)**
```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND conname = 'qxb_artifact_lifecycle_status_check';
-- MUST contain: seed, sapling, tree, oak, archive + NULL tolerance
```

**V-2: No retired values anywhere**
```sql
SELECT COUNT(*) FROM qxb_artifact WHERE lifecycle_status = 'retired';
-- MUST be 0
SELECT COUNT(*) FROM qxb_artifact_project WHERE lifecycle_stage = 'retired';
-- MUST be 0
```

**V-3: artifact_type CHECK v6 with 13 types**
```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND conname LIKE 'qxb_artifact_artifact_type_check%';
-- MUST include all 13: project, journal, restart, snapshot, grass, thorn,
--   forest, thicket, flower, branch, leaf, instruction_pack, limb
```

**V-4: Limb in type registry**
```sql
SELECT artifact_type, enabled
FROM qxb_artifact_type_registry
WHERE artifact_type = 'limb';
-- MUST return 1 row with enabled = true
```

**V-5: Limb extension table exists with RLS**
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'qxb_artifact_limb';
-- MUST return 1 row

SELECT relrowsecurity FROM pg_class
WHERE relname = 'qxb_artifact_limb' AND relnamespace = 'public'::regnamespace;
-- MUST be true

SELECT COUNT(*) FROM pg_policies WHERE tablename = 'qxb_artifact_limb';
-- MUST be 3 (SELECT, INSERT, UPDATE)
```

**V-6: execution_status CHECK on spine**
```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND conname LIKE '%execution_status%';
-- MUST contain: not_started, in_progress, blocked, complete + NULL tolerance
```

**V-7: Priority enforcement**
```sql
SELECT column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'qxb_artifact' AND column_name = 'priority';
-- column_default MUST contain '3', is_nullable MUST be 'NO'

SELECT COUNT(*) FROM qxb_artifact WHERE priority IS NULL;
-- MUST be 0

SELECT COUNT(*) FROM qxb_artifact WHERE priority < 1 OR priority > 5;
-- MUST be 0
```

**V-8: No data violations (comprehensive)**
```sql
-- Execution_status: only valid values or NULL
SELECT COUNT(*) FROM qxb_artifact
WHERE execution_status IS NOT NULL
  AND execution_status NOT IN ('not_started','in_progress','blocked','complete');
-- MUST be 0

-- Lifecycle: only valid values or NULL
SELECT COUNT(*) FROM qxb_artifact
WHERE lifecycle_status IS NOT NULL
  AND lifecycle_status NOT IN ('seed','sapling','tree','oak','archive');
-- MUST be 0

-- No cross-contamination (informational — not a constraint, but governance expectation)
SELECT artifact_type, COUNT(*)
FROM qxb_artifact
WHERE artifact_type = 'project' AND lifecycle_status IS NULL
GROUP BY artifact_type;
-- EXPECTED: 0 rows (all projects should have lifecycle_status)
```

---

## 7. Explicit Non-Goals

Confirming this plan does **NOT** introduce:

| Excluded Item | Status |
|--------------|--------|
| Phase 2C schema enrichment (content validation fields, tagging enforcement) | **NOT INCLUDED** |
| Cross-tree dependency enforcement | **NOT INCLUDED** |
| Weighted rollups or progress calculation | **NOT INCLUDED** |
| Automation (scheduled triggers, cron, event-driven) | **NOT INCLUDED** |
| Calendar or timeline integration | **NOT INCLUDED** |
| Escalation logic | **NOT INCLUDED** |
| New artifact types beyond limb | **NOT INCLUDED** |
| Recurrence systems | **NOT INCLUDED** |
| Bidirectional cross-column constraint (execution types must have execution_status, lifecycle types must have lifecycle_status) | **NOT INCLUDED** — flagged as optional hardening, deferred |
| Branch/leaf extension table creation | **NOT INCLUDED** unless Q3 answer includes them |
| Dependency table (`qxb_artifact_dependency`) | **NOT INCLUDED** — that is Phase 5 per Reconciliation Plan |
| C4 content validation gates in Promote workflow | **NOT INCLUDED** — documented in Block D but not implemented |

---

## 8. Proposed Migration Order

```
Pre-Flight (PF-1 through PF-8)
  ↓ All pass?
  ↓ YES
Block A: Lifecycle Verification (A.1 → A.2 → A.3 → conditional A.4/A.5)
  ↓
Block B: Limb Type Expansion (B.1 → B.2‖B.3 → B.4 → B.5 → B.6‖B.7‖B.9 → B.8)
  ↓
Block C: Execution Enforcement (C.1→C.2→C.3 → C.4 → C.5 → C.6 → C.7)
  ↓
Post-Migration Verification (V-1 through V-8)
  ↓
DDL File Update (v2.2 → v2.3 — reflect all live changes including Phase 1 sealed work)
  ↓
Phase 2 Completion Snapshot
```

**Why this order:**
- Block A first: confirms Phase 1 sealed state is intact before building on it
- Block B before C: limb CHECK expansion is independent and low-risk; execution enforcement is higher risk (data modification)
- Block C last: priority backfill is the highest-risk step (mass UPDATE); everything else should be stable before it runs
- DDL file update after all changes: single update pass captures everything

**Risk posture summary:**

| Block | Risk | Data Modified | Reversible |
|-------|------|---------------|-----------|
| A | LOW | None (verification) | N/A |
| B | LOW | None (additive DDL + DML) | Yes (DROP/DELETE) |
| C.4 | LOW | None (CHECK only) | Yes (DROP CONSTRAINT) |
| C.5 | **MEDIUM** | All NULL-priority rows → 3 | **Conditional** (needs pre-snapshot) |
| C.6-C.7 | LOW | None (DEFAULT + constraint) | Yes |

---

**Confirm migration block order and risk posture before I draft DDL.**
