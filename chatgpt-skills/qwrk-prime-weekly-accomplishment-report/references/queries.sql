-- =====================================================================
-- Qwrk Prime Weekly Accomplishment Report — Read-Only SQL Templates
-- =====================================================================
--
-- All queries below are SELECT-only. Do NOT modify to INSERT/UPDATE/DELETE.
-- Workspace scope is hard-coded to Qwrk Prime
-- (be0d3a48-c764-44f9-90c8-e846d9dbbd0a). Do not widen.
--
-- Window placeholders:
--   :window_start_utc — derived from (report_date - 7 days) at 00:00 America/Chicago
--   :window_end_utc   — derived from (report_date - 1 day)  at 23:59:59.999999 America/Chicago
--
-- Convert local Central times to UTC in the caller before binding.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Q0 — Verification ping (run first, every time)
-- ---------------------------------------------------------------------
-- Confirms the read role can connect AND returns expected window count.
-- If count = 0, that is a valid quiet-week result.
-- If count > 500, flag in §7 of the report.
SELECT
  current_database() AS db,
  current_user      AS usr,
  now()             AS ts,
  (
    SELECT count(*)
    FROM qxb_artifact
    WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
      AND (created_at >= :window_start_utc OR updated_at >= :window_start_utc)
      AND (created_at <= :window_end_utc   OR updated_at <= :window_end_utc)
  ) AS prime_window_count;


-- ---------------------------------------------------------------------
-- Q1 — Counts by artifact_type (for §2 table)
-- ---------------------------------------------------------------------
SELECT
  artifact_type,
  COUNT(*)                                                        AS n,
  COUNT(*) FILTER (WHERE created_at >= :window_start_utc
                     AND created_at <= :window_end_utc)           AS created_in_window,
  COUNT(*) FILTER (WHERE (created_at < :window_start_utc
                          OR created_at > :window_end_utc)
                     AND updated_at >= :window_start_utc
                     AND updated_at <= :window_end_utc)           AS updated_only
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND (
    (created_at >= :window_start_utc AND created_at <= :window_end_utc)
    OR
    (updated_at >= :window_start_utc AND updated_at <= :window_end_utc)
  )
GROUP BY artifact_type
ORDER BY n DESC;


-- ---------------------------------------------------------------------
-- Q2 — Spine page (paginate with LIMIT/OFFSET in batches of 25)
-- ---------------------------------------------------------------------
-- Fetches metadata + semantic_type label. Excludes content/payload to keep
-- response under MCP token limits. Hydrate high-signal items separately
-- via Q3a/Q3b/Q3c.
WITH window_rows AS (
  SELECT
    a.artifact_id,
    a.artifact_type,
    a.title,
    a.summary,
    a.lifecycle_status,
    a.execution_status,
    a.priority,
    a.parent_artifact_id,
    a.tags,
    a.created_at,
    a.updated_at,
    CASE
      WHEN a.created_at >= :window_start_utc AND a.created_at <= :window_end_utc
        THEN 'created'
      ELSE 'updated'
    END AS in_window_via,
    COALESCE(s.key, '') AS semantic_type
  FROM qxb_artifact a
  LEFT JOIN qxb_semantic_type_registry s
    ON s.semantic_type_id = a.semantic_type_id
  WHERE a.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
    AND (
      (a.created_at >= :window_start_utc AND a.created_at <= :window_end_utc)
      OR
      (a.updated_at >= :window_start_utc AND a.updated_at <= :window_end_utc)
    )
)
SELECT *
FROM window_rows
ORDER BY GREATEST(created_at, updated_at) DESC
LIMIT 25
OFFSET :page_offset;


-- ---------------------------------------------------------------------
-- Q3a — Hydrate snapshot extension payloads (high-signal only)
-- ---------------------------------------------------------------------
-- Pass an array of artifact_ids selected by the renderer (priority 1-2 +
-- governance/doctrine/contract/decision tags + execution-core/governance
-- semantic types).
-- LEFT(_, 1500) keeps response under MCP token limits.
SELECT
  artifact_id,
  LEFT(payload::text, 1500) AS payload_preview
FROM qxb_artifact_snapshot
WHERE artifact_id = ANY(:high_signal_snapshot_ids);


-- ---------------------------------------------------------------------
-- Q3b — Hydrate restart extension payloads
-- ---------------------------------------------------------------------
SELECT
  artifact_id,
  LEFT(payload::text, 1500) AS payload_preview
FROM qxb_artifact_restart
WHERE artifact_id = ANY(:high_signal_restart_ids);


-- ---------------------------------------------------------------------
-- Q3c — Hydrate twig content (lives on spine, no twig extension table)
-- ---------------------------------------------------------------------
-- Important: twigs do NOT have an extension table. Their content lives
-- in qxb_artifact.content (jsonb). Querying qxb_artifact_twig will fail
-- with "relation does not exist".
SELECT
  artifact_id,
  LEFT(content::text, 1200) AS content_preview
FROM qxb_artifact
WHERE artifact_id = ANY(:high_signal_twig_ids);


-- ---------------------------------------------------------------------
-- Q3d — Hydrate project lifecycle/extension data (sometimes needed)
-- ---------------------------------------------------------------------
-- Projects have an extension table qxb_artifact_project for lifecycle +
-- operational state. Spine summary is usually enough; hit this only when
-- a project's operational_state or design_spine matters.
SELECT
  artifact_id,
  lifecycle_stage,
  operational_state,
  state_reason,
  design_spine,
  promoted_at
FROM qxb_artifact_project
WHERE artifact_id = ANY(:project_ids_of_interest);


-- ---------------------------------------------------------------------
-- Q4 — Date histogram (helpful for §10 grouping sanity check)
-- ---------------------------------------------------------------------
SELECT
  date_trunc('day', GREATEST(a.created_at, a.updated_at)) AS bucket_day_utc,
  COUNT(*) AS n
FROM qxb_artifact a
WHERE a.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND (
    (a.created_at >= :window_start_utc AND a.created_at <= :window_end_utc)
    OR
    (a.updated_at >= :window_start_utc AND a.updated_at <= :window_end_utc)
  )
GROUP BY 1
ORDER BY 1 DESC;


-- ---------------------------------------------------------------------
-- Q5 — Tag frequency (helpful for theme detection)
-- ---------------------------------------------------------------------
SELECT
  tag_value AS tag,
  COUNT(*)  AS n
FROM qxb_artifact a
CROSS JOIN LATERAL jsonb_array_elements_text(COALESCE(a.tags, '[]'::jsonb)) AS tag_value
WHERE a.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND (
    (a.created_at >= :window_start_utc AND a.created_at <= :window_end_utc)
    OR
    (a.updated_at >= :window_start_utc AND a.updated_at <= :window_end_utc)
  )
GROUP BY tag_value
ORDER BY n DESC
LIMIT 50;


-- ---------------------------------------------------------------------
-- Q6 — Duplicate-detection helper (§7 risk surfacing)
-- ---------------------------------------------------------------------
-- Surfaces artifacts with identical title in the window, separated by
-- less than 30 minutes. Catches Morning Flow duplicate / re-fire cases.
SELECT
  title,
  COUNT(*) AS dup_count,
  array_agg(artifact_id ORDER BY created_at) AS ids,
  array_agg(created_at ORDER BY created_at)  AS created_ats,
  EXTRACT(EPOCH FROM (MAX(created_at) - MIN(created_at)))/60 AS span_minutes
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND (
    (created_at >= :window_start_utc AND created_at <= :window_end_utc)
    OR
    (updated_at >= :window_start_utc AND updated_at <= :window_end_utc)
  )
GROUP BY title
HAVING COUNT(*) > 1
   AND EXTRACT(EPOCH FROM (MAX(created_at) - MIN(created_at)))/60 <= 30
ORDER BY dup_count DESC, span_minutes ASC;


-- ---------------------------------------------------------------------
-- Q7 — for-cc tag presence (§7 attention-concentration signal)
-- ---------------------------------------------------------------------
SELECT
  COUNT(*) FILTER (WHERE tags @> '["for-cc"]'::jsonb) AS for_cc_count,
  COUNT(*) FILTER (WHERE tags @> '["for-q"]'::jsonb)  AS for_q_count,
  COUNT(*) AS total
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND (
    (created_at >= :window_start_utc AND created_at <= :window_end_utc)
    OR
    (updated_at >= :window_start_utc AND updated_at <= :window_end_utc)
  );
