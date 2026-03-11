"""
T69 Contract B: Semantic Key -> UUID Resolution

Insert key->UUID resolution pipeline between Switch_Semantic_Route and RPC_Update_Semantic_Type.

Changes:
1. Insert Lookup_Semantic_Type_By_Key (HTTP Request -> PostgREST)
2. Insert Guard_Semantic_Lookup (Code node — process result)
3. Insert Switch_Semantic_Lookup_Result (Switch node — route ok/error)
4. Rewire: Switch_Semantic_Route[0] -> Lookup -> Guard -> Switch -> {RPC | Error}
5. Modify Guard_Semantic_Type_Result (defensive check: ok !== true)
"""

import json
import uuid
import os

filepath = os.path.join(
    r"c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel",
    "workflows",
    "NQxb_Artifact_Update_v1__T69.json"
)

# Read
with open(filepath, 'r', encoding='utf-8') as f:
    wf = json.load(f)

nodes = wf['nodes']
connections = wf['connections']
prefix = "NQxb_Artifact_Update_v1__"

node_count_before = len(nodes)

# ============================================================
# STEP 1: Remove Switch_Semantic_Route[main#0] -> RPC connection
# ============================================================

switch_sr_name = f"{prefix}Switch_Semantic_Route"
rpc_name = f"{prefix}RPC_Update_Semantic_Type"

if switch_sr_name in connections:
    main_outputs = connections[switch_sr_name]["main"]
    # Output 0 currently -> RPC. Remove it and replace.
    old_output_0 = main_outputs[0]
    # Verify it points to RPC
    assert any(t["node"] == rpc_name for t in old_output_0), \
        f"Expected output 0 to point to {rpc_name}"
    # Clear output 0 (will be rewired in step 5)
    main_outputs[0] = []
    print(f"  [OK] Removed Switch_Semantic_Route[0] -> RPC connection")
else:
    raise RuntimeError(f"No connections found for {switch_sr_name}")

# ============================================================
# STEP 2: Modify Guard_Semantic_Type_Result (defensive check)
# ============================================================

guard_result_name = f"{prefix}Guard_Semantic_Type_Result"
for n in nodes:
    if n["name"] == guard_result_name:
        old_code = n["parameters"]["jsCode"]

        new_code = """// NQxb_Artifact_Update_v1__Guard_Semantic_Type_Result
// T69: Format RPC response into Gateway response envelope
// v2: Defensive check \u2014 treat missing ok or ok!==true as error (Contract B)

const rpcResult = $json;
const upstream = $node['NQxb_Artifact_Update_v1__Detect_Semantic_Route'].json;

// DEFENSIVE: if RPC result is missing or ok is not explicitly true, treat as error
if (!rpcResult || rpcResult.ok !== true) {
  // Extract error details from RPC response if available
  const errorPayload = rpcResult && rpcResult.error
    ? rpcResult.error
    : {
        code: 'RPC_FAILURE',
        message: 'Semantic type update failed \u2014 RPC did not return ok:true',
        details: rpcResult ?? { hint: 'RPC returned null or undefined' }
      };

  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: upstream.gw_action ?? 'artifact.update',
      gw_workspace_id: upstream.gw_workspace_id ?? null,
      artifact_type: upstream.artifact_type ?? null,
      artifact_id: upstream.artifact_id ?? null,
      error: errorPayload,
      timestamp: new Date().toISOString()
    }
  }];
}

// RPC returned noop
if (rpcResult.noop === true) {
  return [{
    json: {
      ok: true,
      _gw_route: 'ok',
      gw_action: upstream.gw_action ?? 'artifact.update',
      artifact_id: upstream.artifact_id,
      artifact_type: upstream.artifact_type,
      operation: 'SEMANTIC_TYPE_UPDATE',
      noop: true,
      message: rpcResult.message ?? 'semantic_type_id unchanged',
      timestamp: new Date().toISOString()
    }
  }];
}

// RPC returned success
return [{
  json: {
    ok: true,
    _gw_route: 'ok',
    gw_action: upstream.gw_action ?? 'artifact.update',
    artifact_id: rpcResult.artifact_id ?? upstream.artifact_id,
    artifact_type: upstream.artifact_type,
    operation: 'SEMANTIC_TYPE_UPDATE',
    old_semantic_type_id: rpcResult.old_semantic_type_id ?? null,
    new_semantic_type_id: rpcResult.new_semantic_type_id ?? null,
    version: rpcResult.version ?? null,
    timestamp: new Date().toISOString()
  }
}];"""

        n["parameters"]["jsCode"] = new_code
        print(f"  [OK] Guard_Semantic_Type_Result: defensive check (ok !== true)")
        break

# ============================================================
# STEP 3: Add Lookup_Semantic_Type_By_Key node (HTTP Request)
# ============================================================

lookup_id = str(uuid.uuid4())
lookup_name = f"{prefix}Lookup_Semantic_Type_By_Key"

lookup_node = {
    "parameters": {
        "url": f"=https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_semantic_type_registry?key=eq.{{{{ $json._semantic_type_update.new_semantic_type_id }}}}&limit=1",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "supabaseApi",
        "options": {}
    },
    "type": "n8n-nodes-base.httpRequest",
    "typeVersion": 4.2,
    "position": [-1536, 960],
    "id": lookup_id,
    "name": lookup_name,
    "alwaysOutputData": True,
    "credentials": {
        "supabaseApi": {
            "id": "n4R4JdOIV9zrCGIT",
            "name": "Qwrk Supabase \u2013 Kernel v1"
        }
    },
    "onError": "continueErrorOutput"
}

nodes.append(lookup_node)
print(f"  [OK] Added Lookup_Semantic_Type_By_Key node (id: {lookup_id})")

# ============================================================
# STEP 4: Add Guard_Semantic_Lookup node (Code)
# ============================================================

guard_lookup_id = str(uuid.uuid4())
guard_lookup_name = f"{prefix}Guard_Semantic_Lookup"

guard_lookup_code = """// NQxb_Artifact_Update_v1__Guard_Semantic_Lookup
// T69 Contract B: Process semantic type registry lookup result.
// Resolves text key \u2192 UUID. Returns ok:true with UUID or ok:false with error.

const lookupResult = $json;
const upstream = $node['NQxb_Artifact_Update_v1__Detect_Semantic_Route'].json;
const originalKey = upstream._semantic_type_update.new_semantic_type_id;

// A. No row found \u2014 key does not exist in registry
if (!lookupResult || !lookupResult.semantic_type_id) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'INVALID_SEMANTIC_TYPE',
        message: 'semantic_type_id not found in registry',
        details: {
          key: originalKey,
          hint: 'Provide a valid registry key (e.g., execution-core, governance, infrastructure)'
        }
      }
    }
  }];
}

// B. Row found but inactive
if (lookupResult.active === false) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'SEMANTIC_TYPE_INACTIVE',
        message: 'Target semantic type is inactive in registry',
        details: {
          key: originalKey,
          semantic_type_id: lookupResult.semantic_type_id
        }
      }
    }
  }];
}

// C. Row found and active \u2014 replace text key with UUID
return [{
  json: {
    ...upstream,
    ok: true,
    _semantic_type_update: {
      ...upstream._semantic_type_update,
      new_semantic_type_id: lookupResult.semantic_type_id,
      _resolved_from_key: originalKey
    }
  }
}];"""

guard_lookup_node = {
    "parameters": {
        "jsCode": guard_lookup_code
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-1312, 960],
    "id": guard_lookup_id,
    "name": guard_lookup_name
}

nodes.append(guard_lookup_node)
print(f"  [OK] Added Guard_Semantic_Lookup node (id: {guard_lookup_id})")

# ============================================================
# STEP 5: Add Switch_Semantic_Lookup_Result node (Switch)
# ============================================================

switch_lookup_id = str(uuid.uuid4())
switch_lookup_name = f"{prefix}Switch_Semantic_Lookup_Result"

switch_lookup_node = {
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
                                "id": "lookup-error"
                            }
                        ],
                        "combinator": "and"
                    }
                },
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
                                "rightValue": True,
                                "operator": {
                                    "type": "boolean",
                                    "operation": "equals"
                                },
                                "id": "lookup-ok"
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
    "position": [-1088, 960],
    "id": switch_lookup_id,
    "name": switch_lookup_name
}

nodes.append(switch_lookup_node)
print(f"  [OK] Added Switch_Semantic_Lookup_Result node (id: {switch_lookup_id})")

# ============================================================
# STEP 6: Wire all new connections
# ============================================================

error_return_name = f"{prefix}Return_Error_Passthrough"

# Switch_Semantic_Route[0] -> Lookup_Semantic_Type_By_Key
connections[switch_sr_name]["main"][0] = [
    {"node": lookup_name, "type": "main", "index": 0}
]

# Lookup_Semantic_Type_By_Key -> Guard_Semantic_Lookup (success) + Return_Error (HTTP error)
connections[lookup_name] = {
    "main": [
        [{"node": guard_lookup_name, "type": "main", "index": 0}],
        [{"node": error_return_name, "type": "main", "index": 0}]
    ]
}

# Guard_Semantic_Lookup -> Switch_Semantic_Lookup_Result
connections[guard_lookup_name] = {
    "main": [
        [{"node": switch_lookup_name, "type": "main", "index": 0}]
    ]
}

# Switch_Semantic_Lookup_Result:
#   [0] ok=false -> Return_Error_Passthrough
#   [1] ok=true  -> RPC_Update_Semantic_Type
#   [2] fallback -> Return_Error_Passthrough
connections[switch_lookup_name] = {
    "main": [
        [{"node": error_return_name, "type": "main", "index": 0}],
        [{"node": rpc_name, "type": "main", "index": 0}],
        [{"node": error_return_name, "type": "main", "index": 0}]
    ]
}

print(f"  [OK] Wired all connections for lookup pipeline")

# ============================================================
# WRITE
# ============================================================

with open(filepath, 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=True)

node_count_after = len(nodes)

print(f"\nSUCCESS: Workflow updated -> {filepath}")
print(f"  Nodes: {node_count_before} -> {node_count_after} (+{node_count_after - node_count_before})")
print(f"  New nodes: Lookup_Semantic_Type_By_Key, Guard_Semantic_Lookup, Switch_Semantic_Lookup_Result")
print(f"  Modified: Guard_Semantic_Type_Result (defensive check: ok !== true)")
print(f"  Rewired: Switch_Semantic_Route[0] -> Lookup -> Guard -> Switch -> {{RPC | Error}}")
print(f"  Removed: Switch_Semantic_Route[0] -> RPC direct connection")
