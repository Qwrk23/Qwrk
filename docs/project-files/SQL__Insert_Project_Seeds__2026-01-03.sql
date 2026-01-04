-- SQL to Insert Project Seeds into Qwrk Database
-- Date: 2026-01-03
-- Purpose: Save two project seeds with lifecycle stage "seed"
--
-- Projects:
-- 1. Walk Phase 1: Email Automation
-- 2. Conversational Journaling as First-Class Artifact
--
-- Execute via Supabase SQL Editor

-- ============================================================================
-- PROJECT 1: Walk Phase 1 - Email Automation
-- ============================================================================

-- Step 1: Insert into qxb_artifact (spine table)
INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  owner_id,
  title,
  description,
  tags
) VALUES (
  'f8a3d7e2-9b4c-4a1e-8f2d-5c6b7a8e9d0f'::uuid,  -- Generated UUID for this project
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid,  -- Master Joel Workspace
  'project',
  'c52c7a57-74ad-433d-a07c-4dcac1778672'::uuid,  -- Joel's user_id
  'Walk Phase 1: Email Automation',
  'Build automated email sequences and admin digest workflows to enhance the Crawl MVP signup experience. This is the first "leaf" of Walk stage implementation. Includes Day 3 and Day 7 follow-up emails, admin digest workflow, and Google Sheets schema enhancements.',
  ARRAY['walk-stage', 'email-automation', 'onboarding', 'n8n-workflow', 'phase-1']::text[]
);

-- Step 2: Insert into qxb_artifact_project (extension table)
INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  operational_state
) VALUES (
  'f8a3d7e2-9b4c-4a1e-8f2d-5c6b7a8e9d0f'::uuid,  -- Same artifact_id as above
  'seed',
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
);

-- ============================================================================
-- PROJECT 2: Conversational Journaling as First-Class Artifact
-- ============================================================================

-- Step 1: Insert into qxb_artifact (spine table)
INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  owner_id,
  title,
  description,
  tags
) VALUES (
  'a1b2c3d4-e5f6-4g7h-8i9j-0k1l2m3n4o5p'::uuid,  -- Generated UUID for this project
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid,  -- Master Joel Workspace
  'project',
  'c52c7a57-74ad-433d-a07c-4dcac1778672'::uuid,  -- Joel's user_id
  'Conversational Journaling as First-Class Artifact',
  'Enable capturing entire reflective conversations between user and Qwrk as coherent journal artifacts. Preserves the full arc of thought including prompts, responses, emotional pivots, and reframes—not just final conclusions. Aligns with Qwrk''s core differentiation: continuity and cognitive lineage over disposable chats.',
  ARRAY['journaling', 'conversation-capture', 'core-product', 'cognitive-lineage', 'thinking-partner']::text[]
);

-- Step 2: Insert into qxb_artifact_project (extension table)
INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  operational_state
) VALUES (
  'a1b2c3d4-e5f6-4g7h-8i9j-0k1l2m3n4o5p'::uuid,  -- Same artifact_id as above
  'seed',
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
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Query 1: Verify both projects were inserted
SELECT
  a.artifact_id,
  a.title,
  a.artifact_type,
  a.tags,
  p.lifecycle_stage,
  a.created_at
FROM qxb_artifact a
JOIN qxb_artifact_project p ON a.artifact_id = p.artifact_id
WHERE a.artifact_id IN (
  'f8a3d7e2-9b4c-4a1e-8f2d-5c6b7a8e9d0f'::uuid,
  'a1b2c3d4-e5f6-4g7h-8i9j-0k1l2m3n4o5p'::uuid
)
ORDER BY a.created_at DESC;

-- Query 2: View operational_state for both projects
SELECT
  a.title,
  p.lifecycle_stage,
  p.operational_state
FROM qxb_artifact a
JOIN qxb_artifact_project p ON a.artifact_id = p.artifact_id
WHERE a.artifact_id IN (
  'f8a3d7e2-9b4c-4a1e-8f2d-5c6b7a8e9d0f'::uuid,
  'a1b2c3d4-e5f6-4g7h-8i9j-0k1l2m3n4o5p'::uuid
);

-- Query 3: List all seed-stage projects in workspace
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
ORDER BY a.created_at DESC;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
EXECUTION INSTRUCTIONS:
1. Open Supabase SQL Editor
2. Select project: npymhacpmxdnkdgzxll (Kernel v1)
3. Copy/paste SQL above
4. Execute all statements
5. Run verification queries to confirm insertion

ARTIFACT IDs GENERATED:
- Walk Phase 1: f8a3d7e2-9b4c-4a1e-8f2d-5c6b7a8e9d0f
- Conversational Journaling: a1b2c3d4-e5f6-4g7h-8i9j-0k1l2m3n4o5p

WORKSPACE CONTEXT:
- workspace_id: be0d3a48-c764-44f9-90c8-e846d9dbbd0a (Master Joel Workspace)
- owner_id: c52c7a57-74ad-433d-a07c-4dcac1778672 (Joel's user_id)

LIFECYCLE STAGE:
Both projects set to "seed" (🌱)

OPERATIONAL STATE:
Stored as JSONB with rich metadata about each project's status, deliverables,
next actions, and conceptual characteristics.
*/
