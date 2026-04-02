"""
Build Promote v28a from v28 -- T149-A Supabase Response Normalization Layer

Problem: Supabase REST and RPC endpoints return arrays ([]) even for single-row
results. Our Code nodes assume object responses ({}), causing false negatives
in validation (e.g., Check_Concurrency sees [{artifact_id: ...}] instead of
{artifact_id: ...}, so !dbResult.artifact_id is true = false CONCURRENCY_CONFLICT).

Fix: Add inline normalization to all Code nodes that read from Supabase nodes.
Pattern:
    const raw = $node["X"].json;
    const data = Array.isArray(raw) ? raw[0] : raw;

Nodes updated:
  1. Check_Concurrency — normalize DB_Promote_Atomic response
  2. Freeze_Event_Payload — normalize DB_Read_Artifact_Post_Update response
  3. Shape_Response — normalize DB_Read_Artifact_Post_Update + DB_Insert_Event responses

NOT updated (already safe):
  - QPM_Attach_Journal_Count — uses $input.all().filter() (array-native)
  - QPM_Attach_Execution_Count — uses $input.all().filter() (array-native)
  - Parse_Promote_Error — reads from Code nodes (never arrays)

No business logic changes. Only data access normalization.
"""

import json
import os

v28_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (28).json")

with open(v28_path, "r", encoding="utf-8") as f:
    wf = json.load(f)

changes = []

# --- Helper: inline normalization pattern ---
# We use a consistent _norm helper at the top of each modified node.
NORM_HELPER = "const _norm = (v) => Array.isArray(v) ? v[0] : v;"

# --- 1. Check_Concurrency: normalize DB_Promote_Atomic response ---

CHECK_NODE = "NQxb_Artifact_Promote_v1__Check_Concurrency"
DB_PROMOTE_NODE = "NQxb_Artifact_Promote_v1__DB_Promote_Atomic"
COMPUTE_NODE = "NQxb_Artifact_Promote_v1__Compute_Next_Version"

NEW_CHECK_CODE = f"""// NQxb_Artifact_Promote_v1__Check_Concurrency
// v28a: Added Supabase response normalization (T149-A).
// Supabase RPC returns array even for single-row RETURNS TABLE functions.
// v23 origin: Detect zero-row update (optimistic concurrency failure).

{NORM_HELPER}

const dbResult = _norm($node["{DB_PROMOTE_NODE}"].json);
const promoteContext = $node["{COMPUTE_NODE}"].json;

// RPC function returns updated row on success, raises exception on failure.
// With onError:continueErrorOutput, errors go to output 1 (Parse_Promote_Error).
// Output 0 should always have a valid row, but guard defensively.
if (!dbResult || !dbResult.artifact_id) {{
  return [{{
    json: {{
      ok: false,
      _gw_route: "error",
      gw_action: "artifact.promote",
      gw_workspace_id: promoteContext.gw_workspace_id ?? null,
      artifact_type: promoteContext.artifact_type ?? null,
      artifact_id: promoteContext.artifact_id ?? null,
      error: {{
        code: "CONCURRENCY_CONFLICT",
        message: "Artifact version mismatch during promote",
        details: {{
          artifact_id: promoteContext.artifact_id ?? null,
          expected_version: promoteContext.verified_version ?? null
        }}
      }}
    }}
  }}];
}}

// Success — pass through promote context for downstream event/response shaping
return [{{
  json: {{
    ...promoteContext,
    ok: true,
    _db_update_confirmed: true
  }}
}}];
"""

DB_READ_NODE = "NQxb_Artifact_Promote_v1__DB_Read_Artifact_Post_Update"
QPM_VALIDATE_NODE = "NQxb_Artifact_Promote_v1__QPM_Validate_Rules"

# --- 2. Freeze_Event_Payload: normalize DB_Read_Artifact_Post_Update response ---

NEW_FREEZE_CODE = f"""// NQxb_Artifact_Promote_v1__Freeze_Event_Payload
// v28a: Added Supabase response normalization (T149-A).
// v27 origin: Uses DB_Read_Artifact_Post_Update as source of truth for persisted state.
// Transition metadata (from_state, to_state, transition, reason) comes from
// QPM_Validate_Rules (pipeline-computed, not stored in DB).

{NORM_HELPER}

const dbState = _norm($node["{DB_READ_NODE}"].json);
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
"""

# --- 3. Shape_Response: normalize DB_Read_Artifact_Post_Update + DB_Insert_Event ---

DB_INSERT_EVENT_NODE = "NQxb_Artifact_Promote_v1__DB_Insert_Event"

NEW_SHAPE_CODE = f"""// NQxb_Artifact_Promote_v1__Shape_Response
// v28a: Added Supabase response normalization (T149-A).
// v27 origin: References DB_Read_Artifact_Post_Update for persisted state.
// Event data from DB_Insert_Event for audit fields.
//
// Response envelope includes lifecycle_status from DB (post-update truth).

{NORM_HELPER}

const input = $json ?? {{}};

// 1) Pass through error envelopes unchanged
if (input.ok === false || input._gw_route === "error") {{
  return [{{ json: input }}];
}}

// 2) Get post-update DB state (source of truth for persisted fields)
let dbState = null;
try {{
  dbState = _norm($node["{DB_READ_NODE}"].json) ?? null;
}} catch (e) {{
  dbState = null;
}}

// 3) Get event row from DB_Insert_Event (also a Supabase node)
let event = null;
if (input.event_id && input.workspace_id && input.artifact_id) {{
  event = input;
}} else {{
  try {{
    const evNode = $node["{DB_INSERT_EVENT_NODE}"];
    const evJson = _norm(evNode?.json) ?? null;
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
"""

# --- Apply changes ---

for node in wf["nodes"]:
    if node["name"] == CHECK_NODE:
        node["parameters"]["jsCode"] = NEW_CHECK_CODE
        changes.append("Check_Concurrency: normalized DB_Promote_Atomic (RPC array)")
    elif node["name"] == "NQxb_Artifact_Promote_v1__Freeze_Event_Payload":
        node["parameters"]["jsCode"] = NEW_FREEZE_CODE
        changes.append("Freeze_Event_Payload: normalized DB_Read_Artifact_Post_Update (Supabase GET array)")
    elif node["name"] == "NQxb_Artifact_Promote_v1__Shape_Response":
        node["parameters"]["jsCode"] = NEW_SHAPE_CODE
        changes.append("Shape_Response: normalized DB_Read_Artifact_Post_Update + DB_Insert_Event (Supabase arrays)")

# --- Write updated v28 ---

with open(v28_path, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"[OK] Promote v28 updated in-place with T149-A normalization")
print(f"  File: {v28_path}")
print(f"  Changes ({len(changes)}):")
for c in changes:
    print(f"    - {c}")
print()
print(f"  Normalization pattern applied:")
print(f"    const _norm = (v) => Array.isArray(v) ? v[0] : v;")
print(f"    const data = _norm($node['X'].json);")
print()
print(f"  Nodes NOT updated (already safe):")
print(f"    - QPM_Attach_Journal_Count: uses $input.all().filter() (array-native)")
print(f"    - QPM_Attach_Execution_Count: uses $input.all().filter() (array-native)")
print(f"    - Parse_Promote_Error: reads from Code nodes only (never arrays)")
print()
print(f"  No business logic changes. Only data access normalization.")
