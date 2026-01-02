-- ============================================
-- Build Tree Management Pack v1
-- Manual SQL to Save Tree Nodes into Qwrk
-- ============================================
--
-- Tree: build_tree__save_query_list__v1
-- Purpose: Create tree structure for artifact.save workflow validation
-- Total Nodes: 11 (1 root + 4 branches + 4 leaves + 1 test + 1 seed)
--
-- INSTRUCTIONS FOR MASTER JOEL:
-- 1. Replace YOUR_WORKSPACE_UUID with your actual workspace UUID
-- 2. Replace YOUR_USER_UUID with your actual user UUID
-- 3. Execute this file in Supabase SQL Editor or psql
-- 4. Verify all nodes created successfully
-- 5. Follow runbook to execute leaves sequentially
--
-- ============================================

-- ============================================
-- CONFIGURATION (REPLACE THESE VALUES)
-- ============================================

-- Set your workspace and user UUIDs here
\set workspace_id 'YOUR_WORKSPACE_UUID'
\set user_id 'YOUR_USER_UUID'

-- Example:
-- \set workspace_id '12345678-1234-1234-1234-123456789012'
-- \set user_id '87654321-4321-4321-4321-210987654321'

-- ============================================
-- GENERATE UUIDs FOR ALL NODES
-- ============================================

-- Root
\set root_id gen_random_uuid()

-- Branches
\set branch_gateway_id gen_random_uuid()
\set branch_n8n_save_id gen_random_uuid()
\set branch_customgpt_id gen_random_uuid()
\set branch_snapshot_id gen_random_uuid()

-- Leaves
\set leaf_1_id gen_random_uuid()
\set leaf_2_id gen_random_uuid()
\set leaf_3_id gen_random_uuid()
\set leaf_4_id gen_random_uuid()

-- Test
\set test_id gen_random_uuid()

-- Seed
\set seed_id gen_random_uuid()

-- ============================================
-- BEGIN TRANSACTION
-- ============================================

BEGIN;

-- ============================================
-- ROOT NODE
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :root_id,
  :workspace_id,
  'project',
  'root__build_tree__save_query_list__v1',
  'Build Tree: Save Query List v1',
  'active',
  NULL, -- Root has no parent
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'root',
      'status', 'in_progress',
      'sequence', jsonb_build_object(
        'ordinal', 0,
        'next_leaf_slug', 'leaf__create_root_artifact_in_qwrk'
      ),
      'blocked_by', '[]'::jsonb,
      'unblocks', jsonb_build_array(
        'leaf__create_root_artifact_in_qwrk',
        'branch__gateway_v1_1_writes',
        'branch__n8n_save_kgb',
        'branch__customgpt_actions',
        'branch__snapshot_and_mirror'
      ),
      'owner', 'Joel',
      'runbook_refs', jsonb_build_array(
        'docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md'
      ),
      'kgb_refs', '[]'::jsonb,
      'notes', 'Master root node for Save Query List build. First leaf is ready for execution.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary,
  tags
) VALUES (
  :root_id,
  'active',
  'Build Tree for validating artifact.save workflow (Gateway v1.1)',
  ARRAY['build_tree', 'artifact_save', 'gateway_v1_1']
);

-- ============================================
-- BRANCH 1: Gateway v1.1 Writes
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :branch_gateway_id,
  :workspace_id,
  'project',
  'branch__gateway_v1_1_writes',
  'Branch: Gateway v1.1 Writes',
  'active',
  :root_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'branch',
      'status', 'in_progress',
      'sequence', jsonb_build_object(
        'ordinal', NULL,
        'next_leaf_slug', NULL
      ),
      'blocked_by', '[]'::jsonb,
      'unblocks', jsonb_build_array(
        'leaf__create_root_artifact_in_qwrk',
        'leaf__create_branch_nodes_in_qwrk'
      ),
      'owner', 'Joel',
      'runbook_refs', '[]'::jsonb,
      'kgb_refs', '[]'::jsonb,
      'notes', 'Contains leaves for creating tree structure in Qwrk database.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :branch_gateway_id,
  'active',
  'Organizational container for Gateway write operation implementation tasks'
);

-- ============================================
-- BRANCH 2: n8n Save KGB
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :branch_n8n_save_id,
  :workspace_id,
  'project',
  'branch__n8n_save_kgb',
  'Branch: n8n Save KGB',
  'active',
  :root_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'branch',
      'status', 'blocked',
      'sequence', jsonb_build_object(
        'ordinal', NULL,
        'next_leaf_slug', NULL
      ),
      'blocked_by', jsonb_build_array(
        'leaf__create_branch_nodes_in_qwrk'
      ),
      'unblocks', jsonb_build_array(
        'test__kgb_save_query_list_v1'
      ),
      'owner', 'Joel',
      'runbook_refs', '[]'::jsonb,
      'kgb_refs', '[]'::jsonb,
      'notes', 'Contains test node for KGB validation of artifact.save workflow.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :branch_n8n_save_id,
  'active',
  'Organizational container for artifact.save workflow KGB validation'
);

-- ============================================
-- BRANCH 3: CustomGPT Actions
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :branch_customgpt_id,
  :workspace_id,
  'project',
  'branch__customgpt_actions',
  'Branch: CustomGPT Actions',
  'active',
  :root_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'branch',
      'status', 'blocked',
      'sequence', jsonb_build_object(
        'ordinal', NULL,
        'next_leaf_slug', NULL
      ),
      'blocked_by', jsonb_build_array(
        'leaf__create_branch_nodes_in_qwrk'
      ),
      'unblocks', jsonb_build_array(
        'leaf__wire_customgpt_actions_stub_docs'
      ),
      'owner', 'Joel',
      'runbook_refs', '[]'::jsonb,
      'kgb_refs', '[]'::jsonb,
      'notes', 'Contains leaf for wiring CustomGPT actions schema stub documentation.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :branch_customgpt_id,
  'active',
  'Organizational container for CustomGPT integration documentation'
);

-- ============================================
-- BRANCH 4: Snapshot and Mirror
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :branch_snapshot_id,
  :workspace_id,
  'project',
  'branch__snapshot_and_mirror',
  'Branch: Snapshot and Mirror',
  'active',
  :root_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'branch',
      'status', 'blocked',
      'sequence', jsonb_build_object(
        'ordinal', NULL,
        'next_leaf_slug', NULL
      ),
      'blocked_by', jsonb_build_array(
        'leaf__create_branch_nodes_in_qwrk'
      ),
      'unblocks', jsonb_build_array(
        'leaf__plant_upgrade_seed_in_qwrk',
        'seed__upgrade_tree_to_typed_model_v2'
      ),
      'owner', 'Joel',
      'runbook_refs', jsonb_build_array(
        'docs/build_tree/v1/runbooks/Runbook__GitHub_Mirror_Discipline__v1.md'
      ),
      'kgb_refs', '[]'::jsonb,
      'notes', 'Contains leaf for planting v2 upgrade seed and seed node for future typed model migration.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :branch_snapshot_id,
  'active',
  'Organizational container for GitHub mirror setup and future tree upgrade'
);

-- ============================================
-- LEAF 1: Create Root Artifact in Qwrk
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :leaf_1_id,
  :workspace_id,
  'project',
  'leaf__create_root_artifact_in_qwrk',
  'Leaf 1: Create Root Artifact in Qwrk',
  'active',
  :branch_gateway_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'leaf',
      'status', 'ready',
      'sequence', jsonb_build_object(
        'ordinal', 1,
        'next_leaf_slug', 'leaf__create_branch_nodes_in_qwrk'
      ),
      'blocked_by', '[]'::jsonb,
      'unblocks', jsonb_build_array(
        'leaf__create_branch_nodes_in_qwrk'
      ),
      'owner', 'Joel',
      'runbook_refs', jsonb_build_array(
        'docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md#execute-leaf-1'
      ),
      'kgb_refs', '[]'::jsonb,
      'notes', 'First executable leaf. Creates the root artifact in Qwrk database. Run manual SQL from sql/ directory.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :leaf_1_id,
  'active',
  'Create the ROOT node as a PROJECT artifact in Qwrk database'
);

-- ============================================
-- LEAF 2: Create Branch Nodes in Qwrk
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :leaf_2_id,
  :workspace_id,
  'project',
  'leaf__create_branch_nodes_in_qwrk',
  'Leaf 2: Create Branch Nodes in Qwrk',
  'active',
  :branch_gateway_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'leaf',
      'status', 'blocked',
      'sequence', jsonb_build_object(
        'ordinal', 2,
        'next_leaf_slug', 'leaf__plant_upgrade_seed_in_qwrk'
      ),
      'blocked_by', jsonb_build_array(
        'leaf__create_root_artifact_in_qwrk'
      ),
      'unblocks', jsonb_build_array(
        'leaf__plant_upgrade_seed_in_qwrk',
        'leaf__wire_customgpt_actions_stub_docs',
        'test__kgb_save_query_list_v1'
      ),
      'owner', 'Joel',
      'runbook_refs', jsonb_build_array(
        'docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md#execute-leaf-2'
      ),
      'kgb_refs', '[]'::jsonb,
      'notes', 'Second executable leaf. Creates 4 branch nodes (gateway, n8n_save_kgb, customgpt, snapshot_and_mirror).'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :leaf_2_id,
  'active',
  'Create all 4 BRANCH nodes as PROJECT artifacts in Qwrk database'
);

-- ============================================
-- LEAF 3: Plant Upgrade Seed in Qwrk
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :leaf_3_id,
  :workspace_id,
  'project',
  'leaf__plant_upgrade_seed_in_qwrk',
  'Leaf 3: Plant Upgrade Seed in Qwrk',
  'active',
  :branch_snapshot_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'leaf',
      'status', 'blocked',
      'sequence', jsonb_build_object(
        'ordinal', 3,
        'next_leaf_slug', 'leaf__wire_customgpt_actions_stub_docs'
      ),
      'blocked_by', jsonb_build_array(
        'leaf__create_branch_nodes_in_qwrk'
      ),
      'unblocks', jsonb_build_array(
        'leaf__wire_customgpt_actions_stub_docs'
      ),
      'owner', 'Joel',
      'runbook_refs', jsonb_build_array(
        'docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md#execute-leaf-3'
      ),
      'kgb_refs', '[]'::jsonb,
      'notes', 'Third executable leaf. Plants seed node for future tree v2 typed model upgrade.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :leaf_3_id,
  'active',
  'Create SEED node for future v2 tree typed model upgrade'
);

-- ============================================
-- LEAF 4: Wire CustomGPT Actions Stub Docs
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :leaf_4_id,
  :workspace_id,
  'project',
  'leaf__wire_customgpt_actions_stub_docs',
  'Leaf 4: Wire CustomGPT Actions Stub Docs',
  'active',
  :branch_customgpt_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'leaf',
      'status', 'blocked',
      'sequence', jsonb_build_object(
        'ordinal', 4,
        'next_leaf_slug', 'test__kgb_save_query_list_v1'
      ),
      'blocked_by', jsonb_build_array(
        'leaf__plant_upgrade_seed_in_qwrk'
      ),
      'unblocks', jsonb_build_array(
        'test__kgb_save_query_list_v1'
      ),
      'owner', 'Joel',
      'runbook_refs', jsonb_build_array(
        'docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md#execute-leaf-4'
      ),
      'kgb_refs', '[]'::jsonb,
      'notes', 'Fourth executable leaf. Creates CustomGPT actions schema stub documentation.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :leaf_4_id,
  'active',
  'Create documentation stub for CustomGPT actions schema integration'
);

-- ============================================
-- TEST: KGB Save Query List v1
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :test_id,
  :workspace_id,
  'project',
  'test__kgb_save_query_list_v1',
  'TEST: KGB Save Query List v1',
  'active',
  :branch_n8n_save_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'test',
      'status', 'blocked',
      'sequence', jsonb_build_object(
        'ordinal', 5,
        'next_leaf_slug', NULL
      ),
      'blocked_by', jsonb_build_array(
        'leaf__wire_customgpt_actions_stub_docs'
      ),
      'unblocks', '[]'::jsonb,
      'owner', 'Joel',
      'runbook_refs', jsonb_build_array(
        'docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md#execute-test'
      ),
      'kgb_refs', jsonb_build_array(
        'docs/build_tree/v1/kgb/KGB__Save_Query_List__v1.md'
      ),
      'notes', 'Final validation checkpoint. Run KGB tests to ensure artifact.save workflow is production-ready.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :test_id,
  'active',
  'Validate artifact.save workflow against Known-Good Baseline (KGB)'
);

-- ============================================
-- SEED: Upgrade Tree to Typed Model v2
-- ============================================

INSERT INTO qxb_artifact (
  artifact_id,
  workspace_id,
  artifact_type,
  artifact_slug,
  label,
  lifecycle_status,
  parent_artifact_id,
  created_by,
  content
) VALUES (
  :seed_id,
  :workspace_id,
  'project',
  'seed__upgrade_tree_to_typed_model_v2',
  'SEED: Upgrade Tree to Typed Model v2',
  'planned',
  :branch_snapshot_id,
  :user_id,
  jsonb_build_object(
    'tree_node', jsonb_build_object(
      'tree_version', 'v1',
      'tree_slug', 'build_tree__save_query_list__v1',
      'node_kind', 'seed',
      'status', 'planned',
      'sequence', jsonb_build_object(
        'ordinal', NULL,
        'next_leaf_slug', NULL
      ),
      'blocked_by', '[]'::jsonb,
      'unblocks', '[]'::jsonb,
      'owner', 'QP1',
      'runbook_refs', '[]'::jsonb,
      'kgb_refs', '[]'::jsonb,
      'notes', 'Future enhancement: upgrade tree from jsonb fast-now representation to typed model with first-class artifact type. See seeds/ for full migration plan.'
    )
  )
);

INSERT INTO qxb_artifact_project (
  artifact_id,
  lifecycle_stage,
  summary
) VALUES (
  :seed_id,
  'planned',
  'Future enhancement proposal for migrating tree representation from jsonb to first-class artifact type'
);

-- ============================================
-- COMMIT TRANSACTION
-- ============================================

COMMIT;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Count all tree nodes (should be 11)
SELECT COUNT(*) AS total_nodes
FROM qxb_artifact
WHERE content @> '{"tree_node": {"tree_slug": "build_tree__save_query_list__v1"}}';

-- List all tree nodes with status
SELECT
  artifact_slug,
  content->'tree_node'->>'node_kind' AS node_kind,
  content->'tree_node'->>'status' AS status,
  content->'tree_node'->'sequence'->>'ordinal' AS ordinal
FROM qxb_artifact
WHERE content @> '{"tree_node": {"tree_slug": "build_tree__save_query_list__v1"}}'
ORDER BY
  CASE content->'tree_node'->>'node_kind'
    WHEN 'root' THEN 1
    WHEN 'branch' THEN 2
    WHEN 'leaf' THEN 3
    WHEN 'test' THEN 4
    WHEN 'seed' THEN 5
  END,
  (content->'tree_node'->'sequence'->>'ordinal')::INTEGER NULLS LAST;

-- Query root node
SELECT artifact_id, artifact_slug, label, content->'tree_node' AS tree_node
FROM qxb_artifact
WHERE artifact_slug = 'root__build_tree__save_query_list__v1';

-- ============================================
-- NEXT STEPS
-- ============================================

-- 1. Verify total_nodes = 11
-- 2. Verify Leaf 1 status = 'ready'
-- 3. Verify all other leaves status = 'blocked'
-- 4. Follow runbook: docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md
-- 5. Execute Leaf 1, mark DONE, unblock Leaf 2
-- 6. Continue sequential execution through Leaf 4
-- 7. Run KGB tests
-- 8. Mark TEST as DONE
-- 9. Mark ROOT as DONE
-- 10. Commit to GitHub

-- ============================================
-- END OF FILE
-- ============================================
