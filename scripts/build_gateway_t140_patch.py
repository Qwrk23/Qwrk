"""
Build script: Patch Gateway v1 and v2 Gatekeeper nodes for T140
Adds content/content_append to the update validation gate.

Creates:
  - NQxb_Gateway_v1 (68).json (from v67)
  - NQxb_Gateway_v2 (2).json (from v2 (1))
  - Archives old versions

Usage: python scripts/build_gateway_t140_patch.py
"""

import json
import copy
import os

REPO = r"c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"

GATEWAYS = [
    {
        "src": os.path.join(REPO, "workflows", "NQxb_Gateway_v1 (67).json"),
        "dst": os.path.join(REPO, "workflows", "NQxb_Gateway_v1 (68).json"),
        "archive": os.path.join(REPO, "workflows", "Archive", "NQxb_Gateway_v1 (67)__v67__2026-03-25.json"),
        "gatekeeper_name": "NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly",
    },
    {
        "src": os.path.join(REPO, "workflows", "NQxb_Gateway_v2 (1).json"),
        "dst": os.path.join(REPO, "workflows", "NQxb_Gateway_v2 (2).json"),
        "archive": os.path.join(REPO, "workflows", "Archive", "NQxb_Gateway_v2 (1)__v1__2026-03-25.json"),
        "gatekeeper_name": "NQxb_Gateway_v2__Gatekeeper",
    },
]

for gw in GATEWAYS:
    print(f"\n=== Processing {os.path.basename(gw['src'])} ===")

    with open(gw["src"], "r", encoding="utf-8") as f:
        wf = json.load(f)
    wf = copy.deepcopy(wf)

    # Find gatekeeper node
    gk = None
    for node in wf["nodes"]:
        if node["name"] == gw["gatekeeper_name"]:
            gk = node
            break

    if not gk:
        print(f"  ERROR: Gatekeeper node '{gw['gatekeeper_name']}' not found!")
        continue

    code = gk["parameters"]["jsCode"]

    # Patch 1: Add content detection after hasSpineFields
    old_validation = """  if (!hasExtension && !hasTags && !hasSpineFields) {
    return fail(
      "VALIDATION_ERROR",
      "artifact.update requires extension, tags, or spine fields",
      {
        expected:
          "extension OR tags.add/remove OR title/summary/priority/lifecycle_status",
      }
    );
  }"""

    new_validation = """  // T140: Content field detection for update validation
  const hasContent = $json?.content !== null && $json?.content !== undefined
    && typeof $json?.content === 'object' && !Array.isArray($json?.content)
    && Object.keys($json.content).length > 0;
  const hasContentAppend = $json?.content_append !== null && $json?.content_append !== undefined
    && typeof $json?.content_append === 'object' && !Array.isArray($json?.content_append);

  if (!hasExtension && !hasTags && !hasSpineFields && !hasContent && !hasContentAppend) {
    return fail(
      "VALIDATION_ERROR",
      "artifact.update requires extension, tags, spine fields, content, or content_append",
      {
        expected:
          "extension OR tags.add/remove OR title/summary/priority/lifecycle_status OR content OR content_append",
      }
    );
  }"""

    if old_validation in code:
        code = code.replace(old_validation, new_validation)
        print(f"  OK: Validation gate patched")
    else:
        print(f"  ERROR: Could not find validation gate pattern!")
        # Try with different whitespace
        print(f"  Attempting fuzzy match...")
        if "!hasExtension && !hasTags && !hasSpineFields" in code:
            # Replace just the condition line
            code = code.replace(
                "if (!hasExtension && !hasTags && !hasSpineFields) {",
                "// T140: Content field detection\n"
                "  const hasContent = $json?.content !== null && $json?.content !== undefined\n"
                "    && typeof $json?.content === 'object' && !Array.isArray($json?.content)\n"
                "    && Object.keys($json.content).length > 0;\n"
                "  const hasContentAppend = $json?.content_append !== null && $json?.content_append !== undefined\n"
                "    && typeof $json?.content_append === 'object' && !Array.isArray($json?.content_append);\n\n"
                "  if (!hasExtension && !hasTags && !hasSpineFields && !hasContent && !hasContentAppend) {"
            )
            # Also update error message
            code = code.replace(
                '"artifact.update requires extension, tags, or spine fields"',
                '"artifact.update requires extension, tags, spine fields, content, or content_append"'
            )
            code = code.replace(
                '"extension OR tags.add/remove OR title/summary/priority/lifecycle_status"',
                '"extension OR tags.add/remove OR title/summary/priority/lifecycle_status OR content OR content_append"'
            )
            print(f"  OK: Fuzzy patch applied")
        else:
            print(f"  FATAL: Cannot find validation pattern at all")
            continue

    gk["parameters"]["jsCode"] = code

    # Verify
    if "hasContent" in code and "hasContentAppend" in code and "T140" in code:
        print(f"  OK: T140 markers verified")
    else:
        print(f"  ERROR: T140 markers missing after patch!")

    # Archive
    os.makedirs(os.path.dirname(gw["archive"]), exist_ok=True)
    with open(gw["src"], "r", encoding="utf-8") as f:
        original = f.read()
    with open(gw["archive"], "w", encoding="utf-8") as f:
        f.write(original)
    print(f"  Archived: {os.path.basename(gw['archive'])}")

    # Write new version
    with open(gw["dst"], "w", encoding="utf-8") as f:
        json.dump(wf, f, indent=2, ensure_ascii=False)
    print(f"  Created: {os.path.basename(gw['dst'])}")
