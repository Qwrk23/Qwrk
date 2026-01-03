# NQxb_Artifact_Update_v1 Test Cases

**Workflow**: `NQxb_Artifact_Update_v1`
**Version**: 1
**Created**: 2026-01-02
**Purpose**: Comprehensive test cases for UPDATE-ONLY workflow with Mutability Registry v1 enforcement

---

## Test Case 1: Valid Project UPDATE (operational_state + state_reason)

**Description**: Update allowed project extension fields

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "valid-project-id-123",
  "extension": {
    "operational_state": "paused",
    "state_reason": "Waiting for external dependency"
  }
}
```

**Expected Outcome**: ✅ **SUCCESS**
- `ok: true`
- Returns full artifact via query workflow
- Extension fields updated in `qxb_artifact_project`

**Registry Rule Applied**: `UPDATE_ALLOWED` for `extension.operational_state` and `extension.state_reason`

---

## Test Case 2: Attempt Snapshot UPDATE

**Description**: Attempt to update immutable snapshot artifact

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "artifact_id": "snapshot-id-456",
  "extension": {
    "payload": {"new": "data"}
  }
}
```

**Expected Outcome**: ❌ **IMMUTABILITY_ERROR**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "IMMUTABILITY_ERROR",
    "message": "Artifact type 'snapshot' is immutable and cannot be updated. Only INSERT operations are allowed.",
    "details": {
      "artifact_type": "snapshot",
      "artifact_id": "snapshot-id-456",
      "operation_attempted": "UPDATE",
      "registry_rule": "CREATE_ONLY",
      "source": "Mutability Registry v1"
    }
  }
}
```

**Registry Rule Applied**: `CREATE_ONLY` for snapshot artifacts

---

## Test Case 3: Attempt Restart UPDATE

**Description**: Attempt to update immutable restart artifact

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "restart",
  "artifact_id": "restart-id-789",
  "extension": {
    "payload": {"session": "data"}
  }
}
```

**Expected Outcome**: ❌ **IMMUTABILITY_ERROR**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "IMMUTABILITY_ERROR",
    "message": "Artifact type 'restart' is immutable and cannot be updated. Only INSERT operations are allowed.",
    "details": {
      "artifact_type": "restart",
      "artifact_id": "restart-id-789",
      "operation_attempted": "UPDATE",
      "registry_rule": "CREATE_ONLY",
      "source": "Mutability Registry v1"
    }
  }
}
```

**Registry Rule Applied**: `CREATE_ONLY` for restart artifacts

---

## Test Case 4: Attempt Journal UPDATE

**Description**: Attempt to update journal artifact (policy undecided)

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "artifact_id": "journal-id-abc",
  "extension": {
    "entry_text": "Updated entry"
  }
}
```

**Expected Outcome**: ❌ **UNDECIDED_BLOCKED_ERROR**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "UNDECIDED_BLOCKED_ERROR",
    "message": "Journal artifact mutability policy is not yet locked. UPDATE operations are blocked.",
    "details": {
      "artifact_type": "journal",
      "artifact_id": "journal-id-abc",
      "operation_attempted": "UPDATE",
      "registry_rule": "UNDECIDED_BLOCKED",
      "source": "Mutability Registry v1",
      "hint": "Journal mutability decision deferred in Phase 2. Use READ-only operations until policy is locked."
    }
  }
}
```

**Registry Rule Applied**: `UNDECIDED_BLOCKED` for journal artifacts

---

## Test Case 5: Attempt Project lifecycle_stage UPDATE

**Description**: Attempt to update PROMOTE_ONLY field lifecycle_stage

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "project-id-def",
  "extension": {
    "lifecycle_stage": "tree"
  }
}
```

**Expected Outcome**: ❌ **MUTABILITY_ERROR**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "MUTABILITY_ERROR",
    "message": "Field 'lifecycle_stage' is PROMOTE_ONLY and cannot be updated via artifact.update.",
    "details": {
      "field": "extension.lifecycle_stage",
      "artifact_type": "project",
      "artifact_id": "project-id-def",
      "registry_rule": "PROMOTE_ONLY",
      "source": "Mutability Registry v1",
      "hint": "Use artifact.promote operation to change lifecycle_stage."
    }
  }
}
```

**Registry Rule Applied**: `PROMOTE_ONLY` for `extension.lifecycle_stage`

---

## Test Case 6: UPDATE Non-Existent Artifact

**Description**: Attempt to update artifact that doesn't exist or workspace_id mismatch

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "non-existent-id-999",
  "extension": {
    "operational_state": "active"
  }
}
```

**Expected Outcome**: ❌ **NOT_FOUND**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "NOT_FOUND",
    "message": "Artifact not found for UPDATE operation",
    "details": {
      "artifact_id": "non-existent-id-999",
      "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
      "operation": "UPDATE"
    }
  }
}
```

**Registry Rule Applied**: Workspace scoping + artifact existence check

---

## Test Case 7: Missing artifact_id (UPDATE_ONLY Enforcement)

**Description**: Request without artifact_id (CREATE vs UPDATE separation)

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "extension": {
    "operational_state": "active"
  }
}
```

**Expected Outcome**: ❌ **UPDATE_ONLY**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "UPDATE_ONLY",
    "message": "artifact.update is update-only. Use artifact.create for new artifacts.",
    "details": {
      "hint": "artifact_id field is required for UPDATE operations."
    }
  }
}
```

**Registry Rule Applied**: UPDATE_ONLY workflow constraint

---

## Test Case 8: Attempt deleted_at UPDATE

**Description**: Attempt to update UNDECIDED_BLOCKED field deleted_at

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "project-id-ghi",
  "deleted_at": "2026-01-02T10:00:00Z",
  "extension": {
    "operational_state": "active"
  }
}
```

**Expected Outcome**: ❌ **MUTABILITY_ERROR**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "MUTABILITY_ERROR",
    "message": "Field 'deleted_at' is UNDECIDED_BLOCKED and cannot be updated.",
    "details": {
      "field": "deleted_at",
      "artifact_type": "project",
      "artifact_id": "project-id-ghi",
      "registry_rule": "UNDECIDED_BLOCKED",
      "source": "Mutability Registry v1",
      "hint": "Soft delete semantics not yet locked. Use dedicated artifact.delete action when implemented."
    }
  }
}
```

**Registry Rule Applied**: `UNDECIDED_BLOCKED` for `deleted_at`

---

## Test Case 9: Valid Project UPDATE (operational_state Only)

**Description**: Update only operational_state (partial PATCH)

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "project-id-jkl",
  "extension": {
    "operational_state": "archived"
  }
}
```

**Expected Outcome**: ✅ **SUCCESS**
- `ok: true`
- Returns full artifact via query workflow
- Only `operational_state` updated, `state_reason` unchanged

**Registry Rule Applied**: `UPDATE_ALLOWED` for `extension.operational_state`

---

## Test Case 10: Valid Project UPDATE (state_reason Only)

**Description**: Update only state_reason (partial PATCH)

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "project-id-mno",
  "extension": {
    "state_reason": "Archived after completion"
  }
}
```

**Expected Outcome**: ✅ **SUCCESS**
- `ok: true`
- Returns full artifact via query workflow
- Only `state_reason` updated, `operational_state` unchanged

**Registry Rule Applied**: `UPDATE_ALLOWED` for `extension.state_reason`

---

## Test Case 11: Project UPDATE with No Extension Fields

**Description**: Request with empty extension object (no fields to update)

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "project-id-pqr",
  "extension": {}
}
```

**Expected Outcome**: ❌ **VALIDATION_ERROR**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "No updateable fields provided in extension for project UPDATE.",
    "details": {
      "artifact_type": "project",
      "artifact_id": "project-id-pqr",
      "allowed_fields": ["operational_state", "state_reason"],
      "hint": "Provide at least one of: operational_state, state_reason"
    }
  }
}
```

**Registry Rule Applied**: UPDATE validation (must provide at least one field)

---

## Test Case 12: Attempt Disallowed Extension Field

**Description**: Attempt to update non-allowed extension field for project

**Request**:
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "project-id-stu",
  "extension": {
    "operational_state": "active",
    "custom_field": "not allowed"
  }
}
```

**Expected Outcome**: ❌ **MUTABILITY_ERROR**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "MUTABILITY_ERROR",
    "message": "Disallowed fields in extension for project UPDATE: custom_field",
    "details": {
      "disallowed_fields": ["custom_field"],
      "allowed_fields": ["operational_state", "state_reason"],
      "artifact_type": "project",
      "artifact_id": "project-id-stu",
      "source": "Mutability Registry v1",
      "hint": "Only operational_state and state_reason are UPDATE_ALLOWED for project artifacts."
    }
  }
}
```

**Registry Rule Applied**: Strict field allowlist enforcement

---

## Summary

| Test # | Scenario | Expected Result | Error Code |
|--------|----------|-----------------|------------|
| 1 | Valid project UPDATE (both fields) | ✅ Success | - |
| 2 | Snapshot UPDATE | ❌ Error | `IMMUTABILITY_ERROR` |
| 3 | Restart UPDATE | ❌ Error | `IMMUTABILITY_ERROR` |
| 4 | Journal UPDATE | ❌ Error | `UNDECIDED_BLOCKED_ERROR` |
| 5 | Project lifecycle_stage UPDATE | ❌ Error | `MUTABILITY_ERROR` |
| 6 | Non-existent artifact UPDATE | ❌ Error | `NOT_FOUND` |
| 7 | Missing artifact_id | ❌ Error | `UPDATE_ONLY` |
| 8 | deleted_at UPDATE | ❌ Error | `MUTABILITY_ERROR` |
| 9 | Valid project UPDATE (operational_state only) | ✅ Success | - |
| 10 | Valid project UPDATE (state_reason only) | ✅ Success | - |
| 11 | Project UPDATE with empty extension | ❌ Error | `VALIDATION_ERROR` |
| 12 | Disallowed extension field | ❌ Error | `MUTABILITY_ERROR` |

**Total Test Cases**: 12
**Success Cases**: 3
**Error Cases**: 9

---

## Error Envelope Codes Reference

All error envelopes follow the same structure:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable description",
    "details": {
      // Context-specific fields
    }
  }
}
```

### Error Codes Used

1. **UPDATE_ONLY**: artifact_id is required for UPDATE operations
2. **VALIDATION_ERROR**: Missing required fields or invalid field values
3. **NOT_FOUND**: Artifact doesn't exist or workspace_id mismatch
4. **IMMUTABILITY_ERROR**: Attempting to update immutable artifact type (snapshot, restart)
5. **UNDECIDED_BLOCKED_ERROR**: Attempting to update artifact with undecided mutability policy (journal)
6. **MUTABILITY_ERROR**: Attempting to update blocked field (lifecycle_stage, deleted_at, disallowed fields)

---

## Mutability Registry v1 Rules Enforced

| Artifact Type | Field Path | Operation | Enforcement |
|--------------|------------|-----------|-------------|
| snapshot | (all fields) | CREATE_ONLY | ✅ Blocked with IMMUTABILITY_ERROR |
| restart | (all fields) | CREATE_ONLY | ✅ Blocked with IMMUTABILITY_ERROR |
| journal | (all fields) | UNDECIDED_BLOCKED | ✅ Blocked with UNDECIDED_BLOCKED_ERROR |
| project | extension.lifecycle_stage | PROMOTE_ONLY | ✅ Blocked with MUTABILITY_ERROR |
| project | extension.operational_state | UPDATE_ALLOWED | ✅ Allowed |
| project | extension.state_reason | UPDATE_ALLOWED | ✅ Allowed |
| (all types) | deleted_at | UNDECIDED_BLOCKED | ✅ Blocked with MUTABILITY_ERROR |
| (all types) | artifact_id, workspace_id, etc. | SYSTEM_ONLY | ✅ Not exposed for UPDATE |

---

## Testing Checklist

Before deploying `NQxb_Artifact_Update_v1`, verify:

- [ ] **Test 1**: Valid project UPDATE (both fields) returns success
- [ ] **Test 2**: Snapshot UPDATE returns IMMUTABILITY_ERROR
- [ ] **Test 3**: Restart UPDATE returns IMMUTABILITY_ERROR
- [ ] **Test 4**: Journal UPDATE returns UNDECIDED_BLOCKED_ERROR
- [ ] **Test 5**: Project lifecycle_stage UPDATE returns MUTABILITY_ERROR
- [ ] **Test 6**: Non-existent artifact UPDATE returns NOT_FOUND
- [ ] **Test 7**: Missing artifact_id returns UPDATE_ONLY error
- [ ] **Test 8**: deleted_at UPDATE returns MUTABILITY_ERROR
- [ ] **Test 9**: Valid project UPDATE (operational_state only) returns success
- [ ] **Test 10**: Valid project UPDATE (state_reason only) returns success
- [ ] **Test 11**: Project UPDATE with empty extension returns VALIDATION_ERROR
- [ ] **Test 12**: Disallowed extension field returns MUTABILITY_ERROR
- [ ] **Integration**: Final query call returns complete merged artifact
- [ ] **Workspace Scoping**: Workspace_id mismatch returns NOT_FOUND

---

## Related Documents

- **Mutability_Registry_v1.md** - Binding mutation rules reference
- **NQxb_Artifact_Save_v1__README.md** (v1.2) - Full Save workflow documentation
- **NQxb_Artifact_Create_v1__CHANGELOG.md** - CREATE-ONLY workflow documentation
- **CLAUDE.md** - Governance rules for workflow changes

---

**End of Test Cases**
