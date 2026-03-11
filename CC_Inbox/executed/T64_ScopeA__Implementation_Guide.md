# T64 Scope A — Spine-Field Update for execution_status (branch/limb/leaf)

## Implementation Guide

**Thread:** T64 — Spine-Field Update Path for Non-Project Types
**Scope:** A (execution_status only — no title/priority/summary/lifecycle)
**Prepared by:** CC
**Date:** 2026-02-24

---

## Executive Summary

This guide adds a `spine_fields` update mode to the Update sub-workflow (`NQxb_Artifact_Update_v1`) enabling `execution_status` updates on `branch`, `limb`, and `leaf` artifact types.

**Key insight:** `execution_status` is a SPINE field on `qxb_artifact` (DDL v2.4, line 159), NOT an extension table field. The extension tables for these types either don't exist (`qxb_artifact_branch`, `qxb_artifact_leaf`) or are shell-only (`qxb_artifact_limb`). Therefore, the update path PATCHes `qxb_artifact` directly — no extension table writes.

---

## Architecture Change

### Before (v36)

```
Switch_Update_Mode
├── tags_only → Compute_Tag_Merge → DB_Update_Spine_Tags → Return_Tags_Ack
└── fallback (extension) → Switch_Type_For_Update
    ├── project → Prepare_Project_Extension → DB_Update_Project → Version_Increment → Ack
    ├── branch → Return_Unimplemented_Type_Error
    ├── limb   → Return_Unimplemented_Type_Error
    ├── leaf   → Return_Unimplemented_Type_Error
    └── fallback → Return_Unhandled_Type_Error
```

### After (T64 Scope A)

```
Switch_Update_Mode
├── tags_only    → Compute_Tag_Merge → DB_Update_Spine_Tags → Return_Tags_Ack
├── spine_fields → Prepare_Spine_Field_Update → DB_Update_Spine_Fields → Return_Update_Ack
└── fallback (extension) → Switch_Type_For_Update
    ├── project → Prepare_Project_Extension → DB_Update_Project → Version_Increment → Ack
    ├── branch → Return_Unimplemented_Type_Error (now unreachable for valid requests)
    ├── limb   → Return_Unimplemented_Type_Error (now unreachable)
    ├── leaf   → Return_Unimplemented_Type_Error (now unreachable)
    └── fallback → Return_Unhandled_Type_Error
```

### Why branch/limb/leaf routes in Switch_Type_For_Update become unreachable

With the new step 6.5 in `Check_Mutability_Rules`, any extension update request for branch/limb/leaf is caught early:
- Valid extension fields → routed to `spine_fields` mode
- Invalid extension fields → returns VALIDATION_ERROR
- Empty extension → returns VALIDATION_ERROR

These types never reach `Switch_Type_For_Update` for extension updates. The dead routes are preserved as defense-in-depth.

---

## What CC Prepared Automatically

### Modified Workflow JSON

**File:** `workflows/NQxb_Artifact_Update_v1__T64_ScopeA.json`

This is a complete, importable workflow JSON with all changes applied. It can be imported directly into n8n as a replacement for the current Update sub-workflow.

### Changes Summary

| # | Node | Action | Description |
|---|------|--------|-------------|
| 1 | `Check_Mutability_Rules` | MODIFY | Added step 6.5: branch/limb/leaf spine-field validation + routing |
| 2 | `Switch_Update_Mode` | MODIFY | Added `spine_fields` rule (output 1). Extension fallback moved to output 2 |
| 3 | `Prepare_Spine_Field_Update` | **NEW** | Code node: extract execution_status, compute next_version |
| 4 | `DB_Update_Spine_Fields` | **NEW** | HTTP Request: PATCH qxb_artifact (execution_status + version in single call) |
| 5 | Wiring | MODIFY | spine_fields path connected through new nodes to existing Return_Update_Ack |

---

## Node Details

### 1. Check_Mutability_Rules — Step 6.5 (NEW CODE BLOCK)

**Location in code:** After the project block (step 6), before the generic fallthrough (step 7).

**What it does:**
1. Matches `artifact_type` in `['branch', 'limb', 'leaf']`
2. Whitelists extension fields: ONLY `execution_status` allowed
3. Rejects unknown fields with `VALIDATION_ERROR`
4. Rejects empty extension with `VALIDATION_ERROR`
5. Validates `execution_status` value against CHECK constraint: `['not_started', 'in_progress', 'blocked', 'complete']`
6. Returns `_update_mode: 'spine_fields'` with `_spine_update` payload

**Full step 6.5 code (inserted between steps 6 and 7):**

```javascript
// 6.5 RULE: branch/limb/leaf — spine-field update only (T64 Scope A)
// execution_status is a SPINE field on qxb_artifact, NOT an extension table field.
// Extension tables for these types either don't exist (branch, leaf) or are shell-only (limb).
// Route to spine PATCH instead of extension table write.
const executionAnatomyTypes = ['branch', 'limb', 'leaf'];
if (executionAnatomyTypes.includes(artifact_type)) {
  const extension = normalizeNode.extension || {};
  const allowedSpineFields = ['execution_status'];
  const providedFields = Object.keys(extension);

  // Whitelist check: reject unknown fields
  const disallowedFields = providedFields.filter(f => !allowedSpineFields.includes(f));
  if (disallowedFields.length > 0) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Disallowed fields in extension for ' + artifact_type + ' UPDATE: ' + disallowedFields.join(', '),
          details: {
            disallowed_fields: disallowedFields,
            allowed_fields: allowedSpineFields,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            source: 'T64 Scope A',
            hint: 'Only execution_status is UPDATE_ALLOWED for ' + artifact_type + ' artifacts. Use tags.add/tags.remove for tag updates.'
          }
        }
      }
    }];
  }

  // Must provide at least one field
  if (providedFields.length === 0) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: 'No updateable fields provided in extension for ' + artifact_type + ' UPDATE.',
          details: {
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            allowed_fields: allowedSpineFields,
            hint: 'Provide execution_status in extension object.'
          }
        }
      }
    }];
  }

  // Validate execution_status value against CHECK constraint
  const validStatuses = ['not_started', 'in_progress', 'blocked', 'complete'];
  const execStatus = extension.execution_status;
  if (execStatus !== null && execStatus !== undefined && !validStatuses.includes(execStatus)) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: "Invalid execution_status value: '" + execStatus + "'",
          details: {
            field: 'execution_status',
            provided_value: execStatus,
            allowed_values: validStatuses,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            hint: 'execution_status must be one of: not_started, in_progress, blocked, complete'
          }
        }
      }
    }];
  }

  // Validation passed — route to spine-field update
  return [{
    json: {
      ok: true,
      _gw_route: 'ok',
      _update_mode: 'spine_fields',
      gw_action: normalizeNode.gw_action ?? 'artifact.update',
      gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
      artifact_id: existing.artifact_id,
      workspace_id: existing.workspace_id,
      artifact_type: artifact_type,
      _normalized_request: normalizeNode,
      _existing_artifact: existing,
      _spine_update: {
        execution_status: execStatus,
      },
      _gw_debug: {
        ...(normalizeNode._gw_debug ?? {}),
        mutability: 'spine_fields_allowed',
        operation: 'UPDATE',
      }
    }
  }];
}
```

### 2. Switch_Update_Mode — Add spine_fields rule

**Change:** Add a new rule between tags_only and the fallback.

**Before (2 outputs):**
- Output 0: `_update_mode == "tags_only"` → Compute_Tag_Merge
- Fallback: → Switch_Type_For_Update

**After (3 outputs):**
- Output 0: `_update_mode == "tags_only"` → Compute_Tag_Merge
- Output 1: `_update_mode == "spine_fields"` → Prepare_Spine_Field_Update **(NEW)**
- Fallback: → Switch_Type_For_Update

**New rule to add:**

```json
{
  "conditions": {
    "options": {
      "caseSensitive": true,
      "leftValue": "",
      "typeValidation": "strict",
      "version": 3
    },
    "conditions": [
      {
        "leftValue": "={{ $json._update_mode }}",
        "rightValue": "spine_fields",
        "operator": {
          "type": "string",
          "operation": "equals"
        },
        "id": "route-spine-fields"
      }
    ],
    "combinator": "and"
  }
}
```

### 3. Prepare_Spine_Field_Update (NEW Code Node)

**Name:** `NQxb_Artifact_Update_v1__Prepare_Spine_Field_Update`
**Type:** Code (n8n-nodes-base.code, typeVersion 2)
**Position:** [-880, 528]

**Full code:**

```javascript
// NQxb_Artifact_Update_v1__Prepare_Spine_Field_Update
// T64 Scope A: Prepare spine-field PATCH payload for branch/limb/leaf.
// Validation already done in Check_Mutability_Rules (step 6.5).
// Combines execution_status + version increment into single spine PATCH.
// This is more efficient than separate extension + version PATCHes
// because execution_status IS a spine field (not extension).

const existing = $json._existing_artifact;
const spineUpdate = $json._spine_update;

// Compute next version
const currentVersion = typeof existing.version === 'number' ? existing.version : 1;
const nextVersion = currentVersion + 1;

return [{
  json: {
    artifact_id: $json.artifact_id,
    workspace_id: $json.workspace_id,
    artifact_type: $json.artifact_type,
    execution_status: spineUpdate.execution_status,
    next_version: nextVersion,
    _spine_debug: {
      version_before: currentVersion,
      version_after: nextVersion,
      field_updated: 'execution_status',
      new_value: spineUpdate.execution_status,
    }
  }
}];
```

### 4. DB_Update_Spine_Fields (NEW HTTP Request Node)

**Name:** `NQxb_Artifact_Update_v1__DB_Update_Spine_Fields`
**Type:** HTTP Request (n8n-nodes-base.httpRequest, typeVersion 4.2)
**Position:** [-656, 528]

**Configuration:**

| Setting | Value |
|---------|-------|
| Method | PATCH |
| URL | `https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact?artifact_id=eq.{{ $json.artifact_id }}&workspace_id=eq.{{ $json.workspace_id }}` |
| Authentication | Predefined Credential Type |
| Credential Type | Supabase API |
| Credential | `Qwrk Supabase – Kernel v1` (id: n4R4JdOIV9zrCGIT) |
| Body Content Type | JSON |
| JSON Body | `={{ JSON.stringify({ execution_status: $json.execution_status, version: $json.next_version }) }}` |
| On Error | Continue (Error Output) |
| Always Output Data | true |

**Why single PATCH:** Both `execution_status` and `version` are spine fields on `qxb_artifact`. A single PATCH is more atomic and efficient than the project path's two-step pattern (extension PATCH + version PATCH), which is only necessary because project writes to a separate extension table.

### 5. Wiring Changes

**New connections to add:**

```
Switch_Update_Mode output 1 (spine_fields) → Prepare_Spine_Field_Update
Prepare_Spine_Field_Update output 0 → DB_Update_Spine_Fields
DB_Update_Spine_Fields output 0 (success) → Return_Update_Ack
DB_Update_Spine_Fields output 1 (error) → Return_Error_Passthrough
```

**Existing connection to modify:**

```
Switch_Update_Mode fallback → Switch_Type_For_Update
(was output index 1, now output index 2)
```

---

## Manual Steps for Joel (n8n Editor)

### Option A: Import Modified Workflow JSON (Recommended)

1. **Open n8n** in browser
2. **Deactivate** the current `NQxb_Artifact_Update_v1` workflow
3. **Export** current workflow as backup (save as `NQxb_Artifact_Update_v1 (15)__backup.json`)
4. **Import** `workflows/NQxb_Artifact_Update_v1__T64_ScopeA.json`
   - n8n will create this as a new workflow
   - **Important:** The credential references use id `n4R4JdOIV9zrCGIT` — verify this matches your `Qwrk Supabase – Kernel v1` credential
5. **Verify** the imported workflow visually:
   - Check that `Switch_Update_Mode` now shows 3 outputs (tags_only, spine_fields, fallback)
   - Check that `Prepare_Spine_Field_Update` and `DB_Update_Spine_Fields` appear between Switch_Update_Mode and Return_Update_Ack
   - Check that DB_Update_Spine_Fields has error output wired to Return_Error_Passthrough
6. **Activate** the new workflow
7. **Update Gateway** — In `NQxb_Gateway_v1`, update the Execute Workflow node for `artifact.update` to reference the new workflow ID
   - Open `NQxb_Gateway_v1` → find the Execute Workflow node that calls Update
   - Change the workflow reference to the newly imported workflow
8. **Save and activate** Gateway
9. **Export** both workflows (Update + Gateway) for version control
10. **Run regression tests** (see below)

### Option B: Manual Node Editing (If Import Fails)

If the JSON import doesn't work (credential ID mismatch, n8n version differences), apply changes manually:

**Step 1: Edit Check_Mutability_Rules**
1. Open `NQxb_Artifact_Update_v1__Check_Mutability_Rules` node
2. Find the comment `// 7. Mutability checks passed — extension update path`
3. Insert the entire step 6.5 code block (from Section 1 above) BEFORE step 7
4. Save node

**Step 2: Edit Switch_Update_Mode**
1. Open `NQxb_Artifact_Update_v1__Switch_Update_Mode` node
2. Add a new rule: Value = `{{ $json._update_mode }}`, Operation = `equals`, Compare = `spine_fields`
3. Ensure the order is: tags_only (0), spine_fields (1), fallback (2)
4. Save node

**Step 3: Add Prepare_Spine_Field_Update**
1. Add new Code node
2. Name: `NQxb_Artifact_Update_v1__Prepare_Spine_Field_Update`
3. Paste code from Section 3 above
4. Position near Switch_Update_Mode

**Step 4: Add DB_Update_Spine_Fields**
1. Add new HTTP Request node
2. Name: `NQxb_Artifact_Update_v1__DB_Update_Spine_Fields`
3. Configure as per Section 4 table above
4. Set On Error to "Continue (Error Output)"
5. Enable "Always Output Data"

**Step 5: Wire connections**
1. Switch_Update_Mode output 1 → Prepare_Spine_Field_Update
2. Prepare_Spine_Field_Update → DB_Update_Spine_Fields
3. DB_Update_Spine_Fields success → Return_Update_Ack
4. DB_Update_Spine_Fields error → Return_Error_Passthrough
5. Verify Switch_Update_Mode fallback still connects to Switch_Type_For_Update

**Step 6: Save, export, update Gateway, activate (same as Option A steps 6-9)**

---

## Regression Test Checklist

### Pre-Test: Identify Test Artifacts

You need one artifact of each type. Use Gateway `artifact.list` to find existing branch/limb/leaf artifacts, or note their IDs from the Walk tree.

### Test 1: Branch — execution_status update

**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_ARTIFACT_ID>",
  "extension": {
    "execution_status": "in_progress"
  }
}
```

**Expected response:**
```json
{
  "ok": true,
  "gw_action": "artifact.update",
  "operation": "UPDATE",
  "artifact_id": "<BRANCH_ARTIFACT_ID>",
  "artifact_type": "branch",
  "updated_fields": ["execution_status"]
}
```

**Verify:** Query the artifact afterwards — `execution_status` should be `"in_progress"` and `version` should be +1 from before.

### Test 2: Limb — execution_status update

**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "limb",
  "artifact_id": "<LIMB_ARTIFACT_ID>",
  "extension": {
    "execution_status": "not_started"
  }
}
```

**Expected:** Same shape as Test 1. `ok: true`, `updated_fields: ["execution_status"]`.

### Test 3: Leaf — execution_status update

**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "leaf",
  "artifact_id": "<LEAF_ARTIFACT_ID>",
  "extension": {
    "execution_status": "complete"
  }
}
```

**Expected:** Same shape. `ok: true`, `updated_fields: ["execution_status"]`.

### Test 4: Negative — disallowed field (fail-closed validation)

**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_ARTIFACT_ID>",
  "extension": {
    "execution_status": "in_progress",
    "title": "Should Not Work"
  }
}
```

**Expected:**
```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Disallowed fields in extension for branch UPDATE: title",
    "details": {
      "disallowed_fields": ["title"],
      "allowed_fields": ["execution_status"],
      "source": "T64 Scope A"
    }
  }
}
```

### Test 5: Negative — invalid execution_status value

**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "leaf",
  "artifact_id": "<LEAF_ARTIFACT_ID>",
  "extension": {
    "execution_status": "finished"
  }
}
```

**Expected:**
```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid execution_status value: 'finished'",
    "details": {
      "allowed_values": ["not_started", "in_progress", "blocked", "complete"]
    }
  }
}
```

### Test 6: No-regression — tags-only update on branch (must still work)

**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_ARTIFACT_ID>",
  "tags": {
    "add": ["t64-test"],
    "remove": []
  }
}
```

**Expected:** `ok: true`, `operation: "TAG_UPDATE"`. Tags-only path unchanged.

### Test 7: No-regression — project extension update (must still work)

**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<PROJECT_ARTIFACT_ID>",
  "extension": {
    "operational_state": "active"
  }
}
```

**Expected:** `ok: true`, `operation: "UPDATE"`. Project extension path unchanged.

---

## Success Criteria

- [ ] Branch execution_status update succeeds (Test 1)
- [ ] Limb execution_status update succeeds (Test 2)
- [ ] Leaf execution_status update succeeds (Test 3)
- [ ] Unknown extension keys rejected with VALIDATION_ERROR (Test 4)
- [ ] Invalid execution_status values rejected with VALIDATION_ERROR (Test 5)
- [ ] Tags-only path still works for branch (Test 6)
- [ ] Project extension update still works (Test 7)
- [ ] Version increments by exactly +1 on successful updates
- [ ] No UPDATE_NOT_IMPLEMENTED errors for branch/limb/leaf with execution_status

---

## Scope Boundaries (What This Does NOT Do)

- Does NOT add new tables or columns
- Does NOT expand mutability policy beyond execution_status
- Does NOT touch journal/snapshot/restart rules
- Does NOT modify the project update path
- Does NOT implement title/priority/summary mutations (future T64 scopes)
- Does NOT implement lifecycle_status changes (promote-only)
- Does NOT handle combined tags + extension updates (existing limitation, consistent with project behavior — tags are silently dropped when extension is also present)

---

## Deployment Checklist (per CLAUDE.md)

1. [ ] Archive current Update workflow version to `workflows/Archive/`
2. [ ] Import T64 Scope A workflow JSON (or apply manual edits)
3. [ ] Save with incremented version number
4. [ ] Update Gateway `NQxb_Gateway_v1` Execute Workflow node to reference new Update workflow ID
5. [ ] Export updated Gateway with incremented version
6. [ ] Import BOTH workflows to n8n (sub-workflow first, then Gateway)
7. [ ] Activate both
8. [ ] Run regression tests (Tests 1-7 above)
9. [ ] Run Phase 2C Certification Harness if available

---

## Version

- Update sub-workflow: v36 → v37 (T64 Scope A)
- Gateway: v58 → v59 (workflow reference update only)

---

End of guide.
