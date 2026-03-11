// NQxb_Artifact_Update_v1__Check_Mutability_Rules
// Enforce Mutability Registry v3 rules
// v3: T64
// v4: T71 â€” dependency check flagging for leaf completing â€” spine-field update mode for branch/limb/leaf
// v5: T69 architectural fix
// v6: T87 -- Spine field routing (title, summary, priority) + mixed update support
// v7: T87 Task 3 -- Lifecycle-scoped mutability governance
// v8: T87 Task 4 -- design_spine added to project extension allowlist
// v9: T94 -- twig added to execution anatomy types (no extension table, lifecycle via spine)
//   - archive: ALL mutations blocked (spine, extension, tags)
//   - tree: title frozen (summary, priority, extension, tags remain mutable)
//   - seed/sapling: fully mutable
//
// Order of checks:
// 1. Existence check (NOT_FOUND)
// 2. Lifecycle-scoped archive guard (blocks everything)
// 3. Routing classification (T87)
//    Three dimensions: hasTags, hasSpineFields, hasExtension
// 4. Lifecycle-scoped tree guard (title frozen -- checked in spine/mixed paths)
// 5. Type-specific rules

const existing = $json;
const artifact_type = existing.artifact_type;
const lifecycle_status = existing.lifecycle_status ?? null;

// Pull the normalized request from the Normalize_Request node output.
function getNormalizeNode() {
  const candidateNodeNames = [
    "NQxb_Artifact_Update_v1__Normalize_Request",
    "Normalize_Request",
    "NQxb_Artifact_Update_v1__Normalize_Request_v3",
  ];

  for (const name of candidateNodeNames) {
    try {
      const items = $items(name, 0);
      if (items && items.length > 0 && items[0]?.json) return items[0].json;
    } catch (e) {
      // ignore and try next name
    }
  }

  if (existing._normalized_request) return existing._normalized_request;
  if (existing.normalizeNode) return existing.normalizeNode;

  return {};
}

const normalizeNode = getNormalizeNode();

const normalizedTags = normalizeNode.tags ?? null;
const extensionKeys = Object.keys(normalizeNode.extension || {});
// T87: Spine field detection â€” check both normalizeNode.spine_fields AND $json top-level
// Belt-and-suspenders: works regardless of which upstream node provides the data
const spineFieldsObj = normalizeNode.spine_fields || {};
const spineFieldKeys = Object.keys(spineFieldsObj);

const hasSpineFields = spineFieldKeys.length > 0;

const hasTags = normalizedTags !== null;
const hasExtension = extensionKeys.length > 0;

// ============================================================================
// 1.5 LIFECYCLE GUARD: archive = ALL mutations blocked
// Applies to projects only (execution anatomy has its own archive guard at 6.7.5)
// ============================================================================
if (artifact_type === "project" && lifecycle_status === "archive") {
  const attemptedFields = [];
  if (hasSpineFields) attemptedFields.push(...spineFieldKeys.map(k => `spine.${k}`));
  if (hasExtension) attemptedFields.push(...extensionKeys.map(k => `extension.${k}`));
  if (hasTags) attemptedFields.push("tags");

  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "ARCHIVE_IMMUTABLE",
          message: "Archived projects are fully immutable. No mutations are permitted.",
          details: {
            artifact_id: existing.artifact_id,
            artifact_type: "project",
            lifecycle_status: "archive",
            attempted_fields: attemptedFields,
            hint: "Archived artifacts are read-only historical records. No spine, extension, or tag updates are allowed.",
          },
        },
      },
    },
  ];
}


// 2d. Extension + (tags OR spine fields) = MIXED_UPDATE_NOT_ALLOWED
if (hasExtension && (hasTags || hasSpineFields)) {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "MIXED_UPDATE_NOT_ALLOWED",
          message: "Cannot combine extension fields with tags or spine fields in a single update. Send extension updates separately.",
          details: {
            artifact_id: existing.artifact_id,
            artifact_type: artifact_type,
            has_extension: true,
            has_tags: hasTags,
            has_spine_fields: hasSpineFields,
            spine_field_keys: spineFieldKeys,
            hint: "Split into two requests: (1) extension-only update, (2) tags/spine update.",
          },
        },
      },
    },
  ];
}

// ============================================================================
// LIFECYCLE GUARD HELPER: tree = title frozen
// Used by spine_only and mixed paths below
// ============================================================================
function checkTreeTitleFreeze() {
  if (artifact_type === "project" && lifecycle_status === "tree" && spineFieldKeys.includes("title")) {
    return {
      ok: false,
      _gw_route: "error",
      error: {
        code: "FIELD_FROZEN",
        message: "Field 'title' is frozen at lifecycle stage 'tree'. Title cannot be changed once a project reaches tree.",
        details: {
          artifact_id: existing.artifact_id,
          artifact_type: "project",
          lifecycle_status: "tree",
          frozen_field: "title",
          allowed_spine_fields: spineFieldKeys.filter(k => k !== "title"),
          hint: "At tree stage, title is locked as the project's permanent identity. Summary and priority remain mutable.",
        },
      },
    };
  }
  return null;
}

// 2a. Tags only
if (hasTags && !hasSpineFields && !hasExtension) {
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

// 2a.5 GUARD: lifecycle_status via spine_fields is TWIG-ONLY
// Projects use artifact.promote -- direct lifecycle_status update is blocked.
if (hasSpineFields && spineFieldKeys.includes('lifecycle_status') && artifact_type !== 'twig') {
  return [
    {
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'MUTABILITY_ERROR',
          message: "Field 'lifecycle_status' cannot be updated via artifact.update for type '" + artifact_type + "'. Use artifact.promote for lifecycle transitions.",
          details: {
            field: 'lifecycle_status',
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            registry_rule: 'PROMOTE_ONLY',
            hint: 'lifecycle_status updates via spine fields are only allowed for twig artifacts. Projects must use artifact.promote.',
          },
        },
      },
    },
  ];
}

// 2a.6 GUARD: twig lifecycle transition validation
if (hasSpineFields && spineFieldKeys.includes('lifecycle_status') && artifact_type === 'twig') {
  const currentLifecycle = existing.lifecycle_status ?? null;
  const requestedLifecycle = spineFieldsObj.lifecycle_status ?? null;

  // Terminal states: promoted and pruned cannot be changed
  if (currentLifecycle === 'promoted' || currentLifecycle === 'pruned') {
    return [
      {
        json: {
          ok: false,
          _gw_route: 'error',
          error: {
            code: 'ARCHIVE_TERMINAL',
            message: 'Cannot update lifecycle_status on ' + currentLifecycle + ' twig. Terminal state.',
            details: {
              artifact_id: existing.artifact_id,
              artifact_type: 'twig',
              lifecycle_status: currentLifecycle,
              hint: 'Twigs in promoted or pruned state are terminal. Archive the twig and create a new artifact if needed.',
            },
          },
        },
      },
    ];
  }

  // Transition matrix: proposed -> active -> promoted | pruned
  const twigTransitions = {
    'null': ['proposed'],
    'proposed': ['active', 'pruned'],
    'active': ['promoted', 'pruned'],
  };

  const fromKey = currentLifecycle === null ? 'null' : currentLifecycle;
  const allowed = twigTransitions[fromKey] || [];

  if (requestedLifecycle !== null && !allowed.includes(requestedLifecycle)) {
    return [
      {
        json: {
          ok: false,
          _gw_route: 'error',
          error: {
            code: 'INVALID_TRANSITION',
            message: "lifecycle_status transition not allowed: '" + (currentLifecycle ?? 'NULL') + "' \u2192 '" + requestedLifecycle + "'",
            details: {
              field: 'lifecycle_status',
              from_status: currentLifecycle,
              to_status: requestedLifecycle,
              artifact_type: 'twig',
              artifact_id: existing.artifact_id,
              allowed_from_current: allowed,
              hint: "Allowed from '" + (currentLifecycle ?? 'NULL') + "': " + (allowed.length > 0 ? allowed.join(', ') : '(none -- terminal state)') + '.',
            },
          },
        },
      },
    ];
  }

  // No-op detection
  if (currentLifecycle === requestedLifecycle) {
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
        lifecycle_status: currentLifecycle,
        version: existing.version,
      }
    }];
  }
}

// 2b. Spine only
if (hasSpineFields && !hasTags && !hasExtension) {
  // T87 Task 3: tree title freeze check
  const titleFreeze = checkTreeTitleFreeze();
  if (titleFreeze) return [{ json: titleFreeze }];

  return [
    {
      json: {
        ok: true,
        _gw_route: "ok",
        _update_mode: "spine_only",
        gw_action: normalizeNode.gw_action ?? "artifact.update",
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_id: existing.artifact_id,
        workspace_id: existing.workspace_id,
        artifact_type: artifact_type,
        _normalized_request: normalizeNode,
        _existing_artifact: existing,
        _gw_debug: {
          ...(normalizeNode._gw_debug ?? {}),
          mutability: "spine_only",
          operation: "UPDATE",
          spine_field_keys: spineFieldKeys,
        },
      },
    },
  ];
}

// 2c. Mixed -- tags + spine fields, no extension (single atomic PATCH)
if (hasTags && hasSpineFields && !hasExtension) {
  // T87 Task 3: tree title freeze check
  const titleFreeze = checkTreeTitleFreeze();
  if (titleFreeze) return [{ json: titleFreeze }];

  return [
    {
      json: {
        ok: true,
        _gw_route: "ok",
        _update_mode: "mixed",
        gw_action: normalizeNode.gw_action ?? "artifact.update",
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_id: existing.artifact_id,
        workspace_id: existing.workspace_id,
        artifact_type: artifact_type,
        _normalized_request: normalizeNode,
        _existing_artifact: existing,
        _gw_debug: {
          ...(normalizeNode._gw_debug ?? {}),
          mutability: "mixed_tags_spine",
          operation: "UPDATE",
          spine_field_keys: spineFieldKeys,
        },
      },
    },
  ];
}

// --- Below: extension-only paths ---

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
            source: "Mutability Registry v3",
            hint: "Extension fields on immutable types cannot be updated. Tags-only updates are allowed via tags.add/tags.remove.",
          },
        },
      },
    },
  ];
}

// 4. RULE: journal is INSERT-ONLY (Mutability Registry v3 -- PERMANENT)
// Decision locked: T46 / T87
if (artifact_type === "journal") {
  return [
    {
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "JOURNAL_INSERT_ONLY",
          message:
            "Journals are permanently INSERT-ONLY. Use artifact.save to append new entries.",
          details: {
            artifact_type: "journal",
            artifact_id: existing.artifact_id,
            operation_attempted: "UPDATE",
            registry_rule: "INSERT_ONLY",
            source: "Mutability Registry v3",
            doctrine: "Journal INSERT-ONLY (Permanent)",
            hint: "Journal extension fields cannot be updated. Tags and spine field updates are allowed via separate requests. Use append-to:<journal_id> tag convention for thread-append.",
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
if (artifact_type === "project" && !hasSpineFields) {
  const extension = normalizeNode.extension || {};
  const allowedFields = ["summary", "operational_state", "state_reason", "design_spine"];
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
              hint: "Only summary, operational_state, state_reason, and design_spine are UPDATE_ALLOWED for project artifacts.",
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
              hint: "Provide at least one of: summary, operational_state, state_reason, design_spine",
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

// 6.7 RULE: branch/limb/leaf â€” spine-field update only (T64)
// execution_status is a SPINE field on qxb_artifact (DDL v2.4).
// Route to spine PATCH instead of extension table write.
const executionAnatomyTypes = ['branch', 'limb', 'leaf', 'twig'];
if (executionAnatomyTypes.includes(artifact_type)) {
  const extension = normalizeNode.extension || {};
  // T94: twig also allows lifecycle_status via extension (routed to spine PATCH)
  const allowedSpineFields = artifact_type === 'twig'
    ? ['execution_status', 'lifecycle_status']
    : ['execution_status'];
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

  // 6.7.3 Must provide at least one updateable field
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

  // 6.7.4a T94: twig lifecycle_status transition validation (via extension path)
  if (artifact_type === 'twig' && extension.lifecycle_status !== undefined) {
    const currentLifecycle = existing.lifecycle_status ?? null;
    const requestedLifecycle = extension.lifecycle_status ?? null;

    // Terminal states
    if (currentLifecycle === 'promoted' || currentLifecycle === 'pruned') {
      return [{
        json: {
          ok: false,
          _gw_route: 'error',
          error: {
            code: 'ARCHIVE_TERMINAL',
            message: 'Cannot update lifecycle_status on ' + currentLifecycle + ' twig. Terminal state.',
            details: {
              artifact_id: existing.artifact_id,
              artifact_type: 'twig',
              lifecycle_status: currentLifecycle,
              hint: 'Twigs in promoted or pruned state are terminal. Archive the twig and create a new artifact if needed.',
            },
          },
        },
      }];
    }

    // Transition matrix: proposed -> active -> promoted | pruned
    const twigTransitions = {
      'null': ['proposed'],
      'proposed': ['active', 'pruned'],
      'active': ['promoted', 'pruned'],
    };
    const fromKey = currentLifecycle === null ? 'null' : currentLifecycle;
    const allowed = twigTransitions[fromKey] || [];

    if (requestedLifecycle !== null && !allowed.includes(requestedLifecycle)) {
      return [{
        json: {
          ok: false,
          _gw_route: 'error',
          error: {
            code: 'INVALID_TRANSITION',
            message: "lifecycle_status transition not allowed: '" + (currentLifecycle ?? 'NULL') + "' → '" + requestedLifecycle + "'",
            details: {
              field: 'lifecycle_status',
              from_status: currentLifecycle,
              to_status: requestedLifecycle,
              artifact_type: 'twig',
              artifact_id: existing.artifact_id,
              allowed_from_current: allowed,
              hint: "Allowed from '" + (currentLifecycle ?? 'NULL') + "': " + (allowed.length > 0 ? allowed.join(', ') : '(none -- terminal state)') + '.',
            },
          },
        },
      }];
    }

    // No-op
    if (currentLifecycle === requestedLifecycle) {
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
          lifecycle_status: currentLifecycle,
          version: existing.version,
        }
      }];
    }

    // Valid lifecycle transition -- route to spine PATCH (skip execution_status pipeline)
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
          lifecycle_status: requestedLifecycle,
        },
        _needs_parent_check: false,
        _needs_dependency_check: false,
        _gw_debug: {
          ...(normalizeNode._gw_debug ?? {}),
          mutability: 'twig_lifecycle_transition',
          operation: 'UPDATE',
          transition: (currentLifecycle ?? 'NULL') + ' → ' + requestedLifecycle,
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

  // 6.7.6 No-op detection: same state â†’ no write
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

    const allowedMsg = allowed.length > 0 ? allowed.join(', ') : '(none â€” terminal state)';
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

  // 6.7.8a Twig lifecycle terminal guard
  // Twigs in promoted/pruned state are terminal -- no execution_status changes allowed
  if (artifact_type === 'twig') {
    const twigLifecycle = existing.lifecycle_status ?? null;
    if (twigLifecycle === 'promoted' || twigLifecycle === 'pruned') {
      return [{
        json: {
          ok: false,
          _gw_route: 'error',
          error: {
            code: 'ARCHIVE_TERMINAL',
            message: 'Cannot mutate execution_status on ' + twigLifecycle + ' twig',
            details: {
              artifact_id: existing.artifact_id,
              artifact_type: 'twig',
              lifecycle_status: twigLifecycle,
              hint: 'Twigs in promoted or pruned state are terminal. No mutations are permitted.'
            }
          }
        }
      }];
    }
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
        ...(execStatus !== null && execStatus !== undefined ? { execution_status: requestedStatus } : {}),
        ...(artifact_type === 'twig' && extension.lifecycle_status !== undefined ? { lifecycle_status: extension.lifecycle_status } : {}),
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

// 7. Mutability checks passed â€” extension update path
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
