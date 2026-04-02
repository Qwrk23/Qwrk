"""
Build script: T140 Branch 4 — Governance & Safety Layer
Enforcement-only pass. No new pipeline nodes, no routing changes.

Changes:
  L1: Check_Mutability_Rules — archive freeze for content (all types)
      Validate_Content_Append — archive freeze for content_append
  L2: Normalize_Request — _content_raw_invalid flag
      Validate_Request — CONTENT_INVALID_SHAPE rejection
  L3: Validate_Content_Append — 100-entry append limit
  L4: Error audit — all paths verified (no code changes, manual audit)

Usage: python scripts/build_update_v13_t140_b4.py
"""

import json
import copy
import os

DOWNLOAD = r"C:\Users\j_bla\Downloads\NQxb_Artifact_Update_v1__T140.json"
REPO_OUT = r"c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\NQxb_Artifact_Update_v1__T140 (10).json"

with open(DOWNLOAD, "r", encoding="utf-8") as f:
    wf = json.load(f)

wf = copy.deepcopy(wf)


def find_node(name):
    for node in wf["nodes"]:
        if node["name"] == name:
            return node
    raise ValueError(f"Node not found: {name}")


# =============================================================================
# L4.1a: Check_Mutability_Rules — archive freeze for content (all types)
# =============================================================================
mut_node = find_node("NQxb_Artifact_Update_v1__Check_Mutability_Rules")
mut_code = mut_node["parameters"]["jsCode"]

# Insert archive freeze for content AFTER immutable type check, BEFORE project archive guard
# The content_append path already exits before this point, so this only catches content merge/replace
CONTENT_ARCHIVE_GUARD = r"""// ============================================================================
// T140 B4 L1: Archive freeze for content updates (ALL types, not just project)
// Any artifact with lifecycle_status = 'archive' is fully frozen.
// ============================================================================
if (hasContent && lifecycle_status === 'archive') {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'ARCHIVE_FROZEN',
        message: "Archived artifacts are fully immutable. Content updates are not permitted.",
        details: {
          artifact_id: existing.artifact_id,
          artifact_type: artifact_type,
          lifecycle_status: 'archive',
          operation: 'content_update',
          hint: 'Archived artifacts are read-only historical records. No content mutations are allowed.',
        },
      },
    },
  }];
}

"""

# Insert before the existing project archive guard
mut_code = mut_code.replace(
    "// ============================================================================\n// 1.5 LIFECYCLE GUARD: archive",
    CONTENT_ARCHIVE_GUARD + "// ============================================================================\n// 1.5 LIFECYCLE GUARD: archive"
)

# Update header
mut_code = mut_code.replace(
    "// v10: T140 -- content mode detection",
    "// v10: T140 -- content mode detection\n// v11: T140 B4 -- archive freeze for content updates (all types)"
)

mut_node["parameters"]["jsCode"] = mut_code


# =============================================================================
# L4.1b: Validate_Content_Append — archive freeze + L4.3 append limit
# =============================================================================
val_append_node = find_node("NQxb_Artifact_Update_v1__Validate_Content_Append")
val_append_code = val_append_node["parameters"]["jsCode"]

# Insert archive check and append limit AFTER type gate, BEFORE payload structure check
APPEND_GOVERNANCE = r"""
// T140 B4 L1: Archive freeze for content_append
if (existing.lifecycle_status === 'archive') {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'ARCHIVE_FROZEN',
        message: "Archived artifacts are fully immutable. Content append operations are not permitted.",
        details: {
          artifact_id: item.artifact_id,
          artifact_type: artifact_type,
          lifecycle_status: 'archive',
          operation: 'content_append',
          hint: 'Archived artifacts are read-only historical records. No append operations are allowed.',
        },
      },
    },
  }];
}

// T140 B4 L3: Append limit enforcement (100 entries max)
const MAX_APPEND_ENTRIES = 100;
let _existingContent = existing.content || {};
if (typeof _existingContent === 'string') {
  try { _existingContent = JSON.parse(_existingContent); } catch (e) { _existingContent = {}; }
}
const currentAppendCount = Array.isArray(_existingContent.append_log) ? _existingContent.append_log.length : 0;
const incomingCount = contentAppend && Array.isArray(contentAppend.entries) ? contentAppend.entries.length : 0;
if (currentAppendCount + incomingCount > MAX_APPEND_ENTRIES) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'APPEND_LIMIT_EXCEEDED',
        message: 'Append operation would exceed maximum append_log entry count (' + MAX_APPEND_ENTRIES + ').',
        details: {
          artifact_id: item.artifact_id,
          artifact_type: artifact_type,
          current_entries: currentAppendCount,
          incoming_entries: incomingCount,
          max_entries: MAX_APPEND_ENTRIES,
          hint: 'Reduce the number of entries or create a new artifact.',
        },
      },
    },
  }];
}

"""

# Insert after type gate, before payload structure check
val_append_code = val_append_code.replace(
    "// 2. Payload structure: must have entries array",
    APPEND_GOVERNANCE + "// 2. Payload structure: must have entries array"
)

# Update header
val_append_code = val_append_code.replace(
    "// T140 B3 L1: content_append entry point + validation",
    "// T140 B3 L1: content_append entry point + validation\n// T140 B4 L1: archive freeze\n// T140 B4 L3: append limit (100 entries)"
)

val_append_node["parameters"]["jsCode"] = val_append_code


# =============================================================================
# L4.2a: Normalize_Request — _content_raw_invalid flag
# =============================================================================
norm_node = find_node("NQxb_Artifact_Update_v1__Normalize_Request")
norm_code = norm_node["parameters"]["jsCode"]

# Add shape validation flag after content extraction
norm_code = norm_code.replace(
    "const content_mode = (typeof req.content_mode === 'string' && req.content_mode.trim().length > 0)\n  ? req.content_mode.trim() : null;",
    "const content_mode = (typeof req.content_mode === 'string' && req.content_mode.trim().length > 0)\n  ? req.content_mode.trim() : null;\n\n"
    "// T140 B4 L2: Content shape validation flag\n"
    "// Detect if content was provided but is not a valid object (array or primitive)\n"
    "const _content_raw_invalid = rawContent !== null && rawContent !== undefined\n"
    "  && (typeof rawContent !== 'object' || Array.isArray(rawContent));"
)

# Add flag to canonical output (in debug section)
norm_code = norm_code.replace(
    "  has_content_mode: content_mode !== null,",
    "  has_content_mode: content_mode !== null,\n"
    "  content_raw_invalid: _content_raw_invalid,"
)

# Add flag to canonical output top level
norm_code = norm_code.replace(
    "  content_mode: content_mode,",
    "  content_mode: content_mode,\n"
    "  _content_raw_invalid: _content_raw_invalid,"
)

norm_node["parameters"]["jsCode"] = norm_code


# =============================================================================
# L4.2b: Validate_Request — CONTENT_INVALID_SHAPE rejection
# =============================================================================
val_node = find_node("NQxb_Artifact_Update_v1__Validate_Request")
val_code = val_node["parameters"]["jsCode"]

# Add shape check before the content mode conflict checks
SHAPE_CHECK = r"""// T140 B4 L2: Content shape validation — reject arrays and primitives
if (req._content_raw_invalid) {
  errors.push({ field: "content", reason: "must be a JSON object (not array or primitive)", expected: "object", code: "CONTENT_INVALID_SHAPE" });
}

"""

val_code = val_code.replace(
    "// T140: Content mode conflict validation (L5)",
    SHAPE_CHECK + "// T140: Content mode conflict validation (L5)"
)

# Update header
val_code = val_code.replace(
    "// v4.0: T140",
    "// v4.0: T140\n// v5.0: T140 B4 — CONTENT_INVALID_SHAPE rejection"
)

val_node["parameters"]["jsCode"] = val_code


# =============================================================================
# Write outputs
# =============================================================================
with open(DOWNLOAD, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

with open(REPO_OUT, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"Nodes: {len(wf['nodes'])}")

# Verify all patches
checks = []

# Check_Mutability_Rules
c = find_node("NQxb_Artifact_Update_v1__Check_Mutability_Rules")["parameters"]["jsCode"]
checks.append(("L1a: archive freeze for content (all types)", "hasContent && lifecycle_status === 'archive'" in c))
checks.append(("L1a: B4 marker in Check_Mutability", "T140 B4" in c))

# Validate_Content_Append
c = find_node("NQxb_Artifact_Update_v1__Validate_Content_Append")["parameters"]["jsCode"]
checks.append(("L1b: archive freeze for content_append", "ARCHIVE_FROZEN" in c))
checks.append(("L3: append limit check", "APPEND_LIMIT_EXCEEDED" in c))
checks.append(("L3: MAX_APPEND_ENTRIES = 100", "MAX_APPEND_ENTRIES = 100" in c))

# Normalize_Request
c = find_node("NQxb_Artifact_Update_v1__Normalize_Request")["parameters"]["jsCode"]
checks.append(("L2a: _content_raw_invalid flag", "_content_raw_invalid" in c))
checks.append(("L2a: Array.isArray check", "Array.isArray(rawContent)" in c))

# Validate_Request
c = find_node("NQxb_Artifact_Update_v1__Validate_Request")["parameters"]["jsCode"]
checks.append(("L2b: CONTENT_INVALID_SHAPE", "CONTENT_INVALID_SHAPE" in c))
checks.append(("L2b: _content_raw_invalid check", "_content_raw_invalid" in c))

for label, ok in checks:
    print(f"  {'OK' if ok else 'FAIL'}: {label}")

# Error code inventory
print("\n  Error codes in workflow:")
all_codes = set()
for node in wf["nodes"]:
    code = node.get("parameters", {}).get("jsCode", "")
    import re
    for match in re.finditer(r"code:\s*['\"]([A-Z_]+)['\"]", code):
        all_codes.add(match.group(1))
for ec in sorted(all_codes):
    print(f"    {ec}")
