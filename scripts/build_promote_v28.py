"""
Build Promote v28 from v27 -- T149 Atomic RPC Promote

v27 added DB_Read_Artifact_Post_Update for response accuracy but spine UPDATE
was still blocked by enforce_lifecycle_alignment trigger (circular dependency
between spine and extension triggers).

v28 replaces the 3-node sequential update pattern with a single HTTP Request
node calling the proven promote_artifact_lifecycle() Postgres function via
Supabase REST RPC endpoint.

The function (SECURITY DEFINER) disables both triggers, atomically updates
extension + spine, re-enables triggers, all in one transaction.

Changes:
  1. REMOVE 3 nodes: DB_Update_Lifecycle, IF_Project, DB_Update_Extension_Lifecycle
  2. ADD 1 node: DB_Promote_Atomic (HTTP Request -> /rpc/promote_artifact_lifecycle)
  3. ADD 1 node: Parse_Promote_Error (Code node to format RPC errors)
  4. WIRE: Compute -> DB_Promote_Atomic[ok] -> Check_Concurrency -> ...
  5. WIRE: DB_Promote_Atomic[error] -> Parse_Promote_Error -> Return_Error_Item
  6. UPDATE Check_Concurrency: $node["DB_Update_Lifecycle"] -> $node["DB_Promote_Atomic"]
  7. KEEP all v27 downstream: DB_Read, Freeze, Insert_Event, Shape_Response

Pipeline change:
  v27: Compute -> DB_Update_Lifecycle -> IF_Project -> DB_Update_Extension -> Check_Concurrency -> Switch -> DB_Read -> Freeze -> ...
  v28: Compute -> DB_Promote_Atomic -> Check_Concurrency -> Switch -> DB_Read -> Freeze -> ...
"""

import json
import os

v27_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (27).json")
v28_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (28).json")

COMPUTE_NODE = "NQxb_Artifact_Promote_v1__Compute_Next_Version"
CHECK_NODE = "NQxb_Artifact_Promote_v1__Check_Concurrency"
RETURN_ERROR_NODE = "NQxb_Artifact_Promote_v1__Return_Error_Item"
DB_PROMOTE_NODE = "NQxb_Artifact_Promote_v1__DB_Promote_Atomic"
PARSE_ERROR_NODE = "NQxb_Artifact_Promote_v1__Parse_Promote_Error"

with open(v27_path, "r", encoding="utf-8") as f:
    wf = json.load(f)

# --- 1. Remove old nodes: DB_Update_Lifecycle, IF_Project, DB_Update_Extension_Lifecycle ---

remove_names = {
    "NQxb_Artifact_Promote_v1__DB_Update_Lifecycle",
    "NQxb_Artifact_Promote_v1__IF_Project",
    "NQxb_Artifact_Promote_v1__DB_Update_Extension_Lifecycle",
}

original_count = len(wf["nodes"])
wf["nodes"] = [n for n in wf["nodes"] if n["name"] not in remove_names]
removed_count = original_count - len(wf["nodes"])
print(f"[OK] Removed {removed_count} nodes: {', '.join(sorted(remove_names))}")

# Remove their connections
conn = wf["connections"]
for name in remove_names:
    if name in conn:
        del conn[name]
        print(f"[OK] Removed connections for: {name}")

# --- 2. Add DB_Promote_Atomic node (HTTP Request calling Supabase RPC) ---
# Uses same auth pattern as existing QPM_Query_Journal_Children (line 576-611 of v27):
#   authentication: "predefinedCredentialType"
#   nodeCredentialType: "supabaseApi"
#   credential: n4R4JdOIV9zrCGIT

db_promote_node = {
    "parameters": {
        "method": "POST",
        "url": "https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/rpc/promote_artifact_lifecycle",
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
        "jsonBody": '={{ JSON.stringify({ p_artifact_id: $json.artifact_id, p_workspace_id: $json.gw_workspace_id, p_to_state: $json.to_state, p_expected_version: $json.verified_version }) }}',
        "options": {
            "response": {
                "response": {
                    "responseFormat": "json"
                }
            }
        }
    },
    "type": "n8n-nodes-base.httpRequest",
    "typeVersion": 4.2,
    "position": [1584, 88],
    "id": "t149-db-promote-atomic",
    "name": DB_PROMOTE_NODE,
    "credentials": {
        "supabaseApi": {
            "id": "n4R4JdOIV9zrCGIT",
            "name": "Qwrk Supabase \u2013 Kernel v1"
        }
    },
    "alwaysOutputData": True,
    "onError": "continueErrorOutput"
}

wf["nodes"].append(db_promote_node)
print(f"[OK] Added node: {DB_PROMOTE_NODE} (HTTP Request -> /rpc/promote_artifact_lifecycle)")

# --- 3. Add Parse_Promote_Error node (Code node for RPC error formatting) ---
# Supabase RPC errors come back as: {"code":"P0001","details":null,"hint":null,"message":"CONCURRENCY_CONFLICT: ..."}
# This node parses the error into our standard Gateway error envelope.

PARSE_ERROR_CODE = f'''// {PARSE_ERROR_NODE}
// v28: Parses Supabase RPC error responses into Gateway error envelope.
// Supabase returns: {{"code":"P0001","message":"CONCURRENCY_CONFLICT: ..."}}
// We extract the error type from the message prefix.

const input = $json ?? {{}};
const promoteContext = $node["{COMPUTE_NODE}"].json ?? {{}};

// The error message from Supabase RPC contains our custom prefix
const msg = input.message ?? input.error ?? String(input);

let errorCode = "PROMOTE_ATOMIC_FAILED";
let errorMessage = msg;

if (typeof msg === "string") {{
  if (msg.includes("CONCURRENCY_CONFLICT")) {{
    errorCode = "CONCURRENCY_CONFLICT";
    errorMessage = "Artifact version mismatch during promote";
  }} else if (msg.includes("ARTIFACT_NOT_FOUND")) {{
    errorCode = "ARTIFACT_NOT_FOUND";
    errorMessage = "Artifact not found for the given workspace";
  }} else if (msg.includes("EXTENSION_NOT_FOUND")) {{
    errorCode = "EXTENSION_NOT_FOUND";
    errorMessage = "Project extension row not found";
  }}
}}

return [{{
  json: {{
    ok: false,
    _gw_route: "error",
    gw_action: "artifact.promote",
    gw_workspace_id: promoteContext.gw_workspace_id ?? null,
    artifact_type: promoteContext.artifact_type ?? null,
    artifact_id: promoteContext.artifact_id ?? null,
    error: {{
      code: errorCode,
      message: errorMessage,
      details: {{
        artifact_id: promoteContext.artifact_id ?? null,
        expected_version: promoteContext.verified_version ?? null,
        raw_error: msg
      }}
    }}
  }}
}}];
'''

parse_error_node = {
    "parameters": {
        "jsCode": PARSE_ERROR_CODE
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [1584, -120],
    "id": "t149-parse-promote-error",
    "name": PARSE_ERROR_NODE
}

wf["nodes"].append(parse_error_node)
print(f"[OK] Added node: {PARSE_ERROR_NODE} (Code node for RPC error parsing)")

# --- 4. Wire: Compute -> DB_Promote_Atomic ---

conn[COMPUTE_NODE]["main"][0] = [
    {
        "node": DB_PROMOTE_NODE,
        "type": "main",
        "index": 0
    }
]
print(f"[OK] {COMPUTE_NODE}[0] -> {DB_PROMOTE_NODE}")

# --- 5. Wire: DB_Promote_Atomic outputs ---
# Output 0 (success): -> Check_Concurrency
# Output 1 (error/continueErrorOutput): -> Parse_Promote_Error

conn[DB_PROMOTE_NODE] = {
    "main": [
        # Output 0: success -> Check_Concurrency
        [
            {
                "node": CHECK_NODE,
                "type": "main",
                "index": 0
            }
        ],
        # Output 1: error -> Parse_Promote_Error
        [
            {
                "node": PARSE_ERROR_NODE,
                "type": "main",
                "index": 0
            }
        ]
    ]
}
print(f"[OK] {DB_PROMOTE_NODE}[0] -> Check_Concurrency, [1] -> Parse_Promote_Error")

# --- 6. Wire: Parse_Promote_Error -> Return_Error_Item ---

conn[PARSE_ERROR_NODE] = {
    "main": [
        [
            {
                "node": RETURN_ERROR_NODE,
                "type": "main",
                "index": 0
            }
        ]
    ]
}
print(f"[OK] {PARSE_ERROR_NODE}[0] -> Return_Error_Item")

# --- 7. Update Check_Concurrency: change DB_Update_Lifecycle ref to DB_Promote_Atomic ---

OLD_CHECK_REF = 'NQxb_Artifact_Promote_v1__DB_Update_Lifecycle'
NEW_CHECK_REF = DB_PROMOTE_NODE

for node in wf["nodes"]:
    if node["name"] == CHECK_NODE:
        old_code = node["parameters"]["jsCode"]
        new_code = old_code.replace(OLD_CHECK_REF, NEW_CHECK_REF)
        if old_code != new_code:
            node["parameters"]["jsCode"] = new_code
            print(f"[OK] Check_Concurrency: updated node reference DB_Update_Lifecycle -> DB_Promote_Atomic")
        else:
            print(f"[WARN] Check_Concurrency: no reference to DB_Update_Lifecycle found (may already be updated)")
        break

# --- 8. Write v28 ---

with open(v28_path, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"\n[OK] Promote v28 written to: {v28_path}")
print(f"  Nodes: {len(wf['nodes'])}")
print(f"  Removed: DB_Update_Lifecycle, IF_Project, DB_Update_Extension_Lifecycle")
print(f"  Added: DB_Promote_Atomic (HTTP Request), Parse_Promote_Error (Code)")
print(f"  Net change: -3 +2 = -1 node ({original_count} -> {len(wf['nodes'])})")
print(f"")
print(f"  Pipeline:")
print(f"    Compute -> DB_Promote_Atomic -> Check_Concurrency -> Switch_Post_Update -> DB_Read -> Freeze -> DB_Insert_Event -> Shape_Response")
print(f"  Error path:")
print(f"    DB_Promote_Atomic[error] -> Parse_Promote_Error -> Return_Error_Item")
print(f"")
print(f"  Key fix: Single HTTP Request calls promote_artifact_lifecycle() via Supabase RPC")
print(f"  Function handles: trigger disable, extension+spine update, trigger re-enable, version check")
print(f"  Auth: predefinedCredentialType + supabaseApi (same as QPM query nodes)")
