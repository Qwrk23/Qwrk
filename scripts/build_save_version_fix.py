"""
Save v48 -> v49: Version field fix
===================================
Patches Normalize_Saved_ID and Build_Response_Context to extract and
forward `version` from Supabase INSERT response to Return_Response.

Changes:
  1. Normalize_Saved_ID: extract version from Supabase response (same
     multi-location pattern as artifact_id)
  2. Build_Response_Context: forward saved_version to Merge output

Input:  workflows/NQxb_Artifact_Save_v1 (48).json
Output: workflows/NQxb_Artifact_Save_v1 (49).json
"""

import json
import os

WORKFLOWS_DIR = os.path.join(os.path.dirname(__file__), '..', 'workflows')
SAVE_INPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Artifact_Save_v1 (48).json')
SAVE_OUTPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Artifact_Save_v1 (49).json')


# ============================================================================
# PATCH 1: Normalize_Saved_ID -- extract version
# ============================================================================

NORMALIZE_SAVED_ID_NEW = r'''// NQxb_Artifact_Save_v1__Normalize_Saved_ID
// Purpose: Extract artifact_id AND version from Supabase INSERT response
// AND carry forward key request fields needed by downstream nodes.
// v1.1: Added version extraction (Sapling A -- version field fix)

const raw = $json ?? {};

// Pull request (canonical) from Normalize_Request node so we don't lose context
const req = $node["NQxb_Artifact_Save_v1__Normalize_Request"]?.json ?? {};

// Try multiple possible locations for artifact_id in Supabase responses
// PostgREST with Prefer:return=representation returns the row directly
// or as data[0] depending on n8n HTTP node version
const saved_artifact_id =
  raw.artifact_id ||
  raw.id ||
  raw.data?.[0]?.artifact_id ||
  raw.data?.[0]?.id ||
  null;

// Extract version from same locations as artifact_id
const saved_version =
  raw.version ??
  raw.data?.[0]?.version ??
  null;

if (!saved_artifact_id) {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "SAVE_ID_MISSING",
          message: "Could not extract saved artifact_id from Supabase INSERT response",
          details: {
            keys_present: Object.keys(raw),
          },
        },
      },
    },
  ];
}

// Output: keep insert response, carry forward lifecycle fields AND version
return [
  {
    json: {
      saved_artifact_id,
      saved_version: saved_version,
      lifecycle_stage: req.extension?.lifecycle_stage ?? null,
      operational_status: req.extension?.operational_state?.status ?? "active",
      state_reason: req.extension?.state_reason ?? null,
      _insert_response: raw,
    },
  },
];

'''


# ============================================================================
# PATCH 2: Build_Response_Context -- forward version
# ============================================================================

BUILD_RESPONSE_CONTEXT_NEW = r'''// NQxb_Artifact_Save_v1__Build_Response_Context
// Purpose: Create a "response context" item that survives Supabase nodes overwriting $json.
// This node runs after Normalize_Saved_ID and feeds Merge Input 0.
// v1.1: Forward saved_version (Sapling A -- version field fix)

const j = $json ?? {};

// Authoritative request snapshot
const reqNode = $node["NQxb_Artifact_Save_v1__Normalize_Request"]?.json ?? {};

// Authoritative owner-source from the node that sets it (survives overwrites)
const ownerNode = $node["NQxb_Artifact_Save_v1__Set_Owner_User_ID_MVP"]?.json ?? {};

// Frozen payload (authoritative for snapshot/restart)
const frozenNode = $node["NQxb_Artifact_Save_v1__Freeze_Extension_Payload"]?.json ?? {};
const frozen_payload = frozenNode._frozen_extension_payload ?? null;

// Version from Normalize_Saved_ID
const savedIdNode = $node["NQxb_Artifact_Save_v1__Normalize_Saved_ID"]?.json ?? {};
const saved_version = savedIdNode.saved_version ?? j.saved_version ?? null;

// Resolve artifact_type/workspace from normalized request
const artifact_type =
  reqNode.req_artifact_type ??
  reqNode.artifact_type ??
  null;

const workspace_id =
  reqNode.req_workspace_id ??
  reqNode.gw_workspace_id ??
  reqNode.workspace_id ??
  null;

// Saved artifact id (post spine insert)
const saved_artifact_id =
  j.saved_artifact_id ??
  j.artifact_id ??
  null;

// Request-time extension intent (payload etc.)
const req_extension =
  (reqNode.req_extension && typeof reqNode.req_extension === "object" && reqNode.req_extension !== null)
    ? reqNode.req_extension
    : (reqNode.extension && typeof reqNode.extension === "object" && reqNode.extension !== null)
      ? reqNode.extension
      : {};

// Action / operation
const gw_action = reqNode.gw_action ?? "artifact.save";
const is_update =
  typeof reqNode.is_update === "boolean"
    ? reqNode.is_update
    : false;

const operation = is_update ? "UPDATE" : "INSERT";

// Context item to merge with extension insert result
const out = {
  gw_action,
  artifact_type,
  workspace_id,
  saved_artifact_id,
  artifact_id: saved_artifact_id,
  saved_version,
  is_update,
  operation,
  extension: req_extension,

  // Carry frozen payload forward so Return_Response can be DB-truth aligned after Merge
  _frozen_extension_payload: frozen_payload,
};

return [{ json: out }];
'''


def find_node(workflow, name):
    for i, node in enumerate(workflow['nodes']):
        if node.get('name') == name:
            return i, node
    return None, None


def patch_code_node(workflow, node_name, new_code):
    idx, node = find_node(workflow, node_name)
    if idx is None:
        raise ValueError(f"Node not found: {node_name}")
    old_code = node['parameters'].get('jsCode', '')
    node['parameters']['jsCode'] = new_code
    print(f"  PATCHED: {node_name}")
    print(f"    Old: {len(old_code)} chars -> New: {len(new_code)} chars")


def main():
    with open(SAVE_INPUT, 'r', encoding='utf-8') as f:
        save_wf = json.load(f)

    patch_code_node(save_wf, 'NQxb_Artifact_Save_v1__Normalize_Saved_ID', NORMALIZE_SAVED_ID_NEW)
    patch_code_node(save_wf, 'NQxb_Artifact_Save_v1__Build_Response_Context', BUILD_RESPONSE_CONTEXT_NEW)

    with open(SAVE_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(save_wf, f, indent=2)
    print(f"  OUTPUT: {SAVE_OUTPUT}")

    print()
    print("SUMMARY")
    print("=" * 50)
    print("  Save: v48 -> v49")
    print("  Normalize_Saved_ID v1.0 -> v1.1: extracts saved_version")
    print("  Build_Response_Context v1.0 -> v1.1: forwards saved_version")
    print("  Return_Response v3.0: already reads coalesce(j.version, j.saved_version, null)")
    print()
    print("  Version extraction pattern (same as artifact_id):")
    print("    raw.version ?? raw.data?.[0]?.version ?? null")
    print()
    print("  Chain: HTTP_Insert -> Normalize_Saved_ID (extract)")
    print("         -> Build_Response_Context (forward)")
    print("         -> Merge -> Return_Response (output)")


if __name__ == '__main__':
    main()
