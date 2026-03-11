-- =============================================================================
-- Migration: T69 — Semantic Type Backfill
-- Date:      2026-03-03
-- Version:   v1
-- Author:    CC (Claude Code) — approved by Joel
-- Thread:    T69 — Behavioral Role Layer / Semantic Type Registry
-- =============================================================================
--
-- PURPOSE:
--   Populate semantic_type_id on all existing top-level artifacts
--   (project, snapshot, journal, restart) with the 'exploratory' default.
--
-- PREREQUISITES:
--   Section A of 2026-03-03__t69_semantic_type_registry__v1.sql must be
--   deployed (registry table seeded, spine column added, FK + index live).
--
-- CONSTRAINTS:
--   - Idempotent: WHERE semantic_type_id IS NULL ensures re-runs are safe
--   - No version increment (migration, not behavioral change)
--   - No audit insert (migration, not RPC-driven change)
--   - Non-top-level types remain NULL
--
-- ROLLBACK:
--   UPDATE public.qxb_artifact
--   SET semantic_type_id = NULL
--   WHERE artifact_type IN ('project', 'snapshot', 'journal', 'restart');
--
-- CHANGELOG:
--   v1 (2026-03-03) — Initial creation
-- =============================================================================


-- =============================================================================
-- SCRIPT A: Dry Run (READ ONLY — no mutations)
-- =============================================================================
-- Run this FIRST to preview the backfill scope.
-- Returns: count by type, plus sample artifact_ids.

-- A1: Count of top-level artifacts needing backfill, grouped by type
SELECT
    artifact_type,
    COUNT(*) AS null_semantic_type_count
FROM public.qxb_artifact
WHERE artifact_type IN ('project', 'snapshot', 'journal', 'restart')
  AND semantic_type_id IS NULL
  AND deleted_at IS NULL
GROUP BY artifact_type
ORDER BY artifact_type;

-- A2: Total count
SELECT COUNT(*) AS total_needing_backfill
FROM public.qxb_artifact
WHERE artifact_type IN ('project', 'snapshot', 'journal', 'restart')
  AND semantic_type_id IS NULL
  AND deleted_at IS NULL;

-- A3: Sample artifact_ids (first 10)
SELECT artifact_id, artifact_type, title, created_at
FROM public.qxb_artifact
WHERE artifact_type IN ('project', 'snapshot', 'journal', 'restart')
  AND semantic_type_id IS NULL
  AND deleted_at IS NULL
ORDER BY created_at ASC
LIMIT 10;


-- =============================================================================
-- SCRIPT B: Backfill Execution (MUTATING — run after dry-run review)
-- =============================================================================
-- Resolves 'exploratory' UUID dynamically from registry.
-- Fails clearly if 'exploratory' key is missing or inactive.

WITH exploratory AS (
    SELECT semantic_type_id
    FROM public.qxb_semantic_type_registry
    WHERE key = 'exploratory'
      AND active = true
)
UPDATE public.qxb_artifact a
SET semantic_type_id = e.semantic_type_id
FROM exploratory e
WHERE a.artifact_type IN ('project', 'snapshot', 'journal', 'restart')
  AND a.semantic_type_id IS NULL;


-- =============================================================================
-- SCRIPT C: Verification (READ ONLY — run after backfill)
-- =============================================================================

-- C1: Should return 0 — no top-level artifacts with NULL semantic_type_id
SELECT COUNT(*) AS top_level_still_null
FROM public.qxb_artifact
WHERE artifact_type IN ('project', 'snapshot', 'journal', 'restart')
  AND semantic_type_id IS NULL
  AND deleted_at IS NULL;

-- C2: Should return >0 — non-top-level types remain NULL (correct)
SELECT
    artifact_type,
    COUNT(*) AS null_count
FROM public.qxb_artifact
WHERE artifact_type NOT IN ('project', 'snapshot', 'journal', 'restart')
  AND semantic_type_id IS NULL
  AND deleted_at IS NULL
GROUP BY artifact_type
ORDER BY artifact_type;

-- C3: Should return 0 — no non-top-level types accidentally backfilled
SELECT COUNT(*) AS non_top_level_incorrectly_filled
FROM public.qxb_artifact
WHERE artifact_type NOT IN ('project', 'snapshot', 'journal', 'restart')
  AND semantic_type_id IS NOT NULL;

-- C4: Confirm all backfilled rows point to 'exploratory'
SELECT
    r.key,
    COUNT(*) AS artifact_count
FROM public.qxb_artifact a
JOIN public.qxb_semantic_type_registry r ON r.semantic_type_id = a.semantic_type_id
WHERE a.artifact_type IN ('project', 'snapshot', 'journal', 'restart')
  AND a.deleted_at IS NULL
GROUP BY r.key;
