# Type Registry Guard — Implementation Spec

**Date:** 2026-01-20
**Version:** 1.0
**Status:** Ready for Implementation
**Target Workflows:** Save_v1, Update_v1, Promote_v1

---

## Overview

This spec adds a **Type Registry Guard** to all write-capable Gateway actions. The guard queries `qxb_artifact_type_registry` before allowing write operations to proceed.

**Error code:** `ARTIFACT_TYPE_NOT_ALLOWED`
**Fail-closed:** If registry lookup fails or returns no rows, reject the request.

---

## 1. Changes Required per Workflow

### 1.1 NQxb_Artifact_Save_v1

**Current hardcoded allow-list (REMOVE):**
```javascript
// In NQxb_Artifact_Save_v1__Validate_Request node
const validTypes = ['project', 'journal', 'restart', 'snapshot', 'grass', 'thorn', 'forest', 'thicket', 'flower'];
if (!validTypes.includes(artifact_type)) {
  errors.push({...});
}
```

**Action:** Remove lines 36-43 from `NQxb_Artifact_Save_v1__Validate_Request` (the artifact_type allow-list check).

**Insert new nodes between:** `Switch` (ok path, output 1) → `Switch_InsertOrUpdate`

### 1.2 NQxb_Artifact_Update_v1

**Current hardcoded allow-list (REMOVE):**
```javascript
// In NQxb_Artifact_Update_v1__Validate_Request node
const TYPE_ALLOWLIST = new Set(["project", "journal", "restart", "snapshot"]);
```

**Action:** Remove lines 4 and 14-21 from `NQxb_Artifact_Update_v1__Validate_Request`.

**Insert new nodes between:** `Guard_Error_ShortCircuit` (ok path, output false) → `Fetch_Existing_Spine`

### 1.3 NQxb_Artifact_Promote_v1

**Current state:** No hardcoded allow-list visible in Normalize_request.

**Insert new nodes between:** `Normalize_request` (ok path) → `Resolve_Transition`

---

## 2. New Nodes to Add (All Workflows)

Add these 3 nodes to each workflow. Adjust positions per workflow layout.

### Node A: Type Registry Lookup (Supabase)

```json
{
  "parameters": {
    "operation": "get",
    "tableId": "qxb_artifact_type_registry",
    "filters": {
      "conditions": [
        {
          "keyName": "artifact_type",
          "keyValue": "={{ $node['PREVIOUS_NODE'].json.artifact_type }}"
        }
      ]
    }
  },
  "type": "n8n-nodes-base.supabase",
  "typeVersion": 1,
  "position": [POSITION_X, POSITION_Y],
  "id": "GENERATE_NEW_UUID",
  "name": "WORKFLOW_PREFIX__Lookup_Type_Registry",
  "alwaysOutputData": true,
  "credentials": {
    "supabaseApi": {
      "id": "n4R4JdOIV9zrCGIT",
      "name": "Qwrk Supabase – Kernel v1"
    }
  }
}
```

**Note:** Replace `PREVIOUS_NODE` with the node that outputs the validated request.

### Node B: Type Registry Guard (Code)

```json
{
  "parameters": {
    "jsCode": "// Type Registry Guard\n// Check artifact type against qxb_artifact_type_registry\n// Error code: ARTIFACT_TYPE_NOT_ALLOWED\n// Fail-closed: no row or disabled = reject\n\n// Get original request from the previous validation node\nconst originalRequest = $node['VALIDATION_OUTPUT_NODE'].json;\n\n// Get registry lookup result (may be empty if no row found)\nconst registryRow = $json;\n\nconst artifact_type = originalRequest.artifact_type;\n\n// FAIL-CLOSED: No row found = type not registered\nif (!registryRow || !registryRow.artifact_type) {\n  return [{\n    json: {\n      ok: false,\n      _gw_route: 'error',\n      gw_action: originalRequest.gw_action ?? 'artifact.save',\n      gw_workspace_id: originalRequest.gw_workspace_id ?? null,\n      artifact_type: artifact_type,\n      artifact_id: originalRequest.artifact_id ?? null,\n      error: {\n        code: 'ARTIFACT_TYPE_NOT_ALLOWED',\n        message: `Artifact type '${artifact_type}' is not allowed`,\n        details: {\n          artifact_type: artifact_type,\n          reason: 'not_registered',\n          hint: 'Type must be registered in qxb_artifact_type_registry'\n        }\n      },\n      timestamp: new Date().toISOString()\n    }\n  }];\n}\n\n// Type found but disabled\nif (registryRow.enabled === false) {\n  return [{\n    json: {\n      ok: false,\n      _gw_route: 'error',\n      gw_action: originalRequest.gw_action ?? 'artifact.save',\n      gw_workspace_id: originalRequest.gw_workspace_id ?? null,\n      artifact_type: artifact_type,\n      artifact_id: originalRequest.artifact_id ?? null,\n      error: {\n        code: 'ARTIFACT_TYPE_NOT_ALLOWED',\n        message: `Artifact type '${artifact_type}' is not allowed`,\n        details: {\n          artifact_type: artifact_type,\n          reason: 'disabled',\n          registry_enabled: false,\n          hint: 'Type is registered but currently disabled'\n        }\n      },\n      timestamp: new Date().toISOString()\n    }\n  }];\n}\n\n// Type is registered and enabled - pass through original request\nreturn [{ json: originalRequest }];\n"
  },
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [POSITION_X, POSITION_Y],
  "id": "GENERATE_NEW_UUID",
  "name": "WORKFLOW_PREFIX__Type_Registry_Guard"
}
```

**Note:** Replace `VALIDATION_OUTPUT_NODE` with the correct node name per workflow.

### Node C: Type Registry Switch (Switch)

```json
{
  "parameters": {
    "rules": {
      "values": [
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
                "leftValue": "={{ $json.ok }}",
                "rightValue": false,
                "operator": {
                  "type": "boolean",
                  "operation": "equals"
                },
                "id": "registry-error"
              }
            ],
            "combinator": "and"
          }
        },
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
                "id": "registry-ok",
                "leftValue": "={{ $json.ok }}",
                "rightValue": true,
                "operator": {
                  "type": "boolean",
                  "operation": "equals"
                }
              }
            ],
            "combinator": "and"
          }
        }
      ]
    },
    "options": {}
  },
  "type": "n8n-nodes-base.switch",
  "typeVersion": 3.4,
  "position": [POSITION_X, POSITION_Y],
  "id": "GENERATE_NEW_UUID",
  "name": "WORKFLOW_PREFIX__Switch_Type_Registry"
}
```

---

## 3. Connection Changes

### 3.1 NQxb_Artifact_Save_v1

**BEFORE:**
```
Switch (output 1) → Switch_InsertOrUpdate
```

**AFTER:**
```
Switch (output 1) → Lookup_Type_Registry → Type_Registry_Guard → Switch_Type_Registry
Switch_Type_Registry (output 0: error) → [no connection, returns error]
Switch_Type_Registry (output 1: ok) → Switch_InsertOrUpdate
```

**Positions (suggested):**
- Lookup_Type_Registry: [970, 750]
- Type_Registry_Guard: [970, 944]
- Switch_Type_Registry: [1050, 944]

### 3.2 NQxb_Artifact_Update_v1

**BEFORE:**
```
Guard_Error_ShortCircuit (output false: ok) → Fetch_Existing_Spine
```

**AFTER:**
```
Guard_Error_ShortCircuit (output false: ok) → Lookup_Type_Registry → Type_Registry_Guard → Switch_Type_Registry
Switch_Type_Registry (output 0: error) → [no connection, returns error]
Switch_Type_Registry (output 1: ok) → Fetch_Existing_Spine
```

**Positions (suggested):**
- Lookup_Type_Registry: [750, -200]
- Type_Registry_Guard: [750, -32]
- Switch_Type_Registry: [830, -32]

### 3.3 NQxb_Artifact_Promote_v1

**BEFORE:**
```
Normalize_request → Resolve_Transition
```

**AFTER:**
```
Normalize_request → Lookup_Type_Registry → Type_Registry_Guard → Switch_Type_Registry
Switch_Type_Registry (output 0: error) → [no connection, returns error]
Switch_Type_Registry (output 1: ok) → Resolve_Transition
```

**Positions (suggested):**
- Lookup_Type_Registry: [-50, -200]
- Type_Registry_Guard: [-50, -48]
- Switch_Type_Registry: [100, -48]

---

## 4. Validate_Request Changes

### 4.1 NQxb_Artifact_Save_v1__Validate_Request

**REMOVE this block (lines ~36-43):**
```javascript
// Validate artifact_type allowed list
if (isNonEmptyString(req.artifact_type)) {
  const validTypes = ['project', 'journal', 'restart', 'snapshot', 'grass', 'thorn', 'forest', 'thicket', 'flower'];
  if (!validTypes.includes(artifact_type)) {
    errors.push({
      field: 'artifact_type',
      reason: `must be one of: ${validTypes.join(', ')}`,
      received: req.artifact_type
    });
  }
}
```

**KEEP:** The check for `artifact_type` being required (non-empty string).

### 4.2 NQxb_Artifact_Update_v1__Validate_Request

**REMOVE this block (line ~4 and lines ~14-21):**
```javascript
const TYPE_ALLOWLIST = new Set(["project", "journal", "restart", "snapshot"]);

// ...and later...

} else if (!TYPE_ALLOWLIST.has(req.artifact_type.trim())) {
  errors.push({
    field: "artifact_type",
    reason: "not_allowed",
    received: req.artifact_type,
    allowed: Array.from(TYPE_ALLOWLIST),
  });
}
```

**KEEP:** The check for `artifact_type` being required (non-empty string).

---

## 5. Test Payloads

### Test 1: Enabled Type — Pass (project)

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "project",
  "title": "Registry Test - Enabled Type",
  "extension": {
    "lifecycle_stage": "seed"
  }
}
```

**Expected:** Proceeds to save, returns `ok: true`

---

### Test 2: Disabled Type — Fail (journal after disabling)

**Setup:** `UPDATE qxb_artifact_type_registry SET enabled = false WHERE artifact_type = 'journal';`

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "journal",
  "title": "Registry Test - Disabled Type",
  "extension": {
    "entry_text": "This should be rejected"
  }
}
```

**Expected:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "ARTIFACT_TYPE_NOT_ALLOWED",
    "message": "Artifact type 'journal' is not allowed",
    "details": {
      "artifact_type": "journal",
      "reason": "disabled",
      "registry_enabled": false
    }
  }
}
```

**Cleanup:** `UPDATE qxb_artifact_type_registry SET enabled = true WHERE artifact_type = 'journal';`

---

### Test 3: Missing Type — Fail (instruction_pack)

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "instruction_pack",
  "title": "Registry Test - Unregistered Type",
  "content": {
    "scope": "global"
  }
}
```

**Expected:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "ARTIFACT_TYPE_NOT_ALLOWED",
    "message": "Artifact type 'instruction_pack' is not allowed",
    "details": {
      "artifact_type": "instruction_pack",
      "reason": "not_registered"
    }
  }
}
```

---

### Test 4: Update with Disabled Type — Fail

**Setup:** `UPDATE qxb_artifact_type_registry SET enabled = false WHERE artifact_type = 'project';`

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "4d635ed1-59f0-4360-9199-bd4962baf61d",
  "extension": {
    "operational_state": "paused"
  }
}
```

**Expected:** `ARTIFACT_TYPE_NOT_ALLOWED` with `reason: "disabled"`

**Cleanup:** `UPDATE qxb_artifact_type_registry SET enabled = true WHERE artifact_type = 'project';`

---

### Test 5: Promote with Disabled Type — Fail

**Setup:** `UPDATE qxb_artifact_type_registry SET enabled = false WHERE artifact_type = 'project';`

```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "4d635ed1-59f0-4360-9199-bd4962baf61d",
  "artifact_payload": {
    "transition": "seed_to_sapling",
    "reason": "Registry guard test"
  }
}
```

**Expected:** `ARTIFACT_TYPE_NOT_ALLOWED` with `reason: "disabled"`

**Cleanup:** `UPDATE qxb_artifact_type_registry SET enabled = true WHERE artifact_type = 'project';`

---

## 6. KGB Proof Set

After implementation, execute these tests and record results:

| Test | Workflow | Type | Registry State | Expected Code | Actual Code | Pass? |
|------|----------|------|----------------|---------------|-------------|-------|
| 1 | Save | project | enabled | (success) | | |
| 2 | Save | journal | disabled | ARTIFACT_TYPE_NOT_ALLOWED | | |
| 3 | Save | instruction_pack | missing | ARTIFACT_TYPE_NOT_ALLOWED | | |
| 4 | Update | project | disabled | ARTIFACT_TYPE_NOT_ALLOWED | | |
| 5 | Promote | project | disabled | ARTIFACT_TYPE_NOT_ALLOWED | | |
| 6 | Query | journal | disabled | (success - reads allowed) | | |
| 7 | List | journal | disabled | (success - reads allowed) | | |

---

## 7. Implementation Order

1. **Backup current workflows** (archive with timestamp)
2. **Add nodes to Save_v1** (test independently)
3. **Add nodes to Update_v1** (test independently)
4. **Add nodes to Promote_v1** (test independently)
5. **Remove hardcoded allow-lists** from Validate_Request nodes
6. **Execute KGB proof set**
7. **Export updated workflow JSONs**

---

## 8. Rollback Plan

If issues discovered:
1. Re-import archived workflow JSONs
2. Registry table can remain (non-destructive)
3. Re-add hardcoded allow-lists if needed

---

**End of Implementation Spec**
