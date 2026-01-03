# NQxb_Artifact_Create_v1 CHANGELOG

**Created From**: `NQxb_Artifact_Save_v1.json` (v1.2 locked)
**Date**: 2026-01-01
**Purpose**: Extract CREATE-ONLY behavior into dedicated workflow

---

## Summary

`NQxb_Artifact_Create_v1` is a simplified, INSERT-ONLY workflow derived from `NQxb_Artifact_Save_v1` (v1.2). It accepts only artifact creation requests and rejects any request containing `artifact_id` with a `CREATE_ONLY` error envelope.

---

## Behavior Changes

### 1. CREATE-ONLY Enforcement

**Change**: Workflow now rejects any request with `artifact_id` provided.

**Implementation**: `Normalize_Request` node checks for `artifact_id` and returns error envelope:
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "CREATE_ONLY",
    "message": "artifact.create is insert-only. Use artifact.update for updates.",
    "details": {
      "provided_artifact_id": "...",
      "hint": "Remove artifact_id field to create a new artifact."
    }
  }
}
```

**Before (Save v1.2)**: `artifact_id` presence determined INSERT vs UPDATE branching
**After (Create v1)**: `artifact_id` presence triggers immediate error

### 2. Simplified Normalize Request

**Removed**:
- `is_update` flag calculation
- `_provided_fields` tracking (PATCH semantics not needed for INSERT-only)
- Lifecycle alignment logic (removed from CREATE workflow)

**Kept**:
- Request body unwrapping
- Field extraction and defaults
- Extension object canonicalization

### 3. Simplified Validation

**Removed**:
- UPDATE-specific validation logic
- PATCH field validation (title non-empty if provided)
- Conditional validation based on `is_update` flag

**Kept**:
- INSERT-only validation:
  - `gw_workspace_id` required
  - `artifact_type` required (must be project, journal, restart, snapshot)
  - `owner_user_id` required
  - `title` required
  - Type-specific extension validation:
    - project: `extension.lifecycle_stage` required
    - restart/snapshot: `extension.payload` required (object)
    - journal: no additional constraints beyond existing

---

## Nodes Removed (Entire UPDATE Branch)

The following nodes were completely removed as they are UPDATE-specific:

### UPDATE Routing & Control Flow
1. **`Switch_InsertOrUpdate`** - No longer needed (CREATE-only, no branching)

### UPDATE Path - Immutability & Fetching
2. **`Check_Immutability`** - Not needed (no UPDATE operations to block)
3. **`Fetch_Existing_Spine`** - Not needed (no existing artifact to fetch)
4. **`Merge_PATCH_Spine`** - Not needed (no PATCH semantics)

### UPDATE Path - Spine Update
5. **`DB_Update_Spine`** - Not needed (no UPDATE operations)
6. **`Switch_Type_For_Update`** - Not needed (no UPDATE branching)

### UPDATE Path - Project Extension UPSERT
7. **`Fetch_Existing_Project_Extension`** - Not needed
8. **`Check_Project_Extension_Exists`** - Not needed
9. **`Merge_PATCH_Project_Extension`** - Not needed
10. **`Prepare_Insert_Missing_Project_Extension`** - Not needed
11. **`DB_Update_Project_Extension`** - Not needed
12. **`DB_Insert_Missing_Project_Extension`** - Not needed

### UPDATE Path - Journal Extension UPSERT
13. **`Fetch_Existing_Journal_Extension`** - Not needed
14. **`Check_Journal_Extension_Exists`** - Not needed
15. **`Merge_PATCH_Journal_Extension`** - Not needed
16. **`Prepare_Insert_Missing_Journal_Extension`** - Not needed
17. **`DB_Update_Journal_Extension`** - Not needed
18. **`DB_Insert_Missing_Journal_Extension`** - Not needed

**Total Removed**: 18 nodes

---

## Nodes Kept (INSERT Path Only)

The following nodes were retained with minor name changes (Save → Create):

### Request Processing
1. **`NQxb_Artifact_Create_v1__In`** (trigger)
2. **`NQxb_Artifact_Create_v1__Normalize_Request`** (simplified - CREATE_ONLY check added)
3. **`NQxb_Artifact_Create_v1__Validate_Request`** (simplified - INSERT-only validation)
4. **`NQxb_Artifact_Create_v1__Guard_Error_ShortCircuit`** (error routing)

### Database INSERT Operations
5. **`NQxb_Artifact_Create_v1__DB_Insert_Spine`**
6. **`NQxb_Artifact_Create_v1__Normalize_Saved_ID`** (deterministic artifact_id extraction)
7. **`NQxb_Artifact_Create_v1__Switch_Type_For_Insert`** (artifact type routing)

### Extension INSERT Operations
8. **`NQxb_Artifact_Create_v1__DB_Insert_Project_Extension`**
9. **`NQxb_Artifact_Create_v1__DB_Insert_Journal_Extension`**
10. **`NQxb_Artifact_Create_v1__DB_Insert_Restart_Extension`**
11. **`NQxb_Artifact_Create_v1__DB_Insert_Snapshot_Extension`**

### Response Construction
12. **`NQxb_Artifact_Create_v1__Prepare_Query_Call`**
13. **`NQxb_Artifact_Create_v1__Call_Query_To_Return_Artifact`**

**Total Kept**: 13 nodes

---

## Workflow Flow (Simplified)

```
1. In (Trigger)
   ↓
2. Normalize_Request (with CREATE_ONLY check)
   ↓ (artifact_id present)        ↓ (no artifact_id)
   [CREATE_ONLY error]         Validate_Request
                                   ↓
                              Guard_Error_ShortCircuit
                                ↓ (ok=false)    ↓ (valid)
                            [Direct to output]  DB_Insert_Spine
                                                    ↓
                                              Normalize_Saved_ID
                                                    ↓
                                              Switch_Type_For_Insert
                                                    ↓
                                              Extension_INSERTs (4 branches)
                                                    ↓
                                              Prepare_Query_Call
                                                    ↓
                                              Call_Query_To_Return_Artifact
```

**Key Simplification**: No UPDATE branching, no PATCH logic, no UPSERT complexity. Linear INSERT-only flow.

---

## Validation Rules (Unchanged from Save v1.2 INSERT path)

### Required Fields (All Types)
- `gw_workspace_id` (UUID)
- `artifact_type` (one of: project, journal, restart, snapshot)
- `owner_user_id` (UUID)
- `title` (non-empty string)

### Type-Specific Requirements
- **project**: `extension.lifecycle_stage` required (one of: seed, sapling, tree, retired)
- **restart**: `extension.payload` required (must be object, not string)
- **snapshot**: `extension.payload` required (must be object, not string)
- **journal**: No additional constraints (entry_text and payload optional)

---

## Error Envelopes

### 1. CREATE_ONLY Error (New)

Returned when `artifact_id` is provided in request:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "CREATE_ONLY",
    "message": "artifact.create is insert-only. Use artifact.update for updates.",
    "details": {
      "provided_artifact_id": "abc-123",
      "hint": "Remove artifact_id field to create a new artifact."
    }
  }
}
```

### 2. VALIDATION_ERROR

Same as Save v1.2, but always references INSERT operation:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed for artifact.create operation (INSERT)",
    "details": {
      "validation_errors": [...],
      "artifact_type": "project",
      "operation": "INSERT"
    }
  }
}
```

---

## Compatibility

### Gateway Integration

**Action Name**: `artifact.create`
- Can coexist with `artifact.save` (Save v1.2 supports both INSERT and UPDATE)
- Recommended: Use `artifact.create` for explicit INSERT-only operations
- Fallback: `artifact.save` without `artifact_id` still works for INSERT

### Existing Workflows

**No Breaking Changes**: `NQxb_Artifact_Save_v1` remains unchanged and fully functional.

**Migration Path**: Workflows calling `artifact.save` for INSERT operations can optionally migrate to `artifact.create` for clarity, but this is not required.

---

## Testing Checklist

Before deploying `NQxb_Artifact_Create_v1`, verify:

1. ✅ **CREATE_ONLY Error**: Request with `artifact_id` returns `CREATE_ONLY` error envelope
2. ✅ **Validation**: Missing required fields return `VALIDATION_ERROR`
3. ✅ **Project INSERT**: Valid project with `lifecycle_stage` creates artifact + extension
4. ✅ **Journal INSERT**: Valid journal creates artifact + extension (entry_text/payload optional)
5. ✅ **Restart INSERT**: Valid restart with `payload` object creates artifact + extension
6. ✅ **Snapshot INSERT**: Valid snapshot with `payload` object creates artifact + extension
7. ✅ **Deterministic ID**: `Normalize_Saved_ID` extracts `saved_artifact_id` correctly
8. ✅ **Query Integration**: Final query call returns complete merged artifact

---

## Future Considerations

### Potential artifact.update Workflow

If UPDATE operations are separated from `artifact.save`, a future `NQxb_Artifact_Update_v1` workflow would:
- Require `artifact_id` (CREATE_ONLY check inverted)
- Implement PATCH semantics (field tracking, merge logic)
- Handle immutability (reject restart/snapshot updates)
- Handle UPSERT for missing extensions

**Not implemented yet** - `NQxb_Artifact_Save_v1` still handles both CREATE and UPDATE.

---

## Node Count Summary

| Workflow | Total Nodes | INSERT Nodes | UPDATE Nodes |
|----------|-------------|--------------|--------------|
| **Save v1.2** | 31 | 13 | 18 |
| **Create v1** | 13 | 13 | 0 |

**Reduction**: 58% fewer nodes (18 nodes removed)

---

## Related Documents

- **NQxb_Artifact_Save_v1__README.md** (v1.2) - Full Save workflow documentation
- **Mutability_Registry_v1.md** - Mutation rules for all artifact types
- **CLAUDE.md** - Governance rules for workflow changes

---

**End of CHANGELOG**
