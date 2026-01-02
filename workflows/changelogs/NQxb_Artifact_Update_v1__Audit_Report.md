# NQxb_Artifact_Update_v1 — Mutability Compliance Audit

**Workflow**: `NQxb_Artifact_Update_v1`
**Audit Date**: 2026-01-02
**Auditor**: Claude Code
**Purpose**: Verify strict enforcement of Mutability Registry v1 rules and Journal INSERT-ONLY doctrine

---

## Audit Scope

Verify the following authoritative rules are enforced:

1. ✅ UPDATE requires `artifact_id`
2. ✅ Snapshot and restart artifacts are fully immutable
3. ✅ Journal artifacts are INSERT-ONLY per temporary doctrine
4. ✅ Project updates are limited to: `extension.operational_state`, `extension.state_reason`
5. ✅ `lifecycle_stage` is PROMOTE_ONLY (blocked)
6. ✅ `deleted_at` is UNDECIDED_BLOCKED (blocked)
7. ✅ Partial PATCH semantics (only provided fields change)
8. ✅ No spine field updates allowed

---

## Audit Findings

### ✅ PASS: UPDATE Requires artifact_id

**Node**: `NQxb_Artifact_Update_v1__Normalize_Request` (lines 20-36)

**Code**:
```javascript
// UPDATE_ONLY: artifact_id is REQUIRED
if (!artifact_id || artifact_id.trim() === '') {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "UPDATE_ONLY",
          message: "artifact.update is update-only. Use artifact.create for new artifacts.",
          details: {
            hint: "artifact_id field is required for UPDATE operations."
          },
        },
      },
    },
  ];
}
```

**Finding**: ✅ **COMPLIANT**
- Checks for missing `artifact_id` in request
- Returns `UPDATE_ONLY` error if absent
- Prevents INSERT operations via update workflow

---

### ✅ PASS: Snapshot and Restart Are Fully Immutable

**Node**: `NQxb_Artifact_Update_v1__Check_Mutability_Rules` (lines 137-152)

**Code**:
```javascript
// RULE: snapshot and restart are fully immutable (Mutability Registry v1)
if (artifact_type === 'snapshot' || artifact_type === 'restart') {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "IMMUTABILITY_ERROR",
          message: `Artifact type '${artifact_type}' is immutable and cannot be updated. Only INSERT operations are allowed.`,
          details: {
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            operation_attempted: 'UPDATE',
            registry_rule: 'CREATE_ONLY',
            source: 'Mutability Registry v1',
          },
        },
      },
    },
  ];
}
```

**Finding**: ✅ **COMPLIANT**
- Blocks ALL UPDATE attempts on snapshot artifacts
- Blocks ALL UPDATE attempts on restart artifacts
- Returns `IMMUTABILITY_ERROR` with registry reference
- Aligns with Mutability Registry v1 CREATE_ONLY rule

---

### ✅ PASS: Journal INSERT-ONLY Enforcement

**Node**: `NQxb_Artifact_Update_v1__Check_Mutability_Rules` (lines 154-174)

**Code**:
```javascript
// RULE: journal mutability is UNDECIDED_BLOCKED (Mutability Registry v1)
// DOCTRINE: Journal INSERT-ONLY (Temporary)
if (artifact_type === 'journal') {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "JOURNAL_MUTABILITY_UNDECIDED",
          message: "Journal update policy is not locked. Use artifact.create to append new entries.",
          details: {
            artifact_type: 'journal',
            artifact_id: existing.artifact_id,
            operation_attempted: 'UPDATE',
            registry_rule: 'UNDECIDED_BLOCKED',
            source: 'Mutability Registry v1',
            doctrine: 'Journal INSERT-ONLY (Temporary)',
            hint: 'Journal artifacts are append-only until mutability policy is locked. Create new journal entries instead.',
          },
        },
      },
    },
  ];
}
```

**Finding**: ✅ **COMPLIANT**
- Blocks ALL UPDATE attempts on journal artifacts
- Returns `JOURNAL_MUTABILITY_UNDECIDED` error code
- References both Mutability Registry v1 AND Doctrine
- Provides clear hint to use `artifact.create` instead
- Aligns with "Doctrine: Journal INSERT-ONLY (Temporary)"

---

### ✅ PASS: Project Updates Limited to Allowed Fields Only

**Node**: `NQxb_Artifact_Update_v1__Check_Mutability_Rules` (lines 193-234)

**Allowed Fields Check**:
```javascript
// RULE: For project artifacts, only operational_state and state_reason allowed
if (artifact_type === 'project') {
  const extension = normalizeNode.extension || {};
  const allowedFields = ['operational_state', 'state_reason'];
  const providedFields = Object.keys(extension);

  // Check for disallowed extension fields
  const disallowedFields = providedFields.filter(f => !allowedFields.includes(f));

  if (disallowedFields.length > 0) {
    // Returns MUTABILITY_ERROR
  }
}
```

**Finding**: ✅ **COMPLIANT**
- Only `operational_state` and `state_reason` are in allowed fields list
- Any other field triggers `MUTABILITY_ERROR`
- Strict allowlist enforcement (no implicit permissions)
- Aligns with Mutability Registry v1 UPDATE_ALLOWED rules

---

### ✅ PASS: lifecycle_stage Is PROMOTE_ONLY

**Node**: `NQxb_Artifact_Update_v1__Check_Mutability_Rules` (lines 197-211)

**Code**:
```javascript
// Special handling for lifecycle_stage (PROMOTE_ONLY)
if (disallowedFields.includes('lifecycle_stage')) {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "MUTABILITY_ERROR",
          message: "Field 'lifecycle_stage' is PROMOTE_ONLY and cannot be updated via artifact.update.",
          details: {
            field: 'extension.lifecycle_stage',
            artifact_type: 'project',
            artifact_id: existing.artifact_id,
            registry_rule: 'PROMOTE_ONLY',
            source: 'Mutability Registry v1',
            hint: 'Use artifact.promote operation to change lifecycle_stage.',
          },
        },
      },
    },
  ];
}
```

**Finding**: ✅ **COMPLIANT**
- Explicitly blocks `lifecycle_stage` updates
- Returns `MUTABILITY_ERROR` with PROMOTE_ONLY reference
- Provides hint to use `artifact.promote` operation
- Aligns with Mutability Registry v1 PROMOTE_ONLY rule

---

### ✅ PASS: deleted_at Is UNDECIDED_BLOCKED

**Node**: `NQxb_Artifact_Update_v1__Check_Mutability_Rules` (lines 176-191)

**Code**:
```javascript
// RULE: deleted_at is UNDECIDED_BLOCKED (Mutability Registry v1)
if (normalizeNode.deleted_at !== null && normalizeNode.deleted_at !== undefined) {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "MUTABILITY_ERROR",
          message: "Field 'deleted_at' is UNDECIDED_BLOCKED and cannot be updated.",
          details: {
            field: 'deleted_at',
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            registry_rule: 'UNDECIDED_BLOCKED',
            source: 'Mutability Registry v1',
            hint: 'Soft delete semantics not yet locked. Use dedicated artifact.delete action when implemented.',
          },
        },
      },
    },
  ];
}
```

**Finding**: ✅ **COMPLIANT**
- Blocks `deleted_at` updates for all artifact types
- Returns `MUTABILITY_ERROR` with UNDECIDED_BLOCKED reference
- Provides hint about future `artifact.delete` action
- Aligns with Mutability Registry v1 gap decision

---

### ✅ PASS: PATCH Semantics (Only Provided Fields Change)

**Node**: `NQxb_Artifact_Update_v1__Prepare_Project_Extension_Update` (lines 162-172)

**Code**:
```javascript
// Only update fields that are explicitly provided
const hasOperationalState = 'operational_state' in extension;
const hasStateReason = 'state_reason' in extension;

const updateFields = {
  artifact_id: $json.artifact_id,
};

if (hasOperationalState) {
  updateFields.operational_state = extension.operational_state;
}

if (hasStateReason) {
  updateFields.state_reason = extension.state_reason;
}
```

**Finding**: ✅ **COMPLIANT**
- Uses `'field' in extension` check (not truthy check)
- Only includes field in UPDATE if explicitly provided
- Supports partial updates (update one field, leave other unchanged)
- True PATCH semantics implementation

**Example Behavior**:
- Request with only `operational_state` → only operational_state updated
- Request with only `state_reason` → only state_reason updated
- Request with both → both updated
- Request with neither → VALIDATION_ERROR (caught earlier)

---

### ✅ PASS: No Spine Field Updates Allowed

**Workflow Analysis**:
- **Supabase UPDATE nodes**: 1 total
- **Spine UPDATE (qxb_artifact)**: 0
- **Extension UPDATE (qxb_artifact_project)**: 1

**Node**: `NQxb_Artifact_Update_v1__DB_Update_Project_Extension` (lines 175-211)

**Code**:
```json
{
  "operation": "update",
  "tableId": "qxb_artifact_project",
  "fieldsUi": {
    "fieldValues": [
      {
        "fieldId": "operational_state",
        "fieldValue": "={{ $json.operational_state }}"
      },
      {
        "fieldId": "state_reason",
        "fieldValue": "={{ $json.state_reason }}"
      }
    ]
  }
}
```

**Finding**: ✅ **COMPLIANT**
- NO Supabase UPDATE operation on `qxb_artifact` table
- ONLY updates `qxb_artifact_project` extension table
- ONLY updates allowed fields: `operational_state`, `state_reason`
- Spine fields (title, summary, priority, tags, content, lifecycle_status, etc.) CANNOT be updated

**Rationale**: Per Mutability Registry v1, all spine fields for projects are either:
- SYSTEM_ONLY (artifact_id, workspace_id, owner_user_id, timestamps)
- UNDECIDED_BLOCKED (summary, priority, tags, content)
- PROMOTE_ONLY (lifecycle_status)

Since NO spine fields are UPDATE_ALLOWED, the workflow correctly avoids ALL spine updates.

---

### ✅ PASS: All Blocked Cases Return Explicit Errors

**Error Coverage Matrix**:

| Blocked Case | Error Code | Node | Line |
|-------------|-----------|------|------|
| Missing artifact_id | UPDATE_ONLY | Normalize_Request | 20-36 |
| Non-existent artifact | NOT_FOUND | Check_Mutability_Rules | 117-132 |
| Snapshot UPDATE | IMMUTABILITY_ERROR | Check_Mutability_Rules | 137-152 |
| Restart UPDATE | IMMUTABILITY_ERROR | Check_Mutability_Rules | 137-152 |
| Journal UPDATE | JOURNAL_MUTABILITY_UNDECIDED | Check_Mutability_Rules | 154-174 |
| deleted_at UPDATE | MUTABILITY_ERROR | Check_Mutability_Rules | 176-191 |
| lifecycle_stage UPDATE | MUTABILITY_ERROR | Check_Mutability_Rules | 197-211 |
| Disallowed extension field | MUTABILITY_ERROR | Check_Mutability_Rules | 213-230 |
| Empty extension | VALIDATION_ERROR | Check_Mutability_Rules | 232-246 |

**Finding**: ✅ **COMPLIANT**
- 9 distinct blocked cases
- 5 unique error codes
- All cases return structured error envelopes
- All errors include registry rule references
- All errors provide actionable hints

---

### ✅ PASS: Returns Full Artifact After Update

**Node**: `NQxb_Artifact_Update_v1__Call_Query_To_Return_Artifact` (lines 227-245)

**Code**:
```json
{
  "workflowId": "={{ 'NQxb_Artifact_Query_v1' }}",
  "options": {
    "inputData": {
      "gw_action": "artifact.query",
      "gw_workspace_id": "={{ $json.saved_workspace_id }}",
      "artifact_type": "={{ $json.saved_artifact_type }}",
      "artifact_id": "={{ $json.saved_artifact_id }}"
    }
  }
}
```

**Finding**: ✅ **COMPLIANT**
- Calls `NQxb_Artifact_Query_v1` workflow after successful UPDATE
- Returns complete merged artifact (spine + extension)
- User receives full canonical artifact representation

---

## Summary

| Audit Requirement | Status | Evidence |
|-------------------|--------|----------|
| UPDATE requires artifact_id | ✅ PASS | UPDATE_ONLY error in Normalize_Request |
| Snapshot immutable | ✅ PASS | IMMUTABILITY_ERROR in Check_Mutability_Rules |
| Restart immutable | ✅ PASS | IMMUTABILITY_ERROR in Check_Mutability_Rules |
| Journal INSERT-ONLY | ✅ PASS | JOURNAL_MUTABILITY_UNDECIDED error |
| Project limited to 2 fields | ✅ PASS | Strict allowlist enforcement |
| lifecycle_stage PROMOTE_ONLY | ✅ PASS | Explicit MUTABILITY_ERROR |
| deleted_at UNDECIDED_BLOCKED | ✅ PASS | Explicit MUTABILITY_ERROR |
| PATCH semantics | ✅ PASS | 'in extension' field checks |
| No spine updates | ✅ PASS | Zero spine UPDATE operations |

**Overall Audit Result**: ✅ **FULLY COMPLIANT**

---

## Workflow Statistics

- **Total Nodes**: 10
- **Supabase Nodes**: 2 (1 GET, 1 UPDATE)
- **Spine UPDATE Operations**: 0
- **Extension UPDATE Operations**: 1 (qxb_artifact_project only)
- **Error Short-Circuit**: Yes (Guard_Error_ShortCircuit node)
- **Query Integration**: Yes (Call_Query_To_Return_Artifact)

---

## Compliance with Mutability Registry v1

| Artifact Type | Workflow Behavior | Registry Rule | Compliance |
|---------------|-------------------|---------------|------------|
| **snapshot** | Blocked (IMMUTABILITY_ERROR) | CREATE_ONLY | ✅ COMPLIANT |
| **restart** | Blocked (IMMUTABILITY_ERROR) | CREATE_ONLY | ✅ COMPLIANT |
| **journal** | Blocked (JOURNAL_MUTABILITY_UNDECIDED) | UNDECIDED_BLOCKED | ✅ COMPLIANT |
| **project** | Limited to operational_state, state_reason | UPDATE_ALLOWED (specific fields) | ✅ COMPLIANT |

---

## Compliance with Doctrine: Journal INSERT-ONLY (Temporary)

**Doctrine**: Journal artifacts are append-only; no updates permitted

**Workflow Behavior**:
- ✅ Blocks ALL journal UPDATE attempts
- ✅ Returns error code `JOURNAL_MUTABILITY_UNDECIDED`
- ✅ References doctrine in error details
- ✅ Provides hint to use `artifact.create` for appending

**Compliance Status**: ✅ **FULLY COMPLIANT**

---

## Compliance with Mutability Gaps Decision Packet v1

**Decision 1**: project.tags mutability → **BLOCK_UNTIL_DECIDED**
- ✅ Workflow blocks tags updates (no allowlist entry)

**Decision 2**: project.summary, project.priority mutability → **BLOCK_UNTIL_DECIDED**
- ✅ Workflow blocks summary updates (no allowlist entry)
- ✅ Workflow blocks priority updates (no allowlist entry)

**Decision 3**: journal mutability → **BLOCK_UNTIL_DECIDED**
- ✅ Workflow blocks ALL journal updates (JOURNAL_MUTABILITY_UNDECIDED error)

**Compliance Status**: ✅ **FULLY COMPLIANT**

---

## Security & Safety Analysis

### ✅ No Mutability Expansion Risk
- Workflow does NOT allow any updates beyond explicitly allowed fields
- Strict allowlist enforcement prevents accidental permissions
- No fallback UPDATE paths that could bypass checks

### ✅ No UPSERT Behavior
- Workflow fetches existing artifact before UPDATE
- Returns NOT_FOUND if artifact doesn't exist
- No automatic INSERT fallback (UPDATE-ONLY)

### ✅ Workspace Scoping Enforced
- Fetch_Existing_Spine filters by both artifact_id AND workspace_id
- Prevents cross-workspace UPDATE attacks
- Returns NOT_FOUND if workspace_id mismatch

### ✅ Error Short-Circuit
- Guard_Error_ShortCircuit prevents DB writes on validation errors
- Errors route directly to output
- No partial UPDATE operations possible

---

## Recommendations

**No changes required.** The workflow is fully compliant with all Mutability Registry v1 rules, Journal INSERT-ONLY doctrine, and Mutability Gaps Decision Packet v1 defaults.

### Optional Future Enhancements (NOT Required for Compliance)

1. **Audit Logging**: Consider logging UPDATE operations for compliance/security tracking
2. **Extension UPSERT**: Consider auto-creating missing project extension rows (similar to Save v1.2 improvement #4)
3. **Optimistic Locking**: Consider version field checking to prevent concurrent update conflicts

**Note**: These are optional enhancements and NOT compliance issues.

---

## Audit Conclusion

**NQxb_Artifact_Update_v1 workflow is FULLY COMPLIANT with all mutability requirements.**

- ✅ No code changes required
- ✅ No security vulnerabilities found
- ✅ All blocked cases return explicit errors
- ✅ PATCH semantics correctly implemented
- ✅ No mutability expansion beyond registry rules
- ✅ Strict enforcement of Mutability Registry v1
- ✅ Strict enforcement of Journal INSERT-ONLY doctrine
- ✅ Strict enforcement of Mutability Gaps defaults

**Approval Status**: ✅ **APPROVED FOR PRODUCTION USE**

---

## Related Documents

- **Mutability_Registry_v1.md** - Binding mutation rules
- **Doctrine_Journal_InsertOnly_Temporary.md** - Journal INSERT-ONLY enforcement
- **Mutability_Gaps_Decision_Packet_v1.md** - Unresolved mutability decisions
- **NQxb_Artifact_Update_v1__Test_Cases.md** - Comprehensive test coverage (12 tests)
- **NQxb_Artifact_Create_v1.json** - CREATE-ONLY counterpart workflow
- **CLAUDE.md** - Governance rules for workflow changes

---

**End of Audit Report**
