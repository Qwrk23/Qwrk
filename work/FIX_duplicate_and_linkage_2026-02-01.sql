-- FIX: Duplicate Seeds and Missing parent_artifact_id Links
-- Date: 2026-02-01
-- Context: Morning briefing found duplicate seeds and unlinked companion journals

-- ============================================
-- PART 1: Soft-delete duplicate seed projects
-- ============================================

-- Delete older "Journal Skill PRD" duplicate (keep 8a5d5cd1 - newer)
UPDATE qxb_artifact
SET deleted_at = NOW()
WHERE artifact_id = '539b52ca-c48e-403f-a258-88bfdc1496b8';

-- Delete older "Journal Mode Redesign" duplicate (keep 136e5384 - newer)
UPDATE qxb_artifact
SET deleted_at = NOW()
WHERE artifact_id = 'aadb0cfd-2dba-46d8-886f-8214c5cb2a05';

-- ============================================
-- PART 2: Link companion journals to parent seeds
-- ============================================

-- Link "Seed Content - Journal Mode Redesign" journal to its parent seed project
UPDATE qxb_artifact
SET parent_artifact_id = '136e5384-d05a-4071-97e4-702e0bb0d84d'
WHERE artifact_id = 'd8859f6c-8826-4de0-8199-d21857c934bd';

-- Link "Seed Content - Telegram Web + QP1" journal to its parent seed project
UPDATE qxb_artifact
SET parent_artifact_id = '00e5f131-6def-497d-8505-b0aff5d8f96e'
WHERE artifact_id = '4fcf15c7-dc7f-49d3-9fbb-3ddf08cf5c8d';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify duplicates are soft-deleted
SELECT artifact_id, title, deleted_at
FROM qxb_artifact
WHERE artifact_id IN (
  '539b52ca-c48e-403f-a258-88bfdc1496b8',
  'aadb0cfd-2dba-46d8-886f-8214c5cb2a05'
);

-- Verify parent links are set
SELECT artifact_id, title, parent_artifact_id
FROM qxb_artifact
WHERE artifact_id IN (
  'd8859f6c-8826-4de0-8199-d21857c934bd',
  '4fcf15c7-dc7f-49d3-9fbb-3ddf08cf5c8d'
);

-- Show linked pairs (journal → parent project)
SELECT
  j.title AS journal_title,
  j.artifact_id AS journal_id,
  p.title AS parent_title,
  p.artifact_id AS parent_id
FROM qxb_artifact j
JOIN qxb_artifact p ON j.parent_artifact_id = p.artifact_id
WHERE j.artifact_id IN (
  'd8859f6c-8826-4de0-8199-d21857c934bd',
  '4fcf15c7-dc7f-49d3-9fbb-3ddf08cf5c8d'
);
