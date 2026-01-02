-- AAA_New_Qwrk__RLS_Patch__Kernel_v1__v1.1__2025-12-30
-- Purpose: Fix infinite recursion in qxb_workspace_user RLS by switching to self-only membership visibility,
--          and update workspace visibility to rely on that self-membership policy.
-- Context: Live DB already updated; this file is the versioned patch artifact reflecting current live policies.

-- 1) qxb_workspace_user: remove recursive policy (member-based) and replace with self-only policy
DROP POLICY IF EXISTS qxb_workspace_user_select_member ON public.qxb_workspace_user;

CREATE POLICY qxb_workspace_user_select_self
ON public.qxb_workspace_user
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
);

-- 2) qxb_workspace: ensure workspace visibility is granted via self-membership (non-recursive)
-- NOTE: We drop/recreate to ensure the definition matches v1.1 exactly.
DROP POLICY IF EXISTS qxb_workspace_select_via_self_membership ON public.qxb_workspace;

CREATE POLICY qxb_workspace_select_via_self_membership
ON public.qxb_workspace
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.qxb_workspace_user wsu
    WHERE wsu.workspace_id = qxb_workspace.workspace_id
      AND wsu.user_id = auth.uid()
  )
);


-- KGB+ Sanity (Authenticated): workspace + membership visible
-- Expect: both queries return at least 1 row for the logged-in user.
SELECT workspace_id, user_id, role, created_at
FROM public.qxb_workspace_user
WHERE user_id = auth.uid();

SELECT workspace_id, name, created_at
FROM public.qxb_workspace
WHERE workspace_id IN (
  SELECT workspace_id FROM public.qxb_workspace_user WHERE user_id = auth.uid()
);
