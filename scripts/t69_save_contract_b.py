"""
T69 Save Workflow: Dual-mode Semantic Type Resolution (Contract B)

Fix Save workflow to support both text keys and UUIDs for semantic_type_id.

Changes:
1. Remove old Supabase GET node (Lookup_Semantic_Type) -- fails on text keys
2. Add Resolve_Semantic_Input (Code node) -- UUID vs key detection
3. Add new Lookup_Semantic_Type (HTTP Request -> PostgREST) -- dual-mode query
4. Modify Guard_Semantic_Type -- resolve key->UUID, inject into request
5. Rewire: Switch_Type_Registry[1] -> Resolve -> Lookup -> Guard -> Switch

Execute via: python scripts/t69_save_contract_b.py
"""

import json
import uuid
import os

filepath = os.path.join(
    r"c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel",
    "workflows",
    "NQxb_Artifact_Save_v1 (40).json"
)

# Read
with open(filepath, 'r', encoding='utf-8') as f:
    wf = json.load(f)

nodes = wf['nodes']
connections = wf['connections']
prefix = "NQxb_Artifact_Save_v1__"

node_count_before = len(nodes)

# ============================================================
# STEP 1: Remove old Supabase Lookup_Semantic_Type node
# ============================================================

old_lookup_name = f"{prefix}Lookup_Semantic_Type"
old_lookup_idx = None
for i, n in enumerate(nodes):
    if n["name"] == old_lookup_name:
        old_lookup_idx = i
        assert n["type"] == "n8n-nodes-base.supabase", \
            f"Expected Supabase node, got {n['type']}"
        break

assert old_lookup_idx is not None, f"Node {old_lookup_name} not found"
nodes.pop(old_lookup_idx)
print(f"  [OK] Removed old Supabase node: {old_lookup_name}")

# ============================================================
# STEP 2: Add Resolve_Semantic_Input (Code node)
# ============================================================

resolve_id = str(uuid.uuid4())
resolve_name = f"{prefix}Resolve_Semantic_Input"

resolve_code = """// NQxb_Artifact_Save_v1__Resolve_Semantic_Input
// T69 Contract B: Detect UUID vs text key input for semantic_type_id
// Builds PostgREST filter parameter for dual-mode registry lookup

const req = $json;
const semanticTypeId = (req.semantic_type_id ?? '').toString().trim();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const isUuid = UUID_REGEX.test(semanticTypeId);

return [{
  json: {
    ...req,
    _semantic_lookup: {
      original_value: semanticTypeId,
      is_uuid: isUuid,
      filter_param: isUuid
        ? 'semantic_type_id=eq.' + semanticTypeId
        : 'key=eq.' + semanticTypeId
    }
  }
}];"""

resolve_node = {
    "parameters": {
        "jsCode": resolve_code
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-1504, 480],
    "id": resolve_id,
    "name": resolve_name
}

nodes.append(resolve_node)
print(f"  [OK] Added Resolve_Semantic_Input node (id: {resolve_id})")

# ============================================================
# STEP 3: Add new Lookup_Semantic_Type (HTTP Request -> PostgREST)
# ============================================================

new_lookup_id = str(uuid.uuid4())
new_lookup_name = f"{prefix}Lookup_Semantic_Type"

new_lookup_node = {
    "parameters": {
        "url": "=https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_semantic_type_registry?{{ $json._semantic_lookup.filter_param }}&limit=1",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "supabaseApi",
        "options": {}
    },
    "type": "n8n-nodes-base.httpRequest",
    "typeVersion": 4.2,
    "position": [-1280, 480],
    "id": new_lookup_id,
    "name": new_lookup_name,
    "alwaysOutputData": True,
    "credentials": {
        "supabaseApi": {
            "id": "n4R4JdOIV9zrCGIT",
            "name": "Qwrk Supabase \u2013 Kernel v1"
        }
    },
    "onError": "continueErrorOutput"
}

nodes.append(new_lookup_node)
print(f"  [OK] Added HTTP Request Lookup_Semantic_Type node (id: {new_lookup_id})")

# ============================================================
# STEP 4: Modify Guard_Semantic_Type (resolve key->UUID)
# ============================================================

guard_name = f"{prefix}Guard_Semantic_Type"
guard_found = False
for n in nodes:
    if n["name"] == guard_name:
        new_guard_code = """// NQxb_Artifact_Save_v1__Guard_Semantic_Type
// T69 Contract B: Validate semantic_type_id against registry + resolve key->UUID
// v2.0: Dual-mode (text key or UUID input). Always outputs resolved UUID.
// n8n-compatible: PostgREST arrays unwrapped by HTTP Request node.
// Empty result (no match) arrives as {} via alwaysOutputData.

const TOP_LEVEL_TYPES = ['project', 'snapshot', 'journal', 'restart'];
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const req = $node['NQxb_Artifact_Save_v1__Validate_Request'].json;
const registryRow = $json;
const artifact_type = (req.artifact_type ?? '').trim();
const is_update = req.is_update === true;
const originalValue = (req.semantic_type_id ?? '').toString().trim();

// Pass-through: UPDATE operations (semantic_type_id not touched on Save UPDATE)
if (is_update) {
  return [{ json: req }];
}

// Pass-through: non-top-level types (semantic_type_id is null, validated by Validate_Request)
if (!TOP_LEVEL_TYPES.includes(artifact_type)) {
  return [{ json: req }];
}

// Top-level INSERT: registry row must exist
// n8n HTTP Request + alwaysOutputData:true -> empty object {} when no rows
if (!registryRow || !registryRow.semantic_type_id) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: req.gw_action ?? 'artifact.save',
      gw_workspace_id: req.gw_workspace_id ?? null,
      artifact_type: artifact_type,
      error: {
        code: 'INVALID_SEMANTIC_TYPE',
        message: 'semantic_type_id not found in registry',
        details: {
          semantic_type_id: originalValue,
          hint: 'Provide a valid registry key (e.g., execution-core, governance) or UUID'
        }
      },
      timestamp: new Date().toISOString()
    }
  }];
}

// Top-level INSERT: registry entry must be active
if (registryRow.active === false) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: req.gw_action ?? 'artifact.save',
      gw_workspace_id: req.gw_workspace_id ?? null,
      artifact_type: artifact_type,
      error: {
        code: 'SEMANTIC_TYPE_INACTIVE',
        message: 'Target semantic type is inactive in registry',
        details: {
          semantic_type_id: originalValue,
          resolved_uuid: registryRow.semantic_type_id
        }
      },
      timestamp: new Date().toISOString()
    }
  }];
}

// Contract assertion: resolved value must be UUID (defense-in-depth)
const resolvedUuid = registryRow.semantic_type_id;
if (!UUID_REGEX.test(resolvedUuid)) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      gw_action: req.gw_action ?? 'artifact.save',
      gw_workspace_id: req.gw_workspace_id ?? null,
      artifact_type: artifact_type,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Registry returned non-UUID semantic_type_id (contract assertion failed)',
        details: {
          raw_value: resolvedUuid,
          original_input: originalValue
        }
      },
      timestamp: new Date().toISOString()
    }
  }];
}

// Registry validated + resolved -- inject UUID into request
const isKeyInput = !UUID_REGEX.test(originalValue);
return [{
  json: {
    ...req,
    semantic_type_id: resolvedUuid,
    _semantic_resolution: isKeyInput
      ? { resolved_from_key: originalValue, resolved_uuid: resolvedUuid }
      : { input_was_uuid: true }
  }
}];"""

        n["parameters"]["jsCode"] = new_guard_code
        guard_found = True
        print(f"  [OK] Modified Guard_Semantic_Type: dual-mode key->UUID resolution")
        break

assert guard_found, f"Node {guard_name} not found"

# ============================================================
# STEP 5: Rewire connections
# ============================================================

switch_type_registry_name = f"{prefix}Switch_Type_Registry"
return_response_name = f"{prefix}Return_Response"
guard_semantic_name = f"{prefix}Guard_Semantic_Type"

# 5a: Switch_Type_Registry[1] -> Resolve_Semantic_Input (was -> old Lookup)
old_target = connections[switch_type_registry_name]["main"][1]
assert any(t["node"] == old_lookup_name for t in old_target), \
    f"Expected Switch_Type_Registry[1] to point to {old_lookup_name}"

connections[switch_type_registry_name]["main"][1] = [
    {"node": resolve_name, "type": "main", "index": 0}
]
print(f"  [OK] Rewired Switch_Type_Registry[1] -> Resolve_Semantic_Input")

# 5b: Resolve_Semantic_Input -> new Lookup_Semantic_Type
connections[resolve_name] = {
    "main": [
        [{"node": new_lookup_name, "type": "main", "index": 0}]
    ]
}
print(f"  [OK] Wired Resolve_Semantic_Input -> Lookup_Semantic_Type")

# 5c: Lookup_Semantic_Type -> Guard (success output 0) + Return_Response (HTTP error output 1)
# This overwrites the old Supabase node's single-output connection
connections[new_lookup_name] = {
    "main": [
        [{"node": guard_semantic_name, "type": "main", "index": 0}],
        [{"node": return_response_name, "type": "main", "index": 0}]
    ]
}
print(f"  [OK] Wired Lookup_Semantic_Type -> Guard (success) + Return_Response (error)")

# Guard -> Switch_Semantic_Type_Result: UNCHANGED
# Switch_Semantic_Type_Result connections: UNCHANGED

# ============================================================
# WRITE
# ============================================================

with open(filepath, 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=True)

node_count_after = len(nodes)

print(f"\nSUCCESS: Workflow updated -> {filepath}")
print(f"  Nodes: {node_count_before} -> {node_count_after} (+{node_count_after - node_count_before})")
print(f"  Removed: Lookup_Semantic_Type (Supabase GET -- uuid-only filter)")
print(f"  Added: Resolve_Semantic_Input (Code -- UUID vs key detection)")
print(f"  Added: Lookup_Semantic_Type (HTTP Request -- PostgREST dual-mode)")
print(f"  Modified: Guard_Semantic_Type (key->UUID resolution + contract assertion)")
print(f"  Rewired: Switch_Type_Registry[1] -> Resolve -> Lookup -> Guard -> Switch")
print(f"  Error path: Lookup_Semantic_Type[1] -> Return_Response (HTTP errors)")
