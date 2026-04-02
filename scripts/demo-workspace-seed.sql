-- ============================================================================
-- Demo Workspace Seed Data
-- ============================================================================
-- Purpose:   Pre-populate the Explore Qwrk Demo workspace with sample artifacts.
--            These seeds give the CustomGPT something to show new users.
--
-- Workspace: 0af5712b-2534-47c1-8e28-45be4a2131dc (Explore Qwrk Demo)
-- Owner:     c52c7a57-74ad-433d-a07c-4dcac1778672 (Joel)
-- Sem Type:  f65bd1a8-7720-4d7b-942c-ce8e2132b365 (exploratory)
-- Tags:      ["demo-mode", "explore-qwrk", "demo-seed"]
--
-- Governance: docs/design/Design__Explore_Qwrk_Demo_Governance__v1.md
-- Sapling:    ed978e03-5899-49cf-b72f-a09898399a36
--
-- IMPORTANT: demo-seed tag protects these from nightly cleanup.
--            User-created artifacts (without demo-seed) are cleaned after 24h.
--
-- Execute:   Run in Supabase SQL Editor (service_role context).
--            Script is idempotent-safe: uses gen_random_uuid() so re-runs
--            create new artifacts (cleanup old seeds first if re-seeding).
--
-- Re-seed:   To reset, run the cleanup query from Governance doc §15.3 first:
--            DELETE FROM qxb_artifact
--            WHERE workspace_id = '0af5712b-2534-47c1-8e28-45be4a2131dc';
--            Then re-run this script.
-- ============================================================================

BEGIN;

-- ── Seed 1: Project — "Starting a Side Project" ──
-- A seed-stage project showing how Qwrk captures ideas at their earliest stage.

WITH s1_spine AS (
  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, lifecycle_status, semantic_type_id, tags, content
  ) VALUES (
    '0af5712b-2534-47c1-8e28-45be4a2131dc',
    'c52c7a57-74ad-433d-a07c-4dcac1778672',
    'project',
    'Starting a Side Project',
    'Capturing the initial spark of an idea — a weekend app to track reading habits.',
    3,
    'seed',
    'f65bd1a8-7720-4d7b-942c-ce8e2132b365',
    '["demo-mode", "explore-qwrk", "demo-seed"]'::jsonb,
    '{"notes": "This is a demo project showing how Qwrk captures ideas at their earliest stage."}'::jsonb
  ) RETURNING artifact_id
)
INSERT INTO public.qxb_artifact_project (artifact_id, lifecycle_stage)
SELECT artifact_id, 'seed' FROM s1_spine;


-- ── Seed 2: Journal — "Morning Reflection" ──
-- A journal entry showing reflective thinking.

WITH s2_spine AS (
  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, semantic_type_id, tags
  ) VALUES (
    '0af5712b-2534-47c1-8e28-45be4a2131dc',
    'c52c7a57-74ad-433d-a07c-4dcac1778672',
    'journal',
    'Morning Reflection',
    'Thinking about what matters most this week.',
    3,
    'f65bd1a8-7720-4d7b-942c-ce8e2132b365',
    '["demo-mode", "explore-qwrk", "demo-seed"]'::jsonb
  ) RETURNING artifact_id
)
INSERT INTO public.qxb_artifact_journal (artifact_id, entry_text)
SELECT artifact_id,
  'Woke up feeling clear about priorities. The reading tracker idea keeps coming back — might be worth pursuing. Need to figure out what "done" looks like before I start building.'
FROM s2_spine;


-- ── Seed 3: Journal — "End of Day Check-In" ──
-- A second journal showing the pattern of ongoing reflection.

WITH s3_spine AS (
  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, semantic_type_id, tags
  ) VALUES (
    '0af5712b-2534-47c1-8e28-45be4a2131dc',
    'c52c7a57-74ad-433d-a07c-4dcac1778672',
    'journal',
    'End of Day Check-In',
    'Reviewing what got done and what carried over.',
    3,
    'f65bd1a8-7720-4d7b-942c-ce8e2132b365',
    '["demo-mode", "explore-qwrk", "demo-seed"]'::jsonb
  ) RETURNING artifact_id
)
INSERT INTO public.qxb_artifact_journal (artifact_id, entry_text)
SELECT artifact_id,
  'Spent some time sketching out the reading tracker. Realized I want it to be more than just a log — I want it to surface patterns. Like: am I reading more fiction when stressed? That would be the real value.'
FROM s3_spine;


-- ── Seed 4: Snapshot — "Decision: Keep It Simple" ──
-- A snapshot capturing a decision point — immutable once saved.

WITH s4_spine AS (
  INSERT INTO public.qxb_artifact (
    workspace_id, owner_user_id, artifact_type, title, summary,
    priority, semantic_type_id, tags
  ) VALUES (
    '0af5712b-2534-47c1-8e28-45be4a2131dc',
    'c52c7a57-74ad-433d-a07c-4dcac1778672',
    'snapshot',
    'Decision: Keep It Simple',
    'Decided to start with just title, author, and a one-line reflection per book.',
    3,
    'f65bd1a8-7720-4d7b-942c-ce8e2132b365',
    '["demo-mode", "explore-qwrk", "demo-seed"]'::jsonb
  ) RETURNING artifact_id
)
INSERT INTO public.qxb_artifact_snapshot (artifact_id, payload)
SELECT artifact_id,
  '{
    "decision": "Start with minimal fields: title, author, one-line reflection.",
    "reasoning": "The temptation is to build a full book database with ratings, genres, and reading speed. But the real test is whether I will actually use it. Minimal friction wins.",
    "alternatives_considered": [
      "Full book database with ratings",
      "Goodreads integration",
      "Just a spreadsheet"
    ],
    "chosen_because": "I want to build the habit of reflecting, not the habit of data entry."
  }'::jsonb
FROM s4_spine;

COMMIT;

-- ============================================================================
-- Verification query (run after seeding):
-- ============================================================================
-- SELECT artifact_id, artifact_type, title, tags
-- FROM public.qxb_artifact
-- WHERE workspace_id = '0af5712b-2534-47c1-8e28-45be4a2131dc'
--   AND deleted_at IS NULL
-- ORDER BY created_at;
--
-- Expected: 4 rows (1 project, 2 journals, 1 snapshot)
-- All should have tags containing "demo-seed"
-- ============================================================================

-- CHANGELOG
-- v1 — 2026-03-15
-- What changed: Initial seed script for Explore Qwrk Demo workspace
-- Why: Pre-populate demo with coherent sample content (side project narrative)
-- Scope: 4 artifacts (1 project, 2 journals, 1 snapshot) with demo-seed protection
-- How to validate: Run verification query above; confirm 4 rows with correct tags
