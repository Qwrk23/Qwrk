# Branch Template v1

**Template for creating new branch nodes in Build Trees**

---

## Instructions

1. Copy this template
2. Replace all `<PLACEHOLDER>` values with actual content
3. Ensure all required fields are populated
4. Save as `Branch__<descriptive_name>__v1.md`
5. Add to tree documentation

---

## Branch Definition

**Slug**: `branch__<descriptive_name>`

**Purpose**: <One sentence describing the organizational grouping>

**Contains**: <List of child nodes: leaves, tests, seeds>

---

## content.tree_node Structure

```json
{
  "tree_node": {
    "tree_version": "v1",
    "tree_slug": "<tree_slug>",
    "node_kind": "branch",
    "status": "<planned|in_progress|blocked|done>",
    "sequence": {
      "ordinal": null,
      "next_leaf_slug": null
    },
    "blocked_by": [
      "<prerequisite_node_slug>"
    ],
    "unblocks": [
      "<dependent_node_slug>"
    ],
    "owner": "<Joel|CC|QP1>",
    "runbook_refs": [
      "docs/build_tree/v1/runbooks/<runbook_filename>"
    ],
    "kgb_refs": [],
    "notes": "<Freeform notes about this branch's purpose or children>"
  }
}
```

---

## Field Guidance

### tree_slug
- Use the same tree_slug as all other nodes in this tree
- Format: `build_tree__<purpose>__v1`

### status
- **planned**: Defined but not yet active
- **in_progress**: At least one child node is active
- **blocked**: Has dependencies in `blocked_by` that must complete first
- **done**: All child nodes completed

### sequence.ordinal
- Branches do not participate in sequential execution
- Always `null`

### sequence.next_leaf_slug
- Branches do not have next pointers
- Always `null`

### blocked_by
- Array of slugs for prerequisite nodes
- Empty array `[]` if no blockers

### unblocks
- Array of slugs for child nodes (leaves, tests, seeds)
- Lists all nodes that belong to this organizational grouping

### owner
- **Joel**: Master Joel (human execution)
- **CC**: Claude Code (AI-assisted execution)
- **QP1**: Qwrk Project Management agent (future automation)

### runbook_refs
- Relative paths from repo root to runbook documentation
- Optional for branches (more common for leaves)

### kgb_refs
- Typically empty for branches
- Tests under the branch will have their own KGB refs

### notes
- Describe the purpose of this organizational grouping
- List child nodes for clarity

---

## Example: Concrete Branch

**Slug**: `branch__gateway_v1_1_writes`

**Purpose**: Organizational container for Gateway write operation implementation tasks

**Contains**:
- `leaf__create_root_artifact_in_qwrk`
- `leaf__create_branch_nodes_in_qwrk`

**content.tree_node**:
```json
{
  "tree_node": {
    "tree_version": "v1",
    "tree_slug": "build_tree__save_query_list__v1",
    "node_kind": "branch",
    "status": "in_progress",
    "sequence": {
      "ordinal": null,
      "next_leaf_slug": null
    },
    "blocked_by": [],
    "unblocks": [
      "leaf__create_root_artifact_in_qwrk",
      "leaf__create_branch_nodes_in_qwrk"
    ],
    "owner": "Joel",
    "runbook_refs": [],
    "kgb_refs": [],
    "notes": "Contains leaves for creating tree structure in Qwrk database."
  }
}
```

---

## Visual Representation

When documenting the tree visually:

```
branch__<name>
│
├─ leaf__<child_1>
├─ leaf__<child_2>
└─ test__<child_3>
```

---

## Parent-Child Relationships

Branches serve as organizational containers. In the database:

- **Branch artifact**: `parent_artifact_id` points to ROOT or another BRANCH
- **Child artifacts**: Their `parent_artifact_id` points to this BRANCH

**Example SQL**:
```sql
-- Branch artifact
INSERT INTO qxb_artifact (artifact_id, artifact_slug, parent_artifact_id, ...)
VALUES ('<branch-uuid>', 'branch__gateway_v1_1_writes', '<root-uuid>', ...);

-- Child leaf artifact
INSERT INTO qxb_artifact (artifact_id, artifact_slug, parent_artifact_id, ...)
VALUES ('<leaf-uuid>', 'leaf__create_root_artifact_in_qwrk', '<branch-uuid>', ...);
```

---

## Status Management

Branch status is typically derived from child status:

- **planned**: No children started yet
- **in_progress**: At least one child is in_progress or done
- **blocked**: All children are blocked (rare)
- **done**: All children are done

**Note**: Branches do not have explicit execution. Their status reflects aggregate child state.

---

## References

- [TreeNode Schema](../tree/TreeNode_Schema__content.tree_node__v1.md)
- [Build Tree Documentation](../tree/)
- [Leaf Template](Leaf_Template__v1.md)

---

**Template Version**: v1
**Last Updated**: 2026-01-02
