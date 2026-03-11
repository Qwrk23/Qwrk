// NQxb_Artifact_Update_v1__Check_Mutability_Rules
// Enforce Mutability Registry v2 rules
// v3: T64
// v4: T71 — dependency check flagging for leaf completing — spine-field update mode for branch/limb/leaf
// v5: T69 architectural fix — semantic_type routing extracted to Detect_Semantic_Route pre-routing layer
// v6: T77 — mixed update guard (tags + extension = MIXED_UPDATE_NOT_ALLOWED)
//
// Order of checks:
// 1. Existence check (NOT_FOUND)
// 2. Tags-only bypass (all types)
// 2.5. Mixed update guard (tags + extension = reject)          ← NEW
// 3. Immutability check (snapshot, restart, instruction_pack)
// 4. Journal block (UNDECIDED_BLOCKED)
// 5. deleted_at block (UNDECIDED_BLOCKED)
// 6. Project extension field validation
// 6.5. Project operational_state value validation (DDL CHECK)
// 6.7. Branch/Limb/Leaf spine-field validation (T64)
// 7. Generic extension fallthrough

const existing = $json;
const normalizeNode = $node['NQxb_Artifact_Update_v1__Normalize_Request'].json;

// 1. Check if artifact was found
if (!existing || !existing.artifact_id) {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "NOT_FOUND",
          message: "Artifact not found for UPDATE operation",
          details: {
            artifact_id: normalizeNode.artifact_id,
            workspace_id: normalizeNode.gw_workspace_id,
            operation: "UPDATE",
          },
        },
      },
    },
  ];
}

const artifact_type = existing.artifact_type?.trim();

// 2. Tags-only bypass (Mutability Registry v2)
// Tags are spine-level organizational metadata — type-agnostic.
// If ONLY tags are requested (no extension fields), bypass all type-specific blocks.
const normalizedTags = normalizeNode.tags ?? null;
const extensionKeys = Object.keys(normalizeNode.extension || {});
const isTagsOnly = normalizedTags !== null && extensionKeys.length === 0;

if (isTagsOnly) {
  return [
    {
      json: {
        ok: true,
        _gw_route: "ok",
        _update_mode: "tags_only",
        gw_action: normalizeNode.gw_action ?? "artifact.update",
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_id: existing.artifact_id,
        workspace_id: existing.workspace_id,
        artifact_type: artifact_type,
        _normalized_request: normalizeNode,
        _existing_artifact: existing,
        _gw_debug: {
          ...(normalizeNode._gw_debug ?? {}),
          mutability: "tags_only_bypass",
          operation: "UPDATE",
        },
      },
    },
  ];
}

// === NEW: 2.5 Mixed update guard (T77) ===
// Tags and extension fields cannot be combined in one update call.
// Prevents silent data loss where one side is applied and the other dropped.
// Note: semantic_type_id + tags mixing is caught earlier by Detect_Semantic_Route.
// This guard covers the general case: tags + any extension fields.
const hasMixedUpdate = normalizedTags !== null && extensionKeys.length > 0;

if (hasMixedUpdate) {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "MIXED_UPDATE_NOT_ALLOWED",
          message: "Cannot combine tags and extension fields in one update call. Submit separately.",
          details: {
            artifact_type: artifact_type ?? normalizeNode.artifact_type,
            artifact_id: existing.artifact_id,
            tags_present: true,
            extension_keys: extensionKeys,
            source: "Mutability Registry v2",
            hint: "Submit tag updates and extension updates as separate artifact.update calls.",
          },
        },
      },
    },
  ];
}
// === END NEW ===

// 3. RULE: snapshot and restart are fully immutable (Mutability Registry v1)
if (artifact_type === "snapshot" || artifact_type === "restart" || artifact_type === "instruction_pack") {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "IMMUTABILITY_ERROR",
          message: `Artifact type '${artifact_type}' is immutable and cannot be updated. Only INSERT operations are allowed.`,
          details: {
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            operation_attempted: "UPDATE",
            registry_rule: "CREATE_ONLY",
            source: "Mutability Registry v2",
            hint: "Extension fields on immutable types cannot be updated. Tags-only updates are allowed via tags.add/tags.remove.",
          },
        },
      },
    },
  ];
}

// 4. RULE: journal mutability is UNDECIDED_BLOCKED (Mutability Registry v2)
// DOCTRINE: Journal INSERT-ONLY (Temporary)
if (artifact_type === "journal") {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "JOURNAL_MUTABILITY_UNDECIDED",
          message:
            "Journal update policy is not locked. Use artifact.create to append new entries.",
          details: {
            artifact_type: "journal",
            artifact_id: existing.artifact_id,
            operation_attempted: "UPDATE",
            registry_rule: "UNDECIDED_BLOCKED",
            source: "Mutability Registry v2",
            doctrine: "Journal INSERT-ONLY (Temporary)",
            hint: "Journal extension fields are blocked until mutability policy is locked. Tags-only updates are allowed via tags.add/tags.remove.",
          },
        },
      },
    },
  ];
}

// 5. RULE: deleted_at is UNDECIDED_BLOCKED (Mutability Registry v1)
if (normalizeNode.deleted_at !== null && normalizeNode.deleted_at !== undefined) {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "MUTABILITY_ERROR",
          message: "Field 'deleted_at' is UNDECIDED_BLOCKED and cannot be updated.",
          details: {
            field: "deleted_at",
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            registry_rule: "UNDECIDED_BLOCKED",
            source: "Mutability Registry v1",
            hint: "Soft delete semantics not yet locked. Use dedicated artifact.delete action when implemented.",
          },
        },
      },
    },
  ];
}

// 6. RULE: For project artifacts, only operational_state and state_reason allowed
if (artifact_type === "project") {
  const extension = normalizeNode.extension || {};
  const allowedFields = ["summary", "operational_state", "state_reason"];
  const providedFields = Object.keys(extension);

  const disallowedFields = providedFields.filter((f) => !allowedFields.includes(f));

  if (disallowedFields.length > 0) {
    if (disallowedFields.includes("lifecycle_stage")) {
      return [
        {
          json: {
            ok: false,
            _gw_route: "error",
            error: {
              code: "MUTABILITY_ERROR",
              message:
                "Field 'lifecycle_stage' is PROMOTE_ONLY and cannot be updated via artifact.update.",
              details: {
                field: "extension.lifecycle_stage",
                artifact_type: "project",
                artifact_id: existing.artifact_id,
                registry_rule: "PROMOTE_ONLY",
                source: "Mutability Registry v1",
                hint: "Use artifact.promote operation to change lifecycle_stage.",
              },
            },
          },
        },
      ];
    }

    return [
      {
        json: {
          ok: false,
          _gw_route: "error",
          error: {
            code: "MUTABILITY_ERROR",
            message: `Disallowed fields in extension for project UPDATE: ${disallowedFields.join(
              ", "
            )}`,
            details: {
              disallowed_fields: disallowedFields,
              allowed_fields: allowedFields,
              artifact_type: "project",
              artifact_id: existing.artifact_id,
              source: "Mutability Registry v1",
              hint: "Only summary, operational_state, and state_reason are UPDATE_ALLOWED for project artifacts.",
            },
          },
        },
      },
    ];
  }

  if (providedFields.length === 0) {
    return [
      {
        json: {
          ok: false,
          _gw_route: "error",
          error: {
            code: "VALIDATION_ERROR",
            message: "No updateable fields provided in extension for project UPDATE.",
            details: {
              artifact_type: "project",
              artifact_id: existing.artifact_id,
              allowed_fields: allowedFields,
              hint: "Provide at least one of: summary, operational_state, state_reason",
            },
          },
        },
      },
    ];
  }

  // 6.5: Value validation for operational_state (DDL CHECK constraint)
  // Allowed: active, paused, blocked, waiting
  // Source: qxb_artifact_project_operational_state_check
  if ('operational_state' in extension) {
    const allowedStates = ['active', 'paused', 'blocked', 'waiting'];
    if (!allowedStates.includes(extension.operational_state)) {
      return [
        {
          json: {
            ok: false,
            _gw_route: "error",
            error: {
              code: "VALIDATION_ERROR",
              message: `Invalid operational_state value: '${extension.operational_state}'`,
              details: {
                field: "operational_state",
                provided_value: extension.operational_state,
                allowed_values: allowedStates,
                artifact_type: "project",
                artifact_id: existing.artifact_id,
                source: "DDL CHECK: qxb_artifact_project_operational_state_check",
              },
            },
          },
        },
      ];
    }
  }
}

// 6.7 RULE: branch/limb/leaf — spine-field update only (T64)
// execution_status is a SPINE field on qxb_artifact (DDL v2.4).
// Route to spine PATCH instead of extension table write.
const executionAnatomyTypes = ['branch', 'limb', 'leaf'];
if (executionAnatomyTypes.includes(artifact_type)) {
  const extension = normalizeNode.extension || {};
  const allowedSpineFields = ['execution_status'];
  const providedFields = Object.keys(extension);

  // 6.7.2 Allowlist check: reject unknown fields
  const disallowedFields = providedFields.filter(f => !allowedSpineFields.includes(f));
  if (disallowedFields.length > 0) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Disallowed fields in extension for ' + artifact_type + ' UPDATE: ' + disallowedFields.join(', '),
          details: {
            disallowed_fields: disallowedFields,
            allowed_fields: allowedSpineFields,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            source: 'T64',
            hint: 'Only execution_status is UPDATE_ALLOWED for ' + artifact_type + ' artifacts. Use tags.add/tags.remove for tag updates.'
          }
        }
      }
    }];
  }

  // 6.7.3 Must provide at least one field
  if (providedFields.length === 0) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: 'No updateable fields provided in extension for ' + artifact_type + ' UPDATE.',
          details: {
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            allowed_fields: allowedSpineFields,
            hint: 'Provide execution_status in extension object.'
          }
        }
      }
    }];
  }

  // 6.7.4 Validate execution_status value against CHECK constraint
  const execStatus = extension.execution_status;
  const validStatuses = ['not_started', 'in_progress', 'blocked', 'complete'];
  if (execStatus !== null && execStatus !== undefined && !validStatuses.includes(execStatus)) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: "Invalid execution_status value: '" + execStatus + "'",
          details: {
            field: 'execution_status',
            provided_value: execStatus,
            allowed_values: validStatuses,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            hint: 'execution_status must be one of: not_started, in_progress, blocked, complete'
          }
        }
      }
    }];
  }

  // 6.7.5 Archive guard: lifecycle_status = 'archive' rejects all mutations
  if (existing.lifecycle_status === 'archive') {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'ARCHIVE_TERMINAL',
          message: 'Cannot mutate execution_status on archived artifact',
          details: {
            artifact_id: existing.artifact_id,
            artifact_type: artifact_type,
            lifecycle_status: 'archive',
            hint: 'Archived artifacts are read-only. No mutations are permitted.'
          }
        }
      }
    }];
  }

  // 6.7.6 No-op detection: same state → no write
  const currentStatus = existing.execution_status ?? null;
  const requestedStatus = execStatus ?? null;
  if (currentStatus === requestedStatus) {
    return [{
      json: {
        ok: true,
        _gw_route: 'ok',
        _update_mode: 'noop',
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_id: existing.artifact_id,
        workspace_id: existing.workspace_id,
        artifact_type: artifact_type,
        execution_status: currentStatus,
        version: existing.version,
      }
    }];
  }

  // 6.7.7 NULL reset prohibition: cannot set back to NULL once initialized
  if (currentStatus !== null && requestedStatus === null) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'INVALID_TRANSITION',
          message: 'Cannot reset execution_status to NULL once initialized',
          details: {
            field: 'execution_status',
            from_status: currentStatus,
            to_status: null,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            reason: 'null_reset_prohibited',
            hint: 'execution_status cannot be set back to NULL. Once initialized, only forward transitions are allowed.'
          }
        }
      }
    }];
  }

  // 6.7.8 Transition matrix enforcement
  const allowedTransitions = {
    'null': ['not_started'],
    'not_started': ['in_progress', 'blocked'],
    'in_progress': ['blocked', 'complete'],
    'blocked': ['in_progress'],
    'complete': []
  };

  const fromKey = currentStatus === null ? 'null' : currentStatus;
  const allowed = allowedTransitions[fromKey] || [];

  if (!allowed.includes(requestedStatus)) {
    // Determine reason for better error messaging
    let reason = 'invalid_transition';
    if (currentStatus === 'complete') {
      reason = 'complete_is_terminal';
    } else if (
      (currentStatus === 'in_progress' && requestedStatus === 'not_started') ||
      (currentStatus === 'blocked' && requestedStatus === 'not_started')
    ) {
      reason = 'backward_transition';
    } else if (
      (currentStatus === null && requestedStatus !== 'not_started') ||
      (currentStatus === 'not_started' && requestedStatus === 'complete') ||
      (currentStatus === 'blocked' && requestedStatus === 'complete')
    ) {
      reason = 'skip_transition';
    }

    const allowedMsg = allowed.length > 0 ? allowed.join(', ') : '(none — terminal state)';
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'INVALID_TRANSITION',
          message: "execution_status transition not allowed: '" + (currentStatus ?? 'NULL') + "' \u2192 '" + requestedStatus + "'",
          details: {
            field: 'execution_status',
            from_status: currentStatus,
            to_status: requestedStatus,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            reason: reason,
            allowed_from_current: allowed,
            hint: "Allowed from '" + (currentStatus ?? 'NULL') + "': " + allowedMsg + "."
          }
        }
      }
    }];
  }

  // 6.7.9 Parent check flagging
  const needsParentCheck = (requestedStatus === 'complete') &&
                           (artifact_type === 'branch' || artifact_type === 'limb');

  // 6.7.9a Dependency check flagging (T71)
  const needsDependencyCheck = (requestedStatus === 'complete') && (artifact_type === 'leaf');

  // 6.7.10 Route to spine-field update
  return [{
    json: {
      ok: true,
      _gw_route: 'ok',
      _update_mode: 'spine_fields',
      gw_action: normalizeNode.gw_action ?? 'artifact.update',
      gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
      artifact_id: existing.artifact_id,
      workspace_id: existing.workspace_id,
      artifact_type: artifact_type,
      _normalized_request: normalizeNode,
      _existing_artifact: existing,
      _spine_update: {
        execution_status: requestedStatus,
      },
      _needs_parent_check: needsParentCheck,
      _needs_dependency_check: needsDependencyCheck,
      _gw_debug: {
        ...(normalizeNode._gw_debug ?? {}),
        mutability: 'spine_fields_allowed',
        operation: 'UPDATE',
        transition: (currentStatus ?? 'NULL') + ' \u2192 ' + requestedStatus,
        needs_parent_check: needsParentCheck,
        needs_dependency_check: needsDependencyCheck,
      }
    }
  }];
}

// 7. Mutability checks passed — extension update path
return [
  {
    json: {
      ok: true,
      _gw_route: "ok",
      _update_mode: "extension",
      gw_action: normalizeNode.gw_action ?? "artifact.update",
      gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
      artifact_id: existing.artifact_id,
      workspace_id: existing.workspace_id,
      artifact_type: existing.artifact_type,
      _normalized_request: normalizeNode,
      _existing_artifact: existing,
      _gw_debug: {
        ...(normalizeNode._gw_debug ?? {}),
        mutability: "passed",
        operation: "UPDATE",
      },
    },
  },
];
