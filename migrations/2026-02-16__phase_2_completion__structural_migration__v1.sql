-- ============================================================================
-- PHASE 2 COMPLETION — STRUCTURAL MIGRATION & ENFORCEMENT
-- ============================================================================
--
-- Migration:  2026-02-16__phase_2_completion__structural_migration__v1.sql
-- Author:     CC (Build Executor)
-- Plan:       Qwrk_Inbox/Phase_2_Completion_Plan__Structural_Migration_and_Enforcement__v1.md
-- Governing:  Governance Gate 765dcdfc, Phase 1 Sealed Snapshot a5dcf3bb
-- DDL Base:   LIVE_DDL__Kernel_v1__2026-01-04.sql (v2.2)
--
-- DECISIONS LOCKED (Session 2026-02-16__004):
--   Q1: Verification-first — do not assume project extension CHECK updated
--   Q2: Limb extension = shell only. execution_status stays on spine.
--   Q3: No branch/leaf extension tables this session.
--   Priority: universal NOT NULL with DEFAULT 3.
--   Block order: A → B → C
--
-- EXECUTION PROTOCOL:
--   1. Run SECTION 0 (Pre-Flight) — ALL queries must pass
--   2. Run SECTION 1 (Block A) — Verify results before proceeding
--   3. Run SECTION 2 (Block B) — Verify results before proceeding
--   4. Run SECTION 3 (Block C) — Verify results before proceeding
--   5. Run SECTION 4 (Post-Migration Verification)
--   6. Drop rollback snapshot table when satisfied
--
-- IMPORTANT: Run each section individually in Supabase SQL Editor.
--            DO NOT run the entire file at once.
-- ============================================================================


-- ############################################################################
-- SECTION 0: PRE-FLIGHT QUERIES
-- ############################################################################
-- Run ALL of these. Verify results match EXPECTED comments.
-- If ANY abort condition is triggered, STOP and investigate.


-- PF-1: Spine lifecycle_status CHECK exists
-- EXPECTED: 1 row with constraint containing (seed, sapling, tree, oak, archive) + NULL tolerance
-- ABORT IF: No rows returned (Phase 1 sealed state not applied)
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND contype = 'c'
  AND conname LIKE '%lifecycle%';


-- PF-2: Project extension lifecycle_stage CHECK values (answers Q1)
-- EXPECTED: Either {seed,sapling,tree,oak,archive} (Phase 1 updated)
--       OR: {seed,sapling,tree,retired} (Phase 1 did NOT update extension)
-- NOTE: Record the constraint name — needed for Block A conditional update
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact_project'::regclass
  AND contype = 'c'
  AND conname LIKE '%lifecycle_stage%';


-- PF-3: No retired values anywhere
-- EXPECTED: 0 rows returned
-- ABORT IF: Any rows (must migrate data before CHECK changes)
SELECT 'spine' AS source, lifecycle_status AS value, COUNT(*)
FROM qxb_artifact WHERE lifecycle_status = 'retired'
GROUP BY lifecycle_status
UNION ALL
SELECT 'extension' AS source, lifecycle_stage AS value, COUNT(*)
FROM qxb_artifact_project WHERE lifecycle_stage = 'retired'
GROUP BY lifecycle_stage;


-- PF-4: execution_status column exists and values are clean
-- EXPECTED: 1 row showing column exists (text, nullable)
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'qxb_artifact'
  AND column_name = 'execution_status';

-- EXPECTED: 0 rows (no invalid values)
-- ABORT IF: Any rows (invalid execution_status must be corrected first)
SELECT execution_status, COUNT(*)
FROM public.qxb_artifact
WHERE execution_status IS NOT NULL
  AND execution_status NOT IN ('not_started', 'in_progress', 'blocked', 'complete')
GROUP BY execution_status;


-- PF-5: Priority value inventory
-- EXPECTED: out_of_range_count = 0
-- ABORT IF: out_of_range_count > 0
-- NOTE: null_count tells you backfill scope for Block C
SELECT
  COUNT(*) AS total_artifacts,
  COUNT(*) FILTER (WHERE priority IS NULL) AS null_count,
  COUNT(*) FILTER (WHERE priority IS NOT NULL) AS non_null_count,
  COUNT(*) FILTER (WHERE priority IS NOT NULL AND (priority < 1 OR priority > 5)) AS out_of_range_count
FROM public.qxb_artifact;


-- PF-6: Non-project lifecycle_status contamination
-- EXPECTED: 0 rows (only projects should have lifecycle_status)
-- ABORT IF: Any rows (cross-contamination must be cleaned first)
SELECT artifact_type, lifecycle_status, COUNT(*)
FROM public.qxb_artifact
WHERE artifact_type != 'project'
  AND lifecycle_status IS NOT NULL
GROUP BY artifact_type, lifecycle_status;


-- PF-7: Branch/leaf artifact counts (informational)
-- No abort condition — just know the scope
SELECT artifact_type, COUNT(*),
  COUNT(*) FILTER (WHERE execution_status = 'not_started') AS exec_not_started,
  COUNT(*) FILTER (WHERE execution_status IS NULL) AS exec_null
FROM public.qxb_artifact
WHERE artifact_type IN ('branch', 'leaf')
GROUP BY artifact_type;


-- PF-8: Branch/leaf in type registry
-- EXPECTED: branch and leaf present with enabled = true, limb absent
SELECT artifact_type, enabled
FROM public.qxb_artifact_type_registry
WHERE artifact_type IN ('branch', 'leaf', 'limb');


-- ############################################################################
-- STOP: Review all pre-flight results before proceeding.
--
-- Abort conditions:
--   PF-1: No lifecycle CHECK on spine           → Phase 1 not sealed
--   PF-3: Any 'retired' values                  → Data migration needed first
--   PF-4: Invalid execution_status values        → Manual correction needed
--   PF-5: Out-of-range priority values           → Should be impossible (CHECK)
--   PF-6: Non-project types with lifecycle_status → Cross-contamination
--
-- Record from PF-2: Does project extension CHECK still contain 'retired'?
--   YES → Block A includes conditional CHECK update (run A.4)
--   NO  → Block A is verification-only (skip A.4)
-- ############################################################################


-- ############################################################################
-- SECTION 1: BLOCK A — LIFECYCLE RESIDUAL VERIFICATION & ALIGNMENT
-- ############################################################################
-- Purpose: Confirm Phase 1 sealed state. Conditionally update project
--          extension CHECK if it still references 'retired'.
-- Risk: LOW
-- Data modified: NONE (verification + additive constraint change only)


-- A.1 + A.2 + A.3: Already covered by PF-1, PF-2, PF-3 above.
-- If PF results confirm Phase 1 sealed AND project extension already updated:
--   → Skip A.4 entirely. Block A complete.


-- A.4: CONDITIONAL — Run ONLY if PF-2 showed {seed,sapling,tree,retired}
-- This dynamically finds and drops the old CHECK, then adds the new one.

-- A.4a: Verify zero retired rows in extension (safety gate before constraint change)
SELECT COUNT(*) AS retired_in_extension
FROM public.qxb_artifact_project
WHERE lifecycle_stage = 'retired';
-- MUST be 0. If > 0: ABORT — migrate data before changing constraint.

-- A.4b: Drop old CHECK and add new one
DO $$
DECLARE
  _conname text;
BEGIN
  -- Find the existing lifecycle_stage CHECK constraint
  SELECT conname INTO _conname
  FROM pg_constraint
  WHERE conrelid = 'public.qxb_artifact_project'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%lifecycle_stage%';

  IF _conname IS NULL THEN
    RAISE NOTICE 'No lifecycle_stage CHECK found on qxb_artifact_project — skipping drop';
  ELSE
    RAISE NOTICE 'Dropping constraint: %', _conname;
    EXECUTE format('ALTER TABLE public.qxb_artifact_project DROP CONSTRAINT %I', _conname);
  END IF;
END $$;

ALTER TABLE public.qxb_artifact_project
  ADD CONSTRAINT qxb_artifact_project_lifecycle_stage_check
  CHECK (lifecycle_stage = ANY (ARRAY[
    'seed'::text, 'sapling'::text, 'tree'::text, 'oak'::text, 'archive'::text
  ]));


-- A.VERIFY: Confirm Block A result
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact_project'::regclass
  AND contype = 'c'
  AND conname LIKE '%lifecycle_stage%';
-- EXPECTED: qxb_artifact_project_lifecycle_stage_check with {seed,sapling,tree,oak,archive}


-- ############################################################################
-- STOP: Verify Block A completed successfully before proceeding to Block B.
-- ############################################################################


-- ############################################################################
-- SECTION 2: BLOCK B — ARTIFACT TYPE EXPANSION (LIMB)
-- ############################################################################
-- Purpose: Add limb as first-class artifact type.
--          CHECK v5 → v6, registry entry, shell extension table + RLS.
-- Risk: LOW (fully additive, no existing data modified)
-- Data modified: NONE (new table, new constraint, new registry row)


-- B.1: Replace artifact_type CHECK (v5 → v6: add 'limb')
DO $$
DECLARE
  _conname text;
BEGIN
  SELECT conname INTO _conname
  FROM pg_constraint
  WHERE conrelid = 'public.qxb_artifact'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%artifact_type%';

  IF _conname IS NULL THEN
    RAISE EXCEPTION 'No artifact_type CHECK found on qxb_artifact — cannot proceed';
  END IF;

  RAISE NOTICE 'Dropping constraint: %', _conname;
  EXECUTE format('ALTER TABLE public.qxb_artifact DROP CONSTRAINT %I', _conname);
END $$;

ALTER TABLE public.qxb_artifact
  ADD CONSTRAINT qxb_artifact_artifact_type_check_v6
  CHECK (artifact_type = ANY (ARRAY[
    'project'::text, 'journal'::text, 'restart'::text, 'snapshot'::text,
    'grass'::text, 'thorn'::text, 'forest'::text, 'thicket'::text,
    'flower'::text, 'branch'::text, 'leaf'::text, 'instruction_pack'::text,
    'limb'::text
  ]));


-- B.2: INSERT limb into type registry
INSERT INTO public.qxb_artifact_type_registry (artifact_type, enabled, description)
VALUES (
  'limb',
  true,
  'Execution anatomy: organizational container for leaves within a branch. Shell extension table (execution state on spine).'
)
ON CONFLICT (artifact_type) DO NOTHING;


-- B.3: Verify branch, leaf, limb in registry
SELECT artifact_type, enabled, description
FROM public.qxb_artifact_type_registry
WHERE artifact_type IN ('branch', 'leaf', 'limb')
ORDER BY artifact_type;
-- EXPECTED: All 3 present with enabled = true


-- B.4: INSERT audit row for limb addition
INSERT INTO public.qxb_artifact_type_registry_audit
  (artifact_type, action, actor, old_enabled, new_enabled, reason)
VALUES (
  'limb',
  'created',
  'service_role',
  NULL,
  true,
  'Phase 2 Completion: limb added as first-class artifact type per Governance Gate 765dcdfc. Shell extension table — execution state on spine.'
);


-- B.5 + B.6: CREATE TABLE with PK + FK (shell extension)
CREATE TABLE public.qxb_artifact_limb (
    artifact_id uuid NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT qxb_artifact_limb_pkey
      PRIMARY KEY (artifact_id),

    CONSTRAINT qxb_artifact_limb_fk
      FOREIGN KEY (artifact_id)
      REFERENCES public.qxb_artifact(artifact_id)
      ON DELETE CASCADE
);

COMMENT ON TABLE public.qxb_artifact_limb IS
  'Limb type table extending qxb_artifact via PK=FK. Shell extension for class-table inheritance compliance. Execution state (execution_status, priority) tracked on spine. Phase 2 Completion (2026-02-16).';


-- B.7: Enable RLS
ALTER TABLE public.qxb_artifact_limb ENABLE ROW LEVEL SECURITY;


-- B.8: RLS policies (hardened pattern — matches video/instruction_pack from 2026-02-11)

-- SELECT: workspace member can read (via artifact existence in spine, which has its own RLS)
CREATE POLICY qxb_artifact_limb_select_via_artifact
  ON public.qxb_artifact_limb
  FOR SELECT TO authenticated
  USING ((EXISTS (
    SELECT 1 FROM public.qxb_artifact a
    WHERE a.artifact_id = qxb_artifact_limb.artifact_id
  )));

-- INSERT: owner only (via spine owner check)
CREATE POLICY qxb_artifact_limb_insert_owner_via_artifact
  ON public.qxb_artifact_limb
  FOR INSERT TO authenticated
  WITH CHECK ((EXISTS (
    SELECT 1 FROM public.qxb_artifact a
    WHERE a.artifact_id = qxb_artifact_limb.artifact_id
      AND a.owner_user_id = public.qxb_current_user_id()
  )));

-- UPDATE: owner or workspace admin
CREATE POLICY qxb_artifact_limb_update_owner_or_admin
  ON public.qxb_artifact_limb
  FOR UPDATE TO authenticated
  USING ((EXISTS (
    SELECT 1 FROM public.qxb_artifact a
    WHERE a.artifact_id = qxb_artifact_limb.artifact_id
      AND (
        a.owner_user_id = public.qxb_current_user_id()
        OR EXISTS (
          SELECT 1 FROM public.qxb_workspace_user wsu
          WHERE wsu.workspace_id = a.workspace_id
            AND wsu.user_id = public.qxb_current_user_id()
            AND wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])
        )
      )
  )))
  WITH CHECK ((EXISTS (
    SELECT 1 FROM public.qxb_artifact a
    WHERE a.artifact_id = qxb_artifact_limb.artifact_id
      AND (
        a.owner_user_id = public.qxb_current_user_id()
        OR EXISTS (
          SELECT 1 FROM public.qxb_workspace_user wsu
          WHERE wsu.workspace_id = a.workspace_id
            AND wsu.user_id = public.qxb_current_user_id()
            AND wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])
        )
      )
  )));


-- B.9: updated_at trigger
CREATE TRIGGER qxb_artifact_limb_set_updated_at
  BEFORE UPDATE ON public.qxb_artifact_limb
  FOR EACH ROW
  EXECUTE FUNCTION public.qxb_set_updated_at();


-- B.VERIFY: Confirm Block B results
-- Check artifact_type CHECK v6
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND contype = 'c'
  AND conname LIKE '%artifact_type%';
-- EXPECTED: qxb_artifact_artifact_type_check_v6 with 13 types including 'limb'

-- Check limb table exists with RLS
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'qxb_artifact_limb';
-- EXPECTED: 1 row, rowsecurity = true

-- Check limb RLS policies
SELECT policyname, cmd
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'qxb_artifact_limb'
ORDER BY policyname;
-- EXPECTED: 3 policies (INSERT, SELECT, UPDATE)

-- Check limb in registry
SELECT artifact_type, enabled
FROM public.qxb_artifact_type_registry
WHERE artifact_type = 'limb';
-- EXPECTED: limb, true


-- ############################################################################
-- STOP: Verify Block B completed successfully before proceeding to Block C.
-- ############################################################################


-- ############################################################################
-- SECTION 3: BLOCK C — EXECUTION ENFORCEMENT (STATUS + PRIORITY)
-- ############################################################################
-- Purpose: Add CHECK on execution_status. Backfill priority NULLs → 3.
--          Add DEFAULT 3 + NOT NULL on priority.
-- Risk: MEDIUM (C.5 backfill modifies existing data)
-- Data modified: All rows with NULL priority get priority = 3


-- C.1: Pre-flight — invalid execution_status values
-- EXPECTED: 0 rows
-- ABORT IF: Any rows returned
SELECT execution_status, COUNT(*)
FROM public.qxb_artifact
WHERE execution_status IS NOT NULL
  AND execution_status NOT IN ('not_started', 'in_progress', 'blocked', 'complete')
GROUP BY execution_status;


-- C.2: Pre-flight — NULL priority count (informational)
SELECT COUNT(*) AS null_priority_count
FROM public.qxb_artifact
WHERE priority IS NULL;


-- C.3: Pre-flight — out-of-range priority
-- EXPECTED: 0
-- ABORT IF: > 0
SELECT COUNT(*) AS out_of_range_count
FROM public.qxb_artifact
WHERE priority IS NOT NULL AND (priority < 1 OR priority > 5);


-- C.SNAPSHOT: Capture pre-backfill state for rollback safety
-- This records every artifact_id that currently has NULL priority.
-- Keep this table until post-migration verification passes.
CREATE TABLE IF NOT EXISTS public._migration_priority_null_snapshot (
    artifact_id  uuid NOT NULL,
    captured_at  timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public._migration_priority_null_snapshot (artifact_id)
SELECT artifact_id
FROM public.qxb_artifact
WHERE priority IS NULL;

-- Verify snapshot captured
SELECT COUNT(*) AS snapshot_row_count
FROM public._migration_priority_null_snapshot;
-- Should match C.2 null_priority_count


-- C.4: Add execution_status CHECK on spine
-- Allows NULL (non-execution types) OR one of the 4 locked values
ALTER TABLE public.qxb_artifact
  ADD CONSTRAINT qxb_artifact_execution_status_check
  CHECK (
    execution_status IS NULL
    OR execution_status = ANY (ARRAY[
      'not_started'::text, 'in_progress'::text, 'blocked'::text, 'complete'::text
    ])
  );


-- C.5: Backfill priority NULLs → 3
-- WARNING: This modifies existing data. Rollback requires _migration_priority_null_snapshot.
UPDATE public.qxb_artifact
SET priority = 3
WHERE priority IS NULL;


-- C.6: Add priority DEFAULT 3 (for future INSERTs)
ALTER TABLE public.qxb_artifact
  ALTER COLUMN priority SET DEFAULT 3;


-- C.7: Add priority NOT NULL
-- Safe because C.5 backfilled all NULLs and C.6 sets default for future inserts.
ALTER TABLE public.qxb_artifact
  ALTER COLUMN priority SET NOT NULL;


-- C.VERIFY: Confirm Block C results
-- execution_status CHECK
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND contype = 'c'
  AND conname LIKE '%execution_status%';
-- EXPECTED: qxb_artifact_execution_status_check with NULL + 4 values

-- priority enforcement
SELECT column_name, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'qxb_artifact'
  AND column_name = 'priority';
-- EXPECTED: column_default contains '3', is_nullable = 'NO'

-- Zero NULL priorities
SELECT COUNT(*) AS null_priority FROM public.qxb_artifact WHERE priority IS NULL;
-- EXPECTED: 0

-- Zero out-of-range priorities
SELECT COUNT(*) AS bad_priority
FROM public.qxb_artifact
WHERE priority < 1 OR priority > 5;
-- EXPECTED: 0


-- ############################################################################
-- STOP: Verify Block C completed successfully before running full verification.
-- ############################################################################


-- ############################################################################
-- SECTION 4: POST-MIGRATION VERIFICATION (V-1 through V-8)
-- ############################################################################
-- Run all of these to confirm complete migration success.


-- V-1: Spine lifecycle CHECK (Phase 1 sealed — still intact)
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND contype = 'c'
  AND conname LIKE '%lifecycle%';
-- MUST contain: seed, sapling, tree, oak, archive + NULL tolerance


-- V-2: No retired values anywhere
SELECT 'spine' AS source, COUNT(*) AS retired_count
FROM public.qxb_artifact WHERE lifecycle_status = 'retired'
UNION ALL
SELECT 'extension', COUNT(*)
FROM public.qxb_artifact_project WHERE lifecycle_stage = 'retired';
-- BOTH must be 0


-- V-3: artifact_type CHECK v6 with 13 types
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND contype = 'c'
  AND conname LIKE '%artifact_type%';
-- MUST include all 13: project, journal, restart, snapshot, grass, thorn,
--   forest, thicket, flower, branch, leaf, instruction_pack, limb


-- V-4: Limb in type registry
SELECT artifact_type, enabled
FROM public.qxb_artifact_type_registry
WHERE artifact_type = 'limb';
-- MUST return 1 row with enabled = true


-- V-5: Limb extension table exists with RLS + 3 policies
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'qxb_artifact_limb';
-- MUST return 1 row with rowsecurity = true

SELECT COUNT(*) AS policy_count
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'qxb_artifact_limb';
-- MUST be 3


-- V-6: execution_status CHECK on spine
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND contype = 'c'
  AND conname LIKE '%execution_status%';
-- MUST contain: not_started, in_progress, blocked, complete + NULL tolerance


-- V-7: Priority enforcement
SELECT column_name, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'qxb_artifact'
  AND column_name = 'priority';
-- column_default MUST contain '3', is_nullable MUST be 'NO'

SELECT COUNT(*) AS null_priority FROM public.qxb_artifact WHERE priority IS NULL;
-- MUST be 0

SELECT COUNT(*) AS bad_range
FROM public.qxb_artifact WHERE priority < 1 OR priority > 5;
-- MUST be 0


-- V-8: Comprehensive data validation
-- No invalid execution_status values
SELECT COUNT(*) AS bad_exec_status
FROM public.qxb_artifact
WHERE execution_status IS NOT NULL
  AND execution_status NOT IN ('not_started', 'in_progress', 'blocked', 'complete');
-- MUST be 0

-- No invalid lifecycle_status values
SELECT COUNT(*) AS bad_lifecycle
FROM public.qxb_artifact
WHERE lifecycle_status IS NOT NULL
  AND lifecycle_status NOT IN ('seed', 'sapling', 'tree', 'oak', 'archive');
-- MUST be 0

-- All CHECKs on spine (complete inventory)
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.qxb_artifact'::regclass
  AND contype = 'c'
ORDER BY conname;
-- Should show: artifact_type v6, execution_status, lifecycle_status, priority range


-- ############################################################################
-- POST-MIGRATION: CLEANUP
-- ############################################################################
-- Once all verification passes and you are satisfied:
--
-- DROP TABLE IF EXISTS public._migration_priority_null_snapshot;
--
-- Then update DDL file to v2.3 reflecting all live changes.
-- ############################################################################
