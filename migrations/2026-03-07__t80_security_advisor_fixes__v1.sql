-- ============================================================================
-- Migration: T80 Security Advisor Fixes
-- Date: 2026-03-07
-- Thread: T80 / T101
-- DDL Version: v2.8 -> v2.9
-- ============================================================================
-- Addresses 3 ERROR-level and 4 WARN-level Supabase advisor findings.
--
-- Security fixes (ERROR):
--   S1: qxb_artifact_rollup_view -- SECURITY DEFINER -> SECURITY INVOKER
--   S2: qxb_artifact_dependency -- Enable RLS + create 3 policies (drift fix)
--   S3: _migration_priority_null_snapshot -- Drop leftover migration table
--
-- Performance fixes (WARN):
--   P1-P4: RLS initplan -- wrap auth.uid() in (select ...) for 4 policies
--
-- NOTE: S4 (Leaked Password Protection) is a Supabase Dashboard toggle,
--       not a SQL change. Enable at: Auth > Settings > Password Security.
-- ============================================================================

-- ============================================================================
-- S3: Drop leftover migration table
-- ============================================================================
DROP TABLE IF EXISTS public._migration_priority_null_snapshot;

-- ============================================================================
-- S1: Fix SECURITY DEFINER view
-- ============================================================================
DROP VIEW IF EXISTS public.qxb_artifact_rollup_view;

CREATE VIEW public.qxb_artifact_rollup_view
WITH (security_invoker = true)
AS
SELECT
    p.artifact_id,
    p.artifact_type,
    p.workspace_id,
    p.semantic_type_id,
    COUNT(c.artifact_id)
        AS total_active_children_count,
    COUNT(c.artifact_id) FILTER (WHERE c.execution_status = 'complete')
        AS completed_children_count,
    CASE
        WHEN COUNT(c.artifact_id) = 0 THEN NULL
        ELSE (COUNT(c.artifact_id) FILTER (WHERE c.execution_status = 'complete'))::numeric
             / COUNT(c.artifact_id)::numeric
    END AS completion_ratio
FROM public.qxb_artifact p
LEFT JOIN public.qxb_artifact c
    ON c.parent_artifact_id = p.artifact_id
    AND c.deleted_at IS NULL
    AND c.workspace_id = p.workspace_id
WHERE p.artifact_type IN ('project', 'branch', 'limb')
    AND p.deleted_at IS NULL
GROUP BY p.artifact_id, p.artifact_type, p.workspace_id, p.semantic_type_id;

-- ============================================================================
-- S2: Enable RLS + create policies on qxb_artifact_dependency
-- ============================================================================
ALTER TABLE public.qxb_artifact_dependency ENABLE ROW LEVEL SECURITY;

CREATE POLICY qxb_artifact_dependency_select_member
    ON public.qxb_artifact_dependency
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.qxb_workspace_user wsu
        WHERE wsu.workspace_id = qxb_artifact_dependency.workspace_id
          AND wsu.user_id = public.qxb_current_user_id()
    ));

CREATE POLICY qxb_artifact_dependency_insert_member
    ON public.qxb_artifact_dependency
    FOR INSERT TO authenticated
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.qxb_workspace_user wsu
        WHERE wsu.workspace_id = qxb_artifact_dependency.workspace_id
          AND wsu.user_id = public.qxb_current_user_id()
    ));

CREATE POLICY qxb_artifact_dependency_delete_owner_or_admin
    ON public.qxb_artifact_dependency
    FOR DELETE TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.qxb_workspace_user wsu
        WHERE wsu.workspace_id = qxb_artifact_dependency.workspace_id
          AND wsu.user_id = public.qxb_current_user_id()
          AND wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])
    ));

-- ============================================================================
-- P1-P4: RLS initplan optimization
-- ============================================================================
DROP POLICY IF EXISTS qxb_user_select_self ON public.qxb_user;
CREATE POLICY qxb_user_select_self
    ON public.qxb_user
    FOR SELECT TO authenticated
    USING (auth_user_id = (select auth.uid()));

DROP POLICY IF EXISTS qxb_user_update_self ON public.qxb_user;
CREATE POLICY qxb_user_update_self
    ON public.qxb_user
    FOR UPDATE TO authenticated
    USING (auth_user_id = (select auth.uid()))
    WITH CHECK (auth_user_id = (select auth.uid()));

DROP POLICY IF EXISTS qxb_workspace_select_via_auth_membership ON public.qxb_workspace;
CREATE POLICY qxb_workspace_select_via_auth_membership
    ON public.qxb_workspace
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.qxb_workspace_user wsu
        JOIN public.qxb_user u ON u.user_id = wsu.user_id
        WHERE wsu.workspace_id = qxb_workspace.workspace_id
          AND u.auth_user_id = (select auth.uid())
    ));

DROP POLICY IF EXISTS qxb_workspace_user_select_via_auth ON public.qxb_workspace_user;
CREATE POLICY qxb_workspace_user_select_via_auth
    ON public.qxb_workspace_user
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.qxb_user u
        WHERE u.user_id = qxb_workspace_user.user_id
          AND u.auth_user_id = (select auth.uid())
    ));
