# Tree Registry — Canonical Truth

**This file is the single source of truth for all active Build Trees in Qwrk.**

---

## Purpose

The Tree Registry prevents conflicts when:
- Multiple trees use similar names
- Old planning docs exist alongside executable trees
- Trees are migrated or superseded

**Rule**: If a tree slug appears in multiple locations, this registry declares which is canonical.

---

## Active Trees

| Tree Slug | Status | Location | Purpose | Owner | Created |
|-----------|--------|----------|---------|-------|---------|
| `build_tree__save_query_list__v1` | Active | [docs/build_tree/v1/](v1/) | Validate artifact.save workflow (Gateway v1.1 writes) | Joel | 2026-01-02 |

---

## Tree Slug Naming Convention

Format: `build_tree__<purpose>__v<version>`

Examples:
- `build_tree__save_query_list__v1`
- `build_tree__artifact_promote__v1`
- `build_tree__structure_layer__v1`

**Rules**:
- Use snake_case for `<purpose>`
- Include version suffix
- Must be unique across all trees
- Add to this registry before creating tree nodes in database

---

## Tree Lifecycle States

| Status | Meaning |
|--------|---------|
| **Active** | Tree is currently in use (leaves being executed or complete) |
| **Planned** | Tree defined but not yet planted in database |
| **Complete** | All leaves executed, TEST passed, ROOT marked DONE |
| **Archived** | Historical tree, no longer in use |
| **Superseded** | Replaced by newer version |

---

## Superseded Locations

| Old Location | Superseded Date | Reason | Canonical Replacement |
|--------------|-----------------|--------|----------------------|
| `AAA_New_Qwrk/Qwrk Build Tree Pack for CC/trees/` | 2026-01-02 | Planning docs replaced by executable tree structure | `docs/build_tree/v1/` |

---

## Registration Process

When creating a new tree:

1. **Check this registry** - Ensure tree slug is unique
2. **Add entry** to Active Trees table
3. **Create tree structure** in `docs/build_tree/v<version>/`
4. **Generate manual SQL** to plant tree in Qwrk database
5. **Commit to GitHub** with tree slug in commit message

---

## Conflict Resolution

If you discover conflicting tree documentation:

1. **Check this registry** - Which location is canonical?
2. **Mark old location** with `[SUPERSEDED]_README.md`
3. **Update this registry** - Add old location to "Superseded Locations" table
4. **Do NOT rename** files unnecessarily
5. **Commit governance changes** to lock canonical truth

---

## Tree Node Storage

All active trees are stored as PROJECT artifacts in Qwrk database:

**Query active trees**:
```sql
SELECT artifact_slug, content->'tree_node'->>'node_kind', content->'tree_node'->>'status'
FROM qxb_artifact
WHERE content @> '{"tree_node": {"tree_slug": "build_tree__save_query_list__v1"}}';
```

**Canonical truth order**:
1. Qwrk database (PROJECT artifacts with content.tree_node)
2. This registry (declares which documentation is authoritative)
3. Tree documentation in docs/build_tree/v*/

---

## References

- [Build Tree Management Pack v1](v1/)
- [TreeNode Schema](v1/tree/TreeNode_Schema__content.tree_node__v1.md)
- [Governance Rules](../governance/CLAUDE.md)

---

**Version**: v1
**Last Updated**: 2026-01-02
**Total Active Trees**: 1
