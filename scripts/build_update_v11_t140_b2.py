"""
Build script: T140 Branch 2 — Content Merge Engine
Modifies NQxb_Artifact_Update_v1__T140

Changes:
  L1: Deep merge engine (recursive, deterministic)
  L2: Array handling (replace-only, no concat)
  L3: Replace mode isolation (bypass merge completely)
  L4: append_log protection (reject incoming, preserve existing)

  NEW NODE: Guard_Content_Error (IF between Compute_Mixed and DB_Update)

Usage: python scripts/build_update_v11_t140_b2.py
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
# Replace Compute_Mixed_Spine_Update code entirely
# =============================================================================
COMPUTE_MIXED_CODE = r"""// NQxb_Artifact_Update_v1__Compute_Mixed_Spine_Update
// T87: Build unified spine PATCH for spine_only and mixed modes
// T140 B1: content field integration + content_mode routing
// T140 B2: Deep merge engine, array replace, append_log protection
// Handles: title, summary, priority, content, tags, version increment
// Single atomic PostgREST PATCH to qxb_artifact

const item = $json;
const normalizeNode = item._normalized_request;
const existingArtifact = item._existing_artifact;

const spineFields = normalizeNode.spine_fields || {};
const tags = normalizeNode.tags || null;
const currentVersion = existingArtifact.version ?? 0;

// ==========================================================================
// T140 B2 L1+L2: Deterministic deep merge
// Rules (LOCKED):
//   - Objects → recursive merge
//   - Scalars → overwrite
//   - Missing keys → preserved
//   - Arrays → ALWAYS replace (no merge, no concat)
//   - null → overwrite (explicit null replaces existing value)
// ==========================================================================
function deepMerge(target, source) {
  const result = { ...target };
  for (const key of Object.keys(source)) {
    const srcVal = source[key];
    const tgtVal = target[key];

    if (
      srcVal !== null &&
      typeof srcVal === 'object' &&
      !Array.isArray(srcVal) &&
      tgtVal !== null &&
      typeof tgtVal === 'object' &&
      !Array.isArray(tgtVal)
    ) {
      // Both are non-null objects (not arrays) → recursive merge
      result[key] = deepMerge(tgtVal, srcVal);
    } else {
      // Scalars, arrays, nulls, or type mismatch → overwrite
      result[key] = srcVal;
    }
  }
  return result;
}

// ==========================================================================
// T140 B2 L4: append_log protection — HARD GUARD
// append_log is a reserved system namespace (Branch 3)
// Reject any incoming payload that includes append_log at top level
// ==========================================================================
const contentUpdate = normalizeNode.content || null;
const contentMode = normalizeNode.content_mode || 'merge';

if (contentUpdate && 'append_log' in contentUpdate) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      _content_error: true,
      error: {
        code: 'RESERVED_NAMESPACE',
        message: "Field 'append_log' is a reserved system namespace and cannot be modified via content update. Use content_append operations instead.",
        details: {
          field: 'append_log',
          artifact_id: existingArtifact.artifact_id,
          artifact_type: existingArtifact.artifact_type,
          hint: 'Remove append_log from content payload. append_log is managed exclusively by the content_append system (Branch 3).',
        },
      },
    },
  }];
}

// Build the spine patch object
const patch = {};

// Spine fields (title, summary, priority)
if ('title' in spineFields) patch.title = spineFields.title;
if ('summary' in spineFields) patch.summary = spineFields.summary;
if ('priority' in spineFields) patch.priority = spineFields.priority;
if ('parent_artifact_id' in spineFields) patch.parent_artifact_id = spineFields.parent_artifact_id;

// ==========================================================================
// T140 B2 L3: Replace mode — bypass merge completely
// T140 B2 L1: Merge mode — deterministic deep merge
// T140 B2 L4: Preserve existing append_log after merge or replace
// ==========================================================================
if (contentUpdate) {
  // Safety: parse existing content if stored as string (double-serialization recovery)
  let existingContent = existingArtifact.content || {};
  if (typeof existingContent === 'string') {
    try { existingContent = JSON.parse(existingContent); } catch (e) { existingContent = {}; }
  }

  // Capture existing append_log before any mutation
  const existingAppendLog = existingContent.append_log ?? null;

  if (contentMode === 'replace') {
    // L3: Full replacement — bypass merge completely
    patch.content = { ...contentUpdate };
  } else {
    // L1+L2: Deterministic deep merge (objects recursive, arrays replace)
    patch.content = deepMerge(existingContent, contentUpdate);
  }

  // L4: Restore append_log if it existed (protected from both merge and replace)
  if (existingAppendLog !== null) {
    patch.content.append_log = existingAppendLog;
  }
}

// Tag merge (if mixed mode)
let tagChanges = null;
if (tags) {
  const currentTags = existingArtifact.tags || [];
  const addTags = tags.add || [];
  const removeTags = tags.remove || [];

  let merged = currentTags.filter(t => !removeTags.includes(t));
  for (const t of addTags) {
    if (!merged.includes(t)) merged.push(t);
  }

  patch.tags = JSON.stringify(merged);
  tagChanges = {
    added: addTags.filter(t => !currentTags.includes(t)),
    removed: removeTags.filter(t => currentTags.includes(t)),
    final: merged,
  };
}

// Version increment (always)
patch.version = currentVersion + 1;

return [{
  json: {
    artifact_id: existingArtifact.artifact_id,
    workspace_id: existingArtifact.workspace_id,
    artifact_type: existingArtifact.artifact_type,
    current_version: currentVersion,
    _spine_patch: patch,
    _tag_changes: tagChanges,
    _update_mode: item._update_mode,
    _gw_debug: item._gw_debug,
    gw_action: item.gw_action,
    gw_workspace_id: item.gw_workspace_id,
  }
}];"""

compute_node = find_node("NQxb_Artifact_Update_v1__Compute_Mixed_Spine_Update")
compute_node["parameters"]["jsCode"] = COMPUTE_MIXED_CODE


# =============================================================================
# NEW NODE: Guard_Content_Error
# Routes append_log rejection errors before DB write
# =============================================================================
guard_node = {
    "parameters": {
        "conditions": {
            "options": {
                "caseSensitive": True,
                "leftValue": "",
                "typeValidation": "strict"
            },
            "conditions": [
                {
                    "id": "content-error-check",
                    "leftValue": "={{ $json._content_error }}",
                    "rightValue": True,
                    "operator": {
                        "type": "boolean",
                        "operation": "true"
                    }
                }
            ],
            "combinator": "and"
        },
        "options": {}
    },
    "type": "n8n-nodes-base.if",
    "typeVersion": 2,
    "position": [112, 0],  # Between Compute_Mixed (0,0) and DB_Update (224,0)
    "id": "t140-b2-guard-content-error",
    "name": "NQxb_Artifact_Update_v1__Guard_Content_Error"
}

wf["nodes"].append(guard_node)


# =============================================================================
# CONNECTIONS: Insert guard between Compute_Mixed and DB_Update_Mixed_Spine
# =============================================================================
# Current: Compute_Mixed → DB_Update_Mixed_Spine
# New:     Compute_Mixed → Guard_Content_Error
#          Guard_Content_Error [true/error] → Return_Error_Passthrough
#          Guard_Content_Error [false/ok]   → DB_Update_Mixed_Spine

# Update Compute_Mixed output to point to guard
wf["connections"]["NQxb_Artifact_Update_v1__Compute_Mixed_Spine_Update"]["main"] = [
    [
        {
            "node": "NQxb_Artifact_Update_v1__Guard_Content_Error",
            "type": "main",
            "index": 0
        }
    ]
]

# Add guard connections: true (error) → error passthrough, false (ok) → DB
wf["connections"]["NQxb_Artifact_Update_v1__Guard_Content_Error"] = {
    "main": [
        [
            {
                "node": "NQxb_Artifact_Update_v1__Return_Error_Passthrough",
                "type": "main",
                "index": 0
            }
        ],
        [
            {
                "node": "NQxb_Artifact_Update_v1__DB_Update_Mixed_Spine",
                "type": "main",
                "index": 0
            }
        ]
    ]
}


# =============================================================================
# Write outputs
# =============================================================================
with open(DOWNLOAD, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

with open(REPO_OUT, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f"Nodes: {len(wf['nodes'])}")

# Verify
node = find_node("NQxb_Artifact_Update_v1__Compute_Mixed_Spine_Update")
code = node["parameters"]["jsCode"]
checks = [
    ("deepMerge function", "function deepMerge(target, source)" in code),
    ("recursive merge", "deepMerge(tgtVal, srcVal)" in code),
    ("array replace (not concat)", "Array.isArray(srcVal)" in code),
    ("append_log rejection", "RESERVED_NAMESPACE" in code),
    ("append_log preservation", "existingAppendLog" in code),
    ("replace isolation", "contentMode === 'replace'" in code),
    ("no JSON.stringify on content", "JSON.stringify(contentUpdate)" not in code and "JSON.stringify(merged)" not in code),
    ("B2 markers", "T140 B2" in code),
]

for label, ok in checks:
    print(f"  {'OK' if ok else 'FAIL'}: {label}")

# Verify guard node exists
try:
    find_node("NQxb_Artifact_Update_v1__Guard_Content_Error")
    print("  OK: Guard_Content_Error node present")
except:
    print("  FAIL: Guard_Content_Error node missing")

# Verify connections
cm_conn = wf["connections"]["NQxb_Artifact_Update_v1__Compute_Mixed_Spine_Update"]["main"]
guard_target = cm_conn[0][0]["node"]
print(f"  OK: Compute_Mixed -> {guard_target.replace('NQxb_Artifact_Update_v1__', '')}")

gc_conn = wf["connections"]["NQxb_Artifact_Update_v1__Guard_Content_Error"]["main"]
print(f"  OK: Guard [error] -> {gc_conn[0][0]['node'].replace('NQxb_Artifact_Update_v1__', '')}")
print(f"  OK: Guard [ok]    -> {gc_conn[1][0]['node'].replace('NQxb_Artifact_Update_v1__', '')}")
