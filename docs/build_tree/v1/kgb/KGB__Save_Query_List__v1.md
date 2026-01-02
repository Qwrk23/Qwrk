# KGB — Save Query List v1

**Known-Good Baseline tests for artifact.save workflow validation**

---

## Purpose

This document defines the Known-Good Baseline (KGB) tests for validating the `artifact.save` workflow in Gateway v1.1.

**Workflow Under Test**: `NQxb_Artifact_Save_v1`

**Validation Goal**: Ensure artifact.save correctly creates and updates artifacts across all supported types.

**Governance**: Journal artifacts are governed by **Doctrine: Journal INSERT-ONLY (Temporary)**. UPDATE operations on journal artifacts are blocked until Mutability Registry v2 is published. See [Doctrine_Journal_InsertOnly_Temporary.md](../../../governance/Doctrine_Journal_InsertOnly_Temporary.md).

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
| TC-02 | Update existing project artifact (mutable fields only) | 🟢 |
| TC-03 | Create snapshot artifact (immutable) | 🟢 |
| TC-04 | Validate type-specific schema enforcement | 🟢 |
| TC-05 | Verify response envelope structure | 🟢 |
| TC-06 | Test error handling (missing fields) | 🟢 |
| TC-07 | Test error handling (invalid artifact_type) | 🟢 |
| TC-08 | Test artifact.query integration | 🟢 |
| TC-09 | Test artifact.list integration | 🟢 |
| TC-10 | Validate RLS enforcement | 🟢 |
| TC-11 | Validate Journal INSERT-ONLY doctrine (UPDATE blocked) | 🟢 |
| TC-12 | Validate Project field mutability blocks (tags/summary/priority) | 🟢 |

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

**Note**: This test only updates `label` (decided-mutable field). Fields `summary`, `priority`, and `tags` are blocked from UPDATE per Mutability Gaps Decision Packet v1 (see TC-12 for validation).

**Request Envelope**:
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.save",
  "artifact_id": "<artifact-id-from-tc01>",
  "artifact_type": "project",
  "artifact_payload": {
    "label": "KGB Test Project TC-01 (Updated)"
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
    "summary": "Test project for KGB validation",
    "tags": ["kgb", "test", "tc-01"]
  }
}
```

**Validation**:
- ✅ artifact_id unchanged
- ✅ label updated
- ✅ summary preserved (not updated - field is blocked)
- ✅ tags preserved (not updated - field is blocked)
- ✅ updated_at is recent timestamp

**Database Verification**:
```sql
SELECT label, summary, tags, updated_at
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

### TC-11: Validate Journal INSERT-ONLY Doctrine (UPDATE Blocked)

**Purpose**: Verify artifact.update correctly blocks UPDATE operations on journal artifacts per Doctrine: Journal INSERT-ONLY (Temporary)

**Setup**:
- Create a journal artifact via artifact.create
- Attempt to update it via artifact.update

**Request 1** (create journal in workspace):
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.create",
  "artifact_type": "journal",
  "artifact_payload": {
    "artifact_slug": "test_journal_tc11",
    "label": "Journal TC-11",
    "entry_text": "Original journal entry for testing INSERT-ONLY doctrine."
  }
}
```

**Expected Response** (Request 1):
```json
{
  "ok": true,
  "_gw_route": "ok",
  "artifact": {
    "artifact_id": "<generated-uuid>",
    "artifact_type": "journal",
    "artifact_slug": "test_journal_tc11",
    "label": "Journal TC-11",
    "entry_text": "Original journal entry for testing INSERT-ONLY doctrine."
  }
}
```

**Request 2** (attempt UPDATE on journal):
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.update",
  "artifact_id": "<artifact-id-from-request-1>",
  "artifact_type": "journal",
  "artifact_payload": {
    "label": "Journal TC-11 (Updated)",
    "entry_text": "Attempting to update journal entry."
  }
}
```

**Expected Response** (Request 2 - BLOCKED):
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "JOURNAL_MUTABILITY_UNDECIDED",
    "message": "Journal update policy is not locked. Use artifact.create to append new entries.",
    "details": {
      "artifact_type": "journal",
      "artifact_id": "<artifact-id-from-request-1>",
      "operation_attempted": "UPDATE",
      "registry_rule": "UNDECIDED_BLOCKED",
      "source": "Mutability Registry v1",
      "doctrine": "Journal INSERT-ONLY (Temporary)",
      "hint": "Journal artifacts are append-only until mutability policy is locked. Create new journal entries instead."
    }
  }
}
```

**Validation**:
- ✅ Journal artifact created successfully via artifact.create
- ✅ UPDATE attempt blocked with `JOURNAL_MUTABILITY_UNDECIDED` error code
- ✅ Error message references Doctrine: Journal INSERT-ONLY (Temporary)
- ✅ Error details include registry_rule: "UNDECIDED_BLOCKED"
- ✅ Hint instructs user to use artifact.create for new entries
- ✅ Original journal artifact remains unchanged in database

**Database Verification**:
```sql
-- Verify journal artifact NOT updated
SELECT artifact_id, label, entry_text
FROM qxb_artifact_journal
WHERE artifact_id = '<artifact-id-from-request-1>';

-- Expected: label still "Journal TC-11" (not "Journal TC-11 (Updated)")
-- Expected: entry_text still "Original journal entry..." (not "Attempting to update...")
```

**Doctrine Reference**:
- See: [Doctrine_Journal_InsertOnly_Temporary.md](../../../governance/Doctrine_Journal_InsertOnly_Temporary.md)
- See: [Mutability_Registry_v1.md](../../../governance/Mutability_Registry_v1.md)

---

### TC-12: Validate Project Field Mutability Blocks (tags/summary/priority)

**Purpose**: Verify artifact.update correctly blocks UPDATE operations on project fields marked UNDECIDED_BLOCKED per Mutability Gaps Decision Packet v1

**Blocked Fields**:
- `tags` (UNDECIDED_BLOCKED)
- `summary` (UNDECIDED_BLOCKED)
- `priority` (UNDECIDED_BLOCKED)

**Setup**:
- Use existing project artifact from TC-01
- Attempt to update blocked fields via artifact.update

**Request** (attempt UPDATE on blocked fields):
```json
{
  "gw_user_id": "test-user-uuid",
  "gw_workspace_id": "test-workspace-uuid",
  "gw_action": "artifact.update",
  "artifact_id": "<artifact-id-from-tc01>",
  "artifact_type": "project",
  "artifact_payload": {
    "tags": ["updated", "tags"],
    "summary": "Attempting to update blocked summary field",
    "priority": 10
  }
}
```

**Expected Response** (BLOCKED):
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "FIELD_MUTABILITY_UNDECIDED",
    "message": "One or more fields are blocked from UPDATE per Mutability Gaps Decision Packet v1.",
    "details": {
      "artifact_type": "project",
      "artifact_id": "<artifact-id-from-tc01>",
      "operation_attempted": "UPDATE",
      "blocked_fields": ["tags", "summary", "priority"],
      "registry_status": "UNDECIDED_BLOCKED",
      "source": "Mutability Gaps Decision Packet v1",
      "hint": "These fields cannot be updated until Mutability Registry v2 publishes explicit policy. Use allowed fields only."
    }
  }
}
```

**Validation**:
- ✅ UPDATE attempt blocked with `FIELD_MUTABILITY_UNDECIDED` error code
- ✅ Error message references Mutability Gaps Decision Packet v1
- ✅ Error details list all blocked fields attempted
- ✅ Error details include registry_status: "UNDECIDED_BLOCKED"
- ✅ Hint instructs user to await Mutability Registry v2
- ✅ Original project artifact remains unchanged in database

**Database Verification**:
```sql
-- Verify project artifact NOT updated
SELECT tags, summary, priority
FROM qxb_artifact_project
WHERE artifact_id = '<artifact-id-from-tc01>';

-- Expected: tags still ["kgb", "test", "tc-01"] (not ["updated", "tags"])
-- Expected: summary still "Test project for KGB validation" (not "Attempting to update...")
-- Expected: priority still NULL (not 10)
```

**Governance Reference**:
- See: [Mutability_Gaps_Decision_Packet_v1.md](../../../governance/Mutability_Gaps_Decision_Packet_v1.md)
- See: [Mutability_Registry_v1.md](../../../governance/Mutability_Registry_v1.md)

---

## Acceptance Criteria

For the Build Tree TEST node to pass:

- ✅ All 12 test cases execute successfully
- ✅ All validation checkpoints pass
- ✅ No unexpected errors in workflow execution
- ✅ Database state is consistent after all tests
- ✅ Response envelopes match Gateway contract
- ✅ RLS enforcement verified
- ✅ Journal INSERT-ONLY doctrine enforced (TC-11)
- ✅ Project field mutability blocks enforced (TC-12)

---

## Test Execution Procedure

### Step 1: Prepare Test Environment

1. Create test workspace in Supabase
2. Create test user with workspace access
3. Note workspace_id and user_id UUIDs

### Step 2: Execute Test Cases in Order

Run TC-01 through TC-12 sequentially.

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
| TC-02 | PASS | Update applied correctly (mutable fields only) |
| TC-03 | PASS | Snapshot created |
| TC-04 | PASS | Schema validation working |
| TC-05 | PASS | Envelopes match contract |
| TC-06 | PASS | Missing field error correct |
| TC-07 | PASS | Invalid type rejected |
| TC-08 | PASS | Query integration working |
| TC-09 | PASS | List integration working |
| TC-10 | PASS | RLS enforced correctly |
| TC-11 | PASS | Journal UPDATE blocked (INSERT-ONLY doctrine) |
| TC-12 | PASS | Project blocked fields rejected (tags/summary/priority) |

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
**Total Test Cases**: 12
