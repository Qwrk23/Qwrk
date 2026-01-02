# TreeNode Schema — content.tree_node v1

**Fast-now representation for Build Tree nodes using standard PROJECT artifacts**

---

## Purpose

Define the canonical shape for `content.tree_node` (jsonb field) that turns any PROJECT artifact into a Tree node for execution management.

This is a **v1 fast-now approach**: we use the existing `qxb_artifact` spine + `content` jsonb field to encode tree semantics without adding new tables or types.

---

## Schema Definition (v1)

```json
{
  "tree_node": {
    "tree_version": "v1",
    "tree_slug": "build_tree__save_query_list__v1",
    "node_kind": "root|branch|leaf|gate|test|seed",
    "status": "planned|ready|in_progress|blocked|done",
    "sequence": {
      "ordinal": 0,
      "next_leaf_slug": "leaf__next_node_slug"
    },
    "blocked_by": ["leaf__prerequisite_slug"],
    "unblocks": ["leaf__dependent_slug"],
    "owner": "Joel|CC|QP1",
    "runbook_refs": ["docs/build_tree/v1/runbooks/..."],
    "kgb_refs": ["docs/build_tree/v1/kgb/..."],
    "notes": "Optional freeform notes"
  }
}
```

---

## Field Definitions

### tree_version (string, required)

**Format**: `"v1"`

**Purpose**: Version of tree schema in use. Allows migration to v2 typed model later.

**Rules**:
- Must be `"v1"` for all nodes in this tree
- Used for validation and migration planning

### tree_slug (string, required)

**Format**: `"build_tree__<purpose>__v<version>"`

**Purpose**: Identifies which tree this node belongs to (scoping for multi-tree future).

**Example**: `"build_tree__save_query_list__v1"`

**Rules**:
- All nodes in same tree must have identical tree_slug
- Slug format: `build_tree__<purpose>__v<version>`

### node_kind (string, required)

**Allowed values**:
- `"root"` - Single root node per tree
- `"branch"` - Organizational grouping (no execution)
- `"leaf"` - Executable task (work unit)
- `"gate"` - Decision/approval point
- `"test"` - Validation checkpoint (e.g., KGB)
- `"seed"` - Future enhancement proposal

**Purpose**: Classifies the node's role in the tree.

**Rules**:
- Exactly one `"root"` per tree
- `"leaf"` nodes are the only executable work units
- `"gate"` and `"test"` nodes may have acceptance criteria
- `"seed"` nodes represent planned future work

### status (string, required)

**Allowed values**:
- `"planned"` - Defined but not yet ready
- `"ready"` - Ready to execute (no blockers)
- `"in_progress"` - Currently being worked on
- `"blocked"` - Cannot proceed (see `blocked_by`)
- `"done"` - Completed

**Purpose**: Tracks execution state.

**Rules**:
- Leaf starts as `"ready"` if no `blocked_by` entries
- Leaf starts as `"blocked"` if `blocked_by` is non-empty
- When a leaf moves to `"done"`, its `unblocks` targets may become `"ready"`
- Only one leaf should be `"in_progress"` at a time (discipline)

### sequence (object, required)

```json
{
  "ordinal": 1,
  "next_leaf_slug": "leaf__next_step_slug"
}
```

**Fields**:
- `ordinal` (integer): Numeric order within the tree (0 = root, 1+ for leaves)
- `next_leaf_slug` (string | null): Slug of the next leaf in execution order

**Purpose**: Defines linear execution order for leaves.

**Rules**:
- Root has `ordinal: 0`
- Leaves have sequential ordinalnumbers (1, 2, 3, ...)
- `next_leaf_slug` is `null` for the final leaf
- Forms a linked list: Leaf 1 → Leaf 2 → Leaf 3 → ...

### blocked_by (array of strings, optional)

**Format**: `["leaf__prerequisite_slug", ...]`

**Purpose**: Lists slugs of nodes that must complete before this node becomes ready.

**Rules**:
- Empty array or omitted = no blockers
- When all `blocked_by` nodes reach `"done"`, this node becomes `"ready"`
- Forms a dependency graph

**Example**:
```json
"blocked_by": ["leaf__create_root_artifact_in_qwrk"]
```

### unblocks (array of strings, optional)

**Format**: `["leaf__dependent_slug", ...]`

**Purpose**: Lists slugs of nodes that will become unblocked when this node completes.

**Rules**:
- Inverse of `blocked_by` (for clarity/validation)
- When this node reaches `"done"`, check all `unblocks` targets
- Optional but recommended for documentation

**Example**:
```json
"unblocks": ["leaf__create_branch_nodes_in_qwrk"]
```

### owner (string, required)

**Allowed values**:
- `"Joel"` - Master Joel (human)
- `"CC"` - Claude Code (AI assistant)
- `"QP1"` - Qwrk Project Management agent (future)

**Purpose**: Indicates who is responsible for executing this node.

**Rules**:
- Default to `"Joel"` for manual work
- Use `"CC"` for AI-assisted implementation
- Use `"QP1"` for future automation

### runbook_refs (array of strings, optional)

**Format**: `["docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md"]`

**Purpose**: Links to execution instructions for this node.

**Rules**:
- Relative paths from repo root
- At least one runbook ref recommended for leaves
- May reference sections with `#` anchors

### kgb_refs (array of strings, optional)

**Format**: `["docs/build_tree/v1/kgb/KGB__Save_Query_List__v1.md"]`

**Purpose**: Links to Known-Good Baseline tests for validation.

**Rules**:
- Relative paths from repo root
- Test nodes should have KGB refs
- Leaves may reference acceptance tests

### notes (string, optional)

**Purpose**: Freeform text for context, rationale, or warnings.

**Example**:
```json
"notes": "This leaf requires Supabase admin access. Coordinate with Joel before execution."
```

---

## Node Naming Convention

**Slug format**: `<node_kind>__<descriptive_name>`

**Examples**:
- Root: `root__build_tree__save_query_list__v1`
- Branch: `branch__gateway_v1_1_writes`
- Leaf: `leaf__create_root_artifact_in_qwrk`
- Test: `test__kgb_save_query_list_v1`
- Seed: `seed__upgrade_tree_to_typed_model_v2`

**Rules**:
- Use snake_case
- Prefix with node_kind
- Descriptive and unique within tree

---

## Validation Rules

### Required Fields

All nodes MUST have:
- `tree_version`
- `tree_slug`
- `node_kind`
- `status`
- `sequence.ordinal`
- `owner`

### Consistency Checks

1. **Root uniqueness**: Exactly one node with `node_kind: "root"` per tree
2. **Ordinal uniqueness**: No duplicate `sequence.ordinal` values
3. **Slug uniqueness**: No duplicate slugs within a tree
4. **Blocked_by validity**: All slugs in `blocked_by` must exist
5. **Unblocks validity**: All slugs in `unblocks` must exist
6. **Status consistency**: If `blocked_by` is empty, status should not be `"blocked"`

---

## Migration Path to v2

A **Seed node** exists in the tree: `seed__upgrade_tree_to_typed_model_v2`

When v2 is implemented:
- New artifact type: `tree_node` (or similar)
- Dedicated type table: `qxb_artifact_tree_node`
- Migration SQL: Copy `content.tree_node` → new columns
- Triggers: Auto-update `status` based on dependencies
- Backward compatibility: Read v1 nodes during transition

---

## Usage Example

```json
{
  "tree_node": {
    "tree_version": "v1",
    "tree_slug": "build_tree__save_query_list__v1",
    "node_kind": "leaf",
    "status": "ready",
    "sequence": {
      "ordinal": 1,
      "next_leaf_slug": "leaf__create_branch_nodes_in_qwrk"
    },
    "blocked_by": [],
    "unblocks": ["leaf__create_branch_nodes_in_qwrk"],
    "owner": "Joel",
    "runbook_refs": [
      "docs/build_tree/v1/runbooks/Runbook__How_to_Execute_Leaves__v1.md#execute-leaf-1"
    ],
    "kgb_refs": [],
    "notes": "First executable leaf. Creates the root artifact in Qwrk database."
  }
}
```

---

## References

- [Build Tree Documentation](Build_Tree__Save_Query_List__v1.md)
- [Execution Runbook](../runbooks/Runbook__How_to_Execute_Leaves__v1.md)
- [Seed: Upgrade to v2](../seeds/Seed__Upgrade_Tree_to_Typed_Model__v2.md)

---

**Version**: v1
**Status**: Locked
**Last Updated**: 2026-01-02
