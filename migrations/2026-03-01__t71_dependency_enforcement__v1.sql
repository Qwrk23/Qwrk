--
-- T71 v1 — Dependency Enforcement: RPC Function
-- Date: 2026-03-01
-- Thread: T71
-- Scope: Enforcement only — no Gateway actions, no triggers
--
-- Prerequisites:
--   qxb_artifact_dependency table must already exist in Supabase
--   (created by Q + Joel during T71 design session)
--
-- What this migration adds:
--   1. RPC function: check_leaf_dependencies(artifact_id, workspace_id)
--      - JOINs qxb_artifact_dependency → qxb_artifact
--      - Returns first incomplete dependency (if any)
--      - 0 rows = all deps complete or no deps exist
--      - 1 row = at least one blocker (early exit via LIMIT 1)
--
-- Called by: Update sub-workflow (DB_Query_Incomplete_Dependencies node)
--   POST /rest/v1/rpc/check_leaf_dependencies
--   Body: { "p_artifact_id": "...", "p_workspace_id": "..." }
--
-- Security model:
--   SECURITY DEFINER — runs as function owner (bypasses RLS)
--   SET search_path = public — inline hardening (DDL v2.4 pattern)
--   Read-only function — no side effects
--

CREATE OR REPLACE FUNCTION public.check_leaf_dependencies(
  p_artifact_id uuid,
  p_workspace_id uuid
)
RETURNS TABLE (
  depends_on_artifact_id uuid,
  execution_status text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT d.depends_on_artifact_id, a.execution_status
  FROM public.qxb_artifact_dependency d
  JOIN public.qxb_artifact a ON a.artifact_id = d.depends_on_artifact_id
  WHERE d.artifact_id = p_artifact_id
    AND d.workspace_id = p_workspace_id
    AND (a.execution_status IS DISTINCT FROM 'complete')
  LIMIT 1;
$$;

COMMENT ON FUNCTION public.check_leaf_dependencies(uuid, uuid) IS 'T71: Returns first incomplete dependency for a leaf artifact. 0 rows = all deps complete (or no deps). Used by Update sub-workflow to enforce leaf-to-leaf dependency rules before allowing execution_status = complete.';
