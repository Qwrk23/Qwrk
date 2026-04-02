-- ============================================================================
-- Compliance-to-Enforcement Hardening: Sapling Structure Build
-- ============================================================================
-- Creates 3 child project saplings under existing seed fb5bccd0
-- Each sapling gets branches, then is promoted seed → sapling
--
-- Parent seed: fb5bccd0-1e64-4407-95d8-989b7e08aa17
-- Workspace:   be0d3a48-c764-44f9-90c8-e846d9dbbd0a (Qwrk Personal)
-- Owner:       c52c7a57-74ad-433d-a07c-4dcac1778672 (Joel)
--
-- Structure:
--   Sapling A — Response & Error Integrity (3 branches)
--   Sapling B — Gateway Strict Mode (8 branches)
--   Sapling C — Architectural Enforcement (3 branches)
--
-- Total: 3 projects + 3 extension rows + 14 branches + 3 event entries
-- ============================================================================

DO $$
DECLARE
  -- Constants
  v_ws       uuid := 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a';
  v_owner    uuid := 'c52c7a57-74ad-433d-a07c-4dcac1778672';
  v_parent   uuid := 'fb5bccd0-1e64-4407-95d8-989b7e08aa17';
  v_sem_gov  uuid := '40a5060b-1a80-4e8b-b7b7-1e102026efc0';

  -- Generated sapling IDs
  v_sap_a uuid;
  v_sap_b uuid;
  v_sap_c uuid;

BEGIN

  -- ================================================================
  -- SAPLING A: Response & Error Integrity
  -- ================================================================

  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, lifecycle_status, semantic_type_id, tags, parent_artifact_id
  ) VALUES (
    v_ws, v_owner, 'project',
    'Sapling — Response & Error Integrity',
    'Fix the Gateway response pipeline so every response is honest, consistent, and never swallows errors. Addresses T113/T114.',
    2, 'seed', v_sem_gov,
    '["compliance-to-enforcement", "response-integrity"]'::jsonb,
    v_parent
  ) RETURNING artifact_id INTO v_sap_a;

  INSERT INTO public.qxb_artifact_project (artifact_id, lifecycle_stage)
  VALUES (v_sap_a, 'seed');

  -- Branches under Sapling A
  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, tags, parent_artifact_id
  ) VALUES
  (
    v_ws, v_owner, 'branch',
    'Deterministic Error Surfacing',
    'Ensure all validation and sub-workflow errors propagate to the Gateway response without being swallowed or masked. Connects to T113 + T114 (mobile silent failures).',
    2, '["compliance-to-enforcement", "response-integrity", "error-surfacing"]'::jsonb,
    v_sap_a
  ),
  (
    v_ws, v_owner, 'branch',
    'Consistent Response Shape',
    'Ensure all Gateway responses follow a strict, consistent schema (ok, data, error, version) regardless of action or failure mode. Fix version:null gap observed in content updates.',
    2, '["compliance-to-enforcement", "response-integrity", "response-shape"]'::jsonb,
    v_sap_a
  ),
  (
    v_ws, v_owner, 'branch',
    'Reject No-Op Extension Updates',
    'Reject artifact.update with extension payload on types that do not persist extension updates (branch, leaf, twig, spine-only types). Eliminates false-positive confirmations.',
    2, '["compliance-to-enforcement", "response-integrity", "no-op-rejection"]'::jsonb,
    v_sap_a
  );

  -- Promote Sapling A: seed → sapling (atomic RPC bypasses circular triggers)
  PERFORM public.promote_artifact_lifecycle(v_sap_a, v_ws, 'sapling', 1);

  INSERT INTO public.qxb_artifact_event (
    workspace_id, artifact_id, actor_user_id, event_type, payload
  ) VALUES (
    v_ws, v_sap_a, v_owner, 'lifecycle_transition',
    jsonb_build_object(
      'from', 'seed', 'to', 'sapling',
      'reason', 'Structure build: 3 branches scaffolded for response and error integrity hardening'
    )
  );

  -- ================================================================
  -- SAPLING B: Gateway Strict Mode
  -- ================================================================

  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, lifecycle_status, semantic_type_id, tags, parent_artifact_id
  ) VALUES (
    v_ws, v_owner, 'project',
    'Sapling — Gateway Strict Mode',
    'Input validation hardening across Save and Update sub-workflows. Reject bad input early, inject deterministic defaults, eliminate silent data loss.',
    2, 'seed', v_sem_gov,
    '["compliance-to-enforcement", "gateway-strict-mode"]'::jsonb,
    v_parent
  ) RETURNING artifact_id INTO v_sap_b;

  INSERT INTO public.qxb_artifact_project (artifact_id, lifecycle_stage)
  VALUES (v_sap_b, 'seed');

  -- Branches under Sapling B
  -- Group B1: Payload Sanitization
  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, tags, parent_artifact_id
  ) VALUES
  (
    v_ws, v_owner, 'branch',
    'Reject Unknown Extension Keys',
    'Reject unknown extension keys with a deterministic VALIDATION_ERROR listing artifact type, allowed keys, and rejected keys. Eliminates silent data loss.',
    2, '["compliance-to-enforcement", "gateway-strict-mode", "payload-sanitization"]'::jsonb,
    v_sap_b
  ),
  (
    v_ws, v_owner, 'branch',
    'Reject Unknown Top-Level Fields',
    'Reject payloads containing unknown top-level fields instead of silently ignoring them. Provide explicit validation feedback listing allowed fields.',
    2, '["compliance-to-enforcement", "gateway-strict-mode", "payload-sanitization"]'::jsonb,
    v_sap_b
  ),
  (
    v_ws, v_owner, 'branch',
    'Reject Empty Required Objects',
    'Reject payloads where required object fields (e.g., extension.payload for snapshots) are present but empty or null. Distinguish presence from validity.',
    2, '["compliance-to-enforcement", "gateway-strict-mode", "payload-sanitization"]'::jsonb,
    v_sap_b
  ),
  (
    v_ws, v_owner, 'branch',
    'Reject append_log Reserved Key',
    'Reject any content update payload that includes an append_log key. Prevents overwriting the system-managed append-only audit trail. Irreversible data corruption prevention.',
    2, '["compliance-to-enforcement", "gateway-strict-mode", "payload-sanitization"]'::jsonb,
    v_sap_b
  ),
  (
    v_ws, v_owner, 'branch',
    'Snapshot for-q Auto-Injection',
    'Auto-inject for-q tag on snapshot save when semantic_type_id is one of: governance, execution-core, infrastructure, platform. Zero compliance surface for rolling memory visibility.',
    2, '["compliance-to-enforcement", "gateway-strict-mode", "auto-injection"]'::jsonb,
    v_sap_b
  ),
  (
    v_ws, v_owner, 'branch',
    'Execution Status Auto-Default',
    'Auto-default execution_status to not_started on insert for branch, limb, leaf, and twig artifact types. Eliminates CmdCtr noise from NULL execution states.',
    2, '["compliance-to-enforcement", "gateway-strict-mode", "auto-injection"]'::jsonb,
    v_sap_b
  ),
  -- Group B2: Structural Validation
  (
    v_ws, v_owner, 'branch',
    'Enforce Parent Requirement for Child Types',
    'Require parent_artifact_id on save for branch, leaf, limb, and twig. Reject orphaned creations. Prevents broken Mother Tree topology.',
    2, '["compliance-to-enforcement", "gateway-strict-mode", "structural-validation"]'::jsonb,
    v_sap_b
  ),
  (
    v_ws, v_owner, 'branch',
    'Twig Content Completeness',
    'Enforce non-empty content on twig save with required intent bundle: idea, why_now, problem_touched, future_hook. Prevents title-only twigs that lose context.',
    2, '["compliance-to-enforcement", "gateway-strict-mode", "structural-validation"]'::jsonb,
    v_sap_b
  );

  -- Promote Sapling B: seed → sapling (atomic RPC bypasses circular triggers)
  PERFORM public.promote_artifact_lifecycle(v_sap_b, v_ws, 'sapling', 1);

  INSERT INTO public.qxb_artifact_event (
    workspace_id, artifact_id, actor_user_id, event_type, payload
  ) VALUES (
    v_ws, v_sap_b, v_owner, 'lifecycle_transition',
    jsonb_build_object(
      'from', 'seed', 'to', 'sapling',
      'reason', 'Structure build: 8 branches scaffolded (6 payload sanitization + 2 structural validation)'
    )
  );

  -- ================================================================
  -- SAPLING C: Architectural Enforcement
  -- ================================================================

  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, lifecycle_status, semantic_type_id, tags, parent_artifact_id
  ) VALUES (
    v_ws, v_owner, 'project',
    'Sapling — Architectural Enforcement',
    'Design-first enforcement items requiring architectural decisions before implementation. Content safety, workspace integrity, and idempotency.',
    3, 'seed', v_sem_gov,
    '["compliance-to-enforcement", "architectural"]'::jsonb,
    v_parent
  ) RETURNING artifact_id INTO v_sap_c;

  INSERT INTO public.qxb_artifact_project (artifact_id, lifecycle_stage)
  VALUES (v_sap_c, 'seed');

  -- Branches under Sapling C
  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, tags, parent_artifact_id
  ) VALUES
  (
    v_ws, v_owner, 'branch',
    'Merge-Safe Content Structure Pattern',
    'Design and enforce a permanent keyed-object content pattern for all artifacts supporting mergeable or appendable content. Eliminates array-replacement risk system-wide.',
    3, '["compliance-to-enforcement", "architectural", "content-safety"]'::jsonb,
    v_sap_c
  ),
  (
    v_ws, v_owner, 'branch',
    'Enforce Workspace Consistency for References',
    'Validate that all references within a payload (parent_artifact_id, dependency IDs) belong to the same workspace as gw_workspace_id. Reject cross-workspace references.',
    3, '["compliance-to-enforcement", "architectural", "workspace-integrity"]'::jsonb,
    v_sap_c
  ),
  (
    v_ws, v_owner, 'branch',
    'Enforce Idempotency',
    'Ensure repeated identical requests do not create duplicate or conflicting state. Focus on messaging and snapshot creation flows. Previously T2 (closed as stale).',
    3, '["compliance-to-enforcement", "architectural", "idempotency"]'::jsonb,
    v_sap_c
  );

  -- Promote Sapling C: seed → sapling (atomic RPC bypasses circular triggers)
  PERFORM public.promote_artifact_lifecycle(v_sap_c, v_ws, 'sapling', 1);

  INSERT INTO public.qxb_artifact_event (
    workspace_id, artifact_id, actor_user_id, event_type, payload
  ) VALUES (
    v_ws, v_sap_c, v_owner, 'lifecycle_transition',
    jsonb_build_object(
      'from', 'seed', 'to', 'sapling',
      'reason', 'Structure build: 3 branches scaffolded for architectural enforcement (design-first)'
    )
  );

  -- ================================================================
  RAISE NOTICE 'Sapling A (Response & Error Integrity): %', v_sap_a;
  RAISE NOTICE 'Sapling B (Gateway Strict Mode): %', v_sap_b;
  RAISE NOTICE 'Sapling C (Architectural Enforcement): %', v_sap_c;
  RAISE NOTICE 'Total: 3 saplings + 14 branches created and promoted.';

END $$;
