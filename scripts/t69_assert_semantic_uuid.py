"""
T69 Assert_Semantic_UUID: Last-mile defense-in-depth guard

Adds Assert_Semantic_UUID Code node between Switch_InsertOrUpdate[1] and DB_Insert_Spine.
Ensures semantic_type_id is a valid UUID for top-level types, or null for non-top-level types,
before any write to qxb_artifact.

Changes:
1. Add Assert_Semantic_UUID (Code node)
2. Rewire: Switch_InsertOrUpdate[1] -> Assert_Semantic_UUID -> DB_Insert_Spine
3. Wire Assert error output -> Return_Response (error path)
4. Add SEMANTIC_TYPE_RESOLUTION_FAILED to Return_Response allowlist

Execute via: python scripts/t69_assert_semantic_uuid.py
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
# STEP 1: Add Assert_Semantic_UUID (Code node)
# ============================================================

assert_id = str(uuid.uuid4())
assert_name = f"{prefix}Assert_Semantic_UUID"

# Verify node doesn't already exist
for n in nodes:
    if n["name"] == assert_name:
        raise RuntimeError(f"Node {assert_name} already exists -- aborting")

assert_code = """// NQxb_Artifact_Save_v1__Assert_Semantic_UUID
// T69: Last-mile defense-in-depth — assert semantic_type_id is UUID before DB write.
// Top-level types (project/snapshot/journal/restart): MUST be a valid UUID.
// Non-top-level types: MUST be null (semantic_type_id not applicable).
// This guard fires ONLY if upstream resolution failed silently.

const req = $json;
const semanticTypeId = req.semantic_type_id;
const artifactType = (req.artifact_type ?? '').trim();

const TOP_LEVEL_TYPES = ['project', 'snapshot', 'journal', 'restart'];
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

if (TOP_LEVEL_TYPES.includes(artifactType)) {
  // Top-level: semantic_type_id MUST be a valid UUID
  if (!semanticTypeId || !UUID_REGEX.test(semanticTypeId)) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        gw_action: req.gw_action ?? 'artifact.save',
        gw_workspace_id: req.gw_workspace_id ?? null,
        artifact_type: artifactType,
        error: {
          code: 'SEMANTIC_TYPE_RESOLUTION_FAILED',
          message: 'semantic_type_id must be a resolved UUID before database write',
          details: {
            artifact_type: artifactType,
            semantic_type_id: semanticTypeId ?? null,
            hint: 'Semantic type must be resolved through registry before insert. This is a defense-in-depth assertion — upstream resolution may have failed silently.'
          }
        },
        timestamp: new Date().toISOString()
      }
    }];
  }
} else {
  // Non-top-level: semantic_type_id MUST be null
  if (semanticTypeId != null && semanticTypeId !== '') {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        gw_action: req.gw_action ?? 'artifact.save',
        gw_workspace_id: req.gw_workspace_id ?? null,
        artifact_type: artifactType,
        error: {
          code: 'SEMANTIC_TYPE_RESOLUTION_FAILED',
          message: 'Non-top-level artifact types must not have semantic_type_id at insert time',
          details: {
            artifact_type: artifactType,
            semantic_type_id: semanticTypeId,
            hint: 'semantic_type_id is only valid for top-level types (project, snapshot, journal, restart)'
          }
        },
        timestamp: new Date().toISOString()
      }
    }];
  }
}

// Assertion passed — forward to DB_Insert_Spine
return [{ json: req }];"""

# Position: between Switch_InsertOrUpdate [-1152, 720] and DB_Insert_Spine [-896, 400]
# Midpoint x = (-1152 + -896) / 2 = -1024, y = closer to insert path = 400
assert_node = {
    "parameters": {
        "jsCode": assert_code
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-1024, 400],
    "id": assert_id,
    "name": assert_name
}

nodes.append(assert_node)
print(f"  [OK] Added Assert_Semantic_UUID node (id: {assert_id})")

# ============================================================
# STEP 2: Rewire Switch_InsertOrUpdate[1] -> Assert -> DB_Insert_Spine
# ============================================================

switch_name = f"{prefix}Switch_InsertOrUpdate"
insert_spine_name = f"{prefix}DB_Insert_Spine"
return_response_name = f"{prefix}Return_Response"

# Verify current wiring: Switch[1] -> DB_Insert_Spine
old_output_1 = connections[switch_name]["main"][1]
assert any(t["node"] == insert_spine_name for t in old_output_1), \
    f"Expected Switch_InsertOrUpdate[1] to point to {insert_spine_name}, got {old_output_1}"

# Rewire: Switch[1] -> Assert_Semantic_UUID
connections[switch_name]["main"][1] = [
    {"node": assert_name, "type": "main", "index": 0}
]
print(f"  [OK] Rewired Switch_InsertOrUpdate[1] -> Assert_Semantic_UUID")

# Wire: Assert_Semantic_UUID -> DB_Insert_Spine (passthrough on success)
# Assert is a Code node with single output — success items go to output 0
connections[assert_name] = {
    "main": [
        [{"node": insert_spine_name, "type": "main", "index": 0}]
    ]
}
print(f"  [OK] Wired Assert_Semantic_UUID -> DB_Insert_Spine")

# Note: Assert produces error envelopes in the main output (same pattern as Guard_Semantic_Type).
# These have _gw_route:'error' and will flow through DB_Insert_Spine which has onError:continueErrorOutput.
# HOWEVER, that's wrong — error envelopes should NOT reach DB_Insert_Spine.
# Fix: Route Assert errors directly to Return_Response.
#
# The Code node only has one output (main[0]). Both success and error envelopes go there.
# We need a different approach: add a lightweight switch after Assert, OR use the same
# pattern as Guard_Semantic_Type where the error envelope flows through Switch_Semantic_Type_Result.
#
# Simplest approach: Assert node outputs go to DB_Insert_Spine. If Assert fails,
# the Supabase INSERT will fail (bad payload), and DB_Insert_Spine's error output
# routes to Return_Response. But the error message would be a DB error, not our clean envelope.
#
# Better approach: Since Code nodes have only 1 output, we need to split on _gw_route.
# But adding a Switch node adds complexity. Let's use a different pattern:
# Make the Assert node a "gate" — pass the error envelope directly to Return_Response
# by having Assert_Semantic_UUID connected to BOTH DB_Insert_Spine AND Return_Response,
# and using _gw_route to determine which path processes it.
#
# Actually, the cleanest approach: Connect Assert -> a mini Switch that routes on _gw_route.
# But that's 2 nodes for 1 guard.
#
# Simplest correct approach: Connect Assert output 0 to a Switch_Assert_Result node
# that routes ok=false to Return_Response and ok!=false (passthrough) to DB_Insert_Spine.

# Let's add a lightweight switch node
switch_assert_id = str(uuid.uuid4())
switch_assert_name = f"{prefix}Switch_Assert_Result"

switch_assert_node = {
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
    "position": [-896, 480],
    "id": switch_assert_id,
    "name": switch_assert_name
}

nodes.append(switch_assert_node)
print(f"  [OK] Added Switch_Assert_Result node (id: {switch_assert_id})")

# Now fix the wiring:
# Assert_Semantic_UUID -> Switch_Assert_Result
connections[assert_name] = {
    "main": [
        [{"node": switch_assert_name, "type": "main", "index": 0}]
    ]
}

# Move DB_Insert_Spine to make room (shift right)
for n in nodes:
    if n["name"] == insert_spine_name:
        n["position"] = [-672, 400]
        print(f"  [OK] Moved DB_Insert_Spine to [-672, 400]")
        break

# Switch_Assert_Result:
#   [0] ok=false -> Return_Response (error)
#   [1] fallback (ok!=false, i.e. passthrough) -> DB_Insert_Spine
connections[switch_assert_name] = {
    "main": [
        [{"node": return_response_name, "type": "main", "index": 0}],
        [{"node": insert_spine_name, "type": "main", "index": 0}]
    ]
}
print(f"  [OK] Wired Switch_Assert_Result[0] -> Return_Response (error)")
print(f"  [OK] Wired Switch_Assert_Result[1] -> DB_Insert_Spine (passthrough)")

# ============================================================
# STEP 3: Add SEMANTIC_TYPE_RESOLUTION_FAILED to Return_Response allowlist
# ============================================================

return_response_found = False
for n in nodes:
    if n["name"] == return_response_name:
        code = n["parameters"]["jsCode"]

        # Find the allowlist and add the new code
        old_line = "  'SEMANTIC_TYPE_NOT_APPLICABLE',"
        new_line = "  'SEMANTIC_TYPE_NOT_APPLICABLE',\n  'SEMANTIC_TYPE_RESOLUTION_FAILED',"

        assert old_line in code, \
            f"Expected to find '{old_line}' in Return_Response jsCode"

        code = code.replace(old_line, new_line)
        n["parameters"]["jsCode"] = code
        return_response_found = True
        print(f"  [OK] Added SEMANTIC_TYPE_RESOLUTION_FAILED to Return_Response allowlist")
        break

assert return_response_found, f"Node {return_response_name} not found"

# ============================================================
# WRITE
# ============================================================

with open(filepath, 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=True)

node_count_after = len(nodes)

print(f"\nSUCCESS: Workflow updated -> {filepath}")
print(f"  Nodes: {node_count_before} -> {node_count_after} (+{node_count_after - node_count_before})")
print(f"  Added: Assert_Semantic_UUID (Code -- last-mile UUID assertion)")
print(f"  Added: Switch_Assert_Result (Switch -- route error/passthrough)")
print(f"  Modified: Return_Response (allowlist += SEMANTIC_TYPE_RESOLUTION_FAILED)")
print(f"  Rewired: Switch_InsertOrUpdate[1] -> Assert -> Switch_Assert -> DB_Insert_Spine")
print(f"  Error path: Switch_Assert_Result[0] -> Return_Response")
print(f"  Moved: DB_Insert_Spine to [-672, 400] (make room for new nodes)")
