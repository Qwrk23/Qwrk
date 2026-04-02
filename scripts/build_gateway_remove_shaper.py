"""
Gateway v2: Remove Shape_Save_Response (Sapling A fix)
=======================================================
Removes the response reshaping node that was overriding Save v48's
Return_Response v3.0 output.

Changes:
  1. Remove NQxb_Gateway__Shape_Save_Response node from nodes array
  2. Rewire: Tag_Save_Result -> Respond_Save_Success (direct passthrough)
  3. Remove Shape_Save_Response connections entry
  4. Freeze_Save_Context left in place (orphaned but harmless)

Input:  workflows/NQxb_Gateway_v2 (3).json
Output: workflows/NQxb_Gateway_v2 (4).json
Archive: workflows/Archive/NQxb_Gateway_v2__v3__2026-03-31.json
"""

import json
import shutil
import os

WORKFLOWS_DIR = os.path.join(os.path.dirname(__file__), '..', 'workflows')
ARCHIVE_DIR = os.path.join(WORKFLOWS_DIR, 'Archive')

GW_INPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Gateway_v2 (3).json')
GW_OUTPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Gateway_v2 (4).json')
GW_ARCHIVE = os.path.join(ARCHIVE_DIR, 'NQxb_Gateway_v2__v3__2026-03-31.json')

SHAPE_NODE_NAME = 'NQxb_Gateway__Shape_Save_Response'
TAG_NODE_NAME = 'NQxb_Gateway__Tag_Save_Result'
RESPOND_NODE_NAME = 'NQxb_Gateway__Respond_Save_Success'


def main():
    os.makedirs(ARCHIVE_DIR, exist_ok=True)

    with open(GW_INPUT, 'r', encoding='utf-8') as f:
        gw = json.load(f)

    # ---- Step 1: Remove Shape_Save_Response from nodes array ----
    original_count = len(gw['nodes'])
    gw['nodes'] = [n for n in gw['nodes'] if n.get('name') != SHAPE_NODE_NAME]
    removed_count = original_count - len(gw['nodes'])
    print(f"  REMOVED node: {SHAPE_NODE_NAME} ({removed_count} node(s))")

    # ---- Step 2: Rewire Tag_Save_Result -> Respond_Save_Success ----
    connections = gw['connections']

    # Current: Tag_Save_Result -> Shape_Save_Response
    # New:     Tag_Save_Result -> Respond_Save_Success
    if TAG_NODE_NAME in connections:
        old_target = connections[TAG_NODE_NAME]
        connections[TAG_NODE_NAME] = {
            "main": [
                [
                    {
                        "node": RESPOND_NODE_NAME,
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        }
        print(f"  REWIRED: {TAG_NODE_NAME} -> {RESPOND_NODE_NAME} (was -> {SHAPE_NODE_NAME})")
    else:
        print(f"  WARNING: {TAG_NODE_NAME} not found in connections")

    # ---- Step 3: Remove Shape_Save_Response connections entry ----
    if SHAPE_NODE_NAME in connections:
        del connections[SHAPE_NODE_NAME]
        print(f"  REMOVED connections entry: {SHAPE_NODE_NAME}")
    else:
        print(f"  NOTE: {SHAPE_NODE_NAME} had no connections entry")

    # ---- Step 4: Verify Tag_Save_Result is non-destructive ----
    tag_node = None
    for n in gw['nodes']:
        if n.get('name') == TAG_NODE_NAME:
            tag_node = n
            break

    if tag_node:
        code = tag_node.get('parameters', {}).get('jsCode', '')
        if '...$json' in code and '_merge_role' in code:
            print(f"  VERIFIED: {TAG_NODE_NAME} is non-destructive (spread + tag only)")
        else:
            print(f"  WARNING: {TAG_NODE_NAME} code may modify response - REVIEW MANUALLY")
            print(f"    Code: {code[:200]}...")
    else:
        print(f"  WARNING: {TAG_NODE_NAME} node not found")

    # ---- Step 5: Verify no other nodes reference Shape_Save_Response ----
    gw_json_str = json.dumps(gw)
    if SHAPE_NODE_NAME in gw_json_str:
        print(f"  WARNING: {SHAPE_NODE_NAME} still referenced somewhere in the workflow!")
        # Find where
        for node_name, conn in connections.items():
            conn_str = json.dumps(conn)
            if SHAPE_NODE_NAME in conn_str:
                print(f"    Referenced in connections of: {node_name}")
        for node in gw['nodes']:
            node_str = json.dumps(node)
            if SHAPE_NODE_NAME in node_str:
                print(f"    Referenced in node: {node.get('name')}")
    else:
        print(f"  VERIFIED: No remaining references to {SHAPE_NODE_NAME}")

    # ---- Archive and write ----
    shutil.copy2(GW_INPUT, GW_ARCHIVE)
    print(f"  ARCHIVED: {GW_ARCHIVE}")

    with open(GW_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(gw, f, indent=2)
    print(f"  OUTPUT: {GW_OUTPUT}")

    # ---- Summary ----
    print()
    print("SUMMARY")
    print("=" * 50)
    print(f"  Gateway: v3 -> v4")
    print(f"  Removed: {SHAPE_NODE_NAME} (response rebuilder)")
    print(f"  Rewired: {TAG_NODE_NAME} -> {RESPOND_NODE_NAME} (direct passthrough)")
    print(f"  Save response path now: Sub-workflow -> Tag -> Respond (no reshaping)")
    print(f"  Update response path:   Sub-workflow -> Respond (no reshaping)")
    print(f"  Both paths are now identical: passthrough to webhook")
    print()
    print("  STOP: Review output before deployment.")


if __name__ == '__main__':
    main()
