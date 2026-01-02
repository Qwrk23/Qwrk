# Seed — Upgrade Tree to Typed Model v2

**Future enhancement proposal for migrating tree representation from jsonb to first-class artifact type**

---

## Seed Metadata

| Field | Value |
|-------|-------|
| **Seed Slug** | `seed__upgrade_tree_to_typed_model_v2` |
| **Planted** | 2026-01-02 |
| **Owner** | QP1 (future Qwrk Project Management agent) |
| **Status** | Planned (deferred until Kernel v2) |
| **Priority** | Medium |

---

## Problem Statement

**Current State (v1):**
- Tree nodes are represented using PROJECT artifacts with `content.tree_node` jsonb field
- "Fast now" approach that avoids creating new tables
- Manual status updates required (no automatic dependency resolution)
- Limited type safety (jsonb is schema-less)
- No database-level validation or triggers

**Limitations**:
1. Tree nodes are not first-class artifacts (they "piggyback" on PROJECT type)
2. Status updates are manual (no auto-unblocking when dependencies complete)
3. Dependency validation is application-level (not enforced by database)
4. Query performance may degrade with large trees (jsonb indexing limitations)
5. No type-specific operations (e.g., "get all READY leaves")

---

## Proposed Solution (v2)

### Create First-Class tree_node Artifact Type

Add `tree_node` to the list of artifact types alongside project, snapshot, restart, journal.

### New Database Schema

#### 1. Extension Table: Qxb_Artifact_Tree_Node

```sql
CREATE TABLE qxb_artifact_tree_node (
  artifact_id UUID PRIMARY KEY REFERENCES qxb_artifact(artifact_id) ON DELETE CASCADE,

  -- Tree Identity
  tree_version TEXT NOT NULL DEFAULT 'v2',
  tree_slug TEXT NOT NULL,

  -- Node Classification
  node_kind TEXT NOT NULL CHECK (node_kind IN ('root', 'branch', 'leaf', 'gate', 'test', 'seed')),

  -- Status
  status TEXT NOT NULL CHECK (status IN ('planned', 'ready', 'in_progress', 'blocked', 'done')),

  -- Sequence
  ordinal INTEGER,
  next_leaf_slug TEXT,

  -- Dependencies (arrays for jsonb compatibility during migration)
  blocked_by TEXT[] DEFAULT '{}',
  unblocks TEXT[] DEFAULT '{}',

  -- Ownership
  owner TEXT NOT NULL CHECK (owner IN ('Joel', 'CC', 'QP1')),

  -- References
  runbook_refs TEXT[] DEFAULT '{}',
  kgb_refs TEXT[] DEFAULT '{}',

  -- Notes
  notes TEXT,

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_tree_node_tree_slug ON qxb_artifact_tree_node(tree_slug);
CREATE INDEX idx_tree_node_status ON qxb_artifact_tree_node(status);
CREATE INDEX idx_tree_node_node_kind ON qxb_artifact_tree_node(node_kind);
CREATE INDEX idx_tree_node_ordinal ON qxb_artifact_tree_node(ordinal);
```

#### 2. Update Qxb_Artifact Spine

Add `tree_node` to artifact_type check constraint:

```sql
ALTER TABLE qxb_artifact DROP CONSTRAINT IF EXISTS qxb_artifact_artifact_type_check;
ALTER TABLE qxb_artifact ADD CONSTRAINT qxb_artifact_artifact_type_check
  CHECK (artifact_type IN ('project', 'snapshot', 'restart', 'journal', 'tree_node'));
```

---

## Migration Strategy

### Phase 1: Dual-Read (Backward Compatibility)

1. Create `Qxb_Artifact_Tree_Node` table
2. Update Gateway to recognize `tree_node` artifact type
3. Migrate existing v1 tree nodes:
   ```sql
   -- For each existing PROJECT artifact with content.tree_node
   INSERT INTO qxb_artifact (artifact_id, artifact_type, artifact_slug, ...)
   SELECT
     gen_random_uuid(),
     'tree_node',
     artifact_slug,
     ...
   FROM qxb_artifact
   WHERE content ? 'tree_node';

   INSERT INTO qxb_artifact_tree_node (artifact_id, tree_version, tree_slug, ...)
   SELECT
     artifact_id,
     content->'tree_node'->>'tree_version',
     content->'tree_node'->>'tree_slug',
     ...
   FROM qxb_artifact
   WHERE content ? 'tree_node';
   ```
4. Gateway reads from both v1 (jsonb) and v2 (typed) sources during transition

### Phase 2: Write to v2 Only

1. Update Gateway to create new tree nodes as `tree_node` artifacts (not PROJECT)
2. Keep v1 nodes readable but frozen (no updates)
3. New trees use v2 exclusively

### Phase 3: Deprecate v1

1. Archive or delete v1 tree nodes (after confirming v2 migration success)
2. Remove dual-read logic from Gateway
3. Update documentation to reference v2 only

---

## Database Triggers (Auto-Dependency Management)

### Trigger 1: Auto-Unblock Dependents

When a tree node reaches `status = 'done'`, automatically update dependent nodes:

```sql
CREATE OR REPLACE FUNCTION auto_unblock_dependents()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'done' AND OLD.status != 'done' THEN
    -- For each slug in NEW.unblocks array
    UPDATE qxb_artifact_tree_node
    SET
      status = 'ready',
      updated_at = NOW()
    WHERE
      artifact_slug = ANY(NEW.unblocks)
      AND status = 'blocked'
      -- Check that all blockers are done
      AND NOT EXISTS (
        SELECT 1
        FROM qxb_artifact_tree_node blocker
        WHERE blocker.artifact_slug = ANY(qxb_artifact_tree_node.blocked_by)
          AND blocker.status != 'done'
      );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_unblock_dependents
AFTER UPDATE OF status ON qxb_artifact_tree_node
FOR EACH ROW
EXECUTE FUNCTION auto_unblock_dependents();
```

### Trigger 2: Validate Dependency References

Ensure all slugs in `blocked_by` and `unblocks` exist in the same tree:

```sql
CREATE OR REPLACE FUNCTION validate_tree_dependencies()
RETURNS TRIGGER AS $$
DECLARE
  invalid_slug TEXT;
BEGIN
  -- Check blocked_by references
  SELECT slug INTO invalid_slug
  FROM unnest(NEW.blocked_by) AS slug
  WHERE NOT EXISTS (
    SELECT 1 FROM qxb_artifact_tree_node
    WHERE artifact_slug = slug AND tree_slug = NEW.tree_slug
  )
  LIMIT 1;

  IF invalid_slug IS NOT NULL THEN
    RAISE EXCEPTION 'Invalid blocked_by reference: % does not exist in tree %', invalid_slug, NEW.tree_slug;
  END IF;

  -- Check unblocks references
  SELECT slug INTO invalid_slug
  FROM unnest(NEW.unblocks) AS slug
  WHERE NOT EXISTS (
    SELECT 1 FROM qxb_artifact_tree_node
    WHERE artifact_slug = slug AND tree_slug = NEW.tree_slug
  )
  LIMIT 1;

  IF invalid_slug IS NOT NULL THEN
    RAISE EXCEPTION 'Invalid unblocks reference: % does not exist in tree %', invalid_slug, NEW.tree_slug;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_tree_dependencies
BEFORE INSERT OR UPDATE ON qxb_artifact_tree_node
FOR EACH ROW
EXECUTE FUNCTION validate_tree_dependencies();
```

### Trigger 3: Auto-Update Tree Root Status

When all leaves in a tree are done, mark root as done:

```sql
CREATE OR REPLACE FUNCTION auto_update_root_status()
RETURNS TRIGGER AS $$
BEGIN
  -- If all leaves in this tree are done, mark root as done
  IF NOT EXISTS (
    SELECT 1 FROM qxb_artifact_tree_node
    WHERE tree_slug = NEW.tree_slug
      AND node_kind = 'leaf'
      AND status != 'done'
  ) THEN
    UPDATE qxb_artifact_tree_node
    SET status = 'done', updated_at = NOW()
    WHERE tree_slug = NEW.tree_slug AND node_kind = 'root';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_update_root_status
AFTER UPDATE OF status ON qxb_artifact_tree_node
FOR EACH ROW
WHEN (NEW.node_kind = 'leaf' AND NEW.status = 'done')
EXECUTE FUNCTION auto_update_root_status();
```

---

## Gateway Changes

### New Action: tree.query

Query a tree node by ID or slug:

**Request**:
```json
{
  "gw_user_id": "uuid",
  "gw_workspace_id": "uuid",
  "gw_action": "tree.query",
  "artifact_id": "uuid",
  "artifact_type": "tree_node"
}
```

**Response**:
```json
{
  "ok": true,
  "artifact": {
    "artifact_id": "uuid",
    "artifact_type": "tree_node",
    "artifact_slug": "leaf__example",
    "tree_version": "v2",
    "tree_slug": "build_tree__example__v1",
    "node_kind": "leaf",
    "status": "ready",
    "ordinal": 1,
    "next_leaf_slug": "leaf__next_example",
    "blocked_by": [],
    "unblocks": ["leaf__next_example"],
    "owner": "Joel",
    "runbook_refs": ["..."],
    "kgb_refs": [],
    "notes": "..."
  }
}
```

### New Action: tree.list

List all nodes in a tree:

**Request**:
```json
{
  "gw_user_id": "uuid",
  "gw_workspace_id": "uuid",
  "gw_action": "tree.list",
  "selector": {
    "tree_slug": "build_tree__save_query_list__v1",
    "node_kind": "leaf",
    "status": "ready"
  }
}
```

**Response**:
```json
{
  "ok": true,
  "items": [
    { /* tree node 1 */ },
    { /* tree node 2 */ }
  ],
  "meta": {
    "count": 2,
    "tree_slug": "build_tree__save_query_list__v1"
  }
}
```

### New Action: tree.update_status

Update tree node status (triggers auto-unblocking):

**Request**:
```json
{
  "gw_user_id": "uuid",
  "gw_workspace_id": "uuid",
  "gw_action": "tree.update_status",
  "artifact_id": "uuid",
  "artifact_type": "tree_node",
  "artifact_payload": {
    "status": "done"
  }
}
```

**Response**:
```json
{
  "ok": true,
  "artifact": { /* updated tree node */ },
  "unblocked": ["leaf__dependent_1", "leaf__dependent_2"]
}
```

---

## Benefits of v2 Typed Model

1. **First-Class Artifacts**: Tree nodes are proper artifact type (not jsonb hack)
2. **Automatic Dependency Resolution**: Database triggers handle unblocking
3. **Type Safety**: PostgreSQL constraints enforce valid states
4. **Better Performance**: Indexed columns for tree_slug, status, node_kind
5. **Validation**: Database-level checks for dependency references
6. **Query Efficiency**: Direct SQL queries for "get all READY leaves"
7. **Audit Trail**: Automatic updated_at timestamps
8. **Future Extensibility**: Easier to add tree-specific features (e.g., deadlock detection)

---

## Risks and Mitigations

### Risk 1: Migration Complexity

**Mitigation**: Dual-read phase allows gradual migration without breaking existing trees

### Risk 2: Trigger Performance

**Mitigation**: Benchmark triggers with large trees; optimize if needed

### Risk 3: Breaking Changes

**Mitigation**: v1 remains readable during transition; documentation updated incrementally

---

## Implementation Checklist

When implementing v2:

- [ ] Create `Qxb_Artifact_Tree_Node` table
- [ ] Update `qxb_artifact` artifact_type constraint
- [ ] Implement auto-unblock trigger
- [ ] Implement dependency validation trigger
- [ ] Implement root status update trigger
- [ ] Update Gateway to recognize `tree_node` type
- [ ] Implement `tree.query` action
- [ ] Implement `tree.list` action
- [ ] Implement `tree.update_status` action
- [ ] Migrate existing v1 trees to v2
- [ ] Update documentation to reference v2
- [ ] Create KGB tests for v2 tree operations
- [ ] Archive or delete v1 tree nodes
- [ ] Remove dual-read logic from Gateway

---

## Timeline

**Kernel v1**: Use jsonb fast-now representation (current)

**Kernel v2** (future): Implement typed model with triggers

**Estimated Effort**: 2-3 weeks (design + implementation + testing)

---

## References

- [TreeNode Schema v1](../tree/TreeNode_Schema__content.tree_node__v1.md)
- [Build Tree Documentation](../tree/Build_Tree__Save_Query_List__v1.md)
- [North Star](../../../../docs/architecture/North_Star_v0.1.md)
- [Phase 1-3](../../../../docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md)

---

**Seed Version**: v1
**Status**: Planned (deferred)
**Owner**: QP1 (future)
**Last Updated**: 2026-01-02
