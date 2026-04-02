"""
Build script: NQxb_Artifact_Update_v1__T140 (10).json
Branch 1: Gateway Contract Expansion

Creates v10 from v9 with T140 Branch 1 changes:
  L2: Normalize_Request — accept content, content_append, content_mode
  L5: Validate_Request — mode conflict validation
  L1: Check_Mutability_Rules — content mode detection before mutability
  L4: content_mode handling (merge vs replace) in Compute_Mixed
  L3: Compute_Mixed — content integration in spine_fields builder
  NEW: Return_Content_Append_Stub node + Switch route

Usage: python scripts/build_update_v10_t140.py
"""

import json
import copy
import os

REPO = r"c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"
SRC = os.path.join(REPO, "workflows", "NQxb_Artifact_Update_v1__T69 (9).json")
DST = os.path.join(REPO, "workflows", "NQxb_Artifact_Update_v1__T140 (10).json")
ARCHIVE = os.path.join(REPO, "workflows", "Archive", "NQxb_Artifact_Update_v1__T69 (9)__v9__2026-03-25.json")

with open(SRC, "r", encoding="utf-8") as f:
    wf = json.load(f)

# Deep copy so source is untouched
wf = copy.deepcopy(wf)

# Update workflow name
wf["name"] = "NQxb_Artifact_Update_v1__T140"

# Helper: find node by name
def find_node(name):
    for node in wf["nodes"]:
        if node["name"] == name:
            return node
    raise ValueError(f"Node not found: {name}")


# =============================================================================
# L2: Normalize_Request — Add content, content_append, content_mode
# =============================================================================
norm_node = find_node("NQxb_Artifact_Update_v1__Normalize_Request")
old_norm = norm_node["parameters"]["jsCode"]

# Insert content extraction after spine_fields block, before "recompute after all spine fields"
CONTENT_EXTRACTION = r"""
// T140: Content field extraction
// content = JSON object for mutable-type merge/replace updates
// content_append = JSON object for immutable-type append-only updates
// content_mode = 'merge' (default) or 'replace' — controls content update semantics
const rawContent = req.content ?? null;
const content = (rawContent && typeof rawContent === 'object' && !Array.isArray(rawContent))
  ? rawContent : null;

const rawContentAppend = req.content_append ?? null;
const content_append = (rawContentAppend && typeof rawContentAppend === 'object' && !Array.isArray(rawContentAppend))
  ? rawContentAppend : null;

const content_mode = (typeof req.content_mode === 'string' && req.content_mode.trim().length > 0)
  ? req.content_mode.trim() : null;

"""

# Find the insertion point: after lifecycle_status block, before "recompute"
norm_code = old_norm.replace(
    "// recompute after all spine fields added\nconst hasSpineFields",
    CONTENT_EXTRACTION + "// recompute after all spine fields added\nconst hasSpineFields"
)

# Add content fields to canonical output — insert after spine_fields line
norm_code = norm_code.replace(
    '  // Spine fields\n  spine_fields: hasSpineFields ? spine_fields : null,',
    '  // Spine fields\n  spine_fields: hasSpineFields ? spine_fields : null,\n\n'
    '  // T140: Content fields\n'
    '  content: content,\n'
    '  content_append: content_append,\n'
    '  content_mode: content_mode,'
)

# Add to debug output
norm_code = norm_code.replace(
    '  spine_field_keys: hasSpineFields ? Object.keys(spine_fields) : [],',
    '  spine_field_keys: hasSpineFields ? Object.keys(spine_fields) : [],\n'
    '  has_content: content !== null,\n'
    '  has_content_append: content_append !== null,\n'
    '  has_content_mode: content_mode !== null,'
)

# Update header comment
norm_code = norm_code.replace(
    "// T94: Twig lifecycle_status support",
    "// T94: Twig lifecycle_status support\n// T140: Content field extraction (content, content_append, content_mode)"
)

norm_node["parameters"]["jsCode"] = norm_code


# =============================================================================
# L5: Validate_Request — Mode conflict validation
# =============================================================================
val_node = find_node("NQxb_Artifact_Update_v1__Validate_Request")
old_val = val_node["parameters"]["jsCode"]

# Insert conflict checks before the "at least one" check
CONFLICT_CHECKS = r"""// T140: Content mode conflict validation (L5)
const hasContent = req.content !== null && req.content !== undefined;
const hasContentAppend = req.content_append !== null && req.content_append !== undefined;

if (hasContent && hasContentAppend) {
  errors.push({ field: "content_mode_conflict", reason: "Cannot provide both content and content_append in the same request", expected: "one of: content OR content_append" });
}

if (hasContentAppend && hasTags) {
  errors.push({ field: "content_mode_conflict", reason: "Cannot combine content_append with tags update", expected: "content_append must be submitted alone" });
}

if (hasContentAppend && (hasExtension || hasSpineFields)) {
  errors.push({ field: "content_mode_conflict", reason: "Cannot combine content_append with extension or spine field updates", expected: "content_append must be submitted alone" });
}

"""

val_code = old_val.replace(
    "if (!hasExtension && !hasTags && !hasSpineFields) {\n  errors.push({ field: \"extension_or_tags_or_spine\", reason: \"required\", expected: \"at least one of: extension object, tags object, spine_fields object\" });\n}",
    CONFLICT_CHECKS
    + "if (!hasExtension && !hasTags && !hasSpineFields && !hasContent && !hasContentAppend) {\n"
    + '  errors.push({ field: "update_fields", reason: "required", expected: "at least one of: extension, tags, spine_fields, content, or content_append" });\n'
    + "}"
)

# Update header
val_code = val_code.replace(
    "// v3.0: Extension optional when tags present (T41)",
    "// v3.0: Extension optional when tags present (T41)\n// v4.0: T140 — Content mode conflict validation"
)

val_node["parameters"]["jsCode"] = val_code


# =============================================================================
# L1: Check_Mutability_Rules — Content mode detection BEFORE mutability
# =============================================================================
mut_node = find_node("NQxb_Artifact_Update_v1__Check_Mutability_Rules")
old_mut = mut_node["parameters"]["jsCode"]

# Add content dimensions after hasExtension
CONTENT_DIMS = r"""
// T140: Content dimension detection (L1 — before mutability checks)
const hasContent = normalizeNode.content !== null && normalizeNode.content !== undefined;
const hasContentAppend = normalizeNode.content_append !== null && normalizeNode.content_append !== undefined;

"""

mut_code = old_mut.replace(
    "const hasExtension = extensionKeys.length > 0;",
    "const hasExtension = extensionKeys.length > 0;\n" + CONTENT_DIMS
)

# Insert content mode routing BEFORE archive guard (after dimensions, before section 1.5)
# Per Joel: mode detection happens before mutability checks
CONTENT_MODE_ROUTING = r"""// ============================================================================
// T140 L1: CONTENT MODE DETECTION (before mutability checks)
// content_append → stub (B3 will implement lifecycle enforcement)
// content_update → route through Compute_Mixed path
// ============================================================================

// T140: content_append mode — route to stub (B3/B4 will implement)
if (hasContentAppend && !hasTags && !hasSpineFields && !hasExtension && !hasContent) {
  return [{
    json: {
      ok: true,
      _gw_route: 'ok',
      _update_mode: 'content_append',
      gw_action: normalizeNode.gw_action ?? 'artifact.update',
      gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
      artifact_id: existing.artifact_id,
      workspace_id: existing.workspace_id,
      artifact_type: artifact_type,
      _normalized_request: normalizeNode,
      _existing_artifact: existing,
      _gw_debug: {
        ...(normalizeNode._gw_debug ?? {}),
        mutability: 'content_append_detected',
        operation: 'UPDATE',
      },
    },
  }];
}

// T140: content_update mode — block immutable types (must use content_append)
if (hasContent) {
  const immutableContentTypes = ['snapshot', 'restart', 'journal', 'instruction_pack'];
  if (immutableContentTypes.includes(artifact_type)) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'CONTENT_UPDATE_NOT_ALLOWED',
          message: "Content updates via merge/replace are not allowed for immutable type '" + artifact_type + "'. Use content_append instead.",
          details: {
            artifact_id: existing.artifact_id,
            artifact_type: artifact_type,
            hint: 'Immutable artifact types (snapshot, restart, journal, instruction_pack) only support content_append operations.',
          },
        },
      },
    }];
  }
}

"""

mut_code = mut_code.replace(
    "// ============================================================================\n// 1.5 LIFECYCLE GUARD:",
    CONTENT_MODE_ROUTING + "// ============================================================================\n// 1.5 LIFECYCLE GUARD:"
)

# Update the routing classification for spine_only/mixed paths to include content
# When content is present alongside spine/tags, route through spine_only or mixed
# 2b. Spine only — now also triggers if hasContent (content_update goes through Compute_Mixed)
mut_code = mut_code.replace(
    "// 2b. Spine only\nif (hasSpineFields && !hasTags && !hasExtension) {",
    "// 2b. Spine only (T140: content_update also routes here)\nif ((hasSpineFields || hasContent) && !hasTags && !hasExtension && !hasContentAppend) {"
)

# 2c. Mixed — also triggers with content
mut_code = mut_code.replace(
    "// 2c. Mixed -- tags + spine fields, no extension (single atomic PATCH)\nif (hasTags && hasSpineFields && !hasExtension) {",
    "// 2c. Mixed -- tags + spine fields, no extension (single atomic PATCH)\n// T140: content can combine with tags and/or spine fields\nif (hasTags && (hasSpineFields || hasContent) && !hasExtension && !hasContentAppend) {"
)

# Update header
mut_code = mut_code.replace(
    "// v9: T94 -- twig added",
    "// v9: T94 -- twig added\n// v10: T140 -- content mode detection (content_update, content_append) before mutability"
)

mut_node["parameters"]["jsCode"] = mut_code


# =============================================================================
# L3 + L4: Compute_Mixed — Content integration + content_mode handling
# =============================================================================
mixed_node = find_node("NQxb_Artifact_Update_v1__Compute_Mixed_Spine_Update")
old_mixed = mixed_node["parameters"]["jsCode"]

# Insert content handling after priority, before tag merge
CONTENT_HANDLING = r"""
// T140 L3+L4: Content field integration
// content_mode: 'merge' (default) — deep merge keys into existing content
// content_mode: 'replace' — full replacement of content field
const contentUpdate = normalizeNode.content || null;
const contentMode = normalizeNode.content_mode || 'merge';

if (contentUpdate) {
  if (contentMode === 'replace') {
    // Full replacement: new content replaces existing entirely
    patch.content = JSON.stringify(contentUpdate);
  } else {
    // Default: deep merge — new keys merge into existing, existing keys updated
    const existingContent = existingArtifact.content || {};
    const merged = { ...existingContent, ...contentUpdate };
    patch.content = JSON.stringify(merged);
  }
}

"""

mixed_code = old_mixed.replace(
    "if ('parent_artifact_id' in spineFields) patch.parent_artifact_id = spineFields.parent_artifact_id;\n\n// Tag merge (if mixed mode)",
    "if ('parent_artifact_id' in spineFields) patch.parent_artifact_id = spineFields.parent_artifact_id;\n"
    + CONTENT_HANDLING
    + "// Tag merge (if mixed mode)"
)

# Update header
mixed_code = mixed_code.replace(
    "// T87: Build unified spine PATCH for spine_only and mixed modes\n// Handles: title, summary, priority, tags, version increment",
    "// T87: Build unified spine PATCH for spine_only and mixed modes\n// T140: content field integration (L3) + content_mode handling (L4)\n// Handles: title, summary, priority, content, tags, version increment"
)

mixed_node["parameters"]["jsCode"] = mixed_code


# =============================================================================
# NEW NODE: Return_Content_Append_Stub
# =============================================================================
stub_node = {
    "parameters": {
        "jsCode": (
            "// NQxb_Artifact_Update_v1__Return_Content_Append_Stub\n"
            "// T140 Branch 1: Placeholder for content_append mode.\n"
            "// Branch 3 will implement the actual append system.\n\n"
            "return [{\n"
            "  json: {\n"
            "    ok: false,\n"
            "    _gw_route: 'error',\n"
            "    error: {\n"
            "      code: 'NOT_IMPLEMENTED',\n"
            "      message: 'content_append mode is not yet implemented. Branch 3 (T140) will deliver this capability.',\n"
            "      details: {\n"
            "        artifact_id: $json.artifact_id ?? null,\n"
            "        artifact_type: $json.artifact_type ?? null,\n"
            "        update_mode: 'content_append',\n"
            "        hint: 'Use content field with content_mode for mutable types. content_append for immutable types is coming in T140 Branch 3.',\n"
            "      },\n"
            "    },\n"
            "  },\n"
            "}];\n"
        )
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-1120, 320],
    "id": "t140-stub-content-append",
    "name": "NQxb_Artifact_Update_v1__Return_Content_Append_Stub"
}

wf["nodes"].append(stub_node)


# =============================================================================
# Switch_Update_Mode — Add content_append route
# =============================================================================
switch_node = find_node("NQxb_Artifact_Update_v1__Switch_Update_Mode")
switch_rules = switch_node["parameters"]["rules"]["values"]

# Add content_append route condition
content_append_condition = {
    "conditions": {
        "options": {
            "caseSensitive": True,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 3
        },
        "conditions": [
            {
                "leftValue": "={{ $json._update_mode }}",
                "rightValue": "content_append",
                "operator": {
                    "type": "string",
                    "operation": "equals"
                },
                "id": "route-content-append"
            }
        ],
        "combinator": "and"
    }
}

# Insert after noop (index 2), before spine_only
switch_rules.insert(3, content_append_condition)


# =============================================================================
# CONNECTIONS — Add content_append route from Switch to Stub
# =============================================================================
# Switch_Update_Mode outputs: [0]=tags_only, [1]=spine_fields, [2]=noop, [3]=NEW content_append, [4]=spine_only, [5]=mixed, [6]=extension_only(fallback)
# Need to update connections to account for the new output index

switch_conn = wf["connections"]["NQxb_Artifact_Update_v1__Switch_Update_Mode"]["main"]

# Current order: [0]=tags, [1]=spine_fields, [2]=noop, [3]=spine_only→Compute_Mixed, [4]=mixed→Compute_Mixed, [5]=extension→Switch_Type
# After insert at index 3: [0]=tags, [1]=spine_fields, [2]=noop, [3]=content_append(NEW), [4]=spine_only→Compute_Mixed, [5]=mixed→Compute_Mixed, [6]=extension→Switch_Type

# Insert the new connection at index 3
new_conn = [{"node": "NQxb_Artifact_Update_v1__Return_Content_Append_Stub", "type": "main", "index": 0}]
switch_conn.insert(3, new_conn)

# Add stub node to connections (terminal — no outputs)
# No outgoing connections needed since it's a terminal node


# =============================================================================
# Write outputs
# =============================================================================

# Archive current version
os.makedirs(os.path.dirname(ARCHIVE), exist_ok=True)
with open(SRC, "r", encoding="utf-8") as f:
    original = f.read()
with open(ARCHIVE, "w", encoding="utf-8") as f:
    f.write(original)

# Write new version
with open(DST, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"Archived: {os.path.basename(ARCHIVE)}")
print(f"Created:  {os.path.basename(DST)}")
print(f"Nodes:    {len(wf['nodes'])}")

# Verify all modifications applied
for name in [
    "NQxb_Artifact_Update_v1__Normalize_Request",
    "NQxb_Artifact_Update_v1__Validate_Request",
    "NQxb_Artifact_Update_v1__Check_Mutability_Rules",
    "NQxb_Artifact_Update_v1__Compute_Mixed_Spine_Update",
    "NQxb_Artifact_Update_v1__Return_Content_Append_Stub",
]:
    node = find_node(name)
    code = node["parameters"]["jsCode"]
    if "T140" in code:
        print(f"  OK {name} -- T140 markers present")
    else:
        print(f"  FAIL {name} -- MISSING T140 markers")

# Verify Switch has correct number of routes
switch = find_node("NQxb_Artifact_Update_v1__Switch_Update_Mode")
route_count = len(switch["parameters"]["rules"]["values"])
conn_count = len(wf["connections"]["NQxb_Artifact_Update_v1__Switch_Update_Mode"]["main"])
print(f"  Switch routes: {route_count} conditions, {conn_count} connections")
