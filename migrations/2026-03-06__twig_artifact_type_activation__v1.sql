-- =============================================================================
-- Migration: Twig Artifact Type Activation
-- Date: 2026-03-06
-- DDL Version: v2.7 -> v2.8
-- Thread: T94 (Twig Activation)
-- Approved by: Joel (session 057)
--
-- Purpose:
--   Activate 'twig' as the 14th artifact type in the Qwrk kernel.
--   Twig = experimental micro-initiative attached to a Limb.
--   No extension table (Option A -- leaf precedent).
--   Lifecycle: proposed -> active -> promoted | pruned (DB-enforced).
--
-- Execution: Run in Supabase SQL Editor as service_role.
-- Rollback: See bottom of file.
-- =============================================================================

-- STEP 1: artifact_type CHECK v6 -> v7
-- Adds 'twig' to the allowed artifact types (13 -> 14 types).

ALTER TABLE public.qxb_artifact
  DROP CONSTRAINT qxb_artifact_artifact_type_check_v6;

ALTER TABLE public.qxb_artifact
  ADD CONSTRAINT qxb_artifact_artifact_type_check_v7
  CHECK (artifact_type = ANY (ARRAY[
    'project'::text,
    'journal'::text,
    'restart'::text,
    'snapshot'::text,
    'grass'::text,
    'thorn'::text,
    'forest'::text,
    'thicket'::text,
    'flower'::text,
    'branch'::text,
    'leaf'::text,
    'instruction_pack'::text,
    'limb'::text,
    'twig'::text
  ]));

-- STEP 2: Twig lifecycle CHECK
-- Enforces valid lifecycle values for twig artifacts.
-- Pattern: conditional CHECK (same approach as project lifecycle CHECK).
-- Non-twig types are unaffected.

ALTER TABLE public.qxb_artifact
  ADD CONSTRAINT qxb_artifact_twig_lifecycle_check
  CHECK (
    (artifact_type <> 'twig'::text)
    OR (lifecycle_status = ANY (ARRAY[
      'proposed'::text,
      'active'::text,
      'promoted'::text,
      'pruned'::text
    ]))
  );

-- STEP 3: Type registry entry
-- Gateway Save consults qxb_artifact_type_registry before allowing creation.

INSERT INTO public.qxb_artifact_type_registry (artifact_type, enabled, description)
VALUES ('twig', true, 'Experimental micro-initiative attached to a Limb. Pilot: Mother Tree only.');

-- STEP 4: Semantic type registry entry
-- Provides semantic classification for twig artifacts.
-- governance_snapshot_id NULL matches bootstrap pattern (9 existing entries).

INSERT INTO public.qxb_semantic_type_registry (key, description, active)
VALUES ('twig', 'Experimental micro-initiative', true);

-- =============================================================================
-- VERIFICATION QUERIES (run after migration)
-- =============================================================================

-- V1: Confirm CHECK v7 is active
-- SELECT conname FROM pg_constraint
-- WHERE conrelid = 'public.qxb_artifact'::regclass
--   AND conname LIKE '%artifact_type_check%';
-- Expected: qxb_artifact_artifact_type_check_v7

-- V2: Confirm twig lifecycle CHECK is active
-- SELECT conname FROM pg_constraint
-- WHERE conrelid = 'public.qxb_artifact'::regclass
--   AND conname = 'qxb_artifact_twig_lifecycle_check';
-- Expected: 1 row

-- V3: Confirm type registry entry
-- SELECT * FROM public.qxb_artifact_type_registry WHERE artifact_type = 'twig';
-- Expected: 1 row, enabled = true

-- V4: Confirm semantic type entry
-- SELECT * FROM public.qxb_semantic_type_registry WHERE key = 'twig';
-- Expected: 1 row, active = true

-- V5: Test INSERT (dry run -- do NOT commit in production)
-- BEGIN;
-- INSERT INTO public.qxb_artifact (
--   workspace_id, owner_user_id, artifact_type, title, lifecycle_status
-- ) VALUES (
--   'be0d3a48-c764-44f9-90c8-e846d9dbbd0a',
--   'c52c7a57-74ad-433d-a07c-4dcac1778672',
--   'twig',
--   'Test Twig -- DELETE ME',
--   'proposed'
-- );
-- ROLLBACK;

-- V6: Confirm invalid lifecycle rejected
-- INSERT INTO public.qxb_artifact (
--   workspace_id, owner_user_id, artifact_type, title, lifecycle_status
-- ) VALUES (
--   'be0d3a48-c764-44f9-90c8-e846d9dbbd0a',
--   'c52c7a57-74ad-433d-a07c-4dcac1778672',
--   'twig',
--   'Test Twig Invalid',
--   'seed'
-- );
-- Expected: CHECK constraint violation (qxb_artifact_twig_lifecycle_check)

-- =============================================================================
-- ROLLBACK (if needed)
-- =============================================================================
-- ALTER TABLE public.qxb_artifact DROP CONSTRAINT qxb_artifact_artifact_type_check_v7;
-- ALTER TABLE public.qxb_artifact
--   ADD CONSTRAINT qxb_artifact_artifact_type_check_v6
--   CHECK (artifact_type = ANY (ARRAY['project','journal','restart','snapshot','grass','thorn','forest','thicket','flower','branch','leaf','instruction_pack','limb']));
-- ALTER TABLE public.qxb_artifact DROP CONSTRAINT qxb_artifact_twig_lifecycle_check;
-- DELETE FROM public.qxb_artifact_type_registry WHERE artifact_type = 'twig';
-- DELETE FROM public.qxb_semantic_type_registry WHERE key = 'twig';
