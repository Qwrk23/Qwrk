-- ============================================================
-- KGB-LOCK: Gateway Type Registry Guard
-- Creates: 1 Project + 1 Snapshot + 1 Restart
-- Date: 2026-01-24
-- ============================================================

DO $OUTER$
DECLARE
    v_project_id  uuid := gen_random_uuid();
    v_snapshot_id uuid := gen_random_uuid();
    v_restart_id  uuid := gen_random_uuid();
    v_workspace_id uuid := 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a';
    v_owner_user_id uuid := 'c52c7a57-74ad-433d-a07c-4dcac1778672';
    v_snapshot_markdown text;
    v_restart_markdown text;
BEGIN
    -- ========================================
    -- Define markdown content
    -- ========================================

    v_snapshot_markdown := $MD_SNAPSHOT$# SNAPSHOT — Gateway Type Registry Guard (KGB-LOCK Candidate)

**Date:** 2026-01-24 (CST)
**Scope:** Gateway v1 — WRITE workflows only
**Status:** KGB-LOCKED (Governance Close-Out)

---

## Purpose

Lock the verified behavior of the Gateway Type Registry Guard so future workflow changes cannot silently loosen enforcement.

This snapshot is based on direct review of the actual n8n workflow JSON files (not summaries).

---

## What Was Reviewed (Ground Truth)

Files reviewed:

- `NQxb_Artifact_Save_v1.json`
- `NQxb_Artifact_Update_v1.json`
- `NQxb_Artifact_Promote_v1.json`

---

## Decisions Locked

### 1) Guard Coverage is WRITE-Only

Guard applies ONLY to:

- `artifact.save`
- `artifact.update`
- `artifact.promote`

Guard does NOT apply to:

- `artifact.query`
- `artifact.list`

### 2) Guard Placement is Correct (All Three Workflows)

Placement is identical across save/update/promote:

- After normalize / validation
- Before any DB write or promote logic

### 3) Fail-Closed Semantics (Verified)

Requests are rejected in all of these cases:

- Missing `artifact_type`
- `artifact_type` not registered in the Type Registry
  - `error.details.reason = "not_registered"`
- `artifact_type` registered but disabled
  - `error.details.reason = "disabled"`

### 4) Canonical Error Envelope (Verified)

All rejections use the same envelope:

- HTTP: **403**
- error.code: **ARTIFACT_TYPE_NOT_ALLOWED**
- error.details.reason: one of:
  - `missing_type`
  - `not_registered`
  - `disabled`

### 5) Regression Check (Verified)

No regressions were detected in existing KGB behavior.

---

## Explicit Non-Goals (Locked)

- No changes to `artifact.query`
- No changes to `artifact.list`
- No expansion of allowed artifact types (registry enforcement only)

---

## Implication

Any future change to this guard behavior requires a versioned override (no silent blending).

— End —$MD_SNAPSHOT$;

    v_restart_markdown := $MD_RESTART$# RESTART — Post KGB-LOCK: Gateway Type Registry Guard (Write Workflows)

**Date:** 2026-01-24 (CST)
**Phase:** Governance close-out complete
**Resume Point:** Next workstream (tests / registry expansion / contract hardening)

---

## Current State (Authoritative)

### What is Completed

Gateway Type Registry Guard is implemented and review-approved for all write workflows:

- `artifact.save`
- `artifact.update`
- `artifact.promote`

Guard behavior is fail-closed and uses canonical error semantics.

### What is Locked

- Enforcement is WRITE-only (save/update/promote).
- `artifact.query` and `artifact.list` are explicitly unchanged.
- Error semantics are stable:
  - HTTP 403
  - `ARTIFACT_TYPE_NOT_ALLOWED`
  - `error.details.reason` differentiates:
    - missing_type
    - not_registered
    - disabled

### What is NOT Done (Intentionally)

- No additional artifact types were added to the registry.
- No contract test pack updates were performed in this step.

---

## Next Action Options

1) Build and run a full Gateway regression test pack (PowerShell + front-end prompts).
2) Expand the Type Registry allow-list for Phase 2 structural types (forest/thicket/flower) under a governed change set.
3) Add additional guards (lineage parent-type validation) after registry expansion is locked.

---

## Notes

This restart exists to prevent archaeology. The workstream is complete; next steps are intentionally separate.

— End —$MD_RESTART$;

    -- ========================================
    -- 1) Insert Parent Project (Gateway Governance)
    -- ========================================

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
        v_project_id,
        v_workspace_id,
        v_owner_user_id,
        'project',
        'Gateway Governance',
        'Parent project for Gateway v1 governance artifacts (snapshots, restarts, KGB locks).',
        3,
        'seed',
        '["project", "gateway_v1", "governance"]'::jsonb,
        '{"kind": "governance_project", "scope": "gateway_v1"}'::jsonb,
        NULL,
        1,
        now(),
        now()
    );

    INSERT INTO public.qxb_artifact_project (
        artifact_id,
        lifecycle_stage,
        operational_state,
        state_reason
    ) VALUES (
        v_project_id,
        'seed',
        'paused',
        'Governance container - not an active workstream'
    );

    -- ========================================
    -- 2) Insert Snapshot Artifact
    -- ========================================

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
        'SNAPSHOT — Gateway Type Registry Guard (KGB-LOCK)',
        'Write-workflow type registry enforcement locked.',
        3,
        'seed',
        '["snapshot", "kgb", "gateway_v1", "type_registry", "guard"]'::jsonb,
        jsonb_build_object(
            'kind', 'gateway_kgb_snapshot',
            'markdown_path', 'docs/qwrk-gateway/KGB_LOCK__Gateway_Type_Registry_Guard__Snapshot__2026-01-24.md'
        ),
        v_project_id,
        1,
        now(),
        now()
    );

    INSERT INTO public.qxb_artifact_snapshot (
        artifact_id,
        payload,
        created_at
    ) VALUES (
        v_snapshot_id,
        jsonb_build_object(
            'document_markdown', v_snapshot_markdown,
            'reviewed_files', jsonb_build_array(
                'NQxb_Artifact_Save_v1.json',
                'NQxb_Artifact_Update_v1.json',
                'NQxb_Artifact_Promote_v1.json'
            ),
            'enforced_actions', jsonb_build_array(
                'artifact.save',
                'artifact.update',
                'artifact.promote'
            ),
            'excluded_actions', jsonb_build_array(
                'artifact.query',
                'artifact.list'
            ),
            'error_code', 'ARTIFACT_TYPE_NOT_ALLOWED',
            'http_status', 403,
            'reasons', jsonb_build_array(
                'missing_type',
                'not_registered',
                'disabled'
            )
        ),
        now()
    );

    -- ========================================
    -- 3) Insert Restart Artifact
    -- ========================================

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
        'RESTART — Gateway Type Registry Guard (Post KGB-LOCK)',
        'Resume after governance close-out.',
        3,
        'seed',
        '["restart", "kgb", "gateway_v1", "type_registry", "guard"]'::jsonb,
        jsonb_build_object(
            'kind', 'gateway_kgb_restart',
            'markdown_path', 'docs/qwrk-gateway/KGB_LOCK__Gateway_Type_Registry_Guard__Restart__2026-01-24.md'
        ),
        v_project_id,
        1,
        now(),
        now()
    );

    INSERT INTO public.qxb_artifact_restart (
        artifact_id,
        payload,
        created_at
    ) VALUES (
        v_restart_id,
        jsonb_build_object(
            'document_markdown', v_restart_markdown,
            'next_actions', jsonb_build_array(
                'Build and run a full Gateway regression test pack (PowerShell + front-end prompts).',
                'Expand the Type Registry allow-list for Phase 2 structural types (forest/thicket/flower) under a governed change set.',
                'Add additional guards (lineage parent-type validation) after registry expansion is locked.'
            ),
            'resume_point', 'Next workstream (tests / registry expansion / contract hardening)'
        ),
        now()
    );

    -- ========================================
    -- Output created IDs
    -- ========================================

    RAISE NOTICE 'Created Gateway Governance Project: %', v_project_id;
    RAISE NOTICE 'Created Snapshot: %', v_snapshot_id;
    RAISE NOTICE 'Created Restart: %', v_restart_id;

END $OUTER$;

-- ============================================================
-- Verification Query (run separately)
-- ============================================================
-- SELECT
--     a.artifact_id,
--     a.artifact_type,
--     a.title,
--     a.parent_artifact_id,
--     a.created_at
-- FROM qxb_artifact a
-- WHERE a.title LIKE '%Gateway%Registry%'
--    OR a.title = 'Gateway Governance'
-- ORDER BY a.created_at DESC;
