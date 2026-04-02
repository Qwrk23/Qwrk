# Manus Reference — Schema Cheatsheet

**Purpose:** Compact schema reference for validating plan references. Not a substitute for Live DDL.
**Date:** 2026-03-22
**Canonical source:** `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` (DDL v2.10)
**Human-readable reference:** `docs/schema/Schema_Reference__Kernel_v1__v2.10.md`

---

## Core Concept: Spine + Extension

Every artifact lives in `qxb_artifact` (the "spine"). Type-specific data lives in extension tables linked by `artifact_id` (PK=FK pattern).

```
qxb_artifact         ←── spine (shared fields for all artifact types)
  └── qxb_artifact_*  ←── extension (type-specific fields)
```

A save operation writes to both tables. A query joins them.

---

## Spine Table — `qxb_artifact`

Key columns a plan might reference:

| Column | Type | Notes |
|--------|------|-------|
| `artifact_id` | uuid | PK, auto-generated |
| `workspace_id` | uuid | FK, required — tenancy boundary |
| `owner_user_id` | uuid | FK, required — artifact owner |
| `artifact_type` | text | CHECK v8: 15 allowed values |
| `title` | text | Required |
| `summary` | text | Optional |
| `priority` | integer | 1–5, default 3. (1=Critical, 5=Plan) |
| `lifecycle_status` | text | project-only CHECK: seed/sapling/tree/archive |
| `execution_status` | text | All types. CHECK: not_started/in_progress/blocked/complete |
| `semantic_type_id` | uuid | FK to semantic type registry. Required for top-level types |
| `tags` | jsonb | Array of strings |
| `content` | jsonb | Flexible payload |
| `parent_artifact_id` | uuid | FK to self — hierarchy/lineage |
| `version` | integer | Starts at 1, increments on update |
| `deleted_at` | timestamptz | NULL = active, non-NULL = soft-deleted |
| `created_at` | timestamptz | Auto-set |
| `updated_at` | timestamptz | Auto-updated by trigger |

---

## Top-Level vs Non-Top-Level Artifacts

| Classification | Types | Distinguishing Rule |
|----------------|-------|---------------------|
| **Top-level** | project, journal, snapshot, restart, person | `semantic_type_id` is **required** (NOT NULL enforced conditionally) |
| **Non-top-level** | branch, limb, leaf, grass, thorn, instruction_pack, twig, forest, thicket, flower | `semantic_type_id` is optional (may be NULL) |

This distinction matters for save validation. Plans referencing top-level types must account for `semantic_type_id`.

---

## Extension Tables — What They Add

| Extension Table | Type | Key Fields |
|----------------|------|------------|
| `qxb_artifact_project` | project | `lifecycle_stage` (seed/sapling/tree/archive), `operational_status` (active/paused) |
| `qxb_artifact_journal` | journal | `entry_text`, `entry_type` |
| `qxb_artifact_snapshot` | snapshot | `payload` (jsonb, immutable) |
| `qxb_artifact_restart` | restart | `payload` (jsonb, immutable) |
| `qxb_artifact_person` | person | 27 columns: identity, contact, professional, interaction, JSONB arrays |
| `qxb_artifact_grass` | grass | `issue_description`, `severity`, `resolution_status` |
| `qxb_artifact_thorn` | thorn | `exception_type`, `exception_details`, `resolution_status` |
| `qxb_artifact_instruction_pack` | instruction_pack | `pack_content`, `pack_version` |
| `qxb_artifact_limb` | limb | Shell only — minimal extension |
| `qxb_artifact_video` | video | `transcript`, `insights`, `video_url` |

**No extension table:** branch, leaf, twig, forest, thicket, flower (spine-only)

---

## Lifecycle Fields

Two separate axes exist on the spine:

| Field | Scope | Values | Governance |
|-------|-------|--------|------------|
| `lifecycle_status` | Project-only | seed, sapling, tree, archive | CHECK constraint, transition-guarded |
| `execution_status` | All types | not_started, in_progress, blocked, complete | CHECK constraint |

The project extension table also has:
- `lifecycle_stage` — mirrors/extends lifecycle state at the extension level
- `operational_status` — active/paused (orthogonal to lifecycle)

**Review implication:** Plans that reference lifecycle transitions should specify the direction (e.g., seed→sapling) and note that transitions are guarded, not freeform.

---

## Parent/Child Hierarchy Rules

| Artifact | Must Parent To |
|----------|---------------|
| Branch | Project |
| Limb | Branch |
| Leaf | Branch OR Limb |

**Prohibited:**
- Branch → Branch (no infinite nesting)
- Limb → Limb (no infinite nesting)
- Leaf → anything (leaves are terminal)
- Project → Leaf directly (must go through Branch)
- Project → Limb directly (must go through Branch)

---

## Supporting Tables

| Table | Purpose |
|-------|---------|
| `qxb_user` | Maps Supabase auth to Qwrk identity |
| `qxb_workspace` | Tenancy boundary |
| `qxb_workspace_user` | Role-based membership (owner/admin/member) |
| `qxb_artifact_event` | Append-only audit log |
| `qxb_artifact_dependency` | Leaf-to-leaf dependency tracking |
| `qxb_semantic_type_registry` | Controlled vocabulary for semantic classification |
| `qxb_gateway_acl` | Gateway access control |
| `qxb_artifact_rollup_view` | Computed completion percentages (VIEW) |

---

## Common Validation Points for Plan Review

When a plan references schema elements, check:

- Does the table exist? (15 artifact types, not all have extension tables)
- Does the column exist on the correct table (spine vs extension)?
- Are NOT NULL constraints satisfied?
- Are CHECK constraints respected (artifact_type, lifecycle_status, execution_status, priority range)?
- Is `semantic_type_id` handled for top-level types?
- Does the parent/child hierarchy follow the rules?
- Are immutability rules respected (snapshot, restart, event log)?

---

## CHANGELOG

### v1 — 2026-03-22
Initial creation for Manus plan reviewer role.
