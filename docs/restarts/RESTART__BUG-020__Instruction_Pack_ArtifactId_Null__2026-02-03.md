# Restart: BUG-020 instruction_pack artifact_id null

**Date:** 2026-02-03
**Priority:** High
**Thread:** T9

---

## Problem Identified

Gateway returns `ok: true` but `artifact_id: null` for instruction_pack saves. The save actually succeeds (artifact exists in database), but the artifact_id isn't returned in the response.

This breaks Telegram Gateway verification which expects artifact_id to confirm save success.

---

## Root Cause (CONFIRMED)

File: `workflows/NQxb_Artifact_Save_v1 (24).json`
Node: `NQxb_Artifact_Save_v1__DB_Insert_Instruction_Pack_Extension` (id: `77771cac-0857-4e8d-94f1-c8c43df275a3`)

**Current (broken) - lines 1173-1222:**
```json
{
  "parameters": {
    "operation": "update",              // ← WRONG: should be create
    "tableId": "qxb_artifact_instruction_pack",
    "matchType": "allFilters",          // ← For update only
    "filters": {                        // ← For update only
      "conditions": [
        {
          "keyName": "artifact_id",
          "condition": "eq",
          "keyValue": "={{ $json.saved_artifact_id }}"
        }
      ]
    },
    "fieldsUi": {
      "fieldValues": [
        // Missing artifact_id field!
        { "fieldId": "workspace_id", ... },
        { "fieldId": "scope", ... },
        ...
      ]
    }
  }
}
```

**Compare to Project extension (working) - lines 313-349:**
```json
{
  "parameters": {
    "tableId": "qxb_artifact_project",
    // No "operation" = defaults to INSERT
    // No matchType, no filters
    "fieldsUi": {
      "fieldValues": [
        { "fieldId": "artifact_id", "fieldValue": "={{ $json.saved_artifact_id }}" },
        { "fieldId": "lifecycle_stage", ... },
        ...
      ]
    }
  }
}
```

---

## Required Fix

1. **Create versioned copy** of `NQxb_Artifact_Save_v1 (24).json` → Archive current as `(24)__SUPERSEDED`
2. **Modify the instruction_pack extension node:**
   - Remove `"operation": "update"`
   - Remove `"matchType": "allFilters"`
   - Remove the `"filters"` block
   - Add `artifact_id` to `fieldsUi.fieldValues`:
     ```json
     { "fieldId": "artifact_id", "fieldValue": "={{ $json.saved_artifact_id }}" }
     ```
3. **Export updated workflow** as `NQxb_Artifact_Save_v1 (25).json`
4. **Import to n8n** and activate
5. **Test via Telegram:** `save instruction_pack titled "Test" with tags test: content`
6. **Verify:** Gateway returns artifact_id, Telegram shows verified success

---

## Related Work Completed This Session

1. **BUG-019 v8-no-sanitizer** — KGB confirmed, T8 closed
2. **instruction_pack singleton constraint removal** — Migration executed, verified working
   - File: `migrations/2026-02-03__Remove_Instruction_Pack_Singleton_Constraint.sql`
   - Multiple instruction_packs can now be saved
3. **Root cause analysis** — instruction_pack extension node misconfiguration identified

---

## Key Files

| File | Purpose |
|------|---------|
| `workflows/NQxb_Artifact_Save_v1 (24).json` | Current KGB — archive before modifying |
| `docs/restarts/RESTART__BUG-020__Instruction_Pack_ArtifactId_Null__2026-02-03.md` | This restart |
| `sessions/OPEN_THREADS.md` | T9 tracking this issue |

---

## Instructions for Next Session

1. **Read this restart prompt**
2. **Archive current workflow:** Copy `(24)` to `Archive/NQxb_Artifact_Save_v1 (24)__SUPERSEDED__2026-02-03.json`
3. **Apply fix to local JSON file** (CC will do this)
4. **Export as `(25)`**
5. **Import to n8n and test**
6. **Update bug tracker on success**

---

## Restart Prompt (Copy-Paste Ready)

```
New session

Continue: BUG-020 instruction_pack artifact_id null fix

Read: docs/restarts/RESTART__BUG-020__Instruction_Pack_ArtifactId_Null__2026-02-03.md

Fix identified: NQxb_Artifact_Save_v1 instruction_pack extension node uses UPDATE instead of INSERT.

Ready to:
1. Archive current workflow (24)
2. Apply fix to JSON
3. Export as (25)
4. Test via Telegram
```
