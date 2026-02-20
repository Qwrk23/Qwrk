-- ============================================================
-- Snapshot: Deterministic Save → Promote → Query KGB
-- Created: 2026-01-24
-- Type: snapshot / kgb / governance
-- Parent Project: 8111bff3-16f6-4381-943f-f451b7536715
-- ============================================================

DO $$
DECLARE
    v_snapshot_id uuid := gen_random_uuid();
BEGIN
    -- Insert spine record
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
        'be0d3a48-c764-44f9-90c8-e846d9dbbd0a',
        'c52c7a57-74ad-433d-a07c-4dcac1778672',
        'snapshot',
        'Snapshot — Deterministic Save→Promote→Query KGB (2026-01-24)',
        'KGB proof: artifact.save→promote→query flow verified end-to-end with DB-confirmed lifecycle transition seed→sapling.',
        3,
        'seed',
        '["snapshot", "kgb", "gateway", "promote", "query"]'::jsonb,
        '{}'::jsonb,
        '8111bff3-16f6-4381-943f-f451b7536715',
        1,
        now(),
        now()
    );

    -- Insert extension record
    INSERT INTO public.qxb_artifact_snapshot (
        artifact_id,
        payload,
        created_at
    ) VALUES (
        v_snapshot_id,
        '{
            "snapshot_type": "kgb_decision_seam",
            "snapshot_version": "v1",
            "created": "2026-01-24",
            "objective": "Establish Known-Good Baseline for deterministic artifact.save → artifact.promote → artifact.query flow",
            "decisions_locked": [
                {"decision": "Gateway call_save must point to active Save workflow", "status": "LOCKED"},
                {"decision": "artifact.save returns artifact_id in response envelope", "status": "LOCKED"},
                {"decision": "artifact.promote requires transition at TOP-LEVEL", "status": "LOCKED"},
                {"decision": "artifact.promote requires reason at TOP-LEVEL", "status": "LOCKED"},
                {"decision": "artifact.query requires artifact_type", "status": "LOCKED"},
                {"decision": "Lifecycle event captures from_state and to_state", "status": "LOCKED"}
            ],
            "open_questions": [
                {"question": "Should Gateway normalize transition from nested to top-level?", "status": "OPEN"},
                {"question": "Should artifact.query infer artifact_type from artifact_id?", "status": "OPEN"}
            ],
            "validator_expectations": {
                "artifact_save": {
                    "required_top_level": ["gw_action", "artifact_type", "title"],
                    "optional_top_level": ["gw_workspace_id", "summary", "extension"],
                    "extension_for_project": ["lifecycle_stage"]
                },
                "artifact_promote": {
                    "required_top_level": ["gw_action", "artifact_type", "artifact_id", "transition", "reason"],
                    "critical_note": "transition and reason must be TOP-LEVEL, not nested under artifact_payload"
                },
                "artifact_query": {
                    "required_top_level": ["gw_action", "artifact_type", "artifact_id"],
                    "critical_note": "artifact_type is REQUIRED, validation rejects without it"
                }
            },
            "receipts": {
                "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
                "project_artifact_id": "8111bff3-16f6-4381-943f-f451b7536715",
                "promote_event_id": "a590e518-051a-4f9d-a352-b83248a90a99",
                "transition_executed": "seed_to_sapling",
                "final_lifecycle_status": "sapling",
                "db_confirmed": true
            },
            "operational_fix": {
                "root_cause": "Gateway call_save node pointed to deactivated/old Save workflow",
                "fix_applied": "Repointed call_save to correct active NQxb_Artifact_Save_v1 workflow",
                "affected_workflow": "NQxb_Gateway_v1",
                "affected_node": "Call NQxb_Artifact_Save_v1",
                "n8n_workflow_id": "D1NWfUWZ9IFDVqNB"
            },
            "next_actions": [
                "Update test harness with KGB payloads as regression tests",
                "Document Gateway contract: formalize top-level transition/reason requirement in schema"
            ]
        }'::jsonb,
        now()
    );

    RAISE NOTICE 'Snapshot created: %', v_snapshot_id;
END $$;

-- Query to verify (run separately after DO block)
-- SELECT artifact_id, title, lifecycle_status, created_at
-- FROM qxb_artifact
-- WHERE artifact_type = 'snapshot'
-- ORDER BY created_at DESC LIMIT 1;
