-- ============================================================================
-- Migration: CmdCtr Phase 2 — Execution Awareness
-- Date: 2026-03-07
-- Thread: T100
-- Depends on: 2026-03-07__cmdctr_phase1_crawl_engine__v1.sql
-- ============================================================================
-- Extends CmdCtr Phase 1 with derived execution state, child aggregation,
-- and new signal types. CmdCtr remains READ-ONLY with respect to canonical
-- artifact tables.
--
-- Changes:
--   1. ALTER cmdctr_execution_state — add 6 columns for derived state
--   2. New index on execution_state
--   3. Replacement cmdctr_run_crawl() with Phase 2 logic
--
-- New derived fields:
--   execution_state     — deterministic derivation: ready|blocked|in_progress|complete
--   ready_child_count   — children with derived state = ready
--   active_child_count  — children with derived state = in_progress
--   complete_child_count — children with derived state = complete
--   total_child_count   — total direct children
--   completion_percent  — complete_child_count / total_child_count * 100
--
-- New signal types:
--   dependency_blocked   — artifact has unresolved structural dependencies
--   dependency_cycle     — artifact participates in dependency cycle
--   ready_to_execute     — structurally ready (QPM-suppressed for saplings)
--   execution_stalled    — in_progress but all children complete
--   orphan_execution     — active work under finished/missing parent
--
-- No canonical tables are modified.
-- ============================================================================


-- ============================================================================
-- STEP 1: ALTER cmdctr_execution_state — add Phase 2 columns
-- ============================================================================

ALTER TABLE public.cmdctr_execution_state
    ADD COLUMN IF NOT EXISTS execution_state       text,
    ADD COLUMN IF NOT EXISTS ready_child_count      integer NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS active_child_count     integer NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS complete_child_count   integer NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_child_count      integer NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS completion_percent     numeric(5,2) NOT NULL DEFAULT 0;


-- ============================================================================
-- STEP 2: Index on derived execution_state
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_cmdctr_execution_state_derived
    ON public.cmdctr_execution_state (execution_state)
    WHERE execution_state IN ('ready', 'blocked');


-- ============================================================================
-- STEP 3: Replace cmdctr_run_crawl() with Phase 2 logic
-- ============================================================================

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
    -- Unchanged from Phase 1.
    -- Recursive CTE walks parent_artifact_id chains top-down.
    -- Computes root_project_id and depth for every active artifact.
    -- Tolerates missing parents and detects cycles via path array.

    DELETE FROM cmdctr_forest_state;

    WITH RECURSIVE forest AS (
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
          AND c.artifact_id != ALL(f.path)
          AND f.depth < 50
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
    -- STEP 2: Rebuild cmdctr_execution_state (Phase 2)
    -- ========================================================================
    -- Multi-pass pipeline via CTE chain:
    --   Pass A: Dependency blocking (forward + reverse graphs)
    --   Pass B: Execution state derivation (deterministic priority rules)
    --   Pass C: Child count aggregation from forest + derived states
    --   Pass D: Final INSERT combining all passes
    --
    -- Execution state derivation priority (first match wins):
    --   1. complete  — canonical execution_status = 'complete'
    --                  OR lifecycle_status = 'archive'
    --                  OR twig lifecycle_status IN ('promoted', 'pruned')
    --   2. blocked   — blocked_dependency_count > 0
    --                  (structural block overrides canonical status)
    --   3. in_progress — canonical execution_status = 'in_progress'
    --   4. ready     — everything else (not_started, stale blocked, etc.)

    DELETE FROM cmdctr_execution_state;

    WITH
    -- Pass A: Forward dependencies (what blocks me)
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
        GROUP BY d.artifact_id, d.workspace_id
    ),
    -- Pass A cont: Reverse dependencies (what depends on me)
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
        GROUP BY d.depends_on_artifact_id, d.workspace_id
    ),
    -- Pass A combined: all artifacts that participate in dependency graph
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
    -- Pass B: Derive execution_state for every artifact in forest
    derived AS (
        SELECT
            fs.artifact_id,
            fs.workspace_id,
            COALESCE(dc.dependency_count, 0)                AS dependency_count,
            COALESCE(dc.blocked_dependency_count, 0)        AS blocked_dependency_count,
            COALESCE(dc.blocked_by, '[]'::jsonb)            AS blocked_by,
            COALESCE(dc.dependents, '[]'::jsonb)            AS dependents,
            -- Deterministic execution_state derivation
            CASE
                -- 1. COMPLETE: done by canonical status, archive, or twig terminal
                WHEN fs.execution_status = 'complete'
                    THEN 'complete'
                WHEN fs.lifecycle_status = 'archive'
                    THEN 'complete'
                WHEN fs.artifact_type = 'twig'
                     AND fs.lifecycle_status IN ('promoted', 'pruned')
                    THEN 'complete'
                -- 2. BLOCKED: structural dependency block overrides canonical
                WHEN COALESCE(dc.blocked_dependency_count, 0) > 0
                    THEN 'blocked'
                -- 3. IN_PROGRESS: canonical in_progress
                WHEN fs.execution_status = 'in_progress'
                    THEN 'in_progress'
                -- 4. READY: everything else
                ELSE 'ready'
            END AS execution_state
        FROM cmdctr_forest_state fs
        LEFT JOIN dep_combined dc
            ON dc.artifact_id = fs.artifact_id
            AND dc.workspace_id = fs.workspace_id
    ),
    -- Pass C: Child count aggregation from forest + derived states
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
        GROUP BY fs_parent.artifact_id
    )
    -- Pass D: Final INSERT
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
    -- STEP 3: Rebuild cmdctr_signal_candidates (Phase 2)
    -- ========================================================================
    -- Phase 1 signals preserved. Phase 2 adds 5 new signal types.

    DELETE FROM cmdctr_signal_candidates;

    -- ---- Phase 1 signals (unchanged) ----

    -- Signal: missing_parent
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
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT a.artifact_id, a.workspace_id, 'orphan_artifact', v_crawl_ts
    FROM qxb_artifact a
    WHERE a.deleted_at IS NULL
      AND a.parent_artifact_id IS NULL
      AND a.artifact_type IN ('branch', 'leaf', 'limb', 'twig');

    -- Signal: blocked_project_root
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT a.artifact_id, a.workspace_id, 'blocked_project_root', v_crawl_ts
    FROM qxb_artifact a
    WHERE a.deleted_at IS NULL
      AND a.artifact_type = 'project'
      AND a.execution_status = 'blocked';

    -- Signal: deep_subtree
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT artifact_id, workspace_id, 'deep_subtree', v_crawl_ts
    FROM cmdctr_forest_state
    WHERE depth > 10;

    -- ---- Phase 2 signals (new) ----

    -- Signal: dependency_blocked
    -- Artifact has unresolved structural dependencies.
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT artifact_id, workspace_id, 'dependency_blocked', v_crawl_ts
    FROM cmdctr_execution_state
    WHERE blocked_dependency_count > 0;

    -- Signal: dependency_cycle
    -- Artifact participates in a cycle in qxb_artifact_dependency graph.
    -- Recursive CTE with path tracking detects cycles. Read-only — no repair.
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT DISTINCT cycle_member, ws.workspace_id, 'dependency_cycle', v_crawl_ts
    FROM (
        WITH RECURSIVE dep_walk AS (
            SELECT
                d.artifact_id AS origin,
                d.depends_on_artifact_id AS current_node,
                ARRAY[d.artifact_id] AS path,
                false AS is_cycle
            FROM qxb_artifact_dependency d
            JOIN qxb_artifact a ON a.artifact_id = d.artifact_id AND a.deleted_at IS NULL

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
    ) cycles
    JOIN qxb_artifact ws ON ws.artifact_id = cycles.cycle_member AND ws.deleted_at IS NULL;

    -- Signal: ready_to_execute
    -- Structurally ready and eligible for work.
    --
    -- QPM SUPPRESSION (Phase 2): Saplings are structurally ready but NOT
    -- governance-approved for execution. ready_to_execute signals are
    -- suppressed for projects with lifecycle_stage = 'sapling' on the
    -- project extension table (qxb_artifact_project).
    --
    -- Structural readiness != semantic executability.
    -- Full QPM-aware execution semantics are reserved for a future phase.
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT es.artifact_id, es.workspace_id, 'ready_to_execute', v_crawl_ts
    FROM cmdctr_execution_state es
    WHERE es.execution_state = 'ready'
      -- QPM suppression: exclude saplings
      AND NOT EXISTS (
          SELECT 1 FROM qxb_artifact_project p
          WHERE p.artifact_id = es.artifact_id
            AND p.lifecycle_stage = 'sapling'
      );

    -- Signal: execution_stalled
    -- Artifact is in_progress but all direct children are complete.
    -- Parent hasn't been marked done despite all child work being finished.
    -- Purely structural heuristic — no timestamp/telemetry dependency.
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT es.artifact_id, es.workspace_id, 'execution_stalled', v_crawl_ts
    FROM cmdctr_execution_state es
    WHERE es.execution_state = 'in_progress'
      AND es.total_child_count > 0
      AND es.complete_child_count = es.total_child_count;

    -- Signal: orphan_execution
    -- Artifact is actively in_progress but is structurally disconnected:
    --   (a) execution-anatomy type with no parent, OR
    --   (b) parent is complete or archived
    -- Detects active work under a finished or missing parent.
    INSERT INTO cmdctr_signal_candidates
        (artifact_id, workspace_id, candidate_type, detected_at)
    SELECT fs.artifact_id, fs.workspace_id, 'orphan_execution', v_crawl_ts
    FROM cmdctr_forest_state fs
    JOIN cmdctr_execution_state es
        ON es.artifact_id = fs.artifact_id
    WHERE es.execution_state = 'in_progress'
      AND fs.artifact_type IN ('branch', 'leaf', 'limb', 'twig')
      AND (
          -- (a) No parent at all
          fs.parent_artifact_id IS NULL
          OR
          -- (b) Parent is complete or archived
          EXISTS (
              SELECT 1 FROM qxb_artifact parent
              WHERE parent.artifact_id = fs.parent_artifact_id
                AND parent.deleted_at IS NULL
                AND (
                    parent.execution_status = 'complete'
                    OR parent.lifecycle_status = 'archive'
                )
          )
      );

    SELECT COUNT(*) INTO v_signal_count FROM cmdctr_signal_candidates;


    -- ========================================================================
    -- RESULT
    -- ========================================================================

    RETURN jsonb_build_object(
        'ok',                    true,
        'phase',                 2,
        'crawl_ts',              v_crawl_ts,
        'duration_ms',           ROUND(extract(milliseconds FROM clock_timestamp() - v_start)),
        'forest_state_rows',     v_forest_count,
        'execution_state_rows',  v_exec_count,
        'signal_candidate_rows', v_signal_count
    );

END;
$fn$;

COMMENT ON FUNCTION public.cmdctr_run_crawl() IS 'CmdCtr Phase 2: Full forest crawl with execution awareness. Rebuilds all 3 read-model tables. Derives execution_state (ready/blocked/in_progress/complete), child aggregation, and 9 signal types. Deterministic, idempotent, rebuildable. Called by pg_cron on ~5 minute cadence.';
