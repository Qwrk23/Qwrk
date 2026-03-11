-- ============================================================================
-- Migration: CmdCtr Phase 1 — Crawl Engine + Read Models
-- Date: 2026-03-07
-- Thread: T100
-- ============================================================================
-- CmdCtr is the system control plane for Qwrk. It is READ-ONLY with respect
-- to the artifact system. It MUST NOT bypass the Gateway mutation perimeter.
--
-- Phase 1 implements the Forest Crawl Engine:
--   - 3 read-model tables (full replacement on each crawl)
--   - 1 PL/pgSQL crawl function (cmdctr_run_crawl)
--   - pg_cron schedule (~5 minute cadence)
--
-- Read-model tables:
--   cmdctr_forest_state       — reconstructed artifact forest
--   cmdctr_execution_state    — dependency execution state
--   cmdctr_signal_candidates  — structural anomaly candidates
--
-- No canonical tables are modified.
-- ============================================================================


-- ============================================================================
-- TABLE: cmdctr_forest_state
-- ============================================================================
-- Reconstructed artifact forest. Full replacement on each crawl.

CREATE TABLE IF NOT EXISTS public.cmdctr_forest_state (
    workspace_id         uuid        NOT NULL,
    artifact_id          uuid        NOT NULL,
    artifact_type        text        NOT NULL,
    parent_artifact_id   uuid,
    root_project_id      uuid,
    depth                integer     NOT NULL DEFAULT 0,
    lifecycle_status     text,
    semantic_type_id     uuid,
    priority             integer,
    tags                 jsonb,
    execution_status     text,
    version              integer,
    crawled_at           timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (artifact_id)
);

COMMENT ON TABLE public.cmdctr_forest_state IS 'CmdCtr Phase 1: Reconstructed artifact forest. Full replacement on each crawl. Read-only observation model -- not a canonical table.';

CREATE INDEX IF NOT EXISTS idx_cmdctr_forest_state_workspace
    ON public.cmdctr_forest_state (workspace_id);

CREATE INDEX IF NOT EXISTS idx_cmdctr_forest_state_root_project
    ON public.cmdctr_forest_state (root_project_id)
    WHERE root_project_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_cmdctr_forest_state_type
    ON public.cmdctr_forest_state (artifact_type);


-- ============================================================================
-- TABLE: cmdctr_execution_state
-- ============================================================================
-- Dependency execution state. Full replacement on each crawl.

CREATE TABLE IF NOT EXISTS public.cmdctr_execution_state (
    artifact_id              uuid    NOT NULL,
    workspace_id             uuid    NOT NULL,
    dependency_count         integer NOT NULL DEFAULT 0,
    blocked_dependency_count integer NOT NULL DEFAULT 0,
    blocked_by               jsonb   NOT NULL DEFAULT '[]'::jsonb,
    dependents               jsonb   NOT NULL DEFAULT '[]'::jsonb,
    crawled_at               timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (artifact_id)
);

COMMENT ON TABLE public.cmdctr_execution_state IS 'CmdCtr Phase 1: Dependency execution state. blocked_by and dependents are JSONB arrays of artifact_id values. Full replacement on each crawl.';

CREATE INDEX IF NOT EXISTS idx_cmdctr_execution_state_workspace
    ON public.cmdctr_execution_state (workspace_id);

CREATE INDEX IF NOT EXISTS idx_cmdctr_execution_state_blocked
    ON public.cmdctr_execution_state (blocked_dependency_count)
    WHERE blocked_dependency_count > 0;


-- ============================================================================
-- TABLE: cmdctr_signal_candidates
-- ============================================================================
-- Structural anomaly candidates detected during crawl. Full replacement.

CREATE TABLE IF NOT EXISTS public.cmdctr_signal_candidates (
    signal_id      uuid        NOT NULL DEFAULT gen_random_uuid(),
    artifact_id    uuid        NOT NULL,
    workspace_id   uuid        NOT NULL,
    candidate_type text        NOT NULL,
    detected_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (signal_id)
);

COMMENT ON TABLE public.cmdctr_signal_candidates IS 'CmdCtr Phase 1: Candidate structural signals detected during crawl. Full replacement on each crawl. Historical tracking is out of scope for Phase 1.';

CREATE INDEX IF NOT EXISTS idx_cmdctr_signal_candidates_workspace
    ON public.cmdctr_signal_candidates (workspace_id);

CREATE INDEX IF NOT EXISTS idx_cmdctr_signal_candidates_type
    ON public.cmdctr_signal_candidates (candidate_type);


-- ============================================================================
-- RLS: Enable + Policies
-- ============================================================================
-- Crawl function runs as SECURITY DEFINER (bypasses RLS for writes).
-- Authenticated users get workspace-scoped read access.

ALTER TABLE public.cmdctr_forest_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cmdctr_execution_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cmdctr_signal_candidates ENABLE ROW LEVEL SECURITY;

-- Forest state: read via workspace membership
CREATE POLICY cmdctr_forest_state_select_member
    ON public.cmdctr_forest_state
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.qxb_workspace_user wsu
        WHERE wsu.workspace_id = cmdctr_forest_state.workspace_id
          AND wsu.user_id = public.qxb_current_user_id()
    ));

-- Execution state: read via workspace membership
CREATE POLICY cmdctr_execution_state_select_member
    ON public.cmdctr_execution_state
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.qxb_workspace_user wsu
        WHERE wsu.workspace_id = cmdctr_execution_state.workspace_id
          AND wsu.user_id = public.qxb_current_user_id()
    ));

-- Signal candidates: read via workspace membership
CREATE POLICY cmdctr_signal_candidates_select_member
    ON public.cmdctr_signal_candidates
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.qxb_workspace_user wsu
        WHERE wsu.workspace_id = cmdctr_signal_candidates.workspace_id
          AND wsu.user_id = public.qxb_current_user_id()
    ));


-- ============================================================================
-- FUNCTION: cmdctr_run_crawl()
-- ============================================================================
-- Executes the full CmdCtr Phase 1 crawl pipeline:
--   1. Forest graph reconstruction (recursive CTE with cycle detection)
--   2. Dependency graph reconstruction
--   3. Signal candidate detection
--   4. Full replacement write to all 3 read-model tables
--
-- Properties: deterministic, idempotent, rebuildable, workspace-isolated.
-- Runs as SECURITY DEFINER to bypass RLS for write operations.

CREATE OR REPLACE FUNCTION public.cmdctr_run_crawl()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
    v_start          timestamptz := clock_timestamp();
    v_crawl_ts       timestamptz := now();
    v_forest_count   integer;
    v_exec_count     integer;
    v_signal_count   integer;
BEGIN

    -- ========================================================================
    -- STEP 1: Rebuild cmdctr_forest_state
    -- ========================================================================
    -- Recursive CTE walks parent_artifact_id chains top-down.
    -- Computes root_project_id and depth for every active artifact.
    -- Tolerates missing parents and detects cycles via path array.

    DELETE FROM cmdctr_forest_state;

    WITH RECURSIVE forest AS (
        -- Base case: root artifacts
        -- An artifact is a root if it has no parent, or its parent is
        -- deleted/missing (tolerates broken parent references).
        SELECT
            a.artifact_id,
            a.workspace_id,
            a.artifact_type,
            a.parent_artifact_id,
            CASE
                WHEN a.artifact_type = 'project' THEN a.artifact_id
                ELSE NULL::uuid
            END AS root_project_id,
            0 AS depth,
            ARRAY[a.artifact_id] AS path
        FROM qxb_artifact a
        WHERE a.deleted_at IS NULL
          AND (
              a.parent_artifact_id IS NULL
              OR NOT EXISTS (
                  SELECT 1 FROM qxb_artifact p
                  WHERE p.artifact_id = a.parent_artifact_id
                    AND p.deleted_at IS NULL
              )
          )

        UNION ALL

        -- Recursive case: children
        -- Inherits root_project_id from parent. If parent has no
        -- root_project_id and this child is a project, it becomes
        -- its own root. Cycle detection via path array membership.
        SELECT
            c.artifact_id,
            c.workspace_id,
            c.artifact_type,
            c.parent_artifact_id,
            COALESCE(
                f.root_project_id,
                CASE
                    WHEN c.artifact_type = 'project' THEN c.artifact_id
                    ELSE NULL::uuid
                END
            ),
            f.depth + 1,
            f.path || c.artifact_id
        FROM qxb_artifact c
        JOIN forest f
            ON c.parent_artifact_id = f.artifact_id
        WHERE c.deleted_at IS NULL
          AND c.artifact_id != ALL(f.path)   -- cycle detection
          AND f.depth < 50                    -- depth safety limit
    )
    INSERT INTO cmdctr_forest_state (
        workspace_id, artifact_id, artifact_type, parent_artifact_id,
        root_project_id, depth, lifecycle_status, semantic_type_id,
        priority, tags, execution_status, version, crawled_at
    )
    SELECT
        f.workspace_id,
        f.artifact_id,
        f.artifact_type,
        f.parent_artifact_id,
        f.root_project_id,
        f.depth,
        a.lifecycle_status,
        a.semantic_type_id,
        a.priority,
        a.tags,
        a.execution_status,
        a.version,
        v_crawl_ts
    FROM forest f
    JOIN qxb_artifact a ON a.artifact_id = f.artifact_id;

    GET DIAGNOSTICS v_forest_count = ROW_COUNT;


    -- ========================================================================
    -- STEP 2: Rebuild cmdctr_execution_state
    -- ========================================================================
    -- Forward dependencies: what blocks each artifact.
    -- Reverse dependencies: what depends on each artifact.
    -- Blocked state derived from depends_on execution_status != 'complete'.

    DELETE FROM cmdctr_execution_state;

    INSERT INTO cmdctr_execution_state (
        artifact_id, workspace_id, dependency_count,
        blocked_dependency_count, blocked_by, dependents, crawled_at
    )
    SELECT
        COALESCE(fwd.artifact_id, rev.artifact_id)       AS artifact_id,
        COALESCE(fwd.workspace_id, rev.workspace_id)     AS workspace_id,
        COALESCE(fwd.dependency_count, 0)                AS dependency_count,
        COALESCE(fwd.blocked_dependency_count, 0)        AS blocked_dependency_count,
        COALESCE(fwd.blocked_by, '[]'::jsonb)            AS blocked_by,
        COALESCE(rev.dependents, '[]'::jsonb)            AS dependents,
        v_crawl_ts
    FROM (
        -- Forward: artifacts I depend on
        SELECT
            d.artifact_id,
            d.workspace_id,
            COUNT(*)::integer AS dependency_count,
            COUNT(*) FILTER (
                WHERE dep.execution_status IS DISTINCT FROM 'complete'
            )::integer AS blocked_dependency_count,
            COALESCE(
                jsonb_agg(d.depends_on_artifact_id) FILTER (
                    WHERE dep.execution_status IS DISTINCT FROM 'complete'
                ),
                '[]'::jsonb
            ) AS blocked_by
        FROM qxb_artifact_dependency d
        JOIN qxb_artifact dep
            ON dep.artifact_id = d.depends_on_artifact_id
            AND dep.deleted_at IS NULL
        JOIN qxb_artifact src
            ON src.artifact_id = d.artifact_id
            AND src.deleted_at IS NULL
        GROUP BY d.artifact_id, d.workspace_id
    ) fwd
    FULL OUTER JOIN (
        -- Reverse: artifacts that depend on me
        SELECT
            d.depends_on_artifact_id AS artifact_id,
            d.workspace_id,
            jsonb_agg(d.artifact_id) AS dependents
        FROM qxb_artifact_dependency d
        JOIN qxb_artifact dep
            ON dep.artifact_id = d.depends_on_artifact_id
            AND dep.deleted_at IS NULL
        JOIN qxb_artifact src
            ON src.artifact_id = d.artifact_id
            AND src.deleted_at IS NULL
        GROUP BY d.depends_on_artifact_id, d.workspace_id
    ) rev
        ON fwd.artifact_id = rev.artifact_id
        AND fwd.workspace_id = rev.workspace_id;

    GET DIAGNOSTICS v_exec_count = ROW_COUNT;


    -- ========================================================================
    -- STEP 3: Rebuild cmdctr_signal_candidates
    -- ========================================================================
    -- Provisional anomaly detection for Phase 2 Signal Engine.
    -- Full replacement -- no historical tracking in Phase 1.

    DELETE FROM cmdctr_signal_candidates;

    -- Signal: missing_parent
    -- Artifact references a parent that is deleted or does not exist.
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT a.artifact_id, a.workspace_id, 'missing_parent', v_crawl_ts
    FROM qxb_artifact a
    WHERE a.deleted_at IS NULL
      AND a.parent_artifact_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM qxb_artifact p
          WHERE p.artifact_id = a.parent_artifact_id
            AND p.deleted_at IS NULL
      );

    -- Signal: orphan_artifact
    -- Execution-anatomy type (branch, leaf, limb, twig) with no parent.
    -- These types are expected to live within a project tree.
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT a.artifact_id, a.workspace_id, 'orphan_artifact', v_crawl_ts
    FROM qxb_artifact a
    WHERE a.deleted_at IS NULL
      AND a.parent_artifact_id IS NULL
      AND a.artifact_type IN ('branch', 'leaf', 'limb', 'twig');

    -- Signal: blocked_project_root
    -- Project artifact with execution_status = 'blocked'.
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT a.artifact_id, a.workspace_id, 'blocked_project_root', v_crawl_ts
    FROM qxb_artifact a
    WHERE a.deleted_at IS NULL
      AND a.artifact_type = 'project'
      AND a.execution_status = 'blocked';

    -- Signal: deep_subtree
    -- Artifact at depth > 10 in the forest hierarchy.
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT artifact_id, workspace_id, 'deep_subtree', v_crawl_ts
    FROM cmdctr_forest_state
    WHERE depth > 10;

    SELECT COUNT(*) INTO v_signal_count FROM cmdctr_signal_candidates;


    -- ========================================================================
    -- RESULT
    -- ========================================================================

    RETURN jsonb_build_object(
        'ok',                    true,
        'crawl_ts',              v_crawl_ts,
        'duration_ms',           ROUND(extract(milliseconds FROM clock_timestamp() - v_start)),
        'forest_state_rows',     v_forest_count,
        'execution_state_rows',  v_exec_count,
        'signal_candidate_rows', v_signal_count
    );

END;
$fn$;

COMMENT ON FUNCTION public.cmdctr_run_crawl() IS 'CmdCtr Phase 1: Full forest crawl. Rebuilds all 3 read-model tables (cmdctr_forest_state, cmdctr_execution_state, cmdctr_signal_candidates). Deterministic, idempotent, rebuildable. Called by pg_cron on ~5 minute cadence.';


-- ============================================================================
-- pg_cron: Schedule crawl every 5 minutes
-- ============================================================================
-- Requires pg_cron extension (included in Supabase).
-- If pg_cron is not yet enabled, enable it via:
--   Supabase Dashboard > Database > Extensions > search "pg_cron" > Enable
-- Then run this schedule statement separately.

SELECT cron.schedule(
    'cmdctr-crawl-5min',
    '*/5 * * * *',
    $$SELECT public.cmdctr_run_crawl()$$
);
