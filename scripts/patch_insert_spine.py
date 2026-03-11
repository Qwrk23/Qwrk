"""
patch_insert_spine.py — Replace Supabase DB_Insert_Spine with HTTP Request + PostgREST

Problem: n8n Supabase node (typeVersion 1) converts null to empty string for UUID fields.
         PostgreSQL rejects "" for uuid columns, crashing the sub-workflow.

Fix:     Replace with Prepare_Insert_Payload (Code) + HTTP_Insert_Spine (HTTP Request).
         Code node builds JSON body, omitting semantic_type_id when null.
         HTTP Request POSTs to PostgREST with proper null handling.

Run:     python scripts/patch_insert_spine.py
"""

import json
import sys
import os

SAVE_PATH = os.path.join("workflows", "NQxb_Artifact_Save_v1 (40).json")

# ─── Load ───────────────────────────────────────────────────────────────────

with open(SAVE_PATH, "r", encoding="utf-8") as f:
    wf = json.load(f)

nodes = wf["nodes"]
conns = wf["connections"]

# ─── Find old node ──────────────────────────────────────────────────────────

old_idx = None
old_node = None
for i, n in enumerate(nodes):
    if n["name"] == "NQxb_Artifact_Save_v1__DB_Insert_Spine":
        old_idx = i
        old_node = n
        break

if old_idx is None:
    print("ERROR: DB_Insert_Spine node not found. Already patched?")
    sys.exit(1)

print(f"Found DB_Insert_Spine at index {old_idx}")

# ─── Copy credentials from old node ────────────────────────────────────────

creds = old_node.get("credentials", {})

# ─── Build Prepare_Insert_Payload (Code node) ──────────────────────────────

prepare_js = r"""// NQxb_Artifact_Save_v1__Prepare_Insert_Payload
// Build clean JSON body for PostgREST INSERT into qxb_artifact.
// Properly handles null semantic_type_id by omitting it from payload.
// PostgREST uses column default (null) when field is absent.
//
// Why: n8n Supabase node (typeVersion 1) converts null to empty string ""
// for expression-mapped fields. PostgreSQL rejects "" for uuid columns.
// HTTP Request + PostgREST gives full control over null handling.

const req = $json;

const payload = {
  workspace_id: req.gw_workspace_id,
  owner_user_id: req.owner_user_id,
  artifact_type: req.artifact_type,
  title: req.title,
  summary: req.summary,
  priority: req.priority,
  tags: req.tags,
  content: req.content,
  parent_artifact_id: req.parent_artifact_id,
  lifecycle_status: req.lifecycle_status,
  execution_status: req.execution_status
};

// Only include semantic_type_id when resolved to a valid UUID.
// Non-top-level types (branch, leaf, limb, etc.) have null — omitting
// lets PostgREST use the column default (null).
if (req.semantic_type_id != null && req.semantic_type_id !== '') {
  payload.semantic_type_id = req.semantic_type_id;
}

return [{ json: payload }];"""

prepare_node = {
    "parameters": {
        "jsCode": prepare_js
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-752, 400],
    "id": "a1b2c3d4-prep-insert-payload",
    "name": "NQxb_Artifact_Save_v1__Prepare_Insert_Payload"
}

# ─── Build HTTP_Insert_Spine (HTTP Request node) ───────────────────────────

http_node = {
    "parameters": {
        "method": "POST",
        "url": "https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact",
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
        "jsonBody": "={{ JSON.stringify($json) }}",
        "options": {}
    },
    "type": "n8n-nodes-base.httpRequest",
    "typeVersion": 4.2,
    "position": [-592, 400],
    "id": "e5f6a7b8-http-insert-spine",
    "name": "NQxb_Artifact_Save_v1__HTTP_Insert_Spine",
    "alwaysOutputData": False,
    "credentials": creds,
    "onError": "continueErrorOutput"
}

# ─── Replace node in nodes array ───────────────────────────────────────────

nodes[old_idx:old_idx + 1] = [prepare_node, http_node]
print(f"Replaced DB_Insert_Spine with Prepare_Insert_Payload + HTTP_Insert_Spine")

# ─── Update connections ─────────────────────────────────────────────────────

# 1. Switch_Assert_Result output[1] target: DB_Insert_Spine -> Prepare_Insert_Payload
assert_key = "NQxb_Artifact_Save_v1__Switch_Assert_Result"
if assert_key in conns:
    for output_group in conns[assert_key]["main"]:
        for conn in output_group:
            if conn["node"] == "NQxb_Artifact_Save_v1__DB_Insert_Spine":
                conn["node"] = "NQxb_Artifact_Save_v1__Prepare_Insert_Payload"
                print(f"  Rewired Switch_Assert_Result -> Prepare_Insert_Payload")

# 2. Remove old DB_Insert_Spine connections, save them for HTTP node
old_conns = conns.pop("NQxb_Artifact_Save_v1__DB_Insert_Spine", None)
if old_conns:
    print(f"  Removed DB_Insert_Spine connections (had {len(old_conns['main'])} outputs)")

# 3. Add Prepare_Insert_Payload -> HTTP_Insert_Spine
conns["NQxb_Artifact_Save_v1__Prepare_Insert_Payload"] = {
    "main": [
        [
            {
                "node": "NQxb_Artifact_Save_v1__HTTP_Insert_Spine",
                "type": "main",
                "index": 0
            }
        ]
    ]
}
print(f"  Added Prepare_Insert_Payload -> HTTP_Insert_Spine")

# 4. Add HTTP_Insert_Spine connections (same as old DB_Insert_Spine)
#    output[0] -> Normalize_Saved_ID (success)
#    output[1] -> Return_Response (error)
if old_conns:
    conns["NQxb_Artifact_Save_v1__HTTP_Insert_Spine"] = old_conns
    print(f"  Added HTTP_Insert_Spine -> {[c['node'].split('__')[-1] for g in old_conns['main'] for c in g]}")

# ─── Update Assert_Semantic_UUID comment ────────────────────────────────────

for n in nodes:
    if n["name"] == "NQxb_Artifact_Save_v1__Assert_Semantic_UUID":
        js = n["parameters"]["jsCode"]
        old_comment = "forward to DB_Insert_Spine"
        new_comment = "forward to Prepare_Insert_Payload"
        if old_comment in js:
            n["parameters"]["jsCode"] = js.replace(old_comment, new_comment)
            print(f"  Updated Assert comment: '{old_comment}' -> '{new_comment}'")
        break

# ─── Save ───────────────────────────────────────────────────────────────────

with open(SAVE_PATH, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"\nSaved. Node count: {len(nodes)} (was 47, now 48: +1 net from split)")
print(f"File: {SAVE_PATH}")
print(f"\nNext: Import to n8n and re-test A3")
