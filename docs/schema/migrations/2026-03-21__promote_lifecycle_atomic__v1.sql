-- T149: Atomic Lifecycle Promote Function (FINAL — deployed & tested 2026-03-21)
-- Purpose: Update spine lifecycle_status AND extension lifecycle_stage in a single
-- transaction, bypassing the circular trigger dependency.
--
-- Problem: Two triggers create circular dependency:
--   - trg_enforce_lifecycle_alignment (on qxb_artifact): requires extension to match
--   - trg_enforce_lifecycle_alignment_project (on qxb_artifact_project): requires spine to match
-- Neither update order works with triggers active.
--
-- Solution: SECURITY DEFINER function disables both triggers, updates both tables
-- atomically, re-enables triggers. Single transaction guarantees consistency.
--
-- Usage from n8n (via Supabase REST RPC):
--   POST https://<project>.supabase.co/rest/v1/rpc/promote_artifact_lifecycle
--   Body: { "p_artifact_id": "...", "p_workspace_id": "...", "p_to_state": "sapling", "p_expected_version": 1 }
--
-- Returns: Single row with post-update spine state, or raises exception on failure.
-- Handles: Trigger bypass, optimistic concurrency (version check), type routing
--          (only projects have extension table), and atomic alignment.
--
-- Exceptions raised:
--   ARTIFACT_NOT_FOUND — no matching artifact_id + workspace_id
--   EXTENSION_NOT_FOUND — project type but no qxb_artifact_project row
--   CONCURRENCY_CONFLICT — version mismatch (optimistic locking failure)

CREATE OR REPLACE FUNCTION public.promote_artifact_lifecycle(
    p_artifact_id uuid,
    p_workspace_id uuid,
    p_to_state text,
    p_expected_version integer
)
RETURNS TABLE (
    artifact_id uuid,
    workspace_id uuid,
    artifact_type text,
    lifecycle_status text,
    version integer,
    updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_artifact_type text;
    v_updated_row record;
BEGIN
    -- 1. Get artifact type (needed to know if extension table update is required)
    SELECT a.artifact_type INTO v_artifact_type
    FROM public.qxb_artifact a
    WHERE a.artifact_id = p_artifact_id
      AND a.workspace_id = p_workspace_id;

    IF v_artifact_type IS NULL THEN
        RAISE EXCEPTION 'ARTIFACT_NOT_FOUND: artifact_id=%, workspace_id=%', p_artifact_id, p_workspace_id;
    END IF;

    -- 2. Disable both lifecycle alignment triggers (circular dependency)
    ALTER TABLE public.qxb_artifact DISABLE TRIGGER trg_enforce_lifecycle_alignment;
    ALTER TABLE public.qxb_artifact_project DISABLE TRIGGER trg_enforce_lifecycle_alignment_project;

    -- 3. Update extension FIRST (if project type)
    IF v_artifact_type = 'project' THEN
        UPDATE public.qxb_artifact_project
        SET lifecycle_stage = p_to_state,
            updated_at = now()
        WHERE qxb_artifact_project.artifact_id = p_artifact_id;

        IF NOT FOUND THEN
            -- Re-enable triggers before raising
            ALTER TABLE public.qxb_artifact ENABLE TRIGGER trg_enforce_lifecycle_alignment;
            ALTER TABLE public.qxb_artifact_project ENABLE TRIGGER trg_enforce_lifecycle_alignment_project;
            RAISE EXCEPTION 'EXTENSION_NOT_FOUND: No qxb_artifact_project row for artifact_id=%', p_artifact_id;
        END IF;
    END IF;

    -- 4. Update spine with optimistic concurrency check
    UPDATE public.qxb_artifact
    SET lifecycle_status = p_to_state,
        updated_at = now(),
        version = p_expected_version + 1
    WHERE qxb_artifact.artifact_id = p_artifact_id
      AND qxb_artifact.workspace_id = p_workspace_id
      AND qxb_artifact.version = p_expected_version
    RETURNING
        qxb_artifact.artifact_id,
        qxb_artifact.workspace_id,
        qxb_artifact.artifact_type,
        qxb_artifact.lifecycle_status,
        qxb_artifact.version,
        qxb_artifact.updated_at
    INTO v_updated_row;

    -- 5. Re-enable triggers (MUST happen before any exception or return)
    ALTER TABLE public.qxb_artifact ENABLE TRIGGER trg_enforce_lifecycle_alignment;
    ALTER TABLE public.qxb_artifact_project ENABLE TRIGGER trg_enforce_lifecycle_alignment_project;

    -- 6. Check concurrency result
    IF v_updated_row.artifact_id IS NULL THEN
        RAISE EXCEPTION 'CONCURRENCY_CONFLICT: version mismatch for artifact_id=%, expected_version=%', p_artifact_id, p_expected_version;
    END IF;

    -- 7. Return the updated spine row
    RETURN QUERY SELECT
        v_updated_row.artifact_id,
        v_updated_row.workspace_id,
        v_updated_row.artifact_type,
        v_updated_row.lifecycle_status,
        v_updated_row.version,
        v_updated_row.updated_at;
END;
$$;

-- Grant execute to authenticated role (n8n uses service_role, but belt-and-suspenders)
GRANT EXECUTE ON FUNCTION public.promote_artifact_lifecycle(uuid, uuid, text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.promote_artifact_lifecycle(uuid, uuid, text, integer) TO service_role;

COMMENT ON FUNCTION public.promote_artifact_lifecycle IS 'T149: Atomic lifecycle promotion. Disables circular triggers, updates extension + spine atomically, re-enables triggers. Returns updated spine row.';
