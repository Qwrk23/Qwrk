# KGB — Save Query List v1

**Known-Good Baseline tests for artifact.save workflow validation**

---

## Purpose

This document defines the Known-Good Baseline (KGB) tests for validating the `artifact.save` workflow in Gateway v1.1.

**Workflow Under Test**: `NQxb_Artifact_Save_v1`

**Validation Goal**: Ensure artifact.save correctly creates and updates artifacts across all supported types.

---

## Test Environment

### Prerequisites

- Supabase project: `npymhacpmxdnkdgzxll`
- n8n instance with Gateway v1 workflows imported
- Test workspace created in Supabase
- Test user created with valid workspace access

### Test Data Requirements

- Valid `gw_user_id` (UUID)
- Valid `gw_workspace_id` (UUID)
- Clean database state (no conflicting artifacts)

---

## Test Suite Overview

| Test Case | Purpose | Status |
|-----------|---------|--------|
| TC-01 | Create new project artifact | 🟢 |
| TC-02 | Update existing project artifact | 🟢 |
| TC-03 | Create snapshot artifact (immutable) | 🟢 |
| TC-04 | Validate type-specific schema enforcement | 🟢 |
| TC-05 | Verify response envelope structure | 🟢 |
| TC-06 | Test error handling (missing fields) | 🟢 |
| TC-07 | Test error handling (invalid artifact_type) | 🟢 |
| TC-08 | Test artifact.query integration | 🟢 |
| TC-09 | Test artifact.list integration | 🟢 |
| TC-10 | Validate RLS enforcement | 🟢 |

---

## Test Cases

### TC-01: Create New Project Artifact

**Purpose**: Verify artifact.save creates a new project artifact when no artifact_id is provided

**Request Envelope**:
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.save",
  "artifact_type": "project",
  "artifact_payload": {
    "artifact_slug": "test_project_kgb_tc01",
    "label": "KGB Test Project TC-01",
    "lifecycle_stage": "active",
    "summary": "Test project for KGB validation",
    "tags": ["kgb", "test", "tc-01"]
  }
}
```

**Expected Response**:
```json
{
  "ok": true,
  "_gw_route": "ok",
  "artifact": {
    "artifact_id": "<generated-uuid>",
    "artifact_type": "project",
    "artifact_slug": "test_project_kgb_tc01",
    "label": "KGB Test Project TC-01",
    "lifecycle_status": "active",
    "workspace_id": "test-workspace-uuid",
    "created_by": "test-user-uuid",
    "lifecycle_stage": "active",
    "summary": "Test project for KGB validation",
    "tags": ["kgb", "test", "tc-01"]
  }
}
```

**Validation**:
- ✅ artifact_id is a valid UUID
- ✅ artifact_type = "project"
- ✅ lifecycle_status = "active" (aligned with lifecycle_stage)
- ✅ Spine fields populated correctly
- ✅ Extension fields populated correctly
- ✅ created_at is recent timestamp

**Database Verification**:
```sql
SELECT * FROM qxb_artifact WHERE artifact_slug = 'test_project_kgb_tc01';
SELECT * FROM qxb_artifact_project WHERE artifact_id = '<generated-uuid>';
```

---

### TC-02: Update Existing Project Artifact

**Purpose**: Verify artifact.save updates an existing project artifact when artifact_id is provided

**Request Envelope**:
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.save",
  "artifact_id": "<artifact-id-from-tc01>",
  "artifact_type": "project",
  "artifact_payload": {
    "label": "KGB Test Project TC-01 (Updated)",
    "summary": "Updated summary for KGB validation",
    "priority": 5
  }
}
```

**Expected Response**:
```json
{
  "ok": true,
  "_gw_route": "ok",
  "artifact": {
    "artifact_id": "<artifact-id-from-tc01>",
    "artifact_type": "project",
    "artifact_slug": "test_project_kgb_tc01",
    "label": "KGB Test Project TC-01 (Updated)",
    "lifecycle_status": "active",
    "workspace_id": "test-workspace-uuid",
    "lifecycle_stage": "active",
    "summary": "Updated summary for KGB validation",
    "priority": 5,
    "tags": ["kgb", "test", "tc-01"]
  }
}
```

**Validation**:
- ✅ artifact_id unchanged
- ✅ label updated
- ✅ summary updated
- ✅ priority updated
- ✅ tags preserved (not overwritten)
- ✅ updated_at is recent timestamp

**Database Verification**:
```sql
SELECT label, summary, priority, updated_at
FROM qxb_artifact_project
WHERE artifact_id = '<artifact-id-from-tc01>';
```

---

### TC-03: Create Snapshot Artifact (Immutable)

**Purpose**: Verify artifact.save creates a snapshot artifact correctly

**Request Envelope**:
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.save",
  "artifact_type": "snapshot",
  "artifact_payload": {
    "artifact_slug": "snapshot_kgb_tc03",
    "label": "KGB Test Snapshot TC-03",
    "parent_artifact_id": "<artifact-id-from-tc01>",
    "snapshot_reason": "lifecycle_transition",
    "snapshot_payload": {
      "label": "Original project label",
      "lifecycle_stage": "active",
      "summary": "Snapshot of project state"
    }
  }
}
```

**Expected Response**:
```json
{
  "ok": true,
  "_gw_route": "ok",
  "artifact": {
    "artifact_id": "<generated-uuid>",
    "artifact_type": "snapshot",
    "artifact_slug": "snapshot_kgb_tc03",
    "label": "KGB Test Snapshot TC-03",
    "parent_artifact_id": "<artifact-id-from-tc01>",
    "snapshot_reason": "lifecycle_transition",
    "snapshot_payload": {
      "label": "Original project label",
      "lifecycle_stage": "active",
      "summary": "Snapshot of project state"
    }
  }
}
```

**Validation**:
- ✅ Snapshot created successfully
- ✅ parent_artifact_id links to source project
- ✅ snapshot_payload preserved exactly
- ✅ Immutability flag set (if implemented)

**Database Verification**:
```sql
SELECT * FROM qxb_artifact WHERE artifact_slug = 'snapshot_kgb_tc03';
SELECT * FROM qxb_artifact_snapshot WHERE artifact_id = '<generated-uuid>';
```

---

### TC-04: Validate Type-Specific Schema Enforcement

**Purpose**: Verify artifact.save enforces type-specific schema rules

**Test 4a: Project Requires lifecycle_stage**

**Request** (missing lifecycle_stage):
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.save",
  "artifact_type": "project",
  "artifact_payload": {
    "artifact_slug": "test_project_missing_lifecycle",
    "label": "Missing Lifecycle"
  }
}
```

**Expected Response**:
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "lifecycle_stage is required for project artifacts",
    "details": {
      "missing_field": "lifecycle_stage"
    }
  }
}
```

**Test 4b: Snapshot Requires snapshot_payload**

**Request** (missing snapshot_payload):
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.save",
  "artifact_type": "snapshot",
  "artifact_payload": {
    "artifact_slug": "snapshot_missing_payload",
    "label": "Missing Payload"
  }
}
```

**Expected Response**:
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "snapshot_payload is required for snapshot artifacts",
    "details": {
      "missing_field": "snapshot_payload"
    }
  }
}
```

---

### TC-05: Verify Response Envelope Structure

**Purpose**: Ensure all successful responses match the Gateway contract

**Expected Structure** (success):
```json
{
  "ok": true,
  "_gw_route": "ok",
  "artifact": { /* hydrated artifact */ }
}
```

**Expected Structure** (error):
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "details": { /* additional context */ }
  }
}
```

**Validation**:
- ✅ All responses have `ok` field (boolean)
- ✅ All responses have `_gw_route` field ("ok" or "error")
- ✅ Success responses have `artifact` field
- ✅ Error responses have `error.code`, `error.message`
- ✅ No unexpected fields in envelope

---

### TC-06: Test Error Handling (Missing Required Fields)

**Purpose**: Verify artifact.save returns proper errors for missing fields

**Request** (missing artifact_type):
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.save",
  "artifact_payload": {
    "artifact_slug": "test_missing_type",
    "label": "Missing Type"
  }
}
```

**Expected Response**:
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "artifact_type is required",
    "details": {}
  }
}
```

**Validation**:
- ✅ Error code = "VALIDATION_ERROR"
- ✅ Message explains missing field
- ✅ No artifact created in database

---

### TC-07: Test Error Handling (Invalid artifact_type)

**Purpose**: Verify artifact.save rejects invalid artifact types

**Request**:
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.save",
  "artifact_type": "invalid_type",
  "artifact_payload": {
    "artifact_slug": "test_invalid_type",
    "label": "Invalid Type"
  }
}
```

**Expected Response**:
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid artifact_type: invalid_type. Allowed values: project, snapshot, restart, journal",
    "details": {
      "invalid_value": "invalid_type",
      "allowed_values": ["project", "snapshot", "restart", "journal"]
    }
  }
}
```

---

### TC-08: Test artifact.query Integration

**Purpose**: Verify artifact.query can retrieve artifacts created by artifact.save

**Setup**: Use artifact from TC-01

**Request**:
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.query",
  "artifact_id": "<artifact-id-from-tc01>",
  "artifact_type": "project"
}
```

**Expected Response**:
```json
{
  "ok": true,
  "artifact": {
    "artifact_id": "<artifact-id-from-tc01>",
    "artifact_type": "project",
    "artifact_slug": "test_project_kgb_tc01",
    "label": "KGB Test Project TC-01 (Updated)",
    /* ... all fields match TC-02 update ... */
  }
}
```

**Validation**:
- ✅ artifact.query returns same data as artifact.save
- ✅ All spine + extension fields present
- ✅ Hydrated response by default

---

### TC-09: Test artifact.list Integration

**Purpose**: Verify artifact.list can list artifacts created by artifact.save

**Request**:
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.list",
  "selector": {
    "artifact_type": "project",
    "limit": 50,
    "offset": 0
  }
}
```

**Expected Response**:
```json
{
  "ok": true,
  "_gw_route": "ok",
  "items": [
    {
      "artifact_id": "<artifact-id-from-tc01>",
      "artifact_type": "project",
      "artifact_slug": "test_project_kgb_tc01",
      "label": "KGB Test Project TC-01 (Updated)",
      /* ... base-only fields ... */
    }
  ],
  "meta": {
    "count": 1,
    "limit": 50,
    "offset": 0
  }
}
```

**Validation**:
- ✅ Artifact from TC-01 appears in list
- ✅ Base-only by default (fast lists)
- ✅ Correct meta.count

---

### TC-10: Validate RLS Enforcement

**Purpose**: Verify Row Level Security prevents cross-workspace access

**Setup**:
- Create artifact in workspace A
- Attempt to query artifact from workspace B

**Request 1** (create in workspace A):
```json
{
  "gw_user_id": "user-a-uuid",
  "gw_workspace_id": "workspace-a-uuid",
  "gw_action": "artifact.save",
  "artifact_type": "project",
  "artifact_payload": {
    "artifact_slug": "test_rls_workspace_a",
    "label": "RLS Test Workspace A",
    "lifecycle_stage": "active"
  }
}
```

**Request 2** (query from workspace B):
```json
{
  "gw_user_id": "user-b-uuid",
  "gw_workspace_id": "workspace-b-uuid",
  "gw_action": "artifact.query",
  "artifact_id": "<artifact-id-from-workspace-a>",
  "artifact_type": "project"
}
```

**Expected Response** (Request 2):
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "NOT_FOUND",
    "message": "Artifact not found or access denied",
    "details": {}
  }
}
```

**Validation**:
- ✅ Workspace B cannot access workspace A artifacts
- ✅ RLS policies enforced at database level
- ✅ Error message does not leak existence of artifact

---

## Acceptance Criteria

For the Build Tree TEST node to pass:

- ✅ All 10 test cases execute successfully
- ✅ All validation checkpoints pass
- ✅ No unexpected errors in workflow execution
- ✅ Database state is consistent after all tests
- ✅ Response envelopes match Gateway contract
- ✅ RLS enforcement verified

---

## Test Execution Procedure

### Step 1: Prepare Test Environment

1. Create test workspace in Supabase
2. Create test user with workspace access
3. Note workspace_id and user_id UUIDs

### Step 2: Execute Test Cases in Order

Run TC-01 through TC-10 sequentially.

For each test case:
1. Send request envelope to Gateway
2. Capture response envelope
3. Verify expected response structure
4. Verify database state (SQL queries)
5. Document results

### Step 3: Clean Up Test Data (Optional)

```sql
DELETE FROM qxb_artifact WHERE artifact_slug LIKE 'test_%' OR artifact_slug LIKE 'snapshot_kgb%';
```

### Step 4: Document Results

Create test run report:
- Date/time of execution
- n8n workflow version tested
- Test case results (PASS/FAIL)
- Any anomalies or deviations
- Overall KGB status (PASS/FAIL)

---

## Test Run Template

```markdown
## KGB Test Run — Save Query List v1

**Date**: YYYY-MM-DD
**Executor**: Master Joel
**Workflow**: NQxb_Artifact_Save_v1 (version X)
**Supabase Project**: npymhacpmxdnkdgzxll

### Results

| Test Case | Status | Notes |
|-----------|--------|-------|
| TC-01 | PASS | Artifact created successfully |
| TC-02 | PASS | Update applied correctly |
| TC-03 | PASS | Snapshot created |
| TC-04 | PASS | Schema validation working |
| TC-05 | PASS | Envelopes match contract |
| TC-06 | PASS | Missing field error correct |
| TC-07 | PASS | Invalid type rejected |
| TC-08 | PASS | Query integration working |
| TC-09 | PASS | List integration working |
| TC-10 | PASS | RLS enforced correctly |

### Overall Status

✅ **KGB PASS** — All test cases passed

### Anomalies

None.

### Recommendations

Workflow is production-ready.
```

---

## References

- [Build Tree Documentation](../tree/Build_Tree__Save_Query_List__v1.md)
- [How to Execute Leaves](../runbooks/Runbook__How_to_Execute_Leaves__v1.md)
- [Gateway README](../../../workflows/README.md)
- [Mutability Registry](../../../docs/governance/Mutability_Registry_v1.md)

---

**Version**: v1
**Status**: Active
**Last Updated**: 2026-01-02
**Total Test Cases**: 10
