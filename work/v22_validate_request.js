// NQxb_Artifact_Save_v1__Validate_Request
// Comprehensive validation with consistent envelope + explicit ok flag for routing
// v2.0: Removed hardcoded validTypes array - now uses Type Registry Guard
// v2.1: Added instruction_pack INSERT validation (scope/active/priority/pack_format)
// v2.2: Added journal strict extension contract (entry_text only, no other keys)

const req = $json;
const errors = [];

// Helpers
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

// NOTE: artifact_type allow-list validation REMOVED
// Type Registry Guard now handles this check downstream

// Operation-specific requirements
if (is_update) {
  // UPDATE requirements
  if (!isNonEmptyString(req.artifact_id)) {
    errors.push({ field: 'artifact_id', reason: 'required for UPDATE operation' });
  }

  // If title is provided for UPDATE, it must be non-empty
  if (req._provided_fields?.title && !isNonEmptyString(req.title)) {
    errors.push({ field: 'title', reason: 'if provided for UPDATE, must be non-empty' });
  }
} else {
  // INSERT requirements
  if (!isNonEmptyString(req.owner_user_id)) {
    errors.push({ field: 'owner_user_id', reason: 'required for INSERT operation' });
  }

  if (!isNonEmptyString(req.title)) {
    errors.push({ field: 'title', reason: 'required for INSERT operation' });
  }
}

// Type-specific validation
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
  }
} else if (artifact_type === 'instruction_pack') {
  if (!is_update) {
    // Required extension metadata for instruction_pack INSERT (matches qxb_artifact_instruction_pack schema)
    if (!isNonEmptyString(req.extension?.scope)) {
      errors.push({ field: 'extension.scope', reason: 'required for instruction_pack INSERT' });
    }

    if (typeof req.extension?.active !== 'boolean') {
      errors.push({
        field: 'extension.active',
        reason: 'required for instruction_pack INSERT (boolean)',
      });
    }

    if (typeof req.extension?.priority !== 'number') {
      errors.push({
        field: 'extension.priority',
        reason: 'required for instruction_pack INSERT (number)',
      });
    }

    if (!isNonEmptyString(req.extension?.pack_format)) {
      errors.push({
        field: 'extension.pack_format',
        reason: 'required for instruction_pack INSERT',
      });
    }
  }
} else if (artifact_type === 'journal') {
  if (!is_update) {
    // Strict journal extension contract (v2.2):
    // - extension.entry_text required (non-empty string)
    // - No other extension keys permitted
    // - payload column intentionally deprecated for journal saves
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
}

// If validation failed, return standardized error envelope
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

// Valid — return explicit ok=true + pass-through request for downstream steps
return [
  {
    json: {
      ok: true,
      _gw_route: 'ok',
      ...req,
    },
  },
];
