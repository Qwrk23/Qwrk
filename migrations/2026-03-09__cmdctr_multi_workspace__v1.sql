-- =============================================================================
-- Migration: CmdCtr Multi-Workspace Enablement
-- Date:      2026-03-09
-- Purpose:   Parameterize cmdctr_build_session_context, cmdctr_render_session_markdown,
--            and cmdctr_operator_briefing for workspace isolation.
--
-- Problem:   These 3 functions have no workspace_id parameter. They read from
--            cmdctr_* read-model tables WITHOUT workspace filters, and
--            operator_briefing hardcodes Prime workspace/owner UUIDs.
--            Once Q@W is crawled, unscoped reads would silently merge data
--            from multiple workspaces.
--
-- Approach:  DROP no-arg overloads, CREATE new versions with
--            p_workspace_id uuid DEFAULT 'be0d3a48-...' (Prime).
--            Existing callers using no args get identical Prime behavior.
--            New Q@W callers pass workspace_id explicitly.
--
-- Functions NOT modified (already correct):
--   cmdctr_run_crawl(p_workspace_id uuid)  -- already workspace-scoped
--   cmdctr_run_crawl()                      -- convenience wrapper, delegates to above
--   cmdctr_process_queue()                  -- reads workspace_id from queue, passes to run_crawl
--
-- Rollback:  Re-run the original migration files:
--   2026-03-07__cmdctr_session_context_builder__v1.sql
--   2026-03-07__cmdctr_render_markdown__v1.sql
--   2026-03-07__cmdctr_operator_briefing__v1.sql
-- =============================================================================

BEGIN;

-- ============================================================================
-- 1. cmdctr_build_session_context(p_workspace_id uuid)
-- ============================================================================
-- Drop the no-arg version first (CREATE OR REPLACE cannot change arg list)
DROP FUNCTION IF EXISTS cmdctr_build_session_context();

CREATE OR REPLACE FUNCTION public.cmdctr_build_session_context(
    p_workspace_id uuid DEFAULT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    -- Crawl metadata
    v_crawl_ts          timestamptz;

    -- Health
    v_forest_rows       integer;
    v_exec_rows         integer;
    v_signal_total      integer;
    v_signals_by_type   jsonb;
    v_has_cycles        boolean;
    v_has_blockers      boolean;
    v_has_stalls        boolean;

    -- Active surface
    v_in_progress       jsonb;
    v_blocked           jsonb;
    v_stalled           jsonb;
    v_cycles            jsonb;
    v_ready_total       integer;
    v_ready_by_type     jsonb;
    v_exec_anat_ready   integer;

    -- Prior session context
    v_prior_payload     jsonb;
    v_prior_ts          timestamptz;
    v_prior_version     integer;

    -- Delta
    v_new_blockers      jsonb;
    v_cleared_blockers  jsonb;
    v_newly_in_progress jsonb;
    v_newly_completed   jsonb;
    v_new_signals       jsonb;
    v_cleared_signals   jsonb;
    v_forest_change     integer;
    v_delta_summary     text;

    -- Operator note
    v_operator_note     text;
BEGIN

    -- ====================================================================
    -- CRAWL TIMESTAMP (workspace-scoped)
    -- ====================================================================

    SELECT crawled_at INTO v_crawl_ts
    FROM cmdctr_forest_state
    WHERE workspace_id = p_workspace_id
    LIMIT 1;

    IF v_crawl_ts IS NULL THEN
        RETURN jsonb_build_object(
            'version', 1,
            'error', 'No CmdCtr crawl data available for workspace ' || p_workspace_id || '. Run cmdctr_run_crawl(''' || p_workspace_id || ''') first.'
        );
    END IF;


    -- ====================================================================
    -- SECTION 1: HEALTH HEADER (workspace-scoped)
    -- ====================================================================

    SELECT COUNT(*) INTO v_forest_rows  FROM cmdctr_forest_state      WHERE workspace_id = p_workspace_id;
    SELECT COUNT(*) INTO v_exec_rows    FROM cmdctr_execution_state    WHERE workspace_id = p_workspace_id;
    SELECT COUNT(*) INTO v_signal_total FROM cmdctr_signal_candidates  WHERE workspace_id = p_workspace_id;

    SELECT COALESCE(jsonb_object_agg(candidate_type, cnt), '{}'::jsonb)
    INTO v_signals_by_type
    FROM (
        SELECT candidate_type, COUNT(*) AS cnt
        FROM cmdctr_signal_candidates
        WHERE workspace_id = p_workspace_id
        GROUP BY candidate_type
    ) sub;

    v_has_cycles   := COALESCE((v_signals_by_type->>'dependency_cycle')::integer, 0) > 0;
    v_has_blockers := COALESCE((v_signals_by_type->>'dependency_blocked')::integer, 0) > 0;
    v_has_stalls   := COALESCE((v_signals_by_type->>'execution_stalled')::integer, 0) > 0;


    -- ====================================================================
    -- SECTION 2: ACTIVE WORK SURFACE (workspace-scoped)
    -- ====================================================================

    -- In Progress (max 20, excluding stalled items for clarity)
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'artifact_id',   sub.artifact_id,
            'title',         sub.title,
            'artifact_type', sub.artifact_type,
            'depth',         sub.depth
        ) ORDER BY sub.depth ASC, sub.priority ASC, sub.created_at ASC, sub.artifact_id ASC
    ), '[]'::jsonb)
    INTO v_in_progress
    FROM (
        SELECT
            es.artifact_id,
            a.title,
            fs.artifact_type,
            fs.depth,
            a.priority,
            a.created_at
        FROM cmdctr_execution_state es
        JOIN qxb_artifact a          ON a.artifact_id = es.artifact_id
        JOIN cmdctr_forest_state fs  ON fs.artifact_id = es.artifact_id
                                    AND fs.workspace_id = p_workspace_id
        WHERE es.execution_state = 'in_progress'
          AND es.workspace_id = p_workspace_id
          AND NOT (es.total_child_count > 0
                   AND es.complete_child_count = es.total_child_count)
        ORDER BY fs.depth ASC, a.priority ASC, a.created_at ASC, es.artifact_id ASC
        LIMIT 20
    ) sub;

    -- Blocked (max 20)
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'artifact_id',   sub.artifact_id,
            'title',         sub.title,
            'artifact_type', sub.artifact_type,
            'blocked_by',    sub.blocked_by
        ) ORDER BY sub.priority ASC, sub.artifact_id ASC
    ), '[]'::jsonb)
    INTO v_blocked
    FROM (
        SELECT
            es.artifact_id,
            a.title,
            fs.artifact_type,
            es.blocked_by,
            a.priority
        FROM cmdctr_execution_state es
        JOIN qxb_artifact a          ON a.artifact_id = es.artifact_id
        JOIN cmdctr_forest_state fs  ON fs.artifact_id = es.artifact_id
                                    AND fs.workspace_id = p_workspace_id
        WHERE es.execution_state = 'blocked'
          AND es.workspace_id = p_workspace_id
        ORDER BY a.priority ASC, es.artifact_id ASC
        LIMIT 20
    ) sub;

    -- Stalled (max 10) — in_progress with all children complete
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'artifact_id',      sub.artifact_id,
            'title',            sub.title,
            'artifact_type',    sub.artifact_type,
            'complete_children', sub.complete_child_count,
            'total_children',   sub.total_child_count
        ) ORDER BY sub.priority ASC, sub.artifact_id ASC
    ), '[]'::jsonb)
    INTO v_stalled
    FROM (
        SELECT
            es.artifact_id,
            a.title,
            fs.artifact_type,
            es.complete_child_count,
            es.total_child_count,
            a.priority
        FROM cmdctr_execution_state es
        JOIN qxb_artifact a          ON a.artifact_id = es.artifact_id
        JOIN cmdctr_forest_state fs  ON fs.artifact_id = es.artifact_id
                                    AND fs.workspace_id = p_workspace_id
        WHERE es.execution_state = 'in_progress'
          AND es.workspace_id = p_workspace_id
          AND es.total_child_count > 0
          AND es.complete_child_count = es.total_child_count
        ORDER BY a.priority ASC, es.artifact_id ASC
        LIMIT 10
    ) sub;

    -- Cycles (if any)
    SELECT COALESCE(jsonb_agg(DISTINCT jsonb_build_object(
        'artifact_id',   sub.artifact_id,
        'title',         sub.title,
        'artifact_type', sub.artifact_type
    )), '[]'::jsonb)
    INTO v_cycles
    FROM (
        SELECT
            sc.artifact_id,
            a.title,
            fs.artifact_type
        FROM cmdctr_signal_candidates sc
        JOIN qxb_artifact a          ON a.artifact_id = sc.artifact_id
        JOIN cmdctr_forest_state fs  ON fs.artifact_id = sc.artifact_id
                                    AND fs.workspace_id = p_workspace_id
        WHERE sc.candidate_type = 'dependency_cycle'
          AND sc.workspace_id = p_workspace_id
        LIMIT 20
    ) sub;

    -- Ready Summary (counts only)
    SELECT COUNT(*) INTO v_ready_total
    FROM cmdctr_execution_state
    WHERE execution_state = 'ready'
      AND workspace_id = p_workspace_id;

    SELECT COALESCE(jsonb_object_agg(artifact_type, cnt), '{}'::jsonb)
    INTO v_ready_by_type
    FROM (
        SELECT fs.artifact_type, COUNT(*) AS cnt
        FROM cmdctr_execution_state es
        JOIN cmdctr_forest_state fs ON fs.artifact_id = es.artifact_id
                                   AND fs.workspace_id = p_workspace_id
        WHERE es.execution_state = 'ready'
          AND es.workspace_id = p_workspace_id
        GROUP BY fs.artifact_type
    ) sub;

    SELECT COUNT(*) INTO v_exec_anat_ready
    FROM cmdctr_execution_state es
    JOIN cmdctr_forest_state fs ON fs.artifact_id = es.artifact_id
                               AND fs.workspace_id = p_workspace_id
    WHERE es.execution_state = 'ready'
      AND es.workspace_id = p_workspace_id
      AND fs.artifact_type IN ('project', 'branch', 'leaf', 'limb', 'twig');


    -- ====================================================================
    -- PRIOR SESSION CONTEXT LOOKUP (workspace-scoped)
    -- ====================================================================

    SELECT s.payload, a.created_at
    INTO v_prior_payload, v_prior_ts
    FROM qxb_artifact a
    JOIN qxb_artifact_snapshot s ON s.artifact_id = a.artifact_id
    WHERE a.deleted_at IS NULL
      AND a.workspace_id = p_workspace_id
      AND a.artifact_type = 'snapshot'
      AND a.tags ?& ARRAY['cmdctr', 'session-context', 'for-q']
    ORDER BY a.created_at DESC
    LIMIT 1;


    -- ====================================================================
    -- SECTION 3: DELTA COMPUTATION
    -- ====================================================================

    IF v_prior_payload IS NOT NULL THEN
        v_prior_version := (v_prior_payload->>'version')::integer;
    END IF;

    IF v_prior_payload IS NOT NULL AND v_prior_version = 1 THEN

        -- New blockers (workspace-scoped, cap 20)
        SELECT COALESCE(jsonb_agg(jsonb_build_object(
            'artifact_id', sub.artifact_id,
            'title',       sub.title
        )), '[]'::jsonb)
        INTO v_new_blockers
        FROM (
            SELECT es.artifact_id, a.title
            FROM cmdctr_execution_state es
            JOIN qxb_artifact a ON a.artifact_id = es.artifact_id
            WHERE es.execution_state = 'blocked'
              AND es.workspace_id = p_workspace_id
              AND NOT EXISTS (
                  SELECT 1
                  FROM jsonb_array_elements(
                      COALESCE(v_prior_payload->'active_surface'->'blocked', '[]'::jsonb)
                  ) elem
                  WHERE (elem->>'artifact_id')::uuid = es.artifact_id
              )
            ORDER BY a.priority ASC, es.artifact_id ASC
            LIMIT 20
        ) sub;

        -- Cleared blockers (cap 20)
        SELECT COALESCE(jsonb_agg(jsonb_build_object(
            'artifact_id', sub.artifact_id,
            'title',       sub.title
        )), '[]'::jsonb)
        INTO v_cleared_blockers
        FROM (
            SELECT
                elem->>'artifact_id' AS artifact_id,
                elem->>'title'       AS title
            FROM jsonb_array_elements(
                COALESCE(v_prior_payload->'active_surface'->'blocked', '[]'::jsonb)
            ) elem
            WHERE NOT EXISTS (
                SELECT 1 FROM cmdctr_execution_state es
                WHERE es.artifact_id = (elem->>'artifact_id')::uuid
                  AND es.execution_state = 'blocked'
                  AND es.workspace_id = p_workspace_id
            )
            LIMIT 20
        ) sub;

        -- Newly in progress (workspace-scoped, cap 20)
        SELECT COALESCE(jsonb_agg(jsonb_build_object(
            'artifact_id',   sub.artifact_id,
            'title',         sub.title,
            'artifact_type', sub.artifact_type
        )), '[]'::jsonb)
        INTO v_newly_in_progress
        FROM (
            SELECT es.artifact_id, a.title, fs.artifact_type
            FROM cmdctr_execution_state es
            JOIN qxb_artifact a          ON a.artifact_id = es.artifact_id
            JOIN cmdctr_forest_state fs  ON fs.artifact_id = es.artifact_id
                                        AND fs.workspace_id = p_workspace_id
            WHERE es.execution_state = 'in_progress'
              AND es.workspace_id = p_workspace_id
              AND NOT EXISTS (
                  SELECT 1
                  FROM jsonb_array_elements(
                      COALESCE(v_prior_payload->'active_surface'->'in_progress', '[]'::jsonb)
                  ) elem
                  WHERE (elem->>'artifact_id')::uuid = es.artifact_id
              )
            ORDER BY a.priority ASC, es.artifact_id ASC
            LIMIT 20
        ) sub;

        -- Newly completed (cap 20)
        SELECT COALESCE(jsonb_agg(jsonb_build_object(
            'artifact_id',   sub.artifact_id,
            'title',         sub.title,
            'artifact_type', sub.artifact_type
        )), '[]'::jsonb)
        INTO v_newly_completed
        FROM (
            SELECT
                elem->>'artifact_id'   AS artifact_id,
                elem->>'title'         AS title,
                elem->>'artifact_type' AS artifact_type
            FROM jsonb_array_elements(
                COALESCE(v_prior_payload->'active_surface'->'in_progress', '[]'::jsonb)
            ) elem
            WHERE EXISTS (
                SELECT 1 FROM cmdctr_execution_state es
                WHERE es.artifact_id = (elem->>'artifact_id')::uuid
                  AND es.execution_state = 'complete'
                  AND es.workspace_id = p_workspace_id
            )
            LIMIT 20
        ) sub;

        -- Signal delta (workspace-scoped)
        SELECT
            COALESCE(
                (SELECT jsonb_object_agg(sd.candidate_type, sd.delta)
                 FROM (
                     SELECT
                         COALESCE(c.candidate_type, p.candidate_type) AS candidate_type,
                         COALESCE(c.cnt, 0) - COALESCE(p.cnt, 0) AS delta
                     FROM (
                         SELECT candidate_type, COUNT(*)::integer AS cnt
                         FROM cmdctr_signal_candidates
                         WHERE workspace_id = p_workspace_id
                         GROUP BY candidate_type
                     ) c
                     FULL OUTER JOIN (
                         SELECT key AS candidate_type, value::integer AS cnt
                         FROM jsonb_each_text(
                             COALESCE(v_prior_payload->'health'->'signals_by_type', '{}'::jsonb)
                         )
                     ) p ON c.candidate_type = p.candidate_type
                 ) sd
                 WHERE sd.delta > 0),
                '{}'::jsonb
            ),
            COALESCE(
                (SELECT jsonb_object_agg(sd.candidate_type, abs(sd.delta))
                 FROM (
                     SELECT
                         COALESCE(c.candidate_type, p.candidate_type) AS candidate_type,
                         COALESCE(c.cnt, 0) - COALESCE(p.cnt, 0) AS delta
                     FROM (
                         SELECT candidate_type, COUNT(*)::integer AS cnt
                         FROM cmdctr_signal_candidates
                         WHERE workspace_id = p_workspace_id
                         GROUP BY candidate_type
                     ) c
                     FULL OUTER JOIN (
                         SELECT key AS candidate_type, value::integer AS cnt
                         FROM jsonb_each_text(
                             COALESCE(v_prior_payload->'health'->'signals_by_type', '{}'::jsonb)
                         )
                     ) p ON c.candidate_type = p.candidate_type
                 ) sd
                 WHERE sd.delta < 0),
                '{}'::jsonb
            )
        INTO v_new_signals, v_cleared_signals;

        -- Forest row change
        v_forest_change := v_forest_rows - COALESCE(
            (v_prior_payload->'health'->>'forest_rows')::integer,
            v_forest_rows
        );

        -- Delta summary (plain language)
        v_delta_summary := '';
        IF v_forest_change != 0 THEN
            v_delta_summary := v_delta_summary
                || abs(v_forest_change)::text || ' '
                || CASE WHEN v_forest_change > 0 THEN 'new' ELSE 'removed' END
                || ' artifacts. ';
        END IF;
        IF jsonb_array_length(v_new_blockers) > 0 THEN
            v_delta_summary := v_delta_summary
                || jsonb_array_length(v_new_blockers)::text || ' new blockers. ';
        END IF;
        IF jsonb_array_length(v_cleared_blockers) > 0 THEN
            v_delta_summary := v_delta_summary
                || jsonb_array_length(v_cleared_blockers)::text || ' blockers cleared. ';
        END IF;
        IF jsonb_array_length(v_newly_completed) > 0 THEN
            v_delta_summary := v_delta_summary
                || jsonb_array_length(v_newly_completed)::text || ' newly completed. ';
        END IF;
        IF v_has_cycles THEN
            v_delta_summary := v_delta_summary || 'Dependency cycles detected. ';
        ELSE
            v_delta_summary := v_delta_summary || 'No cycles. ';
        END IF;
        IF v_delta_summary = '' THEN
            v_delta_summary := 'No significant changes since last session.';
        END IF;
        v_delta_summary := TRIM(v_delta_summary);

    ELSIF v_prior_payload IS NOT NULL AND v_prior_version IS DISTINCT FROM 1 THEN
        v_new_blockers      := '[]'::jsonb;
        v_cleared_blockers  := '[]'::jsonb;
        v_newly_in_progress := '[]'::jsonb;
        v_newly_completed   := '[]'::jsonb;
        v_new_signals       := '{}'::jsonb;
        v_cleared_signals   := '{}'::jsonb;
        v_forest_change     := 0;
        v_delta_summary     := 'Prior briefing version mismatch — delta unavailable.';

    ELSE
        v_new_blockers      := '[]'::jsonb;
        v_cleared_blockers  := '[]'::jsonb;
        v_newly_in_progress := '[]'::jsonb;
        v_newly_completed   := '[]'::jsonb;
        v_new_signals       := '{}'::jsonb;
        v_cleared_signals   := '{}'::jsonb;
        v_forest_change     := 0;
        v_delta_summary     := 'First session briefing. No prior context for delta comparison.';
    END IF;


    -- ====================================================================
    -- SECTION 4: OPERATOR NOTE
    -- ====================================================================

    v_operator_note := '';

    IF v_has_cycles THEN
        v_operator_note := 'WARNING: Dependency cycles detected. ';
    ELSE
        v_operator_note := 'No cycles. ';
    END IF;

    IF v_has_blockers THEN
        v_operator_note := v_operator_note
            || COALESCE((v_signals_by_type->>'dependency_blocked'), '0')
            || ' blocked artifacts. ';
    ELSE
        v_operator_note := v_operator_note || 'No blockers. ';
    END IF;

    IF v_has_stalls THEN
        v_operator_note := v_operator_note
            || COALESCE((v_signals_by_type->>'execution_stalled'), '0')
            || ' stalled items. ';
    END IF;

    IF jsonb_array_length(v_in_progress) > 0 THEN
        v_operator_note := v_operator_note
            || jsonb_array_length(v_in_progress)::text || ' items in progress. ';
    END IF;

    v_operator_note := v_operator_note
        || v_exec_anat_ready::text || ' execution-anatomy items ready.';

    v_operator_note := TRIM(v_operator_note);


    -- ====================================================================
    -- RETURN
    -- ====================================================================

    RETURN jsonb_build_object(
        'version',          1,
        'workspace_id',     p_workspace_id,
        'crawl_ts',         v_crawl_ts,
        'crawl_duration_ms', NULL,
        'prior_session_ts', v_prior_ts,

        'health', jsonb_build_object(
            'forest_rows',     v_forest_rows,
            'execution_rows',  v_exec_rows,
            'signal_total',    v_signal_total,
            'signals_by_type', v_signals_by_type,
            'has_cycles',      v_has_cycles,
            'has_blockers',    v_has_blockers,
            'has_stalls',      v_has_stalls
        ),

        'active_surface', jsonb_build_object(
            'in_progress', v_in_progress,
            'blocked',     v_blocked,
            'stalled',     v_stalled,
            'cycles',      v_cycles,
            'ready_summary', jsonb_build_object(
                'total',                  v_ready_total,
                'by_type',                v_ready_by_type,
                'execution_anatomy_ready', v_exec_anat_ready
            )
        ),

        'delta', jsonb_build_object(
            'new_blockers',      v_new_blockers,
            'cleared_blockers',  v_cleared_blockers,
            'newly_in_progress', v_newly_in_progress,
            'newly_completed',   v_newly_completed,
            'new_signals',       v_new_signals,
            'cleared_signals',   v_cleared_signals,
            'forest_row_change', v_forest_change,
            'summary',           v_delta_summary
        ),

        'operator_note', v_operator_note
    );

END;
$function$;


-- ============================================================================
-- 2. cmdctr_render_session_markdown(p_workspace_id uuid)
-- ============================================================================
DROP FUNCTION IF EXISTS cmdctr_render_session_markdown();

CREATE OR REPLACE FUNCTION public.cmdctr_render_session_markdown(
    p_workspace_id uuid DEFAULT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_ctx       jsonb;
    v_md        text := '';
    v_item      jsonb;
    v_key       text;
    v_val       integer;
    v_health    jsonb;
    v_surface   jsonb;
    v_delta     jsonb;
    v_ws_name   text;
BEGIN
    -- Pass workspace_id through to build_session_context
    v_ctx := cmdctr_build_session_context(p_workspace_id);

    IF v_ctx ? 'error' THEN
        RETURN '# CmdCtr Session Briefing' || E'\n\n' || '**ERROR:** ' || (v_ctx->>'error') || E'\n';
    END IF;

    v_health  := v_ctx->'health';
    v_surface := v_ctx->'active_surface';
    v_delta   := v_ctx->'delta';

    -- Resolve workspace name for header
    SELECT name INTO v_ws_name FROM qxb_workspace WHERE workspace_id = p_workspace_id;

    -- HEADER
    v_md := '# CmdCtr Session Briefing' || E'\n\n';
    v_md := v_md || '**Workspace:** ' || COALESCE(v_ws_name, p_workspace_id::text) || E'\n';
    v_md := v_md || '**Generated:** ' || now()::text || E'\n';
    v_md := v_md || '**Crawl Time:** ' || (v_ctx->>'crawl_ts') || E'\n';
    IF v_ctx->>'prior_session_ts' IS NOT NULL THEN
        v_md := v_md || '**Delta Since:** ' || (v_ctx->>'prior_session_ts') || E'\n';
    ELSE
        v_md := v_md || '**Delta Since:** (first briefing)' || E'\n';
    END IF;
    v_md := v_md || E'\n';

    -- FOREST HEALTH
    v_md := v_md || '## Forest Health' || E'\n\n';
    v_md := v_md || '| Metric | Value |' || E'\n';
    v_md := v_md || '|--------|-------|' || E'\n';
    v_md := v_md || '| Total Artifacts | ' || (v_health->>'forest_rows') || ' |' || E'\n';
    v_md := v_md || '| Execution Artifacts | ' || (v_health->>'execution_rows') || ' |' || E'\n';
    v_md := v_md || '| Active Signals | ' || (v_health->>'signal_total') || ' |' || E'\n';
    v_md := v_md || E'\n';

    -- STRUCTURAL STATUS
    v_md := v_md || '## Structural Status' || E'\n\n';
    v_md := v_md || '- **Cycles:** ' || CASE WHEN (v_health->>'has_cycles')::boolean THEN 'YES' ELSE 'No' END || E'\n';
    v_md := v_md || '- **Blockers:** ' || CASE WHEN (v_health->>'has_blockers')::boolean THEN 'YES' ELSE 'No' END || E'\n';
    v_md := v_md || '- **Stalls:** ' || CASE WHEN (v_health->>'has_stalls')::boolean THEN 'YES' ELSE 'No' END || E'\n';
    v_md := v_md || E'\n';

    -- ACTIVE WORK SURFACE
    v_md := v_md || '## Active Work Surface' || E'\n\n';

    -- In Progress
    IF jsonb_array_length(v_surface->'in_progress') > 0 THEN
        v_md := v_md || '### In Progress' || E'\n\n';
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_surface->'in_progress')
        LOOP
            v_md := v_md || '- ' || (v_item->>'title') || ' (' || (v_item->>'artifact_type') || ', depth ' || (v_item->>'depth') || ')' || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    ELSE
        v_md := v_md || '### In Progress' || E'\n\n' || 'None.' || E'\n\n';
    END IF;

    -- Blocked
    IF jsonb_array_length(v_surface->'blocked') > 0 THEN
        v_md := v_md || '### Blocked' || E'\n\n';
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_surface->'blocked')
        LOOP
            v_md := v_md || '- ' || (v_item->>'title') || ' (' || (v_item->>'artifact_type') || ') — blocked by: ' || (v_item->>'blocked_by') || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    -- Stalled
    IF jsonb_array_length(v_surface->'stalled') > 0 THEN
        v_md := v_md || '### Stalled' || E'\n\n';
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_surface->'stalled')
        LOOP
            v_md := v_md || '- ' || (v_item->>'title') || ' (' || (v_item->>'artifact_type') || ', ' || (v_item->>'complete_children') || '/' || (v_item->>'total_children') || ' children complete)' || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    -- Cycles
    IF jsonb_array_length(v_surface->'cycles') > 0 THEN
        v_md := v_md || '### Dependency Cycles' || E'\n\n';
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_surface->'cycles')
        LOOP
            v_md := v_md || '- **' || (v_item->>'title') || '** (' || (v_item->>'artifact_type') || ')' || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    -- READY SURFACE
    v_md := v_md || '## Ready Surface' || E'\n\n';

    IF v_surface->'ready_summary'->'by_type' != '{}'::jsonb THEN
        v_md := v_md || '| Type | Ready |' || E'\n';
        v_md := v_md || '|------|-------|' || E'\n';
        FOR v_key, v_val IN
            SELECT key, value::integer FROM jsonb_each_text(v_surface->'ready_summary'->'by_type')
            ORDER BY value::integer DESC
        LOOP
            v_md := v_md || '| ' || v_key || ' | ' || v_val::text || ' |' || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    v_md := v_md || '**Execution-layer ready:** ' || (v_surface->'ready_summary'->>'execution_anatomy_ready') || E'\n\n';

    -- DELTA SINCE LAST SESSION
    v_md := v_md || '## Delta Since Last Session' || E'\n\n';
    v_md := v_md || (v_delta->>'summary') || E'\n\n';

    IF (v_delta->>'forest_row_change')::integer != 0 THEN
        v_md := v_md || '- Forest row change: ' || (v_delta->>'forest_row_change') || E'\n\n';
    END IF;

    IF jsonb_array_length(v_delta->'newly_in_progress') > 0 THEN
        v_md := v_md || '**Newly In Progress:**' || E'\n';
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_delta->'newly_in_progress')
        LOOP
            v_md := v_md || '- ' || (v_item->>'title') || ' (' || (v_item->>'artifact_type') || ')' || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    IF jsonb_array_length(v_delta->'newly_completed') > 0 THEN
        v_md := v_md || '**Newly Completed:**' || E'\n';
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_delta->'newly_completed')
        LOOP
            v_md := v_md || '- ' || (v_item->>'title') || ' (' || (v_item->>'artifact_type') || ')' || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    IF jsonb_array_length(v_delta->'new_blockers') > 0 THEN
        v_md := v_md || '**New Blockers:**' || E'\n';
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_delta->'new_blockers')
        LOOP
            v_md := v_md || '- ' || (v_item->>'title') || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    IF jsonb_array_length(v_delta->'cleared_blockers') > 0 THEN
        v_md := v_md || '**Cleared Blockers:**' || E'\n';
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_delta->'cleared_blockers')
        LOOP
            v_md := v_md || '- ' || (v_item->>'title') || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    IF v_delta->'new_signals' != '{}'::jsonb THEN
        v_md := v_md || '**New Signals:**' || E'\n';
        FOR v_key, v_val IN
            SELECT key, value::integer FROM jsonb_each_text(v_delta->'new_signals')
        LOOP
            v_md := v_md || '- ' || v_key || ': +' || v_val::text || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    IF v_delta->'cleared_signals' != '{}'::jsonb THEN
        v_md := v_md || '**Cleared Signals:**' || E'\n';
        FOR v_key, v_val IN
            SELECT key, value::integer FROM jsonb_each_text(v_delta->'cleared_signals')
        LOOP
            v_md := v_md || '- ' || v_key || ': -' || v_val::text || E'\n';
        END LOOP;
        v_md := v_md || E'\n';
    END IF;

    -- OPERATOR NOTE
    v_md := v_md || '## Operator Note' || E'\n\n';
    v_md := v_md || (v_ctx->>'operator_note') || E'\n\n';

    -- PLANNING PROMPT
    v_md := v_md || '## Planning Prompt' || E'\n\n';
    v_md := v_md || 'Continue active work or resolve blockers before initiating new execution.' || E'\n';

    RETURN v_md;
END;
$function$;


-- ============================================================================
-- 3. cmdctr_operator_briefing(p_workspace_id uuid)
-- ============================================================================
DROP FUNCTION IF EXISTS cmdctr_operator_briefing();

CREATE OR REPLACE FUNCTION public.cmdctr_operator_briefing(
    p_workspace_id uuid DEFAULT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_crawl_result      jsonb;
    v_ctx               jsonb;
    v_semantic_type_id  uuid;
    v_artifact_id       uuid;
    v_markdown          text;
    v_owner_user_id     uuid;
    v_title             text;
BEGIN
    -- ================================================================
    -- Derive owner from workspace (Option A)
    -- ================================================================
    SELECT wu.user_id INTO v_owner_user_id
    FROM qxb_workspace_user wu
    WHERE wu.workspace_id = p_workspace_id
      AND wu.role = 'owner'
    LIMIT 1;

    IF v_owner_user_id IS NULL THEN
        RAISE EXCEPTION 'No owner found for workspace_id %', p_workspace_id;
    END IF;

    -- Step 1: Refresh crawl (workspace-scoped)
    v_crawl_result := cmdctr_run_crawl(p_workspace_id);

    -- Step 2: Build session context JSON (workspace-scoped)
    v_ctx := cmdctr_build_session_context(p_workspace_id);

    -- Step 3: Save snapshot artifact (workspace-scoped)
    SELECT semantic_type_id INTO v_semantic_type_id
    FROM qxb_semantic_type_registry
    WHERE key = 'infrastructure' AND active = true;

    IF v_semantic_type_id IS NULL THEN
        RAISE EXCEPTION 'semantic_type_id for key=infrastructure not found in qxb_semantic_type_registry';
    END IF;

    v_title := 'CmdCtr Session Context — ' || to_char(now(), 'YYYY-MM-DD');

    INSERT INTO qxb_artifact (
        workspace_id,
        owner_user_id,
        artifact_type,
        title,
        semantic_type_id,
        tags
    ) VALUES (
        p_workspace_id,
        v_owner_user_id,
        'snapshot',
        v_title,
        v_semantic_type_id,
        '["cmdctr","session-context","for-q"]'::jsonb
    )
    RETURNING artifact_id INTO v_artifact_id;

    INSERT INTO qxb_artifact_snapshot (
        artifact_id,
        payload
    ) VALUES (
        v_artifact_id,
        v_ctx
    );

    -- Step 4: Render markdown briefing (workspace-scoped)
    v_markdown := cmdctr_render_session_markdown(p_workspace_id);

    RETURN v_markdown;
END;
$function$;

COMMIT;
