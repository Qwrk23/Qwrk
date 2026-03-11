-- ============================================================================
-- Migration: CmdCtr Phase 3 -- Telemetry, Crawl Queue, Workspace Isolation
-- Date: 2026-03-07
-- Thread: T100
-- Depends on: 2026-03-07__cmdctr_phase2_execution_awareness__v1.sql
-- ============================================================================
-- Adds operational infrastructure missing from Phase 1/2:
--   1. cmdctr_crawl_runs       -- telemetry table (crawl health + performance)
--   2. cmdctr_crawl_queue      -- decoupled scheduling queue
--   3. cmdctr_run_crawl(uuid)  -- workspace-scoped crawl overload
--   4. Composite indexes       -- prevent cross-tenant scans
--   5. Upgraded parameterless cmdctr_run_crawl() -- delegates per-workspace
--
-- SYSTEM INVARIANT: workspace = forest boundary.
-- No cross-workspace data in any CmdCtr table.
-- CmdCtr MUST NOT mutate canonical artifact tables.
--
-- Additive migration only. No drops. Safe to run in production.
-- ============================================================================


-- ============================================================================
-- TABLE: cmdctr_crawl_runs (Telemetry)
-- ============================================================================
-- Tracks crawl health and performance per workspace per run.

CREATE TABLE IF NOT EXISTS public.cmdctr_crawl_runs (
    crawl_run_id         uuid        NOT NULL DEFAULT gen_random_uuid(),
    workspace_id         uuid        NOT NULL,
    crawl_started_at     timestamptz NOT NULL DEFAULT now(),
    crawl_finished_at    timestamptz,
    duration_ms          integer,
    artifacts_processed  integer     NOT NULL DEFAULT 0,
    signals_generated    integer     NOT NULL DEFAULT 0,
    errors_detected      integer     NOT NULL DEFAULT 0,
    status               text        NOT NULL DEFAULT 'running'
                         CHECK (status IN ('running', 'complete', 'error')),
    error_detail         text,
    PRIMARY KEY (crawl_run_id)
);

COMMENT ON TABLE public.cmdctr_crawl_runs IS 'CmdCtr Phase 3: Crawl telemetry. One row per workspace per crawl run. Tracks duration, artifact count, signal count, and error state.';

CREATE INDEX IF NOT EXISTS idx_cmdctr_crawl_runs_workspace_started
    ON public.cmdctr_crawl_runs (workspace_id, crawl_started_at DESC);

CREATE INDEX IF NOT EXISTS idx_cmdctr_crawl_runs_status
    ON public.cmdctr_crawl_runs (status)
    WHERE status = 'running';


-- ============================================================================
-- TABLE: cmdctr_crawl_queue
-- ============================================================================
-- Decouples scheduling from execution. Workers pull from this queue.

CREATE TABLE IF NOT EXISTS public.cmdctr_crawl_queue (
    queue_id             uuid        NOT NULL DEFAULT gen_random_uuid(),
    workspace_id         uuid        NOT NULL,
    requested_at         timestamptz NOT NULL DEFAULT now(),
    status               text        NOT NULL DEFAULT 'pending'
                         CHECK (status IN ('pending', 'processing', 'complete', 'error')),
    attempts             integer     NOT NULL DEFAULT 0,
    last_attempt_at      timestamptz,
    error_detail         text,
    PRIMARY KEY (queue_id)
);

COMMENT ON TABLE public.cmdctr_crawl_queue IS 'CmdCtr Phase 3: Crawl scheduling queue. Workers pull pending entries and execute workspace-scoped crawls. Decouples scheduling from execution.';

CREATE INDEX IF NOT EXISTS idx_cmdctr_crawl_queue_pending
    ON public.cmdctr_crawl_queue (requested_at)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_cmdctr_crawl_queue_workspace
    ON public.cmdctr_crawl_queue (workspace_id, requested_at DESC);


-- ============================================================================
-- RLS: Enable + Policies on new tables
-- ============================================================================

ALTER TABLE public.cmdctr_crawl_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cmdctr_crawl_queue ENABLE ROW LEVEL SECURITY;

-- Crawl runs: read via workspace membership
CREATE POLICY cmdctr_crawl_runs_select_member
    ON public.cmdctr_crawl_runs
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.qxb_workspace_user wsu
        WHERE wsu.workspace_id = cmdctr_crawl_runs.workspace_id
          AND wsu.user_id = public.qxb_current_user_id()
    ));

-- Crawl queue: read via workspace membership
CREATE POLICY cmdctr_crawl_queue_select_member
    ON public.cmdctr_crawl_queue
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.qxb_workspace_user wsu
        WHERE wsu.workspace_id = cmdctr_crawl_queue.workspace_id
          AND wsu.user_id = public.qxb_current_user_id()
    ));


-- ============================================================================
-- COMPOSITE INDEXES on existing tables (prevent cross-tenant scans)
-- ============================================================================

-- cmdctr_forest_state composites
CREATE INDEX IF NOT EXISTS idx_cmdctr_forest_state_ws_artifact
    ON public.cmdctr_forest_state (workspace_id, artifact_id);

CREATE INDEX IF NOT EXISTS idx_cmdctr_forest_state_ws_parent
    ON public.cmdctr_forest_state (workspace_id, parent_artifact_id)
    WHERE parent_artifact_id IS NOT NULL;

-- cmdctr_execution_state composites
CREATE INDEX IF NOT EXISTS idx_cmdctr_execution_state_ws_artifact
    ON public.cmdctr_execution_state (workspace_id, artifact_id);

CREATE INDEX IF NOT EXISTS idx_cmdctr_execution_state_ws_execstate
    ON public.cmdctr_execution_state (workspace_id, execution_state);

-- cmdctr_signal_candidates composites
CREATE INDEX IF NOT EXISTS idx_cmdctr_signal_candidates_ws_type
    ON public.cmdctr_signal_candidates (workspace_id, candidate_type);


-- ============================================================================
-- FUNCTION: cmdctr_run_crawl(p_workspace_id uuid) -- WORKSPACE-SCOPED
-- ============================================================================
-- New overloaded function. Crawls a SINGLE workspace.
-- Replaces only that workspace rows in read-model tables (not global DELETE).
-- Records telemetry in cmdctr_crawl_runs.
--
-- Properties: deterministic, idempotent, rebuildable, workspace-isolated.
-- Runs as SECURITY DEFINER to bypass RLS for write operations.

CREATE OR REPLACE FUNCTION public.cmdctr_run_crawl(p_workspace_id uuid)
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
    v_run_id         uuid;
    v_error_count    integer := 0;
BEGIN

    -- ========================================================================
    -- VALIDATION: workspace_id must be valid
    -- ========================================================================

    IF p_workspace_id IS NULL THEN
        RAISE EXCEPTION 'workspace_id required';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM qxb_workspace
        WHERE workspace_id = p_workspace_id
    ) THEN
        RAISE EXCEPTION 'invalid workspace_id: %', p_workspace_id;
    END IF;

    -- ========================================================================
    -- TELEMETRY: Start run
    -- ========================================================================

    INSERT INTO cmdctr_crawl_runs (workspace_id, crawl_started_at, status)
    VALUES (p_workspace_id, v_crawl_ts, 'running')
    RETURNING crawl_run_id INTO v_run_id;

    -- ========================================================================
    -- STEP 1: Rebuild cmdctr_forest_state (workspace-scoped)
    -- ========================================================================
    -- Delete only this workspace rows, then rebuild.

    DELETE FROM cmdctr_forest_state
    WHERE workspace_id = p_workspace_id;

    WITH RECURSIVE forest AS (
        -- Base case: root artifacts in this workspace
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
          AND a.workspace_id = p_workspace_id
          AND (
              a.parent_artifact_id IS NULL
              OR NOT EXISTS (
                  SELECT 1 FROM qxb_artifact p
                  WHERE p.artifact_id = a.parent_artifact_id
                    AND p.deleted_at IS NULL
                    AND p.workspace_id = p_workspace_id
              )
          )

        UNION ALL

        -- Recursive case: children within same workspace
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
          AND c.workspace_id = p_workspace_id
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
    -- STEP 2: Rebuild cmdctr_execution_state (workspace-scoped, Phase 2 logic)
    -- ========================================================================

    DELETE FROM cmdctr_execution_state
    WHERE workspace_id = p_workspace_id;

    WITH
    -- Pass A: Forward dependencies (what blocks me) -- workspace-scoped
    fwd AS (
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
        WHERE d.workspace_id = p_workspace_id
        GROUP BY d.artifact_id, d.workspace_id
    ),
    -- Pass A cont: Reverse dependencies (what depends on me) -- workspace-scoped
    rev AS (
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
        WHERE d.workspace_id = p_workspace_id
        GROUP BY d.depends_on_artifact_id, d.workspace_id
    ),
    dep_combined AS (
        SELECT
            COALESCE(fwd.artifact_id, rev.artifact_id)       AS artifact_id,
            COALESCE(fwd.workspace_id, rev.workspace_id)     AS workspace_id,
            COALESCE(fwd.dependency_count, 0)                AS dependency_count,
            COALESCE(fwd.blocked_dependency_count, 0)        AS blocked_dependency_count,
            COALESCE(fwd.blocked_by, '[]'::jsonb)            AS blocked_by,
            COALESCE(rev.dependents, '[]'::jsonb)            AS dependents
        FROM fwd
        FULL OUTER JOIN rev
            ON fwd.artifact_id = rev.artifact_id
            AND fwd.workspace_id = rev.workspace_id
    ),
    -- Pass B: Derive execution_state for this workspace forest
    derived AS (
        SELECT
            fs.artifact_id,
            fs.workspace_id,
            COALESCE(dc.dependency_count, 0)                AS dependency_count,
            COALESCE(dc.blocked_dependency_count, 0)        AS blocked_dependency_count,
            COALESCE(dc.blocked_by, '[]'::jsonb)            AS blocked_by,
            COALESCE(dc.dependents, '[]'::jsonb)            AS dependents,
            CASE
                WHEN fs.execution_status = 'complete'
                    THEN 'complete'
                WHEN fs.lifecycle_status = 'archive'
                    THEN 'complete'
                WHEN fs.artifact_type = 'twig'
                     AND fs.lifecycle_status IN ('promoted', 'pruned')
                    THEN 'complete'
                WHEN COALESCE(dc.blocked_dependency_count, 0) > 0
                    THEN 'blocked'
                WHEN fs.execution_status = 'in_progress'
                    THEN 'in_progress'
                ELSE 'ready'
            END AS execution_state
        FROM cmdctr_forest_state fs
        LEFT JOIN dep_combined dc
            ON dc.artifact_id = fs.artifact_id
            AND dc.workspace_id = fs.workspace_id
        WHERE fs.workspace_id = p_workspace_id
    ),
    -- Pass C: Child count aggregation
    child_agg AS (
        SELECT
            fs_parent.artifact_id,
            COUNT(*)::integer AS total_child_count,
            COUNT(*) FILTER (WHERE d_child.execution_state = 'ready')::integer
                AS ready_child_count,
            COUNT(*) FILTER (WHERE d_child.execution_state = 'in_progress')::integer
                AS active_child_count,
            COUNT(*) FILTER (WHERE d_child.execution_state = 'complete')::integer
                AS complete_child_count
        FROM cmdctr_forest_state fs_child
        JOIN cmdctr_forest_state fs_parent
            ON fs_child.parent_artifact_id = fs_parent.artifact_id
        JOIN derived d_child
            ON d_child.artifact_id = fs_child.artifact_id
        WHERE fs_child.workspace_id = p_workspace_id
        GROUP BY fs_parent.artifact_id
    )
    INSERT INTO cmdctr_execution_state (
        artifact_id, workspace_id, dependency_count,
        blocked_dependency_count, blocked_by, dependents,
        execution_state,
        ready_child_count, active_child_count,
        complete_child_count, total_child_count, completion_percent,
        crawled_at
    )
    SELECT
        d.artifact_id,
        d.workspace_id,
        d.dependency_count,
        d.blocked_dependency_count,
        d.blocked_by,
        d.dependents,
        d.execution_state,
        COALESCE(ca.ready_child_count, 0),
        COALESCE(ca.active_child_count, 0),
        COALESCE(ca.complete_child_count, 0),
        COALESCE(ca.total_child_count, 0),
        CASE
            WHEN COALESCE(ca.total_child_count, 0) = 0 THEN 0
            ELSE ROUND(
                COALESCE(ca.complete_child_count, 0)::numeric
                / ca.total_child_count * 100, 2
            )
        END,
        v_crawl_ts
    FROM derived d
    LEFT JOIN child_agg ca ON ca.artifact_id = d.artifact_id;

    GET DIAGNOSTICS v_exec_count = ROW_COUNT;


    -- ========================================================================
    -- STEP 3: Rebuild cmdctr_signal_candidates (workspace-scoped)
    -- ========================================================================

    DELETE FROM cmdctr_signal_candidates
    WHERE workspace_id = p_workspace_id;

    -- Signal: missing_parent
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT a.artifact_id, a.workspace_id, 'missing_parent', v_crawl_ts
    FROM qxb_artifact a
    WHERE a.deleted_at IS NULL
      AND a.workspace_id = p_workspace_id
      AND a.parent_artifact_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM qxb_artifact p
          WHERE p.artifact_id = a.parent_artifact_id
            AND p.deleted_at IS NULL
      );

    -- Signal: orphan_artifact
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT a.artifact_id, a.workspace_id, 'orphan_artifact', v_crawl_ts
    FROM qxb_artifact a
    WHERE a.deleted_at IS NULL
      AND a.workspace_id = p_workspace_id
      AND a.parent_artifact_id IS NULL
      AND a.artifact_type IN ('branch', 'leaf', 'limb', 'twig');

    -- Signal: blocked_project_root
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT a.artifact_id, a.workspace_id, 'blocked_project_root', v_crawl_ts
    FROM qxb_artifact a
    WHERE a.deleted_at IS NULL
      AND a.workspace_id = p_workspace_id
      AND a.artifact_type = 'project'
      AND a.execution_status = 'blocked';

    -- Signal: deep_subtree
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT artifact_id, workspace_id, 'deep_subtree', v_crawl_ts
    FROM cmdctr_forest_state
    WHERE workspace_id = p_workspace_id
      AND depth > 10;

    -- Signal: dependency_blocked
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT artifact_id, workspace_id, 'dependency_blocked', v_crawl_ts
    FROM cmdctr_execution_state
    WHERE workspace_id = p_workspace_id
      AND blocked_dependency_count > 0;

    -- Signal: dependency_cycle
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT DISTINCT cycle_member, p_workspace_id, 'dependency_cycle', v_crawl_ts
    FROM (
        WITH RECURSIVE dep_walk AS (
            SELECT
                d.artifact_id AS origin,
                d.depends_on_artifact_id AS current_node,
                ARRAY[d.artifact_id] AS path,
                false AS is_cycle
            FROM qxb_artifact_dependency d
            JOIN qxb_artifact a ON a.artifact_id = d.artifact_id
                AND a.deleted_at IS NULL
            WHERE d.workspace_id = p_workspace_id

            UNION ALL

            SELECT
                dw.origin,
                d.depends_on_artifact_id,
                dw.path || d.artifact_id,
                d.depends_on_artifact_id = ANY(dw.path)
            FROM dep_walk dw
            JOIN qxb_artifact_dependency d
                ON d.artifact_id = dw.current_node
            WHERE NOT dw.is_cycle
              AND array_length(dw.path, 1) < 50
        )
        SELECT DISTINCT unnest(path) AS cycle_member
        FROM dep_walk
        WHERE is_cycle
    ) cycles;

    -- Signal: ready_to_execute (with QPM sapling suppression)
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT es.artifact_id, es.workspace_id, 'ready_to_execute', v_crawl_ts
    FROM cmdctr_execution_state es
    WHERE es.workspace_id = p_workspace_id
      AND es.execution_state = 'ready'
      AND NOT EXISTS (
          SELECT 1 FROM qxb_artifact_project p
          WHERE p.artifact_id = es.artifact_id
            AND p.lifecycle_stage = 'sapling'
      );

    -- Signal: execution_stalled
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT es.artifact_id, es.workspace_id, 'execution_stalled', v_crawl_ts
    FROM cmdctr_execution_state es
    WHERE es.workspace_id = p_workspace_id
      AND es.execution_state = 'in_progress'
      AND es.total_child_count > 0
      AND es.complete_child_count = es.total_child_count;

    -- Signal: orphan_execution
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT fs.artifact_id, fs.workspace_id, 'orphan_execution', v_crawl_ts
    FROM cmdctr_forest_state fs
    JOIN cmdctr_execution_state es
        ON es.artifact_id = fs.artifact_id
    WHERE fs.workspace_id = p_workspace_id
      AND es.execution_state = 'in_progress'
      AND fs.artifact_type IN ('branch', 'leaf', 'limb', 'twig')
      AND (
          fs.parent_artifact_id IS NULL
          OR EXISTS (
              SELECT 1 FROM qxb_artifact parent
              WHERE parent.artifact_id = fs.parent_artifact_id
                AND parent.deleted_at IS NULL
                AND (
                    parent.execution_status = 'complete'
                    OR parent.lifecycle_status = 'archive'
                )
          )
      );

    SELECT COUNT(*) INTO v_signal_count
    FROM cmdctr_signal_candidates
    WHERE workspace_id = p_workspace_id;


    -- ========================================================================
    -- TELEMETRY: Complete run
    -- ========================================================================

    UPDATE cmdctr_crawl_runs
    SET crawl_finished_at = clock_timestamp(),
        duration_ms       = ROUND(extract(milliseconds FROM clock_timestamp() - v_start))::integer,
        artifacts_processed = v_forest_count,
        signals_generated   = v_signal_count,
        errors_detected     = v_error_count,
        status              = 'complete'
    WHERE crawl_run_id = v_run_id;


    -- ========================================================================
    -- RESULT
    -- ========================================================================

    RETURN jsonb_build_object(
        'ok',                    true,
        'phase',                 3,
        'workspace_id',          p_workspace_id,
        'crawl_run_id',          v_run_id,
        'crawl_ts',              v_crawl_ts,
        'duration_ms',           ROUND(extract(milliseconds FROM clock_timestamp() - v_start)),
        'forest_state_rows',     v_forest_count,
        'execution_state_rows',  v_exec_count,
        'signal_candidate_rows', v_signal_count
    );

EXCEPTION WHEN OTHERS THEN
    -- Record error in telemetry if run was started
    IF v_run_id IS NOT NULL THEN
        UPDATE cmdctr_crawl_runs
        SET crawl_finished_at = clock_timestamp(),
            duration_ms       = ROUND(extract(milliseconds FROM clock_timestamp() - v_start))::integer,
            errors_detected   = 1,
            status            = 'error',
            error_detail      = SQLERRM
        WHERE crawl_run_id = v_run_id;
    END IF;

    RETURN jsonb_build_object(
        'ok',    false,
        'error', SQLERRM,
        'workspace_id', p_workspace_id
    );

END;
$fn$;

COMMENT ON FUNCTION public.cmdctr_run_crawl(uuid) IS 'CmdCtr Phase 3: Workspace-scoped crawl. Rebuilds read-model tables for a single workspace. Records telemetry. Validates workspace_id. Deterministic, idempotent, workspace-isolated.';


-- ============================================================================
-- FUNCTION: cmdctr_run_crawl() -- UPGRADED to delegate per-workspace
-- ============================================================================
-- The parameterless version now iterates over all active workspaces and
-- delegates to the workspace-scoped overload. Each workspace crawl is
-- independent -- one failure does not block others.

CREATE OR REPLACE FUNCTION public.cmdctr_run_crawl()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
    v_start          timestamptz := clock_timestamp();
    v_ws             record;
    v_result         jsonb;
    v_results        jsonb := '[]'::jsonb;
    v_ws_count       integer := 0;
    v_error_count    integer := 0;
BEGIN

    FOR v_ws IN
        SELECT workspace_id FROM qxb_workspace ORDER BY workspace_id
    LOOP
        v_ws_count := v_ws_count + 1;

        BEGIN
            v_result := cmdctr_run_crawl(v_ws.workspace_id);
            v_results := v_results || v_result;

            IF NOT (v_result->>'ok')::boolean THEN
                v_error_count := v_error_count + 1;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_results := v_results || jsonb_build_object(
                'ok', false,
                'workspace_id', v_ws.workspace_id,
                'error', SQLERRM
            );
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'ok',               v_error_count = 0,
        'phase',            3,
        'workspaces_crawled', v_ws_count,
        'errors',           v_error_count,
        'duration_ms',      ROUND(extract(milliseconds FROM clock_timestamp() - v_start)),
        'results',          v_results
    );

END;
$fn$;

COMMENT ON FUNCTION public.cmdctr_run_crawl() IS 'CmdCtr Phase 3: Multi-workspace crawl dispatcher. Iterates all workspaces and delegates to cmdctr_run_crawl(uuid). Each workspace crawl is independent -- one failure does not block others. Called by pg_cron on ~5 minute cadence.';


-- ============================================================================
-- HELPER: cmdctr_process_queue() -- Pull and execute from crawl queue
-- ============================================================================
-- Workers call this to process the next pending crawl request.

CREATE OR REPLACE FUNCTION public.cmdctr_process_queue()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
    v_queue_id       uuid;
    v_workspace_id   uuid;
    v_result         jsonb;
BEGIN

    -- Atomically claim the next pending request
    UPDATE cmdctr_crawl_queue
    SET status = 'processing',
        attempts = attempts + 1,
        last_attempt_at = now()
    WHERE queue_id = (
        SELECT queue_id
        FROM cmdctr_crawl_queue
        WHERE status = 'pending'
        ORDER BY requested_at
        LIMIT 1
        FOR UPDATE SKIP LOCKED
    )
    RETURNING queue_id, workspace_id
    INTO v_queue_id, v_workspace_id;

    IF v_queue_id IS NULL THEN
        RETURN jsonb_build_object('ok', true, 'message', 'no pending crawl requests');
    END IF;

    -- Execute workspace-scoped crawl
    BEGIN
        v_result := cmdctr_run_crawl(v_workspace_id);

        UPDATE cmdctr_crawl_queue
        SET status = 'complete'
        WHERE queue_id = v_queue_id;

        RETURN v_result;

    EXCEPTION WHEN OTHERS THEN
        UPDATE cmdctr_crawl_queue
        SET status = 'error',
            error_detail = SQLERRM
        WHERE queue_id = v_queue_id;

        RETURN jsonb_build_object(
            'ok', false,
            'workspace_id', v_workspace_id,
            'error', SQLERRM
        );
    END;

END;
$fn$;

COMMENT ON FUNCTION public.cmdctr_process_queue() IS 'CmdCtr Phase 3: Queue worker. Atomically claims next pending crawl request and executes workspace-scoped crawl. Uses SKIP LOCKED for safe parallel processing.';
