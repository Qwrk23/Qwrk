-- AAA_New_Qwrk__RLS_Patch__Kernel_v1__v1.2__2025-12-30
-- Purpose: Align RLS with dual-ID model (qxb_user.user_id internal, qxb_user.auth_user_id == auth.uid())
-- Fix: qxb_workspace_user SELECT and qxb_workspace SELECT authorize via qxb_user.auth_user_id join.

-- 1) qxb_workspace_user: replace prior self-only policy with auth-mapped policy
DROP POLICY IF EXISTS qxb_workspace_user_select_self ON public.qxb_workspace_user;
DROP POLICY IF EXISTS qxb_workspace_user_select_via_auth ON public.qxb_workspace_user;

CREATE POLICY qxb_workspace_user_select_via_auth
ON public.qxb_workspace_user
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.qxb_user u
    WHERE u.user_id = qxb_workspace_user.user_id
      AND u.auth_user_id = auth.uid()
  )
);

-- 2) qxb_workspace: replace prior workspace select policy with auth-mapped membership policy
DROP POLICY IF EXISTS qxb_workspace_select_via_self_membership ON public.qxb_workspace;
DROP POLICY IF EXISTS qxb_workspace_select_via_auth_membership ON public.qxb_workspace;

CREATE POLICY qxb_workspace_select_via_auth_membership
ON public.qxb_workspace
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.qxb_workspace_user wsu
    JOIN public.qxb_user u
      ON u.user_id = wsu.user_id
    WHERE wsu.workspace_id = qxb_workspace.workspace_id
      AND u.auth_user_id = auth.uid()
  )
);


-- KGB+ Sanity (SQL Editor authenticated simulation)
select
  set_config('request.jwt.claim.sub', '7097c16c-ed88-4e49-983f-1de80e5cfcea', true),
  set_config('request.jwt.claim.role', 'authenticated', true);

select auth.uid() as auth_uid;

-- Membership visible
select wsu.workspace_id, wsu.user_id, wsu.role, wsu.created_at
from public.qxb_workspace_user wsu
join public.qxb_user u on u.user_id = wsu.user_id
where u.auth_user_id = auth.uid();

-- Workspace visible
select w.workspace_id, w.name, w.created_at
from public.qxb_workspace w
where exists (
  select 1
  from public.qxb_workspace_user wsu
  join public.qxb_user u on u.user_id = wsu.user_id
  where wsu.workspace_id = w.workspace_id
    and u.auth_user_id = auth.uid()
);
