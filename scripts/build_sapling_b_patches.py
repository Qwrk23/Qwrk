"""
Sapling B -- Gateway Strict Mode: Build Script
================================================
Patches Save v49 -> v50

Branch 1: Reject Unknown Extension Keys (Validate_Request)
Branch 2: Reject Unknown Top-Level Fields (Normalize_Request)
Branch 3: Reject Empty Required Objects (Validate_Request)
Branch 4: ALREADY IMPLEMENTED (append_log in Update)
Branch 5: Snapshot for-q Auto-Injection (Prepare_Insert_Payload)
Branch 6: Execution Status Auto-Default (Prepare_Insert_Payload)
Branch 7: Enforce Parent Requirement (Validate_Request)
Branch 8: Twig Content Completeness (Validate_Request)

Input:  workflows/NQxb_Artifact_Save_v1 (49).json
Output: workflows/NQxb_Artifact_Save_v1 (50).json
Archive: workflows/Archive/NQxb_Artifact_Save_v1__v49__2026-03-31.json
"""

import json
import shutil
import os

WORKFLOWS_DIR = os.path.join(os.path.dirname(__file__), '..', 'workflows')
ARCHIVE_DIR = os.path.join(WORKFLOWS_DIR, 'Archive')

SAVE_INPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Artifact_Save_v1 (49).json')
SAVE_OUTPUT = os.path.join(WORKFLOWS_DIR, 'NQxb_Artifact_Save_v1 (50).json')
SAVE_ARCHIVE = os.path.join(ARCHIVE_DIR, 'NQxb_Artifact_Save_v1__v49__2026-03-31.json')


# ============================================================================
# PATCH 1: Validate_Request -- Branches 1, 3, 7, 8
# ============================================================================

VALIDATE_REQUEST_NEW = r'''// NQxb_Artifact_Save_v1__Validate_Request
// v3.0: Sapling B -- Gateway Strict Mode
//   Branch 1: Reject unknown extension keys (per-type allowlist)
//   Branch 3: Reject empty required objects (snapshot/restart payload)
//   Branch 7: Enforce parent requirement for child types
//   Branch 8: Twig content completeness (4-field intent bundle)
//   + Branch 2: Unknown top-level field check (from Normalize_Request flag)

const req = $json;
const errors = [];

const isNonEmptyString = (v) => typeof v === 'string' && v.trim() !== '';
const trimOrNull = (v) => (typeof v === 'string' ? v.trim() : v ?? null);

// Always required
if (!isNonEmptyString(req.gw_workspace_id)) {
  errors.push({ field: 'gw_workspace_id', reason: 'required' });
}

if (!isNonEmptyString(req.artifact_type)) {
  errors.push({ field: 'artifact_type', reason: 'required' });
}

const artifact_type = trimOrNull(req.artifact_type);
const is_update = req.is_update === true;

// Priority validation
if (req.priority !== undefined && req.priority !== null) {
  const p = Number(req.priority);
  if (!Number.isInteger(p) || p < 1 || p > 5) {
    errors.push({ field: 'priority', reason: 'must be integer 1-5', received: req.priority });
  }
}

// Operation-specific requirements
if (is_update) {
  if (!isNonEmptyString(req.artifact_id)) {
    errors.push({ field: 'artifact_id', reason: 'required for UPDATE operation' });
  }
  if (req._provided_fields?.title && !isNonEmptyString(req.title)) {
    errors.push({ field: 'title', reason: 'if provided for UPDATE, must be non-empty' });
  }
} else {
  if (!isNonEmptyString(req.owner_user_id)) {
    errors.push({ field: 'owner_user_id', reason: 'required for INSERT operation' });
  }
  if (!isNonEmptyString(req.title)) {
    errors.push({ field: 'title', reason: 'required for INSERT operation' });
  }
}

// =========================================================
// Type-specific validation (existing)
// =========================================================

if (artifact_type === 'project') {
  if (!is_update) {
    if (!isNonEmptyString(req.extension?.lifecycle_stage)) {
      errors.push({ field: 'extension.lifecycle_stage', reason: 'required for project INSERT' });
    }
  }
} else if (artifact_type === 'restart' || artifact_type === 'snapshot') {
  if (!is_update) {
    if (
      !req.extension?.payload ||
      typeof req.extension.payload !== 'object' ||
      Array.isArray(req.extension.payload)
    ) {
      errors.push({
        field: 'extension.payload',
        reason: `required for ${artifact_type} INSERT (must be object)`,
      });
    }
    // Branch 3: Reject empty payload object
    else if (Object.keys(req.extension.payload).length === 0) {
      errors.push({
        field: 'extension.payload',
        reason: `extension.payload must not be empty for ${artifact_type} INSERT`,
      });
    }
  }
} else if (artifact_type === 'instruction_pack') {
  if (!is_update) {
    if (!isNonEmptyString(req.extension?.scope)) {
      errors.push({ field: 'extension.scope', reason: 'required for instruction_pack INSERT' });
    }
    if (typeof req.extension?.active !== 'boolean') {
      errors.push({ field: 'extension.active', reason: 'required for instruction_pack INSERT (boolean)' });
    }
    if (typeof req.extension?.priority !== 'number') {
      errors.push({ field: 'extension.priority', reason: 'required for instruction_pack INSERT (number)' });
    }
    if (!isNonEmptyString(req.extension?.pack_format)) {
      errors.push({ field: 'extension.pack_format', reason: 'required for instruction_pack INSERT' });
    }
  }
} else if (artifact_type === 'journal') {
  if (!is_update) {
    const ext = req.extension;
    const journalErrors = [];

    if (!ext || typeof ext !== 'object' || Array.isArray(ext)) {
      journalErrors.push('extension must exist and be an object');
    } else {
      if (typeof ext.entry_text !== 'string' || ext.entry_text.trim().length === 0) {
        journalErrors.push('extension.entry_text must be a non-empty string');
      }
      const allowedKeys = ['entry_text'];
      const extraKeys = Object.keys(ext).filter(k => !allowedKeys.includes(k));
      if (extraKeys.length > 0) {
        journalErrors.push('unknown extension keys: ' + extraKeys.join(', '));
      }
    }

    if (journalErrors.length > 0) {
      return [{
        json: {
          ok: false,
          _gw_route: 'error',
          gw_action: req.gw_action ?? null,
          gw_workspace_id: req.gw_workspace_id ?? null,
          artifact_type: artifact_type ?? null,
          artifact_id: req.artifact_id ?? null,
          is_update,
          error: {
            code: 'JOURNAL_EXTENSION_INVALID',
            message: 'Journal artifacts require extension.entry_text (non-empty string). No other extension fields are permitted.',
            details: {
              validation_errors: journalErrors,
              artifact_type: 'journal',
              operation: 'INSERT',
            },
          },
        },
      }];
    }
  }
} else if (artifact_type === 'person') {
  if (!is_update) {
    if (!isNonEmptyString(req.extension?.full_name)) {
      errors.push({ field: 'extension.full_name', reason: 'required for person INSERT (non-empty string)' });
    }
    if (!isNonEmptyString(req.extension?.preferred_name)) {
      errors.push({ field: 'extension.preferred_name', reason: 'required for person INSERT (non-empty string)' });
    }
    if (!isNonEmptyString(req.extension?.relationship_type)) {
      errors.push({ field: 'extension.relationship_type', reason: 'required for person INSERT' });
    }

    const arrayFields = ['key_facts', 'what_they_care_about', 'preferences'];
    for (const f of arrayFields) {
      const val = req.extension?.[f];
      if (val !== undefined && val !== null && !Array.isArray(val)) {
        errors.push({ field: `extension.${f}`, reason: `must be array if provided` });
      }
    }

    const hasContact =
      isNonEmptyString(req.extension?.personal_email) ||
      isNonEmptyString(req.extension?.work_email) ||
      isNonEmptyString(req.extension?.mobile_phone) ||
      isNonEmptyString(req.extension?.work_phone) ||
      isNonEmptyString(req.extension?.home_phone);

    if (!hasContact) {
      req._person_warnings = [
        "Person has no contact information; follow-up tracking may be limited"
      ];
    }
  }
}

// =========================================================
// Sapling B: Gateway Strict Mode (Branches 1, 2, 7, 8)
// =========================================================

// Branch 7: Parent requirement for child types
const CHILD_TYPES = ['branch', 'leaf', 'limb', 'twig'];
if (!is_update && CHILD_TYPES.includes(artifact_type)) {
  if (!isNonEmptyString(req.parent_artifact_id)) {
    errors.push({
      field: 'parent_artifact_id',
      reason: `required for ${artifact_type} INSERT (child types must have a parent)`,
    });
  }
}

// Branch 8: Twig content completeness
if (artifact_type === 'twig' && !is_update) {
  const twigContent = req.content;
  const TWIG_REQUIRED_KEYS = ['idea', 'why_now', 'problem_touched', 'future_hook'];
  if (!twigContent || typeof twigContent !== 'object' || Array.isArray(twigContent)) {
    errors.push({
      field: 'content',
      reason: 'required for twig INSERT (must be object with intent bundle)',
      required_keys: TWIG_REQUIRED_KEYS,
    });
  } else {
    const missingKeys = TWIG_REQUIRED_KEYS.filter(k => {
      const v = twigContent[k];
      return typeof v !== 'string' || v.trim().length === 0;
    });
    if (missingKeys.length > 0) {
      errors.push({
        field: 'content',
        reason: 'twig content must include all intent bundle fields (non-empty strings)',
        missing_keys: missingKeys,
        required_keys: TWIG_REQUIRED_KEYS,
      });
    }
  }
}

// Branch 1: Extension key allowlist (INSERT only, journal handled above)
if (!is_update && artifact_type !== 'journal') {
  const EXTENSION_ALLOWLISTS = {
    project: ['lifecycle_stage', 'operational_state', 'state_reason', 'design_spine'],
    snapshot: ['payload'],
    restart: ['payload'],
    instruction_pack: ['scope', 'active', 'priority', 'pack_format', 'payload'],
    person: [
      'full_name', 'preferred_name', 'relationship_type', 'status', 'pronouns',
      'personal_email', 'work_email', 'mobile_phone', 'work_phone', 'home_phone',
      'preferred_contact_method', 'preferred_contact_channel', 'timezone',
      'company', 'title', 'department', 'importance_level',
      'interaction_frequency', 'last_contacted_at', 'next_follow_up_at', 'do_not_contact',
      'address', 'communication_style', 'what_they_care_about', 'key_facts', 'preferences'
    ],
    branch: [],
    leaf: [],
    limb: [],
    twig: [],
  };

  const allowedKeys = EXTENSION_ALLOWLISTS[artifact_type];
  if (allowedKeys !== undefined) {
    const ext = req.extension;
    if (ext && typeof ext === 'object' && !Array.isArray(ext)) {
      const providedKeys = Object.keys(ext);
      const unknownKeys = providedKeys.filter(k => !allowedKeys.includes(k));
      if (unknownKeys.length > 0) {
        errors.push({
          field: 'extension',
          reason: 'unknown extension keys for ' + artifact_type,
          artifact_type: artifact_type,
          allowed_keys: allowedKeys.length > 0 ? allowedKeys : '(none -- spine-only type)',
          rejected_keys: unknownKeys,
        });
      }
    }
  }
}

// Branch 2: Unknown top-level fields (detected by Normalize_Request)
if (req._unknown_top_level_fields && req._unknown_top_level_fields.length > 0) {
  errors.push({
    field: '_top_level',
    reason: 'unknown top-level fields in payload',
    rejected_fields: req._unknown_top_level_fields,
  });
}

// =========================================================
// semantic_type_id validation
// =========================================================
const TOP_LEVEL_TYPES = ['project', 'snapshot', 'journal', 'restart', 'person'];

if (!is_update) {
  if (TOP_LEVEL_TYPES.includes(artifact_type)) {
    if (!isNonEmptyString(req.semantic_type_id)) {
      errors.push({
        field: 'semantic_type_id',
        reason: 'required for top-level artifact types (project, snapshot, journal, restart, person)'
      });
    }
  } else {
    if (req.semantic_type_id !== null && req.semantic_type_id !== undefined) {
      errors.push({
        field: 'semantic_type_id',
        reason: 'not allowed for non-top-level artifact types'
      });
    }
  }
}

// =========================================================
// Final error handling
// =========================================================
if (errors.length > 0) {
  return [
    {
      json: {
        ok: false,
        _gw_route: 'error',
        gw_action: req.gw_action ?? null,
        gw_workspace_id: req.gw_workspace_id ?? null,
        artifact_type: artifact_type ?? null,
        artifact_id: req.artifact_id ?? null,
        is_update,
        error: {
          code: 'VALIDATION_ERROR',
          message: `Validation failed for artifact.save operation (${is_update ? 'UPDATE' : 'INSERT'})`,
          details: {
            validation_errors: errors,
            artifact_type: artifact_type ?? null,
            operation: is_update ? 'UPDATE' : 'INSERT',
          },
        },
      },
    },
  ];
}

// Valid
return [
  {
    json: {
      ok: true,
      _gw_route: 'ok',
      ...req,
    },
  },
];
'''


# ============================================================================
# PATCH 2: Normalize_Request -- Branch 2 (unknown top-level field detection)
# Add after req resolution, before field extraction
# ============================================================================

# We need to inject the unknown field detection into the existing Normalize_Request.
# Strategy: find the "Field Fallback Resolution" comment and insert detection before it.

UNKNOWN_FIELD_DETECTION = r'''
// -------------------------
// Branch 2: Detect unknown top-level fields (Sapling B)
// -------------------------
const SAVE_KNOWN_FIELDS = new Set([
  // Canonical fields
  'gw_action', 'gw_workspace_id', 'artifact_type', 'artifact_id',
  'title', 'summary', 'priority', 'tags', 'content', 'extension',
  'parent_artifact_id', 'semantic_type_id', 'owner_user_id',
  'execution_status', 'lifecycle_status',
  // Dual-shape aliases (backward compat)
  'workspace_id', 'actor_user_id',
  'req_artifact_type', 'req_title', 'req_parent_artifact_id',
  'req_gw_workspace_id', 'req_artifact_id', 'req_extension',
]);
const _unknown_top_level_fields = Object.keys(req)
  .filter(k => !SAVE_KNOWN_FIELDS.has(k) && !k.startsWith('_'));
'''

# This goes into the canonical output object
UNKNOWN_FIELD_CANONICAL_LINE = '  _unknown_top_level_fields: _unknown_top_level_fields,'


# ============================================================================
# PATCH 3: Prepare_Insert_Payload -- Branches 5, 6
# ============================================================================

PREPARE_INSERT_PAYLOAD_NEW = r'''// NQxb_Artifact_Save_v1__Prepare_Insert_Payload
// v2.0: Sapling B -- Gateway Strict Mode
//   Branch 5: Snapshot for-q auto-injection (semantic-gated)
//   Branch 6: Execution status auto-default for execution-layer types
//
// Build clean JSON body for PostgREST INSERT into qxb_artifact.

const req = $json;

// Branch 6: Auto-default execution_status for execution-layer types
const EXECUTION_TYPES = ['branch', 'limb', 'leaf', 'twig'];
let execution_status = req.execution_status;
if (EXECUTION_TYPES.includes(req.artifact_type) && !execution_status) {
  execution_status = 'not_started';
}

// Branch 5: Snapshot for-q auto-injection (semantic-gated)
// Qualifying semantic types: governance, execution-core, infrastructure, platform
// Check original input key (before resolver converted to UUID)
let tags = req.tags ?? [];
if (req.artifact_type === 'snapshot') {
  const originalKey = $node["NQxb_Artifact_Save_v1__Normalize_Request"]?.json?.semantic_type_id ?? null;
  const QUALIFYING_SEMANTIC_KEYS = ['governance', 'execution-core', 'infrastructure', 'platform'];
  if (typeof originalKey === 'string' && QUALIFYING_SEMANTIC_KEYS.includes(originalKey.toLowerCase())) {
    if (!Array.isArray(tags)) tags = [];
    if (!tags.includes('for-q')) {
      tags = [...tags, 'for-q'];
    }
  }
}

const payload = {
  workspace_id: req.gw_workspace_id,
  owner_user_id: req.owner_user_id,
  artifact_type: req.artifact_type,
  title: req.title,
  summary: req.summary,
  priority: req.priority,
  tags: tags,
  content: req.content,
  parent_artifact_id: req.parent_artifact_id,
  lifecycle_status: req.lifecycle_status,
  execution_status: execution_status
};

// Only include semantic_type_id when resolved to a valid UUID.
if (req.semantic_type_id != null && req.semantic_type_id !== '') {
  payload.semantic_type_id = req.semantic_type_id;
}

return [{ json: payload }];
'''


# ============================================================================
# EXECUTION
# ============================================================================

def find_node(workflow, name):
    for i, node in enumerate(workflow['nodes']):
        if node.get('name') == name:
            return i, node
    return None, None


def patch_code_node(workflow, node_name, new_code):
    idx, node = find_node(workflow, node_name)
    if idx is None:
        raise ValueError(f"Node not found: {node_name}")
    old_code = node['parameters'].get('jsCode', '')
    node['parameters']['jsCode'] = new_code
    print(f"  PATCHED: {node_name}")
    print(f"    Old: {len(old_code)} chars -> New: {len(new_code)} chars")


def inject_into_normalize_request(workflow):
    """Inject unknown field detection into Normalize_Request."""
    idx, node = find_node(workflow, 'NQxb_Artifact_Save_v1__Normalize_Request')
    if idx is None:
        raise ValueError("Normalize_Request not found")

    code = node['parameters']['jsCode']

    # Insert detection code before "Field Fallback Resolution"
    marker = '// Field Fallback Resolution'
    if marker not in code:
        # Try alternate marker
        marker = '// -------------------------\n// Field Fallback Resolution'
    if marker not in code:
        raise ValueError(f"Could not find marker '{marker}' in Normalize_Request")

    code = code.replace(marker, UNKNOWN_FIELD_DETECTION + '\n' + marker)

    # Add _unknown_top_level_fields to canonical output
    canonical_marker = '// PATCH metadata'
    if canonical_marker in code:
        code = code.replace(
            canonical_marker,
            '// Unknown field detection (Branch 2)\n'
            + UNKNOWN_FIELD_CANONICAL_LINE + '\n\n'
            + '  ' + canonical_marker
        )

    node['parameters']['jsCode'] = code
    print(f"  PATCHED: Normalize_Request (Branch 2 unknown field detection)")
    print(f"    Injected field detection + canonical output")


def main():
    os.makedirs(ARCHIVE_DIR, exist_ok=True)

    with open(SAVE_INPUT, 'r', encoding='utf-8') as f:
        save_wf = json.load(f)

    # Patch 1: Validate_Request (Branches 1, 3, 7, 8)
    patch_code_node(save_wf, 'NQxb_Artifact_Save_v1__Validate_Request', VALIDATE_REQUEST_NEW)

    # Patch 2: Normalize_Request (Branch 2)
    inject_into_normalize_request(save_wf)

    # Patch 3: Prepare_Insert_Payload (Branches 5, 6)
    patch_code_node(save_wf, 'NQxb_Artifact_Save_v1__Prepare_Insert_Payload', PREPARE_INSERT_PAYLOAD_NEW)

    # Archive and write
    shutil.copy2(SAVE_INPUT, SAVE_ARCHIVE)
    print(f"  ARCHIVED: {SAVE_ARCHIVE}")

    with open(SAVE_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(save_wf, f, indent=2)
    print(f"  OUTPUT: {SAVE_OUTPUT}")

    print()
    print("SUMMARY")
    print("=" * 50)
    print("  Save: v49 -> v50 (Sapling B)")
    print()
    print("  Branch 1: Extension key allowlist per type (Validate_Request)")
    print("  Branch 2: Unknown top-level field detection (Normalize_Request + Validate_Request)")
    print("  Branch 3: Empty required object rejection (Validate_Request)")
    print("  Branch 4: SKIPPED (already implemented in Update)")
    print("  Branch 5: Snapshot for-q auto-injection (Prepare_Insert_Payload)")
    print("  Branch 6: Execution status auto-default (Prepare_Insert_Payload)")
    print("  Branch 7: Parent requirement for child types (Validate_Request)")
    print("  Branch 8: Twig content completeness (Validate_Request)")
    print()
    print("  STOP: Review output before deployment.")


if __name__ == '__main__':
    main()
