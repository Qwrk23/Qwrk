# Instruction Pack — {{workspace_display_name}}

**Purpose:** Reference guide for Qwrk Gateway operations in this workspace.
**Workspace UUID:** `{{workspace_uuid}}`
**Gateway Webhook:** `{{webhook_url}}`

---

## Gateway Actions Reference

### artifact.save — Create a New Artifact

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "{{type}}",
  "title": "Your artifact title",
  "priority": 3,
  "tags": ["tag1", "tag2"],
  "summary": "Optional summary",
  "content": {},
  "extension": {}
}
```

**Required fields:** `gw_action`, `gw_workspace_id`, `artifact_type`, `title`, `priority`

**Type-specific extension fields:**
- `project`: `{ "lifecycle_stage": "seed", "operational_state": "active" }`
- `journal`: `{ "entry_text": "Journal entry text" }`
- `snapshot`: `{ "payload": { ... } }`
- `restart`: `{ "payload": { ... } }`

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
- `limit`: 1-100 (default: 20)
- `offset`: pagination offset (default: 0)
- `filters.tags_any`: `["tag1", "tag2"]` — filter by tags

**With tag filter:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "snapshot",
  "selector": {
    "limit": 10,
    "offset": 0,
    "filters": {
      "tags_any": ["governance"]
    }
  }
}
```

### artifact.update — Update an Existing Artifact

```json
{
  "gw_action": "artifact.update",
  "artifact_type": "{{type}}",
  "artifact_id": "{{artifact_uuid}}",
  "extension": {
    "field_to_update": "new_value"
  }
}
```

**Tag operations:**
```json
{
  "gw_action": "artifact.update",
  "artifact_type": "{{type}}",
  "artifact_id": "{{artifact_uuid}}",
  "tags": {
    "add": ["new-tag"],
    "remove": ["old-tag"]
  }
}
```

**Note:** `gw_workspace_id` is NOT required for updates (validated downstream).

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

---

## Allowed Artifact Types

| Type | Description | Has Extension Table |
|------|-------------|-------------------|
| `project` | Lifecycle-managed work items | Yes |
| `journal` | Private reflective entries | Yes |
| `snapshot` | Immutable payload captures | Yes |
| `restart` | Session continuation artifacts | Yes |
| `instruction_pack` | Instruction storage | Yes |
| `branch` | Execution anatomy (North Star) | No (spine-only) |
| `limb` | Execution anatomy (North Star) | Yes (shell) |
| `leaf` | Execution anatomy (North Star) | No (spine-only) |

---

## Error Codes Reference

| Code | Meaning | Common Cause |
|------|---------|-------------|
| `VALIDATION_ERROR` | Missing or invalid required field | Check payload structure |
| `WORKSPACE_FORBIDDEN` | Wrong workspace_id for this gateway | Use `{{workspace_uuid}}` |
| `ACL_FORBIDDEN` | Principal not authorized | ACL row missing or wrong principal |
| `ACTION_NOT_ALLOWED` | Invalid gw_action | Typo in action name |
| `ARTIFACT_TYPE_NOT_ALLOWED` | Invalid artifact_type | Type not in allowlist |
| `TYPE_MISMATCH` | Requested type doesn't match stored type | Check artifact_id + type combination |

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
- **Priority:** Always include `priority: 3` in saves (DB default not applied by workflow)
- **Tags:** JSONB array format: `["tag1", "tag2"]`
- **Content/Extension:** JSONB object format: `{ "key": "value" }`
