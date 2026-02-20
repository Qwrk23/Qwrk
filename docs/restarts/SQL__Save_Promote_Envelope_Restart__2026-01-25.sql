-- =============================================================================
-- SQL to Save Restart Artifact: Promote Workflow Success Envelope Fix
-- Date: 2026-01-25
-- Schema: Spine (qxb_artifact) + Extension (qxb_artifact_restart)
-- Status: EXECUTED SUCCESSFULLY
-- Artifact ID: 427fefef-acb2-4774-99be-b62426d03fc4
-- =============================================================================

-- Qwrk uses spine + extension pattern:
--   qxb_artifact (spine) - common fields for all artifact types
--   qxb_artifact_restart (extension) - restart-specific payload

DO $$
DECLARE
    v_artifact_id uuid := gen_random_uuid();
BEGIN
    -- Insert into spine table
    INSERT INTO qxb_artifact (
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
        v_artifact_id,
        'be0d3a48-c764-44f9-90c8-e846d9dbbd0a',
        'c52c7a57-74ad-433d-a07c-4dcac1778672',
        'restart',
        'RESTART — Promote Workflow Success Envelope Fix (P1/P2)',
        'Make Promote success responses contract-consistent by returning ok:true, so clients, test harness, and Qwrk front-end can reliably detect success.',
        2,
        'seed',
        '{"gateway": true, "workflow": true, "promote": true, "envelope": true}'::jsonb,
        '{"generated_by": "claude_code", "file_path": "docs/restarts/Restart__Promote_Workflow_Success_Envelope_Fix__2026-01-25.md"}'::jsonb,
        NULL,
        1,
        NOW(),
        NOW()
    );

    -- Insert into extension table
    INSERT INTO qxb_artifact_restart (
        artifact_id,
        payload,
        created_at
    ) VALUES (
        v_artifact_id,
        '{
            "restart_type": "workflow_fix",
            "target_workflow": "NQxb_Artifact_Promote_v1",
            "root_cause": "Promote success response missing ok:true field",
            "affected_tests": ["P1", "P2"],
            "fix_summary": "Wrap Promote success return with canonical envelope including ok:true",
            "blocking": "qwrk_alpha",
            "status": "pending"
        }'::jsonb,
        NOW()
    );

    RAISE NOTICE 'Created restart artifact: %', v_artifact_id;
END $$;

-- =============================================================================
-- Verification Query
-- =============================================================================

SELECT
    a.artifact_id,
    a.title,
    a.lifecycle_status,
    r.payload->>'target_workflow' as target_workflow,
    r.payload->>'status' as restart_status,
    a.created_at
FROM qxb_artifact a
JOIN qxb_artifact_restart r ON a.artifact_id = r.artifact_id
WHERE a.artifact_type = 'restart'
  AND a.title ILIKE '%Promote%Envelope%'
ORDER BY a.created_at DESC
LIMIT 1;

-- =============================================================================
-- Result (2026-01-25):
-- artifact_id: 427fefef-acb2-4774-99be-b62426d03fc4
-- title: RESTART — Promote Workflow Success Envelope Fix (P1/P2)
-- lifecycle_status: seed
-- target_workflow: NQxb_Artifact_Promote_v1
-- restart_status: pending
-- created_at: 2026-01-25 21:47:44.973615+00
-- =============================================================================
