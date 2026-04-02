"""
Build Promote v27 from v26 -- T149 Response Accuracy Fix

v26 fixed the extension write (state propagation via explicit node refs).
v27 fixes the RESPONSE: adds a post-update DB read so the response reflects
persisted state, not pipeline intent.

Problem: Freeze_Event_Payload and Shape_Response build from pre-update
pipeline context (QPM_Validate_Rules, Compute_Next_Version). The response
shows lifecycle_status = "seed" even after a successful promote to "sapling".

Fix:
  1. Add DB_Read_Artifact_Post_Update (Supabase GET on qxb_artifact)
  2. Wire: Switch_Post_Update[ok] -> DB_Read -> Freeze_Event_Payload
  3. Freeze_Event_Payload uses DB_Read for persisted state fields
  4. Shape_Response references DB_Read for lifecycle_status in envelope
  5. DB_Insert_Event continues to use $json from Freeze_Event_Payload (correct by inheritance)

Pipeline change:
  v26: Switch_Post_Update -> Freeze_Event_Payload -> DB_Insert_Event -> Shape_Response
  v27: Switch_Post_Update -> DB_Read_Artifact_Post_Update -> Freeze_Event_Payload -> DB_Insert_Event -> Shape_Response
"""

import json
import os

v26_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (26).json")
v27_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (27).json")

COMPUTE_NODE = "NQxb_Artifact_Promote_v1__Compute_Next_Version"
DB_READ_NODE = "NQxb_Artifact_Promote_v1__DB_Read_Artifact_Post_Update"
QPM_VALIDATE_NODE = "NQxb_Artifact_Promote_v1__QPM_Validate_Rules"
DB_INSERT_EVENT_NODE = "NQxb_Artifact_Promote_v1__DB_Insert_Event"
FREEZE_NODE = "NQxb_Artifact_Promote_v1__Freeze_Event_Payload"
RETURN_ERROR_NODE = "NQxb_Artifact_Promote_v1__Return_Error_Item"

with open(v26_path, "r", encoding="utf-8") as f:
    wf = json.load(f)

# --- 1. Add DB_Read_Artifact_Post_Update node ---

db_read_node = {
    "parameters": {
        "tableId": "qxb_artifact",
        "filters": {
            "conditions": [
                {
                    "keyName": "artifact_id",
                    "condition": "eq",
                    "keyValue": f'={{{{ $node["{COMPUTE_NODE}"].json.artifact_id }}}}'
                }
            ]
        }
    },
    "type": "n8n-nodes-base.supabase",
    "typeVersion": 1,
    "position": [2144, 424],
    "id": "t149-db-read-post-update",
    "name": DB_READ_NODE,
    "credentials": {
        "supabaseApi": {
            "id": "n4R4JdOIV9zrCGIT",
            "name": "Qwrk Supabase \u2013 Kernel v1"
        }
    },
    "alwaysOutputData": True,
    "onError": "continueErrorOutput"
}

wf["nodes"].append(db_read_node)
print(f"[OK] Added node: {DB_READ_NODE}")

# --- 2. Shift downstream nodes right to make room ---

# Move Freeze, DB_Insert_Event, Shape_Response 224px right each
SHIFT_X = 224
shift_targets = {
    FREEZE_NODE: None,
    DB_INSERT_EVENT_NODE: None,
    "NQxb_Artifact_Promote_v1__Shape_Response": None,
}

for node in wf["nodes"]:
    if node["name"] in shift_targets:
        old_pos = list(node["position"])
        node["position"] = [old_pos[0] + SHIFT_X, old_pos[1]]
        print(f"[OK] Shifted {node['name']} from [{old_pos[0]}, {old_pos[1]}] to {node['position']}")

# --- 3. Rewire: Switch_Post_Update[ok] -> DB_Read (was -> Freeze) ---

conn = wf["connections"]

spu_conn = conn["NQxb_Artifact_Promote_v1__Switch_Post_Update"]["main"]
spu_conn[0] = [
    {
        "node": DB_READ_NODE,
        "type": "main",
        "index": 0
    }
]
print(f"[OK] Switch_Post_Update[0] -> DB_Read (was -> Freeze)")

# --- 4. Add DB_Read connections: success -> Freeze, error -> Return_Error ---

conn[DB_READ_NODE] = {
    "main": [
        # Output 0: success -> Freeze_Event_Payload
        [
            {
                "node": FREEZE_NODE,
                "type": "main",
                "index": 0
            }
        ],
        # Output 1: error -> Return_Error_Item
        [
            {
                "node": RETURN_ERROR_NODE,
                "type": "main",
                "index": 0
            }
        ]
    ]
}
print(f"[OK] DB_Read[0] -> Freeze, DB_Read[1] -> Return_Error")

# --- 5. Rewrite Freeze_Event_Payload to use DB_Read as source of truth ---

NEW_FREEZE_CODE = f'''// NQxb_Artifact_Promote_v1__Freeze_Event_Payload
// v27: Uses DB_Read_Artifact_Post_Update as source of truth for persisted state.
// Transition metadata (from_state, to_state, transition, reason) comes from
// QPM_Validate_Rules (pipeline-computed, not stored in DB).

const dbState = $node["{DB_READ_NODE}"].json;
const qpmContext = $node["{QPM_VALIDATE_NODE}"].json ?? {{}};

// Validate that the DB read returned a valid row
if (!dbState || !dbState.artifact_id) {{
  return [{{
    json: {{
      ok: false,
      _gw_route: "error",
      error: {{
        code: "POST_UPDATE_READ_FAILED",
        message: "Post-update DB read returned no data. Promote may have succeeded but response cannot be verified.",
        details: {{ artifact_id: qpmContext.artifact_id ?? null }}
      }}
    }}
  }}];
}}

return [{{
  json: {{
    // Persisted DB state (source of truth)
    artifact_id: dbState.artifact_id,
    workspace_id: dbState.workspace_id,
    gw_workspace_id: dbState.workspace_id,
    artifact_type: dbState.artifact_type,
    lifecycle_status: dbState.lifecycle_status,
    version: dbState.version,

    // Transition metadata (pipeline-computed)
    gw_action: qpmContext.gw_action ?? "artifact.promote",
    request_id: qpmContext.request_id ?? null,
    transition: qpmContext.transition ?? null,
    from_state: qpmContext.from_state ?? null,
    to_state: qpmContext.to_state ?? null,
    reason: qpmContext.reason ?? null,
    actor_user_id: qpmContext.actor_user_id ?? null,

    ok: true,
    _gw_route: "ok",
    _db_update_confirmed: true,

    // Event payload for DB_Insert_Event
    _event_payload: {{
      request_id: qpmContext.request_id ?? null,
      transition: qpmContext.transition ?? null,
      from_state: qpmContext.from_state ?? null,
      to_state: dbState.lifecycle_status,
      reason: qpmContext.reason ?? null,
      artifact_type: dbState.artifact_type,
      gw_action: qpmContext.gw_action ?? "artifact.promote",
      lifecycle_status: dbState.lifecycle_status,
      version: dbState.version
    }}
  }}
}}];
'''

for node in wf["nodes"]:
    if node["name"] == FREEZE_NODE:
        node["parameters"]["jsCode"] = NEW_FREEZE_CODE
        print(f"[OK] Freeze_Event_Payload: rewritten to use DB_Read as source of truth")
        break

# --- 6. Rewrite Shape_Response to include lifecycle_status from DB_Read ---

NEW_SHAPE_CODE = f'''// NQxb_Artifact_Promote_v1__Shape_Response
// v27: References DB_Read_Artifact_Post_Update for persisted state.
// Event data from DB_Insert_Event for audit fields.
//
// Response envelope includes lifecycle_status from DB (post-update truth).

const input = $json ?? {{}};

// 1) Pass through error envelopes unchanged
if (input.ok === false || input._gw_route === "error") {{
  return [{{ json: input }}];
}}

// 2) Get post-update DB state (source of truth for persisted fields)
let dbState = null;
try {{
  dbState = $node["{DB_READ_NODE}"].json ?? null;
}} catch (e) {{
  dbState = null;
}}

// 3) Get event row from DB_Insert_Event
let event = null;
if (input.event_id && input.workspace_id && input.artifact_id) {{
  event = input;
}} else {{
  try {{
    const evNode = $node["{DB_INSERT_EVENT_NODE}"];
    const evJson = evNode?.json ?? null;
    if (evJson && evJson.event_id) event = evJson;
  }} catch (e) {{
    event = null;
  }}
}}

if (!event) {{
  return [{{
    json: {{
      ok: false,
      _gw_route: "error",
      error: {{
        code: "INTERNAL_ERROR",
        message: "Promote succeeded but event payload was unavailable for response shaping.",
        details: {{ reason: "missing_event_row" }}
      }}
    }}
  }}];
}}

// 4) Extract transition context from event payload
const payload = event.payload ?? {{}};
const from_state = payload.from_state ?? null;
const to_state = payload.to_state ?? null;
const transition = payload.transition ?? null;

// 5) Canonical timestamp
const timestamp = event.event_ts ?? event.created_at ?? new Date().toISOString();

// 6) Use DB state for identity and lifecycle (source of truth)
const workspace_id = dbState?.workspace_id ?? event.workspace_id ?? null;
const artifact_id = dbState?.artifact_id ?? event.artifact_id ?? null;
const artifact_type = dbState?.artifact_type ?? payload.artifact_type ?? "project";
const lifecycle_status = dbState?.lifecycle_status ?? to_state;
const version = dbState?.version ?? null;

// 7) Return canonical envelope with DB-confirmed state
return [{{
  json: {{
    ok: true,
    gw_action: "artifact.promote",
    workspace_id,
    artifact_type,
    artifact_id,
    lifecycle_status,
    version,

    event_id: event.event_id ?? null,
    operation: "PROMOTE",
    from_state,
    to_state,
    transition,
    timestamp,

    data: {{ event }}
  }}
}}];
'''

for node in wf["nodes"]:
    if node["name"] == "NQxb_Artifact_Promote_v1__Shape_Response":
        node["parameters"]["jsCode"] = NEW_SHAPE_CODE
        print(f"[OK] Shape_Response: rewritten to include lifecycle_status from DB_Read")
        break

# --- 7. Write v27 ---

with open(v27_path, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"\n[OK] Promote v27 written to: {v27_path}")
print(f"  Nodes: {len(wf['nodes'])}")
print(f"  New node: DB_Read_Artifact_Post_Update (Supabase GET on qxb_artifact)")
print(f"  Pipeline: Switch_Post_Update -> DB_Read -> Freeze -> DB_Insert_Event -> Shape_Response")
print(f"  Key fix: Response reflects persisted DB state, not pipeline intent")
