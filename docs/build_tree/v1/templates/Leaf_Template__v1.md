# Leaf Template v1

**Template for creating new leaf nodes in Build Trees**

---

## Instructions

1. Copy this template
2. Replace all `<PLACEHOLDER>` values with actual content
3. Ensure all required fields are populated
4. Save as `Leaf__<descriptive_name>__v1.md`
5. Add to tree documentation

---

## Leaf Definition

**Slug**: `leaf__<descriptive_name>`

**Status**: <ready|blocked|in_progress|done>

**Purpose**: <One sentence describing what this leaf accomplishes>

**Owner**: <Joel|CC|QP1>

**Execution Steps**:
1. <Step 1 description>
2. <Step 2 description>
3. <Step 3 description>
4. ...

---

## content.tree_node Structure

```json
{
  "tree_node": {
    "tree_version": "v1",
    "tree_slug": "<tree_slug>",
    "node_kind": "leaf",
    "status": "<ready|blocked|in_progress|done>",
    "sequence": {
      "ordinal": <number>,
      "next_leaf_slug": "<next_leaf_slug|null>"
    },
    "blocked_by": [
      "<prerequisite_leaf_slug>"
    ],
    "unblocks": [
      "<dependent_leaf_slug>"
    ],
    "owner": "<Joel|CC|QP1>",
    "runbook_refs": [
      "docs/build_tree/v1/runbooks/<runbook_filename>#<anchor>"
    ],
    "kgb_refs": [
      "docs/build_tree/v1/kgb/<kgb_filename>"
    ],
    "notes": "<Freeform notes about execution, warnings, or context>"
  }
}
```

---

## Field Guidance

### tree_slug
- Use the same tree_slug as all other nodes in this tree
- Format: `build_tree__<purpose>__v1`

### status
- **ready**: No blockers, can be executed immediately
- **blocked**: Has dependencies in `blocked_by` that must complete first
- **in_progress**: Currently being executed
- **done**: Completed successfully

### sequence.ordinal
- Numeric order within the tree (1, 2, 3, ...)
- Root = 0, first leaf = 1, second leaf = 2, etc.

### sequence.next_leaf_slug
- Slug of the next leaf in execution order
- `null` if this is the final leaf

### blocked_by
- Array of slugs for prerequisite nodes
- Empty array `[]` if no blockers (leaf is READY)

### unblocks
- Array of slugs for dependent nodes that will become READY when this leaf completes
- Empty array `[]` if no dependents

### owner
- **Joel**: Master Joel (human execution)
- **CC**: Claude Code (AI-assisted execution)
- **QP1**: Qwrk Project Management agent (future automation)

### runbook_refs
- Relative paths from repo root to runbook documentation
- Use `#anchor` to link to specific sections
- Example: `docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md#execute-leaf-1`

### kgb_refs
- Relative paths from repo root to KGB test documentation
- Use if this leaf has specific acceptance tests
- Empty array `[]` if no KGB tests

### notes
- Freeform text for context, warnings, or execution hints
- Example: "Requires Supabase admin access. Coordinate with Joel before execution."

---

## Execution Checklist

When executing this leaf:

- [ ] Verify status is READY
- [ ] Mark leaf as IN_PROGRESS
- [ ] Execute all steps in order
- [ ] Verify completion criteria
- [ ] Mark leaf as DONE
- [ ] Unblock dependent leaves (update their status to READY)

---

## Completion Criteria

Define what "done" means for this leaf:

- ✅ <Criterion 1>
- ✅ <Criterion 2>
- ✅ <Criterion 3>
- ✅ All database changes verified
- ✅ All files committed to GitHub

---

## Example: Concrete Leaf

**Slug**: `leaf__create_forest_artifacts_in_qwrk`

**Status**: ready

**Purpose**: Create all FOREST nodes as PROJECT artifacts in Qwrk database

**Owner**: Joel

**Execution Steps**:
1. Run manual SQL to INSERT forest nodes
2. Verify artifact_ids are generated
3. Verify content.tree_node contains correct forest structures
4. Mark leaf as DONE

**content.tree_node**:
```json
{
  "tree_node": {
    "tree_version": "v1",
    "tree_slug": "build_tree__structure_layer__v1",
    "node_kind": "leaf",
    "status": "ready",
    "sequence": {
      "ordinal": 1,
      "next_leaf_slug": "leaf__create_thicket_artifacts_in_qwrk"
    },
    "blocked_by": [],
    "unblocks": [
      "leaf__create_thicket_artifacts_in_qwrk"
    ],
    "owner": "Joel",
    "runbook_refs": [
      "docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md#execute-leaf-1"
    ],
    "kgb_refs": [],
    "notes": "First executable leaf. Creates forest nodes for major life domains."
  }
}
```

**Completion Criteria**:
- ✅ All forest artifacts exist in Qxb_Artifact
- ✅ Each forest has valid tree_node structure
- ✅ Leaf status = "done"
- ✅ Next leaf status = "ready"

---

## References

- [TreeNode Schema](../tree/TreeNode_Schema__content.tree_node__v1.md)
- [How to Execute Leaves](../runbooks/Runbook__How_to_Execute_Leaves__v1.md)
- [Build Tree Documentation](../tree/)

---

**Template Version**: v1
**Last Updated**: 2026-01-02
