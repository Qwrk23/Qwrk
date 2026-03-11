-- ============================================================================
-- Migration: CmdCtr Session Context Builder v1 (revised)
-- Date: 2026-03-07
-- Thread: T100
-- Depends on: 2026-03-07__cmdctr_phase2_execution_awareness__v1.sql
-- ============================================================================
-- On-demand function that distills CmdCtr read-model state into a single
-- JSONB session briefing. NOT scheduled. Does NOT mutate any tables.
--
-- Usage:  SELECT cmdctr_build_session_context();
--
-- The returned JSONB is intended to be:
--   1. Saved as an immutable snapshot artifact (via Gateway, downstream)
--      Required tags: cmdctr, session-context, for-q
--   2. Rendered to markdown (downstream script/client)
--   3. Uploaded to ChatGPT project as session-start context
--
-- This function is a READER ONLY. It:
--   - Reads cmdctr_forest_state, cmdctr_execution_state, cmdctr_signal_candidates
--   - Reads qxb_artifact + qxb_artifact_snapshot for prior session context
--   - Returns one JSONB object
--   - Writes nothing
--
-- Revision notes (v1 revised):
--   Fix 1: crawl_duration_ms returned as null (not stored in read models)
--   Fix 2: Prior snapshot lookup requires tags: cmdctr + session-context + for-q
--   Fix 3: Prior payload version guard (skip delta on version mismatch)
--   Fix 4: Signal delta uses per-type count deltas, not presence/absence
--   Fix 5: In-progress ordering uses numeric columns, not JSONB text extraction
--   Fix 6: All delta arrays capped at 20 items
--
-- No new tables. No cron changes. No schema changes.
-- ============================================================================


CREATE OR REPLACE FUNCTION public.cmdctr_build_session_context()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
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
    -- CRAWL TIMESTAMP
    -- ====================================================================
    -- All CmdCtr tables share the same crawled_at from the last crawl run.

    SELECT crawled_at INTO v_crawl_ts
    FROM cmdctr_forest_state
    LIMIT 1;

    IF v_crawl_ts IS NULL THEN
        RETURN jsonb_build_object(
            'version', 1,
            'error', 'No CmdCtr crawl data available. Run cmdctr_run_crawl() first.'
        );
    END IF;


    -- ====================================================================
    -- SECTION 1: HEALTH HEADER
    -- ====================================================================

    SELECT COUNT(*) INTO v_forest_rows  FROM cmdctr_forest_state;
    SELECT COUNT(*) INTO v_exec_rows    FROM cmdctr_execution_state;
    SELECT COUNT(*) INTO v_signal_total FROM cmdctr_signal_candidates;

    SELECT COALESCE(jsonb_object_agg(candidate_type, cnt), '{}'::jsonb)
    INTO v_signals_by_type
    FROM (
        SELECT candidate_type, COUNT(*) AS cnt
        FROM cmdctr_signal_candidates
        GROUP BY candidate_type
    ) sub;

    v_has_cycles   := COALESCE((v_signals_by_type->>'dependency_cycle')::integer, 0) > 0;
    v_has_blockers := COALESCE((v_signals_by_type->>'dependency_blocked')::integer, 0) > 0;
    v_has_stalls   := COALESCE((v_signals_by_type->>'execution_stalled')::integer, 0) > 0;


    -- ====================================================================
    -- SECTION 2: ACTIVE WORK SURFACE
    -- ====================================================================

    -- In Progress (max 20, excluding stalled items for clarity)
    -- FIX 5: Sort by typed numeric/timestamp columns, not JSONB text extraction.
    -- Order: depth ASC, priority ASC, created_at ASC, artifact_id ASC (deterministic).
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
        WHERE es.execution_state = 'in_progress'
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
        WHERE es.execution_state = 'blocked'
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
        WHERE es.execution_state = 'in_progress'
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
        WHERE sc.candidate_type = 'dependency_cycle'
        LIMIT 20
    ) sub;

    -- Ready Summary (counts only — never individual items)
    SELECT COUNT(*) INTO v_ready_total
    FROM cmdctr_execution_state
    WHERE execution_state = 'ready';

    SELECT COALESCE(jsonb_object_agg(artifact_type, cnt), '{}'::jsonb)
    INTO v_ready_by_type
    FROM (
        SELECT fs.artifact_type, COUNT(*) AS cnt
        FROM cmdctr_execution_state es
        JOIN cmdctr_forest_state fs ON fs.artifact_id = es.artifact_id
        WHERE es.execution_state = 'ready'
        GROUP BY fs.artifact_type
    ) sub;

    SELECT COUNT(*) INTO v_exec_anat_ready
    FROM cmdctr_execution_state es
    JOIN cmdctr_forest_state fs ON fs.artifact_id = es.artifact_id
    WHERE es.execution_state = 'ready'
      AND fs.artifact_type IN ('project', 'branch', 'leaf', 'limb', 'twig');


    -- ====================================================================
    -- PRIOR SESSION CONTEXT LOOKUP
    -- ====================================================================
    -- FIX 2: Require all 3 tags: cmdctr, session-context, for-q.
    -- tags is jsonb (array). ?& checks ALL elements exist.
    -- SECURITY DEFINER bypasses RLS for this cross-table lookup.

    SELECT s.payload, a.created_at
    INTO v_prior_payload, v_prior_ts
    FROM qxb_artifact a
    JOIN qxb_artifact_snapshot s ON s.artifact_id = a.artifact_id
    WHERE a.deleted_at IS NULL
      AND a.artifact_type = 'snapshot'
      AND a.tags ?& ARRAY['cmdctr', 'session-context', 'for-q']
    ORDER BY a.created_at DESC
    LIMIT 1;


    -- ====================================================================
    -- SECTION 3: DELTA COMPUTATION
    -- ====================================================================

    -- FIX 3: Version guard — skip delta if prior payload version != 1
    IF v_prior_payload IS NOT NULL THEN
        v_prior_version := (v_prior_payload->>'version')::integer;
    END IF;

    IF v_prior_payload IS NOT NULL AND v_prior_version = 1 THEN

        -- New blockers: blocked now but not in prior briefing
        -- FIX 6: Cap at 20
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

        -- Cleared blockers: in prior blocked but no longer blocked
        -- FIX 6: Cap at 20
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
            )
            LIMIT 20
        ) sub;

        -- Newly in progress: in_progress now but not in prior
        -- FIX 6: Cap at 20
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
            WHERE es.execution_state = 'in_progress'
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

        -- Newly completed: was in_progress in prior, now complete
        -- FIX 6: Cap at 20
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
            )
            LIMIT 20
        ) sub;

        -- FIX 4: Signal delta — per-type count deltas, not presence/absence.
        -- new_signals: types where current count > prior count (shows positive delta)
        -- cleared_signals: types where current count < prior count (shows reduction)
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
        -- FIX 3: Version mismatch — skip delta gracefully
        v_new_blockers      := '[]'::jsonb;
        v_cleared_blockers  := '[]'::jsonb;
        v_newly_in_progress := '[]'::jsonb;
        v_newly_completed   := '[]'::jsonb;
        v_new_signals       := '{}'::jsonb;
        v_cleared_signals   := '{}'::jsonb;
        v_forest_change     := 0;
        v_delta_summary     := 'Prior briefing version mismatch — delta unavailable.';

    ELSE
        -- No prior session context — first briefing
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

    -- Cycles (most critical)
    IF v_has_cycles THEN
        v_operator_note := 'WARNING: Dependency cycles detected. ';
    ELSE
        v_operator_note := 'No cycles. ';
    END IF;

    -- Blockers
    IF v_has_blockers THEN
        v_operator_note := v_operator_note
            || COALESCE((v_signals_by_type->>'dependency_blocked'), '0')
            || ' blocked artifacts. ';
    ELSE
        v_operator_note := v_operator_note || 'No blockers. ';
    END IF;

    -- Stalls
    IF v_has_stalls THEN
        v_operator_note := v_operator_note
            || COALESCE((v_signals_by_type->>'execution_stalled'), '0')
            || ' stalled items. ';
    END IF;

    -- In progress
    IF jsonb_array_length(v_in_progress) > 0 THEN
        v_operator_note := v_operator_note
            || jsonb_array_length(v_in_progress)::text || ' items in progress. ';
    END IF;

    -- Execution anatomy ready
    v_operator_note := v_operator_note
        || v_exec_anat_ready::text || ' execution-anatomy items ready.';

    v_operator_note := TRIM(v_operator_note);


    -- ====================================================================
    -- RETURN
    -- ====================================================================

    RETURN jsonb_build_object(
        'version',          1,
        'crawl_ts',         v_crawl_ts,
        -- FIX 1: crawl_duration_ms is not stored in CmdCtr read-model tables.
        -- cmdctr_run_crawl() computes it transiently and returns it, but does
        -- not persist it. Return null explicitly.
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
$fn$;

COMMENT ON FUNCTION public.cmdctr_build_session_context() IS 'CmdCtr Session Context Builder v1 (revised): On-demand function that distills CmdCtr read-model state into a single JSONB session briefing. Reads cmdctr_* tables + latest prior session-context snapshot (tagged cmdctr + session-context + for-q) for delta computation. Does NOT mutate any tables. Not scheduled.';
