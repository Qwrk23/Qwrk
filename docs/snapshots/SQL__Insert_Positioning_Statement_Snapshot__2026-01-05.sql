-- Insert Qwrk Positioning Statement Snapshot into Qwrk's Brain (QB)
-- Date: 2026-01-05
-- Owner: Master Joel
-- Artifact Type: snapshot
-- Purpose: Canonical positioning statement as single source of truth for all Qwrk messaging

-- Single transaction with CTE to handle both inserts atomically
WITH new_artifact AS (
    -- Insert into qxb_artifact (spine table)
    INSERT INTO qxb_artifact (
        workspace_id,
        owner_user_id,
        artifact_type,
        title,
        summary,
        lifecycle_status,
        tags,
        version
    ) VALUES (
        'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid,  -- workspace_id (Master Joel Workspace from KGB)
        'c52c7a57-74ad-433d-a07c-4dcac1778672'::uuid,  -- owner_user_id (Master Joel from KGB)
        'snapshot',  -- artifact_type
        'Snapshot — Qwrk Positioning Statement (Canonical v1) — 2026-01-05',  -- title
        'Canonical positioning statement: "A conversationally driven, lifecycle-aware, agent-capable operating environment for human intent." Single source of truth for all Qwrk messaging, marketing, and derivation per Rule 7.5.',  -- summary
        'active',  -- lifecycle_status
        '["positioning", "canonical", "messaging", "marketing", "locked", "rule-7.5"]'::jsonb,  -- tags
        1  -- version
    )
    RETURNING artifact_id
)
-- Insert into qxb_artifact_snapshot (extension table) using the new artifact_id
INSERT INTO qxb_artifact_snapshot (
    artifact_id,
    payload
)
SELECT
    artifact_id,
    '{
        "core_statement": "A conversationally driven, lifecycle-aware, agent-capable operating environment for human intent.",
        "version": "v1",
        "locked_date": "2026-01-05",
        "stage": "crawl",
        "file_reference": "docs/snapshots/AAA_New_Qwrk__Snapshot__Positioning_Statement_Canonical_v1__2026-01-05.md",
        "canonical_doc": "docs/architecture/Qwrk_Positioning_Statement__Canonical__v1.md",
        "capabilities": {
            "conversationally_driven": "Natural language is the primary interface for all interactions",
            "lifecycle_aware": "Artifacts have lifecycle stages, context persists across sessions",
            "agent_capable": "Supports autonomous execution within governed rails with approval gates",
            "operating_environment": "Infrastructure for human intent, workspace-first, not an app"
        },
        "non_capabilities": {
            "not_chatbot": "Stateful workspace-aware operating environment, not Q&A interface",
            "not_task_manager": "Environment for executing intent, not just tracking",
            "not_code_editor": "Can manage code artifacts but is not IDE-replacement",
            "not_autonomous": "Agents require approval for state changes, human oversight built-in",
            "not_production_ready": "Crawl stage foundational infrastructure, MVP-level features"
        },
        "demo_safety": "demo-partial",
        "demo_safe_elements": ["conversational_interface", "lifecycle_concepts", "approval_gates", "explainability"],
        "demo_unsafe_elements": ["n8n_internals", "database_schema", "rls_policies", "gateway_json"],
        "derivation_targets": ["marketing", "user_guides", "sales_copy", "demo_scripts"],
        "governance_rule": "Rule 7.5 - Documentation & Derivation Contract (GLOBAL)",
        "conflict_resolution": "Canonical documentation wins, derived outputs must be regenerated"
    }'::jsonb
FROM new_artifact
RETURNING artifact_id;

-- The RETURNING clause will output the artifact_id after successful execution
-- Save this artifact_id for governance records
