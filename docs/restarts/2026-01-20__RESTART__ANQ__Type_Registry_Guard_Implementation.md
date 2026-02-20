# RESTART — ANQ: Type Registry Guard Implementation

**Date:** 2026-01-20
**Status:** Ready for implementation
**Owner:** ANQ (AAA_New_Qwrk)
**Prepared by:** Claude Code (CC)

---

## Context

The Artifact Type Registry v1 has been deployed to Supabase. Gateway workflows now need to query this registry before allowing write operations.

**Registry table:** `qxb_artifact_type_registry`
**Seeded types (7):** project, journal, snapshot, restart, forest, thicket, flower
**All enabled:** true

---

## Objective

Add a **Type Registry Guard** to these write-capable workflows:
- NQxb_Artifact_Save_v1
- NQxb_Artifact_Update_v1
- NQxb_Artifact_Promote_v1

The guard must:
1. Query `qxb_artifact_type_registry` by `artifact_type`
2. If no row → reject with `ARTIFACT_TYPE_NOT_ALLOWED`, reason: `not_registered`
3. If row with `enabled = false` → reject with `ARTIFACT_TYPE_NOT_ALLOWED`, reason: `disabled`
4. If row with `enabled = true` → allow flow to continue

**Read operations (Query, List) are NOT affected.** Disabled types remain queryable/listable.

---

## Implementation Spec

**Full spec location:** `workflows/changelogs/Type_Registry_Guard__Implementation_Spec.md`

### Summary per Workflow

| Workflow | Remove | Add | Insert Between |
|----------|--------|-----|----------------|
| Save_v1 | `validTypes` array in Validate_Request | 3 nodes | `Switch` → `Switch_InsertOrUpdate` |
| Update_v1 | `TYPE_ALLOWLIST` Set in Validate_Request | 3 nodes | `Guard_Error_ShortCircuit` → `Fetch_Existing_Spine` |
| Promote_v1 | (none) | 3 nodes | `Normalize_request` → `Resolve_Transition` |

### Nodes to Add (per workflow)

1. **Lookup_Type_Registry** (Supabase node)
   - Operation: get
   - Table: `qxb_artifact_type_registry`
   - Filter: `artifact_type = $json.artifact_type`
   - alwaysOutputData: true

2. **Type_Registry_Guard** (Code node)
   - Check registry result
   - Return error envelope or pass through original request

3. **Switch_Type_Registry** (Switch node)
   - Output 0: `ok === false` → (error, no connection)
   - Output 1: `ok === true` → continue to next node

---

## Error Envelope

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "ARTIFACT_TYPE_NOT_ALLOWED",
    "message": "Artifact type 'X' is not allowed",
    "details": {
      "artifact_type": "X",
      "reason": "not_registered" | "disabled"
    }
  }
}
```

---

## Guard Code (Template)

```javascript
// Type Registry Guard
// Check artifact type against qxb_artifact_type_registry

// Get original request from the previous validation node
const originalRequest = $node['VALIDATION_OUTPUT_NODE'].json;

// Get registry lookup result
const registryRow = $json;

const artifact_type = originalRequest.artifact_type;

// FAIL-CLOSED: No row = not registered
if (!registryRow || !registryRow.artifact_type) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: originalRequest.gw_action,
      gw_workspace_id: originalRequest.gw_workspace_id,
      artifact_type: artifact_type,
      artifact_id: originalRequest.artifact_id ?? null,
      error: {
        code: 'ARTIFACT_TYPE_NOT_ALLOWED',
        message: `Artifact type '${artifact_type}' is not allowed`,
        details: {
          artifact_type: artifact_type,
          reason: 'not_registered'
        }
      },
      timestamp: new Date().toISOString()
    }
  }];
}

// Type disabled
if (registryRow.enabled === false) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: originalRequest.gw_action,
      gw_workspace_id: originalRequest.gw_workspace_id,
      artifact_type: artifact_type,
      artifact_id: originalRequest.artifact_id ?? null,
      error: {
        code: 'ARTIFACT_TYPE_NOT_ALLOWED',
        message: `Artifact type '${artifact_type}' is not allowed`,
        details: {
          artifact_type: artifact_type,
          reason: 'disabled',
          registry_enabled: false
        }
      },
      timestamp: new Date().toISOString()
    }
  }];
}

// Pass through original request
return [{ json: originalRequest }];
```

**Replace `VALIDATION_OUTPUT_NODE` with:**
- Save_v1: `Switch`
- Update_v1: `NQxb_Artifact_Update_v1__Guard_Error_ShortCircuit`
- Promote_v1: `Normalize_request`

---

## Hardcoded Allow-Lists to Remove

### Save_v1 (NQxb_Artifact_Save_v1__Validate_Request)

**REMOVE:**
```javascript
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

### Update_v1 (NQxb_Artifact_Update_v1__Validate_Request)

**REMOVE:**
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

---

## Test Payloads

### Test 1: Enabled Type — Pass

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "title": "Registry Test - Enabled",
  "extension": { "lifecycle_stage": "seed" }
}
```

### Test 2: Disabled Type — Fail

**Setup:** `UPDATE qxb_artifact_type_registry SET enabled = false WHERE artifact_type = 'journal';`

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "title": "Registry Test - Disabled",
  "extension": { "entry_text": "rejected" }
}
```

**Expected:** `ARTIFACT_TYPE_NOT_ALLOWED`, reason: `disabled`

**Cleanup:** `UPDATE qxb_artifact_type_registry SET enabled = true WHERE artifact_type = 'journal';`

### Test 3: Missing Type — Fail

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "instruction_pack",
  "title": "Registry Test - Missing",
  "content": { "scope": "global" }
}
```

**Expected:** `ARTIFACT_TYPE_NOT_ALLOWED`, reason: `not_registered`

---

## KGB Proof Set (Record Results)

| # | Workflow | Type | Registry | Expected | Actual | Pass |
|---|----------|------|----------|----------|--------|------|
| 1 | Save | project | enabled | ok: true | | |
| 2 | Save | journal | disabled | ARTIFACT_TYPE_NOT_ALLOWED | | |
| 3 | Save | instruction_pack | missing | ARTIFACT_TYPE_NOT_ALLOWED | | |
| 4 | Update | project | disabled | ARTIFACT_TYPE_NOT_ALLOWED | | |
| 5 | Promote | project | disabled | ARTIFACT_TYPE_NOT_ALLOWED | | |
| 6 | Query | journal | disabled | ok: true (reads allowed) | | |
| 7 | List | journal | disabled | ok: true (reads allowed) | | |

---

## Governance Rules

- Use Switch nodes, not IF nodes
- Avoid cross-branch node dependencies
- Fail-closed: registry error = reject
- Do not modify Query or List workflows
- Do not add new artifact types
- Prefer `$node['NodeName'].json` for referencing previous nodes

---

## Deliverables

1. Updated workflow JSONs for Save_v1, Update_v1, Promote_v1
2. Completed KGB proof set with receipts
3. Archive superseded workflow versions with timestamp

---

**End of Restart**
