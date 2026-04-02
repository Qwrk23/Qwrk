"""
Build script: T140 Branch 3 — Append System (Immutable Types)
Replaces Return_Content_Append_Stub with dedicated append pipeline.

New nodes:
  - Validate_Content_Append — type check, payload validation, nested injection guard
  - Guard_Append_Validation — IF: error → Return_Error_Passthrough, ok → Compute
  - Compute_Content_Append — init append_log, stamp metadata, build patch
  - DB_Update_Content_Append — atomic PostgREST PATCH
  - Return_Content_Append_Ack — success response

Removes:
  - Return_Content_Append_Stub

Usage: python scripts/build_update_v12_t140_b3.py
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


def remove_node(name):
    wf["nodes"] = [n for n in wf["nodes"] if n["name"] != name]
    if name in wf["connections"]:
        del wf["connections"][name]


# =============================================================================
# Remove stub
# =============================================================================
remove_node("NQxb_Artifact_Update_v1__Return_Content_Append_Stub")


# =============================================================================
# Node 1: Validate_Content_Append
# =============================================================================
VALIDATE_CODE = r"""// NQxb_Artifact_Update_v1__Validate_Content_Append
// T140 B3 L1: content_append entry point + validation
// T140 B3 L4: append metadata pre-validation
//
// Checks:
// 1. Artifact type must be immutable (snapshot, journal, restart)
// 2. content_append must contain entries array
// 3. Each entry must be a non-null object
// 4. No nested append_log injection (recursive check)

const item = $json;
const normalizeNode = item._normalized_request;
const existing = item._existing_artifact;
const artifact_type = item.artifact_type;
const contentAppend = normalizeNode.content_append || null;

// 1. Type gate: ONLY immutable types
const ALLOWED_TYPES = ['snapshot', 'journal', 'restart'];
if (!ALLOWED_TYPES.includes(artifact_type)) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'CONTENT_APPEND_NOT_ALLOWED',
        message: "content_append is only available for immutable artifact types. Type '" + artifact_type + "' does not support append.",
        details: {
          artifact_id: item.artifact_id,
          artifact_type: artifact_type,
          allowed_types: ALLOWED_TYPES,
          hint: 'Use content field with content_mode for mutable types.',
        },
      },
    },
  }];
}

// 2. Payload structure: must have entries array
if (!contentAppend || !Array.isArray(contentAppend.entries) || contentAppend.entries.length === 0) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'VALIDATION_ERROR',
        message: 'content_append must include a non-empty entries array.',
        details: {
          artifact_id: item.artifact_id,
          artifact_type: artifact_type,
          hint: 'Provide content_append: { entries: [{ ... }, ...] }',
        },
      },
    },
  }];
}

// 3. Each entry must be a non-null object
for (let i = 0; i < contentAppend.entries.length; i++) {
  const entry = contentAppend.entries[i];
  if (!entry || typeof entry !== 'object' || Array.isArray(entry)) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Each entry in content_append.entries must be a non-null object. Entry at index ' + i + ' is invalid.',
          details: {
            artifact_id: item.artifact_id,
            index: i,
            received_type: entry === null ? 'null' : typeof entry,
          },
        },
      },
    }];
  }
}

// 4. Nested append_log injection guard (recursive)
function containsAppendLog(obj, path) {
  if (!obj || typeof obj !== 'object') return null;
  for (const key of Object.keys(obj)) {
    const currentPath = path ? path + '.' + key : key;
    if (key === 'append_log') return currentPath;
    if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
      const found = containsAppendLog(obj[key], currentPath);
      if (found) return found;
    }
  }
  return null;
}

for (let i = 0; i < contentAppend.entries.length; i++) {
  const injectionPath = containsAppendLog(contentAppend.entries[i], 'entries[' + i + ']');
  if (injectionPath) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'RESERVED_NAMESPACE',
          message: "Field 'append_log' is a reserved system namespace and cannot appear in append entries.",
          details: {
            artifact_id: item.artifact_id,
            location: injectionPath,
            hint: 'Remove append_log from entry payload. append_log is managed by the system.',
          },
        },
      },
    }];
  }
}

// Validation passed — forward everything
return [{ json: { ...item, ok: true } }];"""

validate_node = {
    "parameters": {"jsCode": VALIDATE_CODE},
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-1120, 320],
    "id": "t140-b3-validate-append",
    "name": "NQxb_Artifact_Update_v1__Validate_Content_Append"
}
wf["nodes"].append(validate_node)


# =============================================================================
# Node 2: Guard_Append_Validation (IF)
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
                    "id": "append-validation-error",
                    "leftValue": "={{ $json.ok }}",
                    "rightValue": False,
                    "operator": {
                        "type": "boolean",
                        "operation": "false"
                    }
                }
            ],
            "combinator": "and"
        },
        "options": {}
    },
    "type": "n8n-nodes-base.if",
    "typeVersion": 2,
    "position": [-896, 320],
    "id": "t140-b3-guard-append",
    "name": "NQxb_Artifact_Update_v1__Guard_Append_Validation"
}
wf["nodes"].append(guard_node)


# =============================================================================
# Node 3: Compute_Content_Append
# =============================================================================
COMPUTE_CODE = r"""// NQxb_Artifact_Update_v1__Compute_Content_Append
// T140 B3 L2: append_log initialization & structure
// T140 B3 L3: append operation execution
// T140 B3 L4: append metadata enforcement
//
// Atomic: read existing → init append_log → stamp entries → build patch

const item = $json;
const normalizeNode = item._normalized_request;
const existing = item._existing_artifact;
const contentAppend = normalizeNode.content_append;
const entries = contentAppend.entries;
const currentVersion = existing.version ?? 0;

// L2: Parse existing content (double-serialization recovery)
let existingContent = existing.content || {};
if (typeof existingContent === 'string') {
  try { existingContent = JSON.parse(existingContent); } catch (e) { existingContent = {}; }
}

// L2: Initialize append_log as empty array if missing
if (!Array.isArray(existingContent.append_log)) {
  existingContent.append_log = [];
}

// L3+L4: Stamp each entry with server metadata and append
const serverTimestamp = new Date().toISOString();

const stampedEntries = entries.map((entry, i) => ({
  ...entry,
  _meta: {
    timestamp: serverTimestamp,
    actor: entry.actor || 'system',
    index: existingContent.append_log.length + i,
  },
}));

// L3: Append to existing (preserve order, never reorder)
const updatedAppendLog = [...existingContent.append_log, ...stampedEntries];

// Build full content with updated append_log
const updatedContent = { ...existingContent, append_log: updatedAppendLog };

// Build spine patch (atomic single write)
const patch = {
  content: updatedContent,
  version: currentVersion + 1,
};

return [{
  json: {
    artifact_id: existing.artifact_id,
    workspace_id: existing.workspace_id,
    artifact_type: existing.artifact_type,
    current_version: currentVersion,
    _spine_patch: patch,
    _append_debug: {
      entries_appended: stampedEntries.length,
      total_entries: updatedAppendLog.length,
      server_timestamp: serverTimestamp,
    },
    gw_action: item.gw_action,
    gw_workspace_id: item.gw_workspace_id,
  },
}];"""

compute_node = {
    "parameters": {"jsCode": COMPUTE_CODE},
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-672, 400],
    "id": "t140-b3-compute-append",
    "name": "NQxb_Artifact_Update_v1__Compute_Content_Append"
}
wf["nodes"].append(compute_node)


# =============================================================================
# Node 4: DB_Update_Content_Append (HTTP Request)
# =============================================================================
db_node = {
    "parameters": {
        "method": "PATCH",
        "url": "=https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact?artifact_id=eq.{{ $json.artifact_id }}&workspace_id=eq.{{ $json.workspace_id }}&version=eq.{{ $json.current_version }}",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "supabaseApi",
        "sendHeaders": True,
        "headerParameters": {
            "parameters": [
                {
                    "name": "Prefer",
                    "value": "return=representation"
                }
            ]
        },
        "sendBody": True,
        "specifyBody": "json",
        "jsonBody": "={{ JSON.stringify($json._spine_patch) }}",
        "options": {}
    },
    "type": "n8n-nodes-base.httpRequest",
    "typeVersion": 4.2,
    "position": [-448, 400],
    "id": "t140-b3-db-append",
    "name": "NQxb_Artifact_Update_v1__DB_Update_Content_Append",
    "alwaysOutputData": True,
    "credentials": {
        "supabaseApi": {
            "id": "n4R4JdOIV9zrCGIT",
            "name": "Qwrk Supabase \u2013 Kernel v1"
        }
    },
    "onError": "continueErrorOutput"
}
wf["nodes"].append(db_node)


# =============================================================================
# Node 5: Return_Content_Append_Ack
# =============================================================================
ACK_CODE = r"""// NQxb_Artifact_Update_v1__Return_Content_Append_Ack
// T140 B3: Terminal acknowledgment for content_append operations

const patchResult = $json;
const compute = $node['NQxb_Artifact_Update_v1__Compute_Content_Append'].json;

// Concurrency check: if PATCH returned empty (version mismatch), report error
if (!patchResult || !patchResult.artifact_id) {
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'CONCURRENCY_CONFLICT',
        message: 'Artifact was modified by another operation. Retry with fresh version.',
        details: {
          artifact_id: compute.artifact_id,
          artifact_type: compute.artifact_type,
          expected_version: compute.current_version,
          hint: 'Re-fetch the artifact and retry the content_append operation.',
        },
      },
    },
  }];
}

return [{
  json: {
    ok: true,
    gw_action: 'artifact.update',
    operation: 'CONTENT_APPEND',
    artifact_id: patchResult.artifact_id,
    artifact_type: patchResult.artifact_type,
    gw_workspace_id: patchResult.workspace_id,
    version: patchResult.version,
    _append_result: compute._append_debug,
    _kgb: {
      status: 'CONTENT_APPEND_CONFIRMED',
      note: 'Entries appended to append_log. Version incremented. Original content preserved.',
    },
  },
}];"""

ack_node = {
    "parameters": {"jsCode": ACK_CODE},
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-224, 400],
    "id": "t140-b3-ack-append",
    "name": "NQxb_Artifact_Update_v1__Return_Content_Append_Ack"
}
wf["nodes"].append(ack_node)


# =============================================================================
# CONNECTIONS
# =============================================================================

# Switch_Update_Mode [content_append] → Validate_Content_Append (replace stub reference)
switch_conns = wf["connections"]["NQxb_Artifact_Update_v1__Switch_Update_Mode"]["main"]
# Index 3 is content_append
switch_conns[3] = [{"node": "NQxb_Artifact_Update_v1__Validate_Content_Append", "type": "main", "index": 0}]

# Validate → Guard
wf["connections"]["NQxb_Artifact_Update_v1__Validate_Content_Append"] = {
    "main": [[{"node": "NQxb_Artifact_Update_v1__Guard_Append_Validation", "type": "main", "index": 0}]]
}

# Guard [true/error] → Return_Error_Passthrough
# Guard [false/ok] → Compute_Content_Append
wf["connections"]["NQxb_Artifact_Update_v1__Guard_Append_Validation"] = {
    "main": [
        [{"node": "NQxb_Artifact_Update_v1__Return_Error_Passthrough", "type": "main", "index": 0}],
        [{"node": "NQxb_Artifact_Update_v1__Compute_Content_Append", "type": "main", "index": 0}]
    ]
}

# Compute → DB_Update
wf["connections"]["NQxb_Artifact_Update_v1__Compute_Content_Append"] = {
    "main": [[{"node": "NQxb_Artifact_Update_v1__DB_Update_Content_Append", "type": "main", "index": 0}]]
}

# DB_Update [success] → Ack, [error] → Error_Passthrough
wf["connections"]["NQxb_Artifact_Update_v1__DB_Update_Content_Append"] = {
    "main": [
        [{"node": "NQxb_Artifact_Update_v1__Return_Content_Append_Ack", "type": "main", "index": 0}],
        [{"node": "NQxb_Artifact_Update_v1__Return_Error_Passthrough", "type": "main", "index": 0}]
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

# Verify all new nodes exist
new_nodes = [
    "NQxb_Artifact_Update_v1__Validate_Content_Append",
    "NQxb_Artifact_Update_v1__Guard_Append_Validation",
    "NQxb_Artifact_Update_v1__Compute_Content_Append",
    "NQxb_Artifact_Update_v1__DB_Update_Content_Append",
    "NQxb_Artifact_Update_v1__Return_Content_Append_Ack",
]

for name in new_nodes:
    try:
        find_node(name)
        print(f"  OK: {name.replace('NQxb_Artifact_Update_v1__', '')}")
    except:
        print(f"  FAIL: {name.replace('NQxb_Artifact_Update_v1__', '')}")

# Verify stub removed
stub_found = any(n["name"] == "NQxb_Artifact_Update_v1__Return_Content_Append_Stub" for n in wf["nodes"])
print(f"  {'FAIL' if stub_found else 'OK'}: Stub removed")

# Verify connections
sc = wf["connections"]["NQxb_Artifact_Update_v1__Switch_Update_Mode"]["main"]
target = sc[3][0]["node"].replace("NQxb_Artifact_Update_v1__", "")
print(f"  OK: Switch[content_append] -> {target}")

# Verify pipeline flow
flow = []
current = "Validate_Content_Append"
for _ in range(5):
    full = f"NQxb_Artifact_Update_v1__{current}"
    if full in wf["connections"]:
        conns = wf["connections"][full]["main"]
        # Follow the ok/success path (last index for IF, first for others)
        if "Guard" in current:
            next_node = conns[1][0]["node"]  # false/ok path
        else:
            next_node = conns[0][0]["node"]  # main path
        short = next_node.replace("NQxb_Artifact_Update_v1__", "")
        flow.append(f"{current} -> {short}")
        current = short
    else:
        flow.append(f"{current} (terminal)")
        break

print(f"  Pipeline: {' | '.join(flow)}")
