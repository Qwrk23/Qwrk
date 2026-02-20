-- SQL to insert Gateway Fix Save Response Restart (Step 1 Execution) into Qwrk
-- Date: 2026-01-09
-- Artifact Type: restart
-- Purpose: Single-step execution prompt for CC - fix artifact.save response shaping

WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    artifact_id,
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags,
    content,
    parent_artifact_id,
    lifecycle_status,
    priority
  )
  VALUES (
    gen_random_uuid(),
    'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid,
    'c52c7a57-74ad-433d-a07c-4dcac1778672'::uuid,
    'restart',
    'Restart Prompt — EXECUTION (CC-Only) — Step 1 — Fix artifact.save INSERT Response Shaping',
    'Single-step execution restart for Claude Code: Fix artifact.save Gateway workflow to return correct response envelope with no loss of request context. Strict scope boundaries; hard stop after completion.',
    '["restart","execution","cc-only","gateway","artifact.save","step-1","response-shaping","bug-fix"]'::jsonb,
    '{}'::jsonb,
    null,
    'seed',
    1
  )
  RETURNING artifact_id
)
INSERT INTO qxb_artifact_restart (
  artifact_id,
  payload
)
SELECT
  artifact_id,
  '{
    "restart_kind": "execution_single_step",
    "audience": "Claude Code (CC)",
    "mode": "Execution",
    "step_number": 1,
    "derived_from": "LOCKED Me-First Governance Restart",
    "status": "READY_FOR_CC",
    "purpose": "Fix artifact.save Gateway workflow so successful INSERT returns correct response envelope with no loss of request context. Addresses known correctness bug, not feature addition.",
    "authorized_scope": {
      "can_modify": [
        "artifact.save workflow",
        "Response shaping logic after successful INSERT"
      ],
      "cannot_modify": [
        "Kernel v1 semantics",
        "Supabase schemas",
        "RLS policies",
        "Lifecycle rules",
        "artifact.query behavior",
        "artifact.list (not implemented)",
        "artifact.update (not implemented)",
        "CustomGPT schemas or actions",
        "New artifact types, actions, or fields"
      ],
      "stop_condition": "If change appears to require prohibited modification, STOP and report"
    },
    "problem_statement": {
      "observed": "artifact.save INSERT succeeds but final Gateway response returns: artifact_type=null, workspace_id=null, extension.payload={} (for restart/snapshot)",
      "diagnosis": "Database write is correct; response is wrong"
    },
    "required_fix_pattern": {
      "freeze_request_context_early": [
        "req_artifact_type",
        "req_workspace_id",
        "req_owner_user_id",
        "req_extension_payload (restart/snapshot)"
      ],
      "do_not": "Rely on downstream nodes to re-derive values",
      "build_final_response_from": [
        "Frozen req_* fields",
        "Inserted artifact_id",
        "Gateway operation metadata (action, timestamp)"
      ],
      "no_other_data_sources": true
    },
    "required_success_response": {
      "minimum_fields": [
        "ok: true",
        "gw_action",
        "artifact_id",
        "artifact_type (from frozen request)",
        "workspace_id (from frozen request)",
        "operation",
        "timestamp"
      ],
      "additional_for_restart_snapshot": "Response must echo saved payload correctly"
    },
    "regression_checklist": {
      "mandatory": true,
      "tests": [
        {
          "category": "artifact.query KGB tests still pass",
          "types": ["project","journal","snapshot","restart"]
        },
        {
          "category": "artifact.save test for restart",
          "validations": [
            "All required fields are non-null",
            "Payload is preserved"
          ]
        },
        {
          "category": "No change in",
          "items": ["Schema","RLS","Query behavior"]
        }
      ],
      "revert_condition": "If any regression appears, revert and report"
    },
    "hard_stop_instruction": {
      "after_completion": [
        "STOP",
        "Do NOT implement additional steps",
        "Do NOT refactor adjacent logic",
        "Do NOT proceed to artifact.list, artifact.update, or CustomGPT work",
        "Report completion and wait for next restart"
      ],
      "non_negotiable": true
    },
    "definition_of_done": {
      "binary": true,
      "complete_only_if": [
        "Response fields listed above are correct and non-null",
        "Restart/snapshot payloads are preserved",
        "All KGB query tests still pass",
        "No scope boundaries were crossed"
      ]
    },
    "execution_directive": "EXECUTE STEP 1 ONLY"
  }'::jsonb
FROM new_artifact;
