# Schema Reference — Kernel v1 (v2.3)

**Source**: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` (DDL v2.3)
**Date**: 2026-02-20
**Version**: v2.3
**Status**: Authoritative DDL-as-Truth Reference
**Purpose**: Human-readable schema documentation derived from LIVE database DDL

**Supersedes**: v1.2 (`Schema_Reference__Kernel_v1__Canonical__v1.1.md`) — that file contained 9+ critical discrepancies vs deployed DDL.

**Drift Prevention Rule**: Any DDL version change requires a corresponding update to this Schema Reference in the same commit. See CLAUDE.md § Schema Truth Policy.

---

## Overview

Qwrk Kernel v1 uses **class-table inheritance pattern**:
- `qxb_artifact` = canonical "spine" table (all artifacts start here)
- Type-specific extension tables (PK=FK relationship)
- `qxb_artifact_event` = append-only audit log

**17 tables total.** All tables have **RLS enabled** (deny-by-default with explicit policies).

**3 helper functions** support RLS and trigger logic.

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

### Audit & Event Log
14. [qxb_artifact_event](#qxb_artifact_event) — Append-Only Audit Log

### System Tables
15. [qxb_artifact_type_registry](#qxb_artifact_type_registry) — Type Registry
16. [qxb_artifact_type_registry_audit](#qxb_artifact_type_registry_audit) — Type Registry Audit Log
17. [qxb_gateway_acl](#qxb_gateway_acl) — Gateway Access Control

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
| `qxb_user_select_self` | SELECT | `auth_user_id = auth.uid()` |
| `qxb_user_update_self` | UPDATE | `auth_user_id = auth.uid()` |

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
| `qxb_workspace_select_via_auth_membership` | SELECT | User has membership via `qxb_workspace_user` JOIN `qxb_user` WHERE `auth_user_id = auth.uid()` |

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
| `qxb_workspace_user_select_via_auth` | SELECT | User's own memberships via `qxb_user` WHERE `auth_user_id = auth.uid()` |

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
| `artifact_type` | text | NOT NULL | — | Type discriminator (CHECK v6: 13 types) |
| `title` | text | NOT NULL | — | Human-readable title |
| `summary` | text | NULL | — | Short description for list views |
| `priority` | integer | **NOT NULL** | **`3`** | Priority scale 1-5 (1=highest, 5=lowest) |
| `lifecycle_status` | text | NULL | — | Lifecycle stage (conditional CHECK: project-only) |
| `execution_status` | text | NULL | — | Execution tracking (spine-level, all types) |
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

**Check Constraints**:
- **artifact_type (CHECK v6)**: IN (`'project'`, `'journal'`, `'restart'`, `'snapshot'`, `'grass'`, `'thorn'`, `'forest'`, `'thicket'`, `'flower'`, `'branch'`, `'leaf'`, `'instruction_pack'`, `'limb'`) — 13 types. Note: `'video'` is NOT in CHECK despite `qxb_artifact_video` table existing.
- **priority**: `>= 1 AND <= 5`
- **lifecycle_status (conditional)**: `artifact_type <> 'project' OR lifecycle_status IN ('seed', 'sapling', 'tree', 'archive')` — only enforced for project type; non-project types are unconstrained.
- **execution_status**: `IS NULL OR IN ('not_started', 'in_progress', 'blocked', 'complete')` — spine-level field available to all artifact types.

### Indexes

| Index | Type | Columns | WHERE |
|-------|------|---------|-------|
| `uq_qxb_artifact_forest_title_active` | UNIQUE (partial) | `workspace_id`, `lower(title)` | `artifact_type = 'forest' AND deleted_at IS NULL` |
| `uq_qxb_artifact_thicket_title_per_forest_active` | UNIQUE (partial) | `workspace_id`, `parent_artifact_id`, `lower(title)` | `artifact_type = 'thicket' AND deleted_at IS NULL` |

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
**Applied to**: `qxb_artifact_event`

### `qxb_set_updated_at()`

**Purpose**: Trigger function to auto-update `updated_at` column to `now()`.
**Returns**: `trigger`
**Language**: plpgsql
**Applied to**: `qxb_artifact`, `qxb_artifact_journal`, `qxb_artifact_project`, `qxb_artifact_limb`, `qxb_user`, `qxb_workspace`, `qxb_workspace_user`

---

## Indexes

| Index Name | Table | Type | Columns | Condition |
|------------|-------|------|---------|-----------|
| `qxb_artifact_grass_review_detected_idx` | `qxb_artifact_grass` | btree | `review_status`, `detected_at DESC` | — |
| `qxb_artifact_thorn_severity_detected_idx` | `qxb_artifact_thorn` | btree | `severity`, `detected_at DESC` | — |
| `qxb_artifact_thorn_status_detected_idx` | `qxb_artifact_thorn` | btree | `status`, `detected_at DESC` | — |
| `uq_qxb_artifact_forest_title_active` | `qxb_artifact` | UNIQUE (partial) | `workspace_id`, `lower(title)` | `artifact_type = 'forest' AND deleted_at IS NULL` |
| `uq_qxb_artifact_thicket_title_per_forest_active` | `qxb_artifact` | UNIQUE (partial) | `workspace_id`, `parent_artifact_id`, `lower(title)` | `artifact_type = 'thicket' AND deleted_at IS NULL` |

---

## Artifact Type Summary

| Type | Extension Table | CHECK v6 | Mutability | Purpose |
|------|----------------|----------|------------|---------|
| `project` | `qxb_artifact_project` | Yes | UPDATE allowed | Lifecycle tracking (seed → sapling → tree → archive) |
| `journal` | `qxb_artifact_journal` | Yes | UPDATE allowed | Owner-private reflections |
| `snapshot` | `qxb_artifact_snapshot` | Yes | CREATE-ONLY | Immutable lifecycle snapshots |
| `restart` | `qxb_artifact_restart` | Yes | CREATE-ONLY | Immutable session continuation |
| `grass` | `qxb_artifact_grass` | Yes | UPDATE allowed | Operational issue tracking |
| `thorn` | `qxb_artifact_thorn` | Yes | UPDATE allowed | Exception tracking |
| `branch` | (no extension table) | Yes | Spine-only | Execution anatomy (North Star v0.4) |
| `leaf` | (no extension table) | Yes | Spine-only | Execution anatomy (North Star v0.4) |
| `limb` | `qxb_artifact_limb` | Yes | UPDATE allowed | Execution anatomy shell (Phase 2) |
| `instruction_pack` | `qxb_artifact_instruction_pack` | Yes | UPDATE allowed | Instruction pack storage |
| `forest` | (no extension table) | Yes | Spine-only | Workspace grouping (reserved) |
| `thicket` | (no extension table) | Yes | Spine-only | Sub-forest grouping (reserved) |
| `flower` | (no extension table) | Yes | Spine-only | Reserved |
| `video` | `qxb_artifact_video` | **No** | UPDATE allowed | Long-form media (NOT in CHECK v6) |

### Gateway Type Registry Boundary (2026-02-20)

The following types exist in CHECK v6 but are **intentionally blocked** at the Gateway layer pending Phase 2C:

| Type | Status | Reason |
|------|--------|--------|
| `grass` | **Blocked** | Extension table exists but no Gateway Save/Update routing |
| `thorn` | **Blocked** | Extension table exists but no Gateway Save/Update routing |
| `forest` | **Blocked** | Reserved — no extension table, no Gateway routing |
| `thicket` | **Blocked** | Reserved — no extension table, no Gateway routing |
| `flower` | **Blocked** | Reserved — no extension table, no Gateway routing |

**Authoritative boundary**: The `qxb_artifact_type_registry` table (service_role access only) determines which types are Gateway-routable. CHECK v6 defines what types the database *accepts*; the type registry defines what types the Gateway *routes*. These are intentionally decoupled — CHECK is permissive; registry is restrictive.

Types will be activated when Gateway routing, extension table schema, and validation logic are implemented for each.

---

## CHANGELOG

### v2.3 — 2026-02-20

**What changed**: Full regeneration from LIVE DDL v2.3. Supersedes v1.2.

**Drift sources corrected** (v1.2 → v2.3):

1. **`qxb_artifact.priority`**: Was `NULL, no default`. Now `NOT NULL DEFAULT 3, CHECK (1-5)`.
2. **`qxb_artifact.execution_status`**: Was **missing entirely**. Now `text NULL, CHECK IS NULL OR IN (not_started, in_progress, blocked, complete)`. Spine-level field.
3. **`qxb_artifact.lifecycle_status`**: Was undocumented CHECK. Now conditional CHECK: `artifact_type <> 'project' OR lifecycle_status IN ('seed', 'sapling', 'tree', 'archive')`.
4. **`qxb_artifact.artifact_type` CHECK**: Was 10 types (included `video`). Now CHECK v6: 13 types (`video` NOT in CHECK; `branch`, `leaf`, `instruction_pack`, `limb` added).
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

**Version**: v2.3
**Status**: Authoritative Reference
**Source**: LIVE DDL v2.3 (2026-02-16)
**Last Updated**: 2026-02-20
