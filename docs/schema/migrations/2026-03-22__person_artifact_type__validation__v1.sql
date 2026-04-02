-- =============================================================================
-- T150: Person Artifact Type — Validation Query Set v1.1
-- =============================================================================
-- Date:    2026-03-22
-- Thread:  T150 (Branch 2 — Leaves 2.11, 2.13–2.17)
--
-- Run AFTER forward migration to verify correctness.
-- Each query includes expected result in comment.
-- =============================================================================

-- ============================================================================
-- V1: CHECK constraint version confirmation
-- ============================================================================
-- Expected: constraint name = 'qxb_artifact_artifact_type_check_v8'

SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND conname LIKE '%artifact_type_check%';

-- ============================================================================
-- V2: Existing artifact types unaffected (regression safety — Leaf 2.11)
-- ============================================================================
-- Expected: all existing types still present, no data loss.
-- Count should match pre-migration count (run before migration to capture baseline).

SELECT artifact_type, count(*) AS cnt
FROM public.qxb_artifact
GROUP BY artifact_type
ORDER BY artifact_type;

-- ============================================================================
-- V3: 'person' type is now allowed in CHECK constraint
-- ============================================================================
-- Expected: no error. If CHECK rejects, migration failed.

DO $$
BEGIN
  -- Dry run: validate 'person' is in the CHECK without inserting.
  -- We test by checking the constraint definition includes 'person'.
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.qxb_artifact'::regclass
      AND conname = 'qxb_artifact_artifact_type_check_v8'
      AND pg_get_constraintdef(oid) LIKE '%person%'
  ) THEN
    RAISE EXCEPTION 'VALIDATION FAILED: person not found in CHECK v8';
  END IF;
  RAISE NOTICE 'V3 PASS: person is in CHECK v8';
END $$;

-- ============================================================================
-- V4: Extension table exists with correct structure
-- ============================================================================
-- Expected: 27 columns (artifact_id + 22 data columns + 2 timestamps + 2 jsonb arrays)

SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'qxb_artifact_person'
ORDER BY ordinal_position;

-- ============================================================================
-- V5: PK and FK constraints exist
-- ============================================================================
-- Expected: pkey + fk constraints present

SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact_person'::regclass;

-- ============================================================================
-- V6: Indexes exist
-- ============================================================================
-- Expected: 6 indexes (full_name, relationship_type, key_facts, what_they_care_about,
-- preferences, last_contacted_at) plus 1 for the PK = 7 total

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'qxb_artifact_person'
ORDER BY indexname;

-- ============================================================================
-- V7: RLS enabled + 3 policies
-- ============================================================================
-- Expected: RLS enabled, 3 policies (select, insert, update)

SELECT relname, relrowsecurity
FROM pg_class
WHERE relname = 'qxb_artifact_person';

SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'qxb_artifact_person'
ORDER BY policyname;

-- ============================================================================
-- V8: updated_at trigger exists
-- ============================================================================
-- Expected: qxb_artifact_person_set_updated_at trigger

SELECT tgname, tgtype
FROM pg_trigger
WHERE tgrelid = 'public.qxb_artifact_person'::regclass
  AND NOT tgisinternal;

-- ============================================================================
-- V9: Type registry entry exists
-- ============================================================================
-- Expected: person, enabled=true

SELECT artifact_type, enabled, description
FROM public.qxb_artifact_type_registry
WHERE artifact_type = 'person';

-- ============================================================================
-- V10: Semantic type conditional NOT NULL includes 'person'
-- ============================================================================
-- Expected: constraint definition includes 'person' in the NOT IN list

SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND conname = 'qxb_artifact_semantic_type_required_for_top_level';

-- ============================================================================
-- V11: Insert + select round-trip test (Leaf 2.14–2.15)
-- ============================================================================
-- This test requires a valid spine row first. Run manually with a test artifact.
-- Template below — replace UUIDs with actual test values.
--
-- STEP A: Create spine row
--   INSERT INTO public.qxb_artifact (
--     artifact_id, workspace_id, owner_user_id, artifact_type,
--     title, priority, semantic_type_id
--   ) VALUES (
--     gen_random_uuid(),
--     'be0d3a48-c764-44f9-90c8-e846d9dbbd0a',  -- Prime workspace
--     'c52c7a57-74ad-433d-a07c-4dcac1778672',   -- Joel user_id
--     'person',
--     'Test Person — Validation',
--     3,
--     (SELECT semantic_type_id FROM qxb_semantic_type_registry WHERE key = 'product')
--   ) RETURNING artifact_id;
--
-- STEP B: Create extension row (use artifact_id from STEP A)
--   INSERT INTO public.qxb_artifact_person (
--     artifact_id, full_name, preferred_name, relationship_type,
--     key_facts, what_they_care_about
--   ) VALUES (
--     '<artifact_id_from_step_a>',
--     'Test Person',
--     'Testy',
--     'friend',
--     '["Likes coffee", "Morning person"]'::jsonb,
--     '["Productivity", "Design systems"]'::jsonb
--   );
--
-- STEP C: Verify hydrated query
--   SELECT a.artifact_id, a.artifact_type, a.title,
--          p.full_name, p.preferred_name, p.relationship_type,
--          p.key_facts, p.what_they_care_about
--   FROM public.qxb_artifact a
--   JOIN public.qxb_artifact_person p ON p.artifact_id = a.artifact_id
--   WHERE a.artifact_type = 'person';
--
-- STEP D: Cleanup (delete test artifact — cascade removes extension row)
--   DELETE FROM public.qxb_artifact WHERE artifact_id = '<artifact_id_from_step_a>';

-- ============================================================================
-- V12: List behavior — person appears in artifact.list results (Leaf 2.17)
-- ============================================================================
-- After V11 insert, verify:
--   SELECT artifact_id, artifact_type, title
--   FROM public.qxb_artifact
--   WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
--     AND artifact_type = 'person'
--     AND deleted_at IS NULL;
-- Expected: test person row appears.

-- ============================================================================
-- V13: PATCH — RLS enforcement test (Q audit finding)
-- ============================================================================
-- Ensures SELECT policy is actually restrictive, not just present.
-- This test requires two Supabase users in DIFFERENT workspaces.
--
-- To simulate:
--   1. Create a person artifact in workspace A (e.g., Prime: be0d3a48)
--   2. Query qxb_artifact_person as a user who is ONLY in workspace B
--   3. Expected: 0 rows returned (workspace isolation enforced)
--
-- Manual verification approach using Supabase SQL Editor:
--   -- As service_role (bypasses RLS), confirm the row exists:
--   SELECT count(*) FROM public.qxb_artifact_person;  -- should be >= 1
--
--   -- As an authenticated user NOT in the artifact's workspace:
--   -- (Use Supabase client SDK or set role + auth.uid() for testing)
--   -- Expected: 0 rows from qxb_artifact_person for artifacts outside their workspace
--
-- Alternatively, verify the policy definition includes workspace_user join:
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'qxb_artifact_person'
      AND policyname = 'qxb_artifact_person_select_via_artifact'
      AND qual LIKE '%qxb_workspace_user%'
  ) THEN
    RAISE EXCEPTION 'V13 FAIL: SELECT policy does not enforce workspace membership';
  END IF;
  RAISE NOTICE 'V13 PASS: SELECT policy includes workspace membership check';
END $$;

-- ============================================================================
-- V14: PATCH — JSONB array shape constraints exist (Q audit finding)
-- ============================================================================
-- Expected: 3 CHECK constraints enforcing jsonb_typeof = 'array'

SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact_person'::regclass
  AND conname LIKE '%_is_array'
ORDER BY conname;

-- Expected output:
--   qxb_artifact_person_key_facts_is_array
--   qxb_artifact_person_preferences_is_array
--   qxb_artifact_person_what_they_care_about_is_array
