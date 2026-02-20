# AAA_New_Qwrk__Snapshot__CC_ReadOnly_QB_Access_Validated__2026-01-05__v1

**Date:** 2026-01-05
**Owner:** Master Joel
**Status:** LOCKED
**Build Phase:** Operational Baseline Established
**Milestone:** CC now has validated read-only database access to QB

---

## Summary
CC (Claude Code) now has validated read-only access to Qwrk's Brain (QB) via Supabase database. All permissions verified, schema visibility proven, and evidence-based building capability established.

---

## What Was Completed

### 1. Database Role Created
- Created `cc_readonly` role with SELECT-only permissions
- Granted CONNECT, USAGE on public schema
- Granted SELECT on all tables (current and future)
- Granted USAGE on sequences
- Verified role is non-superuser with login capability

### 2. Permissions Validated
Confirmed via has_table_privilege tests:
- ✅ SELECT: true (can read)
- ❌ INSERT: false (cannot write)
- ❌ UPDATE: false (cannot modify)
- ❌ DELETE: false (cannot remove)

### 3. Schema Visibility Proof Completed
**Part A - Object Inventory:**
- 12 database objects in public schema
- All qxb_* tables visible

**Part B - Column Inventory:**
Documented complete column schema for:
- qxb_artifact (spine table)
- qxb_artifact_project
- qxb_artifact_journal
- qxb_artifact_restart
- qxb_artifact_snapshot
- qxb_artifact_video
- qxb_attachment
- qxb_tag
- qxb_artifact_tag
- qxb_workspace
- qxb_user
- qxb_workspace_user

**Part C - Constraints:**
All foreign keys, primary keys, and check constraints documented for qxb_artifact* tables.

### 4. Functional Query Validated
Successfully queried QB for all sapling projects:
- 38 sapling-stage projects retrieved
- Full artifact data accessible (id, title, summary, tags, dates)
- Demonstrates end-to-end read capability

---

## Access Method

**Selected Option:** Option C (Proxy Queries)
- CC provides SQL queries
- Master Joel executes in Supabase SQL Editor
- Results shared back to CC
- Reason: psql not installed locally; proxy method works immediately

**Connection Details:**
- Database: Supabase hosted PostgreSQL
- Role: `cc_readonly`
- Permissions: SELECT only, RLS enforced
- Access Pattern: Query-on-demand via proxy

---

## Known-Good Declaration

CC has full, read-only visibility into Qwrk's live schema and data sufficient to:
verify, diagnose, validate, and gate builds using evidence rather than assumptions.

---

## What CC Can Now Do

### Evidence-Based Building ✅
- Verify LIVE_DDL matches actual deployed schema
- Validate workflow outputs (check if Save created records)
- Gate builds on actual data state (e.g., "no artifacts with status X")
- Diagnose issues by inspecting live data
- Generate accurate reports (artifact counts, status summaries)

### Schema Validation ✅
- Compare design specs to deployed schema
- Verify foreign key relationships exist
- Check constraints are enforced
- Validate column types and nullability

### Query Capabilities ✅
- Read all qxb_* tables
- Count artifacts by type, status, stage
- List projects, journals, restarts, snapshots, videos
- Inspect attachments, tags, workspaces, users
- Verify data integrity

---

## What CC Still Cannot Do (By Design)

### Write Operations ❌
- Cannot INSERT new records (must use Gateway workflows)
- Cannot UPDATE existing records (must use Gateway workflows)
- Cannot DELETE records (destructive operations prohibited)

### Schema Operations ❌
- Cannot CREATE/ALTER/DROP tables (DDL prohibited)
- Cannot CREATE/DROP triggers (admin operations prohibited)
- Cannot GRANT/REVOKE permissions (security operations prohibited)

### Workspace Isolation 🔒
- RLS policies still enforced
- Can only read data allowed by RLS
- Cannot bypass workspace boundaries

---

## Governance Alignment

This capability aligns with CC Governance Model:
- **"No receipt, no action"** - Can verify receipts in QB
- **Change control > autonomy** - Read-only enforces control
- **Evidence-based gating** - Can query actual state before building
- **Audit trail** - Can verify what was saved vs. what should exist

---

## Supporting Documentation

Created during access establishment:
- `docs/governance/QP1_Walkthrough__Grant_CC_ReadOnly_Supabase_Access.md`
  - Step-by-step guide for QP1 to walk Master Joel through setup
  - SQL for role creation, permission validation
  - Troubleshooting guide

---

## Security Posture

### Protections in Place ✅
1. **Read-only role** - No write/delete/DDL permissions
2. **RLS enforced** - Row Level Security still active
3. **No superuser** - Cannot escalate privileges
4. **Password secured** - Strong password, not in version control
5. **Audit logged** - All queries logged in Supabase (if enabled)

### Attack Surface
- **Risk:** Exposure of sensitive data via SELECT queries
- **Mitigation:** RLS policies filter rows, workspace isolation enforced
- **Risk:** Password compromise
- **Mitigation:** Rotate password periodically via `ALTER ROLE cc_readonly WITH PASSWORD`

---

## Validation Tests Passed

1. ✅ Role created successfully
2. ✅ Role is non-superuser
3. ✅ Role can login
4. ✅ SELECT permission granted
5. ✅ INSERT permission denied
6. ✅ UPDATE permission denied
7. ✅ DELETE permission denied
8. ✅ All 12 public schema objects visible
9. ✅ Column schemas readable
10. ✅ Constraints readable
11. ✅ Functional query returns data (38 saplings)

---

## Next Steps (Enabled by This Baseline)

### Immediate Capabilities
- Validate Gateway Internal Normalization plan against live schema
- Verify Video artifact table exists before implementing Video Worker
- Check existing artifact counts before migration workflows
- Diagnose workflow failures by inspecting QB state

### Future Enhancements (Optional)
- Install psql for direct query execution (eliminates proxy)
- Add connection string to .env for programmatic access
- Create saved query library for common diagnostics
- Set up query result caching for faster lookups

---

## Repository State

**No code changes** - This is operational access only.

**Documentation created:**
- `docs/governance/QP1_Walkthrough__Grant_CC_ReadOnly_Supabase_Access.md`
- This snapshot

**Database changes:**
- `cc_readonly` role exists in Supabase
- Permissions granted and validated

---

## Lessons Learned

1. **Proxy queries work immediately** - No need for psql installation
2. **Schema visibility proof essential** - Demonstrates access is real and complete
3. **Functional query validates end-to-end** - Not just permissions, but actual data flow
4. **Governance alignment critical** - Read-only enforces "no receipt, no action"

---

## Status: OPERATIONAL ✅

CC read-only QB access is now a Known-Good operational baseline.

All builds going forward can leverage evidence-based validation.

---
