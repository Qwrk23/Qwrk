"""
Build Promote v25 from v24 -- T149 Atomicity Fix (Corrected Ordering)

v24 placed the extension update AFTER Switch_Post_Update.
v25 moves it EARLIER: immediately after DB_Update_Lifecycle, BEFORE Check_Concurrency.

Pipeline change:
  v24: DB_Update_Lifecycle -> Check_Concurrency -> Switch_Post_Update -> IF_Project -> DB_Update_Extension -> Freeze
  v25: DB_Update_Lifecycle -> IF_Project -> DB_Update_Extension -> Check_Concurrency -> Switch_Post_Update -> Freeze

Changes:
  1. DB_Update_Lifecycle[0] now -> IF_Project (was -> Check_Concurrency)
  2. IF_Project[0] (project) -> DB_Update_Extension_Lifecycle (unchanged)
  3. IF_Project[1,2] (other/extra) -> Check_Concurrency (was -> Freeze_Event_Payload)
  4. DB_Update_Extension_Lifecycle[0] -> Check_Concurrency (was -> Freeze_Event_Payload)
  5. Switch_Post_Update[0] (ok) -> Freeze_Event_Payload (restored v23 path)
  6. DB_Update_Extension_Lifecycle field: $json.lifecycle_status (was $json.to_state)
  7. Check_Concurrency code: read $node["DB_Update_Lifecycle"] instead of $json
"""

import json
import os

v24_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (24).json")
v25_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (25).json")

with open(v24_path, "r", encoding="utf-8") as f:
    wf = json.load(f)

# --- 1. Update DB_Update_Extension_Lifecycle: $json.to_state -> $json.lifecycle_status ---

for node in wf["nodes"]:
    if node["name"] == "NQxb_Artifact_Promote_v1__DB_Update_Extension_Lifecycle":
        for fv in node["parameters"]["fieldsUi"]["fieldValues"]:
            if fv["fieldId"] == "lifecycle_stage":
                old_val = fv["fieldValue"]
                fv["fieldValue"] = "={{ $json.lifecycle_status }}"
                print(f"[OK] DB_Update_Extension_Lifecycle: fieldValue changed")
                print(f"     was: {old_val}")
                print(f"     now: {fv['fieldValue']}")
        break

# --- 2. Update Check_Concurrency: $json -> $node["DB_Update_Lifecycle"].json ---

for node in wf["nodes"]:
    if node["name"] == "NQxb_Artifact_Promote_v1__Check_Concurrency":
        old_code = node["parameters"]["jsCode"]
        # Replace the $json reference for dbResult with $node reference
        new_code = old_code.replace(
            "const dbResult = $json;",
            'const dbResult = $node["NQxb_Artifact_Promote_v1__DB_Update_Lifecycle"].json;'
        )
        if new_code != old_code:
            node["parameters"]["jsCode"] = new_code
            print("[OK] Check_Concurrency: dbResult now reads from $node['DB_Update_Lifecycle']")
        else:
            print("[WARN] Check_Concurrency: could not find 'const dbResult = $json;' to replace")
        break

# --- 3. Rewire connections ---

conn = wf["connections"]

# 3a. DB_Update_Lifecycle output 0: Check_Concurrency -> IF_Project
db_update_conn = conn["NQxb_Artifact_Promote_v1__DB_Update_Lifecycle"]["main"]
db_update_conn[0] = [
    {
        "node": "NQxb_Artifact_Promote_v1__IF_Project",
        "type": "main",
        "index": 0
    }
]
# Output 1 (error) stays at Return_Error_Item
print("[OK] DB_Update_Lifecycle[0] -> IF_Project (was -> Check_Concurrency)")

# 3b. IF_Project outputs: project -> DB_Update_Extension, other/extra -> Check_Concurrency
conn["NQxb_Artifact_Promote_v1__IF_Project"] = {
    "main": [
        # Output 0: project -> DB_Update_Extension_Lifecycle
        [
            {
                "node": "NQxb_Artifact_Promote_v1__DB_Update_Extension_Lifecycle",
                "type": "main",
                "index": 0
            }
        ],
        # Output 1: other -> Check_Concurrency (was Freeze_Event_Payload)
        [
            {
                "node": "NQxb_Artifact_Promote_v1__Check_Concurrency",
                "type": "main",
                "index": 0
            }
        ],
        # Output 2: extra/fallback -> Check_Concurrency (was Freeze_Event_Payload)
        [
            {
                "node": "NQxb_Artifact_Promote_v1__Check_Concurrency",
                "type": "main",
                "index": 0
            }
        ]
    ]
}
print("[OK] IF_Project: project -> DB_Update_Extension, other/extra -> Check_Concurrency")

# 3c. DB_Update_Extension_Lifecycle: success -> Check_Concurrency, error -> Return_Error_Item
conn["NQxb_Artifact_Promote_v1__DB_Update_Extension_Lifecycle"] = {
    "main": [
        # Output 0: success -> Check_Concurrency (was Freeze_Event_Payload)
        [
            {
                "node": "NQxb_Artifact_Promote_v1__Check_Concurrency",
                "type": "main",
                "index": 0
            }
        ],
        # Output 1: error -> Return_Error_Item
        [
            {
                "node": "NQxb_Artifact_Promote_v1__Return_Error_Item",
                "type": "main",
                "index": 0
            }
        ]
    ]
}
print("[OK] DB_Update_Extension_Lifecycle[0] -> Check_Concurrency (was -> Freeze_Event_Payload)")

# 3d. Switch_Post_Update output 0: IF_Project -> Freeze_Event_Payload (restore v23 path)
spu_conn = conn["NQxb_Artifact_Promote_v1__Switch_Post_Update"]["main"]
spu_conn[0] = [
    {
        "node": "NQxb_Artifact_Promote_v1__Freeze_Event_Payload",
        "type": "main",
        "index": 0
    }
]
print("[OK] Switch_Post_Update[0] -> Freeze_Event_Payload (restored v23 path, was -> IF_Project)")

# --- 4. Update node positions for visual clarity ---

for node in wf["nodes"]:
    if node["name"] == "NQxb_Artifact_Promote_v1__IF_Project":
        # Place between DB_Update_Lifecycle (1584,88) and Check_Concurrency (1808,16)
        node["position"] = [1696, 88]
        print(f"[OK] IF_Project position -> [1696, 88]")
    elif node["name"] == "NQxb_Artifact_Promote_v1__DB_Update_Extension_Lifecycle":
        # Place above IF_Project, between it and Check_Concurrency
        node["position"] = [1696, -60]
        print(f"[OK] DB_Update_Extension_Lifecycle position -> [1696, -60]")

# --- 5. Write v25 ---

with open(v25_path, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"\n[OK] Promote v25 written to: {v25_path}")
print(f"  Nodes: {len(wf['nodes'])}")
print(f"  Key change: Extension update now fires BEFORE Check_Concurrency")
print(f"  Pipeline: DB_Update_Lifecycle -> IF_Project -> DB_Update_Extension -> Check_Concurrency -> Switch_Post_Update -> Freeze")
