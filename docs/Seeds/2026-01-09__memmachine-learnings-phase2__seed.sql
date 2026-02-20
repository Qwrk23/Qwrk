-- SQL to insert MemMachine Learnings Seed Project into Qwrk
-- Date: 2026-01-09
-- Artifact Type: project (seed stage)
-- Parent: Core Build Cycle thicket

WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    artifact_id,
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags,
    content,
    parent_artifact_id,
    lifecycle_status,
    priority
  )
  VALUES (
    gen_random_uuid(),
    'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid,
    'c52c7a57-74ad-433d-a07c-4dcac1778672'::uuid,
    'project',
    'MemMachine Learnings for Qwrk Phase 2+',
    'Exploratory seed capturing valuable conceptual patterns from MemMachine n8n-nodes project: automatic context retrieval, external agent APIs, session tracking, and observability patterns for future Qwrk phases.',
    '["phase-2","memmachine","context-retrieval","semantic-search","external-api","observability"]'::jsonb,
    '{}'::jsonb,
    '84ccd9aa-c123-4747-968d-9262fa56ec65'::uuid,
    'seed',
    3
  )
  RETURNING artifact_id
)
INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  operational_state,
  state_reason
)
SELECT
  artifact_id,
  'seed',
  'active',
  'Exploratory seed - awaiting Beta V1 completion before Phase 2 planning'
FROM new_artifact;

-- Query to verify insertion
-- SELECT
--   a.artifact_id,
--   a.title,
--   a.artifact_type,
--   a.lifecycle_status,
--   p.lifecycle_stage,
--   p.operational_state,
--   a.created_at
-- FROM qxb_artifact a
-- JOIN qxb_artifact_project p ON a.artifact_id = p.artifact_id
-- WHERE a.title = 'MemMachine Learnings for Qwrk Phase 2+'
-- ORDER BY a.created_at DESC
-- LIMIT 1;
