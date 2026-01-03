# Doctrine: Journal Insert-Only (Temporary)

**Status**: Temporary
**Created**: 2026-01-02
**Scope**: Journal artifact type mutability policy
**Authority**: Derived from Mutability Registry v1
**Supersedes**: None (first formal doctrine)

---

## Summary

**Journal artifacts are INSERT-ONLY (append-only) until a permanent mutability policy is locked.**

This doctrine establishes a temporary, binding operational rule: **all journal artifact UPDATE operations are blocked** via the `artifact.update` workflow. New journal entries must be created using `artifact.create` instead.

---

## Doctrine Name

**Journal INSERT-ONLY (Temporary)**

---

## Rule

**Journal artifacts are append-only; no updates permitted.**

All UPDATE attempts on journal artifact type will return error code `JOURNAL_MUTABILITY_UNDECIDED` with message:
```
"Journal update policy is not locked. Use artifact.create to append new entries."
```

---

## Reason

**Mutability policy not locked.**

From Mutability Registry v1:
- Journal artifact mutability is classified as `UNDECIDED_BLOCKED`
- The decision on whether journals should be editable or immutable was explicitly deferred in Phase 2
- No authoritative design decision has been locked regarding journal UPDATE semantics

**Design Choice Deferred**:
Journals may eventually be:
1. **Fully immutable (append-only)**: Once written, entries cannot be edited (privacy, audit trail)
2. **Editable**: Users can correct typos or update entries (user experience, flexibility)

This choice has semantic implications for:
- Privacy model (can users delete/edit past reflections?)
- Audit trail requirements (should journal history be preserved?)
- User expectations (editing vs. correction-by-appending)

Until this decision is made and locked in a versioned design document, the safe default is **INSERT-ONLY**.

---

## Enforcement Mechanism

**Workflow**: `NQxb_Artifact_Update_v1` (Workflow Files/NQxb_Artifact_Update_v1.json)

**Node**: `NQxb_Artifact_Update_v1__Check_Mutability_Rules`

**Code Snippet** (lines ~152-171 in Check_Mutability_Rules node):
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

**Error Envelope**:
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "JOURNAL_MUTABILITY_UNDECIDED",
    "message": "Journal update policy is not locked. Use artifact.create to append new entries.",
    "details": {
      "artifact_type": "journal",
      "artifact_id": "<artifact_id>",
      "operation_attempted": "UPDATE",
      "registry_rule": "UNDECIDED_BLOCKED",
      "source": "Mutability Registry v1",
      "doctrine": "Journal INSERT-ONLY (Temporary)",
      "hint": "Journal artifacts are append-only until mutability policy is locked. Create new journal entries instead."
    }
  }
}
```

---

## User Impact

### Allowed Operations
✅ **artifact.create** - Create new journal entries
✅ **artifact.query** - Read existing journal entries
✅ **artifact.list** - List journal artifacts

### Blocked Operations
❌ **artifact.update** - Attempting to update any journal artifact will fail with `JOURNAL_MUTABILITY_UNDECIDED` error

### Recommended Pattern

**To add new journal content**:
```json
{
  "gw_action": "artifact.create",
  "gw_workspace_id": "<workspace_id>",
  "owner_user_id": "<user_id>",
  "artifact_type": "journal",
  "title": "Daily Reflection - 2026-01-02",
  "extension": {
    "entry_text": "New journal entry content",
    "payload": {
      "tags": ["reflection", "daily"],
      "mood": "productive"
    }
  }
}
```

**To correct/amend previous journal entry**:
- Create a new journal artifact with corrected content
- Use `parent_artifact_id` to link to original entry (optional)
- Include metadata indicating correction/amendment in `payload`

---

## Future Unlock Condition

**This doctrine will be superseded when:**

A new Mutability Registry version (v2 or later) is published with an explicit, locked decision on journal mutability that includes:

1. **Design Decision Document**: Versioned specification documenting the chosen journal mutability model
2. **Mutability Registry Update**: New registry version with journal artifacts moved from `UNDECIDED_BLOCKED` to one of:
   - `CREATE_ONLY` (permanent append-only, like snapshot/restart)
   - `UPDATE_ALLOWED` (specific fields editable with PATCH semantics)
3. **Workflow Updates**: `NQxb_Artifact_Update_v1` (or successor) updated to enforce new rules
4. **KGB Regression**: Verification that existing journal artifacts are not broken by the new policy
5. **Master Joel Approval**: Truth hierarchy compliance check

**Until then**, this doctrine remains in force and **journal UPDATE operations are blocked**.

---

## Related Documents

- **Mutability_Registry_v1.md** - Binding mutation rules (marks journal as `UNDECIDED_BLOCKED`)
- **Mutability_Registry_v1__snapshot_payload.json** - Machine-readable registry rules
- **NQxb_Artifact_Update_v1.json** - UPDATE workflow enforcing this doctrine
- **NQxb_Artifact_Update_v1__Test_Cases.md** - Test Case 4 validates journal blocking
- **CLAUDE.md** - Governance rules for doctrine changes

---

## Changelog

### 2026-01-02 - Doctrine Established
- **Formalized** Journal INSERT-ONLY rule as temporary doctrine
- **Updated** `NQxb_Artifact_Update_v1` workflow with `JOURNAL_MUTABILITY_UNDECIDED` error code
- **Created** doctrine snapshot artifact for immutable reference
- **Source**: Mutability Registry v1, Phase 2 deferred decisions

---

## Snapshot Reference

This doctrine has been formalized as an immutable snapshot artifact:

**File**: `Doctrine_Journal_InsertOnly_Temporary.snapshot.json`
**Artifact Type**: snapshot
**Title**: "Doctrine: Journal Insert-Only (Temporary)"

To save this doctrine to Qwrk:
```bash
# Use artifact.create workflow with the snapshot payload
# Artifact will be immutable once created
```

---

**End of Doctrine**
