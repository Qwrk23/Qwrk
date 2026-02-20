-- ============================================================================
-- MIGRATION: Supabase Linter Hardening — RLS + Function search_path
-- Version: 1.0
-- Date: 2026-02-11
-- ============================================================================
--
-- PURPOSE:
--   Resolve all Supabase linter findings for:
--     (A) RLS disabled on 3 public tables
--     (B) Mutable search_path on 6 functions
--
-- SCOPE:
--   - Enable RLS on qxb_artifact_video, qxb_artifact_instruction_pack, qxb_gateway_acl
--   - Create deterministic RLS policies for video and instruction_pack (extension table pattern)
--   - Create zero policies for gateway_acl (deny-all for non-service_role)
--   - Pin search_path = public on all 6 flagged functions
--
-- ASSUMPTIONS (verify before executing):
--   1. n8n Gateway accesses qxb_gateway_acl via service_role (bypasses RLS).
--      If using anon/authenticated, this migration WILL BREAK ACL lookups.
--   2. qxb_enforce_instruction_pack_extension() is a trigger function with no arguments.
--      If it has arguments, the ALTER will fail safely.
--   3. No RLS policies currently exist on the 3 flagged tables.
--      If policies exist, CREATE POLICY will fail with "already exists" (harmless).
--
-- EXECUTION:
--   Run in Supabase SQL Editor as a single script.
--   All statements are idempotent or fail-safe.
--
-- ROLLBACK:
--   See ROLLBACK section at the bottom of this file.
--
-- ============================================================================


-- ============================================================================
-- PART A: RLS ENABLEMENT + POLICIES
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────────
-- A1: qxb_artifact_video
-- ──────────────────────────────────────────────────────────────────────────────
-- Extension table (PK=FK to qxb_artifact). Mutable.
-- Follows the same delegation pattern as project/grass/thorn:
--   SELECT delegates to spine (spine RLS enforces workspace membership)
--   INSERT checks artifact ownership via spine
--   UPDATE checks owner or workspace admin via spine
--   No DELETE policy (deny-by-default; deletions via spine soft-delete)

ALTER TABLE public.qxb_artifact_video ENABLE ROW LEVEL SECURITY;

-- SELECT: workspace members can read (delegated through spine RLS)
CREATE POLICY qxb_artifact_video_select_via_artifact
  ON public.qxb_artifact_video
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.qxb_artifact a
      WHERE a.artifact_id = qxb_artifact_video.artifact_id
    )
  );

-- INSERT: only the artifact owner can create the extension row
CREATE POLICY qxb_artifact_video_insert_owner_via_artifact
  ON public.qxb_artifact_video
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.qxb_artifact a
      WHERE a.artifact_id = qxb_artifact_video.artifact_id
        AND a.owner_user_id = public.qxb_current_user_id()
    )
  );

-- UPDATE: owner or workspace admin (for status transitions during processing)
CREATE POLICY qxb_artifact_video_update_owner_or_admin
  ON public.qxb_artifact_video
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.qxb_artifact a
      WHERE a.artifact_id = qxb_artifact_video.artifact_id
        AND (
          a.owner_user_id = public.qxb_current_user_id()
          OR EXISTS (
            SELECT 1
            FROM public.qxb_workspace_user wsu
            WHERE wsu.workspace_id = a.workspace_id
              AND wsu.user_id = public.qxb_current_user_id()
              AND wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.qxb_artifact a
      WHERE a.artifact_id = qxb_artifact_video.artifact_id
        AND (
          a.owner_user_id = public.qxb_current_user_id()
          OR EXISTS (
            SELECT 1
            FROM public.qxb_workspace_user wsu
            WHERE wsu.workspace_id = a.workspace_id
              AND wsu.user_id = public.qxb_current_user_id()
              AND wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])
          )
        )
    )
  );


-- ──────────────────────────────────────────────────────────────────────────────
-- A2: qxb_artifact_instruction_pack
-- ──────────────────────────────────────────────────────────────────────────────
-- Extension table (PK=FK to qxb_artifact). Mutable.
-- Same delegation pattern. Ignores the redundant workspace_id column on this
-- table; all security checks delegate through the spine.

ALTER TABLE public.qxb_artifact_instruction_pack ENABLE ROW LEVEL SECURITY;

-- SELECT: workspace members can read (delegated through spine RLS)
CREATE POLICY qxb_artifact_instruction_pack_select_via_artifact
  ON public.qxb_artifact_instruction_pack
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.qxb_artifact a
      WHERE a.artifact_id = qxb_artifact_instruction_pack.artifact_id
    )
  );

-- INSERT: only the artifact owner can create the extension row
CREATE POLICY qxb_artifact_instruction_pack_insert_owner_via_artifact
  ON public.qxb_artifact_instruction_pack
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.qxb_artifact a
      WHERE a.artifact_id = qxb_artifact_instruction_pack.artifact_id
        AND a.owner_user_id = public.qxb_current_user_id()
    )
  );

-- UPDATE: owner or workspace admin
CREATE POLICY qxb_artifact_instruction_pack_update_owner_or_admin
  ON public.qxb_artifact_instruction_pack
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.qxb_artifact a
      WHERE a.artifact_id = qxb_artifact_instruction_pack.artifact_id
        AND (
          a.owner_user_id = public.qxb_current_user_id()
          OR EXISTS (
            SELECT 1
            FROM public.qxb_workspace_user wsu
            WHERE wsu.workspace_id = a.workspace_id
              AND wsu.user_id = public.qxb_current_user_id()
              AND wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.qxb_artifact a
      WHERE a.artifact_id = qxb_artifact_instruction_pack.artifact_id
        AND (
          a.owner_user_id = public.qxb_current_user_id()
          OR EXISTS (
            SELECT 1
            FROM public.qxb_workspace_user wsu
            WHERE wsu.workspace_id = a.workspace_id
              AND wsu.user_id = public.qxb_current_user_id()
              AND wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])
          )
        )
    )
  );


-- ──────────────────────────────────────────────────────────────────────────────
-- A3: qxb_gateway_acl
-- ──────────────────────────────────────────────────────────────────────────────
-- Internal infrastructure table. NOT an extension table.
-- Accessed exclusively by n8n Gateway via service_role (which bypasses RLS).
-- Enable RLS with ZERO policies = deny-all for anon and authenticated roles.
--
-- WARNING: If the Gateway does NOT use service_role, this will break ACL lookups.

ALTER TABLE public.qxb_gateway_acl ENABLE ROW LEVEL SECURITY;

-- No policies created intentionally. This is deny-all by design.
-- service_role bypasses RLS and continues to function normally.


-- ============================================================================
-- PART B: FUNCTION search_path HARDENING
-- ============================================================================
-- Pin search_path = public on all 6 flagged functions.
-- This prevents search_path injection where a malicious schema earlier in
-- the path could shadow public objects (tables, functions).
--
-- ALTER FUNCTION SET is non-destructive and reversible (RESET search_path).

-- ──────────────────────────────────────────────────────────────────────────────
-- B1: qxb_current_user_id() — CRITICAL
-- ──────────────────────────────────────────────────────────────────────────────
-- Used by ALL RLS policies in the system. Without pinned search_path, an
-- attacker could substitute a fake qxb_user table to return an arbitrary
-- user_id, bypassing every RLS check.

ALTER FUNCTION public.qxb_current_user_id()
  SET search_path = public;

-- ──────────────────────────────────────────────────────────────────────────────
-- B2: qxb_block_update_delete() — trigger function
-- ──────────────────────────────────────────────────────────────────────────────
-- Protects append-only tables (event log). Lower risk since it only raises
-- an exception, but hardening eliminates the linter finding.

ALTER FUNCTION public.qxb_block_update_delete()
  SET search_path = public;

-- ──────────────────────────────────────────────────────────────────────────────
-- B3: qxb_set_updated_at() — trigger function
-- ──────────────────────────────────────────────────────────────────────────────
-- Auto-sets updated_at on UPDATE. Used by multiple table triggers.

ALTER FUNCTION public.qxb_set_updated_at()
  SET search_path = public;

-- ──────────────────────────────────────────────────────────────────────────────
-- B4: fn_artifact_type_registry_set_updated_at() — trigger function
-- ──────────────────────────────────────────────────────────────────────────────
-- BEFORE UPDATE trigger on qxb_artifact_type_registry.
-- Definition in: migrations/2026-01-20__artifact_type_registry__fix_updated_at__v1.0.sql

ALTER FUNCTION public.fn_artifact_type_registry_set_updated_at()
  SET search_path = public;

-- ──────────────────────────────────────────────────────────────────────────────
-- B5: fn_audit_artifact_type_registry() — SECURITY DEFINER — CRITICAL
-- ──────────────────────────────────────────────────────────────────────────────
-- AFTER INSERT/UPDATE/DELETE trigger on qxb_artifact_type_registry.
-- Runs with OWNER privileges (SECURITY DEFINER). Without pinned search_path,
-- this is a privilege escalation vector — a malicious schema could intercept
-- the INSERT into the audit table and execute with elevated privileges.

ALTER FUNCTION public.fn_audit_artifact_type_registry()
  SET search_path = public;

-- ──────────────────────────────────────────────────────────────────────────────
-- B6: qxb_enforce_instruction_pack_extension() — LIVE-ONLY
-- ──────────────────────────────────────────────────────────────────────────────
-- No definition found in repo. Assumed trigger function with no arguments.
-- If this function has arguments, this ALTER will fail with
-- "function does not exist" — which is safe and informative.

ALTER FUNCTION public.qxb_enforce_instruction_pack_extension()
  SET search_path = public;


-- ============================================================================
-- PART C: VERIFICATION QUERIES
-- ============================================================================
-- Run these AFTER applying the migration to confirm correctness.

-- ──────────────────────────────────────────────────────────────────────────────
-- C1: Confirm RLS is enabled on all 3 tables
-- ──────────────────────────────────────────────────────────────────────────────
-- Expected: All 3 rows show relforcerowsecurity = true

SELECT
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS rls_forced
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
    'qxb_artifact_video',
    'qxb_artifact_instruction_pack',
    'qxb_gateway_acl'
  )
ORDER BY c.relname;

-- ──────────────────────────────────────────────────────────────────────────────
-- C2: Confirm policies exist for video and instruction_pack (none for acl)
-- ──────────────────────────────────────────────────────────────────────────────
-- Expected:
--   qxb_artifact_video: 3 policies (SELECT, INSERT, UPDATE)
--   qxb_artifact_instruction_pack: 3 policies (SELECT, INSERT, UPDATE)
--   qxb_gateway_acl: 0 policies

SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'qxb_artifact_video',
    'qxb_artifact_instruction_pack',
    'qxb_gateway_acl'
  )
ORDER BY tablename, cmd;

-- ──────────────────────────────────────────────────────────────────────────────
-- C3: Confirm search_path is set on all 6 functions
-- ──────────────────────────────────────────────────────────────────────────────
-- Expected: All 6 rows show proconfig containing 'search_path=public'

SELECT
  p.proname AS function_name,
  p.proconfig AS config
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'qxb_current_user_id',
    'qxb_block_update_delete',
    'qxb_set_updated_at',
    'fn_artifact_type_registry_set_updated_at',
    'fn_audit_artifact_type_registry',
    'qxb_enforce_instruction_pack_extension'
  )
ORDER BY p.proname;

-- ──────────────────────────────────────────────────────────────────────────────
-- C4: Confirm anon cannot read qxb_gateway_acl
-- ──────────────────────────────────────────────────────────────────────────────
-- Run this as the anon role (or authenticated without service_role).
-- Expected: 0 rows returned.

-- SET ROLE anon;
-- SELECT count(*) FROM public.qxb_gateway_acl;
-- RESET ROLE;

-- ──────────────────────────────────────────────────────────────────────────────
-- C5: Confirm workspace-scoped reads still work for video and instruction_pack
-- ──────────────────────────────────────────────────────────────────────────────
-- These queries use service_role (Supabase SQL Editor default) so they bypass
-- RLS. To test actual RLS enforcement, use PostgREST with an authenticated
-- user JWT or use SET ROLE:
--
-- SET ROLE authenticated;
-- SET request.jwt.claims = '{"sub": "7097c16c-ed88-4e49-983f-1de80e5cfcea"}';
-- SELECT * FROM public.qxb_artifact_video LIMIT 5;
-- SELECT * FROM public.qxb_artifact_instruction_pack LIMIT 5;
-- RESET ROLE;

-- ──────────────────────────────────────────────────────────────────────────────
-- C6: Confirm triggers still fire (function hardening didn't break them)
-- ──────────────────────────────────────────────────────────────────────────────
-- Verify the updated_at trigger on artifact still works:
--
-- SELECT artifact_id, updated_at FROM public.qxb_artifact
-- WHERE artifact_id = '668bd18f-4424-41e6-b2f9-393ecd2ec534';
--
-- UPDATE public.qxb_artifact SET title = title
-- WHERE artifact_id = '668bd18f-4424-41e6-b2f9-393ecd2ec534';
--
-- SELECT artifact_id, updated_at FROM public.qxb_artifact
-- WHERE artifact_id = '668bd18f-4424-41e6-b2f9-393ecd2ec534';
-- (updated_at should have advanced)

-- ──────────────────────────────────────────────────────────────────────────────
-- C7: Full RLS status for all qxb_* tables (comprehensive check)
-- ──────────────────────────────────────────────────────────────────────────────
-- Expected: ALL qxb_* tables show rls_enabled = true

SELECT
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname LIKE 'qxb_%'
  AND c.relkind = 'r'
ORDER BY c.relname;


-- ============================================================================
-- PART D: ROLLBACK
-- ============================================================================
-- If this migration causes issues, run the following to revert.
-- WARNING: Disabling RLS re-exposes the tables. Only use if the migration
-- causes functional breakage (e.g., Gateway ACL lookups failing).

-- D1: Revert RLS on qxb_artifact_video
-- DROP POLICY IF EXISTS qxb_artifact_video_select_via_artifact ON public.qxb_artifact_video;
-- DROP POLICY IF EXISTS qxb_artifact_video_insert_owner_via_artifact ON public.qxb_artifact_video;
-- DROP POLICY IF EXISTS qxb_artifact_video_update_owner_or_admin ON public.qxb_artifact_video;
-- ALTER TABLE public.qxb_artifact_video DISABLE ROW LEVEL SECURITY;

-- D2: Revert RLS on qxb_artifact_instruction_pack
-- DROP POLICY IF EXISTS qxb_artifact_instruction_pack_select_via_artifact ON public.qxb_artifact_instruction_pack;
-- DROP POLICY IF EXISTS qxb_artifact_instruction_pack_insert_owner_via_artifact ON public.qxb_artifact_instruction_pack;
-- DROP POLICY IF EXISTS qxb_artifact_instruction_pack_update_owner_or_admin ON public.qxb_artifact_instruction_pack;
-- ALTER TABLE public.qxb_artifact_instruction_pack DISABLE ROW LEVEL SECURITY;

-- D3: Revert RLS on qxb_gateway_acl
-- ALTER TABLE public.qxb_gateway_acl DISABLE ROW LEVEL SECURITY;

-- D4: Revert function search_path hardening
-- ALTER FUNCTION public.qxb_current_user_id() RESET search_path;
-- ALTER FUNCTION public.qxb_block_update_delete() RESET search_path;
-- ALTER FUNCTION public.qxb_set_updated_at() RESET search_path;
-- ALTER FUNCTION public.fn_artifact_type_registry_set_updated_at() RESET search_path;
-- ALTER FUNCTION public.fn_audit_artifact_type_registry() RESET search_path;
-- ALTER FUNCTION public.qxb_enforce_instruction_pack_extension() RESET search_path;


-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
