# Gateway Workflow Fixes - Restart Prompt

**Type:** Restart Prompt
**Created:** 2026-01-24
**Context:** Gateway v1 Test Harness revealed workflow connection bugs
**Scope:** Fix dead-end connections in Update, Promote, and Save subworkflows

---

## Background Context

Gateway v1 test results showed:
- **QUERY:** 7/7 PASSED
- **LIST:** 10/10 PASSED
- **SAVE:** 5/8 PARTIAL (returns `artifact_id: null`)
- **UPDATE:** 0/7 FAILED (returns empty string `""`)
- **PROMOTE:** 0/5 FAILED (returns empty string `""`)

Root cause analysis identified **dead-end workflow connections** where error paths or terminal nodes are not wired, causing n8n to return empty output to the Gateway.

---

## Workflow Files Reference

| Workflow | File | n8n ID |
|----------|------|--------|
| Gateway | `NQxb_Gateway_v1 (27).json` | D1NWfUWZ9IFDVqNB |
| Update | `NQxb_Artifact_Update_v1.json` | 0648bPAenHiR5ixy |
| Promote | `NQxb_Artifact_Promote_v1.json` | nP9KyhnjqYOKQRiA |
| Save | `NQxb_Artifact_Save_v1.json` | g0zpVK0sesavO4JA |

---

## FIX 1: Update Workflow (CRITICAL)

### Problem
The `NQxb_Artifact_Update_v1__Switch_Type_Registry` node has TWO outputs:
- Output 0 (top): Error path (when `ok === false`)
- Output 1 (bottom): Success path (when `ok === true`)

**The error path (Output 0) is NOT CONNECTED to anything.** When the Type Registry Guard returns an error, the workflow dead-ends and returns nothing.

### Steps to Fix

1. **Open n8n** and navigate to workflow `NQxb_Artifact_Update_v1`

2. **Locate the Switch node** named `NQxb_Artifact_Update_v1__Switch_Type_Registry`
   - Position: approximately [830, -32] on the canvas
   - It's between `Type_Registry_Guard` and `Fetch_Existing_Spine`

3. **Identify the outputs:**
   - The switch has 2 outputs
   - Output 0 (top connector): triggers when `ok === false` (registry error)
   - Output 1 (bottom connector): triggers when `ok === true` (continue normally)
   - Currently, Output 1 connects to `Fetch_Existing_Spine`
   - **Output 0 has no connection** (this is the bug)

4. **Create the error connection:**
   - Click and drag from Output 0 of `Switch_Type_Registry`
   - Connect it to the input of `NQxb_Artifact_Update_v1__Return_Update_Ack`
   - This node is at approximately [2560, -208]

5. **Verify the connection:**
   - The error path should now flow: `Type_Registry_Guard` → `Switch_Type_Registry` (error output) → `Return_Update_Ack`
   - This ensures Type Registry errors produce a proper JSON response

6. **Save the workflow** (Ctrl+S or click Save)

### Expected Result
When Type Registry Guard returns an error (type not registered or disabled), the workflow will now return the error JSON instead of empty string.

---

## FIX 2: Promote Workflow (CRITICAL - Multiple Issues)

### Problem A: Type Registry Error Path Dead-End

The `Switch_Type_Registry` node error output is not connected.

### Steps to Fix Problem A

1. **Open n8n** and navigate to workflow `NQxb_Artifact_Promote_v1`

2. **Locate the Switch node** named `Switch_Type_Registry`
   - Position: approximately [352, -48]
   - It's between `Type_Registry_Guard` and `Resolve_Transition`

3. **Identify the outputs:**
   - Output 0 (labeled "ok"): Success path → connects to `Resolve_Transition`
   - Output 1 (labeled "error"): Error path → **NOT CONNECTED** (bug)

4. **Create the error connection:**
   - Click and drag from Output 1 ("error") of `Switch_Type_Registry`
   - Connect it to the input of `NQxb_Artifact_Promote_v1__Return_Error_Item`
   - This node is at approximately [1568, 48]

5. **Save** (but don't close yet - more fixes needed)

---

### Problem B: Query Call Not Connected (Orphaned Node)

The `Call 'NQxb_Artifact_Query_v1'` node exists but is **completely disconnected** from the flow. The `Build_Query_Request` node that should feed it has no output connection.

### Steps to Fix Problem B

1. **Locate** `NQxb_Artifact_Promote_v1__Build_Query_Request`
   - Position: approximately [2224, -48]
   - This node builds the query request after promote succeeds

2. **Locate** `Call 'NQxb_Artifact_Query_v1'`
   - Position: approximately [2512, -48]
   - This is an Execute Workflow node that calls the Query subworkflow

3. **Connect them:**
   - Click and drag from the output of `Build_Query_Request`
   - Connect it to the input of `Call 'NQxb_Artifact_Query_v1'`

4. **Save** (but don't close yet - one more fix)

---

### Problem C: No Terminal Output Node

Even after fixing Problem B, the Query call output goes nowhere. We need a terminal node that shapes and returns the final response.

### Steps to Fix Problem C

1. **Create a new Code node** for shaping the promote response:
   - Click the "+" button or drag a Code node onto the canvas
   - Position it to the right of `Call 'NQxb_Artifact_Query_v1'` (around [2736, -48])
   - Name it: `NQxb_Artifact_Promote_v1__Shape_Response`

2. **Configure the Code node** with this JavaScript:

```javascript
// NQxb_Artifact_Promote_v1__Shape_Response
// Shape the final promote response from Query result

const queryResult = $json ?? {};

// If query returned an error, pass it through
if (queryResult.ok === false || queryResult._gw_route === "error") {
  return [{ json: queryResult }];
}

// Extract artifact from query response
const artifact = queryResult.data?.artifact ?? queryResult;

// Build promote-specific response
return [{
  json: {
    ok: true,
    gw_action: "artifact.promote",
    data: { artifact },
    _promote_completed: true,
    timestamp: new Date().toISOString()
  }
}];
```

3. **Connect the flow:**
   - Connect output of `Call 'NQxb_Artifact_Query_v1'` → input of `Shape_Response`

4. **Verify the complete flow:**
   - `Merge_Verify` → `Build_Query_Request` → `Call 'NQxb_Artifact_Query_v1'` → `Shape_Response`

5. **Save the workflow**

---

### Problem D: Event Insert Dead-End (Optional Fix)

The `DB_Insert_Event` node output goes nowhere. This is less critical (it's a side-effect write), but for cleanliness:

1. **Locate** `NQxb_Artifact_Promote_v1__DB_Insert_Event`
   - Position: approximately [1776, 176]

2. **Note:** This node runs in parallel with the main flow (branched from `Switch_OK`). Its output doesn't need to feed the response. However, if you want to capture any DB errors, you could connect it to a logging node. **For now, this can remain as-is** since the event insert is fire-and-forget.

---

## FIX 3: Save Workflow (MODERATE)

### Problem
The Save workflow returns `artifact_id: null` because the artifact ID gets lost during the Merge operation. The issue is in how `Build_Response_Context` captures the ID.

### Steps to Fix

1. **Open n8n** and navigate to workflow `NQxb_Artifact_Save_v1`

2. **Locate** `NQxb_Artifact_Save_v1__Build_Response_Context`
   - Position: approximately [3360, 0]
   - This node runs after `Normalize_Saved_ID` and feeds the Merge

3. **Review the current code** - look for this section:
```javascript
// Saved artifact id (post spine insert)
const saved_artifact_id =
  j.saved_artifact_id ??
  j.artifact_id ??
  null;
```

4. **The issue:** The node receives data from `Normalize_Saved_ID` via `$json`, but the lookup chain might be wrong. The `saved_artifact_id` should come from the upstream node.

5. **Update the code** to explicitly reference the correct upstream node:

Find this line:
```javascript
const j = $json ?? {};
```

Change it to:
```javascript
const j = $json ?? {};
const savedIdNode = $node["NQxb_Artifact_Save_v1__Normalize_Saved_ID"]?.json ?? {};
```

Then update the artifact_id resolution:
```javascript
// Saved artifact id (post spine insert)
const saved_artifact_id =
  savedIdNode.saved_artifact_id ??
  j.saved_artifact_id ??
  j.artifact_id ??
  null;
```

6. **Save the workflow**

---

## Verification Steps

After completing all fixes:

### 1. Test Update Workflow Directly

In n8n, use the workflow's pinned test data or create a test execution:

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "fe176f19-cfd2-4843-89c1-0853f04781c8",
  "extension": {
    "operational_state": "active",
    "state_reason": "Test update via fixed workflow"
  }
}
```

**Expected:** JSON response with `ok: true` or proper error envelope (not empty string)

### 2. Test Promote Workflow Directly

```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "fe176f19-cfd2-4843-89c1-0853f04781c8",
  "artifact_payload": {
    "transition": "seed_to_sapling",
    "reason": "Test promote via fixed workflow"
  }
}
```

**Expected:** JSON response with promoted artifact data (not empty string)

### 3. Run Gateway Test Harness

From PowerShell:
```powershell
cd "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"
.\docs\testing\run-tests.ps1 -Password "aslfja'wwe*(#fhwoII843ghlw_ek2l" -TestSuite "All"
```

**Expected Results:**
- QUERY: 7/7 PASSED
- LIST: 10/10 PASSED
- SAVE: 8/8 PASSED (including artifact_id present)
- UPDATE: 7/7 PASSED
- PROMOTE: 5/5 PASSED

---

## Summary Checklist

- [ ] **Update Workflow:** Connect `Switch_Type_Registry` output 0 → `Return_Update_Ack`
- [ ] **Promote Workflow:** Connect `Switch_Type_Registry` output 1 → `Return_Error_Item`
- [ ] **Promote Workflow:** Connect `Build_Query_Request` → `Call 'NQxb_Artifact_Query_v1'`
- [ ] **Promote Workflow:** Create `Shape_Response` node and connect after Query call
- [ ] **Save Workflow:** Update `Build_Response_Context` to reference `Normalize_Saved_ID` node explicitly
- [ ] **Verify:** Run test harness and confirm all 37 tests pass

---

## Notes

- All workflow changes should be exported and saved to the `workflows/` directory after verification
- Archive the current (broken) versions with `__SUPERSEDED__` suffix before overwriting
- Update the workflow version IDs in the JSON files after changes
