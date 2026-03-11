"""
Build Resolver Integration — Integrate QXB__Resolve_Semantic_Type_v1 into Save + Update

Part A: Save (48 → 47 nodes)
  Remove: Resolve_Semantic_Input, Lookup_Semantic_Type, Guard_Semantic_Type (-3)
  Add: Call_Semantic_Resolver, Inject_Resolved_Semantic_Type (+2)
  Rewire: Switch_Type_Registry[1] → Call → Inject → Switch_Semantic_Type_Result

Part B: Update (42 → 44 nodes)
  Remove: Lookup_Semantic_Type_By_Key, Guard_Semantic_Lookup, Switch_Semantic_Lookup_Result (-3)
  Add: Prepare_Resolver_Input, Call_Semantic_Resolver, Inject_Resolved_For_RPC,
       Assert_Semantic_UUID, Switch_Assert_Result (+5)
  Rewire: Switch_Semantic_Route[0] → Prepare → Call → Inject → Assert → Switch_Assert
          Switch_Assert[0] → Return_Error_Passthrough
          Switch_Assert[1] → RPC_Update_Semantic_Type

Execute via: python scripts/build_resolver_integration.py
"""

import json
import uuid
import os

RESOLVER_WORKFLOW_ID = "1NAtJghJlcRdzrpj"

base = r"c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"
save_path = os.path.join(base, "workflows", "NQxb_Artifact_Save_v1 (40).json")
update_path = os.path.join(base, "workflows", "NQxb_Artifact_Update_v1__T69 (3).json")

# Helper: Execute Workflow node template
def make_execute_workflow_node(name, node_id, position):
    return {
        "parameters": {
            "workflowId": {
                "__rl": True,
                "value": RESOLVER_WORKFLOW_ID,
                "mode": "id"
            },
            "workflowInputs": {
                "mappingMode": "defineBelow",
                "value": {},
                "matchingColumns": [],
                "schema": [],
                "attemptToConvertTypes": False,
                "convertFieldsToString": False
            },
            "options": {
                "waitForSubWorkflow": True
            }
        },
        "type": "n8n-nodes-base.executeWorkflow",
        "typeVersion": 1.3,
        "position": position,
        "id": node_id,
        "name": name
    }

# Helper: Switch node (ok===false check) template
def make_assert_switch_node(name, node_id, position):
    return {
        "parameters": {
            "rules": {
                "values": [
                    {
                        "conditions": {
                            "options": {
                                "caseSensitive": True,
                                "leftValue": "",
                                "typeValidation": "strict",
                                "version": 3
                            },
                            "conditions": [
                                {
                                    "leftValue": "={{ $json.ok }}",
                                    "rightValue": False,
                                    "operator": {
                                        "type": "boolean",
                                        "operation": "equals"
                                    },
                                    "id": "assert-fail"
                                }
                            ],
                            "combinator": "and"
                        }
                    }
                ]
            },
            "options": {
                "fallbackOutput": "extra"
            }
        },
        "type": "n8n-nodes-base.switch",
        "typeVersion": 3.4,
        "position": position,
        "id": node_id,
        "name": name
    }

# Helper: remove node + its connection entry
def remove_node(nodes, conns, name):
    idx = None
    for i, n in enumerate(nodes):
        if n["name"] == name:
            idx = i
            break
    assert idx is not None, f"Node {name} not found"
    nodes.pop(idx)
    if name in conns:
        del conns[name]
    return True


# ==========================================================================
# PART A: SAVE WORKFLOW
# ==========================================================================

print("=" * 60)
print("PART A: SAVE WORKFLOW")
print("=" * 60)

with open(save_path, 'r', encoding='utf-8') as f:
    save_wf = json.load(f)

nodes = save_wf['nodes']
conns = save_wf['connections']
sp = "NQxb_Artifact_Save_v1__"
save_before = len(nodes)

# --- A1: Remove 3 nodes ---
for rname in [f"{sp}Resolve_Semantic_Input",
              f"{sp}Lookup_Semantic_Type",
              f"{sp}Guard_Semantic_Type"]:
    remove_node(nodes, conns, rname)
    print(f"  [OK] Removed {rname}")

# --- A2: Add Call_Semantic_Resolver ---
call_save_id = str(uuid.uuid4())
call_save_name = f"{sp}Call_Semantic_Resolver"
nodes.append(make_execute_workflow_node(call_save_name, call_save_id, [-1400, 480]))
print(f"  [OK] Added {call_save_name}")

# --- A3: Add Inject_Resolved_Semantic_Type ---
inject_save_id = str(uuid.uuid4())
inject_save_name = f"{sp}Inject_Resolved_Semantic_Type"

inject_save_code = r"""// NQxb_Artifact_Save_v1__Inject_Resolved_Semantic_Type
// Maps resolver output back into validated request for downstream processing.
// Resolver returns: { ok, resolved_semantic_type_id, resolution_mode, error? }
// Must set ok:true on success for Switch_Semantic_Type_Result routing.

const resolver = $json;
const req = $node['NQxb_Artifact_Save_v1__Validate_Request'].json;

// Safety: if $node reference failed after Execute Workflow, fail loudly
if (!req || typeof req !== 'object' || !req.artifact_type) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Inject_Resolved_Semantic_Type: Validate_Request node reference returned empty',
        details: { req_type: typeof req, has_req: !!req }
      },
      timestamp: new Date().toISOString()
    }
  }];
}

const artifactType = (req.artifact_type ?? '').trim();

// Resolver error -- forward as gateway error envelope
if (resolver.ok === false) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: req.gw_action ?? 'artifact.save',
      gw_workspace_id: req.gw_workspace_id ?? null,
      artifact_type: artifactType,
      error: resolver.error,
      timestamp: new Date().toISOString()
    }
  }];
}

// Not applicable (non-top-level types) -- pass through req unchanged.
// CRITICAL: Must DELETE semantic_type_id from output. When the value is null,
// n8n expression ={{ $json.semantic_type_id }} resolves to empty string "",
// which PostgreSQL rejects for UUID columns. Deleting the property makes the
// expression resolve to undefined, and the Supabase node omits it from INSERT.
if (resolver.resolution_mode === 'not_applicable') {
  const out = { ...req, ok: true };
  delete out.semantic_type_id;
  return [{ json: out }];
}

// Resolver success — inject resolved UUID into validated request
const originalValue = resolver._resolution_debug?.original_value ?? null;

return [{
  json: {
    ...req,
    ok: true,
    semantic_type_id: resolver.resolved_semantic_type_id,
    _semantic_resolution: resolver.resolution_mode === 'key_to_uuid'
      ? { resolved_from_key: originalValue, resolved_uuid: resolver.resolved_semantic_type_id }
      : { input_was_uuid: true }
  }
}];"""

inject_save_node = {
    "parameters": {"jsCode": inject_save_code},
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-1176, 480],
    "id": inject_save_id,
    "name": inject_save_name
}
nodes.append(inject_save_node)
print(f"  [OK] Added {inject_save_name}")

# --- A4: Rewire ---

# Switch_Type_Registry[1] → Call_Semantic_Resolver
switch_tr = f"{sp}Switch_Type_Registry"
old_target_1 = conns[switch_tr]["main"][1]
assert any(t["node"] == f"{sp}Resolve_Semantic_Input" for t in old_target_1), \
    f"Expected Switch_Type_Registry[1] -> Resolve_Semantic_Input, got {old_target_1}"
conns[switch_tr]["main"][1] = [
    {"node": call_save_name, "type": "main", "index": 0}
]
print(f"  [OK] Rewired Switch_Type_Registry[1] -> Call_Semantic_Resolver")

# Call → Inject
conns[call_save_name] = {
    "main": [[{"node": inject_save_name, "type": "main", "index": 0}]]
}
print(f"  [OK] Wired Call_Semantic_Resolver -> Inject_Resolved_Semantic_Type")

# Inject → Switch_Semantic_Type_Result
switch_sem = f"{sp}Switch_Semantic_Type_Result"
conns[inject_save_name] = {
    "main": [[{"node": switch_sem, "type": "main", "index": 0}]]
}
print(f"  [OK] Wired Inject_Resolved_Semantic_Type -> Switch_Semantic_Type_Result")

# --- A5: Write Save ---
with open(save_path, 'w', encoding='utf-8') as f:
    json.dump(save_wf, f, indent=2, ensure_ascii=True)

save_after = len(nodes)
print(f"\n  Save: {save_before} -> {save_after} nodes ({save_after - save_before:+d})")
print(f"  Removed: Resolve_Semantic_Input, Lookup_Semantic_Type, Guard_Semantic_Type (-3)")
print(f"  Added: Call_Semantic_Resolver, Inject_Resolved_Semantic_Type (+2)")
print(f"  Chain: Switch_Type_Registry[1] -> Call -> Inject -> Switch_Semantic_Type_Result")


# ==========================================================================
# PART B: UPDATE WORKFLOW
# ==========================================================================

print()
print("=" * 60)
print("PART B: UPDATE WORKFLOW")
print("=" * 60)

with open(update_path, 'r', encoding='utf-8') as f:
    update_wf = json.load(f)

nodes = update_wf['nodes']
conns = update_wf['connections']
up = "NQxb_Artifact_Update_v1__"
update_before = len(nodes)

# --- B1: Remove 3 nodes ---
for rname in [f"{up}Lookup_Semantic_Type_By_Key",
              f"{up}Guard_Semantic_Lookup",
              f"{up}Switch_Semantic_Lookup_Result"]:
    remove_node(nodes, conns, rname)
    print(f"  [OK] Removed {rname}")

# --- B2: Add Prepare_Resolver_Input ---
prep_id = str(uuid.uuid4())
prep_name = f"{up}Prepare_Resolver_Input"

prep_code = r"""// NQxb_Artifact_Update_v1__Prepare_Resolver_Input
// Extract semantic_type_id and artifact_type for resolver sub-workflow.
// Resolver expects: { semantic_type_id, artifact_type }

const req = $json;

return [{
  json: {
    semantic_type_id: req._semantic_type_update.new_semantic_type_id,
    artifact_type: req.artifact_type
  }
}];"""

prep_node = {
    "parameters": {"jsCode": prep_code},
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-3584, 960],
    "id": prep_id,
    "name": prep_name
}
nodes.append(prep_node)
print(f"  [OK] Added {prep_name}")

# --- B3: Add Call_Semantic_Resolver ---
call_upd_id = str(uuid.uuid4())
call_upd_name = f"{up}Call_Semantic_Resolver"
nodes.append(make_execute_workflow_node(call_upd_name, call_upd_id, [-3360, 960]))
print(f"  [OK] Added {call_upd_name}")

# --- B4: Add Inject_Resolved_For_RPC ---
inject_upd_id = str(uuid.uuid4())
inject_upd_name = f"{up}Inject_Resolved_For_RPC"

inject_upd_code = r"""// NQxb_Artifact_Update_v1__Inject_Resolved_For_RPC
// Maps resolver output back into upstream request for RPC call.
// Upstream context: Detect_Semantic_Route output (has _semantic_type_update, artifact_id, etc.)
// Resolver returns: { ok, resolved_semantic_type_id, resolution_mode, error? }

const resolver = $json;
const upstream = $node['NQxb_Artifact_Update_v1__Detect_Semantic_Route'].json;

// Resolver error — forward as gateway error envelope
if (resolver.ok === false) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: resolver.error
    }
  }];
}

// Resolver success — merge resolved UUID into _semantic_type_update
const originalKey = upstream._semantic_type_update.new_semantic_type_id;
const resolvedUuid = resolver.resolved_semantic_type_id;

return [{
  json: {
    ...upstream,
    ok: true,
    _semantic_type_update: {
      ...upstream._semantic_type_update,
      new_semantic_type_id: resolvedUuid,
      _resolved_from_key: resolver.resolution_mode === 'key_to_uuid' ? originalKey : undefined
    }
  }
}];"""

inject_upd_node = {
    "parameters": {"jsCode": inject_upd_code},
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-3136, 960],
    "id": inject_upd_id,
    "name": inject_upd_name
}
nodes.append(inject_upd_node)
print(f"  [OK] Added {inject_upd_name}")

# --- B5: Add Assert_Semantic_UUID ---
assert_upd_id = str(uuid.uuid4())
assert_upd_name = f"{up}Assert_Semantic_UUID"

assert_upd_code = r"""// NQxb_Artifact_Update_v1__Assert_Semantic_UUID
// T69: Last-mile defense-in-depth — assert semantic_type_id is UUID before RPC call.
// Only top-level types reach this point (Detect_Semantic_Route filters non-top-level).
// This guard fires ONLY if upstream resolution failed silently.

const req = $json;

// Pass through upstream error envelopes unchanged (resolver errors, inject errors)
if (req.ok === false) {
  return [{ json: req }];
}

const semanticTypeId = req._semantic_type_update?.new_semantic_type_id;
const artifactType = (req.artifact_type ?? '').trim();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

if (!semanticTypeId || !UUID_REGEX.test(semanticTypeId)) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: req.gw_action ?? 'artifact.update',
      gw_workspace_id: req.gw_workspace_id ?? null,
      artifact_type: artifactType,
      error: {
        code: 'SEMANTIC_TYPE_RESOLUTION_FAILED',
        message: 'semantic_type_id must be a resolved UUID before RPC call',
        details: {
          artifact_type: artifactType,
          semantic_type_id: semanticTypeId ?? null,
          hint: 'Semantic type must be resolved through registry before update. This is a defense-in-depth assertion — upstream resolution may have failed silently.'
        }
      },
      timestamp: new Date().toISOString()
    }
  }];
}

// Assertion passed — forward to RPC
return [{ json: req }];"""

assert_upd_node = {
    "parameters": {"jsCode": assert_upd_code},
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-2912, 960],
    "id": assert_upd_id,
    "name": assert_upd_name
}
nodes.append(assert_upd_node)
print(f"  [OK] Added {assert_upd_name}")

# --- B6: Add Switch_Assert_Result ---
switch_assert_upd_id = str(uuid.uuid4())
switch_assert_upd_name = f"{up}Switch_Assert_Result"
nodes.append(make_assert_switch_node(switch_assert_upd_name, switch_assert_upd_id, [-2688, 960]))
print(f"  [OK] Added {switch_assert_upd_name}")

# --- B7: Rewire ---

# Switch_Semantic_Route[0] → Prepare_Resolver_Input
switch_sr = f"{up}Switch_Semantic_Route"
old_sr_0 = conns[switch_sr]["main"][0]
assert any(t["node"] == f"{up}Lookup_Semantic_Type_By_Key" for t in old_sr_0), \
    f"Expected Switch_Semantic_Route[0] -> Lookup_Semantic_Type_By_Key, got {old_sr_0}"
conns[switch_sr]["main"][0] = [
    {"node": prep_name, "type": "main", "index": 0}
]
print(f"  [OK] Rewired Switch_Semantic_Route[0] -> Prepare_Resolver_Input")

# Prepare → Call
conns[prep_name] = {
    "main": [[{"node": call_upd_name, "type": "main", "index": 0}]]
}
print(f"  [OK] Wired Prepare -> Call_Semantic_Resolver")

# Call → Inject
conns[call_upd_name] = {
    "main": [[{"node": inject_upd_name, "type": "main", "index": 0}]]
}
print(f"  [OK] Wired Call -> Inject_Resolved_For_RPC")

# Inject → Assert
conns[inject_upd_name] = {
    "main": [[{"node": assert_upd_name, "type": "main", "index": 0}]]
}
print(f"  [OK] Wired Inject -> Assert_Semantic_UUID")

# Assert → Switch_Assert_Result
conns[assert_upd_name] = {
    "main": [[{"node": switch_assert_upd_name, "type": "main", "index": 0}]]
}
print(f"  [OK] Wired Assert -> Switch_Assert_Result")

# Switch_Assert_Result:
#   [0] ok=false → Return_Error_Passthrough (error)
#   [1] fallback → RPC_Update_Semantic_Type (success)
ret_err = f"{up}Return_Error_Passthrough"
rpc_update = f"{up}RPC_Update_Semantic_Type"

conns[switch_assert_upd_name] = {
    "main": [
        [{"node": ret_err, "type": "main", "index": 0}],
        [{"node": rpc_update, "type": "main", "index": 0}]
    ]
}
print(f"  [OK] Wired Switch_Assert[0] -> Return_Error_Passthrough (error)")
print(f"  [OK] Wired Switch_Assert[1] -> RPC_Update_Semantic_Type (success)")

# --- B8: Write Update ---
with open(update_path, 'w', encoding='utf-8') as f:
    json.dump(update_wf, f, indent=2, ensure_ascii=True)

update_after = len(nodes)
print(f"\n  Update: {update_before} -> {update_after} nodes ({update_after - update_before:+d})")
print(f"  Removed: Lookup_Semantic_Type_By_Key, Guard_Semantic_Lookup, Switch_Semantic_Lookup_Result (-3)")
print(f"  Added: Prepare_Resolver_Input, Call_Semantic_Resolver, Inject_Resolved_For_RPC,")
print(f"         Assert_Semantic_UUID, Switch_Assert_Result (+5)")
print(f"  Chain: Switch_Semantic_Route[0] -> Prepare -> Call -> Inject -> Assert -> Switch_Assert")
print(f"  Error: Switch_Assert[0] -> Return_Error_Passthrough")
print(f"  Success: Switch_Assert[1] -> RPC_Update_Semantic_Type")


# ==========================================================================
# SUMMARY
# ==========================================================================

print()
print("=" * 60)
print("SUMMARY")
print("=" * 60)
print(f"  Resolver ID: {RESOLVER_WORKFLOW_ID}")
print(f"  Save:   {save_before} -> {save_after} ({save_after - save_before:+d})")
print(f"  Update: {update_before} -> {update_after} ({update_after - update_before:+d})")
print()
print("  NEXT STEPS:")
print(f"  1. Import Save workflow to n8n (ID: GTSGFy1QGpeXRniD)")
print(f"  2. Import Update workflow to n8n (ID: Fd6EqFMW18vSlKEC)")
print(f"  3. Activate resolver + Save + Update")
print(f"  4. Run test suites: S-Suite, A-Suite, H-Suite, R-Suite")
