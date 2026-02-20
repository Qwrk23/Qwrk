--
-- Qwrk Kernel v1 — Live DDL Reference
-- Project: npymhacpmxdnkqdzgxll (Supabase)
-- Database: PostgreSQL 17.6
--
-- CHANGELOG:
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
    tags jsonb,
    content jsonb,
    parent_artifact_id uuid,
    version integer DEFAULT 1 NOT NULL,
    deleted_at timestamptz,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT qxb_artifact_artifact_type_check_v6 CHECK ((artifact_type = ANY (ARRAY['project'::text, 'journal'::text, 'restart'::text, 'snapshot'::text, 'grass'::text, 'thorn'::text, 'forest'::text, 'thicket'::text, 'flower'::text, 'branch'::text, 'leaf'::text, 'instruction_pack'::text, 'limb'::text]))),
    CONSTRAINT qxb_artifact_priority_check CHECK (((priority >= 1) AND (priority <= 5))),
    CONSTRAINT qxb_artifact_lifecycle_status_check CHECK (((artifact_type <> 'project'::text) OR (lifecycle_status = ANY (ARRAY['seed'::text, 'sapling'::text, 'tree'::text, 'archive'::text])))),
    CONSTRAINT qxb_artifact_execution_status_check CHECK ((execution_status IS NULL OR (execution_status = ANY (ARRAY['not_started'::text, 'in_progress'::text, 'blocked'::text, 'complete'::text]))))
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

ALTER TABLE ONLY public.qxb_artifact_type_registry
    ADD CONSTRAINT qxb_artifact_type_registry_pkey PRIMARY KEY (artifact_type);

ALTER TABLE ONLY public.qxb_artifact_type_registry_audit
    ADD CONSTRAINT qxb_artifact_type_registry_audit_pkey PRIMARY KEY (audit_id);

ALTER TABLE ONLY public.qxb_gateway_acl
    ADD CONSTRAINT qxb_gateway_acl_pkey PRIMARY KEY (acl_id);


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


-- ============================================================================
-- INDEXES
-- ============================================================================

-- [VERIFIED]
CREATE INDEX qxb_artifact_grass_review_detected_idx ON public.qxb_artifact_grass USING btree (review_status, detected_at DESC);

CREATE INDEX qxb_artifact_thorn_severity_detected_idx ON public.qxb_artifact_thorn USING btree (severity, detected_at DESC);

CREATE INDEX qxb_artifact_thorn_status_detected_idx ON public.qxb_artifact_thorn USING btree (status, detected_at DESC);

CREATE UNIQUE INDEX uq_qxb_artifact_forest_title_active ON public.qxb_artifact USING btree (workspace_id, lower(title)) WHERE ((artifact_type = 'forest'::text) AND (deleted_at IS NULL));

CREATE UNIQUE INDEX uq_qxb_artifact_thicket_title_per_forest_active ON public.qxb_artifact USING btree (workspace_id, parent_artifact_id, lower(title)) WHERE ((artifact_type = 'thicket'::text) AND (deleted_at IS NULL));

-- [NEEDS VERIFICATION] New tables may have additional indexes not exposed by OpenAPI


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

ALTER TABLE ONLY public.qxb_gateway_acl
    ADD CONSTRAINT qxb_gateway_acl_workspace_fk FOREIGN KEY (workspace_id) REFERENCES public.qxb_workspace(workspace_id);


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
ALTER TABLE public.qxb_artifact_type_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_artifact_type_registry_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qxb_gateway_acl ENABLE ROW LEVEL SECURITY;


-- ============================================================================
-- RLS POLICIES [VERIFIED]
-- ============================================================================

-- qxb_user: self-only access
CREATE POLICY qxb_user_select_self ON public.qxb_user FOR SELECT TO authenticated USING ((auth_user_id = auth.uid()));
CREATE POLICY qxb_user_update_self ON public.qxb_user FOR UPDATE TO authenticated USING ((auth_user_id = auth.uid())) WITH CHECK ((auth_user_id = auth.uid()));

-- qxb_workspace: member access via auth
CREATE POLICY qxb_workspace_select_via_auth_membership ON public.qxb_workspace FOR SELECT TO authenticated USING ((EXISTS (
  SELECT 1 FROM (public.qxb_workspace_user wsu JOIN public.qxb_user u ON ((u.user_id = wsu.user_id)))
  WHERE ((wsu.workspace_id = qxb_workspace.workspace_id) AND (u.auth_user_id = auth.uid()))
)));

-- qxb_workspace_user: self-only select via auth
CREATE POLICY qxb_workspace_user_select_via_auth ON public.qxb_workspace_user FOR SELECT TO authenticated USING ((EXISTS (
  SELECT 1 FROM public.qxb_user u WHERE ((u.user_id = qxb_workspace_user.user_id) AND (u.auth_user_id = auth.uid()))
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
