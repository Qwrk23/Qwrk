# KGB Proof: QPM Lifecycle Semantics — Phase 2

**Date:** 2026-02-01
**Author:** CC (Claude Code)
**Status:** PENDING VERIFICATION
**Participants:** Master Joel, QP1, CC

---

## Summary

This document provides KGB (Known-Good Baseline) proof for the QPM Lifecycle Semantics Phase 2 implementation in `artifact.promote` workflow.

## Changes Implemented

### Schema & Registry (Step 0)

**Migration file:** `migrations/2026-02-01__QPM_Lifecycle_Semantics__Step0__Schema_Registry.sql`

| Change | Description |
|--------|-------------|
| Constraint v2 → v3 | Added `instruction_pack`, `branch`, `limb`, `leaf` to artifact_type CHECK |
| Registry entries | Added `branch`, `limb`, `leaf`, `thorn`, `grass` to `qxb_artifact_type_registry` |

**New artifact types (execution layer):**
- `branch` — Strategic or functional domain within a project
- `limb` — Workstream or phase within a branch (optional layer)
- `leaf` — Single executable action (terminal)

### Gateway Workflow (Step 1)

**Workflow file:** `workflows/NQxb_Artifact_Promote_v1 (17).json`

| Change | Description |
|--------|-------------|
| `retired_to_tree` REMOVED | Retired is now terminal (irreversible) |
| QPM validation nodes ADDED | Child query + validation before DB update |

**New error codes:**
| Code | HTTP | Condition |
|------|------|-----------|
| `PROMOTION_BLOCKED_SEED_NOT_READY` | 400 | Seed lacks summary AND no journal children |
| `PROMOTION_BLOCKED_NO_ANATOMY` | 400 | Sapling has no execution-type children |

---

## QPM Rules Enforced

### Seed → Sapling

**Requirement:** `summary` present (non-empty, trimmed) **OR** linked journal child

**Validation query:**
```sql
SELECT COUNT(*)::int as journal_count
FROM qxb_artifact
WHERE parent_artifact_id = $artifact_id
  AND workspace_id = $workspace_id
  AND artifact_type = 'journal'
  AND deleted_at IS NULL
```

**Pass if:** `summary.trim().length > 0` OR `journal_count > 0`

### Sapling → Tree

**Requirement:** Execution anatomy exists (branch, limb, or leaf child)

**Validation query:**
```sql
SELECT COUNT(*)::int as execution_count
FROM qxb_artifact
WHERE parent_artifact_id = $artifact_id
  AND workspace_id = $workspace_id
  AND artifact_type IN ('branch', 'limb', 'leaf')
  AND deleted_at IS NULL
```

**Pass if:** `execution_count > 0`

### Tree → Retired

**Requirement:** None (always pass)

**Notes:** Retired is terminal. No backward transitions allowed.

---

## Verification Test Matrix

### Pre-Verification Checklist

- [ ] Step 0 SQL executed successfully on Supabase
- [ ] All 13 artifact types in registry (query: `SELECT artifact_type FROM qxb_artifact_type_registry ORDER BY artifact_type`)
- [ ] Workflow v17 imported to n8n

### Seed → Sapling Tests

| Test | Input | Expected | Status |
|------|-------|----------|--------|
| S2S-001 | Seed with no summary, no journal child | `PROMOTION_BLOCKED_SEED_NOT_READY` | PENDING |
| S2S-002 | Seed with summary (non-empty) | Promotes to sapling | PENDING |
| S2S-003 | Seed with linked journal child (no summary) | Promotes to sapling | PENDING |
| S2S-004 | Seed with snapshot child only | `PROMOTION_BLOCKED_SEED_NOT_READY` | PENDING |

### Sapling → Tree Tests

| Test | Input | Expected | Status |
|------|-------|----------|--------|
| SAP2T-001 | Sapling with no children | `PROMOTION_BLOCKED_NO_ANATOMY` | PENDING |
| SAP2T-002 | Sapling with journal child only | `PROMOTION_BLOCKED_NO_ANATOMY` | PENDING |
| SAP2T-003 | Sapling with branch child | Promotes to tree | PENDING |
| SAP2T-004 | Sapling with limb child | Promotes to tree | PENDING |
| SAP2T-005 | Sapling with leaf child | Promotes to tree | PENDING |

### Tree → Retired Tests

| Test | Input | Expected | Status |
|------|-------|----------|--------|
| T2R-001 | Tree → retired | Promotes to retired | PENDING |

### Retired Terminal Tests

| Test | Input | Expected | Status |
|------|-------|----------|--------|
| RET-001 | Retired → tree | `LIFECYCLE_TRANSITION_NOT_ALLOWED` | PENDING |
| RET-002 | Retired → sapling | `LIFECYCLE_TRANSITION_NOT_ALLOWED` | PENDING |
| RET-003 | Retired → seed | `LIFECYCLE_TRANSITION_NOT_ALLOWED` | PENDING |

### Backward Transition Tests (Existing)

| Test | Input | Expected | Status |
|------|-------|----------|--------|
| BWD-001 | Sapling → seed | `LIFECYCLE_TRANSITION_NOT_ALLOWED` | PENDING |
| BWD-002 | Tree → sapling | `LIFECYCLE_TRANSITION_NOT_ALLOWED` | PENDING |

---

## Workflow Node Topology

**After QPM Phase 2:**

```
In → Normalize → Pass_Actor → Lookup_Type_Registry → Type_Registry_Guard
  → Switch_Type_Registry
    → [ok] Resolve_Transition → Verify_Current_State + Merge → Enforce_Verified_State
      → Switch_OK
        → [ok] QPM_Prepare + QPM_Query_Journal + QPM_Query_Execution
          → QPM_Merge → QPM_Validate → QPM_Switch
            → [ok] DB_Update_Lifecycle + Freeze_Event → Merge_Verify → DB_Insert_Event
              → Shape_Response → Build_Query → Call_Query
            → [error] Return_Error_Item
        → [error] Return_Error_Item
    → [error] Return_Error_Item
```

**New nodes added:**
- `NQxb_Artifact_Promote_v1__QPM_Prepare_Child_Queries` — Prep context for queries
- `NQxb_Artifact_Promote_v1__QPM_Query_Journal_Children` — Count journal children
- `NQxb_Artifact_Promote_v1__QPM_Query_Execution_Children` — Count branch/limb/leaf children
- `NQxb_Artifact_Promote_v1__QPM_Merge_Child_Counts` — Merge query results
- `NQxb_Artifact_Promote_v1__QPM_Validate_Rules` — Enforce QPM rules
- `NQxb_Artifact_Promote_v1__QPM_Switch` — Route ok/error after validation

---

## Files Modified

| File | Change |
|------|--------|
| `migrations/2026-02-01__QPM_Lifecycle_Semantics__Step0__Schema_Registry.sql` | NEW: Schema & registry migration |
| `workflows/NQxb_Artifact_Promote_v1 (17).json` | NEW: Workflow with QPM validation |
| `docs/kgb/2026-02-01__KGB_Proof__QPM_Lifecycle_Semantics__Phase2.md` | NEW: This document |

---

## Governance Compliance

| Rule | Status |
|------|--------|
| DDL-as-Truth checked | Yes (constraint verified against LIVE_DDL) |
| Archive-based versioning | Workflow v16 preserved; v17 is new |
| No-Guessing rule | All types from plan; no invented schemas |
| Changelog requirement | Migration file has CHANGELOG section |

---

## Rollback Instructions

### Workflow Rollback

1. Re-import `workflows/NQxb_Artifact_Promote_v1 (16).json` to n8n
2. Set workflow v16 as active

### Schema Rollback

Execute rollback section in migration SQL file:
```sql
-- See migrations/2026-02-01__QPM_Lifecycle_Semantics__Step0__Schema_Registry.sql
-- ROLLBACK section at bottom of file
```

---

## Sign-off

**Awaiting verification by:** Master Joel

**Post-verification steps:**
1. Update test matrix with PASS/FAIL results
2. Update status from PENDING VERIFICATION to VERIFIED
3. Archive this document if superseded

---

## CHANGELOG

### v1 — 2026-02-01
- Initial KGB proof document for QPM Lifecycle Semantics Phase 2
- Documents schema changes, workflow changes, and verification matrix
