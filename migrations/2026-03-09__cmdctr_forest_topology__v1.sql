-- ============================================================================
-- Migration: CmdCtr Forest Topology Reference in Session Briefing
-- Date: 2026-03-09
-- Purpose: Add Forest Topology section to cmdctr_render_session_markdown
--          Renders a lightweight pointer (UUID + hydrate payload) to the
--          latest Forest Map snapshot, rather than embedding the full topology.
--          Q can hydrate on-demand when it needs the structure.
-- Depends on: 2026-03-09__cmdctr_multi_workspace__v1.sql
-- Convention: Forest Map = snapshot tagged ["topology","founding-forest"]
--             Selection: latest by created_at (ORDER BY created_at DESC LIMIT 1)
--             Artifact type: snapshot (immutable structural truth)
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
    v_topo_id   uuid;
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

    -- FOREST TOPOLOGY REFERENCE (latest snapshot tagged topology+founding-forest)
    SELECT a.artifact_id INTO v_topo_id
    FROM qxb_artifact a
    WHERE a.workspace_id = p_workspace_id
      AND a.deleted_at IS NULL
      AND a.tags @> '["topology","founding-forest"]'::jsonb
      AND a.artifact_type = 'snapshot'
    ORDER BY a.created_at DESC
    LIMIT 1;

    IF v_topo_id IS NOT NULL THEN
        v_md := v_md || '## Forest Topology' || E'\n\n';
        v_md := v_md || '**Forest Map:** `' || v_topo_id || '`' || E'\n';
        v_md := v_md || '**Hydrate:** `{"gw_action":"artifact.query","gw_workspace_id":"' || p_workspace_id || '","artifact_type":"snapshot","artifact_id":"' || v_topo_id || '"}`' || E'\n\n';
    END IF;

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
