# PHASE 2B --- QPM Execution Semantics ("Walk")

**Status:** Draft\
**Posture:** Crawl → Walk → Run\
**Relationship to Phase 2:** Extends lifecycle semantics into usable
execution behavior without expanding into full automation or recurrence
systems.

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

These fields apply to execution-layer artifacts (branch, limb, leaf).

## 1.1 Status (Required for Execution Types)

Enum: - not_started - in_progress - blocked - complete

Status drives rollup behavior.

------------------------------------------------------------------------

## 1.2 Priority (Structured Field)

Numeric scale (1--5).

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
