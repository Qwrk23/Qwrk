# Schema Reference — Kernel v1 (Canonical)

**Source**: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`
**Date**: 2026-01-04
**Status**: Authoritative DDL-as-Truth Reference
**Purpose**: Human-readable schema documentation derived from LIVE database DDL

---

## Overview

Qwrk Kernel v1 uses **class-table inheritance pattern**:
- `qxb_artifact` = canonical "spine" table (all artifacts start here)
- Type-specific extension tables (PK=FK relationship)
- `qxb_artifact_event` = append-only audit log

**All tables have RLS enabled** (deny-by-default with explicit policies)

---

## Table of Contents

1. [qxb_artifact](#qxb_artifact) (Spine Table)
2. [qxb_artifact_project](#qxb_artifact_project) (Extension)
3. [qxb_artifact_journal](#qxb_artifact_journal) (Extension)
4. [qxb_artifact_snapshot](#qxb_artifact_snapshot) (Extension)
5. [qxb_artifact_restart](#qxb_artifact_restart) (Extension)
6. [qxb_artifact_grass](#qxb_artifact_grass) (Extension)
7. [qxb_artifact_thorn](#qxb_artifact_thorn) (Extension)
8. [qxb_artifact_event](#qxb_artifact_event) (Audit Log)
9. [qxb_user](#qxb_user) (Identity Mapping)
10. [qxb_workspace](#qxb_workspace) (Tenancy)
11. [qxb_workspace_user](#qxb_workspace_user) (Membership)

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
| `artifact_type` | text | NOT NULL | — | Type discriminator (see CHECK constraint) |
| `title` | text | NOT NULL | — | Human-readable title |
| `summary` | text | NULL | — | Short description for list views |
| `priority` | integer | NULL | — | 1-5 scale (1=Critical, 5=Plan) |
| `lifecycle_status` | text | NULL | — | Canonical lifecycle stage |
| `tags` | jsonb | NULL | — | Tag set for filtering/organization |
| `content` | jsonb | NULL | — | Flexible payload (minimal; type tables hold structured data) |
| `parent_artifact_id` | uuid | NULL | — | FK to qxb_artifact (lineage/spawn relationships) |
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
- `artifact_type` IN ('project', 'snapshot', 'restart', 'journal', 'forest', 'thicket', 'flower', 'thorn', 'grass')
- `priority` BETWEEN 1 AND 5

### Triggers

- `qxb_artifact_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at` timestamp

### RLS

- **Enabled**: Yes (deny-by-default)
- **Policy approach**: Workspace-scoped visibility based on `qxb_workspace_user` membership

---

## qxb_artifact_project

**Purpose**: Extension table for project artifacts. Tracks lifecycle stages (seed → sapling → tree → retired) and operational state.

**Extends**: `qxb_artifact` (PK=FK pattern)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `lifecycle_stage` | text | NULL | — | Project lifecycle: seed, sapling, tree, retired |
| `operational_state` | jsonb | NULL | — | Flexible operational metadata (deliverables, status, next actions) |
| `created_at` | timestamptz | NOT NULL | `now()` | Extension record creation |
| `updated_at` | timestamptz | NOT NULL | `now()` | Extension record update (auto-updated by trigger) |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id`

### Triggers

- `qxb_artifact_project_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS

- **Enabled**: Yes
- **Policy approach**: Delegates to `qxb_artifact` spine policies

### JSONB Structure (`operational_state`)

Example for seed-stage project:
```json
{
  "status": "ready_to_activate",
  "prerequisite": "crawl_complete",
  "deliverables": ["Workflow JSON", "Email templates", "Runbook"],
  "timeline_estimate": "1-2 weeks",
  "next_actions": ["Draft templates", "Build workflows", "Test"]
}
```

---

## qxb_artifact_journal

**Purpose**: Extension table for journal artifacts. Stores owner-private reflective text and flexible payload.

**Extends**: `qxb_artifact` (PK=FK pattern)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `entry_text` | text | NULL | — | Main journal entry text (owner-private) |
| `payload` | jsonb | NULL | — | Flexible metadata (tags, mood, links, etc.) |
| `created_at` | timestamptz | NOT NULL | `now()` | Entry creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Entry update timestamp (auto-updated) |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id`

### Triggers

- `qxb_artifact_journal_set_updated_at` (BEFORE UPDATE): Auto-updates `updated_at`

### RLS

- **Enabled**: Yes
- **Policy approach**: **Owner-only** (journals are strictly private to owner_user_id)

### JSONB Structure (`payload`)

Example:
```json
{
  "mood": "reflective",
  "session_type": "coaching",
  "conversation_id": "uuid-here",
  "key_insights": ["insight 1", "insight 2"]
}
```

---

## qxb_artifact_snapshot

**Purpose**: Extension table for snapshot artifacts. Immutable lifecycle snapshots with JSONB payload.

**Extends**: `qxb_artifact` (PK=FK pattern)
**Mutability**: CREATE-ONLY (no UPDATE policies)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `payload` | jsonb | NOT NULL | — | Immutable snapshot data |
| `created_at` | timestamptz | NOT NULL | `now()` | Snapshot creation timestamp |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id`

### RLS

- **Enabled**: Yes
- **Policy approach**: SELECT only (no UPDATE/DELETE policies)

### JSONB Structure (`payload`)

Flexible structure for frozen state snapshots. Example:
```json
{
  "snapshot_type": "project_milestone",
  "captured_state": { ... },
  "metadata": { "milestone": "v1.0_launch" }
}
```

---

## qxb_artifact_restart

**Purpose**: Extension table for restart artifacts. Manual session continuation with immutable payload.

**Extends**: `qxb_artifact` (PK=FK pattern)
**Mutability**: CREATE-ONLY (no UPDATE policies)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `artifact_id` | uuid | NOT NULL | — | PK & FK to qxb_artifact.artifact_id |
| `payload` | jsonb | NOT NULL | — | Immutable restart context |
| `created_at` | timestamptz | NOT NULL | `now()` | Restart creation timestamp |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id`

### RLS

- **Enabled**: Yes
- **Policy approach**: SELECT only (no UPDATE/DELETE policies)

### JSONB Structure (`payload`)

Session continuation context. Example:
```json
{
  "restart_type": "session_resume",
  "prior_session_summary": "...",
  "context_items": ["item1", "item2"],
  "continuation_intent": "continue_design_work"
}
```

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
| `review_status` | text | NOT NULL | `'unreviewed'` | Review state: unreviewed, reviewed, dismissed |
| `summary` | text | NOT NULL | — | Brief issue description |
| `details_json` | jsonb | NOT NULL | `'{}'` | Detailed issue data |
| `disposition` | text | NOT NULL | `'none'` | Disposition: none, promoted_to_flower, dismissed |
| `reviewed_at` | timestamptz | NULL | — | Review completion timestamp |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id`

**Check Constraints**:
- `review_status` IN ('unreviewed', 'reviewed', 'dismissed')
- `disposition` IN ('none', 'promoted_to_flower', 'dismissed')

### RLS

- **Enabled**: Yes
- **Policy approach**: Workspace-scoped (operational visibility)

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
| `severity` | text | NOT NULL | `'medium'` | Severity: low, medium, high, critical |
| `review_status` | text | NOT NULL | `'unreviewed'` | Review state |
| `summary` | text | NOT NULL | — | Brief exception description |
| `details_json` | jsonb | NOT NULL | `'{}'` | Detailed exception data |
| `resolution` | text | NOT NULL | `'none'` | Resolution state |
| `resolved_at` | timestamptz | NULL | — | Resolution timestamp |
| `created_at` | timestamptz | NOT NULL | `now()` | Thorn creation timestamp |

### Constraints

**Primary Key**: `artifact_id`

**Foreign Keys**:
- `artifact_id` → `qxb_artifact.artifact_id`

**Check Constraints**:
- `severity` IN ('low', 'medium', 'high', 'critical')
- `review_status` IN ('unreviewed', 'reviewed', 'dismissed')
- `resolution` IN ('none', 'resolved', 'dismissed', 'escalated')

### RLS

- **Enabled**: Yes
- **Policy approach**: Workspace-scoped (exception visibility)

---

## qxb_artifact_event

**Purpose**: Append-only audit log for all artifact operations. Immutable event history.

**Mutability**: CREATE-ONLY (triggers block UPDATE/DELETE)

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
- `artifact_id` → `qxb_artifact.artifact_id`
- `actor_user_id` → `qxb_user.user_id`

### Triggers

- **Blocks UPDATE and DELETE** (append-only enforcement)

### RLS

- **Enabled**: Yes
- **Policy approach**: Workspace-scoped SELECT (append via application logic)

---

## qxb_user

**Purpose**: Maps Supabase Auth users to Qwrk user identity. Required for RLS policies.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `user_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key (Qwrk user ID) |
| `auth_user_id` | uuid | NOT NULL | — | FK to auth.users (Supabase Auth) |
| `email` | text | NOT NULL | — | User email address (for display) |
| `display_name` | text | NULL | — | User display name |
| `created_at` | timestamptz | NOT NULL | `now()` | User registration timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Profile update timestamp |

### Constraints

**Primary Key**: `user_id`

**Unique Constraints**:
- `auth_user_id` (one-to-one mapping)
- `email` (unique email addresses)

### RLS

- **Enabled**: Yes
- **Policy approach**: Users can SELECT their own record via `qxb_current_user_id()` helper

---

## qxb_workspace

**Purpose**: Workspace (tenancy boundary). All artifacts belong to a workspace.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `workspace_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key (workspace ID) |
| `owner_user_id` | uuid | NOT NULL | — | FK to qxb_user (workspace owner) |
| `name` | text | NOT NULL | — | Workspace name |
| `created_at` | timestamptz | NOT NULL | `now()` | Workspace creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Workspace update timestamp |

### Constraints

**Primary Key**: `workspace_id`

**Foreign Keys**:
- `owner_user_id` → `qxb_user.user_id`

### RLS

- **Enabled**: Yes
- **Policy approach**: Visible to workspace members (via qxb_workspace_user)

---

## qxb_workspace_user

**Purpose**: Workspace membership and role-based access. Maps users to workspaces with roles.

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `workspace_user_id` | uuid | NOT NULL | `gen_random_uuid()` | Primary key |
| `workspace_id` | uuid | NOT NULL | — | FK to qxb_workspace |
| `user_id` | uuid | NOT NULL | — | FK to qxb_user |
| `role` | text | NOT NULL | — | Role: owner, admin, member |
| `created_at` | timestamptz | NOT NULL | `now()` | Membership creation timestamp |
| `updated_at` | timestamptz | NOT NULL | `now()` | Membership update timestamp |

### Constraints

**Primary Key**: `workspace_user_id`

**Unique Constraints**:
- `(workspace_id, user_id)` (one membership per user per workspace)

**Foreign Keys**:
- `workspace_id` → `qxb_workspace.workspace_id`
- `user_id` → `qxb_user.user_id`

**Check Constraints**:
- `role` IN ('owner', 'admin', 'member')

### RLS

- **Enabled**: Yes
- **Policy approach**: Users can SELECT their own memberships

---

## Helper Functions

### `qxb_current_user_id()`

**Purpose**: Maps Supabase Auth `auth.uid()` to `qxb_user.user_id`

**Returns**: `uuid`

**Usage in RLS policies**:
```sql
owner_user_id = qxb_current_user_id()
```

### `qxb_set_updated_at()`

**Purpose**: Trigger function to auto-update `updated_at` column

**Returns**: `trigger`

**Applied to**: All tables with `updated_at` column

---

## Artifact Type Summary

| Type | Extension Table | Mutability | Purpose |
|------|----------------|------------|---------|
| `project` | `qxb_artifact_project` | UPDATE allowed | Lifecycle tracking (seed→tree) |
| `journal` | `qxb_artifact_journal` | UPDATE allowed | Owner-private reflections |
| `snapshot` | `qxb_artifact_snapshot` | CREATE-ONLY | Immutable lifecycle snapshots |
| `restart` | `qxb_artifact_restart` | CREATE-ONLY | Immutable session continuation |
| `grass` | `qxb_artifact_grass` | UPDATE allowed | Operational issue tracking |
| `thorn` | `qxb_artifact_thorn` | UPDATE allowed | Exception tracking |
| `forest` | (TBD) | (TBD) | (Reserved for future use) |
| `thicket` | (TBD) | (TBD) | (Reserved for future use) |
| `flower` | (TBD) | (TBD) | (Reserved for future use) |

---

## CHANGELOG

### 2026-01-04
**What changed**: Initial canonical schema reference creation

**Why**: Establish DDL-as-Truth governance; eliminate schema drift errors

**Scope**: Comprehensive reference for all Kernel v1 tables derived from LIVE DDL export

**Source**: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`

**How to validate**: Cross-reference against LIVE DDL file for accuracy

---

**Version**: v1
**Status**: Authoritative Reference
**Source**: LIVE DDL (2026-01-04)
**Last Updated**: 2026-01-04
