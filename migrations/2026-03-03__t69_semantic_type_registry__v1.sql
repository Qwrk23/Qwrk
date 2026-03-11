-- =============================================================================
-- Migration: T69 — Semantic Type Registry (Phase 3.1)
-- Date:      2026-03-03
-- Version:   DDL v2.5 → v2.6
-- Author:    CC (Claude Code) — approved by Joel
-- Thread:    T69 — Behavioral Role Layer / Semantic Type Registry
-- =============================================================================
--
-- PURPOSE:
--   Add a semantic classification layer to the artifact spine. Introduces:
--   1. Controlled vocabulary registry (qxb_semantic_type_registry)
--   2. Append-only audit table for classification changes
--   3. semantic_type_id column on qxb_artifact (FK to registry)
--   4. Conditional NOT NULL enforcement (top-level types only)
--   5. Atomic RPC for update + audit (fail-closed)
--   6. Rollup view update (add semantic_type_id)
--
-- SCOPE:
--   Top-level types requiring semantic_type_id:
--     project, snapshot, journal, restart
--   Excluded (semantic_type_id = NULL allowed):
--     instruction_pack, branch, limb, leaf, grass, thorn,
--     forest, thicket, flower
--
-- DEPLOYMENT ORDER:
--   This file has TWO sections:
--
--   SECTION A: Run IMMEDIATELY (no dependencies on backfill or workflows)
--     Steps 1-8: Tables, seed, column, FK, indexes, RLS, view, RPC
--
--   SECTION B: Run AFTER backfill complete AND workflows deployed
--     Step 9: Conditional NOT NULL CHECK constraint
--
--   If Section B is run before backfill, existing top-level artifacts
--   with NULL semantic_type_id will cause the constraint to fail.
--
-- ROLLBACK:
--   -- Step 9 (CHECK):
--   ALTER TABLE public.qxb_artifact DROP CONSTRAINT IF EXISTS qxb_artifact_semantic_type_required_for_top_level;
--   -- Step 8 (RPC):
--   DROP FUNCTION IF EXISTS public.update_semantic_type(uuid, uuid, text, uuid);
--   -- Step 7 (View — restore original):
--   CREATE OR REPLACE VIEW public.qxb_artifact_rollup_view AS ... (see T70 migration for original);
--   -- Step 6 (RLS): policies dropped with tables
--   -- Step 5 (FK + Index):
--   ALTER TABLE public.qxb_artifact DROP CONSTRAINT IF EXISTS qxb_artifact_semantic_type_fk;
--   DROP INDEX IF EXISTS idx_qxb_artifact_semantic_type;
--   -- Step 4 (Column):
--   ALTER TABLE public.qxb_artifact DROP COLUMN IF EXISTS semantic_type_id;
--   -- Step 3 (Audit):
--   DROP TABLE IF EXISTS public.qxb_semantic_type_audit;
--   -- Step 1 (Registry — must drop after FK removed):
--   DROP TABLE IF EXISTS public.qxb_semantic_type_registry;
--
-- CHANGELOG:
--   v1 (2026-03-03) — Initial creation
-- =============================================================================


-- =============================================================================
-- SECTION A: Run IMMEDIATELY
-- =============================================================================


-- =============================================================================
-- STEP 1: Create qxb_semantic_type_registry
-- =============================================================================
-- Controlled vocabulary for artifact semantic classification.
-- key is UNIQUE and immutable after creation. Deactivate via active=false.
-- governance_snapshot_id: required for post-bootstrap additions (procedural).
-- parent_id: structural reservation for future hierarchy (nullable).

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

COMMENT ON TABLE public.qxb_semantic_type_registry IS
  'T69: Controlled vocabulary for artifact semantic classification. Sole source of truth. key is UNIQUE and immutable after creation. Deactivate via active=false, never delete. governance_snapshot_id required for post-bootstrap additions (procedural enforcement).';

-- PK
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_pkey PRIMARY KEY (semantic_type_id);

-- UNIQUE on key (immutable after creation — no rename)
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_key_unique UNIQUE (key);

-- Self-referential FK for hierarchy (parent_id → semantic_type_id)
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_parent_fk
    FOREIGN KEY (parent_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id);

-- FK to governance snapshot artifact
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_snapshot_fk
    FOREIGN KEY (governance_snapshot_id) REFERENCES public.qxb_artifact(artifact_id);


-- =============================================================================
-- STEP 2: Seed 9 v1 values
-- =============================================================================
-- Bootstrap seed — governance_snapshot_id is NULL for initial registry.
-- Post-implementation: Joel creates governance snapshot, backfills IDs.

INSERT INTO public.qxb_semantic_type_registry (key, description, created_by) VALUES
    ('execution-core',  'Core execution and lifecycle operations',              'bootstrap'),
    ('governance',      'Governance rules, policies, and enforcement',          'bootstrap'),
    ('infrastructure',  'System infrastructure and platform plumbing',          'bootstrap'),
    ('platform',        'Platform capabilities and features',                   'bootstrap'),
    ('product',         'Product-facing functionality and user features',       'bootstrap'),
    ('alignment',       'Strategic alignment and direction-setting',            'bootstrap'),
    ('sales',           'Sales operations and pipeline',                        'bootstrap'),
    ('marketing',       'Marketing operations and content',                     'bootstrap'),
    ('exploratory',     'Undeclared meaning — default for unclassified artifacts', 'bootstrap');


-- =============================================================================
-- STEP 3: Create qxb_semantic_type_audit (append-only)
-- =============================================================================
-- Audit log for semantic_type_id changes. Append-only: triggers block
-- UPDATE/DELETE. All writes go through update_semantic_type() RPC
-- (SECURITY DEFINER — bypasses RLS).

CREATE TABLE public.qxb_semantic_type_audit (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    artifact_id uuid NOT NULL,
    old_semantic_type_id uuid,
    new_semantic_type_id uuid NOT NULL,
    reason text NOT NULL,
    -- TODO: replace actor_id default with authenticated user context
    --       when multi-user auth is introduced
    actor_id uuid NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

COMMENT ON TABLE public.qxb_semantic_type_audit IS
  'T69: Append-only audit log for semantic_type_id changes on qxb_artifact. Triggers block UPDATE/DELETE. Writes exclusively via update_semantic_type() RPC (SECURITY DEFINER).';

-- PK
ALTER TABLE ONLY public.qxb_semantic_type_audit
    ADD CONSTRAINT qxb_semantic_type_audit_pkey PRIMARY KEY (id);

-- FKs
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

-- Index for artifact-scoped audit queries
CREATE INDEX idx_qxb_semantic_type_audit_artifact
    ON public.qxb_semantic_type_audit USING btree (artifact_id, created_at DESC);

-- Append-only triggers (same pattern as qxb_artifact_event)
CREATE TRIGGER qxb_semantic_type_audit_block_update
    BEFORE UPDATE ON public.qxb_semantic_type_audit
    FOR EACH ROW EXECUTE FUNCTION public.qxb_block_update_delete();

CREATE TRIGGER qxb_semantic_type_audit_block_delete
    BEFORE DELETE ON public.qxb_semantic_type_audit
    FOR EACH ROW EXECUTE FUNCTION public.qxb_block_update_delete();


-- =============================================================================
-- STEP 4: Add semantic_type_id column to qxb_artifact
-- =============================================================================
-- Column is nullable initially. Backfill runs separately (Phase 2).
-- Conditional NOT NULL enforced via CHECK in Section B (Step 9).

ALTER TABLE public.qxb_artifact
    ADD COLUMN semantic_type_id uuid;


-- =============================================================================
-- STEP 5: Add FK + indexes on qxb_artifact.semantic_type_id
-- =============================================================================

-- FK to registry
ALTER TABLE ONLY public.qxb_artifact
    ADD CONSTRAINT qxb_artifact_semantic_type_fk
    FOREIGN KEY (semantic_type_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id)
    ON DELETE RESTRICT;

-- Index for FK lookups and filtered queries
CREATE INDEX idx_qxb_artifact_semantic_type
    ON public.qxb_artifact USING btree (semantic_type_id)
    WHERE semantic_type_id IS NOT NULL;


-- =============================================================================
-- STEP 6: RLS policies
-- =============================================================================

-- qxb_semantic_type_registry: RLS enabled
ALTER TABLE public.qxb_semantic_type_registry ENABLE ROW LEVEL SECURITY;

-- Read-only for authenticated users (vocabulary is public within workspace)
CREATE POLICY qxb_semantic_type_registry_select_authenticated
    ON public.qxb_semantic_type_registry
    FOR SELECT TO authenticated
    USING (true);

-- No INSERT/UPDATE/DELETE policies — writes via service_role only
-- (same pattern as qxb_gateway_acl: RLS enabled, zero write policies = deny-all)


-- qxb_semantic_type_audit: RLS enabled
ALTER TABLE public.qxb_semantic_type_audit ENABLE ROW LEVEL SECURITY;

-- Read-only for authenticated users (audit trail is readable)
CREATE POLICY qxb_semantic_type_audit_select_authenticated
    ON public.qxb_semantic_type_audit
    FOR SELECT TO authenticated
    USING (true);

-- No INSERT/UPDATE/DELETE policies for authenticated
-- Writes exclusively via update_semantic_type() RPC (SECURITY DEFINER bypasses RLS)
-- Triggers block UPDATE/DELETE regardless


-- =============================================================================
-- STEP 7: Update rollup view to include semantic_type_id
-- =============================================================================
-- Original view (T70) had: artifact_id, artifact_type, workspace_id,
--   total_active_children_count, completed_children_count, completion_ratio
-- Adding: semantic_type_id (from parent artifact)
-- DROP required: CREATE OR REPLACE cannot reorder columns on an existing view.
-- The original T70 view had (artifact_id, artifact_type, workspace_id, total_active_children_count, ...)
-- Adding semantic_type_id at position 4 shifts subsequent columns, which PostgreSQL rejects.

DROP VIEW IF EXISTS public.qxb_artifact_rollup_view;

CREATE VIEW public.qxb_artifact_rollup_view AS
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


-- =============================================================================
-- STEP 8: Create update_semantic_type() RPC function
-- =============================================================================
-- Atomic semantic type update + audit insert. Fail-closed: any DB error
-- in steps 7-8 (UPDATE spine + INSERT audit) rolls back the entire
-- function call automatically (PostgreSQL transaction semantics).
--
-- Called by: Update sub-workflow (DB_RPC_Update_Semantic_Type node)
--   POST /rest/v1/rpc/update_semantic_type
--   Body: { "p_artifact_id": "...", "p_new_semantic_type_id": "...",
--           "p_reason": "...", "p_actor_id": null }
--
-- Returns: jsonb with ok=true/false + error envelope on failure.

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
    -- ---------------------------------------------------------------
    -- 1. Validate reason is non-empty
    -- ---------------------------------------------------------------
    IF p_reason IS NULL OR length(trim(p_reason)) = 0 THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'VALIDATION_ERROR',
                'message', 'reason is required and must be non-empty'
            )
        );
    END IF;

    -- ---------------------------------------------------------------
    -- 2. Fetch artifact (existence + type + current semantic_type_id)
    -- ---------------------------------------------------------------
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

    -- ---------------------------------------------------------------
    -- 3. Validate artifact is a top-level type
    -- ---------------------------------------------------------------
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

    -- ---------------------------------------------------------------
    -- 4. Validate new semantic type exists and is active
    -- ---------------------------------------------------------------
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

    -- ---------------------------------------------------------------
    -- 5. Capture old value
    -- ---------------------------------------------------------------
    v_old_semantic_type_id := v_artifact.semantic_type_id;

    -- ---------------------------------------------------------------
    -- 6. No-op detection (same value = skip mutation)
    -- ---------------------------------------------------------------
    IF v_old_semantic_type_id IS NOT DISTINCT FROM p_new_semantic_type_id THEN
        RETURN jsonb_build_object(
            'ok', true,
            'noop', true,
            'message', 'semantic_type_id unchanged'
        );
    END IF;

    -- ---------------------------------------------------------------
    -- 7. ATOMIC: Update spine (semantic_type_id + version increment)
    --    updated_at is auto-set by qxb_artifact_set_updated_at trigger
    -- ---------------------------------------------------------------
    UPDATE public.qxb_artifact
    SET semantic_type_id = p_new_semantic_type_id,
        version = version + 1
    WHERE artifact_id = p_artifact_id
    RETURNING version INTO v_new_version;

    -- ---------------------------------------------------------------
    -- 8. ATOMIC: Insert audit row (same transaction as step 7)
    --    If this INSERT fails, PostgreSQL rolls back step 7 too.
    -- ---------------------------------------------------------------
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

    -- ---------------------------------------------------------------
    -- 9. Return success
    -- ---------------------------------------------------------------
    RETURN jsonb_build_object(
        'ok', true,
        'artifact_id', p_artifact_id,
        'old_semantic_type_id', v_old_semantic_type_id,
        'new_semantic_type_id', p_new_semantic_type_id,
        'version', v_new_version
    );
END;
$$;

COMMENT ON FUNCTION public.update_semantic_type(uuid, uuid, text, uuid) IS
  'T69: Atomic semantic type update + audit. Validates: artifact exists, is top-level, new type is active, reason non-empty. Increments version. Inserts audit row. Fail-closed: any DB error in UPDATE or INSERT rolls back entire transaction. Called via POST /rest/v1/rpc/update_semantic_type.';


-- =============================================================================
-- SECTION A VERIFICATION QUERIES (run after Section A to confirm)
-- =============================================================================

-- Verify registry seeded (expect 9 rows)
-- SELECT key, active, governance_snapshot_id FROM public.qxb_semantic_type_registry ORDER BY key;

-- Verify column exists on spine
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'qxb_artifact' AND column_name = 'semantic_type_id';

-- Verify RPC function exists
-- SELECT proname, prosecdef FROM pg_proc WHERE proname = 'update_semantic_type';

-- Verify rollup view has semantic_type_id
-- SELECT column_name FROM information_schema.columns
-- WHERE table_name = 'qxb_artifact_rollup_view' ORDER BY ordinal_position;

-- Verify RLS enabled on both new tables
-- SELECT tablename, rowsecurity FROM pg_tables
-- WHERE tablename IN ('qxb_semantic_type_registry', 'qxb_semantic_type_audit');


-- =============================================================================
-- SECTION B: Run AFTER backfill complete AND workflows deployed
-- =============================================================================
-- DO NOT RUN THIS until:
--   1. Backfill SQL has set all top-level artifacts to a valid semantic_type_id
--   2. Backfill verification shows 0 top-level artifacts with NULL semantic_type_id
--   3. Save workflow is deployed with semantic_type_id validation
--
-- This CHECK follows the lifecycle_status conditional pattern:
--   qxb_artifact_lifecycle_status_check:
--     CHECK ((artifact_type <> 'project') OR (lifecycle_status = ANY (...)))
--
-- Same logic: "if you are a top-level type, semantic_type_id must not be NULL"

-- ALTER TABLE public.qxb_artifact
--     ADD CONSTRAINT qxb_artifact_semantic_type_required_for_top_level
--     CHECK (
--         (artifact_type NOT IN ('project', 'snapshot', 'journal', 'restart'))
--         OR (semantic_type_id IS NOT NULL)
--     );

-- Verification after Step 9:
-- SELECT conname, contype, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'public.qxb_artifact'::regclass
--   AND conname = 'qxb_artifact_semantic_type_required_for_top_level';
