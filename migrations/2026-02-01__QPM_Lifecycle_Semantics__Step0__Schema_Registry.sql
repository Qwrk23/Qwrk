-- ============================================================================
-- QPM Lifecycle Semantics — Step 0: Schema & Registry Prerequisites
-- Date: 2026-02-01
-- Purpose: Add execution anatomy types (branch, limb, leaf) and sync registry
-- ============================================================================
--
-- EXECUTION ORDER:
-- 1. Run Step 0.1 (schema constraint update)
-- 2. Run Step 0.2 (type registry inserts)
-- 3. Verify with Step 0.3 (validation queries)
--
-- ROLLBACK: See bottom of file for rollback statements if needed.
-- ============================================================================

-- ============================================================================
-- STEP 0.1: Update Schema CHECK Constraint
-- ============================================================================
-- Current constraint (v2) is missing: instruction_pack, branch, limb, leaf
-- New constraint (v3) includes all 13 artifact types

-- Drop old constraint
ALTER TABLE public.qxb_artifact
DROP CONSTRAINT IF EXISTS qxb_artifact_artifact_type_check_v2;

-- Add new constraint with all 13 types
ALTER TABLE public.qxb_artifact
ADD CONSTRAINT qxb_artifact_artifact_type_check_v3
CHECK ((artifact_type = ANY (ARRAY[
  'project'::text,
  'snapshot'::text,
  'restart'::text,
  'journal'::text,
  'forest'::text,
  'thicket'::text,
  'flower'::text,
  'thorn'::text,
  'grass'::text,
  'instruction_pack'::text,
  'branch'::text,
  'limb'::text,
  'leaf'::text
])));

-- ============================================================================
-- STEP 0.2: Add Types to Registry
-- ============================================================================
-- Execution types: branch, limb, leaf
-- Operational types: thorn, grass (already in schema but may be missing from registry)

INSERT INTO public.qxb_artifact_type_registry (artifact_type, enabled, description)
VALUES
  ('branch', true, 'Strategic or functional domain within a project (execution layer)'),
  ('limb', true, 'Workstream or phase within a branch (execution layer, optional)'),
  ('leaf', true, 'Single executable action (execution layer, terminal)'),
  ('thorn', true, 'Exception tracking artifact'),
  ('grass', true, 'Operational issue tracking artifact')
ON CONFLICT (artifact_type) DO NOTHING;

-- ============================================================================
-- STEP 0.3: Verification Queries (run after migration)
-- ============================================================================

-- Verify constraint exists and has correct definition
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conname = 'qxb_artifact_artifact_type_check_v3';

-- Verify all 13 types are registered
-- SELECT artifact_type, enabled, description
-- FROM public.qxb_artifact_type_registry
-- ORDER BY artifact_type;

-- Expected output: 13 rows (all enabled)
-- branch, flower, forest, grass, instruction_pack, journal, leaf, limb,
-- project, restart, snapshot, thicket, thorn

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================
--
-- -- Revert to v2 constraint (removes branch, limb, leaf, instruction_pack)
-- ALTER TABLE public.qxb_artifact
-- DROP CONSTRAINT IF EXISTS qxb_artifact_artifact_type_check_v3;
--
-- ALTER TABLE public.qxb_artifact
-- ADD CONSTRAINT qxb_artifact_artifact_type_check_v2
-- CHECK ((artifact_type = ANY (ARRAY[
--   'project'::text,
--   'snapshot'::text,
--   'restart'::text,
--   'journal'::text,
--   'forest'::text,
--   'thicket'::text,
--   'flower'::text,
--   'thorn'::text,
--   'grass'::text
-- ])));
--
-- -- Remove new registry entries (be careful - may break existing data)
-- DELETE FROM public.qxb_artifact_type_registry
-- WHERE artifact_type IN ('branch', 'limb', 'leaf');
-- ============================================================================

-- CHANGELOG
-- ============================================================================
-- v1 - 2026-02-01
-- - Initial migration for QPM Lifecycle Semantics Phase 2
-- - Added constraint v3 with 13 artifact types
-- - Added branch, limb, leaf, thorn, grass to type registry
-- ============================================================================
