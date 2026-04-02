"""
Build Promote v26 from v25 -- T149 State Propagation Fix

Root cause: v25's IF_Project and DB_Update_Extension_Lifecycle both use $json,
which contains the Supabase UPDATE response from DB_Update_Lifecycle.
The n8n Supabase node may NOT return all columns after UPDATE — only the
updated fields or an empty acknowledgement. This means:
  - $json.artifact_type may be undefined → IF_Project always routes to "other"
  - $json.artifact_id may be undefined → extension filter matches nothing
  - $json.lifecycle_status may be stale or undefined

Fix: Replace all $json references in IF_Project and DB_Update_Extension_Lifecycle
with explicit $node["Compute_Next_Version"] references. Compute_Next_Version
has all the known-good values (artifact_id, artifact_type, to_state) from
BEFORE the DB write.

Changes:
  1. IF_Project condition: $json.artifact_type → $node["...Compute_Next_Version"].json.artifact_type
  2. DB_Update_Extension_Lifecycle filter: $json.artifact_id → $node["...Compute_Next_Version"].json.artifact_id
  3. DB_Update_Extension_Lifecycle field: $json.lifecycle_status → $node["...Compute_Next_Version"].json.to_state
"""

import json
import os

COMPUTE_NODE = "NQxb_Artifact_Promote_v1__Compute_Next_Version"
COMPUTE_REF = f'$node["{COMPUTE_NODE}"]'

v25_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (25).json")
v26_path = os.path.join(os.path.dirname(__file__), "..", "workflows", "NQxb_Artifact_Promote_v1 (26).json")

with open(v25_path, "r", encoding="utf-8") as f:
    wf = json.load(f)

changes = []

# --- 1. Fix IF_Project: use Compute_Next_Version for artifact_type check ---

for node in wf["nodes"]:
    if node["name"] == "NQxb_Artifact_Promote_v1__IF_Project":
        for rule in node["parameters"]["rules"]["values"]:
            for cond in rule["conditions"]["conditions"]:
                old_val = cond["leftValue"]
                if "$json.artifact_type" in old_val:
                    cond["leftValue"] = f'={{{{ {COMPUTE_REF}.json.artifact_type }}}}'
                    changes.append(f"IF_Project condition: {old_val} → {cond['leftValue']}")
        break

# --- 2. Fix DB_Update_Extension_Lifecycle: use Compute_Next_Version for filter + field ---

for node in wf["nodes"]:
    if node["name"] == "NQxb_Artifact_Promote_v1__DB_Update_Extension_Lifecycle":
        # 2a. Fix filter: artifact_id
        for cond in node["parameters"]["filters"]["conditions"]:
            if cond["keyName"] == "artifact_id":
                old_val = cond["keyValue"]
                cond["keyValue"] = f'={{{{ {COMPUTE_REF}.json.artifact_id }}}}'
                changes.append(f"DB_Update_Extension filter artifact_id: {old_val} → {cond['keyValue']}")

        # 2b. Fix field: lifecycle_stage
        for fv in node["parameters"]["fieldsUi"]["fieldValues"]:
            if fv["fieldId"] == "lifecycle_stage":
                old_val = fv["fieldValue"]
                fv["fieldValue"] = f'={{{{ {COMPUTE_REF}.json.to_state }}}}'
                changes.append(f"DB_Update_Extension field lifecycle_stage: {old_val} → {fv['fieldValue']}")
        break

# --- 3. Write v26 ---

with open(v26_path, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"[OK] Promote v26 written to: {v26_path}")
print(f"  Nodes: {len(wf['nodes'])}")
print(f"  Changes ({len(changes)}):")
for c in changes:
    print(f"    - {c}")
print()
print(f"  Pipeline (unchanged from v25):")
print(f"    DB_Update_Lifecycle → IF_Project → DB_Update_Extension → Check_Concurrency → Switch_Post_Update → Freeze")
print()
print(f"  Key fix: IF_Project + DB_Update_Extension now reference Compute_Next_Version")
print(f"  instead of $json (which was the unreliable Supabase UPDATE response)")
