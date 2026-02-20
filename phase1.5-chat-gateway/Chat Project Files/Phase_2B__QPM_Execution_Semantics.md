# PHASE 2B --- QPM Execution Semantics ("Walk")

**Status:** Draft\
**Posture:** Crawl → Walk → Run\
**Relationship to Phase 2:** Extends lifecycle semantics into usable
execution behavior without expanding into full automation or recurrence
systems.

------------------------------------------------------------------------

# Phase 2B Walk — Pending — Gaps Identified

**Validated:** 2026-02-20\
**Validator:** CC (Build Executor)

### Criteria Assessment

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | Status field exists and is enforceable | **PASS** | `execution_status` on spine — `IS NULL OR IN (not_started, in_progress, blocked, complete)`. DDL v2.3. |
| 2 | Leaves can be marked complete | **PASS** | `artifact.update` routes leaf type (Update v12). Spine `execution_status` updatable. |
| 3 | Parent rollup percentage is queryable | **FAIL** | No aggregation query, function, or API endpoint exists. Manual counting via list + filter is possible but not first-class queryable. |
| 4 | Basic dependency blocking works | **FAIL** | `qxb_artifact_dependency` table does not exist in DDL v2.3. No dependency tracking deployed. |
| 5 | Real project trackable end-to-end | **PARTIAL** | Save → branch → leaf → update execution_status → promote lifecycle works. Missing: rollup aggregation and dependency enforcement. |

### Precise Gaps

1. **Rollup query** — No mechanism to query "what % of leaves under branch X are complete?" Requires either: (a) a Gateway query extension, (b) a database function, or (c) a dedicated workflow node. This is the core Walk value proposition.
2. **Dependency table** — `qxb_artifact_dependency` not created. Table design exists in Phase 0 DDL Audit (Section 3.5). Blocked on Phase 5 authorization.

### What IS Working (Walk Partial Credit)

- Execution status field deployed and enforceable (spine-level)
- Priority field deployed (NOT NULL DEFAULT 3)
- Branch/limb/leaf Save, Query, List, Update all routed (Gateway v56)
- Lifecycle promotion chain works (seed → sapling → tree → archive)
- Execution anatomy hierarchy expressible via parent_artifact_id

Walk is structurally enabled but not functionally complete.

------------------------------------------------------------------------

# Structural Alignment Note (2026-02-20)

**Aligned with DDL v2.3 (deployed 2026-02-16).**

- `execution_status` is a **spine-level column** on `qxb_artifact`, not on extension tables.
  - CHECK: `IS NULL OR IN ('not_started', 'in_progress', 'blocked', 'complete')`
  - Available to ALL artifact types, not only execution-layer types.
- `priority` is a **spine-level column**: `integer NOT NULL DEFAULT 3, CHECK (1-5)`.
- Prior references in this document to execution fields existing on extension tables were **historical planning assumptions** made before Phase 2 structural migration.
- The deployed architecture places execution state on the spine for universal availability and simpler query patterns. Extension tables (branch, limb, leaf) inherit execution semantics via the spine.
- `lifecycle_status` on spine: conditional CHECK — `seed`, `sapling`, `tree`, `archive` (project-only). No `oak` or `retired`.

------------------------------------------------------------------------

# Purpose

Phase 2 (Crawl) established lifecycle governance: - Seed → Sapling →
Tree validation - Execution anatomy requirement (branch / limb / leaf) -
Promotion enforcement and irreversible retirement

Phase 2B (Walk) introduces execution semantics so trees can be
**managed**, not just grown.

This phase enables real project tracking.

------------------------------------------------------------------------

# Scope Boundaries

Phase 2B DOES include: - Structured execution status - Parent-child
aggregation logic - Basic progress rollup - Optional dependency tracking
(minimal viable version)

Phase 2B DOES NOT include: - Recurrence infrastructure - Automated
reminder engines - Escalation logic - Background scheduling - Calendar
integration

------------------------------------------------------------------------

# 1. Universal Execution Fields

These fields exist on the **`qxb_artifact` spine** and are available to all artifact types.
They are primarily used by execution-layer artifacts (branch, limb, leaf) but are not
restricted to them.

## 1.1 Status (Spine-Level: `execution_status`)

Values: `not_started` | `in_progress` | `blocked` | `complete`

Nullable — `NULL` means no execution tracking applies.
CHECK constraint: `IS NULL OR IN ('not_started', 'in_progress', 'blocked', 'complete')`.

Status drives rollup behavior.

------------------------------------------------------------------------

## 1.2 Priority (Spine-Level: `priority`)

`integer NOT NULL DEFAULT 3, CHECK (1-5)` — 1 = highest, 5 = lowest.

Used for ordering and future surfacing logic.\
Replaces tag-based priority handling.

------------------------------------------------------------------------

# 2. Parent--Child Aggregation Logic

Phase 2B formalizes hierarchical rollup.

Hierarchy:

Tree\
└── Branch\
└── Limb (optional layer)\
└── Leaf (terminal execution)

Leaves are atomic completion units.

------------------------------------------------------------------------

## 2.1 Completion Rules

-   Leaf marked complete → counts as 100% complete.
-   Limb progress = % of completed leaves beneath it.
-   Branch progress = aggregated % of limbs or leaves.
-   Tree progress = aggregated % of all descendant leaves.

Initial implementation: - Equal weighting across leaves. - No weighted
scoring yet.

------------------------------------------------------------------------

# 3. Minimal Dependency Model (Optional in 2B)

Allow leaf-to-leaf dependency mapping.

Example: Leaf 3 depends on Leaf 2.

Requirements: - Many-to-many dependency table. - Prevent marking leaf
complete if dependency not complete. - No advanced DAG validation
required yet.

No cross-branch dependency enforcement required for Phase 2B.

------------------------------------------------------------------------

# 4. Promotion Semantics (Unchanged)

Phase 2 lifecycle rules remain authoritative.

Tree promotion still requires: - At least one execution child (branch,
limb, or leaf).

Phase 2B does not modify lifecycle rules.

## Advisory Note (2026-02-20)

The execution child requirement above is a **governance-layer advisory**. It is
NOT enforced at the Gateway runtime level. Promote v2_HTTP does not validate
child artifact existence before allowing `seed_to_sapling` or `sapling_to_tree`
transitions.

**Recommended preflight check** (manual, before promoting):
- Query the project's children: list artifacts with `parent_artifact_id` matching the project
- Verify at least one branch/limb/leaf exists before promoting seed → sapling
- Verify execution anatomy is populated before promoting sapling → tree

Runtime enforcement of C4 content validation gates is deferred beyond Phase 2B scope.

------------------------------------------------------------------------

# 5. Query & Progress Requirements

Phase 2B must enable:

-   Query tree progress percentage.
-   Query leaves by status.
-   Query blocked leaves.
-   Query leaves by priority.

No dashboard required yet --- query-driven visibility is sufficient.

------------------------------------------------------------------------

# 6. Explicitly Deferred to Phase 3 (Run)

-   Recurring integrity system
-   Review surfacing automation
-   Escalation logic
-   Weighted execution models
-   Cross-tree dependency enforcement
-   Calendar integration

------------------------------------------------------------------------

# Definition of "Walk Complete"

Phase 2B is complete when:

1.  Status field exists and is enforceable.
2.  Leaves can be marked complete.
3.  Parent rollup percentage is queryable.
4.  Basic dependency blocking works.
5.  QPM can be used to track a real project end-to-end.

------------------------------------------------------------------------

# Design Philosophy

Crawl: Can grow a tree.\
Walk: Can manage a tree.\
Run: Can automate a forest.

Phase 2B is about usable execution clarity --- not sophistication.

Ship clarity before power.
