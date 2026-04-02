# Schema Reference — Kernel v1 (v2.10)

**Source**: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` (DDL v2.10)
**Date**: 2026-03-22
**Version**: v2.10
**Status**: Authoritative DDL-as-Truth Reference
**Purpose**: Human-readable schema documentation derived from LIVE database DDL

**Supersedes**: v2.9 (`Archive/Schema_Reference__Kernel_v1__v2.9__2026-03-22.md`)

**Drift Prevention Rule**: Any DDL version change requires a corresponding update to this Schema Reference in the same commit. See CLAUDE.md § Schema Truth Policy.

---

## Overview

Qwrk Kernel v1 uses **class-table inheritance pattern**:
- `qxb_artifact` = canonical "spine" table (all artifacts start here)
- Type-specific extension tables (PK=FK relationship)
- `qxb_artifact_event` = append-only audit log
- `qxb_semantic_type_registry` = controlled vocabulary for semantic classification (T69)
- `qxb_artifact_rollup_view` = computed completion percentages (T70)

**20 tables + 1 VIEW total.** All tables have **RLS enabled** (deny-by-default with explicit policies).

**5 functions** support RLS, trigger logic, dependency enforcement, and semantic type updates.

---

## Table of Contents

### Core Tables
1. [qxb_user](#qxb_user) — Identity Mapping
2. [qxb_workspace](#qxb_workspace) — Tenancy
3. [qxb_workspace_user](#qxb_workspace_user) — Membership

### Artifact Spine
4. [qxb_artifact](#qxb_artifact) — Spine Table

### Extension Tables
5. [qxb_artifact_project](#qxb_artifact_project) — Lifecycle + Operational State
6. [qxb_artifact_journal](#qxb_artifact_journal) — Owner-Private Entries
7. [qxb_artifact_snapshot](#qxb_artifact_snapshot) — Immutable Snapshots
8. [qxb_artifact_restart](#qxb_artifact_restart) — Immutable Restart Context
9. [qxb_artifact_video](#qxb_artifact_video) — Long-Form Media
10. [qxb_artifact_grass](#qxb_artifact_grass) — Operational Issue Tracking
11. [qxb_artifact_thorn](#qxb_artifact_thorn) — Exception Tracking
12. [qxb_artifact_instruction_pack](#qxb_artifact_instruction_pack) — Instruction Pack Storage
13. [qxb_artifact_limb](#qxb_artifact_limb) — Execution Anatomy (Shell)
14. [qxb_artifact_person](#qxb_artifact_person) — Identity, Contact & Relationship (T150)

### Audit & Event Log
15. [qxb_artifact_event](#qxb_artifact_event) — Append-Only Audit Log

### Dependency Table
16. [qxb_artifact_dependency](#qxb_artifact_dependency) — Leaf-to-Leaf Dependency Tracking

### Semantic Type System (T69)
17. [qxb_semantic_type_registry](#qxb_semantic_type_registry) — Semantic Classification Vocabulary
18. [qxb_semantic_type_audit](#qxb_semantic_type_audit) — Semantic Type Change Audit Log

### System Tables
19. [qxb_artifact_type_registry](#qxb_artifact_type_registry) — Type Registry
20. [qxb_artifact_type_registry_audit](#qxb_artifact_type_registry_audit) — Type Registry Audit Log
21. [qxb_gateway_acl](#qxb_gateway_acl) — Gateway Access Control

### Views
- [qxb_artifact_rollup_view](#qxb_artifact_rollup_view) — Completion Rollup (T70/T69)

### Reference
- [Helper Functions](#helper-functions)
- [Indexes](#indexes)
- [Artifact Type Summary](#artifact-type-summary)

---

## qxb_user

**Purpose**: Maps Supabase Auth users to Qwrk user identity. Required for RLS policies.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `user_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key (Qwrk user ID) |
| `auth_user_id` | uuid | NOT NULL | — | FK to auth.users (Supabase Auth) |
| `status` | text | NOT NULL | `'active'` | User status |
| `display_name` | text | NULL | — | User display name |
| `email` | text | NULL | — | User email address |
| `created_at` | timestamptz | NOT NULL | `now()` | User registration timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Profile update timestamp (auto-updated by trigger) |

### Constraints

**Primary Key**: `user_id`

**Unique Constraints**:
- `auth_user_id` (one-to-one mapping to Supabase Auth)

**Check Constraints**:
- `status` IN (`'active'`, `'disabled'`)

### Triggers

- `qxb_user_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_user_select_self` | SELECT | `auth_user_id = (select auth.uid())` |
| `qxb_user_update_self` | UPDATE | `auth_user_id = (select auth.uid())` |

---

## qxb_workspace

**Purpose**: Workspace (tenancy boundary). All artifacts belong to a workspace. Ownership is expressed via `qxb_workspace_user` with role `'owner'`.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `workspace_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key |
| `name` | text | NOT NULL | — | Workspace name |
| `created_at` | timestamptz | NOT NULL | `now()` | Workspace creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Workspace update timestamp (auto-updated by trigger) |

### Constraints

**Primary Key**: `workspace_id`

### Triggers

- `qxb_workspace_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_workspace_select_via_auth_membership` | SELECT | User has membership via `qxb_workspace_user` JOIN `qxb_user` WHERE `auth_user_id = (select auth.uid())` |

---

## qxb_workspace_user

**Purpose**: Workspace membership and role-based access. Maps users to workspaces with roles.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `workspace_user_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key |
| `workspace_id` | uuid | NOT NULL | — | FK to qxb_workspace |
| `user_id` | uuid | NOT NULL | — | FK to qxb_user |
| `role` | text | NOT NULL | `'member'` | Role assignment |
| `created_at` | timestamptz | NOT NULL | `now()` | Membership creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Membership update timestamp (auto-updated by trigger) |

### Constraints

**Primary Key**: `workspace_user_id`

**Unique Constraints**:
- `(workspace_id, user_id)` — one membership per user per workspace

**Foreign Keys**:
- `workspace_id` → `qxb_workspace.workspace_id`
- `user_id` → `qxb_user.user_id`

**Check Constraints**:
- `role` IN (`'owner'`, `'admin'`, `'member'`)

### Triggers

- `qxb_workspace_user_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_workspace_user_select_via_auth` | SELECT | User's own memberships via `qxb_user` WHERE `auth_user_id = (select auth.uid())` |

---

## qxb_artifact

**Purpose**: Canonical spine table for all artifact types. All records begin here and extend via PK=FK relationship to type-specific tables.

**Class-Table Inheritance Root**: Yes

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key (auto-generated) |
| `workspace_id` | uuid | NOT NULL | — | FK to qxb_workspace (tenancy boundary) |
| `owner_user_id` | uuid | NOT NULL | — | FK to qxb_user (canonical ownership) |
| `artifact_type` | text | NOT NULL | — | Type discriminator (CHECK v8: 15 types) |
| `title` | text | NOT NULL | — | Human-readable title |
| `summary` | text | NULL | — | Short description for list views |
| `priority` | integer | **NOT NULL** | **`3`** | Priority scale 1-5 (1=highest, 5=lowest) |
| `lifecycle_status` | text | NULL | — | Lifecycle stage (conditional CHECK: project-only) |
| `execution_status` | text | NULL | — | Execution tracking (spine-level, all types) |
| `semantic_type_id` | uuid | conditional | — | FK to `qxb_semantic_type_registry`. Conditional NOT NULL: REQUIRED for top-level types (project, snapshot, journal, restart, person); NULL for all others. |
| `tags` | jsonb | NULL | — | Tag set for filtering/organization |
| `content` | jsonb | NULL | — | Flexible payload (minimal; type tables hold structured data) |
| `parent_artifact_id` | uuid | NULL | — | FK to qxb_artifact (lineage/hierarchy) |
| `version` | integer | NOT NULL | `1` | Version counter (increments on UPDATE) |
| `deleted_at` | timestamptz | NULL | — | Soft delete timestamp (NULL = active) |
| `created_at` | timestamptz | NOT NULL | `now()` | DB-managed creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | DB-managed update timestamp (auto-updated by trigger) |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `workspace_id` → `qxb_workspace.workspace_id`
- `owner_user_id` → `qxb_user.user_id`
- `parent_artifact_id` → `qxb_artifact.artifact_id`
- `semantic_type_id` → `qxb_semantic_type_registry.semantic_type_id` (ON DELETE RESTRICT)

**Check Constraints**:
- **artifact_type (CHECK v8)**: IN (`'project'`, `'journal'`, `'restart'`, `'snapshot'`, `'grass'`, `'thorn'`, `'forest'`, `'thicket'`, `'flower'`, `'branch'`, `'leaf'`, `'instruction_pack'`, `'limb'`, `'twig'`, `'person'`) — 15 types. Note: `'video'` is NOT in CHECK despite `qxb_artifact_video` table existing.
- **priority**: `>= 1 AND <= 5`
- **lifecycle_status (conditional, project)**: `artifact_type <> 'project' OR lifecycle_status IN ('seed', 'sapling', 'tree', 'archive')` — only enforced for project type.
- **lifecycle_status (conditional, twig)**: `artifact_type <> 'twig' OR lifecycle_status IN ('proposed', 'active', 'promoted', 'pruned')` — only enforced for twig type. (T94)
- **execution_status**: `IS NULL OR IN ('not_started', 'in_progress', 'blocked', 'complete')` — spine-level field available to all artifact types.
- **semantic_type_required_for_top_level (conditional)**: `artifact_type NOT IN ('project', 'snapshot', 'journal', 'restart', 'person') OR semantic_type_id IS NOT NULL` — top-level types MUST have a semantic_type_id; non-top-level types may be NULL.

### Indexes

| Index | Type | Columns | WHERE |
|-------|------|---------|-------|
| `uq_qxb_artifact_forest_title_active` | UNIQUE (partial) | `workspace_id`, `lower(title)` | `artifact_type = 'forest' AND deleted_at IS NULL` |
| `uq_qxb_artifact_thicket_title_per_forest_active` | UNIQUE (partial) | `workspace_id`, `parent_artifact_id`, `lower(title)` | `artifact_type = 'thicket' AND deleted_at IS NULL` |
| `idx_qxb_artifact_semantic_type` | btree (partial) | `semantic_type_id` | `semantic_type_id IS NOT NULL` |

### Triggers

- `qxb_artifact_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_select_member` | SELECT | Workspace member via `qxb_workspace_user`; journals restricted to `owner_user_id` only |
| `qxb_artifact_insert_owner` | INSERT | Owner (`owner_user_id = qxb_current_user_id()`) AND workspace member |
| `qxb_artifact_update_owner_or_admin` | UPDATE | Owner OR workspace admin/owner role |

---

## qxb_artifact_project

**Purpose**: Extension table for project artifacts. Tracks lifecycle stages and operational state.

**Extends**: `qxb_artifact` (PK=FK pattern)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `lifecycle_stage` | text | NOT NULL | — | Project lifecycle stage |
| `operational_state` | text | NOT NULL | `'active'` | Operational state |
| `state_reason` | text | NULL | — | Freeform reason for current state |
| `design_spine` | jsonb | NULL | — | Architecture definition (freeform JSONB, no schema validation) |
| `created_at` | timestamptz | NOT NULL | `now()` | Extension record creation |
| `updated_at` | timestamptz | NOT NULL | `now()` | Extension record update (auto-updated by trigger) |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

**Check Constraints**:
- `lifecycle_stage` IN (`'seed'`, `'sapling'`, `'tree'`, `'archive'`)
- `operational_state` IN (`'active'`, `'paused'`, `'blocked'`, `'waiting'`)

### Triggers

- `qxb_artifact_project_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_project_select_via_artifact` | SELECT | Spine artifact exists (delegates to spine RLS) |
| `qxb_artifact_project_update_owner_or_admin` | UPDATE | Owner or admin via spine delegation |

---

## qxb_artifact_journal

**Purpose**: Extension table for journal artifacts. Stores owner-private reflective text and flexible payload.

**Extends**: `qxb_artifact` (PK=FK pattern)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `entry_text` | text | NULL | — | Main journal entry text (owner-private) |
| `payload` | jsonb | NULL | — | Flexible metadata |
| `created_at` | timestamptz | NOT NULL | `now()` | Entry creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Entry update timestamp (auto-updated by trigger) |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

### Triggers

- `qxb_artifact_journal_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_journal_insert_owner_via_artifact` | INSERT | Owner only via spine |
| `qxb_artifact_journal_select_owner_via_artifact` | SELECT | Owner only via spine |
| `qxb_artifact_journal_update_owner_via_artifact` | UPDATE | Owner only via spine |

---

## qxb_artifact_snapshot

**Purpose**: Extension table for snapshot artifacts. Immutable lifecycle snapshots with JSONB payload.

**Extends**: `qxb_artifact` (PK=FK pattern)
**Mutability**: CREATE-ONLY (no UPDATE/DELETE policies on extension table)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `payload` | jsonb | NOT NULL | — | Immutable snapshot data |
| `created_at` | timestamptz | NOT NULL | `now()` | Snapshot creation timestamp |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_snapshot_insert_owner_via_artifact` | INSERT | Owner only via spine |
| `qxb_artifact_snapshot_select_via_artifact` | SELECT | Spine artifact exists |

---

## qxb_artifact_restart

**Purpose**: Extension table for restart artifacts. Manual session continuation with immutable payload.

**Extends**: `qxb_artifact` (PK=FK pattern)
**Mutability**: CREATE-ONLY (no UPDATE/DELETE policies on extension table)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `payload` | jsonb | NOT NULL | — | Immutable restart context |
| `created_at` | timestamptz | NOT NULL | `now()` | Restart creation timestamp |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_restart_insert_owner_via_artifact` | INSERT | Owner only via spine |
| `qxb_artifact_restart_select_via_artifact` | SELECT | Spine artifact exists |

---

## qxb_artifact_video

**Purpose**: Extension table for video artifacts. Long-form media with transcripts and derived insights.

**Extends**: `qxb_artifact` (PK=FK pattern)

> **Note**: `'video'` is NOT in the `artifact_type` CHECK constraint (v6) despite this table existing. The table is live but the type is not Gateway-registerable via CHECK.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `source_url` | text | NOT NULL | — | Source video URL |
| `source_platform` | text | NOT NULL | `'youtube'` | Platform identifier |
| `source_video_id` | text | NULL | — | Platform-specific video ID |
| `source_channel` | text | NULL | — | Source channel name or ID |
| `source_published_at` | timestamptz | NULL | — | Original publish timestamp |
| `duration_seconds` | integer | NULL | — | Video duration in seconds |
| `status` | text | NOT NULL | `'queued'` | Processing status |
| `idempotency_key` | text | NOT NULL | — | Unique deduplication key |
| `content` | jsonb | NOT NULL | `'{}'` | Transcript and derived insights |
| `error` | jsonb | NULL | — | Error details if processing failed |
| `created_at` | timestamptz | NOT NULL | `now()` | Video artifact creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Video artifact update timestamp (auto-updated) |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

**Unique Constraints**:
- `idempotency_key` — prevents duplicate video ingests

**Check Constraints**:
- `status` IN (`'queued'`, `'downloading'`, `'chunking'`, `'transcribing'`, `'stitching'`, `'saving'`, `'complete'`, `'failed'`)

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_video_select_via_artifact` | SELECT | Spine artifact exists |
| `qxb_artifact_video_insert_owner_via_artifact` | INSERT | Owner only via spine |
| `qxb_artifact_video_update_owner_or_admin` | UPDATE | Owner or admin via spine |

---

## qxb_artifact_grass

**Purpose**: Extension table for grass artifacts (operational tracking). Tracks transient operational issues detected by workflows.

**Extends**: `qxb_artifact` (PK=FK pattern)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `source_system` | text | NOT NULL | `'n8n'` | Source system identifier |
| `source_workflow` | text | NULL | — | Workflow name/ID that detected issue |
| `source_execution_id` | text | NULL | — | Execution ID for traceability |
| `detected_at` | timestamptz | NOT NULL | `now()` | Detection timestamp |
| `review_status` | text | NOT NULL | `'unreviewed'` | Review state |
| `summary` | text | NOT NULL | — | Brief issue description |
| `details_json` | jsonb | NOT NULL | `'{}'` | Detailed issue data |
| `disposition` | text | NOT NULL | `'none'` | Disposition outcome |
| `reviewed_at` | timestamptz | NULL | — | Review completion timestamp |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

**Check Constraints**:
- `review_status` IN (`'unreviewed'`, `'reviewed'`, `'dismissed'`)
- `disposition` IN (`'none'`, `'promoted_to_flower'`, `'dismissed'`)

### Indexes

| Index | Type | Columns |
|-------|------|---------|
| `qxb_artifact_grass_review_detected_idx` | btree | `review_status`, `detected_at DESC` |

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_grass_insert_via_artifact` | INSERT | Spine artifact exists |
| `qxb_artifact_grass_select_via_artifact` | SELECT | Spine artifact exists |
| `qxb_artifact_grass_update_via_artifact` | UPDATE | Spine artifact exists |

---

## qxb_artifact_thorn

**Purpose**: Extension table for thorn artifacts (exception tracking). Tracks significant issues requiring attention.

**Extends**: `qxb_artifact` (PK=FK pattern)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `source_system` | text | NOT NULL | `'n8n'` | Source system identifier |
| `source_workflow` | text | NULL | — | Workflow name/ID |
| `source_execution_id` | text | NULL | — | Execution ID |
| `detected_at` | timestamptz | NOT NULL | `now()` | Detection timestamp |
| `severity` | integer | NOT NULL | `3` | Severity level 1-5 (1=highest) |
| `status` | text | NOT NULL | `'open'` | Thorn status |
| `summary` | text | NOT NULL | — | Brief exception description |
| `details_json` | jsonb | NOT NULL | `'{}'` | Detailed exception data |
| `resolution_notes` | text | NULL | — | Freeform resolution notes |
| `resolved_at` | timestamptz | NULL | — | Resolution timestamp |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

**Check Constraints**:
- `severity` BETWEEN 1 AND 5
- `status` IN (`'open'`, `'acknowledged'`, `'resolved'`, `'ignored'`)

### Indexes

| Index | Type | Columns |
|-------|------|---------|
| `qxb_artifact_thorn_severity_detected_idx` | btree | `severity`, `detected_at DESC` |
| `qxb_artifact_thorn_status_detected_idx` | btree | `status`, `detected_at DESC` |

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_thorn_insert_via_artifact` | INSERT | Spine artifact exists |
| `qxb_artifact_thorn_select_via_artifact` | SELECT | Spine artifact exists |
| `qxb_artifact_thorn_update_via_artifact` | UPDATE | Spine artifact exists |

---

## qxb_artifact_instruction_pack

**Purpose**: Extension table for instruction pack artifacts. Stores system instruction metadata for Q execution surface.

**Extends**: `qxb_artifact` (PK=FK pattern)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `workspace_id` | uuid | NULL | — | Optional workspace scope (redundant with spine) |
| `scope` | text | NOT NULL | — | Pack scope identifier |
| `active` | boolean | NOT NULL | `true` | Whether pack is active |
| `priority` | integer | NOT NULL | `0` | Pack priority (ordering) |
| `pack_format` | text | NOT NULL | `'json'` | Pack format identifier |
| `created_by_source` | text | NULL | — | Source that created the pack |
| `approved_at` | timestamptz | NULL | — | Approval timestamp |
| `checksum_sha256` | text | NULL | — | Content integrity checksum |
| `created_at` | timestamptz | NOT NULL | `now()` | Pack creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Pack update timestamp |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_instruction_pack_select_via_artifact` | SELECT | Spine artifact exists |
| `qxb_artifact_instruction_pack_insert_owner_via_artifact` | INSERT | Owner only via spine |
| `qxb_artifact_instruction_pack_update_owner_or_admin` | UPDATE | Owner or admin via spine |

---

## qxb_artifact_limb

**Purpose**: Shell extension table for limb artifact type (execution anatomy). Execution state (`execution_status`, `priority`) is tracked on the **spine**, not on this table.

**Extends**: `qxb_artifact` (PK=FK pattern)
**Phase**: Phase 2 Completion (2026-02-16)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `created_at` | timestamptz | NOT NULL | `now()` | Extension record creation |
| `updated_at` | timestamptz | NOT NULL | `now()` | Extension record update (auto-updated by trigger) |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

### Triggers

- `qxb_artifact_limb_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_limb_select_via_artifact` | SELECT | Spine artifact exists |
| `qxb_artifact_limb_insert_owner_via_artifact` | INSERT | Owner only via spine |
| `qxb_artifact_limb_update_owner_or_admin` | UPDATE | Owner or admin via spine |

---

## qxb_artifact_person

**Purpose**: Person extension table. Stores identity, contact, professional context, interaction tracking, and communication intelligence for real individuals in the operator's network.

**Extends**: `qxb_artifact` (PK=FK pattern)
**Phase**: T150 (2026-03-22)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `full_name` | text | NOT NULL | — | Person's full legal/formal name |
| `preferred_name` | text | NOT NULL | — | Name the person goes by |
| `relationship_type` | text | NOT NULL | — | Relationship category (family, friend, coworker, client, mentor, partner, other) |
| `status` | text | NOT NULL | `'active'` | Person status (active, inactive, archived) |
| `pronouns` | text | NULL | — | Preferred pronouns |
| `personal_email` | text | NULL | — | Personal email address |
| `work_email` | text | NULL | — | Work email address |
| `mobile_phone` | text | NULL | — | Mobile phone number |
| `work_phone` | text | NULL | — | Work phone number |
| `home_phone` | text | NULL | — | Home phone number |
| `preferred_contact_method` | text | NULL | — | Preferred method (email, phone, text, etc.) |
| `preferred_contact_channel` | text | NULL | — | Preferred channel (personal_email, work_email, mobile, etc.) |
| `timezone` | text | NULL | — | Person's timezone |
| `company` | text | NULL | — | Company/organization |
| `title` | text | NULL | — | Job title or role |
| `department` | text | NULL | — | Department within organization |
| `importance_level` | text | NULL | — | Importance level (critical, high, medium, low) |
| `interaction_frequency` | text | NULL | — | How often to interact (daily, weekly, monthly, quarterly, rarely) |
| `last_contacted_at` | timestamptz | NULL | — | When last contacted |
| `next_follow_up_at` | timestamptz | NULL | — | When next follow-up is due |
| `do_not_contact` | boolean | NOT NULL | `false` | Do-not-contact flag |
| `address` | jsonb | NULL | — | Mailing address object: `{mailing_address_line1, mailing_address_line2, city, state_region, postal_code, country}` |
| `communication_style` | jsonb | NULL | — | Communication preferences: `{tone, detail_level, decision_style}` |
| `what_they_care_about` | jsonb | NULL | — | Array of priorities/interests: `["string", ...]` |
| `key_facts` | jsonb | NULL | — | Array of durable facts: `["string", ...]` |
| `preferences` | jsonb | NULL | — | Array of communication preferences: `["string", ...]` |
| `created_at` | timestamptz | NOT NULL | `now()` | Extension record creation |
| `updated_at` | timestamptz | NOT NULL | `now()` | Extension record update (auto-updated by trigger) |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)

**CHECK Constraints**:
- `qxb_artifact_person_key_facts_is_array`: `key_facts IS NULL OR jsonb_typeof(key_facts) = 'array'`
- `qxb_artifact_person_what_they_care_about_is_array`: `what_they_care_about IS NULL OR jsonb_typeof(what_they_care_about) = 'array'`
- `qxb_artifact_person_preferences_is_array`: `preferences IS NULL OR jsonb_typeof(preferences) = 'array'`

### Indexes

| Index | Type | Columns | Condition |
|-------|------|---------|-----------|
| `idx_qxb_artifact_person_full_name` | B-tree | `full_name` | — |
| `idx_qxb_artifact_person_relationship_type` | B-tree | `relationship_type` | — |
| `idx_qxb_artifact_person_last_contacted_at` | B-tree | `last_contacted_at` | `WHERE last_contacted_at IS NOT NULL` |
| `idx_qxb_artifact_person_key_facts` | GIN | `key_facts` | `WHERE key_facts IS NOT NULL` |
| `idx_qxb_artifact_person_what_they_care_about` | GIN | `what_they_care_about` | `WHERE what_they_care_about IS NOT NULL` |
| `idx_qxb_artifact_person_preferences` | GIN | `preferences` | `WHERE preferences IS NOT NULL` |

### Triggers

- `qxb_artifact_person_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_person_select_via_artifact` | SELECT | Workspace member via `qxb_workspace_user` join (hardened — not spine-only) |
| `qxb_artifact_person_insert_owner_via_artifact` | INSERT | Owner only via spine |
| `qxb_artifact_person_update_owner_or_admin` | UPDATE | Owner or admin via spine |

### Controlled Vocabulary Conventions (Application-Layer)

These fields use free text with documented conventions — **not** enforced by database CHECK constraints:

| Field | Documented Values |
|-------|------------------|
| `relationship_type` | family, friend, coworker, client, mentor, partner, other |
| `status` | active, inactive, archived |
| `importance_level` | critical, high, medium, low |
| `interaction_frequency` | daily, weekly, monthly, quarterly, rarely |

---

## qxb_artifact_event

**Purpose**: Append-only audit log for all artifact operations. Immutable event history.

**Mutability**: CREATE-ONLY (triggers block UPDATE and DELETE)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `event_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key (auto-generated) |
| `workspace_id` | uuid | NOT NULL | — | FK to qxb_workspace (required for RLS) |
| `artifact_id` | uuid | NOT NULL | — | FK to qxb_artifact (event subject) |
| `actor_user_id` | uuid | NULL | — | FK to qxb_user (who performed action) |
| `event_type` | text | NOT NULL | — | Event type identifier |
| `event_ts` | timestamptz | NOT NULL | `now()` | Event timestamp |
| `payload` | jsonb | NULL | — | Event-specific data |
| `created_at` | timestamptz | NOT NULL | `now()` | Record creation (immutable) |

### Constraints

**Primary Key**: `event_id`

**Foreign Keys**:
- `workspace_id` → `qxb_workspace.workspace_id`
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)
- `actor_user_id` → `qxb_user.user_id`

### Triggers

- `qxb_artifact_event_block_delete` (BEFORE DELETE): Raises exception — blocks all deletes
- `qxb_artifact_event_block_update` (BEFORE UPDATE): Raises exception — blocks all updates

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_event_select_member` | SELECT | Workspace member via `qxb_workspace_user` |

---

## qxb_artifact_dependency

**Purpose**: Many-to-many dependency table for leaf-to-leaf execution dependencies. Records that one artifact (source) depends on another (target). Used by T71 dependency enforcement in the Update sub-workflow.

**Mutability**: CREATE/DELETE only (no UPDATE policy)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `dependency_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key (auto-generated) |
| `artifact_id` | uuid | NOT NULL | — | FK to qxb_artifact (source — the dependent artifact) |
| `depends_on_artifact_id` | uuid | NOT NULL | — | FK to qxb_artifact (target — the dependency) |
| `workspace_id` | uuid | NOT NULL | — | FK to qxb_workspace |
| `created_at` | timestamptz | NOT NULL | `now()` | Record creation |

### Constraints

**Primary Key**: `dependency_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)
- `depends_on_artifact_id` → `qxb_artifact.artifact_id` (ON DELETE CASCADE)
- `workspace_id` → `qxb_workspace.workspace_id`

**Check Constraints**:
- `qxb_artifact_dependency_no_self_ref`: `artifact_id != depends_on_artifact_id` — prevents self-referential dependencies

### Indexes

| Index | Columns | Purpose |
|-------|---------|---------|
| `idx_qxb_artifact_dependency_source` | `artifact_id` | Forward lookup: "what does this artifact depend on?" |
| `idx_qxb_artifact_dependency_target` | `depends_on_artifact_id` | Reverse lookup: "what depends on this artifact?" |

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_artifact_dependency_select_member` | SELECT | Workspace member via `qxb_workspace_user` |
| `qxb_artifact_dependency_insert_member` | INSERT | Workspace member via `qxb_workspace_user` |
| `qxb_artifact_dependency_delete_owner_or_admin` | DELETE | Owner or admin via `qxb_workspace_user` |

**No UPDATE policy** — dependencies are immutable. Create or delete only.

### Design Notes

- Phase 2B DDL Reconciliation Audit used column names `source_artifact_id` / `target_artifact_id`. Verify live table column names match before deployment.
- No DAG validation, no cycle detection, no cross-branch enforcement.
- Enforcement via `check_leaf_dependencies()` RPC function called by Update sub-workflow.

---

## qxb_semantic_type_registry

**Purpose**: Controlled vocabulary for artifact semantic classification. Sole source of truth for `semantic_type_id` values referenced by `qxb_artifact`. Keys are UNIQUE and immutable after creation. Deactivate via `active=false`, never delete.

**Phase**: T69 (2026-03-03)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `semantic_type_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key |
| `key` | text | NOT NULL | — | Human-readable key (UNIQUE, immutable after creation) |
| `description` | text | NOT NULL | — | Description of the semantic category |
| `active` | boolean | NOT NULL | `true` | Whether this value is active for new classifications |
| `parent_id` | uuid | NULL | — | Self-referential FK for future hierarchy (unused) |
| `governance_snapshot_id` | uuid | NULL | — | FK to `qxb_artifact` (required for post-bootstrap additions) |
| `created_at` | timestamptz | NOT NULL | `now()` | Entry creation timestamp |
| `created_by` | text | NOT NULL | `'service_role'` | Actor that created the entry |

### Constraints

**Primary Key**: `semantic_type_id`

**Unique Constraints**:
- `key` — immutable after creation, no rename

**Foreign Keys**:
- `parent_id` → `qxb_semantic_type_registry.semantic_type_id` (self-referential, hierarchy)
- `governance_snapshot_id` → `qxb_artifact.artifact_id`

### Bootstrap Values (9)

| Key | Description |
|-----|-------------|
| `execution-core` | Core execution and lifecycle operations |
| `governance` | Governance rules, policies, and enforcement |
| `infrastructure` | System infrastructure and platform plumbing |
| `platform` | Platform capabilities and features |
| `product` | Product-facing functionality and user features |
| `alignment` | Strategic alignment and direction-setting |
| `sales` | Sales operations and pipeline |
| `marketing` | Marketing operations and content |
| `exploratory` | Undeclared meaning — default for unclassified artifacts |

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_semantic_type_registry_select_authenticated` | SELECT | `true` (vocabulary is public for authenticated users) |

No INSERT/UPDATE/DELETE policies — writes via `service_role` only.

---

## qxb_semantic_type_audit

**Purpose**: Append-only audit log for `semantic_type_id` changes on `qxb_artifact`. All writes go through `update_semantic_type()` RPC (SECURITY DEFINER bypasses RLS).

**Phase**: T69 (2026-03-03)
**Mutability**: CREATE-ONLY (triggers block UPDATE and DELETE)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key |
| `artifact_id` | uuid | NOT NULL | — | FK to `qxb_artifact` (subject of change) |
| `old_semantic_type_id` | uuid | NULL | — | Previous semantic type (NULL on first assignment) |
| `new_semantic_type_id` | uuid | NOT NULL | — | New semantic type |
| `reason` | text | NOT NULL | — | Reason for reclassification |
| `actor_id` | uuid | NOT NULL | — | Who performed the change |
| `created_at` | timestamptz | NOT NULL | `now()` | Change timestamp |

### Constraints

**Primary Key**: `id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id`
- `old_semantic_type_id` → `qxb_semantic_type_registry.semantic_type_id` (ON DELETE RESTRICT)
- `new_semantic_type_id` → `qxb_semantic_type_registry.semantic_type_id` (ON DELETE RESTRICT)

### Indexes

| Index | Columns | Purpose |
|-------|---------|---------|
| `idx_qxb_semantic_type_audit_artifact` | `artifact_id`, `created_at DESC` | Artifact-scoped audit queries |

### Triggers

- `qxb_semantic_type_audit_block_update` (BEFORE UPDATE): Raises exception — blocks all updates
- `qxb_semantic_type_audit_block_delete` (BEFORE DELETE): Raises exception — blocks all deletes

### RLS Policies

| Policy | Operation | Rule |
|--------|-----------|------|
| `qxb_semantic_type_audit_select_authenticated` | SELECT | `true` (audit trail is readable for authenticated users) |

No INSERT/UPDATE/DELETE policies for authenticated. Writes exclusively via `update_semantic_type()` RPC.

---

## qxb_artifact_rollup_view

**Purpose**: Computed VIEW for completion percentage of rollup-eligible artifact types (`project`, `branch`, `limb`). Uses `security_invoker = true` — runs with caller RLS permissions, not view creator.

**Phase**: T70 (2026-03-01), updated T69 (2026-03-03) to include `semantic_type_id`
**Type**: VIEW with `security_invoker = true` (not a table — read-only, caller RLS applies)

### Columns

| Column | Type | Description |
|--------|------|-------------|
| `artifact_id` | uuid | Parent artifact ID |
| `artifact_type` | text | Parent artifact type (project/branch/limb) |
| `workspace_id` | uuid | Workspace boundary |
| `semantic_type_id` | uuid | Semantic classification (from parent, T69) |
| `total_active_children_count` | bigint | Count of non-deleted direct children |
| `completed_children_count` | bigint | Count of children with `execution_status = 'complete'` |
| `completion_ratio` | numeric | `completed / total` (NULL if 0 children) |

### Design Notes

- Denominator: all non-deleted children (`deleted_at IS NULL`), regardless of `execution_status`
- Numerator: children where `execution_status = 'complete'`
- 0 children → `completion_ratio = NULL` (not 0)
- Direct parent-child only (no recursive CTE)
- Rollup is opt-in via `selector.rollup: true` in Gateway query

---

## qxb_artifact_type_registry

**Purpose**: Authoritative registry of recognized artifact types. Gateway consults this before save/update/promote operations.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_type` | text | NOT NULL | — | Primary key (type name) |
| `enabled` | boolean | NOT NULL | `true` | Whether type is enabled for Gateway operations |
| `description` | text | NULL | — | Human-readable type description |
| `created_at` | timestamptz | NOT NULL | `now()` | Registry entry creation |
| `updated_at` | timestamptz | NOT NULL | `now()` | Registry entry update |

### Constraints

**Primary Key**: `artifact_type`

### RLS

- **Enabled**: Yes
- Policies: [NEEDS VERIFICATION] (T27)

---

## qxb_artifact_type_registry_audit

**Purpose**: Append-only audit log for all changes to `qxb_artifact_type_registry`.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `audit_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key |
| `artifact_type` | text | NOT NULL | — | Type that was changed |
| `action` | text | NOT NULL | — | Action performed |
| `actor` | text | NOT NULL | `'service_role'` | Who performed the action |
| `old_enabled` | boolean | NULL | — | Previous enabled state |
| `new_enabled` | boolean | NULL | — | New enabled state |
| `reason` | text | NULL | — | Reason for change |
| `created_at` | timestamptz | NOT NULL | `now()` | Audit entry creation |

### Constraints

**Primary Key**: `audit_id`

### RLS

- **Enabled**: Yes
- Policies: [NEEDS VERIFICATION] (T27)

---

## qxb_gateway_acl

**Purpose**: Gateway ACL table. Maps `principal_name` x `workspace_id` for multi-forest access control.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `acl_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key |
| `principal_name` | text | NOT NULL | — | Gateway principal identifier |
| `workspace_id` | uuid | NOT NULL | — | FK to qxb_workspace |
| `role` | text | NOT NULL | `'owner'` | ACL role assignment |
| `created_at` | timestamptz | NOT NULL | `now()` | ACL entry creation |

### Constraints

**Primary Key**: `acl_id`

**Foreign Keys**:
- `workspace_id` → `qxb_workspace.workspace_id`

### RLS

- **Enabled**: Yes
- **ZERO policies** — deny-all by design. Access via `service_role` only.

---

## Helper Functions

### `qxb_current_user_id()`

**Purpose**: Maps Supabase Auth `auth.uid()` to `qxb_user.user_id`
**Returns**: `uuid`
**Language**: SQL
**Volatility**: STABLE

```sql
SELECT user_id FROM public.qxb_user WHERE auth_user_id = auth.uid()
```

### `qxb_block_update_delete()`

**Purpose**: Trigger function that raises an exception to block UPDATE/DELETE on append-only tables.
**Returns**: `trigger`
**Language**: plpgsql
**Applied to**: `qxb_artifact_event`, `qxb_semantic_type_audit`

### `qxb_set_updated_at()`

**Purpose**: Trigger function to auto-update `updated_at` column to `now()`.
**Returns**: `trigger`
**Language**: plpgsql
**Applied to**: `qxb_artifact`, `qxb_artifact_journal`, `qxb_artifact_project`, `qxb_artifact_limb`, `qxb_user`, `qxb_workspace`, `qxb_workspace_user`

### `check_leaf_dependencies(p_artifact_id uuid, p_workspace_id uuid)`

**Purpose**: Returns first incomplete dependency for a leaf artifact. Called by Update sub-workflow to enforce leaf-to-leaf dependency rules before allowing `execution_status = 'complete'`.
**Returns**: `TABLE (depends_on_artifact_id uuid, execution_status text)`
**Language**: SQL
**Security**: SECURITY DEFINER, SET search_path = public
**Behavior**:
- 0 rows returned = all dependencies complete (or no dependencies exist) — leaf can complete
- 1 row returned = at least one incomplete dependency — leaf completion blocked
- Uses `LIMIT 1` for early exit (only need to find one blocker)
**Called via**: `POST /rest/v1/rpc/check_leaf_dependencies`

### `update_semantic_type(p_artifact_id uuid, p_new_semantic_type_id uuid, p_reason text, p_actor_id uuid DEFAULT NULL)`

**Purpose**: Atomic semantic type update + audit insert. Validates artifact exists, is top-level type, new type is active in registry, reason is non-empty. Increments version. Inserts audit row. Fail-closed: any error rolls back entire transaction.
**Returns**: `jsonb` (`ok: true/false` + error envelope on failure)
**Language**: plpgsql
**Security**: SECURITY DEFINER, SET search_path = public
**Phase**: T69 (2026-03-03)
**Validations**:
1. `p_reason` is non-empty
2. Artifact exists (fetched with `FOR UPDATE` lock)
3. Artifact is a top-level type (`project`, `snapshot`, `journal`, `restart`)
4. New semantic type exists and is active in registry
5. No-op detection (same value = skip mutation)
**Mutations (atomic)**:
- Updates `qxb_artifact.semantic_type_id` and increments `version`
- Inserts row into `qxb_semantic_type_audit`
**Error codes**: `VALIDATION_ERROR`, `NOT_FOUND`, `SEMANTIC_TYPE_NOT_APPLICABLE`, `INVALID_SEMANTIC_TYPE`, `SEMANTIC_TYPE_INACTIVE`
**Called via**: `POST /rest/v1/rpc/update_semantic_type`

---

## Indexes

| Index Name | Table | Type | Columns | Condition |
|------------|-------|------|---------|-----------|
| `qxb_artifact_grass_review_detected_idx` | `qxb_artifact_grass` | btree | `review_status`, `detected_at DESC` | — |
| `qxb_artifact_thorn_severity_detected_idx` | `qxb_artifact_thorn` | btree | `severity`, `detected_at DESC` | — |
| `qxb_artifact_thorn_status_detected_idx` | `qxb_artifact_thorn` | btree | `status`, `detected_at DESC` | — |
| `uq_qxb_artifact_forest_title_active` | `qxb_artifact` | UNIQUE (partial) | `workspace_id`, `lower(title)` | `artifact_type = 'forest' AND deleted_at IS NULL` |
| `uq_qxb_artifact_thicket_title_per_forest_active` | `qxb_artifact` | UNIQUE (partial) | `workspace_id`, `parent_artifact_id`, `lower(title)` | `artifact_type = 'thicket' AND deleted_at IS NULL` |
| `idx_qxb_artifact_dependency_source` | `qxb_artifact_dependency` | btree | `artifact_id` | — |
| `idx_qxb_artifact_dependency_target` | `qxb_artifact_dependency` | btree | `depends_on_artifact_id` | — |
| `idx_qxb_artifact_semantic_type` | `qxb_artifact` | btree (partial) | `semantic_type_id` | `semantic_type_id IS NOT NULL` |
| `idx_qxb_semantic_type_audit_artifact` | `qxb_semantic_type_audit` | btree | `artifact_id`, `created_at DESC` | — |

---

## Artifact Type Summary

| Type | Extension Table | CHECK v8 | Mutability | semantic_type_id | Purpose |
|------|----------------|----------|------------|------------------|---------|
| `project` | `qxb_artifact_project` | Yes | UPDATE allowed | **REQUIRED** | Lifecycle tracking (seed → sapling → tree → archive) |
| `journal` | `qxb_artifact_journal` | Yes | UPDATE allowed | **REQUIRED** | Owner-private reflections |
| `snapshot` | `qxb_artifact_snapshot` | Yes | CREATE-ONLY | **REQUIRED** | Immutable lifecycle snapshots |
| `restart` | `qxb_artifact_restart` | Yes | CREATE-ONLY | **REQUIRED** | Immutable session continuation |
| `grass` | `qxb_artifact_grass` | Yes | UPDATE allowed | NULL allowed | Operational issue tracking |
| `thorn` | `qxb_artifact_thorn` | Yes | UPDATE allowed | NULL allowed | Exception tracking |
| `branch` | (no extension table) | Yes | Spine-only | NULL allowed | Execution anatomy (North Star v0.4) |
| `leaf` | (no extension table) | Yes | Spine-only | NULL allowed | Execution anatomy (North Star v0.4) |
| `limb` | `qxb_artifact_limb` | Yes | UPDATE allowed | NULL allowed | Execution anatomy shell (Phase 2) |
| `instruction_pack` | `qxb_artifact_instruction_pack` | Yes | UPDATE allowed | NULL allowed | Instruction pack storage |
| `forest` | (no extension table) | Yes | Spine-only | NULL allowed | Workspace grouping (reserved) |
| `thicket` | (no extension table) | Yes | Spine-only | NULL allowed | Sub-forest grouping (reserved) |
| `flower` | (no extension table) | Yes | Spine-only | NULL allowed | Reserved |
| `person` | `qxb_artifact_person` | Yes | UPDATE allowed | **REQUIRED** | Real individuals in operator's network (T150) |
| `twig` | (no extension table) | Yes | Spine + lifecycle | NULL allowed | Experimental micro-initiative (T94, pilot: Mother Tree) |
| `video` | `qxb_artifact_video` | **No** | UPDATE allowed | NULL allowed | Long-form media (NOT in CHECK v8) |

### Gateway Type Registry Boundary (2026-02-20)

The following types exist in CHECK v8 but are **intentionally blocked** at the Gateway layer pending activation:

| Type | Status | Reason |
|------|--------|--------|
| `grass` | **Blocked** | Extension table exists but no Gateway Save/Update routing |
| `thorn` | **Blocked** | Extension table exists but no Gateway Save/Update routing |
| `forest` | **Blocked** | Reserved — no extension table, no Gateway routing |
| `thicket` | **Blocked** | Reserved — no extension table, no Gateway routing |
| `flower` | **Blocked** | Reserved — no extension table, no Gateway routing |

**Authoritative boundary**: The `qxb_artifact_type_registry` table (service_role access only) determines which types are Gateway-routable. CHECK v8 defines what types the database *accepts*; the type registry defines what types the Gateway *routes*. These are intentionally decoupled — CHECK is permissive; registry is restrictive.

Types will be activated when Gateway routing, extension table schema, and validation logic are implemented for each.

---

## CHANGELOG

### v2.10 — 2026-03-22

**T150 Person Artifact Type — Branch 2 Schema.**

1. `artifact_type` CHECK v7 → v8: added `'person'` (15 types total).
2. New table: `qxb_artifact_person` — full extension table (27 columns, PK=FK). Identity, contact, professional, interaction, JSONB fields.
3. 3 JSONB array shape CHECKs (`key_facts`, `what_they_care_about`, `preferences`).
4. `semantic_type_required_for_top_level`: `'person'` added to required list.
5. Type registry entry: `person` (enabled).
6. RLS: 3 policies. SELECT uses workspace_user join (hardened per Q audit). INSERT owner. UPDATE owner/admin.
7. 6 indexes: `full_name` (B-tree), `relationship_type` (B-tree), `last_contacted_at` (B-tree partial), `key_facts` (GIN partial), `what_they_care_about` (GIN partial), `preferences` (GIN partial).
8. Trigger: `updated_at` via shared `qxb_set_updated_at()`.

**Table count**: 19 → 20 tables + 1 VIEW.

### v2.9 — 2026-03-07

**T80 Security Advisor Fixes.**

1. `qxb_artifact_rollup_view`: added `WITH (security_invoker = true)`. View now runs with caller permissions/RLS instead of creator permissions.
2. `qxb_artifact_dependency`: RLS + 3 policies confirmed deployed (were in DDL v2.5+ but missing from live DB — T71 drift fix).
3. `_migration_priority_null_snapshot`: dropped (leftover migration table, 494 rows, no references).
4. RLS initplan optimization: 4 policies updated to use `(select auth.uid())` instead of `auth.uid()` for per-query evaluation instead of per-row. Tables: `qxb_user` (2 policies), `qxb_workspace` (1), `qxb_workspace_user` (1).

**Table count**: 20 → 19 tables + 1 VIEW (dropped `_migration_priority_null_snapshot`).

**Source**: LIVE DDL v2.9 (2026-03-07)
**Previous version**: `Archive/Schema_Reference__Kernel_v1__v2.8__2026-03-06.md`

### v2.7 — 2026-03-06

**What changed**: T87 gap closure — added `design_spine` JSONB column to `qxb_artifact_project`.

**Additions**:
1. **`qxb_artifact_project.design_spine`** column: jsonb, nullable, no default. Stores architecture definitions for project artifacts (architectural intent, system roles, capabilities, structural contracts).

**Context**: T87 deployed mutability registry (Check_Mutability_Rules v8) and documentation (Canonical v4) for `design_spine`, but the DB column was never created. Gateway accepted the field and returned ok:true, but values were silently discarded. Phase2C D20-D23 tests passed because they asserted response shape only, not read-back persistence.

**No other changes**: Table count, function count, RLS policies, indexes all unchanged.

**Source**: LIVE DDL v2.7 (2026-03-06)
**Previous version**: `Archive/Schema_Reference__Kernel_v1__v2.6__2026-03-06.md`

### v2.6 — 2026-03-04

**What changed**: T69 Semantic Type Registry + T70 Rollup VIEW merged into DDL and Schema Reference.

**Additions**:
1. **`qxb_semantic_type_registry` table**: Controlled vocabulary for `semantic_type_id`. PK: `semantic_type_id`. UNIQUE on `key`. Self-referential FK for hierarchy. FK to `qxb_artifact` for governance snapshots. RLS enabled, 1 SELECT policy (authenticated). No write policies (service_role only). 9 bootstrap values.
2. **`qxb_semantic_type_audit` table**: Append-only audit log for semantic type changes. PK: `id`. 3 FKs (artifact, old type, new type). 1 index. Triggers block UPDATE/DELETE. RLS enabled, 1 SELECT policy.
3. **`qxb_artifact.semantic_type_id`** column: uuid FK to registry (ON DELETE RESTRICT). Conditional NOT NULL CHECK: top-level types (project/snapshot/journal/restart) MUST NOT be NULL. Partial index.
4. **`update_semantic_type()` function**: Atomic RPC for semantic type changes + audit insert. SECURITY DEFINER, search_path pinned. 5 validations, fail-closed.
5. **`qxb_artifact_rollup_view`**: VIEW for completion rollup (T70). Updated by T69 to include `semantic_type_id` in SELECT/GROUP BY.

**Table count**: 18 → 20 tables + 1 VIEW.
**Function count**: 4 → 5 functions.

**Source**: LIVE DDL v2.6 (2026-03-04)
**Previous version**: `Archive/Schema_Reference__Kernel_v1__v2.5__2026-03-04.md`

### v2.5 — 2026-03-01

**What changed**: T71 Dependency Enforcement — added `qxb_artifact_dependency` table and `check_leaf_dependencies()` RPC function.

**Additions**:
1. **`qxb_artifact_dependency` table**: Many-to-many leaf-to-leaf dependency tracking. PK: `dependency_id`. FKs to `qxb_artifact` (source + target) and `qxb_workspace`. Self-ref CHECK. 3 RLS policies (SELECT/INSERT member, DELETE owner/admin). No UPDATE policy (immutable).
2. **`check_leaf_dependencies()` function**: RPC function for Update sub-workflow dependency enforcement. SECURITY DEFINER with inline search_path hardening.
3. **2 indexes**: Forward and reverse dependency lookups.

**Source**: LIVE DDL v2.5 (2026-03-01)
**Previous version**: `Archive/Schema_Reference__Kernel_v1__v2.3__2026-03-01.md`

### v2.3 — 2026-02-20

**What changed**: Full regeneration from LIVE DDL v2.3. Supersedes v1.2.

**Drift sources corrected** (v1.2 → v2.3):

1. **`qxb_artifact.priority`**: Was `NULL, no default`. Now `NOT NULL DEFAULT 3, CHECK (1-5)`.
2. **`qxb_artifact.execution_status`**: Was **missing entirely**. Now `text NULL, CHECK IS NULL OR IN (not_started, in_progress, blocked, complete)`. Spine-level field.
3. **`qxb_artifact.lifecycle_status`**: Was undocumented CHECK. Now conditional CHECK: `artifact_type <> 'project' OR lifecycle_status IN ('seed', 'sapling', 'tree', 'archive')`.
4. **`qxb_artifact.artifact_type` CHECK**: Was 10 types (included `video`). Now CHECK v8: 15 types (`video` NOT in CHECK; `branch`, `leaf`, `instruction_pack`, `limb`, `twig`, `person` added).
5. **`qxb_artifact_project.lifecycle_stage`**: Was `NULL`. Now `NOT NULL`.
6. **`qxb_artifact_project.lifecycle_stage` CHECK**: Was `seed, sapling, tree, retired`. Now `seed, sapling, tree, archive`. No `retired`.
7. **`qxb_artifact_project.operational_state`**: Was `jsonb NULL`. Now `text NOT NULL DEFAULT 'active', CHECK (active, paused, blocked, waiting)`.
8. **`qxb_artifact_project.state_reason`**: Was **missing**. Now `text NULL`.
9. **`qxb_workspace`**: Had phantom `owner_user_id` column. DDL has no such column. Ownership via `qxb_workspace_user` role.
10. **`qxb_workspace_user.role`**: Missing default. Now `DEFAULT 'member'`.
11. **5 tables missing entirely**: `qxb_artifact_instruction_pack`, `qxb_artifact_limb`, `qxb_artifact_type_registry`, `qxb_artifact_type_registry_audit`, `qxb_gateway_acl`.
12. **`qxb_block_update_delete()` function**: Was undocumented.
13. **`oak` and `retired` lifecycle values**: Removed — never existed in deployed DDL v2.3.

**Alignment date**: 2026-02-20
**DDL version**: v2.3 (Phase 2 Completion, 2026-02-16)
**Migration history**: v1 → v2 → v2.1 → v2.2 → v2.3

---

**Version**: v2.9
**Status**: Authoritative Reference
**Source**: LIVE DDL v2.7 (2026-03-06)
**Last Updated**: 2026-03-06
