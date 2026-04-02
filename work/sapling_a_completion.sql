-- ============================================================================
-- Sapling A — Response & Error Integrity: Completion + Promotion to Tree
-- ============================================================================
-- Sapling A:  20d27f2d-9464-4ab4-884f-34ee2aa0b5b1 (version 2)
-- Workspace:  be0d3a48-c764-44f9-90c8-e846d9dbbd0a
-- Owner:      c52c7a57-74ad-433d-a07c-4dcac1778672
--
-- Steps:
--   1. Mark all 16 leaves as complete
--   2. Mark all 3 branches as complete
--   3. Rename title (drop "Sapling —" prefix, title freezes at tree)
--   4. Promote sapling → tree via atomic RPC
--   5. Insert event log entry
-- ============================================================================

DO $$
DECLARE
  v_sapling_a uuid := '20d27f2d-9464-4ab4-884f-34ee2aa0b5b1';
  v_ws        uuid := 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a';
  v_owner     uuid := 'c52c7a57-74ad-433d-a07c-4dcac1778672';
  v_leaf_count int;
  v_branch_count int;
BEGIN

  -- ================================================================
  -- STEP 1: Mark all leaves as complete
  -- ================================================================
  UPDATE public.qxb_artifact
  SET execution_status = 'complete',
      version = version + 1,
      updated_at = now()
  WHERE parent_artifact_id IN (
    SELECT artifact_id FROM public.qxb_artifact
    WHERE parent_artifact_id = v_sapling_a
      AND artifact_type = 'branch'
      AND deleted_at IS NULL
  )
  AND artifact_type = 'leaf'
  AND deleted_at IS NULL;

  GET DIAGNOSTICS v_leaf_count = ROW_COUNT;
  RAISE NOTICE 'Leaves marked complete: %', v_leaf_count;

  -- ================================================================
  -- STEP 2: Mark all branches as complete
  -- ================================================================
  UPDATE public.qxb_artifact
  SET execution_status = 'complete',
      version = version + 1,
      updated_at = now()
  WHERE parent_artifact_id = v_sapling_a
    AND artifact_type = 'branch'
    AND deleted_at IS NULL;

  GET DIAGNOSTICS v_branch_count = ROW_COUNT;
  RAISE NOTICE 'Branches marked complete: %', v_branch_count;

  -- ================================================================
  -- STEP 3: Rename title (title freezes at tree stage)
  -- ================================================================
  UPDATE public.qxb_artifact
  SET title = 'Response & Error Integrity',
      version = version + 1,
      updated_at = now()
  WHERE artifact_id = v_sapling_a;

  RAISE NOTICE 'Title updated: Sapling -- Response & Error Integrity -> Response & Error Integrity';

  -- ================================================================
  -- STEP 4: Promote sapling → tree (atomic RPC)
  -- Current version after title update = 3
  -- ================================================================
  PERFORM public.promote_artifact_lifecycle(v_sapling_a, v_ws, 'tree', 3);

  RAISE NOTICE 'Promoted to tree (version now 4)';

  -- ================================================================
  -- STEP 5: Event log
  -- ================================================================
  INSERT INTO public.qxb_artifact_event (
    workspace_id, artifact_id, actor_user_id, event_type, payload
  ) VALUES (
    v_ws, v_sapling_a, v_owner, 'lifecycle_transition',
    jsonb_build_object(
      'from', 'sapling',
      'to', 'tree',
      'reason', 'Sapling A certified: 12 PASS, 2 FAIL (pre-existing), 2 SKIP. All 3 branches implemented and validated. Gateway passthrough enforced. Dual-shaping eliminated.',
      'certification_snapshot', 'e35be5af-f9e1-490e-b9c9-fa8e93b592e3',
      'leaves_completed', v_leaf_count,
      'branches_completed', v_branch_count
    )
  );

  RAISE NOTICE 'Event logged. Sapling A is now a tree.';

END $$;
