"""
build_save_v47_comms_fix.py

Bug: Person communication_style Corruption (Save Pipeline)
Authorization: 7c81ad8d-a1fe-4736-8588-dfe5af666773
Root Cause: Malformed n8n expression on field index 21 in DB_Insert_Person_Extension
Fix: Remove orphaned ternary text after premature }} close

Input:  workflows/NQxb_Artifact_Save_v1 (46).json
Output: workflows/NQxb_Artifact_Save_v1 (47).json

Changes: ONLY field index 21 (communication_style) expression.
No other fields, nodes, or connections are modified.
"""

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
INPUT_FILE = REPO_ROOT / "workflows" / "NQxb_Artifact_Save_v1 (46).json"
OUTPUT_FILE = REPO_ROOT / "workflows" / "NQxb_Artifact_Save_v1 (47).json"

NODE_NAME = "NQxb_Artifact_Save_v1__DB_Insert_Person_Extension"
FIELD_INDEX = 21
FIELD_ID = "communication_style"

BROKEN_EXPRESSION = (
    '={{ $node["NQxb_Artifact_Save_v1__Normalize_Request"]'
    '.json.extension.communication_style ?? null }}'
    '  ? $node["NQxb_Artifact_Save_v1__Normalize_Request"]'
    '.json.extension.communication_style \n  : null }}'
)

FIXED_EXPRESSION = (
    '={{ $node["NQxb_Artifact_Save_v1__Normalize_Request"]'
    '.json.extension.communication_style ?? null }}'
)


def main():
    # Load
    if not INPUT_FILE.exists():
        print(f"ERROR: Input file not found: {INPUT_FILE}")
        sys.exit(1)

    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        workflow = json.load(f)

    # Find node
    target_node = None
    for node in workflow["nodes"]:
        if node["name"] == NODE_NAME:
            target_node = node
            break

    if target_node is None:
        print(f"ERROR: Node '{NODE_NAME}' not found in workflow")
        sys.exit(1)

    # Verify field
    fields = target_node["parameters"]["fieldsUi"]["fieldValues"]

    if FIELD_INDEX >= len(fields):
        print(f"ERROR: Field index {FIELD_INDEX} out of range (total: {len(fields)})")
        sys.exit(1)

    field = fields[FIELD_INDEX]

    if field["fieldId"] != FIELD_ID:
        print(f"ERROR: Field at index {FIELD_INDEX} is '{field['fieldId']}', expected '{FIELD_ID}'")
        sys.exit(1)

    current_value = field["fieldValue"]

    if current_value != BROKEN_EXPRESSION:
        print(f"ERROR: Field value does not match expected broken expression.")
        print(f"  Expected: {repr(BROKEN_EXPRESSION)}")
        print(f"  Actual:   {repr(current_value)}")
        sys.exit(1)

    # Apply fix
    field["fieldValue"] = FIXED_EXPRESSION

    # Verify fix applied
    assert fields[FIELD_INDEX]["fieldValue"] == FIXED_EXPRESSION, "Fix verification failed"

    # Verify no other fields changed
    for i, f in enumerate(fields):
        if i != FIELD_INDEX:
            # Spot-check: no field should contain the orphaned ternary pattern
            if "? $node[" in f["fieldValue"] and ": null }}" in f["fieldValue"]:
                print(f"WARNING: Field {i} ({f['fieldId']}) may have similar issue")

    # Write output
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(workflow, f, indent=2, ensure_ascii=False)

    print(f"SUCCESS: Save v47 written to {OUTPUT_FILE}")
    print(f"  Node: {NODE_NAME}")
    print(f"  Field: {FIELD_INDEX} ({FIELD_ID})")
    print(f"  Before: {repr(BROKEN_EXPRESSION[:80])}...")
    print(f"  After:  {repr(FIXED_EXPRESSION)}")
    print()
    print("Next steps:")
    print("  1. Import Save v47 to n8n (same workflow ID: N8G9pstDFnGpQITW)")
    print("  2. Activate workflow")
    print("  3. Run validation test cases TC1-TC6")


if __name__ == "__main__":
    main()
