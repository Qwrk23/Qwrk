# KGB — No-Fail SQL Pattern: Save a Project (Spine + Extension) (v1)
**Date:** 2026-01-03 (CST)  
**Applies to:** `qxb_artifact` + `qxb_artifact_project`  
**Goal:** Avoid schema-drift mistakes (e.g., wrong column names) and create a repeatable, no-fail insert pattern.

---

## What went wrong (baseline captured)
We attempted to insert columns that **do not exist** in `qxb_artifact_project` (`start_date`, `target_date`, `retired_at`, `last_lifecycle_change_at`, `lifecycle_notes`).

**Actual `qxb_artifact_project` columns (confirmed):**
- `artifact_id` (uuid, PK/FK)
- `lifecycle_stage` (text, NOT NULL)
- `operational_state` (text, NOT NULL)
- `state_reason` (text, nullable)
- `created_at` (timestamptz, NOT NULL, default now())
- `updated_at` (timestamptz, NOT NULL, default now())

---

## Invariants (must hold)
1. Insert **spine row** first in `qxb_artifact`.
2. Insert **extension row** next in `qxb_artifact_project` using the same `artifact_id`.
3. `qxb_artifact_project.lifecycle_stage` is required and should mirror `qxb_artifact.lifecycle_status` (until/unless we lock otherwise).
4. Use `gen_random_uuid()` in SQL for deterministic creation (Gateway can generate IDs later; SQL can generate now).
5. If creating lineage containers (e.g., thicket), resolve-or-create them first, then parent the project correctly.

---

## No-Fail Template (Project)
Use this template as the canonical baseline for “project save” via SQL:

- Resolve-or-create parent container (optional)
- Insert into `qxb_artifact`
- Insert into `qxb_artifact_project`

**Key: never invent columns; only use the confirmed schema.**

---

## Next hardening step
Create KGB patterns for:
- Snapshot save (spine + `qxb_artifact_snapshot`)
- Restart save (spine + `qxb_artifact_restart`)
- Journal save (spine + `qxb_artifact_journal`)
- Forest/Thicket save (if those types are live in DB)

(We will add each as we validate their exact schemas.)


-- KGB: Save Snapshot (spine + qxb_artifact_snapshot)
-- Assumes you already know:
--   workspace_id, owner_user_id
--   project_artifact_id you are snapshotting
-- You may optionally pre-fetch frozen_payload via SELECTs, or paste it in.

DO $$
DECLARE
  v_workspace_id uuid := 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a';
  v_owner_user_id uuid := 'c52c7a57-74ad-433d-a07c-4dcac1778672';

  v_project_artifact_id uuid := 'PUT_PROJECT_ARTIFACT_ID_HERE';
  v_snapshot_id uuid := gen_random_uuid();

  -- lifecycle context (store inside payload)
  v_lifecycle_from text := 'seed';
  v_lifecycle_to   text := 'sapling';

  -- captured version of the project (store inside payload)
  v_captured_version int := 1;

  -- optional narrative
  v_capture_reason text := 'Lifecycle transition snapshot';

  -- frozen payload (store inside payload)
  -- For KGB purposes, you can start with a minimal object and evolve later.
  v_frozen_payload jsonb := jsonb_build_object(
    'project_artifact_id', v_project_artifact_id,
    'note', 'Replace this with a hydrated project object when ready.'
  );

  v_payload jsonb;
BEGIN
  -- Build snapshot payload (extension table only stores payload jsonb)
  v_payload := jsonb_build_object(
    'project_artifact_id', v_project_artifact_id,
    'lifecycle_from', v_lifecycle_from,
    'lifecycle_to', v_lifecycle_to,
    'captured_version', v_captured_version,
    'capture_reason', v_capture_reason,
    'frozen_payload', v_frozen_payload
  );

  -- 1) Insert spine row
  INSERT INTO public.qxb_artifact (
    artifact_id,
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    priority,
    lifecycle_status,
    tags,
    content,
    parent_artifact_id,
    version,
    created_at,
    updated_at
  ) VALUES (
    v_snapshot_id,
    v_workspace_id,
    v_owner_user_id,
    'snapshot',
    'Snapshot — ' || v_lifecycle_from || ' → ' || v_lifecycle_to,
    'Lifecycle-only snapshot capturing project state at promotion time.',
    3,
    'seed',
    jsonb_build_array('snapshot','lifecycle','kgb'),
    jsonb_build_object(
      'project_artifact_id', v_project_artifact_id,
      'lifecycle_from', v_lifecycle_from,
      'lifecycle_to', v_lifecycle_to
    ),
    v_project_artifact_id,
    1,
    now(),
    now()
  );

  -- 2) Insert snapshot extension row (LIVE SCHEMA: artifact_id, payload, created_at)
  INSERT INTO public.qxb_artifact_snapshot (
    artifact_id,
    payload,
    created_at
  ) VALUES (
    v_snapshot_id,
    v_payload,
    now()
  );

END $$;

-- KGB: Save Restart (spine + qxb_artifact_restart)
-- Assumes you already know:
--   workspace_id, owner_user_id
--   project_artifact_id you are freezing (recommended as parent)

DO $$
DECLARE
  v_workspace_id uuid := 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a';
  v_owner_user_id uuid := 'c52c7a57-74ad-433d-a07c-4dcac1778672';

  v_project_artifact_id uuid := 'PUT_PROJECT_ARTIFACT_ID_HERE';
  v_restart_id uuid := gen_random_uuid();

  v_restart_reason text := 'Pause / handoff';
  v_next_step text := 'Describe the next concrete action to resume';

  -- frozen payload (start minimal; can be hydrated later)
  v_frozen_payload jsonb := jsonb_build_object(
    'project_artifact_id', v_project_artifact_id,
    'note', 'Replace this with a hydrated project object when ready.'
  );

  v_payload jsonb;
BEGIN
  -- Build restart payload (extension table only stores payload jsonb)
  v_payload := jsonb_build_object(
    'project_artifact_id', v_project_artifact_id,
    'restart_reason', v_restart_reason,
    'next_step', v_next_step,
    'frozen_payload', v_frozen_payload
  );

  -- 1) Insert spine row
  INSERT INTO public.qxb_artifact (
    artifact_id,
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    priority,
    lifecycle_status,
    tags,
    content,
    parent_artifact_id,
    version,
    created_at,
    updated_at
  ) VALUES (
    v_restart_id,
    v_workspace_id,
    v_owner_user_id,
    'restart',
    'Restart — ' || v_restart_reason,
    'Ad-hoc freeze + next step (does not change lifecycle).',
    3,
    'seed',
    jsonb_build_array('restart','handoff','kgb'),
    jsonb_build_object(
      'project_artifact_id', v_project_artifact_id,
      'restart_reason', v_restart_reason,
      'next_step', v_next_step
    ),
    v_project_artifact_id,
    1,
    now(),
    now()
  );

  -- 2) Insert restart extension row (LIVE SCHEMA: artifact_id, payload, created_at)
  INSERT INTO public.qxb_artifact_restart (
    artifact_id,
    payload,
    created_at
  ) VALUES (
    v_restart_id,
    v_payload,
    now()
  );

END $$;

-- KGB: Save Journal (spine + qxb_artifact_journal)
-- Assumes you already know:
--   workspace_id, owner_user_id
-- Optionally relate the journal to a project via parent_artifact_id or payload.

DO $$
DECLARE
  v_workspace_id uuid := 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a';
  v_owner_user_id uuid := 'c52c7a57-74ad-433d-a07c-4dcac1778672';

  -- Optional: link to a project as the parent. Set NULL if truly standalone.
  v_parent_project_id uuid := NULL;  -- e.g. 'PUT_PROJECT_ARTIFACT_ID_HERE'

  v_journal_id uuid := gen_random_uuid();

  v_entry_text text := 'Journal entry text goes here.';
  v_payload jsonb := jsonb_build_object(
    'mood', 'calm',
    'tags', jsonb_build_array('journal','kgb'),
    'note', 'Add any structured metadata here; keep long text in entry_text.'
  );
BEGIN
  -- 1) Insert spine row
  INSERT INTO public.qxb_artifact (
    artifact_id,
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    priority,
    lifecycle_status,
    tags,
    content,
    parent_artifact_id,
    version,
    created_at,
    updated_at
  ) VALUES (
    v_journal_id,
    v_workspace_id,
    v_owner_user_id,
    'journal',
    'Journal — ' || to_char(now(), 'YYYY-MM-DD'),
    'Journal entry captured as a first-class artifact.',
    4,
    'seed',
    jsonb_build_array('journal','kgb'),
    jsonb_build_object(
      'has_entry_text', (v_entry_text IS NOT NULL),
      'has_payload', (v_payload IS NOT NULL)
    ),
    v_parent_project_id,
    1,
    now(),
    now()
  );

  -- 2) Insert journal extension row (LIVE SCHEMA: artifact_id, entry_text, payload, created_at, updated_at)
  INSERT INTO public.qxb_artifact_journal (
    artifact_id,
    entry_text,
    payload,
    created_at,
    updated_at
  ) VALUES (
    v_journal_id,
    v_entry_text,
    v_payload,
    now(),
    now()
  );

END $$;

