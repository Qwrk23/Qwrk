# Instruction Pack — {{workspace_display_name}}

**Purpose:** Reference guide for Qwrk Gateway operations in this workspace.
**Workspace UUID:** `{{workspace_uuid}}`
**Gateway Webhook:** `{{webhook_url}}`
**Updated:** 2026-03-04 (T69 alignment — semantic_type_id, structured tags, error codes)

---

## Gateway Actions Reference

### artifact.save — Create a New Artifact

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "{{type}}",
  "title": "Your artifact title",
  "semantic_type_id": "execution-core",
  "priority": 3,
  "tags": ["tag1", "tag2"],
  "extension": {}
}
```

**Required fields:** `gw_action`, `gw_workspace_id`, `artifact_type`, `title`, `semantic_type_id` (top-level types only)

**`semantic_type_id` rules:**
- **REQUIRED** for top-level types: `project`, `snapshot`, `journal`, `restart`
- **FORBIDDEN** for non-top-level types: `branch`, `leaf`, `limb`, `instruction_pack`
- Registry values: `execution-core`, `governance`, `infrastructure`, `platform`, `product`, `alignment`, `sales`, `marketing`, `exploratory`

**Optional fields:** `priority` (default 3), `tags` (recommended), `summary`, `content`, `parent_artifact_id`, `execution_status`

**Type-specific extension fields:**
- `project`: `{ "lifecycle_stage": "seed" }`
- `journal`: `{ "entry_text": "Journal entry text" }` (ONLY `entry_text` permitted)
- `snapshot`: `{ "payload": { ... } }`
- `restart`: `{ "payload": { ... } }`
- `instruction_pack`: `{ "scope": "...", "active": true, "priority": 1, "pack_format": "json" }`
- `branch`, `leaf`: spine-only (extension ignored)
- `limb`: shell INSERT (no required extension fields)

### artifact.query — Get a Specific Artifact

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "{{type}}",
  "artifact_id": "{{artifact_uuid}}"
}
```

**Required fields:** `gw_action`, `gw_workspace_id`, `artifact_type`, `artifact_id`

### artifact.list — List Artifacts

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "{{type}}",
  "selector": {
    "limit": 20,
    "offset": 0
  }
}
```

**Optional selector fields:**
- `limit`: 1-200 (default: 50)
- `offset`: pagination offset (default: 0)
- `hydrate`: boolean (default: false for list)
- `filters.tags_any`: `["tag1", "tag2"]` — artifact must contain ALL specified tags
- `parent_artifact_id`: filter by parent

**Pagination cap:** `offset + limit + 1` must not exceed 500.

**With tag filter:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "snapshot",
  "selector": {
    "limit": 10,
    "filters": {
      "tags_any": ["governance"]
    }
  }
}
```

### artifact.update — Update an Existing Artifact

**Extension update (project only):**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "project",
  "artifact_id": "{{artifact_uuid}}",
  "extension": {
    "operational_state": "active",
    "state_reason": "Work started"
  }
}
```

**Tag update (all types):**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "{{type}}",
  "artifact_id": "{{artifact_uuid}}",
  "tags": {
    "add": ["new-tag"],
    "remove": ["old-tag"]
  }
}
```

**Semantic type update (dedicated path — top-level types only):**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "project",
  "artifact_id": "{{artifact_uuid}}",
  "extension": {
    "semantic_type_id": "governance",
    "reason": "Reclassified after scope review"
  }
}
```

**Update rules:**
- Tags and extension cannot be combined in one call
- Semantic type update must be standalone (no tags, no other extension fields)
- Semantic type update only applies to top-level types
- Snapshot/restart extension updates are BLOCKED (IMMUTABILITY_ERROR)
- Journal extension updates are BLOCKED (JOURNAL_MUTABILITY_UNDECIDED)

### artifact.promote — Lifecycle Transition

```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "project",
  "artifact_id": "{{artifact_uuid}}",
  "transition": "seed_to_sapling",
  "reason": "Reason for promotion"
}
```

**Valid transitions:**
- `seed_to_sapling`
- `sapling_to_tree`
- `tree_to_archive`

### artifact.delete / artifact.restore / artifact.list_deleted

```json
{
  "gw_action": "artifact.delete",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "{{type}}",
  "artifact_id": "{{artifact_uuid}}"
}
```

Soft-delete only. Use `artifact.restore` with same shape to restore. `artifact.list_deleted` lists soft-deleted artifacts.

---

## Allowed Artifact Types

| Type | Description | Has Extension Table | Requires semantic_type_id |
|------|-------------|-------------------|--------------------------|
| `project` | Lifecycle-managed work items | Yes | Yes |
| `journal` | Private reflective entries | Yes | Yes |
| `snapshot` | Immutable payload captures | Yes | Yes |
| `restart` | Session continuation artifacts | Yes | Yes |
| `instruction_pack` | Instruction storage | Yes | No (FORBIDDEN) |
| `branch` | Execution anatomy (North Star) | No (spine-only) | No (FORBIDDEN) |
| `limb` | Execution anatomy (North Star) | Yes (shell) | No (FORBIDDEN) |
| `leaf` | Execution anatomy (North Star) | No (spine-only) | No (FORBIDDEN) |

---

## Error Codes Reference

| Code | Meaning | Common Cause |
|------|---------|-------------|
| `VALIDATION_ERROR` | Missing or invalid required field | Check payload structure |
| `WORKSPACE_FORBIDDEN` | Wrong workspace_id for this gateway | Use `{{workspace_uuid}}` |
| `ACTION_NOT_ALLOWED` | Invalid gw_action | Typo in action name |
| `ARTIFACT_TYPE_NOT_ALLOWED` | Invalid artifact_type | Type not in allowlist |
| `TYPE_MISMATCH` | Requested type doesn't match stored type | Check artifact_id + type combination |
| `NOT_FOUND` | Artifact not found | Check artifact_id and workspace |
| `IMMUTABILITY_ERROR` | Extension update on snapshot/restart | Use tags-only update instead |
| `JOURNAL_EXTENSION_INVALID` | Invalid keys in journal extension | Only `entry_text` is allowed |
| `JOURNAL_MUTABILITY_UNDECIDED` | Extension update on journal | Use tags-only update |
| `MUTABILITY_ERROR` | Disallowed field in project extension | Only `operational_state` and `state_reason` allowed |
| `INVALID_SEMANTIC_TYPE` | semantic_type_id not in registry | Check registry values |
| `SEMANTIC_TYPE_INACTIVE` | semantic type is inactive | Use an active registry value |
| `MIXED_UPDATE_NOT_ALLOWED` | semantic_type combined with tags/extension | Submit separately |
| `SEMANTIC_TYPE_NOT_APPLICABLE` | semantic_type update on non-top-level | Only top-level types support this |
| `LIFECYCLE_STATE_MISMATCH` | Current lifecycle doesn't match expected | Check current lifecycle_status |
| `PAGINATION_WINDOW_EXCEEDED` | offset + limit too large | Reduce offset or limit |

---

## Artifact Extension Contracts

### Journal

Strict contract:

```
extension:
  entry_text: string (required, non-empty)
```

No additional fields permitted.

Failure to comply results in `JOURNAL_EXTENSION_INVALID`.

---

## Constraints

- **Workspace lock:** All operations must use `{{workspace_uuid}}`
- **Priority:** Optional (default 3). Explicit recommended.
- **semantic_type_id:** REQUIRED for top-level types, FORBIDDEN for non-top-level
- **Tags on save:** JSONB array format: `["tag1", "tag2"]`
- **Tags on update:** Structured format: `{ "add": [...], "remove": [...] }`
- **Content/Extension:** JSONB object format: `{ "key": "value" }`
