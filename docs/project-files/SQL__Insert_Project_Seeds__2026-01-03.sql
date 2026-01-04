-- SQL to Insert Project Artifacts (Lifecycle: Seed) into Qwrk Database
-- Date: 2026-01-03
-- Version: v3 (CORRECTED - Schema-Accurate)
-- Purpose: Create two project artifacts with lifecycle_stage = 'seed'
--
-- Projects:
-- 1. Walk Phase 1: Email Automation (ready to activate)
-- 2. Conversational Journaling as First-Class Artifact (conceptual direction)
--
-- Schema Compliance: Kernel v1 (NoFail discipline)
-- Execute via: Supabase SQL Editor

-- ============================================================================
-- SINGLE TRANSACTION: Insert Both Projects
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- PROJECT 1: Walk Phase 1 - Email Automation
-- ----------------------------------------------------------------------------

-- Step 1: Insert into qxb_artifact (spine table)
WITH new_project_1 AS (
  INSERT INTO qxb_artifact (
    workspace_id,
    artifact_type,
    owner_user_id,
    title,
    summary,
    tags,
    content
  ) VALUES (
    'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid,  -- Master Joel Workspace
    'project',
    'c52c7a57-74ad-433d-a07c-4dcac1778672'::uuid,  -- Joel's user_id
    'Walk Phase 1: Email Automation',
    'Build automated email sequences and admin digest workflows to enhance the Crawl MVP signup experience. First leaf of Walk stage implementation.',
    '["walk-stage", "email-automation", "onboarding", "n8n-workflow", "phase-1"]'::jsonb,
    '{
      "description_full": "Includes Day 3 and Day 7 follow-up emails, admin digest workflow, and Google Sheets schema enhancements for tracking email sends.",
      "crawl_completion": "2026-01-03",
      "phase": "walk-phase-1"
    }'::jsonb
  )
  RETURNING artifact_id
)

-- Step 2: Insert into qxb_artifact_project (extension table)
INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  operational_state
)
SELECT
  artifact_id,
  'seed'::text,
  '{
    "status": "ready_to_activate",
    "prerequisite": "crawl_complete",
    "crawl_completion_date": "2026-01-03",
    "deliverables": [
      "Qxb_Onboarding_Email_Sequences_v1.json",
      "Qxb_Onboarding_Admin_Digest_v1.json",
      "Email templates (Day 3, Day 7, Admin Digest)",
      "Runbook for activation",
      "Test plan"
    ],
    "schema_changes": {
      "google_sheets": {
        "table": "Qwrk NDA Signups",
        "new_columns": ["email_sent_day_3", "email_sent_day_7", "priority", "last_contacted"]
      }
    },
    "timeline_estimate": "1-2 weeks",
    "next_actions": [
      "Draft email templates",
      "Design n8n workflow logic",
      "Add tracking columns to Google Sheets",
      "Build and test workflows",
      "Create runbook and test plan"
    ],
    "references": {
      "design_doc": "docs/design/Design__Onboarding_Walk_Stage__Enhanced_MVP.md",
      "crawl_runbook": "docs/runbooks/Runbook__Activate_MVP_Signup__Crawl_Stage.md",
      "production_form": "https://n8n.halosparkai.com/form/qwrk-nda-signup"
    }
  }'::jsonb
FROM new_project_1;

-- ----------------------------------------------------------------------------
-- PROJECT 2: Conversational Journaling as First-Class Artifact
-- ----------------------------------------------------------------------------

-- Step 1: Insert into qxb_artifact (spine table)
WITH new_project_2 AS (
  INSERT INTO qxb_artifact (
    workspace_id,
    artifact_type,
    owner_user_id,
    title,
    summary,
    tags,
    content
  ) VALUES (
    'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid,  -- Master Joel Workspace
    'project',
    'c52c7a57-74ad-433d-a07c-4dcac1778672'::uuid,  -- Joel's user_id
    'Conversational Journaling as First-Class Artifact',
    'Enable capturing entire reflective conversations between user and Qwrk as coherent journal artifacts. Preserves the full arc of thought including prompts, responses, emotional pivots, and reframes.',
    '["journaling", "conversation-capture", "core-product", "cognitive-lineage", "thinking-partner"]'::jsonb,
    '{
      "description_full": "Aligns with Qwrk core differentiation: continuity and cognitive lineage over disposable chats. Insight is dialogic, emergent, and emotionally contextual.",
      "stage": "conceptual",
      "category": "core-product-feature"
    }'::jsonb
  )
  RETURNING artifact_id
)

-- Step 2: Insert into qxb_artifact_project (extension table)
INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  operational_state
)
SELECT
  artifact_id,
  'seed'::text,
  '{
    "status": "conceptual_direction",
    "maturity": "philosophical_foundation",
    "core_idea": "Preserve full conversation transcripts as journal artifacts, not just user-written paragraphs",
    "what_this_enables": [
      "Preservation of how insight was reached, not just the outcome",
      "Record of evolving beliefs and decisions in context",
      "Richer long-term memory for coaching and reflection",
      "Qwrk as witness and thinking partner"
    ],
    "conceptual_characteristics": {
      "artifact_composition": [
        "Full conversation transcript (user + Qwrk)",
        "Session metadata (date, mode, intent)",
        "Optional post-session highlights or summary layers"
      ],
      "canonical_source": "Raw conversation preserved; summaries are derivative",
      "capture_method": "Manual at first, with future guided or automatic capture",
      "artifact_meaning": "Represents a thinking session, not a document draft"
    },
    "philosophy_alignment": {
      "core_differentiation": "Insight is dialogic, emergent, and emotionally contextual",
      "qwrk_value": "Adapts to how users understand and arrive at meaning, not just what they conclude"
    },
    "open_questions": [
      "Privacy & Control: How do users control what gets captured vs ephemeral?",
      "Granularity: Tag individual messages or capture whole sessions?",
      "AI Role: Proactively identify journaling moments or wait for user intent?",
      "Editability: Immutable transcript or editable with version history?",
      "Cross-session linking: How do journal entries relate to projects, restarts, other artifacts?"
    ],
    "next_actions_for_sapling": [
      "User research: Interview beta users about journaling practices",
      "Schema design: Define journal artifact extension for conversation storage",
      "Prototype: Build minimal capture flow (manual save → transcript storage)",
      "Test hypothesis: Does full conversation add value vs summary-only?",
      "Iterate based on usage patterns"
    ],
    "no_commitments_yet": {
      "ui_design": "undefined",
      "schema_details": "undefined",
      "implementation_timeline": "undefined",
      "feature_prioritization": "undefined"
    }
  }'::jsonb
FROM new_project_2;

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES (Run After Commit)
-- ============================================================================

-- Query 1: List all seed-stage projects (should show our 2 new projects)
SELECT
  a.artifact_id,
  a.title,
  p.lifecycle_stage,
  a.created_at,
  a.tags
FROM qxb_artifact a
JOIN qxb_artifact_project p ON a.artifact_id = p.artifact_id
WHERE a.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid
  AND p.lifecycle_stage = 'seed'
ORDER BY a.created_at DESC
LIMIT 10;

-- Query 2: View full details of both new projects
SELECT
  a.artifact_id,
  a.title,
  a.summary,
  a.artifact_type,
  p.lifecycle_stage,
  p.operational_state,
  a.tags,
  a.content,
  a.created_at
FROM qxb_artifact a
JOIN qxb_artifact_project p ON a.artifact_id = p.artifact_id
WHERE a.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid
  AND p.lifecycle_stage = 'seed'
  AND a.created_at > NOW() - INTERVAL '5 minutes'  -- Only recent inserts
ORDER BY a.created_at DESC;

-- Query 3: Extract operational_state for Walk Phase 1 (most recent seed project)
SELECT
  a.title,
  p.lifecycle_stage,
  jsonb_pretty(p.operational_state) AS operational_state_pretty
FROM qxb_artifact a
JOIN qxb_artifact_project p ON a.artifact_id = p.artifact_id
WHERE a.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid
  AND p.lifecycle_stage = 'seed'
ORDER BY a.created_at DESC
LIMIT 1;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
EXECUTION INSTRUCTIONS:
1. Open Supabase SQL Editor
2. Select project: npymhacpmxdnkdgzxll (Kernel v1)
3. Copy/paste the entire transaction block (BEGIN...COMMIT)
4. Execute transaction
5. Run verification queries to confirm insertion

SCHEMA COMPLIANCE (Kernel v1 - ACTUAL SCHEMA):
✅ Uses gen_random_uuid() for artifact_id (NoFail discipline)
✅ Correct column names: owner_user_id, summary
✅ tags column exists (JSONB) - used for tag arrays
✅ content column exists (JSONB) - used for additional metadata
✅ All NOT NULL constraints satisfied
✅ Valid UUIDs (workspace_id, owner_user_id)
✅ Uses RETURNING clause to capture generated artifact_id
✅ CTE pattern for spine → extension insert dependency

ACTUAL qxb_artifact COLUMNS (from schema):
- artifact_id (uuid, PK, default gen_random_uuid())
- workspace_id (uuid, NOT NULL)
- owner_user_id (uuid, NOT NULL)
- artifact_type (text, NOT NULL)
- title (text, NOT NULL)
- summary (text, NULL)
- priority (int, NULL)
- lifecycle_status (text, NULL)
- tags (jsonb, NULL) ✅ EXISTS
- content (jsonb, NULL) ✅ EXISTS
- parent_artifact_id (uuid, NULL)
- version (int, NOT NULL, default 1)
- deleted_at (timestamptz, NULL)
- created_at (timestamptz, NOT NULL, default now())
- updated_at (timestamptz, NOT NULL, default now())

WORKSPACE CONTEXT:
- workspace_id: be0d3a48-c764-44f9-90c8-e846d9dbbd0a (Master Joel Workspace)
- owner_user_id: c52c7a57-74ad-433d-a07c-4dcac1778672 (Joel's user_id)

LIFECYCLE STAGE:
Both projects set to lifecycle_stage = 'seed' (🌱)

OPERATIONAL STATE:
Stored as JSONB with rich metadata about each project's status, deliverables,
next actions, and conceptual characteristics.

ARTIFACT IDs:
Generated by database (gen_random_uuid())
Retrieved via verification queries after insert

VERSION HISTORY:
v1 (BROKEN): Wrong column names (owner_id, description), invalid UUID, manual artifact_id
v2 (BROKEN): Fixed column names but used non-existent 'payload' column
v3 (CURRENT): Correct schema - uses 'tags' and 'content' columns
*/
