--
-- Qwrk Kernel v1 — Live DDL Reference
-- Project: npymhacpmxdnkqdzgxll (Supabase)
-- Database: PostgreSQL 17.6
--
-- CHANGELOG:
--   v2.10 (2026-03-22): T150 Person Artifact Type — Branch 2 Schema.
--     - artifact_type CHECK v7 -> v8: added 'person' (15 types total)
--     - New table: qxb_artifact_person (full extension, PK=FK, 27 columns)
--       Identity: full_name, preferred_name, relationship_type, status, pronouns
--       Contact: personal_email, work_email, mobile_phone, work_phone, home_phone,
--         preferred_contact_method, preferred_contact_channel, timezone
--       Professional: company, title, department, importance_level
--       Interaction: interaction_frequency, last_contacted_at, next_follow_up_at, do_not_contact
--       JSONB: address, communication_style, what_they_care_about, key_facts, preferences
--     - 3 JSONB array shape CHECKs: key_facts, what_they_care_about, preferences
--       (jsonb_typeof = 'array' or NULL)
--     - semantic_type_required_for_top_level CHECK updated: 'person' added to required list
--     - Type registry entry: person (enabled, has extension)
--     - RLS: 3 policies (SELECT workspace-member via join, INSERT owner, UPDATE owner/admin)
--       SELECT policy uses workspace_user join (not spine-only) per Q audit
--     - Indexes: full_name (btree), relationship_type (btree), last_contacted_at (btree partial),
--       key_facts (GIN partial), what_they_care_about (GIN partial), preferences (GIN partial)
--     - Trigger: updated_at via shared qxb_set_updated_at()
--     - No new semantic type created (person uses existing registry values)
--     - Migration: migrations/2026-03-22__person_artifact_type__v1.sql (v1.1 patched)
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.9__2026-03-22.sql
--
--   v2.9 (2026-03-07): T80 Security Advisor Fixes.
--     - qxb_artifact_rollup_view: added WITH (security_invoker = true)
--       Ensures view runs with caller permissions, not creator permissions.
--     - qxb_artifact_dependency: RLS + 3 policies were in DDL but missing from
--       live DB (T71 drift). Now confirmed deployed. No DDL text change needed.
--     - _migration_priority_null_snapshot: dropped (leftover migration table).
--       Removed from DDL (was never in DDL -- no text change needed).
--     - RLS initplan optimization: 4 policies updated to use (select auth.uid())
--       instead of auth.uid() for per-query evaluation instead of per-row.
--       Tables: qxb_user (2 policies), qxb_workspace (1), qxb_workspace_user (1).
--     - Migration: migrations/2026-03-07__t80_security_advisor_fixes__v1.sql
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.8__2026-03-06.sql
--
--   v2.8 (2026-03-06): T94 Twig artifact type activation.
--     - artifact_type CHECK v6 -> v7: added 'twig' (14 types total)
--     - New conditional CHECK: qxb_artifact_twig_lifecycle_check
--       Enforces: proposed, active, promoted, pruned (twig-only)
--     - Type registry entry: twig (enabled)
--     - Semantic type registry entry: twig (active)
--     - No extension table (Option A -- leaf precedent)
--     - Pilot: Mother Tree only
--     - Migration: migrations/2026-03-06__twig_artifact_type_activation__v1.sql
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.7__2026-03-06.sql
--
--   v2.7 (2026-03-06): T87 gap closure — design_spine column on qxb_artifact_project.
--     - New column: qxb_artifact_project.design_spine (jsonb, nullable, no default)
--     - Workflow + mutability registry already deployed in T87 (Check_Mutability_Rules v8)
--     - Column was missing from DB while Gateway accepted the field (silently discarded)
--     - Phase2C D20-D23 tests already cover design_spine lifecycle behavior
--     - Migration: migrations/2026-03-06__design_spine_column__v1.sql
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.6__2026-03-06.sql
--
--   v2.6 (2026-03-03): T69 Semantic Type Registry + T70 Rollup VIEW.
--     - T69: New table: qxb_semantic_type_registry (controlled vocabulary, 9 bootstrapped values)
--       PK: semantic_type_id. UNIQUE on key. Self-ref FK (parent_id). FK to qxb_artifact (governance_snapshot_id).
--       RLS enabled, 1 SELECT policy (authenticated). No write policies (service_role only).
--     - T69: New table: qxb_semantic_type_audit (append-only classification change log)
--       PK: id. FKs: artifact_id, old/new semantic_type_id. Index on (artifact_id, created_at DESC).
--       RLS enabled, 1 SELECT policy (authenticated). Triggers block UPDATE/DELETE.
--     - T69: New column: qxb_artifact.semantic_type_id (uuid, FK to registry, ON DELETE RESTRICT)
--       Conditional NOT NULL CHECK: top-level types (project/snapshot/journal/restart) must NOT be NULL.
--       Partial index: idx_qxb_artifact_semantic_type WHERE semantic_type_id IS NOT NULL.
--     - T69: New function: update_semantic_type(uuid, uuid, text, uuid) — atomic semantic type
--       update + audit insert. SECURITY DEFINER, SET search_path = public. Validates: artifact
--       exists, is top-level, new type is active, reason non-empty. Increments version.
--     - T70: New VIEW: qxb_artifact_rollup_view — completion percentage for project/branch/limb.
--       Inherits RLS from qxb_artifact. T69 adds semantic_type_id to GROUP BY.
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.5__2026-03-04.sql
--
--   v2.5 (2026-03-01): T71 Dependency Enforcement — table + RPC function.
--     - New table: qxb_artifact_dependency (many-to-many leaf-to-leaf dependencies)
--       PK: dependency_id. FKs: artifact_id, depends_on_artifact_id -> qxb_artifact.
--       Self-ref CHECK. RLS enabled, 3 policies (SELECT/INSERT member, DELETE owner/admin).
--       No UPDATE policy — dependencies are immutable (create or delete only).
--     - New function: check_leaf_dependencies(uuid, uuid) — RPC for Update workflow
--       SECURITY DEFINER, SET search_path = public. Returns first incomplete dependency.
--     - New indexes: idx_qxb_artifact_dependency_source, idx_qxb_artifact_dependency_target
--     - DESIGN NOTE: Phase 2B design doc used source_artifact_id/target_artifact_id.
--       Live table column names to be verified by Joel before deployment.
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.4__2026-03-01.sql
--
--   v2.4 (2026-02-20): Inline search_path hardening (C2).
--     - Added SET search_path = public to all 3 DDL-defined functions:
--       qxb_current_user_id(), qxb_block_update_delete(), qxb_set_updated_at()
--     - Hardening now inline in CREATE FUNCTION definitions (self-contained)
--     - Post-creation ALTER FUNCTION in migration 2026-02-11 is now redundant for these 3
--     - No function logic, signatures, or RLS policies changed
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.3__2026-02-20.sql
--
--   v2.3 (2026-02-16): Phase 2 Completion — Structural Migration & Enforcement.
--     - spine lifecycle_status CHECK: conditional (project-only), values {seed,sapling,tree,archive}
--     - execution_status column added to spine (text, nullable, with CHECK)
--     - priority changed from nullable to NOT NULL with DEFAULT 3
--     - artifact_type CHECK v5 → v6: added 'limb' (13 types total)
--     - qxb_artifact_project lifecycle_stage CHECK: {seed,sapling,tree,retired} → {seed,sapling,tree,archive}
--     - New table: qxb_artifact_limb (shell extension, PK=FK, RLS enabled, 3 policies)
--     - New type registry entry: limb (enabled)
--     - execution_status CHECK: IS NULL OR IN (not_started, in_progress, blocked, complete)
--     - Migration: migrations/2026-02-16__phase_2_completion__structural_migration__v1.sql
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.2__2026-02-16.sql
--
--   v2.2 (2026-02-11): RLS reconciliation after Supabase Linter Hardening.
--     - RLS VERIFIED on ALL 16 qxb_* tables (C7 verification query)
--     - Added RLS policies for qxb_artifact_video (3), qxb_artifact_instruction_pack (3)
--     - qxb_gateway_acl: RLS enabled, deny-all (0 policies, service_role only)
--     - Removed [NEEDS VERIFICATION] markers for RLS on 5 tables
--     - Triggers/indexes for newer tables still [NEEDS VERIFICATION] (T27)
--     - Migration: migrations/2026-02-11__supabase_linter_hardening__v1.0.sql
--     - Snapshot: 0caf807a-db9f-45ff-9c1d-07e91f6b8f25
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.1__2026-02-11.sql
--
--   v2.1 (2026-02-09): Verified CHECK constraints from live DB (Query 1).
--     - artifact_type CHECK updated to v5: added branch, leaf, instruction_pack (video NOT in CHECK)
--     - Converted file from UTF-16LE to UTF-8
--
--   v2 (2026-02-09): Refreshed from live PostgREST OpenAPI + original pg_dump.
--     - Added 4 new tables: qxb_artifact_instruction_pack, qxb_artifact_type_registry,
--       qxb_artifact_type_registry_audit, qxb_gateway_acl
--     - RLS policies/triggers/indexes for new tables marked [NEEDS VERIFICATION]
--     - Previous version: Archive/LIVE_DDL__Kernel_v1__2026-01-04__v1__2026-02-09.sql
--
--   v1 (2026-01-04): Original pg_dump export. 12 tables.
--
-- VERIFICATION STATUS:
--   [VERIFIED]            = Present in original pg_dump (2026-01-04) AND confirmed in live OpenAPI (2026-02-09)
--   [LIVE-ONLY]           = Present in live OpenAPI (2026-02-09) but NOT in original pg_dump
--   [RLS VERIFIED 2026-02-11] = RLS enablement and policies confirmed via Supabase linter + verification queries
--   [NEEDS VERIFICATION]  = Reconstructed from OpenAPI; triggers/indexes unknown
--

-- ============================================================================
-- FUNCTIONS (from original pg_dump)
-- ============================================================================

-- Helper: map auth.uid() to qxb_user.user_id
-- [VERIFIED] - used by all RLS policies
CREATE OR REPLACE FUNCTION public.qxb_current_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT user_id FROM public.qxb_user WHERE auth_user_id = auth.uid()
$$;

-- Helper: block UPDATE/DELETE on append-only tables
-- [VERIFIED] - used by event log triggers
CREATE OR REPLACE FUNCTION public.qxb_block_update_delete()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION 'UPDATE and DELETE are not allowed on this table';
END;
$$;

-- Helper: auto-set updated_at on UPDATE
-- [VERIFIED] - used by multiple table triggers
CREATE OR REPLACE FUNCTION public.qxb_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- T71: RPC function for dependency enforcement (Update sub-workflow)
-- Returns first incomplete dependency for a leaf artifact.
-- 0 rows = all deps complete (or no deps). 1 row = blocker (LIMIT 1).
-- Called via POST /rest/v1/rpc/check_leaf_dependencies
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

-- T69: Atomic semantic type update + audit insert
-- Validates: artifact exists, is top-level, new type is active, reason non-empty.
-- Increments version. Inserts audit row. Fail-closed.
-- Called via POST /rest/v1/rpc/update_semantic_type
CREATE OR REPLACE FUNCTION public.update_semantic_type(
    p_artifact_id uuid,
    p_new_semantic_type_id uuid,
    p_reason text,
    p_actor_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_artifact record;
    v_old_semantic_type_id uuid;
    v_registry_active boolean;
    v_new_version integer;
    v_top_level_types text[] := ARRAY['project', 'snapshot', 'journal', 'restart'];
BEGIN
    -- 1. Validate reason is non-empty
    IF p_reason IS NULL OR length(trim(p_reason)) = 0 THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'VALIDATION_ERROR',
                'message', 'reason is required and must be non-empty'
            )
        );
    END IF;

    -- 2. Fetch artifact (existence + type + current semantic_type_id)
    SELECT artifact_id, artifact_type, semantic_type_id, owner_user_id
    INTO v_artifact
    FROM public.qxb_artifact
    WHERE artifact_id = p_artifact_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'NOT_FOUND',
                'message', 'Artifact not found',
                'details', jsonb_build_object('artifact_id', p_artifact_id)
            )
        );
    END IF;

    -- 3. Validate artifact is a top-level type
    IF NOT (v_artifact.artifact_type = ANY(v_top_level_types)) THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'SEMANTIC_TYPE_NOT_APPLICABLE',
                'message', 'semantic_type_id applies only to top-level artifact types',
                'details', jsonb_build_object(
                    'artifact_id', p_artifact_id,
                    'artifact_type', v_artifact.artifact_type,
                    'allowed_types', to_jsonb(v_top_level_types)
                )
            )
        );
    END IF;

    -- 4. Validate new semantic type exists and is active
    SELECT active INTO v_registry_active
    FROM public.qxb_semantic_type_registry
    WHERE semantic_type_id = p_new_semantic_type_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'INVALID_SEMANTIC_TYPE',
                'message', 'semantic_type_id not found in registry',
                'details', jsonb_build_object(
                    'semantic_type_id', p_new_semantic_type_id
                )
            )
        );
    END IF;

    IF NOT v_registry_active THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'SEMANTIC_TYPE_INACTIVE',
                'message', 'Target semantic type is inactive in registry',
                'details', jsonb_build_object(
                    'semantic_type_id', p_new_semantic_type_id
                )
            )
        );
    END IF;

    -- 5. Capture old value
    v_old_semantic_type_id := v_artifact.semantic_type_id;

    -- 6. No-op detection (same value = skip mutation)
    IF v_old_semantic_type_id IS NOT DISTINCT FROM p_new_semantic_type_id THEN
        RETURN jsonb_build_object(
            'ok', true,
            'noop', true,
            'message', 'semantic_type_id unchanged'
        );
    END IF;

    -- 7. ATOMIC: Update spine (semantic_type_id + version increment)
    UPDATE public.qxb_artifact
    SET semantic_type_id = p_new_semantic_type_id,
        version = version + 1
    WHERE artifact_id = p_artifact_id
    RETURNING version INTO v_new_version;

    -- 8. ATOMIC: Insert audit row (same transaction as step 7)
    INSERT INTO public.qxb_semantic_type_audit (
        artifact_id,
        old_semantic_type_id,
        new_semantic_type_id,
        reason,
        actor_id,
        created_at
    ) VALUES (
        p_artifact_id,
        v_old_semantic_type_id,
        p_new_semantic_type_id,
        trim(p_reason),
        COALESCE(p_actor_id, v_artifact.owner_user_id),
        now()
    );

    -- 9. Return success
    RETURN jsonb_build_object(
        'ok', true,
        'artifact_id', p_artifact_id,
        'old_semantic_type_id', v_old_semantic_type_id,
        'new_semantic_type_id', p_new_semantic_type_id,
        'version', v_new_version
    );
END;
$$;

COMMENT ON FUNCTION public.update_semantic_type(uuid, uuid, text, uuid) IS 'T69: Atomic semantic type update + audit. Validates: artifact exists, is top-level, new type is active, reason non-empty. Increments version. Inserts audit row. Fail-closed. Called via POST /rest/v1/rpc/update_semantic_type.';


-- ============================================================================
-- TABLE: qxb_user [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_user (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    auth_user_id uuid NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    display_name text,
    email text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT qxb_user_status_check CHECK ((status = ANY (ARRAY['active'::text, 'disabled'::text])))
);

COMMENT ON TABLE public.qxb_user IS 'Kernel v1 identity table. Maps Supabase auth.users to Qwrk user identity. RLS is enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_workspace [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_workspace (
    workspace_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_workspace IS 'Kernel v1 workspace table. System is workspace-first; every artifact requires workspace_id. RLS enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_workspace_user [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_workspace_user (
    workspace_user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text DEFAULT 'member'::text NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT qxb_workspace_user_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'member'::text])))
);

COMMENT ON TABLE public.qxb_workspace_user IS 'Kernel v1 workspace membership table. Maps users to workspaces with role-based access. RLS enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_artifact (spine) [VERIFIED]
-- ============================================================================
-- [VERIFIED 2026-02-09] CHECK constraints confirmed from live DB.
-- [UPDATED 2026-02-16] Phase 2 Completion: execution_status added, priority NOT NULL DEFAULT 3,
--   artifact_type CHECK v6 (13 types), lifecycle_status CHECK, execution_status CHECK.
-- [UPDATED 2026-03-06] T94: artifact_type CHECK v7 (14 types, twig added), twig lifecycle CHECK.
-- [UPDATED 2026-03-22] T150: artifact_type CHECK v8 (15 types, person added). semantic_type_required updated.
-- [UPDATED 2026-03-03] T69: semantic_type_id column + conditional NOT NULL CHECK.
-- NOTE: 'video' is NOT in the CHECK despite qxb_artifact_video table existing.

CREATE TABLE public.qxb_artifact (
    artifact_id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_id uuid NOT NULL,
    owner_user_id uuid NOT NULL,
    artifact_type text NOT NULL,
    title text NOT NULL,
    summary text,
    priority integer DEFAULT 3 NOT NULL,
    lifecycle_status text,
    execution_status text,
    semantic_type_id uuid,
    tags jsonb,
    content jsonb,
    parent_artifact_id uuid,
    version integer DEFAULT 1 NOT NULL,
    deleted_at timestamptz,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT qxb_artifact_artifact_type_check_v8 CHECK ((artifact_type = ANY (ARRAY['project'::text, 'journal'::text, 'restart'::text, 'snapshot'::text, 'grass'::text, 'thorn'::text, 'forest'::text, 'thicket'::text, 'flower'::text, 'branch'::text, 'leaf'::text, 'instruction_pack'::text, 'limb'::text, 'twig'::text, 'person'::text]))),
    CONSTRAINT qxb_artifact_priority_check CHECK (((priority >= 1) AND (priority <= 5))),
    CONSTRAINT qxb_artifact_lifecycle_status_check CHECK (((artifact_type <> 'project'::text) OR (lifecycle_status = ANY (ARRAY['seed'::text, 'sapling'::text, 'tree'::text, 'archive'::text])))),
    CONSTRAINT qxb_artifact_execution_status_check CHECK ((execution_status IS NULL OR (execution_status = ANY (ARRAY['not_started'::text, 'in_progress'::text, 'blocked'::text, 'complete'::text])))),
    CONSTRAINT qxb_artifact_twig_lifecycle_check CHECK (((artifact_type <> 'twig'::text) OR (lifecycle_status = ANY (ARRAY['proposed'::text, 'active'::text, 'promoted'::text, 'pruned'::text])))),
    CONSTRAINT qxb_artifact_semantic_type_required_for_top_level CHECK (((artifact_type NOT IN ('project', 'snapshot', 'journal', 'restart', 'person')) OR (semantic_type_id IS NOT NULL)))
);

COMMENT ON TABLE public.qxb_artifact IS 'Kernel v1 canonical spine. All record types spawn from this table and extend via PK=FK class-table inheritance. RLS enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_artifact_event [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_artifact_event (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_id uuid NOT NULL,
    artifact_id uuid NOT NULL,
    actor_user_id uuid,
    event_type text NOT NULL,
    event_ts timestamptz DEFAULT now() NOT NULL,
    payload jsonb,
    created_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_artifact_event IS 'Append-only event log for artifacts (explainability/audit). RLS enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_artifact_project [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_artifact_project (
    artifact_id uuid NOT NULL,
    lifecycle_stage text NOT NULL,
    operational_state text DEFAULT 'active'::text NOT NULL,
    state_reason text,
    design_spine jsonb,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT qxb_artifact_project_lifecycle_stage_check CHECK ((lifecycle_stage = ANY (ARRAY['seed'::text, 'sapling'::text, 'tree'::text, 'archive'::text]))),
    CONSTRAINT qxb_artifact_project_operational_state_check CHECK ((operational_state = ANY (ARRAY['active'::text, 'paused'::text, 'blocked'::text, 'waiting'::text])))
);

COMMENT ON TABLE public.qxb_artifact_project IS 'Project type table extending qxb_artifact. Enforces lifecycle + operational state. Transitions enforced at Gateway layer. RLS enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_artifact_journal [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_artifact_journal (
    artifact_id uuid NOT NULL,
    entry_text text,
    payload jsonb,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_artifact_journal IS 'Journal type table extending qxb_artifact. Owner-private by default (policy later). RLS enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_artifact_snapshot [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_artifact_snapshot (
    artifact_id uuid NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_artifact_snapshot IS 'Snapshot type table extending qxb_artifact. Immutable lifecycle-only snapshot payload stored inline as jsonb. RLS enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_artifact_restart [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_artifact_restart (
    artifact_id uuid NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_artifact_restart IS 'Restart type table extending qxb_artifact. Manual, ad-hoc, immutable payload stored inline as jsonb. RLS enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_artifact_video [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_artifact_video (
    artifact_id uuid NOT NULL,
    source_url text NOT NULL,
    source_platform text DEFAULT 'youtube'::text NOT NULL,
    source_video_id text,
    source_channel text,
    source_published_at timestamptz,
    duration_seconds integer,
    status text DEFAULT 'queued'::text NOT NULL,
    idempotency_key text NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    error jsonb,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT qxb_artifact_video_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'downloading'::text, 'chunking'::text, 'transcribing'::text, 'stitching'::text, 'saving'::text, 'complete'::text, 'failed'::text])))
);

COMMENT ON TABLE public.qxb_artifact_video IS 'Video type table extending qxb_artifact. Long-form media artifacts with transcript and derived insights. RLS enabled; policies added later (deny-by-default).';

-- ============================================================================
-- TABLE: qxb_artifact_grass [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_artifact_grass (
    artifact_id uuid NOT NULL,
    source_system text DEFAULT 'n8n'::text NOT NULL,
    source_workflow text,
    source_execution_id text,
    detected_at timestamptz DEFAULT now() NOT NULL,
    review_status text DEFAULT 'unreviewed'::text NOT NULL,
    summary text NOT NULL,
    details_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    disposition text DEFAULT 'none'::text NOT NULL,
    reviewed_at timestamptz,
    CONSTRAINT qxb_artifact_grass_disposition_check CHECK ((disposition = ANY (ARRAY['none'::text, 'promoted_to_flower'::text, 'dismissed'::text]))),
    CONSTRAINT qxb_artifact_grass_review_status_check CHECK ((review_status = ANY (ARRAY['unreviewed'::text, 'reviewed'::text, 'dismissed'::text])))
);

-- ============================================================================
-- TABLE: qxb_artifact_thorn [VERIFIED]
-- ============================================================================

CREATE TABLE public.qxb_artifact_thorn (
    artifact_id uuid NOT NULL,
    source_system text DEFAULT 'n8n'::text NOT NULL,
    source_workflow text,
    source_execution_id text,
    detected_at timestamptz DEFAULT now() NOT NULL,
    severity integer DEFAULT 3 NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    summary text NOT NULL,
    details_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    resolution_notes text,
    resolved_at timestamptz,
    CONSTRAINT qxb_artifact_thorn_severity_check CHECK (((severity >= 1) AND (severity <= 5))),
    CONSTRAINT qxb_artifact_thorn_status_check CHECK ((status = ANY (ARRAY['open'::text, 'acknowledged'::text, 'resolved'::text, 'ignored'::text])))
);

-- ============================================================================
-- TABLE: qxb_artifact_instruction_pack [LIVE-ONLY] [RLS VERIFIED 2026-02-11]
-- ============================================================================
-- Reconstructed from PostgREST OpenAPI on 2026-02-09.
-- RLS: Enabled with 3 policies (SELECT/INSERT/UPDATE via spine delegation).
-- Triggers/indexes: [NEEDS VERIFICATION] (T27).

CREATE TABLE public.qxb_artifact_instruction_pack (
    artifact_id uuid NOT NULL,
    workspace_id uuid,
    scope text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    pack_format text DEFAULT 'json'::text NOT NULL,
    created_by_source text,
    approved_at timestamptz,
    checksum_sha256 text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_artifact_instruction_pack IS 'Instruction pack extension table. Extends qxb_artifact via PK=FK. Stores system instruction metadata for Q execution surface.';

-- ============================================================================
-- TABLE: qxb_artifact_limb [2026-02-16] [Phase 2 Completion]
-- ============================================================================
-- Shell extension table for limb artifact type (execution anatomy).
-- Execution state (execution_status, priority) tracked on spine, not here.
-- Created during Phase 2 Completion migration per Governance Gate 765dcdfc.

CREATE TABLE public.qxb_artifact_limb (
    artifact_id uuid NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.qxb_artifact_limb IS 'Limb type table extending qxb_artifact via PK=FK. Shell extension for class-table inheritance compliance. Execution state (execution_status, priority) tracked on spine. Phase 2 Completion (2026-02-16).';

-- ============================================================================
-- TABLE: qxb_artifact_person [2026-03-22] [T150 Person Artifact Type]
-- ============================================================================
-- Full extension table for person artifact type.
-- Stores identity, contact, professional context, interaction tracking,
-- and communication intelligence for real individuals in the operator's network.
-- JSONB array fields (key_facts, what_they_care_about, preferences) have shape CHECKs.
-- RLS SELECT uses workspace_user join (not spine-only) per Q audit.

CREATE TABLE public.qxb_artifact_person (
    artifact_id                uuid        NOT NULL,
    full_name                  text        NOT NULL,
    preferred_name             text        NOT NULL,
    relationship_type          text        NOT NULL,
    status                     text        NOT NULL DEFAULT 'active',
    pronouns                   text,
    personal_email             text,
    work_email                 text,
    mobile_phone               text,
    work_phone                 text,
    home_phone                 text,
    preferred_contact_method   text,
    preferred_contact_channel  text,
    timezone                   text,
    company                    text,
    title                      text,
    department                 text,
    importance_level           text,
    interaction_frequency      text,
    last_contacted_at          timestamptz,
    next_follow_up_at          timestamptz,
    do_not_contact             boolean     NOT NULL DEFAULT false,
    address                    jsonb,
    communication_style        jsonb,
    what_they_care_about       jsonb,
    key_facts                  jsonb,
    preferences                jsonb,
    created_at                 timestamptz  NOT NULL DEFAULT now(),
    updated_at                 timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT qxb_artifact_person_key_facts_is_array
      CHECK (key_facts IS NULL OR jsonb_typeof(key_facts) = 'array'),
    CONSTRAINT qxb_artifact_person_what_they_care_about_is_array
      CHECK (what_they_care_about IS NULL OR jsonb_typeof(what_they_care_about) = 'array'),
    CONSTRAINT qxb_artifact_person_preferences_is_array
      CHECK (preferences IS NULL OR jsonb_typeof(preferences) = 'array')
);

COMMENT ON TABLE public.qxb_artifact_person IS 'Person extension table. Extends qxb_artifact via PK=FK. Stores identity, contact, professional context, interaction tracking, and communication intelligence for real individuals in the operator''s network. T150 (2026-03-22).';

-- ============================================================================
-- TABLE: qxb_artifact_dependency [2026-03-01] [T71 Dependency Enforcement]
-- ============================================================================
-- Many-to-many dependency table for leaf-to-leaf execution dependencies.
-- artifact_id = the artifact that depends on another (source/dependent).
-- depends_on_artifact_id = the artifact being depended upon (target/dependency).
-- No UPDATE policy — dependencies are immutable (create or delete only).
-- No updated_at column — append/delete only.
-- DESIGN NOTE: Phase 2B DDL Reconciliation Audit used column names
--   source_artifact_id / target_artifact_id. Verify live table matches.

CREATE TABLE public.qxb_artifact_dependency (
    dependency_id uuid NOT NULL DEFAULT gen_random_uuid(),
    artifact_id uuid NOT NULL,
    depends_on_artifact_id uuid NOT NULL,
    workspace_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT qxb_artifact_dependency_no_self_ref CHECK (artifact_id != depends_on_artifact_id)
);

COMMENT ON TABLE public.qxb_artifact_dependency IS 'Many-to-many dependency table for leaf-to-leaf execution dependencies. artifact_id depends on depends_on_artifact_id. No UPDATE policies — dependencies are immutable (create or delete only). T71 enforcement (2026-03-01).';

-- ============================================================================
-- TABLE: qxb_artifact_type_registry [LIVE-ONLY] [RLS VERIFIED 2026-02-11]
-- ============================================================================
-- Reconstructed from PostgREST OpenAPI on 2026-02-09.
-- Gateway Save workflow consults this table before allowing artifact creation.
-- RLS: Enabled (not flagged by Supabase linter). Policies: [NEEDS VERIFICATION] (T27).

CREATE TABLE public.qxb_artifact_type_registry (
    artifact_type text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_artifact_type_registry IS 'Authoritative registry of recognized artifact types. Gateway consults this before save/update/promote operations.';

-- ============================================================================
-- TABLE: qxb_artifact_type_registry_audit [LIVE-ONLY] [RLS VERIFIED 2026-02-11]
-- ============================================================================
-- Reconstructed from PostgREST OpenAPI on 2026-02-09.
-- Append-only audit log for type registry changes.
-- RLS: Enabled (not flagged by Supabase linter). Policies: [NEEDS VERIFICATION] (T27).

CREATE TABLE public.qxb_artifact_type_registry_audit (
    audit_id uuid DEFAULT gen_random_uuid() NOT NULL,
    artifact_type text NOT NULL,
    action text NOT NULL,
    actor text DEFAULT 'service_role'::text NOT NULL,
    old_enabled boolean,
    new_enabled boolean,
    reason text,
    created_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_artifact_type_registry_audit IS 'Append-only audit log for all changes to qxb_artifact_type_registry.';

-- ============================================================================
-- TABLE: qxb_gateway_acl [LIVE-ONLY] [RLS VERIFIED 2026-02-11]
-- ============================================================================
-- Reconstructed from PostgREST OpenAPI on 2026-02-09.
-- Maps Gateway principals to workspace access.
-- RLS: Enabled with ZERO policies (deny-all). Service_role only.

CREATE TABLE public.qxb_gateway_acl (
    acl_id uuid DEFAULT gen_random_uuid() NOT NULL,
    principal_name text NOT NULL,
    workspace_id uuid NOT NULL,
    role text DEFAULT 'owner'::text NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_gateway_acl IS 'Gateway ACL table. Maps principal_name x workspace_id for multi-forest access control.';

-- ============================================================================
-- TABLE: qxb_semantic_type_registry [2026-03-03] [T69 Semantic Type Registry]
-- ============================================================================
-- Controlled vocabulary for artifact semantic classification.
-- key is UNIQUE and immutable after creation. Deactivate via active=false.
-- governance_snapshot_id: required for post-bootstrap additions (procedural).
-- parent_id: structural reservation for future hierarchy (nullable).
-- Bootstrapped with 9 values. No write policies (service_role only).

CREATE TABLE public.qxb_semantic_type_registry (
    semantic_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    key text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    parent_id uuid,
    governance_snapshot_id uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    created_by text DEFAULT 'service_role'::text NOT NULL
);

COMMENT ON TABLE public.qxb_semantic_type_registry IS 'T69: Controlled vocabulary for artifact semantic classification. Sole source of truth. key is UNIQUE and immutable after creation. Deactivate via active=false, never delete. governance_snapshot_id required for post-bootstrap additions (procedural enforcement).';

-- ============================================================================
-- TABLE: qxb_semantic_type_audit [2026-03-03] [T69 Semantic Type Registry]
-- ============================================================================
-- Append-only audit log for semantic_type_id changes.
-- Triggers block UPDATE/DELETE. All writes go through update_semantic_type() RPC.

CREATE TABLE public.qxb_semantic_type_audit (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    artifact_id uuid NOT NULL,
    old_semantic_type_id uuid,
    new_semantic_type_id uuid NOT NULL,
    reason text NOT NULL,
    actor_id uuid NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_semantic_type_audit IS 'T69: Append-only audit log for semantic_type_id changes on qxb_artifact. Triggers block UPDATE/DELETE. Writes exclusively via update_semantic_type() RPC (SECURITY DEFINER).';

-- ============================================================================
-- VIEW: qxb_artifact_rollup_view [2026-03-01 T70, updated 2026-03-03 T69]
-- ============================================================================
-- Completion percentage for rollup-eligible artifact types (project, branch, limb).
-- Denominator: all non-deleted children. Numerator: children with execution_status = 'complete'.
-- 0 children → completion_ratio = NULL. Direct parent-child only (no recursive CTE).
-- VIEW uses security_invoker=true -- runs with caller RLS, not creator.
-- T69 adds semantic_type_id to SELECT/GROUP BY.

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
-- PRIMARY KEYS
-- ============================================================================

-- [VERIFIED] Original 12 tables
ALTER TABLE ONLY public.qxb_user
    ADD CONSTRAINT qxb_user_pkey PRIMARY KEY (user_id);

ALTER TABLE ONLY public.qxb_workspace
    ADD CONSTRAINT qxb_workspace_pkey PRIMARY KEY (workspace_id);

ALTER TABLE ONLY public.qxb_workspace_user
    ADD CONSTRAINT qxb_workspace_user_pkey PRIMARY KEY (workspace_user_id);

ALTER TABLE ONLY public.qxb_artifact
    ADD CONSTRAINT qxb_artifact_pkey PRIMARY KEY (artifact_id);

ALTER TABLE ONLY public.qxb_artifact_event
    ADD CONSTRAINT qxb_artifact_event_pkey PRIMARY KEY (event_id);

ALTER TABLE ONLY public.qxb_artifact_project
    ADD CONSTRAINT qxb_artifact_project_pkey PRIMARY KEY (artifact_id);

ALTER TABLE ONLY public.qxb_artifact_journal
    ADD CONSTRAINT qxb_artifact_journal_pkey PRIMARY KEY (artifact_id);

ALTER TABLE ONLY public.qxb_artifact_snapshot
    ADD CONSTRAINT qxb_artifact_snapshot_pkey PRIMARY KEY (artifact_id);

ALTER TABLE ONLY public.qxb_artifact_restart
    ADD CONSTRAINT qxb_artifact_restart_pkey PRIMARY KEY (artifact_id);

ALTER TABLE ONLY public.qxb_artifact_video
    ADD CONSTRAINT qxb_artifact_video_pkey PRIMARY KEY (artifact_id);

ALTER TABLE ONLY public.qxb_artifact_grass
    ADD CONSTRAINT qxb_artifact_grass_pkey PRIMARY KEY (artifact_id);

ALTER TABLE ONLY public.qxb_artifact_thorn
    ADD CONSTRAINT qxb_artifact_thorn_pkey PRIMARY KEY (artifact_id);

-- [LIVE-ONLY] New tables
ALTER TABLE ONLY public.qxb_artifact_instruction_pack
    ADD CONSTRAINT qxb_artifact_instruction_pack_pkey PRIMARY KEY (artifact_id);

-- [2026-02-16] Phase 2 Completion
ALTER TABLE ONLY public.qxb_artifact_limb
    ADD CONSTRAINT qxb_artifact_limb_pkey PRIMARY KEY (artifact_id);

-- [2026-03-22] T150 Person Artifact Type
ALTER TABLE ONLY public.qxb_artifact_person
    ADD CONSTRAINT qxb_artifact_person_pkey PRIMARY KEY (artifact_id);

-- [2026-03-01] T71 Dependency Enforcement
ALTER TABLE ONLY public.qxb_artifact_dependency
    ADD CONSTRAINT qxb_artifact_dependency_pkey PRIMARY KEY (dependency_id);

ALTER TABLE ONLY public.qxb_artifact_type_registry
    ADD CONSTRAINT qxb_artifact_type_registry_pkey PRIMARY KEY (artifact_type);

ALTER TABLE ONLY public.qxb_artifact_type_registry_audit
    ADD CONSTRAINT qxb_artifact_type_registry_audit_pkey PRIMARY KEY (audit_id);

ALTER TABLE ONLY public.qxb_gateway_acl
    ADD CONSTRAINT qxb_gateway_acl_pkey PRIMARY KEY (acl_id);

-- [2026-03-03] T69 Semantic Type Registry
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_pkey PRIMARY KEY (semantic_type_id);

ALTER TABLE ONLY public.qxb_semantic_type_audit
    ADD CONSTRAINT qxb_semantic_type_audit_pkey PRIMARY KEY (id);


-- ============================================================================
-- UNIQUE CONSTRAINTS
-- ============================================================================

-- [VERIFIED]
ALTER TABLE ONLY public.qxb_user
    ADD CONSTRAINT qxb_user_auth_user_id_key UNIQUE (auth_user_id);

ALTER TABLE ONLY public.qxb_workspace_user
    ADD CONSTRAINT qxb_workspace_user_unique_membership UNIQUE (workspace_id, user_id);

ALTER TABLE ONLY public.qxb_artifact_video
    ADD CONSTRAINT qxb_artifact_video_idempotency_key_key UNIQUE (idempotency_key);

-- [2026-03-03] T69 Semantic Type Registry
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_key_unique UNIQUE (key);


-- ============================================================================
-- INDEXES
-- ============================================================================

-- [VERIFIED]
CREATE INDEX qxb_artifact_grass_review_detected_idx ON public.qxb_artifact_grass USING btree (review_status, detected_at DESC);

CREATE INDEX qxb_artifact_thorn_severity_detected_idx ON public.qxb_artifact_thorn USING btree (severity, detected_at DESC);

CREATE INDEX qxb_artifact_thorn_status_detected_idx ON public.qxb_artifact_thorn USING btree (status, detected_at DESC);

CREATE UNIQUE INDEX uq_qxb_artifact_forest_title_active ON public.qxb_artifact USING btree (workspace_id, lower(title)) WHERE ((artifact_type = 'forest'::text) AND (deleted_at IS NULL));

CREATE UNIQUE INDEX uq_qxb_artifact_thicket_title_per_forest_active ON public.qxb_artifact USING btree (workspace_id, parent_artifact_id, lower(title)) WHERE ((artifact_type = 'thicket'::text) AND (deleted_at IS NULL));

-- [2026-03-01] T71 Dependency Enforcement
CREATE INDEX idx_qxb_artifact_dependency_source ON public.qxb_artifact_dependency (artifact_id);
CREATE INDEX idx_qxb_artifact_dependency_target ON public.qxb_artifact_dependency (depends_on_artifact_id);

-- [2026-03-03] T69 Semantic Type Registry
CREATE INDEX idx_qxb_artifact_semantic_type ON public.qxb_artifact USING btree (semantic_type_id) WHERE semantic_type_id IS NOT NULL;
CREATE INDEX idx_qxb_semantic_type_audit_artifact ON public.qxb_semantic_type_audit USING btree (artifact_id, created_at DESC);

-- [NEEDS VERIFICATION] New tables may have additional indexes not exposed by OpenAPI

-- [2026-03-22] T150 Person Artifact Type
CREATE INDEX idx_qxb_artifact_person_full_name ON public.qxb_artifact_person USING btree (full_name);
CREATE INDEX idx_qxb_artifact_person_relationship_type ON public.qxb_artifact_person USING btree (relationship_type);
CREATE INDEX idx_qxb_artifact_person_last_contacted_at ON public.qxb_artifact_person USING btree (last_contacted_at) WHERE last_contacted_at IS NOT NULL;
CREATE INDEX idx_qxb_artifact_person_key_facts ON public.qxb_artifact_person USING gin (key_facts) WHERE key_facts IS NOT NULL;
CREATE INDEX idx_qxb_artifact_person_what_they_care_about ON public.qxb_artifact_person USING gin (what_they_care_about) WHERE what_they_care_about IS NOT NULL;
CREATE INDEX idx_qxb_artifact_person_preferences ON public.qxb_artifact_person USING gin (preferences) WHERE preferences IS NOT NULL;


-- ============================================================================
-- FOREIGN KEYS
-- ============================================================================

-- qxb_user
ALTER TABLE ONLY public.qxb_user
    ADD CONSTRAINT qxb_user_auth_user_fk FOREIGN KEY (auth_user_id) REFERENCES auth.users(id);

-- qxb_workspace_user
ALTER TABLE ONLY public.qxb_workspace_user
    ADD CONSTRAINT qxb_workspace_user_user_fk FOREIGN KEY (user_id) REFERENCES public.qxb_user(user_id);

ALTER TABLE ONLY public.qxb_workspace_user
    ADD CONSTRAINT qxb_workspace_user_workspace_fk FOREIGN KEY (workspace_id) REFERENCES public.qxb_workspace(workspace_id);

-- qxb_artifact
ALTER TABLE ONLY public.qxb_artifact
    ADD CONSTRAINT qxb_artifact_workspace_fk FOREIGN KEY (workspace_id) REFERENCES public.qxb_workspace(workspace_id);

ALTER TABLE ONLY public.qxb_artifact
    ADD CONSTRAINT qxb_artifact_owner_user_fk FOREIGN KEY (owner_user_id) REFERENCES public.qxb_user(user_id);

ALTER TABLE ONLY public.qxb_artifact
    ADD CONSTRAINT qxb_artifact_parent_fk FOREIGN KEY (parent_artifact_id) REFERENCES public.qxb_artifact(artifact_id);

-- qxb_artifact_event
ALTER TABLE ONLY public.qxb_artifact_event
    ADD CONSTRAINT qxb_artifact_event_workspace_fk FOREIGN KEY (workspace_id) REFERENCES public.qxb_workspace(workspace_id);

ALTER TABLE ONLY public.qxb_artifact_event
    ADD CONSTRAINT qxb_artifact_event_artifact_fk FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_artifact_event
    ADD CONSTRAINT qxb_artifact_event_actor_fk FOREIGN KEY (actor_user_id) REFERENCES public.qxb_user(user_id);

-- Extension tables → spine FK (PK=FK pattern)
ALTER TABLE ONLY public.qxb_artifact_project
    ADD CONSTRAINT qxb_artifact_project_fk FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_artifact_journal
    ADD CONSTRAINT qxb_artifact_journal_fk FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_artifact_snapshot
    ADD CONSTRAINT qxb_artifact_snapshot_fk FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_artifact_restart
    ADD CONSTRAINT qxb_artifact_restart_fk FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_artifact_video
    ADD CONSTRAINT qxb_artifact_video_artifact_id_fkey FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_artifact_grass
    ADD CONSTRAINT qxb_artifact_grass_artifact_id_fkey FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_artifact_thorn
    ADD CONSTRAINT qxb_artifact_thorn_artifact_id_fkey FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

-- [LIVE-ONLY] New table FKs
ALTER TABLE ONLY public.qxb_artifact_instruction_pack
    ADD CONSTRAINT qxb_artifact_instruction_pack_fk FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

-- [2026-02-16] Phase 2 Completion
ALTER TABLE ONLY public.qxb_artifact_limb
    ADD CONSTRAINT qxb_artifact_limb_fk FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

-- [2026-03-22] T150 Person Artifact Type
ALTER TABLE ONLY public.qxb_artifact_person
    ADD CONSTRAINT qxb_artifact_person_fk FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_gateway_acl
    ADD CONSTRAINT qxb_gateway_acl_workspace_fk FOREIGN KEY (workspace_id) REFERENCES public.qxb_workspace(workspace_id);

-- [2026-03-01] T71 Dependency Enforcement
ALTER TABLE ONLY public.qxb_artifact_dependency
    ADD CONSTRAINT qxb_artifact_dependency_source_fk FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_artifact_dependency
    ADD CONSTRAINT qxb_artifact_dependency_target_fk FOREIGN KEY (depends_on_artifact_id) REFERENCES public.qxb_artifact(artifact_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.qxb_artifact_dependency
    ADD CONSTRAINT qxb_artifact_dependency_workspace_fk FOREIGN KEY (workspace_id) REFERENCES public.qxb_workspace(workspace_id);

-- [2026-03-03] T69 Semantic Type Registry

-- qxb_artifact → qxb_semantic_type_registry
ALTER TABLE ONLY public.qxb_artifact
    ADD CONSTRAINT qxb_artifact_semantic_type_fk
    FOREIGN KEY (semantic_type_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id)
    ON DELETE RESTRICT;

-- qxb_semantic_type_registry self-referential FK (parent hierarchy)
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_parent_fk
    FOREIGN KEY (parent_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id);

-- qxb_semantic_type_registry → qxb_artifact (governance snapshot)
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_snapshot_fk
    FOREIGN KEY (governance_snapshot_id) REFERENCES public.qxb_artifact(artifact_id);

-- qxb_semantic_type_audit FKs
ALTER TABLE ONLY public.qxb_semantic_type_audit
    ADD CONSTRAINT qxb_semantic_type_audit_artifact_fk
    FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id);

ALTER TABLE ONLY public.qxb_semantic_type_audit
    ADD CONSTRAINT qxb_semantic_type_audit_old_type_fk
    FOREIGN KEY (old_semantic_type_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id)
    ON DELETE RESTRICT;

ALTER TABLE ONLY public.qxb_semantic_type_audit
    ADD CONSTRAINT qxb_semantic_type_audit_new_type_fk
    FOREIGN KEY (new_semantic_type_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id)
    ON DELETE RESTRICT;


-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Append-only protection on event log [VERIFIED]
CREATE TRIGGER qxb_artifact_event_block_delete BEFORE DELETE ON public.qxb_artifact_event FOR EACH ROW EXECUTE FUNCTION public.qxb_block_update_delete();
CREATE TRIGGER qxb_artifact_event_block_update BEFORE UPDATE ON public.qxb_artifact_event FOR EACH ROW EXECUTE FUNCTION public.qxb_block_update_delete();

-- Auto-set updated_at [VERIFIED]
CREATE TRIGGER qxb_artifact_set_updated_at BEFORE UPDATE ON public.qxb_artifact FOR EACH ROW EXECUTE FUNCTION public.qxb_set_updated_at();
CREATE TRIGGER qxb_artifact_journal_set_updated_at BEFORE UPDATE ON public.qxb_artifact_journal FOR EACH ROW EXECUTE FUNCTION public.qxb_set_updated_at();
CREATE TRIGGER qxb_artifact_project_set_updated_at BEFORE UPDATE ON public.qxb_artifact_project FOR EACH ROW EXECUTE FUNCTION public.qxb_set_updated_at();
CREATE TRIGGER qxb_user_set_updated_at BEFORE UPDATE ON public.qxb_user FOR EACH ROW EXECUTE FUNCTION public.qxb_set_updated_at();
CREATE TRIGGER qxb_workspace_set_updated_at BEFORE UPDATE ON public.qxb_workspace FOR EACH ROW EXECUTE FUNCTION public.qxb_set_updated_at();
CREATE TRIGGER qxb_workspace_user_set_updated_at BEFORE UPDATE ON public.qxb_workspace_user FOR EACH ROW EXECUTE FUNCTION public.qxb_set_updated_at();

-- [NEEDS VERIFICATION] qxb_artifact_instruction_pack likely has updated_at trigger
-- [NEEDS VERIFICATION] qxb_artifact_type_registry likely has updated_at trigger
-- [NEEDS VERIFICATION] qxb_artifact_type_registry_audit likely has block_update_delete triggers

-- [2026-02-16] Phase 2 Completion
CREATE TRIGGER qxb_artifact_limb_set_updated_at BEFORE UPDATE ON public.qxb_artifact_limb FOR EACH ROW EXECUTE FUNCTION public.qxb_set_updated_at();

-- [2026-03-22] T150 Person Artifact Type
CREATE TRIGGER qxb_artifact_person_set_updated_at BEFORE UPDATE ON public.qxb_artifact_person FOR EACH ROW EXECUTE FUNCTION public.qxb_set_updated_at();

-- [2026-03-03] T69 — Append-only protection on semantic type audit
CREATE TRIGGER qxb_semantic_type_audit_block_update BEFORE UPDATE ON public.qxb_semantic_type_audit FOR EACH ROW EXECUTE FUNCTION public.qxb_block_update_delete();
CREATE TRIGGER qxb_semantic_type_audit_block_delete BEFORE DELETE ON public.qxb_semantic_type_audit FOR EACH ROW EXECUTE FUNCTION public.qxb_block_update_delete();


-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on all tables [VERIFIED for original 12]
ALTER TABLE public.qxb_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_workspace ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_workspace_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_project ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_journal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_snapshot ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_restart ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_grass ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_thorn ENABLE ROW LEVEL SECURITY;
-- [VERIFIED 2026-02-11] All 5 tables confirmed RLS enabled via Supabase linter + C7 query
ALTER TABLE public.qxb_artifact_video ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_instruction_pack ENABLE ROW LEVEL SECURITY;
-- [2026-02-16] Phase 2 Completion
ALTER TABLE public.qxb_artifact_limb ENABLE ROW LEVEL SECURITY;
-- [2026-03-22] T150 Person Artifact Type
ALTER TABLE public.qxb_artifact_person ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_type_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_type_registry_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_gateway_acl ENABLE ROW LEVEL SECURITY;
-- [2026-03-01] T71 Dependency Enforcement
ALTER TABLE public.qxb_artifact_dependency ENABLE ROW LEVEL SECURITY;
-- [2026-03-03] T69 Semantic Type Registry
ALTER TABLE public.qxb_semantic_type_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_semantic_type_audit ENABLE ROW LEVEL SECURITY;


-- ============================================================================
-- RLS POLICIES [VERIFIED]
-- ============================================================================

-- qxb_user: self-only access
CREATE POLICY qxb_user_select_self ON public.qxb_user FOR SELECT TO authenticated USING ((auth_user_id = (select auth.uid())));
CREATE POLICY qxb_user_update_self ON public.qxb_user FOR UPDATE TO authenticated USING ((auth_user_id = (select auth.uid()))) WITH CHECK ((auth_user_id = (select auth.uid())));

-- qxb_workspace: member access via auth
CREATE POLICY qxb_workspace_select_via_auth_membership ON public.qxb_workspace FOR SELECT TO authenticated USING ((EXISTS (
  SELECT 1 FROM (public.qxb_workspace_user wsu JOIN public.qxb_user u ON ((u.user_id = wsu.user_id)))
  WHERE ((wsu.workspace_id = qxb_workspace.workspace_id) AND (u.auth_user_id = (select auth.uid())))
)));

-- qxb_workspace_user: self-only select via auth
CREATE POLICY qxb_workspace_user_select_via_auth ON public.qxb_workspace_user FOR SELECT TO authenticated USING ((EXISTS (
  SELECT 1 FROM public.qxb_user u WHERE ((u.user_id = qxb_workspace_user.user_id) AND (u.auth_user_id = (select auth.uid())))
)));

-- qxb_artifact: workspace member SELECT (journals = owner-only)
CREATE POLICY qxb_artifact_select_member ON public.qxb_artifact FOR SELECT TO authenticated USING ((
  (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = qxb_artifact.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()))))
  AND ((artifact_type <> 'journal'::text) OR (owner_user_id = public.qxb_current_user_id()))
));

-- qxb_artifact: INSERT owner + workspace member
CREATE POLICY qxb_artifact_insert_owner ON public.qxb_artifact FOR INSERT TO authenticated WITH CHECK ((
  (owner_user_id = public.qxb_current_user_id())
  AND (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = qxb_artifact.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()))))
));

-- qxb_artifact: UPDATE owner or admin
CREATE POLICY qxb_artifact_update_owner_or_admin ON public.qxb_artifact FOR UPDATE TO authenticated
  USING (((owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = qxb_artifact.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])))))))
  WITH CHECK (((owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = qxb_artifact.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])))))));

-- qxb_artifact_event: workspace member SELECT
CREATE POLICY qxb_artifact_event_select_member ON public.qxb_artifact_event FOR SELECT TO authenticated USING ((EXISTS (
  SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = qxb_artifact_event.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()))
)));

-- qxb_artifact_project: SELECT via artifact, UPDATE owner/admin via artifact
CREATE POLICY qxb_artifact_project_select_via_artifact ON public.qxb_artifact_project FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_project.artifact_id))));
CREATE POLICY qxb_artifact_project_update_owner_or_admin ON public.qxb_artifact_project FOR UPDATE TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_project.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))))
  WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_project.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))));

-- qxb_artifact_journal: owner-only (INSERT, SELECT, UPDATE)
CREATE POLICY qxb_artifact_journal_insert_owner_via_artifact ON public.qxb_artifact_journal FOR INSERT TO authenticated WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_journal.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))));
CREATE POLICY qxb_artifact_journal_select_owner_via_artifact ON public.qxb_artifact_journal FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_journal.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))));
CREATE POLICY qxb_artifact_journal_update_owner_via_artifact ON public.qxb_artifact_journal FOR UPDATE TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_journal.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))))
  WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_journal.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))));

-- qxb_artifact_snapshot: INSERT owner, SELECT member (immutable — no UPDATE/DELETE policies)
CREATE POLICY qxb_artifact_snapshot_insert_owner_via_artifact ON public.qxb_artifact_snapshot FOR INSERT TO authenticated WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_snapshot.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))));
CREATE POLICY qxb_artifact_snapshot_select_via_artifact ON public.qxb_artifact_snapshot FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_snapshot.artifact_id))));

-- qxb_artifact_restart: INSERT owner, SELECT member (immutable — no UPDATE/DELETE policies)
CREATE POLICY qxb_artifact_restart_insert_owner_via_artifact ON public.qxb_artifact_restart FOR INSERT TO authenticated WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_restart.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))));
CREATE POLICY qxb_artifact_restart_select_via_artifact ON public.qxb_artifact_restart FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_restart.artifact_id))));

-- qxb_artifact_grass: INSERT/SELECT/UPDATE via artifact existence
CREATE POLICY qxb_artifact_grass_insert_via_artifact ON public.qxb_artifact_grass FOR INSERT TO authenticated WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_grass.artifact_id))));
CREATE POLICY qxb_artifact_grass_select_via_artifact ON public.qxb_artifact_grass FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_grass.artifact_id))));
CREATE POLICY qxb_artifact_grass_update_via_artifact ON public.qxb_artifact_grass FOR UPDATE TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_grass.artifact_id))))
  WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_grass.artifact_id))));

-- qxb_artifact_thorn: INSERT/SELECT/UPDATE via artifact existence
CREATE POLICY qxb_artifact_thorn_insert_via_artifact ON public.qxb_artifact_thorn FOR INSERT TO authenticated WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_thorn.artifact_id))));
CREATE POLICY qxb_artifact_thorn_select_via_artifact ON public.qxb_artifact_thorn FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_thorn.artifact_id))));
CREATE POLICY qxb_artifact_thorn_update_via_artifact ON public.qxb_artifact_thorn FOR UPDATE TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_thorn.artifact_id))))
  WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_thorn.artifact_id))));

-- ============================================================================
-- RLS POLICIES [VERIFIED 2026-02-11] — Hardening migration
-- ============================================================================
-- Migration: migrations/2026-02-11__supabase_linter_hardening__v1.0.sql

-- qxb_artifact_video: SELECT/INSERT/UPDATE via spine delegation (3 policies)
CREATE POLICY qxb_artifact_video_select_via_artifact ON public.qxb_artifact_video FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_video.artifact_id))));
CREATE POLICY qxb_artifact_video_insert_owner_via_artifact ON public.qxb_artifact_video FOR INSERT TO authenticated WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_video.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))));
CREATE POLICY qxb_artifact_video_update_owner_or_admin ON public.qxb_artifact_video FOR UPDATE TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_video.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))))
  WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_video.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))));

-- qxb_artifact_instruction_pack: SELECT/INSERT/UPDATE via spine delegation (3 policies)
CREATE POLICY qxb_artifact_instruction_pack_select_via_artifact ON public.qxb_artifact_instruction_pack FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_instruction_pack.artifact_id))));
CREATE POLICY qxb_artifact_instruction_pack_insert_owner_via_artifact ON public.qxb_artifact_instruction_pack FOR INSERT TO authenticated WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_instruction_pack.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))));
CREATE POLICY qxb_artifact_instruction_pack_update_owner_or_admin ON public.qxb_artifact_instruction_pack FOR UPDATE TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_instruction_pack.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))))
  WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_instruction_pack.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))));

-- qxb_gateway_acl: ZERO policies (deny-all for anon/authenticated; service_role only)
-- No policies created intentionally. This is deny-all by design.

-- qxb_artifact_type_registry: RLS enabled (not flagged by linter). Policies: [NEEDS VERIFICATION] (T27)
-- qxb_artifact_type_registry_audit: RLS enabled (not flagged by linter). Policies: [NEEDS VERIFICATION] (T27)


-- ============================================================================
-- RLS POLICIES [2026-03-03] — T69 Semantic Type Registry
-- ============================================================================
-- Both tables: read-only for authenticated users. No write policies (service_role only).
-- Writes to audit exclusively via update_semantic_type() RPC (SECURITY DEFINER bypasses RLS).

-- qxb_semantic_type_registry: SELECT for authenticated (vocabulary is public)
CREATE POLICY qxb_semantic_type_registry_select_authenticated
    ON public.qxb_semantic_type_registry
    FOR SELECT TO authenticated
    USING (true);

-- qxb_semantic_type_audit: SELECT for authenticated (audit trail is readable)
CREATE POLICY qxb_semantic_type_audit_select_authenticated
    ON public.qxb_semantic_type_audit
    FOR SELECT TO authenticated
    USING (true);


-- ============================================================================
-- RLS POLICIES [2026-03-01] — T71 Dependency Enforcement
-- ============================================================================
-- Dependencies use workspace membership (not spine delegation).
-- No UPDATE policy — dependencies are immutable (create or delete only).

-- qxb_artifact_dependency: SELECT via workspace membership
CREATE POLICY qxb_artifact_dependency_select_member ON public.qxb_artifact_dependency FOR SELECT TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu
    WHERE ((wsu.workspace_id = qxb_artifact_dependency.workspace_id)
    AND (wsu.user_id = public.qxb_current_user_id())))));

-- qxb_artifact_dependency: INSERT via workspace membership
CREATE POLICY qxb_artifact_dependency_insert_member ON public.qxb_artifact_dependency FOR INSERT TO authenticated
  WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu
    WHERE ((wsu.workspace_id = qxb_artifact_dependency.workspace_id)
    AND (wsu.user_id = public.qxb_current_user_id())))));

-- qxb_artifact_dependency: DELETE via owner/admin only
CREATE POLICY qxb_artifact_dependency_delete_owner_or_admin ON public.qxb_artifact_dependency FOR DELETE TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu
    WHERE ((wsu.workspace_id = qxb_artifact_dependency.workspace_id)
    AND (wsu.user_id = public.qxb_current_user_id())
    AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))));


-- ============================================================================
-- RLS POLICIES [2026-02-16] — Phase 2 Completion (qxb_artifact_limb)
-- ============================================================================
-- Hardened pattern matching video/instruction_pack (2026-02-11 migration).

-- qxb_artifact_limb: SELECT/INSERT/UPDATE via spine delegation (3 policies)
CREATE POLICY qxb_artifact_limb_select_via_artifact ON public.qxb_artifact_limb FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE (a.artifact_id = qxb_artifact_limb.artifact_id))));
CREATE POLICY qxb_artifact_limb_insert_owner_via_artifact ON public.qxb_artifact_limb FOR INSERT TO authenticated WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_limb.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))));
CREATE POLICY qxb_artifact_limb_update_owner_or_admin ON public.qxb_artifact_limb FOR UPDATE TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_limb.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))))
  WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_limb.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))));

-- ============================================================================
-- RLS POLICIES [2026-03-22] — T150 Person Artifact Type (qxb_artifact_person)
-- ============================================================================
-- SELECT uses workspace_user join (hardened per Q audit — not spine-only).
-- INSERT/UPDATE follow standard spine delegation pattern.

-- qxb_artifact_person: SELECT (workspace member) / INSERT (owner) / UPDATE (owner/admin)
CREATE POLICY qxb_artifact_person_select_via_artifact ON public.qxb_artifact_person FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a JOIN public.qxb_workspace_user wsu ON wsu.workspace_id = a.workspace_id WHERE (a.artifact_id = qxb_artifact_person.artifact_id) AND (wsu.user_id = public.qxb_current_user_id()))));
CREATE POLICY qxb_artifact_person_insert_owner_via_artifact ON public.qxb_artifact_person FOR INSERT TO authenticated WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_person.artifact_id) AND (a.owner_user_id = public.qxb_current_user_id())))));
CREATE POLICY qxb_artifact_person_update_owner_or_admin ON public.qxb_artifact_person FOR UPDATE TO authenticated
  USING ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_person.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))))
  WITH CHECK ((EXISTS (SELECT 1 FROM public.qxb_artifact a WHERE ((a.artifact_id = qxb_artifact_person.artifact_id) AND ((a.owner_user_id = public.qxb_current_user_id()) OR (EXISTS (SELECT 1 FROM public.qxb_workspace_user wsu WHERE ((wsu.workspace_id = a.workspace_id) AND (wsu.user_id = public.qxb_current_user_id()) AND (wsu.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))))));


-- ============================================================================
-- VERIFICATION CHECKLIST
-- ============================================================================
-- To fully verify this DDL, run these queries against the live database:
--
-- 1. CHECK constraint on artifact_type:
--    SELECT conname, pg_get_constraintdef(oid)
--    FROM pg_constraint
--    WHERE conrelid = 'public.qxb_artifact'::regclass AND contype = 'c';
--
-- 2. All RLS policies:
--    SELECT schemaname, tablename, policyname, cmd, qual, with_check
--    FROM pg_policies WHERE schemaname = 'public' AND tablename LIKE 'qxb_%';
--
-- 3. All triggers:
--    SELECT trigger_name, event_manipulation, event_object_table, action_statement
--    FROM information_schema.triggers WHERE trigger_schema = 'public';
--
-- 4. All indexes:
--    SELECT indexname, indexdef FROM pg_indexes WHERE schemaname = 'public' AND tablename LIKE 'qxb_%';
--
-- PostgreSQL database dump complete
--
