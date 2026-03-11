"""
Build T71 Update workflow from T64 base.
T71: Dependency enforcement for leaf completing.
Adds 4 new nodes, modifies Check_Mutability_Rules, rewires connections.
"""
import json
import os
import sys

base_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "workflows")
input_file = os.path.join(base_dir, "NQxb_Artifact_Update_v1__T64.json")
output_file = os.path.join(base_dir, "NQxb_Artifact_Update_v1__T71.json")

print(f"Reading: {input_file}")
with open(input_file, 'r', encoding='utf-8') as f:
    wf = json.load(f)

print(f"Base workflow: {wf['name']}, {len(wf['nodes'])} nodes")

# ──────────────────────────────────────────────
# 1. Update name and versionId
# ──────────────────────────────────────────────
wf['name'] = 'NQxb_Artifact_Update_v1__T71'
wf['versionId'] = 't71-dependency-enforcement-v1'

# ──────────────────────────────────────────────
# 2. Modify Check_Mutability_Rules jsCode
# ──────────────────────────────────────────────
found = False
for node in wf['nodes']:
    if node['name'] == 'NQxb_Artifact_Update_v1__Check_Mutability_Rules':
        code = node['parameters']['jsCode']

        # 2a. Update comment header
        old_header = "// v3: T64"
        new_header = "// v3: T64\n// v4: T71 \u2014 dependency check flagging for leaf completing"
        assert old_header in code, "FAIL: Could not find v3 header"
        code = code.replace(old_header, new_header, 1)

        # 2b. Add needsDependencyCheck variable after needsParentCheck
        old_flag = (
            "  // 6.7.9 Parent check flagging\n"
            "  const needsParentCheck = (requestedStatus === 'complete') &&\n"
            "                           (artifact_type === 'branch' || artifact_type === 'limb');\n"
            "\n"
            "  // 6.7.10"
        )
        new_flag = (
            "  // 6.7.9 Parent check flagging\n"
            "  const needsParentCheck = (requestedStatus === 'complete') &&\n"
            "                           (artifact_type === 'branch' || artifact_type === 'limb');\n"
            "\n"
            "  // 6.7.9a Dependency check flagging (T71)\n"
            "  const needsDependencyCheck = (requestedStatus === 'complete') && (artifact_type === 'leaf');\n"
            "\n"
            "  // 6.7.10"
        )
        assert old_flag in code, "FAIL: Could not find step 6.7.9 block"
        code = code.replace(old_flag, new_flag, 1)

        # 2c. Add _needs_dependency_check to return payload
        old_ret = "      _needs_parent_check: needsParentCheck,\n      _gw_debug"
        new_ret = "      _needs_parent_check: needsParentCheck,\n      _needs_dependency_check: needsDependencyCheck,\n      _gw_debug"
        assert old_ret in code, "FAIL: Could not find _needs_parent_check in return payload"
        code = code.replace(old_ret, new_ret, 1)

        # 2d. Add needs_dependency_check to _gw_debug
        old_dbg = "        needs_parent_check: needsParentCheck,\n      }\n    }\n  }];\n}"
        new_dbg = "        needs_parent_check: needsParentCheck,\n        needs_dependency_check: needsDependencyCheck,\n      }\n    }\n  }];\n}"
        assert old_dbg in code, "FAIL: Could not find needs_parent_check in _gw_debug"
        code = code.replace(old_dbg, new_dbg, 1)

        node['parameters']['jsCode'] = code
        found = True
        print("  [OK] Check_Mutability_Rules jsCode modified (4 edits)")
        break

if not found:
    print("FATAL: Check_Mutability_Rules node not found")
    sys.exit(1)

# ──────────────────────────────────────────────
# 3. Add 4 new nodes
# ──────────────────────────────────────────────
new_nodes = [
    # Node 1: Switch_Dependency_Check (IF)
    {
        "parameters": {
            "conditions": {
                "options": {
                    "caseSensitive": True,
                    "leftValue": "",
                    "typeValidation": "strict"
                },
                "conditions": [
                    {
                        "id": "needs-dependency-check",
                        "leftValue": "={{ $json._needs_dependency_check }}",
                        "rightValue": True,
                        "operator": {
                            "type": "boolean",
                            "operation": "true"
                        }
                    }
                ],
                "combinator": "and"
            },
            "options": {}
        },
        "type": "n8n-nodes-base.if",
        "typeVersion": 2,
        "position": [-656, 640],
        "id": "a1b2c3d4-0009-4000-8000-000000000009",
        "name": "NQxb_Artifact_Update_v1__Switch_Dependency_Check"
    },
    # Node 2: DB_Query_Incomplete_Dependencies (HTTP Request → RPC)
    {
        "parameters": {
            "method": "POST",
            "url": "https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/rpc/check_leaf_dependencies",
            "authentication": "predefinedCredentialType",
            "nodeCredentialType": "supabaseApi",
            "sendBody": True,
            "specifyBody": "json",
            "jsonBody": "={{ JSON.stringify({ p_artifact_id: $json.artifact_id, p_workspace_id: $json.workspace_id }) }}",
            "options": {}
        },
        "type": "n8n-nodes-base.httpRequest",
        "typeVersion": 4.2,
        "position": [-432, 640],
        "id": "a1b2c3d4-000a-4000-8000-00000000000a",
        "name": "NQxb_Artifact_Update_v1__DB_Query_Incomplete_Dependencies",
        "alwaysOutputData": True,
        "credentials": {
            "supabaseApi": {
                "id": "n4R4JdOIV9zrCGIT",
                "name": "Qwrk Supabase \u2013 Kernel v1"
            }
        },
        "onError": "continueErrorOutput"
    },
    # Node 3: Guard_Dependencies_Complete (Code)
    {
        "parameters": {
            "jsCode": (
                "// NQxb_Artifact_Update_v1__Guard_Dependencies_Complete\n"
                "// T71: Check if RPC found any incomplete dependencies.\n"
                "// check_leaf_dependencies returns [] if all complete (or no deps).\n"
                "// With alwaysOutputData, 0 rows \u2192 {json:{}} (no depends_on_artifact_id).\n"
                "\n"
                "const queryResult = $json;\n"
                "const parentData = $node['NQxb_Artifact_Update_v1__Switch_Dependency_Check'].json;\n"
                "\n"
                "if (queryResult && queryResult.depends_on_artifact_id) {\n"
                "  // Found an incomplete dependency \u2014 block completion\n"
                "  return [{\n"
                "    json: {\n"
                "      ok: false,\n"
                "      _gw_route: 'error',\n"
                "      error: {\n"
                "        code: 'DEPENDENCY_INCOMPLETE',\n"
                "        message: 'Dependency not complete',\n"
                "        details: {\n"
                "          artifact_id: parentData.artifact_id,\n"
                "          artifact_type: 'leaf',\n"
                "          incomplete_dependency: {\n"
                "            artifact_id: queryResult.depends_on_artifact_id,\n"
                "            execution_status: queryResult.execution_status ?? null\n"
                "          },\n"
                "          hint: \"All dependencies must have execution_status = 'complete' before this leaf can be marked complete.\"\n"
                "        }\n"
                "      }\n"
                "    }\n"
                "  }];\n"
                "}\n"
                "\n"
                "// All deps complete (or no deps) \u2014 pass through for spine update\n"
                "return [{ json: parentData }];\n"
            )
        },
        "type": "n8n-nodes-base.code",
        "typeVersion": 2,
        "position": [-208, 640],
        "id": "a1b2c3d4-000b-4000-8000-00000000000b",
        "name": "NQxb_Artifact_Update_v1__Guard_Dependencies_Complete"
    },
    # Node 4: Switch_Dependencies_Result (Switch)
    {
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
                                    "id": "dependency-error"
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
                                    "id": "dependency-ok"
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
        "position": [16, 640],
        "id": "a1b2c3d4-000c-4000-8000-00000000000c",
        "name": "NQxb_Artifact_Update_v1__Switch_Dependencies_Result"
    }
]

wf['nodes'].extend(new_nodes)
print(f"  [OK] Added 4 new nodes. Total: {len(wf['nodes'])}")

# ──────────────────────────────────────────────
# 4. Modify connections
# ──────────────────────────────────────────────

# 4a. Rewire Switch_Parent_Check false → Switch_Dependency_Check
#     (was: false → Prepare_Spine_Field_Update)
pc = wf['connections']['NQxb_Artifact_Update_v1__Switch_Parent_Check']
old_target = pc['main'][1][0]['node']
pc['main'][1] = [
    {"node": "NQxb_Artifact_Update_v1__Switch_Dependency_Check", "type": "main", "index": 0}
]
print(f"  [OK] Rewired Switch_Parent_Check false: {old_target} -> Switch_Dependency_Check")

# 4b. Switch_Dependency_Check connections
wf['connections']['NQxb_Artifact_Update_v1__Switch_Dependency_Check'] = {
    "main": [
        # True (needs dep check) → DB_Query_Incomplete_Dependencies
        [{"node": "NQxb_Artifact_Update_v1__DB_Query_Incomplete_Dependencies", "type": "main", "index": 0}],
        # False (no dep check needed) → Prepare_Spine_Field_Update (bypass)
        [{"node": "NQxb_Artifact_Update_v1__Prepare_Spine_Field_Update", "type": "main", "index": 0}]
    ]
}

# 4c. DB_Query_Incomplete_Dependencies connections
wf['connections']['NQxb_Artifact_Update_v1__DB_Query_Incomplete_Dependencies'] = {
    "main": [
        # Main output → Guard_Dependencies_Complete
        [{"node": "NQxb_Artifact_Update_v1__Guard_Dependencies_Complete", "type": "main", "index": 0}],
        # Error output → Return_Error_Passthrough
        [{"node": "NQxb_Artifact_Update_v1__Return_Error_Passthrough", "type": "main", "index": 0}]
    ]
}

# 4d. Guard_Dependencies_Complete connections
wf['connections']['NQxb_Artifact_Update_v1__Guard_Dependencies_Complete'] = {
    "main": [
        [{"node": "NQxb_Artifact_Update_v1__Switch_Dependencies_Result", "type": "main", "index": 0}]
    ]
}

# 4e. Switch_Dependencies_Result connections
wf['connections']['NQxb_Artifact_Update_v1__Switch_Dependencies_Result'] = {
    "main": [
        # Output 0: ok === false → Return_Error_Passthrough
        [{"node": "NQxb_Artifact_Update_v1__Return_Error_Passthrough", "type": "main", "index": 0}],
        # Output 1: ok === true → Prepare_Spine_Field_Update
        [{"node": "NQxb_Artifact_Update_v1__Prepare_Spine_Field_Update", "type": "main", "index": 0}],
        # Fallback → Return_Error_Passthrough
        [{"node": "NQxb_Artifact_Update_v1__Return_Error_Passthrough", "type": "main", "index": 0}]
    ]
}

print(f"  [OK] Added 4 new connection blocks. Total: {len(wf['connections'])} entries")

# ──────────────────────────────────────────────
# 5. Write output
# ──────────────────────────────────────────────
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"\n{'='*60}")
print(f"Written: {output_file}")
print(f"Name: {wf['name']}")
print(f"Nodes: {len(wf['nodes'])} (was 31, now 35)")
print(f"Connections: {len(wf['connections'])} entries")
print(f"versionId: {wf['versionId']}")
print(f"id: {wf['id']} (unchanged — imports in-place)")
print(f"{'='*60}")

# Verification: list all node names
print("\nNode inventory:")
for i, n in enumerate(wf['nodes']):
    marker = " [NEW]" if n['name'] in [
        'NQxb_Artifact_Update_v1__Switch_Dependency_Check',
        'NQxb_Artifact_Update_v1__DB_Query_Incomplete_Dependencies',
        'NQxb_Artifact_Update_v1__Guard_Dependencies_Complete',
        'NQxb_Artifact_Update_v1__Switch_Dependencies_Result'
    ] else ""
    print(f"  {i+1:2d}. {n['name']}{marker}")
