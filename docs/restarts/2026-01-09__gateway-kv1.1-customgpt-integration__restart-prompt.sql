-- SQL to insert Gateway Kv1.1 + CustomGPT Integration Restart Prompt into Qwrk
-- Date: 2026-01-09
-- Artifact Type: restart
-- Purpose: Session continuation prompt for Gateway build

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
    'RESTART PROMPT — Gateway Solid for Kv1.1 + CustomGPT Integration',
    'Session continuation prompt: Fix artifact.save response shaping blocker, implement artifact.list MVP, complete artifact.update with mutability enforcement, integrate CustomGPT end-to-end.',
    '["restart","gateway","kv1.1","customgpt","integration","session-prompt","phase-a"]'::jsonb,
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
    "restart_kind": "session_continuation_prompt",
    "session_date": "2026-01-09",
    "overall_goal": "Get Gateway solidly working for all Kv1.1 capabilities, then bring up Qwrk CustomGPT front end and confirm it interacts successfully with Gateway.",
    "phase_a_scope": {
      "artifact_types": ["project","journal","snapshot","restart"],
      "capabilities": ["save","query","list","hydrate","update"],
      "mutability_rules": {
        "journal": "UPDATE_BLOCKED",
        "snapshot": "UPDATE_BLOCKED",
        "restart": "UPDATE_BLOCKED",
        "project": "UPDATE_ALLOWED"
      }
    },
    "contract_invariants": [
      "Use artifact.save (single save action) - do NOT introduce artifact.create",
      "Spine-first: qxb_artifact is fetched/validated first; stored artifact_type is truth",
      "Response shaping must not depend on post-DB nodes that drop request context",
      "After each meaningful change, run regression tests"
    ],
    "current_blocker": {
      "issue": "artifact.save INSERT succeeds but final Gateway response returns null workspace_id, null artifact_type, empty extension.payload",
      "diagnosis": "Response is being built from a later node output that lost key fields",
      "fix_required": "Freeze request intent fields early (before DB nodes) and build final response from frozen req_* fields + inserted artifact_id"
    },
    "execution_steps": [
      {
        "step": 1,
        "title": "Fix artifact.save INSERT response shaping",
        "action": "Freeze req_artifact_type, req_workspace_id, req_owner_user_id, req_extension_payload early; build final response from frozen fields + artifact_id",
        "regression_gate": "Re-run artifact.query KGB tests (project/journal/snapshot/restart); run 1 restart save INSERT test"
      },
      {
        "step": 2,
        "title": "Implement artifact.list (MVP)",
        "action": "Type-scoped list with minimal selector (artifact_type required, parent_artifact_id optional, limit default 20 max 100); return fully hydrated artifacts",
        "regression_gate": "Query KGB tests still pass; list returns correct rows and hydration for 2+ types"
      },
      {
        "step": 3,
        "title": "Implement artifact.update (only where allowed)",
        "action": "Enforce immutability rules; allow project updates only (limited fields, no client-supplied version)"
      },
      {
        "step": 4,
        "title": "CustomGPT integration",
        "action": "Align GPT Action schema to Gateway contract; run end-to-end tests: create journal, query journal, list journals, attempt journal update (blocked), create project, update project"
      }
    ],
    "kgb_state": {
      "working": "artifact.query works end-to-end for all 4 KGB types; spine-first architecture validated",
      "test_ids": {
        "journal": "db428a32-1afa-4e6b-a649-347b0bffd46c",
        "project": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
        "snapshot": "610e16d1-c5bb-468c-bd35-57eadf9f2e38",
        "restart": "ac1d6294-2bd7-4a9d-823e-827562b56e26"
      }
    },
    "hard_rules": [
      "DO NOT type leading = in n8n expressions",
      "Flatten payloads before DB nodes",
      "Use Qxb-prefixed node names",
      "Guard against whitespace in switch comparisons using trim()",
      "No guessing schemas/enums/endpoints"
    ],
    "session_start_procedure": [
      "User uploads NQxb_Gateway_v1.json workflow export",
      "Locate broken Save response shaping code",
      "Design the fix",
      "Proceed with Step 1 implementation"
    ],
    "optional_phase_b": "Expand artifact_type support beyond KGB types ONLY if schema tables confirmed, allow-lists updated, tests added. No guessing.",
    "success_estimate": "85-90% confidence for 12-hour completion",
    "priority": "Critical (gates CustomGPT launch)"
  }'::jsonb
FROM new_artifact;
