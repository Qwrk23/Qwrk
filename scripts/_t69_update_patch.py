"""T69 Phase 3: Create Update workflow v_T69 from T71 base — add semantic type enforcement"""
import json, uuid, os, copy

base_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'workflows', 'NQxb_Artifact_Update_v1__T71.json')
output_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'workflows', 'NQxb_Artifact_Update_v1__T69.json')

with open(base_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Rename workflow
data['name'] = 'NQxb_Artifact_Update_v1__T69'

# ============================================================
# 1. Modify Check_Mutability_Rules: insert check #2.5
# ============================================================

CHECK_25_CODE = """// 2.5 semantic_type_id detection (T69)
// If extension contains semantic_type_id, route to dedicated path.
// This check runs BEFORE type-specific immutability checks because
// semantic_type_id update is valid even for immutable types (snapshot, restart).
const extensionObj = normalizeNode.extension || {};
const extensionKeyList = Object.keys(extensionObj);

if ('semantic_type_id' in extensionObj) {
  const topLevelTypes = ['project', 'snapshot', 'journal', 'restart'];

  // 2.5.1 Mixed update guard: semantic_type_id + tags
  if (normalizedTags !== null) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'MIXED_UPDATE_NOT_ALLOWED',
          message: 'semantic_type_id update cannot be combined with tags update',
          details: {
            semantic_type_id_present: true,
            tags_present: true,
            hint: 'Submit semantic_type_id + reason as a standalone update, then update tags separately'
          }
        },
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_type: artifact_type,
        artifact_id: existing.artifact_id,
      }
    }];
  }

  // 2.5.2 Mixed update guard: semantic_type_id + other extension fields
  const otherExtKeys = extensionKeyList.filter(k => k !== 'semantic_type_id' && k !== 'reason');
  if (otherExtKeys.length > 0) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'MIXED_UPDATE_NOT_ALLOWED',
          message: 'semantic_type_id update cannot be combined with other extension fields',
          details: {
            semantic_type_id_present: true,
            other_fields: otherExtKeys,
            hint: 'Submit semantic_type_id + reason as a standalone update, then update other fields separately'
          }
        },
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_type: artifact_type,
        artifact_id: existing.artifact_id,
      }
    }];
  }

  // 2.5.3 Top-level type check
  if (!topLevelTypes.includes(artifact_type)) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'SEMANTIC_TYPE_NOT_APPLICABLE',
          message: 'semantic_type_id applies only to top-level artifact types',
          details: {
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            allowed_types: topLevelTypes
          }
        },
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_type: artifact_type,
        artifact_id: existing.artifact_id,
      }
    }];
  }

  // 2.5.4 Reason validation
  const semanticReason = (extensionObj.reason ?? '').toString().trim();
  if (!semanticReason) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: 'reason is required for semantic_type_id update',
          details: {
            field: 'reason',
            hint: 'Provide extension.reason when updating semantic_type_id'
          }
        },
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_type: artifact_type,
        artifact_id: existing.artifact_id,
      }
    }];
  }

  // 2.5.5 Route to dedicated semantic type update
  return [{
    json: {
      ok: true,
      _gw_route: 'ok',
      _update_mode: 'semantic_type',
      gw_action: normalizeNode.gw_action ?? 'artifact.update',
      gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
      artifact_id: existing.artifact_id,
      workspace_id: existing.workspace_id,
      artifact_type: artifact_type,
      _semantic_type_update: {
        new_semantic_type_id: extensionObj.semantic_type_id,
        reason: semanticReason,
      },
      _normalized_request: normalizeNode,
      _existing_artifact: existing,
      _gw_debug: {
        ...(normalizeNode._gw_debug ?? {}),
        mutability: 'semantic_type_dedicated',
        operation: 'UPDATE',
      }
    }
  }];
}

"""

for node in data['nodes']:
    if 'Check_Mutability' in node.get('name', ''):
        code = node['parameters']['jsCode']
        # Find the exact boundary: end of tags_only block, before immutability check
        # The tags_only block ends with "}\n\n" and check 3 starts with "// 3. RULE: snapshot"
        marker = '// 3. RULE: snapshot and restart are fully immutable'
        idx = code.find(marker)
        if idx < 0:
            # Try alternative
            marker = '// 3. RULE:'
            idx = code.find(marker)
        if idx < 0:
            print("ERROR: Could not find check #3 marker in Check_Mutability_Rules")
            exit(1)

        # Insert check 2.5 before check 3
        new_code = code[:idx] + CHECK_25_CODE + code[idx:]

        # Also update the comment header to mention check 2.5
        old_header = "// 2. Tags-only bypass (all types)"
        new_header = "// 2. Tags-only bypass (all types)\n// 2.5 semantic_type_id detection (T69) \u2014 dedicated RPC route"
        new_code = new_code.replace(old_header, new_header, 1)

        node['parameters']['jsCode'] = new_code
        print(f"  Check_Mutability_Rules: inserted check #2.5 ({len(CHECK_25_CODE)} chars)")
        break

# ============================================================
# 2. Modify Switch_Update_Mode: add semantic_type case
# ============================================================

for node in data['nodes']:
    if 'Switch_Update_Mode' in node.get('name', ''):
        rules = node['parameters']['rules']['values']
        # Add new case: semantic_type
        new_case = {
            "conditions": {
                "options": {
                    "caseSensitive": True,
                    "leftValue": "",
                    "typeValidation": "strict",
                    "version": 3
                },
                "conditions": [
                    {
                        "id": "semantic-type",
                        "leftValue": "={{ $json._update_mode }}",
                        "rightValue": "semantic_type",
                        "operator": {
                            "type": "string",
                            "operation": "equals"
                        }
                    }
                ],
                "combinator": "and"
            }
        }
        rules.append(new_case)
        print(f"  Switch_Update_Mode: added case 3 (semantic_type). Now {len(rules)} cases + fallback")
        break

# ============================================================
# 3. Create RPC_Update_Semantic_Type node
# ============================================================

node_rpc = {
    "parameters": {
        "method": "POST",
        "url": "https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/rpc/update_semantic_type",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "supabaseApi",
        "sendHeaders": True,
        "headerParameters": {
            "parameters": [
                {
                    "name": "Content-Type",
                    "value": "application/json"
                },
                {
                    "name": "Prefer",
                    "value": "return=representation"
                }
            ]
        },
        "sendBody": True,
        "specifyBody": "json",
        "jsonBody": "={\n  \"p_artifact_id\": \"{{ $json.artifact_id }}\",\n  \"p_new_semantic_type_id\": \"{{ $json._semantic_type_update.new_semantic_type_id }}\",\n  \"p_reason\": \"{{ $json._semantic_type_update.reason }}\",\n  \"p_actor_id\": null\n}",
        "options": {}
    },
    "type": "n8n-nodes-base.httpRequest",
    "typeVersion": 4.2,
    "position": [-656, 960],
    "id": str(uuid.uuid4()),
    "name": "NQxb_Artifact_Update_v1__RPC_Update_Semantic_Type",
    "alwaysOutputData": True,
    "onError": "continueErrorOutput",
    "credentials": {
        "supabaseApi": {
            "id": "n4R4JdOIV9zrCGIT",
            "name": "Qwrk Supabase \u2013 Kernel v1"
        }
    }
}

data['nodes'].append(node_rpc)
print(f"  Created RPC_Update_Semantic_Type node")

# ============================================================
# 4. Create Guard_Semantic_Type_Result node
# ============================================================

guard_code = (
    "// NQxb_Artifact_Update_v1__Guard_Semantic_Type_Result\n"
    "// T69: Format RPC response into Gateway response envelope\n"
    "\n"
    "const rpcResult = $json;\n"
    "const upstream = $node['NQxb_Artifact_Update_v1__Switch_Update_Mode'].json;\n"
    "\n"
    "// RPC returned error\n"
    "if (rpcResult.ok === false) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ok: false,\n"
    "      _gw_route: 'error',\n"
    "      gw_action: upstream.gw_action ?? 'artifact.update',\n"
    "      gw_workspace_id: upstream.gw_workspace_id ?? null,\n"
    "      artifact_type: upstream.artifact_type ?? null,\n"
    "      artifact_id: upstream.artifact_id ?? null,\n"
    "      error: rpcResult.error ?? {\n"
    "        code: 'INTERNAL_ERROR',\n"
    "        message: 'RPC returned error without envelope'\n"
    "      },\n"
    "      timestamp: new Date().toISOString()\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// RPC returned noop\n"
    "if (rpcResult.noop === true) {\n"
    "  return [{\n"
    "    json: {\n"
    "      ok: true,\n"
    "      _gw_route: 'ok',\n"
    "      gw_action: upstream.gw_action ?? 'artifact.update',\n"
    "      artifact_id: upstream.artifact_id,\n"
    "      artifact_type: upstream.artifact_type,\n"
    "      operation: 'SEMANTIC_TYPE_UPDATE',\n"
    "      noop: true,\n"
    "      message: rpcResult.message ?? 'semantic_type_id unchanged',\n"
    "      timestamp: new Date().toISOString()\n"
    "    }\n"
    "  }];\n"
    "}\n"
    "\n"
    "// RPC returned success\n"
    "return [{\n"
    "  json: {\n"
    "    ok: true,\n"
    "    _gw_route: 'ok',\n"
    "    gw_action: upstream.gw_action ?? 'artifact.update',\n"
    "    artifact_id: rpcResult.artifact_id ?? upstream.artifact_id,\n"
    "    artifact_type: upstream.artifact_type,\n"
    "    operation: 'SEMANTIC_TYPE_UPDATE',\n"
    "    old_semantic_type_id: rpcResult.old_semantic_type_id ?? null,\n"
    "    new_semantic_type_id: rpcResult.new_semantic_type_id ?? null,\n"
    "    version: rpcResult.version ?? null,\n"
    "    timestamp: new Date().toISOString()\n"
    "  }\n"
    "}];\n"
)

node_guard = {
    "parameters": {
        "jsCode": guard_code
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-432, 960],
    "id": str(uuid.uuid4()),
    "name": "NQxb_Artifact_Update_v1__Guard_Semantic_Type_Result"
}

data['nodes'].append(node_guard)
print(f"  Created Guard_Semantic_Type_Result node")

# ============================================================
# 5. Wire connections
# ============================================================

conn = data['connections']

# Switch_Update_Mode now has 4 cases + fallback = 5 outputs
# Current outputs: 0=tags_only, 1=spine_fields, 2=noop, 3=fallback(extension)
# New:             0=tags_only, 1=spine_fields, 2=noop, 3=semantic_type, 4=fallback(extension)
#
# The current output 3 (fallback/extra) -> Switch_Type_For_Update
# We need to add output 3 (semantic_type) -> RPC, and move fallback to output 4

switch_conn = conn['NQxb_Artifact_Update_v1__Switch_Update_Mode']['main']

# Current state should be: [0]=tags, [1]=spine, [2]=noop, [3]=fallback(extension)
assert len(switch_conn) == 4, f"Expected 4 outputs, got {len(switch_conn)}"

# Save current fallback (output 3)
fallback_targets = switch_conn[3]

# Insert semantic_type at position 3, push fallback to position 4
switch_conn[3] = [
    {
        "node": "NQxb_Artifact_Update_v1__RPC_Update_Semantic_Type",
        "type": "main",
        "index": 0
    }
]
switch_conn.append(fallback_targets)

print(f"  Switch_Update_Mode connections: {len(switch_conn)} outputs")

# RPC -> Guard
conn['NQxb_Artifact_Update_v1__RPC_Update_Semantic_Type'] = {
    "main": [
        [
            {
                "node": "NQxb_Artifact_Update_v1__Guard_Semantic_Type_Result",
                "type": "main",
                "index": 0
            }
        ]
    ]
}

# Guard_Semantic_Type_Result is terminal (no outgoing connections needed)
# Sub-workflow returns its output directly to Gateway caller
print(f"  RPC -> Guard connection wired")
print(f"  Guard_Semantic_Type_Result is terminal (sub-workflow return)")

# ============================================================
# 6. Write output file
# ============================================================

with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)

print(f"\nWrote: {output_path}")

# ============================================================
# 7. Verification
# ============================================================

print(f"\n=== VERIFICATION ===")
print(f"Total nodes: {len(data['nodes'])}")
print(f"Total connection entries: {len(conn)}")

# Check for orphan connections
node_names = {n['name'] for n in data['nodes']}
errors = []
for source, outputs in conn.items():
    if source not in node_names:
        errors.append(f"Connection source not a node: {source}")
    for oi, targets in enumerate(outputs.get('main', [])):
        for t in targets:
            if t['node'] not in node_names:
                errors.append(f"{source} output {oi} -> MISSING: {t['node']}")

if errors:
    for e in errors:
        print(f"  ERROR: {e}")
else:
    print("  No orphan connections")

# Print new semantic_type chain
print(f"\n=== T69 SEMANTIC TYPE CHAIN ===")
sm = conn['NQxb_Artifact_Update_v1__Switch_Update_Mode']['main']
for i, targets in enumerate(sm):
    for t in targets:
        labels = ['tags_only', 'spine_fields', 'noop', 'semantic_type', 'fallback(extension)']
        label = labels[i] if i < len(labels) else f'output_{i}'
        print(f"  Switch_Update_Mode [{label}] -> {t['node']}")

rpc_conn = conn.get('NQxb_Artifact_Update_v1__RPC_Update_Semantic_Type', {})
for targets in rpc_conn.get('main', []):
    for t in targets:
        print(f"  RPC_Update_Semantic_Type -> {t['node']}")

print(f"  Guard_Semantic_Type_Result -> (terminal)")
