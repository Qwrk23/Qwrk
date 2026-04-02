"""
Build Promote v24 from v23 — T149 Atomicity Fix
Adds extension lifecycle_stage update for project artifacts during promote.

New nodes:
  1. IF_Project — Switch: routes project artifacts to extension update
  2. DB_Update_Extension_Lifecycle — Supabase UPDATE on qxb_artifact_project

Connection change:
  OLD: Switch_Post_Update (ok) → Freeze_Event_Payload
  NEW: Switch_Post_Update (ok) → IF_Project
       IF_Project (project) → DB_Update_Extension_Lifecycle → Freeze_Event_Payload
       IF_Project (other)   → Freeze_Event_Payload
"""

import json
import sys
import os

# Paths
v23_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (23).json")
v24_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (24).json")

with open(v23_path, "r", encoding="utf-8") as f:
    wf = json.load(f)

# --- 1. Add new nodes ---

if_project_node = {
    "parameters": {
        "rules": {
            "values": [
                {
                    "conditions": {
                        "options": {
                            "caseSensitive": True,
                            "leftValue": "",
                            "typeValidation": "loose",
                            "version": 3
                        },
                        "conditions": [
                            {
                                "id": "is-project-check",
                                "leftValue": "={{ $json.artifact_type }}",
                                "rightValue": "project",
                                "operator": {
                                    "type": "string",
                                    "operation": "equals"
                                }
                            }
                        ],
                        "combinator": "and"
                    },
                    "renameOutput": True,
                    "outputKey": "project"
                },
                {
                    "conditions": {
                        "options": {
                            "caseSensitive": True,
                            "leftValue": "",
                            "typeValidation": "loose",
                            "version": 3
                        },
                        "conditions": [
                            {
                                "id": "is-not-project-check",
                                "leftValue": "={{ $json.artifact_type }}",
                                "rightValue": "project",
                                "operator": {
                                    "type": "string",
                                    "operation": "notEquals",
                                    "name": "filter.operator.notEquals"
                                }
                            }
                        ],
                        "combinator": "and"
                    },
                    "renameOutput": True,
                    "outputKey": "other"
                }
            ]
        },
        "looseTypeValidation": True,
        "options": {
            "fallbackOutput": "extra"
        }
    },
    "type": "n8n-nodes-base.switch",
    "typeVersion": 3.4,
    "position": [2144, 424],
    "id": "t149-if-project-gate",
    "name": "NQxb_Artifact_Promote_v1__IF_Project"
}

db_update_extension_node = {
    "parameters": {
        "operation": "update",
        "tableId": "qxb_artifact_project",
        "matchType": "allFilters",
        "filters": {
            "conditions": [
                {
                    "keyName": "artifact_id",
                    "condition": "eq",
                    "keyValue": "={{ $json.artifact_id }}"
                }
            ]
        },
        "fieldsUi": {
            "fieldValues": [
                {
                    "fieldId": "lifecycle_stage",
                    "fieldValue": "={{ $json.to_state }}"
                }
            ]
        }
    },
    "type": "n8n-nodes-base.supabase",
    "typeVersion": 1,
    "position": [2144, 280],
    "id": "t149-db-update-extension-lifecycle",
    "name": "NQxb_Artifact_Promote_v1__DB_Update_Extension_Lifecycle",
    "alwaysOutputData": True,
    "credentials": {
        "supabaseApi": {
            "id": "n4R4JdOIV9zrCGIT",
            "name": "Qwrk Supabase \u2013 Kernel v1"
        }
    },
    "onError": "continueErrorOutput"
}

wf["nodes"].append(if_project_node)
wf["nodes"].append(db_update_extension_node)

# --- 2. Modify connections ---

# OLD: Switch_Post_Update output 0 → Freeze_Event_Payload
# NEW: Switch_Post_Update output 0 → IF_Project
spu_conn = wf["connections"]["NQxb_Artifact_Promote_v1__Switch_Post_Update"]["main"]
# Output 0 currently points to Freeze_Event_Payload — redirect to IF_Project
spu_conn[0] = [
    {
        "node": "NQxb_Artifact_Promote_v1__IF_Project",
        "type": "main",
        "index": 0
    }
]
# Outputs 1 and 2 (error paths) remain unchanged

# NEW: IF_Project connections
wf["connections"]["NQxb_Artifact_Promote_v1__IF_Project"] = {
    "main": [
        # Output 0: project → DB_Update_Extension_Lifecycle
        [
            {
                "node": "NQxb_Artifact_Promote_v1__DB_Update_Extension_Lifecycle",
                "type": "main",
                "index": 0
            }
        ],
        # Output 1: other → Freeze_Event_Payload (skip extension update)
        [
            {
                "node": "NQxb_Artifact_Promote_v1__Freeze_Event_Payload",
                "type": "main",
                "index": 0
            }
        ],
        # Output 2: fallback/extra → Freeze_Event_Payload (safety)
        [
            {
                "node": "NQxb_Artifact_Promote_v1__Freeze_Event_Payload",
                "type": "main",
                "index": 0
            }
        ]
    ]
}

# NEW: DB_Update_Extension_Lifecycle connections
wf["connections"]["NQxb_Artifact_Promote_v1__DB_Update_Extension_Lifecycle"] = {
    "main": [
        # Output 0: success → Freeze_Event_Payload
        [
            {
                "node": "NQxb_Artifact_Promote_v1__Freeze_Event_Payload",
                "type": "main",
                "index": 0
            }
        ],
        # Output 1: error → Return_Error_Item (extension update failed)
        [
            {
                "node": "NQxb_Artifact_Promote_v1__Return_Error_Item",
                "type": "main",
                "index": 0
            }
        ]
    ]
}

# --- 3. Write v24 ---

with open(v24_path, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"[OK] Promote v24 written to: {v24_path}")
print(f"  Nodes: {len(wf['nodes'])} (was {len(wf['nodes']) - 2} in v23)")
print(f"  New: IF_Project switch + DB_Update_Extension_Lifecycle")
print(f"  Changed: Switch_Post_Update output 0 -> IF_Project (was Freeze_Event_Payload)")
