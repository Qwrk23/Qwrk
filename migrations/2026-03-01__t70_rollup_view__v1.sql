-- =============================================================================
-- Migration: T70 — Deterministic Rollup VIEW
-- Date:      2026-03-01
-- Version:   v1
-- Author:    CC (Claude Code) — approved by Joel
-- Thread:    T70 — Deterministic Rollup Query
-- =============================================================================
--
-- PURPOSE:
--   Create a read-only VIEW that computes completion percentage for
--   rollup-eligible artifact types (project, branch, limb) based on
--   direct parent-child relationships and execution_status.
--
-- DESIGN DECISIONS:
--   - completion_ratio: 0–1 numeric (raw, no rounding)
--   - Denominator: all non-deleted children (deleted_at IS NULL),
--     regardless of execution_status value (including NULL)
--   - Numerator: children where execution_status = 'complete'
--   - 0 children → completion_ratio = NULL (not 0)
--   - Direct parent-child only (no recursive CTE)
--   - VIEW inherits RLS from underlying qxb_artifact — workspace
--     isolation is automatic
--
-- ROLLBACK:
--   DROP VIEW IF EXISTS public.qxb_artifact_rollup_view;
--
-- CHANGELOG:
--   v1 (2026-03-01) — Initial creation
-- =============================================================================

CREATE OR REPLACE VIEW public.qxb_artifact_rollup_view AS
SELECT
    p.artifact_id,
    p.artifact_type,
    p.workspace_id,
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
GROUP BY p.artifact_id, p.artifact_type, p.workspace_id;

-- Verify: should return column names and types
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'qxb_artifact_rollup_view'
-- ORDER BY ordinal_position;
