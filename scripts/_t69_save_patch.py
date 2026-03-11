"""T69 Phase 3: Patch Save workflow — add semantic type nodes + rewire connections"""
import json, uuid, sys, os

workflow_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'workflows', 'NQxb_Artifact_Save_v1 (40).json')

with open(workflow_path, 'r') as f:
    data = json.load(f)

# --- 1. Add 3 new nodes ---

node_lookup = {
    "parameters": {
        "operation": "get",
        "tableId": "qxb_semantic_type_registry",
        "filters": {
            "conditions": [
                {
                    "keyName": "semantic_type_id",
                    "keyValue": "={{ $json.semantic_type_id }}"
                }
            ]
        }
    },
    "type": "n8n-nodes-base.supabase",
    "typeVersion": 1,
    "position": [-1280, 480],
    "id": str(uuid.uuid4()),
    "name": "NQxb_Artifact_Save_v1__Lookup_Semantic_Type",
    "alwaysOutputData": True,
    "credentials": {
        "supabaseApi": {
            "id": "n4R4JdOIV9zrCGIT",
            "name": "Qwrk Supabase \u2013 Kernel v1"
        }
    }
}

guard_code = (
    "// NQxb_Artifact_Save_v1__Guard_Semantic_Type\n"
    "// T69: Validate semantic_type_id against registry\n"
    "// Only applies to top-level INSERT operations\n"
    "// Non-top-level types pass through (semantic_type_id is null, already validated)\n"
    "\n"
    "const TOP_LEVEL_TYPES = ['project', 'snapshot', 'journal', 'restart'];\n"
    "\n"
    "// Get original validated request from upstream\n"
    "const req = $node['NQxb_Artifact_Save_v1__Validate_Request'].json;\n"
    "const registryRow = $json;\n"
    "const artifact_type = (req.artifact_type ?? '').trim();\n"
    "const is_update = req.is_update === true;\n"
    "\n"
    "// Pass-through: UPDATE operations (semantic_type_id not touched on UPDATE)\n"
    "if (is_update) {\n"
    "  return [{ json: req }];\n"
    "}\n"
    "\n"
    "// Pass-through: non-top-level types (semantic_type_id is null, validated by Validate_Request)\n"
    "if (!TOP_LEVEL_TYPES.includes(artifact_type)) {\n"
    "  return [{ json: req }];\n"
    "}\n"
    "\n"
    "// Top-level INSERT: registry row must exist\n"
    "if (!registryRow || !registryRow.semantic_type_id) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ok: false,\n"
    "      _gw_route: 'error',\n"
    "      gw_action: req.gw_action ?? 'artifact.save',\n"
    "      gw_workspace_id: req.gw_workspace_id ?? null,\n"
    "      artifact_type: artifact_type,\n"
    "      error: {\n"
    "        code: 'INVALID_SEMANTIC_TYPE',\n"
    "        message: 'semantic_type_id not found in registry',\n"
    "        details: {\n"
    "          semantic_type_id: req.semantic_type_id\n"
    "        }\n"
    "      },\n"
    "      timestamp: new Date().toISOString()\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// Top-level INSERT: registry entry must be active\n"
    "if (registryRow.active === false) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ok: false,\n"
    "      _gw_route: 'error',\n"
    "      gw_action: req.gw_action ?? 'artifact.save',\n"
    "      gw_workspace_id: req.gw_workspace_id ?? null,\n"
    "      artifact_type: artifact_type,\n"
    "      error: {\n"
    "        code: 'SEMANTIC_TYPE_INACTIVE',\n"
    "        message: 'Target semantic type is inactive in registry',\n"
    "        details: {\n"
    "          semantic_type_id: req.semantic_type_id\n"
    "        }\n"
    "      },\n"
    "      timestamp: new Date().toISOString()\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// Registry validated — pass through original request\n"
    "return [{ json: req }];\n"
)

node_guard = {
    "parameters": {
        "jsCode": guard_code
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-1056, 480],
    "id": str(uuid.uuid4()),
    "name": "NQxb_Artifact_Save_v1__Guard_Semantic_Type"
}

node_switch = {
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
                                "id": "semantic-error"
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
                                "id": "semantic-ok",
                                "leftValue": "={{ $json.ok }}",
                                "rightValue": True,
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
        "options": {
            "fallbackOutput": "extra"
        }
    },
    "type": "n8n-nodes-base.switch",
    "typeVersion": 3.4,
    "position": [-832, 480],
    "id": str(uuid.uuid4()),
    "name": "NQxb_Artifact_Save_v1__Switch_Semantic_Type_Result"
}

# Add nodes
data['nodes'].append(node_lookup)
data['nodes'].append(node_guard)
data['nodes'].append(node_switch)

# --- 2. Modify DB_Insert_Spine: add semantic_type_id field ---
for node in data['nodes']:
    if node.get('name') == 'NQxb_Artifact_Save_v1__DB_Insert_Spine':
        fields = node['parameters']['fieldsUi']['fieldValues']
        fields.append({
            "fieldId": "semantic_type_id",
            "fieldValue": "={{ $json.semantic_type_id }}"
        })
        break

# --- 3. Rewire connections ---
conn = data['connections']

# Switch_Type_Registry output 1 (ok) now -> Lookup_Semantic_Type (was -> Switch_InsertOrUpdate)
conn['NQxb_Artifact_Save_v1__Switch_Type_Registry']['main'][1] = [
    {
        "node": "NQxb_Artifact_Save_v1__Lookup_Semantic_Type",
        "type": "main",
        "index": 0
    }
]

# New: Lookup -> Guard
conn['NQxb_Artifact_Save_v1__Lookup_Semantic_Type'] = {
    "main": [
        [
            {
                "node": "NQxb_Artifact_Save_v1__Guard_Semantic_Type",
                "type": "main",
                "index": 0
            }
        ]
    ]
}

# New: Guard -> Switch
conn['NQxb_Artifact_Save_v1__Guard_Semantic_Type'] = {
    "main": [
        [
            {
                "node": "NQxb_Artifact_Save_v1__Switch_Semantic_Type_Result",
                "type": "main",
                "index": 0
            }
        ]
    ]
}

# New: Switch outputs: error -> Return_Response, ok -> Switch_InsertOrUpdate, extra -> Return_Response
conn['NQxb_Artifact_Save_v1__Switch_Semantic_Type_Result'] = {
    "main": [
        [
            {
                "node": "NQxb_Artifact_Save_v1__Return_Response",
                "type": "main",
                "index": 0
            }
        ],
        [
            {
                "node": "NQxb_Artifact_Save_v1__Switch_InsertOrUpdate",
                "type": "main",
                "index": 0
            }
        ],
        [
            {
                "node": "NQxb_Artifact_Save_v1__Return_Response",
                "type": "main",
                "index": 0
            }
        ]
    ]
}

with open(workflow_path, 'w') as f:
    json.dump(data, f, indent=2)

print("SUCCESS: 3 nodes added, DB_Insert_Spine updated, connections rewired")

# Verify
for node in data['nodes']:
    name = node.get('name', '')
    if 'Semantic_Type' in name or 'DB_Insert_Spine' in name:
        print(f"  Node: {name}")
        if 'DB_Insert_Spine' in name:
            fields = [f['fieldId'] for f in node['parameters']['fieldsUi']['fieldValues']]
            print(f"    Fields: {fields}")

print(f"  Connection: Switch_Type_Registry ok -> {conn['NQxb_Artifact_Save_v1__Switch_Type_Registry']['main'][1][0]['node']}")
print(f"  Connection: Switch_Semantic_Type_Result ok -> {conn['NQxb_Artifact_Save_v1__Switch_Semantic_Type_Result']['main'][1][0]['node']}")
print(f"  Connection: Switch_Semantic_Type_Result error -> {conn['NQxb_Artifact_Save_v1__Switch_Semantic_Type_Result']['main'][0][0]['node']}")
