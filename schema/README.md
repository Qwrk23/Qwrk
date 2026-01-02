# Database Schema — New Qwrk Kernel v1

**PostgreSQL schemas for Supabase backend**

---

## Overview

This directory contains the authoritative database schema for New Qwrk Kernel v1, organized by dependency order and purpose.

**Database**: PostgreSQL 15+ (Supabase)
**Project Ref**: `npymhacpmxdnkdgzxll`
**Architecture**: Class-table inheritance with Row Level Security (RLS)

---

## Directory Structure

```
schema/
├── 01_bundle/              # Complete schema bundle (recommended)
├── 02_individual_tables/   # Individual table definitions
├── 03_rls_policies/        # Row Level Security policies
├── 04_kgb/                 # Known-Good Baseline validation
└── README.md               # This file
```

---

## Execution Order (CRITICAL)

### Recommended: Use Bundle

```bash
# 1. Execute complete bundle (includes pgcrypto + all tables)
psql -f 01_bundle/AAA_New_Qwrk__Schema__Kernel_v1__BUNDLE__v1.0__2025-12-30.sql

# 2. Apply latest RLS policies
psql -f 03_rls_policies/AAA_New_Qwrk__RLS_Patch__Kernel_v1__v1.2__2025-12-30.sql

# 3. Validate with KGB pack
psql -f 04_kgb/AAA_New_Qwrk__KGB__Kernel_v1__SQL_Pack__v1.0__2025-12-30.sql
```

### Alternative: Individual Tables

If running individual files from `02_individual_tables/`, execute in this **strict dependency order**:

1. `AAA_New_Qwrk__Schema__Qxb_User__v1.0__2025-12-30.sql`
2. `AAA_New_Qwrk__Schema__Qxb_Workspace__v1.0__2025-12-30.sql`
3. `AAA_New_Qwrk__Schema__Qxb_Workspace_User__v1.0__2025-12-30.sql`
4. `AAA_New_Qwrk__Schema__Qxb_Artifact__v1.0__2025-12-30.sql`
5. `AAA_New_Qwrk__Schema__Qxb_Artifact_Project__v1.0__2025-12-30.sql`
6. `AAA_New_Qwrk__Schema__Qxb_Artifact_Snapshot__v1.0__2025-12-30.sql`
7. `AAA_New_Qwrk__Schema__Qxb_Artifact_Restart__v1.0__2025-12-30.sql`
8. `AAA_New_Qwrk__Schema__Qxb_Artifact_Journal__v1.0__2025-12-30.sql`
9. `AAA_New_Qwrk__Schema__Qxb_Artifact_Event__v1.0__2025-12-30.sql`

Then apply RLS policies (see above).

---

## Table Dependency Graph

```
pgcrypto (extension)
    ↓
Qxb_User
    ↓
Qxb_Workspace
    ↓
Qxb_Workspace_User
    ↓
Qxb_Artifact (spine)
    ↓
┌─────────┬──────────┬──────────┬──────────┐
│ Project │ Snapshot │ Restart  │ Journal  │ Event
└─────────┴──────────┴──────────┴──────────┘
(All extend Qxb_Artifact via PK=FK)
```

---

## Schema Architecture

### Class-Table Inheritance

**Spine Table**: `Qxb_Artifact`
- Contains all common fields (artifact_id, title, workspace_id, owner_user_id, etc.)
- PK: `artifact_id` (uuid, auto-generated)

**Type Tables**: Extend spine via PK=FK relationship
- `Qxb_Artifact_Project`: `artifact_id` → `Qxb_Artifact.artifact_id`
- `Qxb_Artifact_Snapshot`: `artifact_id` → `Qxb_Artifact.artifact_id`
- `Qxb_Artifact_Restart`: `artifact_id` → `Qxb_Artifact.artifact_id`
- `Qxb_Artifact_Journal`: `artifact_id` → `Qxb_Artifact.artifact_id`

**Event Log**: `Qxb_Artifact_Event`
- Append-only audit trail
- Protected by triggers (blocks UPDATE/DELETE)

---

## Row Level Security (RLS)

**Status**: Enabled on all tables (deny-by-default)

### Helper Function

`qxb_current_user_id()` - Maps `auth.uid()` → `qxb_user.user_id`

### Policy Model

- **Workspace visibility**: Users see only workspaces where they have membership
- **Artifact visibility**: Workspace members can read (except journals = owner-only)
- **Type table policies**: Delegate to `Qxb_Artifact` spine

### Known RLS Fixes

**v1.1** (2025-12-30):
- Fixed infinite recursion in `qxb_workspace_user_select_member`
- Created self-only select policy: `qxb_workspace_user_select_self`
- Updated workspace policy to use direct membership check

**v1.2** (2025-12-30):
- Additional RLS refinements (see patch file)

---

## Known-Good Baseline (KGB)

The KGB SQL pack validates:

- All tables exist with correct schema
- RLS policies are applied
- Foreign key constraints are valid
- Triggers are active
- Extension (pgcrypto) is enabled

**Run after** schema + RLS execution to confirm health.

---

## Key Fields

### Qxb_Artifact (Spine)

| Field | Type | Purpose |
|-------|------|---------|
| `artifact_id` | uuid | Primary key (auto-generated) |
| `workspace_id` | uuid | Required FK to Qxb_Workspace |
| `owner_user_id` | uuid | Required FK to Qxb_User |
| `artifact_type` | text | Allow-listed type (project, snapshot, restart, journal) |
| `title` | text | Human-readable title |
| `summary` | text | Short description |
| `priority` | int | 1-5 (Critical/High/Medium/Low/Plan) |
| `lifecycle_status` | text | Canonical lifecycle stage |
| `tags` | jsonb | Tag set for filtering |
| `content` | jsonb | Flexible payload |
| `parent_artifact_id` | uuid | Optional FK for lineage |
| `version` | int | Starts at 1, increments on update |
| `deleted_at` | timestamptz | Soft delete timestamp |
| `created_at` | timestamptz | Creation timestamp |
| `updated_at` | timestamptz | Last update (auto-updated) |

### Qxb_Artifact_Project

| Field | Type | Purpose |
|-------|------|---------|
| `artifact_id` | uuid | PK=FK to Qxb_Artifact |
| `lifecycle_stage` | text | seed, sapling, tree, retired |
| `operational_state` | text | active, paused, blocked, waiting |
| `state_reason` | text | Optional reason for blocked/waiting |
| `start_date` | date | Optional start date |
| `target_date` | date | Optional target date |
| `retired_at` | timestamptz | Retirement timestamp |
| `last_lifecycle_change_at` | timestamptz | Last lifecycle transition |
| `lifecycle_notes` | text | Optional lifecycle notes |

### Qxb_Artifact_Snapshot

| Field | Type | Purpose |
|-------|------|---------|
| `artifact_id` | uuid | PK=FK to Qxb_Artifact |
| `project_artifact_id` | uuid | FK to source project |
| `lifecycle_from` | text | Previous lifecycle stage |
| `lifecycle_to` | text | New lifecycle stage |
| `captured_version` | int | Version of project when captured |
| `frozen_payload` | jsonb | Immutable project state |
| `capture_reason` | text | Optional reason |

### Qxb_Artifact_Restart

| Field | Type | Purpose |
|-------|------|---------|
| `artifact_id` | uuid | PK=FK to Qxb_Artifact |
| `project_artifact_id` | uuid | FK to related project |
| `restart_reason` | text | Why the restart |
| `next_step` | text | Optional next step |
| `frozen_payload` | jsonb | Immutable project state |

### Qxb_Artifact_Journal

| Field | Type | Purpose |
|-------|------|---------|
| `artifact_id` | uuid | PK=FK to Qxb_Artifact |
| `entry_text` | text | Main journal entry |
| `payload` | jsonb | Optional structured metadata |

---

## Immutability Rules

**Fully Immutable (no UPDATE policies):**
- `Qxb_Artifact_Snapshot`
- `Qxb_Artifact_Restart`
- `Qxb_Artifact_Event` (protected by triggers)

**Mutable with Constraints:**
- `Qxb_Artifact_Project` (PATCH semantics via Gateway)
- `Qxb_Artifact_Journal` (INSERT-ONLY per doctrine, UPDATE blocked)

---

## Troubleshooting

### RLS Infinite Recursion

**Symptom**: "infinite recursion detected in policy for relation qxb_workspace_user"

**Solution**: Ensure you've applied the latest RLS patch (v1.2 or later)

### Missing pgcrypto Extension

**Symptom**: "function gen_random_uuid() does not exist"

**Solution**:
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

### Foreign Key Violations

**Symptom**: "insert or update violates foreign key constraint"

**Solution**: Verify execution order. Parent tables must be populated before child tables.

---

## Version History

- **v1.0** (2025-12-30): Initial Kernel v1 schema
- **v1.1** (2025-12-30): RLS recursion fix
- **v1.2** (2025-12-30): Additional RLS refinements

---

## References

- [North Star](../docs/architecture/North_Star_v0.1.md)
- [Phase 1-3 Documentation](../docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md)
- [Mutability Registry](../docs/governance/Mutability_Registry_v1.md)

---

**Last Updated**: 2026-01-02
**Schema Version**: Kernel v1
