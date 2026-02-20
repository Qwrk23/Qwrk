-- ============================================================
-- Snapshot: Full Access Enablement Restart Prompt
-- Created: 2026-01-24
-- Type: snapshot (governance/restart prompt)
-- Artifact ID: 3f6822bf-eeb8-43f8-8215-397724610c3d
-- ============================================================
--
-- Schema notes (qxb_artifact):
--   - owner_user_id: required, must exist in qxb_user
--   - priority: constraint CHECK ((priority >= 1) AND (priority <= 5))
--
-- Schema notes (qxb_artifact_snapshot):
--   - artifact_id: FK to qxb_artifact
--   - payload: jsonb NOT NULL
--   - created_at: auto-generated
--   - NO workspace_id column
-- ============================================================

WITH workspace_owner AS (
    SELECT u.user_id
    FROM qxb_workspace_user wsu
    JOIN qxb_user u ON u.user_id = wsu.user_id
    WHERE wsu.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
      AND wsu.role = 'owner'
    LIMIT 1
),
new_artifact AS (
    INSERT INTO qxb_artifact (
        workspace_id,
        artifact_type,
        title,
        summary,
        lifecycle_status,
        owner_user_id,
        priority,
        tags
    )
    SELECT
        'be0d3a48-c764-44f9-90c8-e846d9dbbd0a',
        'snapshot',
        'Full Access Enablement — Restart Prompt',
        'Restart prompt for enabling full access (read + write) capabilities in Qwrk GPT front-end. Covers schema v2.0.0-dev, instructions v1, verification tasks, and deployment checklist.',
        'tree',
        wo.user_id,
        5,
        '{"type": "governance", "category": "restart_prompt", "version": "v1", "status": "pending"}'::jsonb
    FROM workspace_owner wo
    RETURNING artifact_id
)
INSERT INTO qxb_artifact_snapshot (artifact_id, payload)
SELECT
    artifact_id,
    '{
        "snapshot_type": "governance_restart_prompt",
        "snapshot_version": "v1",
        "created": "2026-01-24",
        "status": "pending",
        "prerequisites": ["Gateway Workflow Fixes", "Test harness 37/37 PASSED"],
        "scope": {
            "actions": ["artifact.list", "artifact.query", "artifact.save", "artifact.update", "artifact.promote"],
            "types": ["project", "journal", "restart", "snapshot"]
        },
        "files": {
            "schema": "docs/qwrk-instructions/Qwrk_Gateway_v1_Actions_Schema.yaml (v2.0.0-dev)",
            "instructions": "docs/qwrk-instructions/Qwrk_Full_Access_MVP_Instructions_v1.md",
            "restart_prompt": "docs/qwrk-instructions/Full_Access_Enablement__Restart_Prompt.md"
        },
        "tasks_pending": 6,
        "mutability": {
            "project": "partial (operational_state, state_reason only)",
            "journal": "immutable",
            "restart": "immutable",
            "snapshot": "immutable"
        }
    }'::jsonb
FROM new_artifact
RETURNING artifact_id, created_at;

-- ============================================================
-- EXECUTED: 2026-01-24 22:51:20.623801+00
-- RESULT: artifact_id = 3f6822bf-eeb8-43f8-8215-397724610c3d
-- ============================================================
