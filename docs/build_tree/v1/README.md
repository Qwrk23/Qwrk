# Build Tree Management Pack v1

**Tree-based execution management system for New Qwrk front-end builds**

---

## ⚠️ CANONICAL TRUTH DECLARATION

**This is the canonical Build Tree for the slug `build_tree__save_query_list__v1`.**

- **Supersedes**: All previous planning documents in AAA_New_Qwrk/Qwrk Build Tree Pack for CC/
- **Authority**: This version is stored as PROJECT artifacts in Qwrk database (content.tree_node jsonb)
- **Locked**: 2026-01-02
- **Changes**: Must follow governance rules in [CLAUDE.md](../../../CLAUDE.md)

**If you find conflicting documentation with this tree slug, this version wins.**

See: [Tree Registry](../TREE_REGISTRY.md) for all active trees.

---

## Overview

The Build Tree Management Pack provides a structured approach to managing complex, multi-step front-end builds using tree-based execution management.

**Key Concept**: Use PROJECT artifacts with `content.tree_node` jsonb field to encode tree semantics without creating new tables (v1 "fast now" strategy).

---

## Quick Start

### For Master Joel

1. **Review the tree structure**: [Build_Tree__Save_Query_List__v1.md](tree/Build_Tree__Save_Query_List__v1.md)
2. **Run the manual SQL**: Execute `sql/manual_save_build_tree_v1.sql` in Supabase
3. **Follow the runbook**: [Runbook__How_to_Execute_Leaves__v1.md](runbooks/Runbook__How_to_Execute_Leaves__v1.md)
4. **Execute leaves sequentially**: Leaf 1 → Leaf 2 → Leaf 3 → Leaf 4 → TEST
5. **Validate with KGB**: Run tests from [KGB__Save_Query_List__v1.md](kgb/KGB__Save_Query_List__v1.md)

### For Future Trees

1. **Copy templates**: Use [Leaf_Template__v1.md](templates/Leaf_Template__v1.md) and [Branch_Template__v1.md](templates/Branch_Template__v1.md)
2. **Define tree structure**: Create tree documentation showing ROOT, BRANCHES, LEAVES, TEST, SEED
3. **Generate manual SQL**: Create INSERT statements for all nodes
4. **Create runbook**: Document execution steps for each leaf
5. **Plant seed**: Add upgrade path documentation in seeds/

---

## Directory Structure

```
docs/build_tree/v1/
├── tree/                      # Tree structure definitions
│   ├── TreeNode_Schema__content.tree_node__v1.md
│   └── Build_Tree__Save_Query_List__v1.md
├── runbooks/                  # Execution guides
│   ├── Runbook__How_to_Execute_Leaves__v1.md
│   └── Runbook__GitHub_Mirror_Discipline__v1.md
├── kgb/                       # Known-Good Baseline tests
│   └── KGB__Save_Query_List__v1.md
├── templates/                 # Templates for creating new nodes
│   ├── Leaf_Template__v1.md
│   └── Branch_Template__v1.md
├── seeds/                     # Future enhancement proposals
│   └── Seed__Upgrade_Tree_to_Typed_Model__v2.md
└── README.md                  # This file

sql/
└── manual_save_build_tree_v1.sql  # Manual SQL to save tree into Qwrk
```

---

## Tree Management Concepts

### Node Types

| Node Kind | Purpose | Executable |
|-----------|---------|-----------|
| **root** | Single master node per tree | No |
| **branch** | Organizational grouping | No |
| **leaf** | Executable work unit | Yes |
| **gate** | Decision/approval point | Yes |
| **test** | Validation checkpoint | Yes |
| **seed** | Future enhancement proposal | No |

### Status States

| Status | Meaning | Transitions To |
|--------|---------|---------------|
| **planned** | Defined but not ready | ready (when unblocked) |
| **ready** | No blockers, can execute | in_progress (when started) |
| **in_progress** | Currently being worked | done (when completed) |
| **blocked** | Has unmet dependencies | ready (when dependencies done) |
| **done** | Completed successfully | - |

### Dependency Management

- **blocked_by**: Array of prerequisite node slugs
- **unblocks**: Array of dependent node slugs (inverse of blocked_by)
- **sequence**: Linear execution order for leaves (ordinal + next_leaf_slug)

**Example**:
```json
{
  "blocked_by": ["leaf__create_root_artifact_in_qwrk"],
  "unblocks": ["leaf__plant_upgrade_seed_in_qwrk"],
  "sequence": {
    "ordinal": 2,
    "next_leaf_slug": "leaf__plant_upgrade_seed_in_qwrk"
  }
}
```

---

## Current Trees

### Build Tree: Save Query List v1

**Purpose**: Validate artifact.save workflow for Gateway v1.1

**Tree Slug**: `build_tree__save_query_list__v1`

**Structure**:
- 1 ROOT node
- 4 BRANCH nodes
- 4 LEAF nodes (sequential execution)
- 1 TEST node
- 1 SEED node

**Status**: Active (Leaf 1 ready for execution)

**Documentation**: [Build_Tree__Save_Query_List__v1.md](tree/Build_Tree__Save_Query_List__v1.md)

---

## Execution Workflow

### Step 1: Plant the Tree

Run manual SQL to create all tree nodes in Qwrk:

```bash
psql -h npymhacpmxdnkdgzxll.supabase.co \
     -U postgres \
     -d postgres \
     -f sql/manual_save_build_tree_v1.sql
```

Or use Supabase Studio SQL Editor to execute the file contents.

### Step 2: Verify Tree Created

Query root node:

```sql
SELECT artifact_id, artifact_slug, content->'tree_node' AS tree_node
FROM qxb_artifact
WHERE artifact_slug = 'root__build_tree__save_query_list__v1';
```

### Step 3: Execute Leaves Sequentially

Follow the runbook: [Runbook__How_to_Execute_Leaves__v1.md](runbooks/Runbook__How_to_Execute_Leaves__v1.md)

1. Execute Leaf 1 → mark DONE → unblock Leaf 2
2. Execute Leaf 2 → mark DONE → unblock Leaf 3, Leaf 4, TEST
3. Execute Leaf 3 → mark DONE
4. Execute Leaf 4 → mark DONE
5. Execute TEST → validate KGB → mark DONE
6. Mark ROOT as DONE

### Step 4: Validate with KGB

Run all test cases from: [KGB__Save_Query_List__v1.md](kgb/KGB__Save_Query_List__v1.md)

### Step 5: Commit to GitHub

Follow GitHub mirror discipline: [Runbook__GitHub_Mirror_Discipline__v1.md](runbooks/Runbook__GitHub_Mirror_Discipline__v1.md)

```bash
git add .
git commit -m "Complete Build Tree: Save Query List v1

All leaves executed, KGB tests passed, tree marked as done.

🤖 Generated with Claude Code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push origin main
```

---

## File Reference

### Core Documentation

| File | Purpose |
|------|---------|
| [TreeNode_Schema__content.tree_node__v1.md](tree/TreeNode_Schema__content.tree_node__v1.md) | Schema definition for tree_node jsonb field |
| [Build_Tree__Save_Query_List__v1.md](tree/Build_Tree__Save_Query_List__v1.md) | Complete tree structure and node definitions |

### Runbooks

| File | Purpose |
|------|---------|
| [Runbook__How_to_Execute_Leaves__v1.md](runbooks/Runbook__How_to_Execute_Leaves__v1.md) | Step-by-step execution guide for leaves |
| [Runbook__GitHub_Mirror_Discipline__v1.md](runbooks/Runbook__GitHub_Mirror_Discipline__v1.md) | Git commit and GitHub sync workflow |

### Testing

| File | Purpose |
|------|---------|
| [KGB__Save_Query_List__v1.md](kgb/KGB__Save_Query_List__v1.md) | Known-Good Baseline test cases for artifact.save |

### Templates

| File | Purpose |
|------|---------|
| [Leaf_Template__v1.md](templates/Leaf_Template__v1.md) | Template for creating new leaf nodes |
| [Branch_Template__v1.md](templates/Branch_Template__v1.md) | Template for creating new branch nodes |

### Seeds

| File | Purpose |
|------|---------|
| [Seed__Upgrade_Tree_to_Typed_Model__v2.md](seeds/Seed__Upgrade_Tree_to_Typed_Model__v2.md) | Migration plan to v2 typed model with triggers |

### SQL

| File | Purpose |
|------|---------|
| [manual_save_build_tree_v1.sql](../../sql/manual_save_build_tree_v1.sql) | Manual SQL to INSERT all tree nodes into Qwrk |

---

## Design Principles

### 1. Fast-Now v1 Strategy

Use existing PROJECT artifacts with jsonb field to avoid creating new tables:

- ✅ No schema migrations required
- ✅ Works with existing Gateway workflows
- ✅ Incremental adoption (tree or no tree, your choice)
- ⚠️ Manual status updates (no triggers)
- ⚠️ Limited type safety (jsonb is schema-less)

### 2. Spine-First Consistency

All tree nodes are stored in `Qxb_Artifact` spine:

- artifact_type = "project"
- artifact_slug = node slug (e.g., "leaf__create_root_artifact_in_qwrk")
- content.tree_node = tree-specific fields

### 3. Sequential Leaf Execution

Leaves form a linked list via `sequence.ordinal` and `sequence.next_leaf_slug`:

```
Leaf 1 (ordinal: 1, next: Leaf 2) →
Leaf 2 (ordinal: 2, next: Leaf 3) →
Leaf 3 (ordinal: 3, next: Leaf 4) →
Leaf 4 (ordinal: 4, next: null)
```

### 4. Explicit Dependency Tracking

Use `blocked_by` and `unblocks` arrays for clarity:

- **blocked_by**: Prerequisites that must complete first
- **unblocks**: Dependents that become READY when this node completes

### 5. Human-in-the-Loop

v1 requires manual status updates (no database triggers):

- Mark leaf as IN_PROGRESS when starting
- Mark leaf as DONE when finished
- Manually update dependents to READY

**Future (v2)**: Database triggers auto-unblock dependents.

### 6. Journal INSERT-ONLY Doctrine (Temporary)

**Journal artifacts are append-only until Mutability Registry v2 is published.**

- ❌ **artifact.update on journal** → BLOCKED with `JOURNAL_MUTABILITY_UNDECIDED` error
- ✅ **artifact.create for journal** → Allowed (append new entries)
- ✅ **artifact.query for journal** → Allowed (read entries)

**Governance**: See [Doctrine_Journal_InsertOnly_Temporary.md](../../governance/Doctrine_Journal_InsertOnly_Temporary.md)

**Reason**: Journal mutability policy is classified as `UNDECIDED_BLOCKED` in Mutability Registry v1. The decision on whether journals should be editable or immutable has been explicitly deferred. Until this is locked, the safe default is INSERT-ONLY.

**Future**: Will be unlocked when Mutability Registry v2 publishes an explicit journal mutability policy.

### 7. Project Field Mutability Blocks (Temporary)

**Certain project artifact fields are blocked from UPDATE until Mutability Registry v2 is published.**

**Blocked Fields**:
- ❌ **project.tags** → UNDECIDED_BLOCKED
- ❌ **project.summary** → UNDECIDED_BLOCKED
- ❌ **project.priority** → UNDECIDED_BLOCKED

**Governance**: See [Mutability_Gaps_Decision_Packet_v1.md](../../governance/Mutability_Gaps_Decision_Packet_v1.md)

**What This Means**:
- ✅ **artifact.create with these fields** → Allowed (set on creation)
- ✅ **artifact.update with other fields** → Allowed (e.g., `label`, `lifecycle_stage`)
- ❌ **artifact.update with blocked fields** → BLOCKED with `FIELD_MUTABILITY_UNDECIDED` error

**Error Response**:
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "FIELD_MUTABILITY_UNDECIDED",
    "message": "One or more fields are blocked from UPDATE per Mutability Gaps Decision Packet v1.",
    "details": {
      "blocked_fields": ["tags", "summary", "priority"],
      "registry_status": "UNDECIDED_BLOCKED",
      "hint": "These fields cannot be updated until Mutability Registry v2 publishes explicit policy."
    }
  }
}
```

**Reason**: The decision on whether these fields should be mutable has been explicitly deferred in Phase 2 design. Open questions include:
- Are tags editable or append-only?
- Can users edit summary/priority or are they set-once?
- What are the UX implications of making these mutable?

Until these questions are answered and locked in Mutability Registry v2, the safe default is **BLOCK**.

**Future**: Will be unlocked when Mutability Registry v2 publishes explicit mutability policies for these fields.

---

## Migration Path to v2

See: [Seed__Upgrade_Tree_to_Typed_Model__v2.md](seeds/Seed__Upgrade_Tree_to_Typed_Model__v2.md)

**v2 Benefits**:
- First-class `tree_node` artifact type
- Database triggers for auto-unblocking
- Type safety with PostgreSQL constraints
- Better query performance (indexed columns)
- Validation at database level

**v1 → v2 Migration**:
1. Create `Qxb_Artifact_Tree_Node` extension table
2. Migrate jsonb → typed columns
3. Add triggers for dependency management
4. Update Gateway to use new artifact type
5. Keep v1 readable during transition

---

## Troubleshooting

### Problem: Leaf Won't Unblock

**Symptom**: Dependent leaf remains "blocked" after prerequisite is "done"

**Solution**:
1. Verify prerequisite status: `SELECT content->'tree_node'->>'status' FROM qxb_artifact WHERE artifact_slug = 'prerequisite_slug';`
2. Manually update dependent: `UPDATE qxb_artifact SET content = jsonb_set(content, '{tree_node,status}', '"ready"') WHERE artifact_slug = 'dependent_slug';`

### Problem: SQL INSERT Fails

**Symptom**: Manual SQL execution fails with constraint violation

**Solution**:
1. Check workspace_id matches your Supabase workspace
2. Verify parent_artifact_id exists (for non-root nodes)
3. Ensure artifact_slug is unique

### Problem: Tree Structure Unclear

**Symptom**: Can't visualize tree dependencies

**Solution**:
1. Read tree documentation: [Build_Tree__Save_Query_List__v1.md](tree/Build_Tree__Save_Query_List__v1.md)
2. Query all nodes: `SELECT artifact_slug, content->'tree_node'->>'node_kind', content->'tree_node'->>'status' FROM qxb_artifact WHERE content @> '{"tree_node": {"tree_slug": "build_tree__save_query_list__v1"}}';`

---

## Best Practices

1. **One Tree at a Time**: Complete one tree fully before starting another
2. **Sequential Execution**: Follow ordinal order for leaves
3. **Test Early**: Run KGB tests incrementally, not just at the end
4. **Document Anomalies**: Add notes to leaf if unexpected behavior occurs
5. **Commit Frequently**: Push changes to GitHub after each leaf
6. **Use Templates**: Copy templates when creating new trees

---

## References

- [North Star](../../architecture/North_Star_v0.1.md) - Qwrk V2 architecture
- [Phase 1-3](../../architecture/Phase_1-3_Kernel_Semantics_Lock.md) - Kernel semantics
- [Mutability Registry](../../governance/Mutability_Registry_v2.md) - Field mutation rules
- [Gateway README](../../../workflows/README.md) - Gateway v1 workflows
- [CLAUDE.md](../../governance/CLAUDE.md) - AI collaboration governance

---

**Version**: v1
**Status**: Active
**Last Updated**: 2026-01-02
**Trees**: 1 (Save Query List v1)
