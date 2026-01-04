# Kernel v1 — NoFail Insert Templates

**Purpose**: Schema-accurate SQL templates for all Kernel v1 artifact write patterns
**Source**: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`
**Date**: 2026-01-04
**Status**: Authoritative SQL Reference

---

## Overview

These templates follow **DDL-as-Truth** and **NoFail discipline**:
- ✅ Exact column names from LIVE DDL
- ✅ Correct data types and constraints
- ✅ `gen_random_uuid()` for artifact_id (never manual assignment)
- ✅ `RETURNING` clause to capture generated IDs
- ✅ CTE pattern for spine → extension dependencies
- ✅ Example JSONB payloads that match schema

---

## Table of Contents

1. [Spine Insert (qxb_artifact)](#1-spine-insert-qxb_artifact)
2. [Project Artifact](#2-project-artifact)
3. [Journal Artifact](#3-journal-artifact)
4. [Snapshot Artifact](#4-snapshot-artifact)
5. [Restart Artifact](#5-restart-artifact)
6. [Grass Artifact](#6-grass-artifact-operational-tracking)
7. [Thorn Artifact](#7-thorn-artifact-exception-tracking)
8. [Event Log Append](#8-event-log-append-qxb_artifact_event)

---

## 1. Spine Insert (qxb_artifact)

**Use Case**: Insert into spine table only (no extension). Rarely used alone; typically followed by extension insert.

### Template

```sql
INSERT INTO qxb_artifact (
  workspace_id,
  owner_user_id,
  artifact_type,
  title,
  summary,
  tags,
  content
) VALUES (
  'workspace-uuid-here'::uuid,
  'user-uuid-here'::uuid,
  'project',  -- Must match allowed types in CHECK constraint
  'Artifact Title',
  'Brief summary for list views',
  '["tag1", "tag2", "tag3"]'::jsonb,  -- Array of strings
  '{
    "key1": "value1",
    "key2": "value2"
  }'::jsonb
)
RETURNING artifact_id, created_at;
```

### Required Columns

- `workspace_id` (uuid, NOT NULL)
- `owner_user_id` (uuid, NOT NULL)
- `artifact_type` (text, NOT NULL) — Must be in CHECK constraint
- `title` (text, NOT NULL)

### Optional Columns

- `summary` (text)
- `priority` (integer 1-5)
- `lifecycle_status` (text)
- `tags` (jsonb)
- `content` (jsonb)
- `parent_artifact_id` (uuid FK to qxb_artifact)

### Auto-Generated Columns (Do Not Provide)

- `artifact_id` (uuid, gen_random_uuid())
- `version` (integer, default 1)
- `created_at` (timestamptz, now())
- `updated_at` (timestamptz, now())
- `deleted_at` (timestamptz, NULL)

---

## 2. Project Artifact

**Use Case**: Create project with lifecycle tracking (seed → sapling → tree → retired)

### Full Transaction Template

```sql
BEGIN;

-- Step 1: Insert spine
WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags,
    content
  ) VALUES (
    'workspace-uuid-here'::uuid,
    'user-uuid-here'::uuid,
    'project',
    'Walk Phase 1: Email Automation',
    'Build automated email sequences for signup flow enhancement',
    '["walk-stage", "email-automation", "phase-1"]'::jsonb,
    '{
      "phase": "walk-phase-1",
      "crawl_completion": "2026-01-03"
    }'::jsonb
  )
  RETURNING artifact_id
)

-- Step 2: Insert project extension
INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  operational_state
)
SELECT
  artifact_id,
  'seed',
  '{
    "status": "ready_to_activate",
    "prerequisite": "crawl_complete",
    "deliverables": [
      "Email sequences workflow",
      "Admin digest workflow",
      "Email templates",
      "Runbook",
      "Test plan"
    ],
    "timeline_estimate": "1-2 weeks",
    "next_actions": [
      "Draft email templates",
      "Design n8n workflow logic",
      "Build and test workflows"
    ]
  }'::jsonb
FROM new_artifact
RETURNING artifact_id;

COMMIT;
```

### Lifecycle Stages

- `seed` — Initial project seed
- `sapling` — Active development
- `tree` — Mature/production
- `retired` — Archived/completed

### operational_state JSONB Structure

Flexible structure; common keys:
```json
{
  "status": "ready_to_activate",
  "prerequisite": "dependency_name",
  "deliverables": ["item1", "item2"],
  "timeline_estimate": "duration",
  "next_actions": ["action1", "action2"],
  "references": {
    "design_doc": "path",
    "runbook": "path"
  }
}
```

---

## 3. Journal Artifact

**Use Case**: Owner-private reflective entries

### Full Transaction Template

```sql
BEGIN;

-- Step 1: Insert spine
WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags
  ) VALUES (
    'workspace-uuid-here'::uuid,
    'user-uuid-here'::uuid,
    'journal',
    'Reflections on Product Strategy — 2026-01-04',
    'Strategic thinking about onboarding flow evolution',
    '["strategy", "product", "onboarding"]'::jsonb
  )
  RETURNING artifact_id
)

-- Step 2: Insert journal extension
INSERT INTO qxb_artifact_journal (
  artifact_id,
  entry_text,
  payload
)
SELECT
  artifact_id,
  'Today I reflected on the balance between MVP velocity and long-term architecture...',
  '{
    "mood": "contemplative",
    "session_type": "strategic_thinking",
    "key_insights": [
      "Walk stage automation will reduce manual overhead",
      "Need to prioritize email deliverability"
    ],
    "follow_up_tasks": [
      "Research email service providers",
      "Draft Walk Phase 2 design"
    ]
  }'::jsonb
FROM new_artifact
RETURNING artifact_id;

COMMIT;
```

### RLS Note

**Journals are owner-only.** Only `owner_user_id` can SELECT/UPDATE this artifact.

### payload JSONB Structure

Flexible structure; common keys:
```json
{
  "mood": "string",
  "session_type": "string",
  "conversation_id": "uuid",
  "key_insights": ["insight1", "insight2"],
  "follow_up_tasks": ["task1", "task2"]
}
```

---

## 4. Snapshot Artifact

**Use Case**: Immutable lifecycle snapshots (CREATE-ONLY, no updates)

### Full Transaction Template

```sql
BEGIN;

-- Step 1: Insert spine
WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags
  ) VALUES (
    'workspace-uuid-here'::uuid,
    'user-uuid-here'::uuid,
    'snapshot',
    'Project Seeds Post-Insert Snapshot — 2026-01-04',
    'Captured state after inserting two seed-stage projects',
    '["snapshot", "project-seeds", "kernel-v1"]'::jsonb
  )
  RETURNING artifact_id
)

-- Step 2: Insert snapshot extension (IMMUTABLE)
INSERT INTO qxb_artifact_snapshot (
  artifact_id,
  payload
)
SELECT
  artifact_id,
  '{
    "snapshot_type": "project_milestone",
    "captured_at": "2026-01-04T10:30:00Z",
    "projects_created": 2,
    "project_ids": [
      "uuid1",
      "uuid2"
    ],
    "milestone": "walk_phase1_seed_created",
    "state_description": "Two project seeds created: Walk Phase 1 (ready) and Conversational Journaling (conceptual)"
  }'::jsonb
FROM new_artifact
RETURNING artifact_id;

COMMIT;
```

### Mutability Rules

- **CREATE-ONLY**: No UPDATE or DELETE policies
- **Immutable**: `payload` cannot be changed after insert
- **Purpose**: Frozen state captures for audit/history

---

## 5. Restart Artifact

**Use Case**: Manual session continuation context (CREATE-ONLY, no updates)

### Full Transaction Template

```sql
BEGIN;

-- Step 1: Insert spine
WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags,
    parent_artifact_id
  ) VALUES (
    'workspace-uuid-here'::uuid,
    'user-uuid-here'::uuid,
    'restart',
    'Restart: Walk Phase 1 Implementation',
    'Session continuation for email automation workflow build',
    '["restart", "walk-phase1", "email-automation"]'::jsonb,
    'parent-project-uuid-here'::uuid  -- Optional: link to parent project
  )
  RETURNING artifact_id
)

-- Step 2: Insert restart extension (IMMUTABLE)
INSERT INTO qxb_artifact_restart (
  artifact_id,
  payload
)
SELECT
  artifact_id,
  '{
    "restart_type": "session_resume",
    "prior_session_date": "2026-01-03",
    "prior_session_summary": "Completed Crawl MVP and created Walk Phase 1 project seed",
    "context_items": [
      "Email templates need drafting",
      "n8n workflow logic designed but not built",
      "Google Sheets schema changes identified"
    ],
    "continuation_intent": "Build email sequences workflow and test with production data",
    "next_immediate_actions": [
      "Draft Day 3 email template",
      "Draft Day 7 email template",
      "Create Qxb_Onboarding_Email_Sequences_v1 workflow"
    ]
  }'::jsonb
FROM new_artifact
RETURNING artifact_id;

COMMIT;
```

### Mutability Rules

- **CREATE-ONLY**: No UPDATE or DELETE policies
- **Immutable**: `payload` cannot be changed
- **Purpose**: Session continuation breadcrumbs

---

## 6. Grass Artifact (Operational Tracking)

**Use Case**: Track transient operational issues detected by workflows

### Full Transaction Template

```sql
BEGIN;

-- Step 1: Insert spine
WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags
  ) VALUES (
    'workspace-uuid-here'::uuid,
    'user-uuid-here'::uuid,
    'grass',
    'Email Bounce Detected — joel@example.com',
    'Signup confirmation email bounced (invalid address)',
    '["email-issue", "bounce", "operational"]'::jsonb
  )
  RETURNING artifact_id
)

-- Step 2: Insert grass extension
INSERT INTO qxb_artifact_grass (
  artifact_id,
  source_system,
  source_workflow,
  source_execution_id,
  summary,
  details_json,
  review_status,
  disposition
)
SELECT
  artifact_id,
  'n8n',
  'Qxb_Onboarding_Email_Sequences_v1',
  'execution-id-12345',
  'Email bounce detected for joel@example.com during Day 3 follow-up',
  '{
    "bounce_type": "hard",
    "bounce_reason": "Invalid mailbox",
    "email_address": "joel@example.com",
    "signup_id": "uuid-here",
    "detected_at": "2026-01-04T14:22:00Z"
  }'::jsonb,
  'unreviewed',
  'none'
FROM new_artifact
RETURNING artifact_id;

COMMIT;
```

### Review Status Values

- `unreviewed` (default)
- `reviewed`
- `dismissed`

### Disposition Values

- `none` (default)
- `promoted_to_flower` (escalated to higher-priority tracking)
- `dismissed`

---

## 7. Thorn Artifact (Exception Tracking)

**Use Case**: Track significant exceptions requiring attention

### Full Transaction Template

```sql
BEGIN;

-- Step 1: Insert spine
WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags
  ) VALUES (
    'workspace-uuid-here'::uuid,
    'user-uuid-here'::uuid,
    'thorn',
    'Gateway Timeout — artifact.query Failed',
    'Gateway workflow timeout during artifact.query operation',
    '["exception", "timeout", "gateway"]'::jsonb
  )
  RETURNING artifact_id
)

-- Step 2: Insert thorn extension
INSERT INTO qxb_artifact_thorn (
  artifact_id,
  source_system,
  source_workflow,
  source_execution_id,
  severity,
  summary,
  details_json,
  review_status,
  resolution
)
SELECT
  artifact_id,
  'n8n',
  'NQxb_Gateway_v1',
  'execution-id-67890',
  'high',
  'Gateway timeout: Supabase query exceeded 30s timeout threshold',
  '{
    "error_type": "timeout",
    "operation": "artifact.query",
    "artifact_type": "project",
    "workspace_id": "uuid-here",
    "timeout_duration_ms": 30000,
    "stack_trace": "...",
    "supabase_query": "SELECT * FROM qxb_artifact WHERE ...",
    "detected_at": "2026-01-04T15:45:00Z"
  }'::jsonb,
  'unreviewed',
  'none'
FROM new_artifact
RETURNING artifact_id;

COMMIT;
```

### Severity Values

- `low`
- `medium` (default)
- `high`
- `critical`

### Resolution Values

- `none` (default)
- `resolved`
- `dismissed`
- `escalated`

---

## 8. Event Log Append (qxb_artifact_event)

**Use Case**: Append-only audit log for artifact operations

### Template

```sql
INSERT INTO qxb_artifact_event (
  workspace_id,
  artifact_id,
  actor_user_id,
  event_type,
  payload
) VALUES (
  'workspace-uuid-here'::uuid,
  'artifact-uuid-here'::uuid,
  'user-uuid-here'::uuid,
  'artifact.created',
  '{
    "artifact_type": "project",
    "lifecycle_stage": "seed",
    "created_via": "n8n_workflow",
    "workflow_name": "manual_insert"
  }'::jsonb
)
RETURNING event_id, event_ts;
```

### Common Event Types

- `artifact.created`
- `artifact.updated`
- `artifact.deleted` (soft delete)
- `artifact.lifecycle_transition` (e.g., seed → sapling)
- `artifact.promoted` (e.g., grass → flower)

### Mutability Rules

- **APPEND-ONLY**: Triggers block UPDATE and DELETE
- **Immutable**: Cannot modify event log records
- **Purpose**: Audit trail / explainability

---

## Pre-Flight Checklist Template

Before executing ANY SQL from these templates:

```
✅ Verified table name exists in LIVE DDL?
✅ Verified all column names exist in LIVE DDL?
✅ Verified data types match exactly?
✅ Verified NOT NULL constraints satisfied?
✅ Verified CHECK constraints respected?
   - artifact_type in allowed list?
   - priority between 1-5?
   - Enum fields match allowed values?
✅ Using gen_random_uuid() for artifact_id?
✅ Using RETURNING clause to capture generated ID?
✅ JSONB payloads valid and match expected structure?
✅ FK references valid (workspace_id, owner_user_id exist)?
```

---

## CHANGELOG

### v1 - 2026-01-04
**What changed**: Initial SQL templates creation

**Why**: Establish DDL-as-Truth governance; eliminate SQL errors from schema drift

**Scope**: All Kernel v1 artifact write patterns with schema-accurate templates

**Source**: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`

**How to validate**: Cross-reference column names, types, and constraints against LIVE DDL

---

**Version**: v1
**Status**: Authoritative SQL Reference
**Source**: LIVE DDL (2026-01-04)
**Last Updated**: 2026-01-04
