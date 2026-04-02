"""
Sapling A — Response & Error Integrity: Build Script
=====================================================
Patches Save v44 -> v48 and Update T140 v1 -> v2

Changes:
  Branch 1 (Error Surfacing): Standardize error envelope consistency
  Branch 2 (Response Shape):  Add version, remove debug fields, standardize workspace_id, add _gw_route to success
  Branch 3 (No-Op Extension): Unify error code to EXTENSION_NOT_MUTABLE, add twig to explicit routing

Inputs:
  workflows/NQxb_Artifact_Save_v1 (44).json
  workflows/NQxb_Artifact_Update_v1__T140 (1).json

Outputs:
  workflows/NQxb_Artifact_Save_v1 (48).json
  workflows/NQxb_Artifact_Update_v1__T140 (2).json

Archives:
  workflows/Archive/NQxb_Artifact_Save_v1__v44__2026-03-31.json
  workflows/Archive/NQxb_Artifact_Update_v1__T140__v1__2026-03-31.json
"""

import json
import shutil
import os

WORKFLOWS_DIR = os.path.join(os.path.dirname(__file__), '..', 'workflows')
ARCHIVE_DIR = os.path.join(WORKFLOWS_DIR, 'Archive')

SAVE_INPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Artifact_Save_v1 (44).json')
SAVE_OUTPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Artifact_Save_v1 (48).json')
SAVE_ARCHIVE = os.path.join(ARCHIVE_DIR, 'NQxb_Artifact_Save_v1__v44__2026-03-31.json')

UPDATE_INPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Artifact_Update_v1__T140 (1).json')
UPDATE_OUTPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Artifact_Update_v1__T140 (2).json')
UPDATE_ARCHIVE = os.path.join(ARCHIVE_DIR, 'NQxb_Artifact_Update_v1__T140__v1__2026-03-31.json')


# ============================================================================
# PATCH 1: Save Return_Response — Branch 1 + Branch 2
# ============================================================================

SAVE_RETURN_RESPONSE_NEW_CODE = r'''// NQxb_Artifact_Save_v1__Return_Response
// v3.0: Sapling A — Response & Error Integrity
//   Branch 1: Deterministic error surfacing — consistent error envelope
//   Branch 2: Consistent response shape — version on both paths,
//             _gw_route on both paths, standardize workspace_id,
//             remove _debug_warnings and _owner_source

const j = $json ?? {};
const now = new Date().toISOString();

const ALLOWED_ERROR_CODES = new Set([
  'AUTH_REQUIRED',
  'WORKSPACE_FORBIDDEN',
  'ARTIFACT_TYPE_NOT_ALLOWED',
  'ACTION_NOT_ALLOWED',
  'VALIDATION_ERROR',
  'NOT_FOUND',
  'CONFLICT',
  'IMMUTABLE_RECORD',
  'LIFECYCLE_TRANSITION_NOT_ALLOWED',
  'SNAPSHOT_REQUIRED',
  'JOURNAL_EXTENSION_INVALID',
  'INVALID_SEMANTIC_TYPE',
  'SEMANTIC_TYPE_INACTIVE',
  'MIXED_UPDATE_NOT_ALLOWED',
  'SEMANTIC_TYPE_NOT_APPLICABLE',
  'SEMANTIC_TYPE_RESOLUTION_FAILED',
  'EXTENSION_NOT_MUTABLE',
  'INTERNAL_ERROR',
]);

const safeStr = (v) => (typeof v === 'string' ? v : v == null ? null : String(v));
const coalesce = (...vals) => {
  for (const v of vals) if (v !== undefined && v !== null) return v;
  return null;
};

const isUniqueViolationText = (s) => {
  const txt = (s ?? '').toString();
  return (
    txt.includes('"code":"23505"') ||
    txt.includes('23505') ||
    txt.toLowerCase().includes('duplicate key value violates unique constraint') ||
    txt.toLowerCase().includes('violates unique constraint') ||
    txt.toLowerCase().includes('unique constraint')
  );
};

const ctxNormalize = (() => {
  try {
    return $node['NQxb_Artifact_Save_v1__Normalize_Request']?.json ?? {};
  } catch (e) {
    return {};
  }
})();

const gw_action = coalesce(j.gw_action, ctxNormalize.gw_action, 'artifact.save');

const workspace_id = coalesce(
  j.gw_workspace_id,
  j.workspace_id,
  ctxNormalize.gw_workspace_id,
  ctxNormalize.workspace_id
);

const artifact_type = coalesce(j.saved_artifact_type, j.artifact_type, ctxNormalize.artifact_type);

const buildErrorEnvelope = ({ code, message, details, artifact_id = null, version = null }) => {
  let mapped = code;
  if (mapped === 'IMMUTABILITY_ERROR') mapped = 'IMMUTABLE_RECORD';

  const finalCode = ALLOWED_ERROR_CODES.has(mapped) ? mapped : 'INTERNAL_ERROR';

  return [
    {
      json: {
        ok: false,
        _gw_route: 'error',
        gw_action,
        artifact_type,
        artifact_id,
        workspace_id,
        version: version ?? null,
        error: {
          code: finalCode,
          message: safeStr(message) ?? 'Gateway error',
          details:
            finalCode === mapped
              ? (details ?? {})
              : {
                  original: { code, message, details },
                  note: 'Error code not allow-listed; mapped to INTERNAL_ERROR',
                },
        },
        timestamp: now,
      },
    },
  ];
};

// PATH 1: Upstream already produced error envelope (ok:false or _gw_route:error)
if (j && (j.ok === false || j._gw_route === 'error')) {
  const upstreamErr = j.error ?? {};
  const upstreamCodeRaw = safeStr(upstreamErr.code);

  const upstreamCode =
    upstreamCodeRaw === 'IMMUTABILITY_ERROR' ? 'IMMUTABLE_RECORD' : upstreamCodeRaw;

  const code = ALLOWED_ERROR_CODES.has(upstreamCode) ? upstreamCode : 'INTERNAL_ERROR';
  const message = safeStr(upstreamErr.message) ?? 'Gateway error';
  const details = upstreamErr.details ?? {};

  return [
    {
      json: {
        ok: false,
        _gw_route: 'error',
        gw_action,
        artifact_type,
        artifact_id: j.artifact_id ?? null,
        workspace_id,
        version: null,
        error: {
          code,
          message,
          details: ALLOWED_ERROR_CODES.has(upstreamCode)
            ? details
            : {
                original_error: upstreamErr,
                note: 'Upstream error code was not allow-listed; mapped to INTERNAL_ERROR',
              },
        },
        timestamp: now,
      },
    },
  ];
}

// PATH 2: n8n HTTP node error fields (errorMessage, errorDescription, etc.)
if (j && (j.errorMessage || j.errorDescription || j.errorDetails || j.n8nDetails)) {
  const httpCodeRaw = j.errorDetails?.httpCode;
  const httpCode = Number(httpCodeRaw ?? NaN);

  const raw = Array.isArray(j.errorDetails?.rawErrorMessage)
    ? j.errorDetails.rawErrorMessage.join(' ')
    : safeStr(j.errorDetails?.rawErrorMessage) ?? '';

  const isUnique = (httpCode === 409) || isUniqueViolationText(raw);

  const code = isUnique ? 'CONFLICT' : 'INTERNAL_ERROR';
  const message = safeStr(j.errorDescription) ?? safeStr(j.errorMessage) ?? 'Request failed';

  return buildErrorEnvelope({
    code,
    message,
    details: {
      httpCode: Number.isFinite(httpCode) ? httpCode : null,
      rawErrorMessage: j.errorDetails?.rawErrorMessage ?? null,
      n8nDetails: j.n8nDetails ?? null,
    },
  });
}

// PATH 3: String error field (Supabase node error output)
if (typeof j.error === 'string' && j.error.trim() !== '') {
  const errText = j.error.trim();
  const code = isUniqueViolationText(errText) ? 'CONFLICT' : 'INTERNAL_ERROR';

  return buildErrorEnvelope({
    code,
    message: isUniqueViolationText(errText)
      ? 'Conflict: unique constraint violation'
      : 'Upstream database error',
    details: {
      rawErrorMessage: errText,
      note: 'Received ok:true with error:string (likely Supabase node error output)',
    },
  });
}

// PATH 4: Success
const isUpdate = j.is_update === true;
const op = isUpdate ? 'UPDATE' : 'INSERT';

const ctxSavedId = (() => {
  try {
    return $node['NQxb_Artifact_Save_v1__Normalize_Saved_ID']?.json?.saved_artifact_id ?? null;
  } catch (e) {
    return null;
  }
})();

const artifact_id = coalesce(j.saved_artifact_id, j.artifact_id, ctxSavedId);
const extension = j.extension ?? null;
const version = coalesce(j.version, j.saved_version, null);

if (!artifact_id) {
  return buildErrorEnvelope({
    code: 'INTERNAL_ERROR',
    message: 'artifact.save completed response stage without a valid artifact_id (fail-closed)',
    details: {
      operation: op,
      note: 'Upstream insert/update did not yield an artifact_id',
    },
  });
}

const warnings = j._person_warnings && j._person_warnings.length > 0 ? j._person_warnings : undefined;

return [
  {
    json: {
      ok: true,
      _gw_route: 'ok',
      gw_action,
      artifact_id,
      artifact_type,
      workspace_id,
      operation: op,
      version: version ?? null,
      extension,
      warnings,
      timestamp: now,
    },
  },
];
'''


# ============================================================================
# PATCH 2: Update Return_Unimplemented_Type_Error — Branch 3
# ============================================================================

UPDATE_UNIMPLEMENTED_NEW_CODE = r'''// NQxb_Artifact_Update_v1__Return_Unimplemented_Type_Error
// v2.0: Sapling A Branch 3 — Reject No-Op Extension Updates
// Error code unified to EXTENSION_NOT_MUTABLE (replaces UPDATE_NOT_IMPLEMENTED)

const normalize = $node['NQxb_Artifact_Update_v1__Normalize_Request'].json;

return [{
  json: {
    ok: false,
    _gw_route: 'error',
    gw_action: 'artifact.update',
    artifact_id: normalize.artifact_id ?? null,
    artifact_type: normalize.artifact_type ?? null,
    workspace_id: normalize.gw_workspace_id ?? null,
    version: null,
    error: {
      code: 'EXTENSION_NOT_MUTABLE',
      message: `Extension updates are not supported for artifact type '${normalize.artifact_type ?? 'unknown'}'. Use tags.add/tags.remove for metadata updates.`,
      details: {
        artifact_type: normalize.artifact_type ?? null,
        artifact_id: normalize.artifact_id ?? null
      }
    },
    timestamp: new Date().toISOString()
  }
}];
'''


# ============================================================================
# PATCH 3: Update Return_Unhandled_Type_Error — Branch 3
# ============================================================================

UPDATE_UNHANDLED_NEW_CODE = r'''// NQxb_Artifact_Update_v1__Return_Unhandled_Type_Error
// v2.0: Sapling A Branch 3 — Reject No-Op Extension Updates
// Error code unified to EXTENSION_NOT_MUTABLE (replaces EXTENSION_ROUTING_UNHANDLED_TYPE)
// Fail-closed: no silent drops for unrouted types.

const normalize = $node['NQxb_Artifact_Update_v1__Normalize_Request'].json;

return [{
  json: {
    ok: false,
    _gw_route: 'error',
    gw_action: 'artifact.update',
    artifact_id: normalize.artifact_id ?? null,
    artifact_type: normalize.artifact_type ?? null,
    workspace_id: normalize.gw_workspace_id ?? null,
    version: null,
    error: {
      code: 'EXTENSION_NOT_MUTABLE',
      message: `Extension updates are not supported for artifact type '${normalize.artifact_type ?? 'unknown'}'. Use tags.add/tags.remove for metadata updates.`,
      details: {
        artifact_type: normalize.artifact_type ?? null,
        artifact_id: normalize.artifact_id ?? null
      }
    },
    timestamp: new Date().toISOString()
  }
}];
'''


# ============================================================================
# PATCH 4: Switch_Type_For_Update — add twig output routed to rejection
# ============================================================================

TWIG_SWITCH_CONDITION = {
    "conditions": {
        "options": {
            "caseSensitive": True,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 3
        },
        "conditions": [
            {
                "leftValue": "={{ $json.artifact_type }}",
                "rightValue": "twig",
                "operator": {
                    "type": "string",
                    "operation": "equals"
                },
                "id": "update-twig"
            }
        ],
        "combinator": "and"
    }
}


# ============================================================================
# EXECUTION
# ============================================================================

def find_node(workflow, name):
    """Find a node by name in the workflow."""
    for i, node in enumerate(workflow['nodes']):
        if node.get('name') == name:
            return i, node
    return None, None


def patch_code_node(workflow, node_name, new_code):
    """Replace jsCode in a code node."""
    idx, node = find_node(workflow, node_name)
    if idx is None:
        raise ValueError(f"Node not found: {node_name}")
    old_code = node['parameters'].get('jsCode', '')
    node['parameters']['jsCode'] = new_code
    print(f"  PATCHED: {node_name}")
    print(f"    Old code length: {len(old_code)} chars")
    print(f"    New code length: {len(new_code)} chars")
    return idx


def main():
    os.makedirs(ARCHIVE_DIR, exist_ok=True)

    # ---- SAVE WORKFLOW ----
    print("=" * 60)
    print("SAVE WORKFLOW: v44 -> v48")
    print("=" * 60)

    with open(SAVE_INPUT, 'r', encoding='utf-8') as f:
        save_wf = json.load(f)

    # Patch 1: Return_Response (Branch 1 + 2)
    patch_code_node(save_wf, 'NQxb_Artifact_Save_v1__Return_Response', SAVE_RETURN_RESPONSE_NEW_CODE)

    # Archive and write
    shutil.copy2(SAVE_INPUT, SAVE_ARCHIVE)
    print(f"  ARCHIVED: {SAVE_ARCHIVE}")

    with open(SAVE_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(save_wf, f, indent=2)
    print(f"  OUTPUT: {SAVE_OUTPUT}")

    # ---- UPDATE WORKFLOW ----
    print()
    print("=" * 60)
    print("UPDATE WORKFLOW: T140 v1 -> v2")
    print("=" * 60)

    with open(UPDATE_INPUT, 'r', encoding='utf-8') as f:
        update_wf = json.load(f)

    # Patch 2: Return_Unimplemented_Type_Error (Branch 3)
    patch_code_node(update_wf, 'NQxb_Artifact_Update_v1__Return_Unimplemented_Type_Error', UPDATE_UNIMPLEMENTED_NEW_CODE)

    # Patch 3: Return_Unhandled_Type_Error (Branch 3)
    patch_code_node(update_wf, 'NQxb_Artifact_Update_v1__Return_Unhandled_Type_Error', UPDATE_UNHANDLED_NEW_CODE)

    # Patch 4: Switch_Type_For_Update — add twig condition
    idx, switch_node = find_node(update_wf, 'NQxb_Artifact_Update_v1__Switch_Type_For_Update')
    if idx is None:
        raise ValueError("Switch_Type_For_Update not found")

    rules = switch_node['parameters']['rules']['values']
    # Check if twig already exists
    twig_exists = any(
        any(c.get('id') == 'update-twig' for c in rule.get('conditions', {}).get('conditions', []))
        for rule in rules
    )
    if not twig_exists:
        rules.append(TWIG_SWITCH_CONDITION)
        print(f"  PATCHED: Switch_Type_For_Update — added twig output (index {len(rules) - 1})")

        # Add connection for new twig output -> Return_Unimplemented_Type_Error
        conn_key = 'NQxb_Artifact_Update_v1__Switch_Type_For_Update'
        connections = update_wf['connections'][conn_key]['main']

        # The new twig output should go BEFORE the extra/fallback output
        # Currently: [project, branch, limb, leaf, extra/fallback]
        # After:     [project, branch, limb, leaf, twig, extra/fallback]
        # Insert twig connection before the last (fallback) entry
        twig_connection = [{
            "node": "NQxb_Artifact_Update_v1__Return_Unimplemented_Type_Error",
            "type": "main",
            "index": 0
        }]
        connections.insert(len(connections) - 1, twig_connection)
        print(f"  PATCHED: Switch_Type_For_Update connections — twig -> Return_Unimplemented_Type_Error")
    else:
        print(f"  SKIPPED: Switch_Type_For_Update — twig output already exists")

    # Archive and write
    shutil.copy2(UPDATE_INPUT, UPDATE_ARCHIVE)
    print(f"  ARCHIVED: {UPDATE_ARCHIVE}")

    with open(UPDATE_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(update_wf, f, indent=2)
    print(f"  OUTPUT: {UPDATE_OUTPUT}")

    # ---- SUMMARY ----
    print()
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"  Save:   {SAVE_INPUT} -> {SAVE_OUTPUT}")
    print(f"  Update: {UPDATE_INPUT} -> {UPDATE_OUTPUT}")
    print()
    print("  Changes:")
    print("    1. Save Return_Response v2.6 -> v3.0")
    print("       - version field on BOTH success and error paths")
    print("       - _gw_route on BOTH paths (success='ok', error='error')")
    print("       - workspace_id standardized (was gw_workspace_id on error)")
    print("       - Removed _debug_warnings, _owner_source from success")
    print("       - EXTENSION_NOT_MUTABLE added to error allowlist")
    print("    2. Update Return_Unimplemented_Type_Error v1 -> v2")
    print("       - Error code: UPDATE_NOT_IMPLEMENTED -> EXTENSION_NOT_MUTABLE")
    print("       - workspace_id standardized")
    print("       - version:null included in error response")
    print("    3. Update Return_Unhandled_Type_Error v1 -> v2")
    print("       - Error code: EXTENSION_ROUTING_UNHANDLED_TYPE -> EXTENSION_NOT_MUTABLE")
    print("       - workspace_id standardized")
    print("       - version:null included in error response")
    print("    4. Update Switch_Type_For_Update — twig output added")
    print("       - Routes twig extension updates to explicit rejection")
    print("       - Was falling through to unhandled fallback")
    print()
    print("  STOP: Review outputs before deployment.")


if __name__ == '__main__':
    main()
