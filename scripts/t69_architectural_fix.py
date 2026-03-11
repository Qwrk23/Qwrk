"""
T69 Architectural Fix: Extract semantic_type routing from Check_Mutability_Rules
into a dedicated pre-routing layer (Detect_Semantic_Route + Switch_Semantic_Route).

Changes:
1. Add Detect_Semantic_Route (Code node) between Fetch_Existing_Spine and Check_Mutability_Rules
2. Add Switch_Semantic_Route (Switch node) after Detect_Semantic_Route
3. Rewire: Fetch_Existing_Spine -> Detect -> Switch -> {RPC | Error | Check_Mutability}
4. Remove check #2.5 from Check_Mutability_Rules
5. Remove semantic_type case from Switch_Update_Mode
6. Update Guard_Semantic_Type_Result upstream reference
"""

import json
import uuid
import sys
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

# Build node lookup
node_map = {}
for i, node in enumerate(nodes):
    node_map[node['name']] = i

original_count = len(nodes)

# ========== 1. Modify Check_Mutability_Rules jsCode ==========
cmr_idx = node_map['NQxb_Artifact_Update_v1__Check_Mutability_Rules']
cmr_code = nodes[cmr_idx]['parameters']['jsCode']

# 1a. Remove the "2.5" line from header comment
header_line = "// 2.5 semantic_type_id detection (T69) \u2014 dedicated RPC route \u2014 spine-level tags are type-agnostic\n"
if header_line not in cmr_code:
    print("ERROR: Could not find check #2.5 header line in Check_Mutability_Rules")
    sys.exit(1)
cmr_code = cmr_code.replace(header_line, "")

# 1b. Add version line
v4_line = "// v4: T71 \u2014 dependency check flagging for leaf completing \u2014 spine-field update mode for branch/limb/leaf\n"
v5_line = "// v5: T69 architectural fix \u2014 semantic_type routing extracted to Detect_Semantic_Route pre-routing layer\n"
if v4_line not in cmr_code:
    print("ERROR: Could not find v4 version line in Check_Mutability_Rules")
    sys.exit(1)
cmr_code = cmr_code.replace(v4_line, v4_line + v5_line)

# 1c. Remove entire check #2.5 block
start_marker = "\n\n// 2.5 semantic_type_id detection (T69)\n"
end_marker = "\n// 3. RULE: snapshot and restart are fully immutable"

start_idx = cmr_code.find(start_marker)
end_idx = cmr_code.find(end_marker)

if start_idx == -1:
    print("ERROR: Could not find check #2.5 start marker")
    sys.exit(1)
if end_idx == -1:
    print("ERROR: Could not find check #3 start marker")
    sys.exit(1)

cmr_code = cmr_code[:start_idx] + "\n" + cmr_code[end_idx:]
nodes[cmr_idx]['parameters']['jsCode'] = cmr_code
print("  [OK] Check_Mutability_Rules: removed check #2.5, added v5 header")


# ========== 2. Modify Guard_Semantic_Type_Result upstream reference ==========
gsr_idx = node_map['NQxb_Artifact_Update_v1__Guard_Semantic_Type_Result']
gsr_code = nodes[gsr_idx]['parameters']['jsCode']

old_ref = "NQxb_Artifact_Update_v1__Switch_Update_Mode"
new_ref = "NQxb_Artifact_Update_v1__Detect_Semantic_Route"

if old_ref not in gsr_code:
    print("ERROR: Could not find Switch_Update_Mode reference in Guard_Semantic_Type_Result")
    sys.exit(1)

gsr_code = gsr_code.replace(old_ref, new_ref)
nodes[gsr_idx]['parameters']['jsCode'] = gsr_code
print("  [OK] Guard_Semantic_Type_Result: upstream ref -> Detect_Semantic_Route")


# ========== 3. Remove semantic_type rule from Switch_Update_Mode ==========
sum_idx = node_map['NQxb_Artifact_Update_v1__Switch_Update_Mode']
rules = nodes[sum_idx]['parameters']['rules']['values']

if len(rules) != 4:
    print(f"ERROR: Expected 4 rules in Switch_Update_Mode, found {len(rules)}")
    sys.exit(1)

semantic_rule = rules[3]
conds = semantic_rule.get('conditions', {}).get('conditions', [])
if not conds or conds[0].get('id') != 'semantic-type':
    print("ERROR: Rule at index 3 is not 'semantic-type'")
    sys.exit(1)

rules.pop(3)
print("  [OK] Switch_Update_Mode: removed semantic_type rule (was output 3)")


# ========== 4. Remove semantic_type output from Switch_Update_Mode connections ==========
mode_conns = connections['NQxb_Artifact_Update_v1__Switch_Update_Mode']['main']

if len(mode_conns) != 5:
    print(f"ERROR: Expected 5 outputs in Switch_Update_Mode connections, found {len(mode_conns)}")
    sys.exit(1)

if mode_conns[3][0]['node'] != 'NQxb_Artifact_Update_v1__RPC_Update_Semantic_Type':
    print(f"ERROR: Output 3 doesn't point to RPC_Update_Semantic_Type, found: {mode_conns[3][0]['node']}")
    sys.exit(1)

mode_conns.pop(3)
print("  [OK] Switch_Update_Mode connections: removed output 3 (semantic_type -> RPC)")


# ========== 5. Rewire Fetch_Existing_Spine connection ==========
fetch_key = 'NQxb_Artifact_Update_v1__Fetch_Existing_Spine'
fetch_conns = connections[fetch_key]['main'][0]

if fetch_conns[0]['node'] != 'NQxb_Artifact_Update_v1__Check_Mutability_Rules':
    print(f"ERROR: Fetch_Existing_Spine doesn't connect to Check_Mutability_Rules")
    sys.exit(1)

fetch_conns[0]['node'] = 'NQxb_Artifact_Update_v1__Detect_Semantic_Route'
print("  [OK] Fetch_Existing_Spine: rewired -> Detect_Semantic_Route")


# ========== 6. Add new connections ==========
connections['NQxb_Artifact_Update_v1__Detect_Semantic_Route'] = {
    "main": [[
        {"node": "NQxb_Artifact_Update_v1__Switch_Semantic_Route", "type": "main", "index": 0}
    ]]
}

connections['NQxb_Artifact_Update_v1__Switch_Semantic_Route'] = {
    "main": [
        [{"node": "NQxb_Artifact_Update_v1__RPC_Update_Semantic_Type", "type": "main", "index": 0}],
        [{"node": "NQxb_Artifact_Update_v1__Return_Error_Passthrough", "type": "main", "index": 0}],
        [{"node": "NQxb_Artifact_Update_v1__Check_Mutability_Rules", "type": "main", "index": 0}]
    ]
}
print("  [OK] Added connections for Detect_Semantic_Route and Switch_Semantic_Route")


# ========== 7. Add Detect_Semantic_Route node ==========
detect_code = (
    "// NQxb_Artifact_Update_v1__Detect_Semantic_Route\n"
    "// T69 Architectural Fix: Extract semantic_type routing into dedicated pre-routing layer.\n"
    "// Runs between Fetch_Existing_Spine and Check_Mutability_Rules.\n"
    "// If semantic_type_id is present in extension, validates and routes to RPC directly.\n"
    "// Otherwise, passes through to Check_Mutability_Rules unchanged.\n"
    "\n"
    "const existing = $json;\n"
    "const normalizeNode = $node['NQxb_Artifact_Update_v1__Normalize_Request'].json;\n"
    "const extensionObj = normalizeNode.extension || {};\n"
    "const normalizedTags = normalizeNode._normalized_tags ?? normalizeNode.tags ?? null;\n"
    "const artifact_type = (existing.artifact_type ?? '').trim();\n"
    "\n"
    "// If semantic_type_id NOT in extension, passthrough to Check_Mutability_Rules\n"
    "if (!('semantic_type_id' in extensionObj)) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ...existing,\n"
    "      _semantic_route: 'passthrough'\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// semantic_type_id IS present — run dedicated validation\n"
    "\n"
    "// A. deleted_at guard (CRITICAL — bypasses Check_Mutability_Rules check #5)\n"
    "if (existing.deleted_at !== null && existing.deleted_at !== undefined) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ok: false,\n"
    "      _gw_route: 'error',\n"
    "      error: {\n"
    "        code: 'NOT_FOUND',\n"
    "        message: 'Artifact not found',\n"
    "        details: { artifact_id: existing.artifact_id }\n"
    "      }\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// B. Mixed update with tags\n"
    "if (normalizedTags !== null) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ok: false,\n"
    "      _gw_route: 'error',\n"
    "      error: {\n"
    "        code: 'MIXED_UPDATE_NOT_ALLOWED',\n"
    "        message: 'semantic_type_id update cannot be combined with tags update',\n"
    "        details: {\n"
    "          semantic_type_id_present: true,\n"
    "          tags_present: true,\n"
    "          hint: 'Submit semantic_type_id + reason as a standalone update, then update tags separately'\n"
    "        }\n"
    "      }\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// C. Mixed update with other extension fields\n"
    "const otherKeys = Object.keys(extensionObj).filter(k => k !== 'semantic_type_id' && k !== 'reason');\n"
    "if (otherKeys.length > 0) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ok: false,\n"
    "      _gw_route: 'error',\n"
    "      error: {\n"
    "        code: 'MIXED_UPDATE_NOT_ALLOWED',\n"
    "        message: 'semantic_type_id update cannot be combined with other extension fields',\n"
    "        details: {\n"
    "          semantic_type_id_present: true,\n"
    "          other_fields: otherKeys,\n"
    "          hint: 'Submit semantic_type_id + reason as a standalone update, then update other fields separately'\n"
    "        }\n"
    "      }\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// D. Top-level artifact check\n"
    "const topLevelTypes = ['project', 'snapshot', 'journal', 'restart'];\n"
    "if (!topLevelTypes.includes(artifact_type)) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ok: false,\n"
    "      _gw_route: 'error',\n"
    "      error: {\n"
    "        code: 'SEMANTIC_TYPE_NOT_APPLICABLE',\n"
    "        message: 'semantic_type_id applies only to top-level artifact types',\n"
    "        details: {\n"
    "          artifact_type: artifact_type,\n"
    "          artifact_id: existing.artifact_id,\n"
    "          allowed_types: topLevelTypes\n"
    "        }\n"
    "      }\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// E. Reason required\n"
    "const reason = (extensionObj.reason ?? '').toString().trim();\n"
    "if (!reason) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ok: false,\n"
    "      _gw_route: 'error',\n"
    "      error: {\n"
    "        code: 'VALIDATION_ERROR',\n"
    "        message: 'reason is required for semantic_type_id update',\n"
    "        details: {\n"
    "          field: 'reason',\n"
    "          hint: 'Provide extension.reason when updating semantic_type_id'\n"
    "        }\n"
    "      }\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// F. Success — route to dedicated semantic path\n"
    "return [{\n"
    "  json: {\n"
    "    ok: true,\n"
    "    _semantic_route: 'semantic_type',\n"
    "    _update_mode: 'semantic_type',\n"
    "    artifact_id: existing.artifact_id,\n"
    "    workspace_id: existing.workspace_id,\n"
    "    artifact_type: artifact_type,\n"
    "    _semantic_type_update: {\n"
    "      new_semantic_type_id: extensionObj.semantic_type_id,\n"
    "      reason: reason\n"
    "    },\n"
    "    gw_action: normalizeNode.gw_action,\n"
    "    gw_workspace_id: normalizeNode.gw_workspace_id,\n"
    "    _existing_artifact: existing,\n"
    "    _normalized_request: normalizeNode\n"
    "  }\n"
    "}];\n"
)

detect_node = {
    "parameters": {
        "jsCode": detect_code
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-1984, 528],
    "id": str(uuid.uuid4()),
    "name": "NQxb_Artifact_Update_v1__Detect_Semantic_Route"
}
nodes.append(detect_node)
print(f"  [OK] Added Detect_Semantic_Route node (id: {detect_node['id']})")


# ========== 8. Add Switch_Semantic_Route node ==========
switch_node = {
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
                                "id": "semantic-route-match",
                                "leftValue": "={{ $json._semantic_route }}",
                                "rightValue": "semantic_type",
                                "operator": {
                                    "type": "string",
                                    "operation": "equals"
                                }
                            },
                            {
                                "id": "semantic-route-ok",
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
                                "id": "semantic-route-error",
                                "leftValue": "={{ $json.ok }}",
                                "rightValue": False,
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
    "position": [-1760, 528],
    "id": str(uuid.uuid4()),
    "name": "NQxb_Artifact_Update_v1__Switch_Semantic_Route"
}
nodes.append(switch_node)
print(f"  [OK] Added Switch_Semantic_Route node (id: {switch_node['id']})")


# ========== Write output ==========
with open(filepath, 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=True)

print(f"\nSUCCESS: Workflow updated — {filepath}")
print(f"  Nodes: {original_count} -> {len(nodes)} (+2)")
print(f"  New nodes: Detect_Semantic_Route, Switch_Semantic_Route")
print(f"  Modified nodes: Check_Mutability_Rules, Guard_Semantic_Type_Result, Switch_Update_Mode")
print(f"  Rewired: Fetch_Existing_Spine -> Detect_Semantic_Route (was -> Check_Mutability_Rules)")
print(f"  Removed: semantic_type rule from Switch_Update_Mode (output 3 -> fallback renumbered)")
print(f"  Removed: check #2.5 block (~120 lines) from Check_Mutability_Rules")
