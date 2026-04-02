-- =============================================================================
-- T150: Person Artifact Type — Rollback Migration v1.1
-- =============================================================================
-- Date:    2026-03-22
-- Thread:  T150 (Branch 2 — Supabase Schema & Data Model)
-- DDL:     v2.10 → v2.9 (reversal)
-- CHECK:   v8 → v7 (15 → 14 types, removes 'person')
--
-- WARNING: This will DROP qxb_artifact_person and all data in it.
-- WARNING: Any qxb_artifact rows with artifact_type='person' must be deleted
--          BEFORE running this rollback, or the CHECK constraint will fail.
--
-- Execution: Run in Supabase SQL Editor as a single transaction.
-- =============================================================================

BEGIN;

-- ============================================================================
-- STEP 0: Pre-validation — ensure no person artifacts exist
-- ============================================================================
-- If person artifacts exist, they must be deleted first (spine rows).
-- Extension rows will cascade-delete via FK.

DO $$
DECLARE
  _person_count integer;
BEGIN
  SELECT count(*) INTO _person_count
  FROM public.qxb_artifact
  WHERE artifact_type = 'person';
  IF _person_count > 0 THEN
    RAISE EXCEPTION 'Rollback BLOCKED: % person artifact(s) exist in qxb_artifact. Delete them first.', _person_count;
  END IF;
END $$;

-- ============================================================================
-- STEP 1: Drop RLS policies
-- ============================================================================

DROP POLICY IF EXISTS qxb_artifact_person_select_via_artifact ON public.qxb_artifact_person;
DROP POLICY IF EXISTS qxb_artifact_person_insert_owner_via_artifact ON public.qxb_artifact_person;
DROP POLICY IF EXISTS qxb_artifact_person_update_owner_or_admin ON public.qxb_artifact_person;

-- ============================================================================
-- STEP 2: Drop indexes
-- ============================================================================

DROP INDEX IF EXISTS public.idx_qxb_artifact_person_full_name;
DROP INDEX IF EXISTS public.idx_qxb_artifact_person_relationship_type;
DROP INDEX IF EXISTS public.idx_qxb_artifact_person_key_facts;
DROP INDEX IF EXISTS public.idx_qxb_artifact_person_what_they_care_about;
DROP INDEX IF EXISTS public.idx_qxb_artifact_person_preferences;
-- PATCH: added in v1.1
DROP INDEX IF EXISTS public.idx_qxb_artifact_person_last_contacted_at;

-- ============================================================================
-- STEP 3: Drop trigger
-- ============================================================================

DROP TRIGGER IF EXISTS qxb_artifact_person_set_updated_at ON public.qxb_artifact_person;

-- ============================================================================
-- STEP 4: Drop table
-- ============================================================================

DROP TABLE IF EXISTS public.qxb_artifact_person;

-- ============================================================================
-- STEP 5: Remove from type registry
-- ============================================================================

DELETE FROM public.qxb_artifact_type_registry
WHERE artifact_type = 'person';

-- ============================================================================
-- STEP 6: Restore semantic_type_id conditional NOT NULL CHECK
-- ============================================================================
-- Remove 'person' from the required list.

ALTER TABLE public.qxb_artifact
  DROP CONSTRAINT qxb_artifact_semantic_type_required_for_top_level;

ALTER TABLE public.qxb_artifact
  ADD CONSTRAINT qxb_artifact_semantic_type_required_for_top_level
  CHECK (
    (artifact_type NOT IN ('project', 'snapshot', 'journal', 'restart'))
    OR (semantic_type_id IS NOT NULL)
  );

-- ============================================================================
-- STEP 7: Restore CHECK constraint v7 (remove 'person')
-- ============================================================================

ALTER TABLE public.qxb_artifact
  DROP CONSTRAINT qxb_artifact_artifact_type_check_v8;

ALTER TABLE public.qxb_artifact
  ADD CONSTRAINT qxb_artifact_artifact_type_check_v7
  CHECK (artifact_type = ANY (ARRAY[
    'project'::text, 'journal'::text, 'restart'::text, 'snapshot'::text,
    'grass'::text, 'thorn'::text, 'forest'::text, 'thicket'::text, 'flower'::text,
    'branch'::text, 'leaf'::text, 'instruction_pack'::text, 'limb'::text, 'twig'::text
  ]));

COMMIT;
