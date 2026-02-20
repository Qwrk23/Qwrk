# PHASE 2C --- Artifact Schema Enrichment ("Structure")

**Status:** Draft\
**Posture:** Crawl → Walk → Structure → Run\
**Relationship to Phase 2 & 2B:** Extends lifecycle (Crawl) and
execution semantics (Walk) by enriching the underlying artifact data
model without introducing automation.

------------------------------------------------------------------------

# Purpose

Phase 2C formalizes cross-artifact schema capabilities required for
long-term system maturity.

Phase 2 established lifecycle governance.\
Phase 2B established execution behavior.

Phase 2C defines structural intelligence in the artifact layer.

This phase enables richer classification, relationship modeling, and
future extensibility without introducing automation or recurrence
engines.

------------------------------------------------------------------------

# Scope Boundaries

Phase 2C DOES include: - Universal classification fields - Structured
relationship modeling - Parent vs related distinction - Dependency table
formalization - Optional review_date field (non-automated) -
Clarification of artifact type roles (journal vs flower)

Phase 2C DOES NOT include: - Recurring interval engines - Escalation
logic - Calendar integration - Automated surfacing - Background jobs

------------------------------------------------------------------------

# 1. Universal Classification Fields

These fields apply to all artifact types unless explicitly excluded.

## 1.1 Category

Free-text or controlled vocabulary field.

Purpose: - High-level grouping across artifact types - Enables
consistent filtering beyond tags

Examples: - work - personal - governance - reading - infrastructure

------------------------------------------------------------------------

## 1.2 Subcategory

Optional refinement beneath category.

Purpose: - Enables structured organization without multiplying artifact
types - Reduces need for flowers as a separate type

Example: Category: personal\
Subcategory: recurring

------------------------------------------------------------------------

# 2. Relationship Model

Phase 2C formalizes distinction between hierarchy and association.

------------------------------------------------------------------------

## 2.1 Parent--Child (Hierarchical)

Field: - parent_artifact_id (single parent)

Purpose: - Defines execution anatomy (tree → branch → limb → leaf) -
Defines companion relationships (journal linked to project)

Cardinality: - One parent per artifact - Unlimited children

------------------------------------------------------------------------

## 2.2 Related-To (Associative)

New many-to-many relationship table.

Purpose: - Link artifacts across hierarchies - Allow cross-tree
references - Enable thematic linking without structural inheritance

Cardinality: - Many-to-many

No lifecycle inheritance implied.

------------------------------------------------------------------------

# 3. Dependency Table (Formalized)

Dependency is distinct from hierarchy.

Dependency table must: - Allow many-to-many leaf dependencies - Prevent
completion if blocking dependency incomplete - Avoid implicit DAG
enforcement (deferred)

No cross-tree enforcement required in 2C.

------------------------------------------------------------------------

# 4. Optional Review_Date Field (Non-Automated)

Add optional field: - review_date (timestamp)

Purpose: - Manual review surfacing - Deterministic query-based
resurfacing - Foundation for future recurrence engine

Phase 2C only introduces the field --- no automation.

------------------------------------------------------------------------

# 5. Artifact Role Clarification

Clarify usage boundaries:

Journal: - Narrative content - Thinking capture - Companion records

Project: - Lifecycle-tracked initiative - Promotable through seed →
sapling → tree

Flower (If retained): - Standalone execution artifact - No lifecycle
promotion - Optional; may be replaced by category/subcategory structure

Phase 2C does not introduce new artifact types.

------------------------------------------------------------------------

# 6. Explicitly Deferred to Phase 3

-   Recurring integrity engine
-   Automated resurfacing logic
-   Escalation modeling
-   Cross-tree dependency validation
-   Weighted scoring models

------------------------------------------------------------------------

# Definition of "Structure Complete"

Phase 2C is complete when:

1.  Category and subcategory fields exist and are queryable.
2.  parent_artifact_id is clearly defined and documented.
3.  related_to many-to-many model exists.
4.  Dependency table exists and enforces basic blocking.
5.  review_date field exists and is queryable.

No automation required.

------------------------------------------------------------------------

# Design Philosophy

Crawl: Lifecycle correctness\
Walk: Execution clarity\
Structure: Schema intelligence\
Run: Automation and orchestration

Phase 2C ensures the data model can support future intelligence without
requiring it today.

Build stable bones before adding muscle.
