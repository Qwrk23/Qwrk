-- ============================================================================
-- Sapling B -- Gateway Strict Mode: Completion + Promotion to Tree
-- ============================================================================
-- Sapling B:  8a937ffd-ea52-4c7b-9c47-91eb740390af (version 2)
-- Workspace:  be0d3a48-c764-44f9-90c8-e846d9dbbd0a
-- Owner:      c52c7a57-74ad-433d-a07c-4dcac1778672
--
-- Steps:
--   1. Mark all 40 leaves as complete
--   2. Mark all 8 branches as complete
--   3. Rename title (drop "Sapling --" prefix, title freezes at tree)
--   4. Promote sapling -> tree via atomic RPC
--   5. Insert event log entry
-- ============================================================================

DO $$
DECLARE
  v_sapling_b uuid := '8a937ffd-ea52-4c7b-9c47-91eb740390af';
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
    WHERE parent_artifact_id = v_sapling_b
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
  WHERE parent_artifact_id = v_sapling_b
    AND artifact_type = 'branch'
    AND deleted_at IS NULL;

  GET DIAGNOSTICS v_branch_count = ROW_COUNT;
  RAISE NOTICE 'Branches marked complete: %', v_branch_count;

  -- ================================================================
  -- STEP 3: Rename title (title freezes at tree stage)
  -- ================================================================
  UPDATE public.qxb_artifact
  SET title = 'Gateway Strict Mode',
      version = version + 1,
      updated_at = now()
  WHERE artifact_id = v_sapling_b;

  RAISE NOTICE 'Title updated: Sapling -- Gateway Strict Mode -> Gateway Strict Mode';

  -- ================================================================
  -- STEP 4: Promote sapling -> tree (atomic RPC)
  -- Current version after title update = 3
  -- ================================================================
  PERFORM public.promote_artifact_lifecycle(v_sapling_b, v_ws, 'tree', 3);

  RAISE NOTICE 'Promoted to tree (version now 4)';

  -- ================================================================
  -- STEP 5: Event log
  -- ================================================================
  INSERT INTO public.qxb_artifact_event (
    workspace_id, artifact_id, actor_user_id, event_type, payload
  ) VALUES (
    v_ws, v_sapling_b, v_owner, 'lifecycle_transition',
    jsonb_build_object(
      'from', 'sapling',
      'to', 'tree',
      'reason', 'Sapling B certified: 30 PASS, 2 test-expectation (not code bugs), 0 data integrity failures. All 8 branches enforcing. Save v50 deployed. Branch 2 future hardening logged on T168.',
      'certification_snapshot', '3f8e5052-783f-4872-9b53-cb02d3f74f85',
      'leaves_completed', v_leaf_count,
      'branches_completed', v_branch_count
    )
  );

  RAISE NOTICE 'Event logged. Sapling B is now a tree.';

END $$;
