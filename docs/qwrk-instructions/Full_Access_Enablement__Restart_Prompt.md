# Full Access Enablement — Restart Prompt

**Type:** Restart Prompt
**Created:** 2026-01-24
**Status:** PENDING — Pick up after Gateway workflow fixes are verified
**Prerequisites:** Complete `Gateway_Workflow_Fixes__Restart_Prompt.md` first

---

## Context

We have created new schema and instruction files to enable **full access** (read + write) for the Qwrk GPT front-end:

| File | Version | Path |
|------|---------|------|
| Schema | v2.0.0-dev | `docs/qwrk-instructions/Qwrk_Gateway_v1_Actions_Schema.yaml` |
| Instructions | v1 | `docs/qwrk-instructions/Qwrk_Full_Access_MVP_Instructions_v1.md` |

### What Changed

**Schema (v2.0.0-dev):**
- Added `artifact.save`, `artifact.update`, `artifact.promote` to `GwAction` enum
- Expanded `ArtifactType` from `["project"]` to `["project", "journal", "restart", "snapshot"]`
- Added write request schemas: `ArtifactSaveRequest`, `ArtifactUpdateRequest`, `ArtifactPromoteRequest`
- Added extension schemas: `ProjectExtension`, `JournalExtension`, `RestartExtension`, `SnapshotExtension`
- Added enums: `LifecycleStage`, `OperationalState`, `LifecycleTransition`

**Instructions (v1):**
- 12 sections covering all read and write operations
- Mutability registry defining what can be updated per artifact type
- Confirmation patterns for write operations
- Error code reference

---

## Prerequisite Work (Must Be Complete)

Before starting this enablement, verify:

1. **Gateway workflow fixes applied and tested:**
   - [ ] Update workflow: `Switch_Type_Registry` error path connected
   - [ ] Promote workflow: All dead-ends connected, terminal node added
   - [ ] Save workflow: `artifact_id` properly returned
   - [ ] Test harness shows 37/37 PASSED for project operations

2. **Run test harness to confirm:**
   ```powershell
   cd "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"
   .\docs\testing\run-tests.ps1 -Password "[PASSWORD]" -TestSuite "All"
   ```

---

## Tasks for Full Access Enablement

### Task 1: Verify Type Registry

Check that all 4 artifact types are registered and enabled:

```sql
SELECT artifact_type, enabled, created_at
FROM qxb_artifact_type_registry
WHERE artifact_type IN ('project', 'journal', 'restart', 'snapshot')
ORDER BY artifact_type;
```

**Expected:** All 4 types present with `enabled = true`

**If missing:** Insert the missing types:
```sql
INSERT INTO qxb_artifact_type_registry (artifact_type, enabled)
VALUES
  ('journal', true),
  ('restart', true),
  ('snapshot', true)
ON CONFLICT (artifact_type) DO UPDATE SET enabled = true;
```

---

### Task 2: Verify Extension Tables Exist

Check that extension tables exist for all artifact types:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE 'qxb_artifact_%'
ORDER BY table_name;
```

**Expected tables:**
- `qxb_artifact` (spine table)
- `qxb_artifact_project`
- `qxb_artifact_journal`
- `qxb_artifact_restart`
- `qxb_artifact_snapshot`

**If missing:** Extension tables need to be created. Check `docs/schema/` for DDL or generate based on existing patterns.

---

### Task 3: Review Subworkflow Type Support

Review each subworkflow to verify it handles all 4 artifact types:

#### 3a. NQxb_Artifact_Query_v1
- [ ] Verify type-specific hydration branches exist for: project, journal, restart, snapshot
- [ ] Each branch should JOIN the correct extension table

#### 3b. NQxb_Artifact_List_v1
- [ ] Verify type-specific list queries for all 4 types
- [ ] Hydration should JOIN correct extension table when `selector.hydrate = true`

#### 3c. NQxb_Artifact_Save_v1
- [ ] Verify INSERT branches for all 4 artifact types
- [ ] Each branch should INSERT into both spine (`qxb_artifact`) and extension table
- [ ] Extension field mapping is correct per type

#### 3d. NQxb_Artifact_Update_v1
- [ ] Verify UPDATE only allowed for `project` type
- [ ] For `project`: only `operational_state` and `state_reason` should be updateable
- [ ] For `journal`, `restart`, `snapshot`: should return IMMUTABILITY_ERROR

**Add immutability guard if missing:**
```javascript
// In Update workflow, after Type Registry check
const IMMUTABLE_TYPES = new Set(['journal', 'restart', 'snapshot']);

if (IMMUTABLE_TYPES.has(artifact_type)) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'IMMUTABILITY_ERROR',
        message: `Artifact type '${artifact_type}' is immutable and cannot be updated`,
        details: { artifact_type }
      }
    }
  }];
}
```

---

### Task 4: Expand Test Harness

Add test cases for journal, restart, and snapshot to `Qwrk.Gateway.TestHarness.ps1`:

#### New Test Functions Needed:

```powershell
# Journal tests
function Invoke-QwrkJournalTests {
    # LIST journal
    # QUERY journal (need Known-Good journal ID)
    # SAVE journal (create new)
    # UPDATE journal (should fail with IMMUTABILITY_ERROR)
}

# Restart tests
function Invoke-QwrkRestartTests {
    # LIST restart
    # QUERY restart (need Known-Good restart ID)
    # SAVE restart (create new)
    # UPDATE restart (should fail with IMMUTABILITY_ERROR)
}

# Snapshot tests
function Invoke-QwrkSnapshotTests {
    # LIST snapshot
    # QUERY snapshot (need Known-Good snapshot ID)
    # SAVE snapshot (create new)
    # UPDATE snapshot (should fail with IMMUTABILITY_ERROR)
}
```

#### Known-Good IDs Needed:
- Journal ID: [TBD - create or find existing]
- Restart ID: [TBD - create or find existing]
- Snapshot ID: [TBD - create or find existing]

---

### Task 5: Deploy Schema to ChatGPT Custom GPT

Once all verification passes:

1. Open ChatGPT Custom GPT configuration
2. Go to Actions section
3. Replace schema with contents of `Qwrk_Gateway_v1_Actions_Schema.yaml` (v2.0.0-dev)
4. Update system instructions with contents of `Qwrk_Full_Access_MVP_Instructions_v1.md`
5. Test in ChatGPT:
   - "List all journals"
   - "Create a new journal entry titled 'Test Entry'"
   - "Show me all snapshots"

---

### Task 6: End-to-End Validation

Perform manual validation in ChatGPT:

| Test | Expected Result |
|------|-----------------|
| "List projects" | Returns project list |
| "List journals" | Returns journal list |
| "List restarts" | Returns restart list |
| "List snapshots" | Returns snapshot list |
| "Create a new project called Test" | Creates project, returns artifact_id |
| "Create a journal entry" | Creates journal, returns artifact_id |
| "Save a restart point" | Creates restart, returns artifact_id |
| "Pause project [ID]" | Updates operational_state to paused |
| "Promote project [ID] to sapling" | Transitions lifecycle_status |
| "Update the journal entry" | Returns IMMUTABILITY_ERROR |

---

## Success Criteria

- [ ] Type Registry has all 4 types enabled
- [ ] Extension tables exist for all 4 types
- [ ] Query works for all 4 types
- [ ] List works for all 4 types
- [ ] Save works for all 4 types
- [ ] Update works for project only
- [ ] Update correctly rejects journal/restart/snapshot
- [ ] Promote works for project
- [ ] Schema deployed to ChatGPT Custom GPT
- [ ] End-to-end validation passes

---

## Reference Files

| Purpose | Path |
|---------|------|
| New Schema | `docs/qwrk-instructions/Qwrk_Gateway_v1_Actions_Schema.yaml` |
| New Instructions | `docs/qwrk-instructions/Qwrk_Full_Access_MVP_Instructions_v1.md` |
| Archived Schema | `docs/qwrk-instructions/Qwrk_Gateway_v1_Actions_Schema__v1.2.1-dev__SUPERSEDED__2026-01-24.yaml` |
| Archived Instructions | `docs/qwrk-instructions/Qwrk_Dev_Read_Only_MVP_Instructions_v7__SUPERSEDED__2026-01-24.md` |
| Test Harness | `docs/testing/Qwrk.Gateway.TestHarness.ps1` |
| Workflow Fixes Prompt | `docs/testing/Gateway_Workflow_Fixes__Restart_Prompt.md` |

---

## Workflow Files (for reference)

| Workflow | File | n8n ID |
|----------|------|--------|
| Gateway | `workflows/NQxb_Gateway_v1 (27).json` | D1NWfUWZ9IFDVqNB |
| Query | `workflows/NQxb_Artifact_Query_v1 (5).json` | IsLBYjXJ5R2Djfrv |
| List | `workflows/NQxb_Artifact_List_v1.json` | Wbg4ciSwUSSTrO3C |
| Save | `workflows/NQxb_Artifact_Save_v1.json` | g0zpVK0sesavO4JA |
| Update | `workflows/NQxb_Artifact_Update_v1.json` | 0648bPAenHiR5ixy |
| Promote | `workflows/NQxb_Artifact_Promote_v1.json` | nP9KyhnjqYOKQRiA |
