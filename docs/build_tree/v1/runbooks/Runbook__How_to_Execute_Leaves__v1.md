# Runbook — How to Execute Leaves v1

**Step-by-step execution guide for Build Tree leaf nodes**

---

## Purpose

This runbook provides detailed instructions for executing leaf nodes in the Build Tree. Each leaf represents an executable work unit that must be completed in sequential order.

**Tree**: `build_tree__save_query_list__v1`

**Owner**: Master Joel (with Claude Code assistance)

---

## Prerequisites

Before executing any leaf:

1. **Verify leaf status is READY**
   - Query the leaf artifact from Qwrk
   - Check `content.tree_node.status === "ready"`
   - If status is "blocked", check `blocked_by` dependencies

2. **Review leaf definition**
   - Read the leaf's `notes` field
   - Check `runbook_refs` for specific instructions
   - Understand `unblocks` targets

3. **Prepare execution environment**
   - Supabase project: `npymhacpmxdnkdgzxll`
   - SQL client connected (psql, Supabase Studio, or n8n)
   - Manual SQL file available: `sql/manual_save_build_tree_v1.sql`

---

## General Execution Flow

For each leaf:

```
1. Mark leaf as IN_PROGRESS
2. Execute leaf instructions
3. Verify completion
4. Mark leaf as DONE
5. Unblock dependent leaves (update their status to READY)
6. Proceed to next leaf
```

---

## Leaf 1: Create Root Artifact in Qwrk {#execute-leaf-1}

**Slug**: `leaf__create_root_artifact_in_qwrk`

**Status**: ✅ READY

**Purpose**: Create the ROOT node as a PROJECT artifact in Qwrk database

### Step 1: Mark Leaf as IN_PROGRESS

Update the leaf's status in Qwrk:

```sql
-- Execute via n8n artifact.update or direct SQL
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"in_progress"'
)
WHERE artifact_slug = 'leaf__create_root_artifact_in_qwrk';
```

### Step 2: Execute Root Node Creation

Run the SQL from `manual_save_build_tree_v1.sql` for the root node:

```sql
-- This will be in the manual SQL file
-- Creates ROOT node with:
-- - artifact_type: 'project'
-- - artifact_slug: 'root__build_tree__save_query_list__v1'
-- - content.tree_node: { ... root structure ... }
```

### Step 3: Verify Root Node Created

Query the root artifact:

```sql
SELECT artifact_id, artifact_slug, artifact_type, content->'tree_node' AS tree_node
FROM qxb_artifact
WHERE artifact_slug = 'root__build_tree__save_query_list__v1';
```

**Expected Result**:
- artifact_id is a valid UUID
- artifact_type = 'project'
- content.tree_node.node_kind = 'root'
- content.tree_node.status = 'in_progress'

### Step 4: Mark Leaf 1 as DONE

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"done"'
)
WHERE artifact_slug = 'leaf__create_root_artifact_in_qwrk';
```

### Step 5: Unblock Leaf 2

Update Leaf 2 status to READY:

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"ready"'
)
WHERE artifact_slug = 'leaf__create_branch_nodes_in_qwrk';
```

### Completion Criteria

- ✅ Root artifact exists in Qxb_Artifact
- ✅ Root artifact has valid tree_node structure
- ✅ Leaf 1 status = "done"
- ✅ Leaf 2 status = "ready"

---

## Leaf 2: Create Branch Nodes in Qwrk {#execute-leaf-2}

**Slug**: `leaf__create_branch_nodes_in_qwrk`

**Status**: 🔒 BLOCKED (becomes READY after Leaf 1)

**Purpose**: Create all 4 BRANCH nodes as PROJECT artifacts in Qwrk database

### Step 1: Verify Leaf 2 is READY

```sql
SELECT content->'tree_node'->>'status' AS status
FROM qxb_artifact
WHERE artifact_slug = 'leaf__create_branch_nodes_in_qwrk';
```

**Expected**: status = "ready"

### Step 2: Mark Leaf 2 as IN_PROGRESS

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"in_progress"'
)
WHERE artifact_slug = 'leaf__create_branch_nodes_in_qwrk';
```

### Step 3: Execute Branch Node Creation

Run the SQL from `manual_save_build_tree_v1.sql` for all 4 branch nodes:

```sql
-- Creates 4 BRANCH nodes:
-- 1. branch__gateway_v1_1_writes
-- 2. branch__n8n_save_kgb
-- 3. branch__customgpt_actions
-- 4. branch__snapshot_and_mirror
```

### Step 4: Verify All Branch Nodes Created

```sql
SELECT artifact_id, artifact_slug, content->'tree_node'->>'node_kind' AS node_kind
FROM qxb_artifact
WHERE artifact_slug IN (
  'branch__gateway_v1_1_writes',
  'branch__n8n_save_kgb',
  'branch__customgpt_actions',
  'branch__snapshot_and_mirror'
);
```

**Expected Result**: 4 rows returned, all with node_kind = 'branch'

### Step 5: Mark Leaf 2 as DONE

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"done"'
)
WHERE artifact_slug = 'leaf__create_branch_nodes_in_qwrk';
```

### Step 6: Unblock Dependent Leaves

Update Leaf 3, Leaf 4, and TEST to READY:

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"ready"'
)
WHERE artifact_slug IN (
  'leaf__plant_upgrade_seed_in_qwrk',
  'leaf__wire_customgpt_actions_stub_docs',
  'test__kgb_save_query_list_v1'
);
```

### Completion Criteria

- ✅ All 4 branch artifacts exist in Qxb_Artifact
- ✅ Each branch has valid tree_node structure
- ✅ Leaf 2 status = "done"
- ✅ Leaf 3, Leaf 4, TEST status = "ready"

---

## Leaf 3: Plant Upgrade Seed in Qwrk {#execute-leaf-3}

**Slug**: `leaf__plant_upgrade_seed_in_qwrk`

**Status**: 🔒 BLOCKED (becomes READY after Leaf 2)

**Purpose**: Create SEED node for future v2 tree typed model upgrade

### Step 1: Verify Leaf 3 is READY

```sql
SELECT content->'tree_node'->>'status' AS status
FROM qxb_artifact
WHERE artifact_slug = 'leaf__plant_upgrade_seed_in_qwrk';
```

**Expected**: status = "ready"

### Step 2: Mark Leaf 3 as IN_PROGRESS

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"in_progress"'
)
WHERE artifact_slug = 'leaf__plant_upgrade_seed_in_qwrk';
```

### Step 3: Execute Seed Node Creation

Run the SQL from `manual_save_build_tree_v1.sql` for the seed node:

```sql
-- Creates SEED node:
-- - artifact_slug: 'seed__upgrade_tree_to_typed_model_v2'
-- - parent_artifact_id: points to branch__snapshot_and_mirror
```

### Step 4: Verify Seed Node Created

```sql
SELECT artifact_id, artifact_slug, content->'tree_node'->>'node_kind' AS node_kind
FROM qxb_artifact
WHERE artifact_slug = 'seed__upgrade_tree_to_typed_model_v2';
```

**Expected Result**: 1 row with node_kind = 'seed'

### Step 5: Mark Leaf 3 as DONE

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"done"'
)
WHERE artifact_slug = 'leaf__plant_upgrade_seed_in_qwrk';
```

### Step 6: Leaf 4 Already Unblocked

No additional unblocking needed (Leaf 2 already unblocked Leaf 4).

### Completion Criteria

- ✅ Seed artifact exists in Qxb_Artifact
- ✅ Seed has valid tree_node structure
- ✅ Seed parent_artifact_id points to branch__snapshot_and_mirror
- ✅ Leaf 3 status = "done"

---

## Leaf 4: Wire CustomGPT Actions Stub Docs {#execute-leaf-4}

**Slug**: `leaf__wire_customgpt_actions_stub_docs`

**Status**: 🔒 BLOCKED (becomes READY after Leaf 2)

**Purpose**: Create documentation stub for CustomGPT actions schema integration

### Step 1: Verify Leaf 4 is READY

```sql
SELECT content->'tree_node'->>'status' AS status
FROM qxb_artifact
WHERE artifact_slug = 'leaf__wire_customgpt_actions_stub_docs';
```

**Expected**: status = "ready" (unblocked by Leaf 2)

### Step 2: Mark Leaf 4 as IN_PROGRESS

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"in_progress"'
)
WHERE artifact_slug = 'leaf__wire_customgpt_actions_stub_docs';
```

### Step 3: Create CustomGPT Actions Stub

This is a documentation task (not SQL):

1. Create placeholder file: `docs/integrations/CustomGPT_Actions_Schema__v1.md`
2. Add stub content referencing Gateway v1 actions
3. Wire reference into CustomGPT configuration (if applicable)

**Stub Content Template**:
```markdown
# CustomGPT Actions Schema v1

**Gateway v1 Integration**

## Available Actions

- artifact.query
- artifact.list
- artifact.create
- artifact.update
- artifact.promote (planned)

See [Gateway README](../../workflows/README.md) for full API contract.
```

### Step 4: Verify Stub Created

Check file exists in repository:
```bash
ls docs/integrations/CustomGPT_Actions_Schema__v1.md
```

### Step 5: Commit to GitHub Mirror

```bash
git add docs/integrations/CustomGPT_Actions_Schema__v1.md
git commit -m "Add CustomGPT actions schema stub

🤖 Generated with Claude Code
Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push origin main
```

### Step 6: Mark Leaf 4 as DONE

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"done"'
)
WHERE artifact_slug = 'leaf__wire_customgpt_actions_stub_docs';
```

### Step 7: TEST Already Unblocked

No additional unblocking needed (Leaf 2 already unblocked TEST).

### Completion Criteria

- ✅ CustomGPT stub documentation file created
- ✅ File committed to GitHub mirror
- ✅ Leaf 4 status = "done"
- ✅ TEST remains READY

---

## TEST: KGB Save Query List v1 {#execute-test}

**Slug**: `test__kgb_save_query_list_v1`

**Status**: 🔒 BLOCKED (becomes READY after Leaf 2)

**Purpose**: Validate artifact.save workflow against Known-Good Baseline (KGB)

### Step 1: Verify TEST is READY

```sql
SELECT content->'tree_node'->>'status' AS status
FROM qxb_artifact
WHERE artifact_slug = 'test__kgb_save_query_list_v1';
```

**Expected**: status = "ready" (unblocked by Leaf 2)

### Step 2: Mark TEST as IN_PROGRESS

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"in_progress"'
)
WHERE artifact_slug = 'test__kgb_save_query_list_v1';
```

### Step 3: Execute KGB Test Cases

Run all test cases from `kgb/KGB__Save_Query_List__v1.md`:

1. **Test Case 1**: Create new project artifact via artifact.save
2. **Test Case 2**: Update existing project artifact via artifact.save
3. **Test Case 3**: Validate type-specific schema enforcement
4. **Test Case 4**: Verify response envelope structure
5. **Test Case 5**: Test error handling (missing fields, invalid types)

### Step 4: Verify All Tests PASS

**Acceptance Criteria**:
- ✅ All 5 test cases pass
- ✅ No unexpected errors in workflow execution
- ✅ Response envelopes match contract
- ✅ Database state is consistent

### Step 5: Mark TEST as DONE

If all tests pass:

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"done"'
)
WHERE artifact_slug = 'test__kgb_save_query_list_v1';
```

### Step 6: Mark Root as DONE

All leaves complete, mark root as done:

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"done"'
)
WHERE artifact_slug = 'root__build_tree__save_query_list__v1';
```

### Completion Criteria

- ✅ All KGB test cases pass
- ✅ TEST status = "done"
- ✅ ROOT status = "done"
- ✅ Build Tree execution complete

---

## Status Update Patterns

### Manual SQL Update (Direct)

```sql
UPDATE qxb_artifact
SET content = jsonb_set(
  content,
  '{tree_node,status}',
  '"<new_status>"'
)
WHERE artifact_slug = '<leaf_slug>';
```

### Via Gateway (artifact.update)

```json
{
  "gw_user_id": "your-user-uuid",
  "gw_workspace_id": "your-workspace-uuid",
  "gw_action": "artifact.update",
  "artifact_id": "leaf-artifact-uuid",
  "artifact_type": "project",
  "artifact_payload": {
    "content": {
      "tree_node": {
        "status": "in_progress"
      }
    }
  }
}
```

---

## Troubleshooting

### Leaf Won't Unblock

**Problem**: Dependent leaf remains "blocked" after prerequisite is "done"

**Solution**:
1. Verify prerequisite leaf status is actually "done"
2. Check `blocked_by` array in dependent leaf
3. Manually update dependent leaf status to "ready"

### SQL Execution Fails

**Problem**: Manual SQL INSERT fails with constraint violation

**Solution**:
1. Check workspace_id matches your Supabase workspace
2. Verify parent_artifact_id exists (for branch/leaf/seed nodes)
3. Ensure artifact_slug is unique

### TEST Fails

**Problem**: KGB test cases fail during TEST execution

**Solution**:
1. Review specific failing test case
2. Check artifact.save workflow for errors
3. Verify Supabase RLS policies are active
4. Re-execute failing test in isolation
5. Fix workflow, re-run full KGB suite

---

## Best Practices

1. **One leaf at a time**: Complete each leaf fully before starting the next
2. **Verify before proceeding**: Always check completion criteria
3. **Document anomalies**: Add notes to leaf if unexpected behavior occurs
4. **Commit frequently**: Push changes to GitHub mirror after each leaf
5. **Test early**: Run KGB tests incrementally, not just at the end

---

## References

- [Build Tree Documentation](../tree/Build_Tree__Save_Query_List__v1.md)
- [TreeNode Schema](../tree/TreeNode_Schema__content.tree_node__v1.md)
- [KGB Test Cases](../kgb/KGB__Save_Query_List__v1.md)
- [GitHub Mirror Discipline](Runbook__GitHub_Mirror_Discipline__v1.md)
- [Manual SQL File](../../sql/manual_save_build_tree_v1.sql)

---

**Version**: v1
**Status**: Active
**Last Updated**: 2026-01-02
