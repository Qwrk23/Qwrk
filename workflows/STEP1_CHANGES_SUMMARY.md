# Gateway Step 1 Fix — Change Summary

**File:** `NQxb_Gateway_v1__STEP1_CORRECTED.json`
**Date:** 2026-01-10
**Purpose:** Fix artifact.save response shaping to return correct, non-null fields

---

## Problem Fixed

artifact.save INSERT succeeds, but final Gateway response incorrectly returns:
- `artifact_type = null`
- `workspace_id = null`
- `extension.payload = {}` (for restart/snapshot)

**Root cause:** Execute Workflow node replaces `$json` entirely with sub-workflow output, losing parent request context.

---

## Solution Pattern

**Freeze → Split → Call → Tag → Merge → Shape → Respond**

1. Freeze request context BEFORE calling Save sub-workflow
2. Split flow: one path calls Save, other bypasses to Merge
3. Tag both results with `_merge_role` for deterministic selection
4. Merge tagged results
5. Shape final response from frozen context + Save result
6. Respond with correct, complete response envelope

---

## Changes Made

### 1. MODIFIED: `NQxb_Gateway_v1__Normalize_Request`

**Added freezing for Save operations:**
```javascript
extension: asObj(req.extension),

// IMPORTANT: freeze request intent so it survives later nodes that overwrite $json
// (e.g., Supabase "Get row" returning the artifact row, Execute Workflow replacing $json)
req_artifact_type: req.artifact_type ?? null,
req_artifact_id: req.artifact_id ?? null,
req_workspace_id: req.gw_workspace_id ?? null,  // NEW
req_extension: asObj(req.extension),             // NEW
```

**Why:** Preserve workspace_id and extension payload through Execute Workflow replacement.

---

### 2. NEW: `NQxb_Gateway__Freeze_Save_Context`

**Position:** Between `Switch_Action` (Save output) and `Call 'NQxb_Artifact_Save_v1'`

**Purpose:** Freeze request fields and tag for deterministic merge

**Code:**
```javascript
return [{
  json: {
    ...$json,
    _merge_role: "frozen_context",
    _frozen_artifact_type: $json.req_artifact_type ?? $json.artifact_type ?? null,
    _frozen_workspace_id: $json.req_workspace_id ?? $json.gw_workspace_id ?? null,
    _frozen_extension: $json.req_extension ?? $json.extension ?? {},
  }
}];
```

**Connections OUT (splits to TWO destinations):**
- Path 1: → `Call 'NQxb_Artifact_Save_v1'`
- Path 2: → `NQxb_Gateway__Merge_Save_Context` (input 1, bypass)

---

### 3. UNCHANGED: `Call 'NQxb_Artifact_Save_v1'`

**Now receives input from:** `NQxb_Gateway__Freeze_Save_Context`
**Sends output to:** `NQxb_Gateway__Tag_Save_Result` (NEW)

---

### 4. NEW: `NQxb_Gateway__Tag_Save_Result`

**Position:** After `Call 'NQxb_Artifact_Save_v1'`

**Purpose:** Tag Save sub-workflow result for deterministic merge

**Code:**
```javascript
return [{
  json: {
    ...$json,
    _merge_role: "save_result"
  }
}];
```

**Connections OUT:**
- → `NQxb_Gateway__Merge_Save_Context` (input 0)

---

### 5. NEW: `NQxb_Gateway__Merge_Save_Context`

**Type:** `n8n-nodes-base.merge`
**Mode:** `combine` / `mergeByPosition`

**Purpose:** Combine Save result + frozen context for response shaping

**Inputs:**
- Input 0: From `NQxb_Gateway__Tag_Save_Result` (tagged save_result)
- Input 1: From `NQxb_Gateway__Freeze_Save_Context` (tagged frozen_context, bypass)

**Connections OUT:**
- → `NQxb_Gateway__Shape_Save_Response`

---

### 6. NEW: `NQxb_Gateway__Shape_Save_Response`

**Position:** After `NQxb_Gateway__Merge_Save_Context`

**Purpose:** Build final response from tagged merge items (deterministic)

**Code:**
```javascript
const items = $input.all();

// Find Save_v1 result by tag (DETERMINISTIC)
const saveResult = items.find(item => item.json._merge_role === "save_result");
if (!saveResult) {
  return [{ json: { ok: false, error: { code: "MERGE_ERROR", message: "Could not find Save_v1 result in merge", details: { item_count: items.length } } } }];
}

// Find frozen context by tag (DETERMINISTIC)
const context = items.find(item => item.json._merge_role === "frozen_context");
if (!context) {
  return [{ json: { ok: false, error: { code: "MERGE_ERROR", message: "Could not find frozen context in merge", details: { item_count: items.length } } } }];
}

// Extract from Save_v1 result
const artifact_id = saveResult.json.artifact_id ?? null;
const operation = saveResult.json.operation ?? "INSERT";

// Extract from frozen context (ALWAYS use frozen, never trust Save_v1 for these)
const artifact_type = context.json._frozen_artifact_type;
const workspace_id = context.json._frozen_workspace_id;
const extension_payload = context.json._frozen_extension?.payload ?? {};

// Build complete response
const response = {
  ok: true,
  gw_action: "artifact.save",
  artifact_id,
  artifact_type,
  workspace_id,
  operation,
  timestamp: new Date().toISOString(),
};

// For restart/snapshot, include extension payload that was saved
if (artifact_type === "restart" || artifact_type === "snapshot") {
  response.extension = {
    payload: extension_payload
  };
}

return [{ json: response }];
```

**Why deterministic:** Uses explicit `_merge_role` tags, not heuristics like artifact_id presence.

**Connections OUT:**
- → `NQxb_Gateway__Respond_Save_Success`

---

### 7. NEW: `NQxb_Gateway__Respond_Save_Success`

**Type:** `n8n-nodes-base.respondToWebhook`

**Purpose:** Dedicated Save response node (NOT shared with Query)

**Code:**
```json
{
  "respondWith": "json",
  "responseBody": "={{ JSON.stringify($json) }}",
  "options": {}
}
```

**Why separate:** Save response contract differs from Query response contract.

---

## What Did NOT Change (Scope Compliance)

✅ **Query branch:** Byte-for-byte unchanged
✅ **List branch:** Byte-for-byte unchanged (output 1 still empty)
✅ **Error Response:** Byte-for-byte unchanged
✅ **Respond_Query_Success:** Byte-for-byte unchanged
✅ **Gatekeeper:** Unchanged
✅ **Switch nodes:** Unchanged (only connection from Switch_Action output 2 changed)
✅ **Supabase schemas:** Not touched
✅ **RLS policies:** Not touched
✅ **artifact.query behavior:** Not touched

---

## Connection Changes Summary

### OLD (BROKEN):
```
Switch_Action (Save, output 2)
  → Call 'NQxb_Artifact_Save_v1'
  → Respond_Query_Success (WRONG - uses Query responder!)
```

### NEW (FIXED):
```
Switch_Action (Save, output 2)
  → Freeze_Save_Context (splits)
    → Call 'NQxb_Artifact_Save_v1' → Tag_Save_Result → Merge (input 0)
    → Merge (input 1, bypass)
  → Shape_Save_Response
  → Respond_Save_Success
```

---

## Required Success Response Contract (Now Met)

On successful INSERT, response includes:
- ✅ `ok: true`
- ✅ `gw_action: "artifact.save"`
- ✅ `artifact_id` (from Save_v1 result)
- ✅ `artifact_type` (from frozen request)
- ✅ `workspace_id` (from frozen request)
- ✅ `operation` (from Save_v1 result)
- ✅ `timestamp` (generated)
- ✅ `extension.payload` (for restart/snapshot, from frozen request)

---

## Next Steps (Before You Import)

1. **Review this change summary**
2. **Workflow ID references verified:**
   - Save sub-workflow ID: `"g0zpVK0sesavO4JA"` ✅ (updated from Downloads/NQxb_Artifact_Save_v1.json)
   - Query sub-workflow ID: `"IsLBYjXJ5R2Djfrv"` ✅ (unchanged from original)
3. **Import `NQxb_Gateway_v1__STEP1_CORRECTED.json` to n8n**
4. **Run regression tests:**
   - artifact.query KGB tests (project/journal/snapshot/restart)
   - artifact.save INSERT test for restart
   - Confirm all required fields are non-null
   - Confirm payload is preserved
5. **Report results**

---

## Revert Procedure (If Needed)

If any regression appears:
1. Re-import original `NQxb_Gateway_v1.json` from workflows directory
2. Report which test failed
3. STOP (per Step 1 hard stop instruction)

---

**END OF STEP 1 CHANGES**
