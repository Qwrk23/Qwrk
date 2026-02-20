# Workflow Review — 2026-01-11 New Versions

**Date:** 2026-01-11
**Reviewer:** Claude Code
**Status:** Initial review complete

---

## Files Uploaded

Three new workflow versions were uploaded with Windows download numbering:

1. **NQxb_Artifact_Query_v1 (1).json** (1,195 lines)
   - Workflow ID: `IsLBYjXJ5R2Djfrv` ✅ (matches Gateway reference)
   - Version ID: `b0c8fcaf-0467-4d86-b885-0925ff67c9d9`
   - Change from archived: +84 lines (+7.6%)

2. **NQxb_Artifact_List_v1 (5).json** (712 lines)
   - Workflow ID: `Wbg4ciSwUSSTrO3C`
   - Version ID: `bd659a6c-82d3-4c22-8235-6053006b1d5a`
   - Change from archived: +27 lines (+3.9%)

3. **NQxb_Artifact_Save_v1 (7).json** (1,503 lines)
   - Workflow ID: `g0zpVK0sesavO4JA` ✅ (matches Gateway reference)
   - Version ID: `6a6b115f-4de5-48be-8ee1-7fcbaed08d33`
   - No prior version in workflows directory (previous archive: 2026-01-04)

**Missing:** NQxb_Artifact_Update_v1.json (was archived but no replacement uploaded)

---

## Key Findings

### 1. NQxb_Artifact_Save_v1 — Context Preservation Architecture

**Major enhancement: Response context preservation through DB node overwrites**

#### New Nodes
- `NQxb_Artifact_Save_v1__Build_Response_Context`
- `NQxb_Artifact_Save_v1__Merge_Context_For_Response`
- `NQxb_Artifact_Save_v1__Freeze_Extension_Payload`

#### Pattern
```
Normalize_Request
  → Set_Owner_User_ID_MVP
  → Freeze_Extension_Payload
  → [DB operations]
  → Build_Response_Context (creates context snapshot)
  → Merge_Context_For_Response (merges with DB result)
  → Return_Response (uses merged context, not DB lookup)
```

#### Key Improvements

**A) Frozen Extension Payload**
- Captures `extension.payload` before DB nodes
- Ensures restart/snapshot payloads in response match what was saved
- Prevents DB-truth vs response-truth divergence

**B) Build Response Context**
- Reads from authoritative nodes: `Normalize_Request`, `Set_Owner_User_ID_MVP`, `Freeze_Extension_Payload`
- Creates stable context item that survives Supabase overwrites
- Carries forward:
  - `artifact_type` (from request)
  - `workspace_id` (from request)
  - `saved_artifact_id` (from spine insert)
  - `_frozen_extension_payload` (from freeze node)
  - `_owner_source` (from owner derivation)
  - `operation` (INSERT vs UPDATE)

**C) Return Response**
- Uses **merged context only**, no node lookups
- Deterministic field resolution order
- Type-specific extension shaping (project/journal/restart/snapshot)

**D) Owner Source Surfacing**
- Response includes `_owner_source` field (temporary debug trace)
- Value: `mvp_service_principal` during MVP phase
- Documented in restart artifact: `f6c12ee1-4b4a-4deb-8f7f-862d88ae5550`

#### Code Quality Notes
- Comprehensive inline comments explaining intent
- Explicit note about v1.x patches
- Guards against null/undefined throughout
- Maintains backward compatibility with existing callers

---

### 2. NQxb_Artifact_Query_v1 — Node Naming Inconsistency

**Observation: Mixed node name prefixes**

#### Nodes with Correct Prefix
- `NQxb_Artifact_Query_v1__In`
- `NQxb_Artifact_Query_v1__Normalize_Request`
- `NQxb_Artifact_Query_v1__DB_Get_Artifact_Spine`
- `NQxb_Artifact_Query_v1__Shape_Return`
- `NQxb_Artifact_Query_v1__Return`
- `NQxb_Artifact_Query_v1__Return_NotFound`
- `NQxb_Artifact_Query_v1__Return_TypeMismatch`

#### Nodes with Gateway Prefix (Inconsistent)
- `NQxb_Gateway_v1__DB_Get_Journal_Extension`
- `NQxb_Gateway_v1__DB_Get_Project_Extension`
- `NQxb_Gateway_v1__DB_Get_Restart_Extension`
- `NQxb_Gateway_v1__DB_Get_Snapshot_Extension`
- `NQxb_Gateway_v1__Merge_Spine_And_Journal_Extension`
- `NQxb_Gateway_v1__Merge_Spine_And_Project_Extension`
- `NQxb_Gateway_v1__Merge_Spine_And_Restart_Extension`
- `NQxb_Gateway_v1__Merge_Spine_And_Snapshot_Extension`
- `NQxb_Gateway_v1__Switch_ArtifactType_ForQuery`
- `NQxb_Gateway_v1__Switch_Spine_Found`
- `NQxb_Gateway_v1__Switch_SpineType_Matches_RequestType`
- `NQxb_Gateway_v1__Set_SpineType` (1-3)
- `NQxb_Gateway_v1__Edit_CompareKey`

**Impact:**
- Functional: None (nodes work regardless of naming)
- Maintenance: Confusing when debugging or extending
- Governance: Violates naming discipline

**Recommendation:**
- Track as technical debt
- Rename to `NQxb_Artifact_Query_v1__*` in next maintenance cycle
- OR: Accept as-is if workflow is KGB-proven and stable

---

### 3. NQxb_Artifact_List_v1 — Clean Implementation

**Observation: Consistent naming, clear structure**

#### Node Organization
- Request handling: `In`, `Normalize_Request`, `Validate_Request`
- Filtering: `Build_Filters`, `Apply_Filters_And_Pagination`
- Branching: `Switch_ArtifactType`, `If_Hydrate`
- Hydration: Type-specific DB gets + Merge nodes for all 4 types
- Response: `Format_Base_Response`, `Format_Hydrated_Response`, `Combine_Hydrated_Results`

#### Key Features
- Supports `selector.hydrate` (boolean)
- Pagination with `selector.limit` and `selector.offset`
- Type-scoped list (artifact_type required)
- Returns fully hydrated artifacts when requested

#### Merge Node Pattern
- `NQxb_Artifact_List_v1__Merge_Journal`
- `NQxb_Artifact_List_v1__Merge_Project`
- `NQxb_Artifact_List_v1__Merge_Restart`
- `NQxb_Artifact_List_v1__Merge_Snapshot`

**Note:** Each merge node fixed for cardinality (iterates all items, returns 1:1)
- Documented in KGB proof: `docs/kgb/KGB__Gateway_artifact.list__2026-01-11.md`

---

## File Naming Issues

All three uploaded files have Windows download suffixes:
- `NQxb_Artifact_Query_v1 (1).json`
- `NQxb_Artifact_List_v1 (5).json`
- `NQxb_Artifact_Save_v1 (7).json`

**Required Action:**
Rename to canonical names before import:
- `NQxb_Artifact_Query_v1.json`
- `NQxb_Artifact_List_v1.json`
- `NQxb_Artifact_Save_v1.json`

---

## Workflow ID Verification

✅ **Query:** `IsLBYjXJ5R2Djfrv` matches Gateway reference
✅ **Save:** `g0zpVK0sesavO4JA` matches Gateway reference
⚠️ **List:** `Wbg4ciSwUSSTrO3C` not yet referenced in Gateway (List not implemented in Gateway yet)

---

## Integration Checklist

Before importing to n8n:

- [ ] Rename files to remove download suffixes
- [ ] Verify workflow IDs match Gateway references
- [ ] Confirm Supabase credential references are correct
- [ ] Test Save workflow with all 4 artifact types
- [ ] Test Query workflow with all 4 artifact types
- [ ] Test List workflow with hydrate=true and hydrate=false
- [ ] Verify `_owner_source` appears in Save responses
- [ ] Confirm restart/snapshot payloads are preserved correctly
- [ ] Run KGB regression suite (Query + List)

---

## Architecture Observations

### Context Preservation Pattern (Save workflow)
The new Save workflow implements a sophisticated context preservation architecture:

1. **Early Freezing:** Capture request intent before any DB operations
2. **Parallel Context Stream:** Build response context separately from DB mutations
3. **Merge Before Response:** Combine frozen context with DB results
4. **Deterministic Resolution:** Response builder uses merged context only, no lookups

This pattern solves the "Execute Workflow replaces $json" problem seen in Gateway.

**Applicability:**
- Gateway already implements similar pattern for artifact.save
- This Save workflow uses internal merge for its own response building
- Both layers (Gateway + Save) now preserve context correctly

---

## Recommendations

### Immediate (Pre-Import)
1. ✅ Rename files to canonical names
2. ✅ Verify workflow IDs
3. ⚠️ Decide: Accept Query workflow naming inconsistency or defer import for cleanup?

### Post-Import
1. Run full KGB test suite
2. Verify `_owner_source` surfacing works end-to-end
3. Document Query workflow naming debt if accepting as-is
4. Test Gateway → Save integration with new context preservation

### Future Maintenance
1. Consider renaming Query workflow nodes for consistency
2. Add Update workflow (was archived but no replacement provided)
3. Document context preservation pattern as architectural standard

---

## Summary

**Quality Assessment:**
- **Save:** Excellent - sophisticated context preservation, well-documented
- **List:** Good - clean structure, consistent naming, KGB-proven
- **Query:** Good functionality, naming inconsistency noted

**Ready for Import:** Yes, with file renaming
**Blocking Issues:** None
**Technical Debt:** Query workflow node naming

---

**Review complete. Awaiting decision on next steps.**
