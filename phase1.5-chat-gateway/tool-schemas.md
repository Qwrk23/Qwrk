# Tool Schemas for Qwrk Chat Gateway AI Agent

**Version:** 1.0
**Created:** 2026-01-29

---

## Overview

These tool definitions tell the AI Agent how to construct Gateway payloads. In n8n, these are configured as "Tools" attached to the AI Agent node.

---

## Tool 1: artifact_query

**Description:** Retrieve a specific artifact by its ID. Returns full artifact details including extension data.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| artifact_type | string | Yes | Type: project, journal, snapshot, restart, instruction_pack |
| artifact_id | string | Yes | UUID of the artifact to retrieve |

**Output Schema:**
```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "{{artifact_type}}",
  "artifact_id": "{{artifact_id}}"
}
```

---

## Tool 2: artifact_list

**Description:** List artifacts of a specific type. Supports pagination and filtering.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| artifact_type | string | Yes | Type: project, journal, snapshot, restart, instruction_pack |
| limit | number | No | Max results (1-100, default 10) |
| offset | number | No | Skip N results (for pagination) |
| hydrate | boolean | No | Include extension data (default false) |

**Output Schema:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "{{artifact_type}}",
  "selector": {
    "limit": "{{limit || 10}}",
    "offset": "{{offset || 0}}",
    "hydrate": "{{hydrate || false}}"
  }
}
```

---

## Tool 3: artifact_save

**Description:** Create a new artifact. Different artifact types require different fields.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| artifact_type | string | Yes | Type: project, journal, snapshot, restart, instruction_pack |
| title | string | Yes | Title of the artifact |
| summary | string | No | Short description |
| content | string | No | Main content/body text |
| tags | array | No | Array of tag strings |
| lifecycle_stage | string | No | For projects: seed, sapling, tree |
| entry_text | string | No | For journals: the journal entry text |

**Output Schema (Project):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "7097c16c-ed88-4e49-983f-1de80e5cfcea",
  "artifact_type": "project",
  "title": "{{title}}",
  "summary": "{{summary}}",
  "content": {},
  "extension": {
    "lifecycle_stage": "{{lifecycle_stage || 'seed'}}"
  }
}
```

**Output Schema (Journal):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "7097c16c-ed88-4e49-983f-1de80e5cfcea",
  "artifact_type": "journal",
  "title": "{{title}}",
  "summary": "{{summary}}",
  "extension": {
    "entry_text": "{{entry_text || content}}"
  }
}
```

---

## Tool 4: artifact_update

**Description:** Update an existing artifact. Only certain fields can be updated.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| artifact_type | string | Yes | Type of artifact being updated |
| artifact_id | string | Yes | UUID of artifact to update |
| operational_state | string | No | For projects: active, paused, blocked, waiting |
| state_reason | string | No | Reason for state (when blocked/waiting) |

**Output Schema:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "{{artifact_type}}",
  "artifact_id": "{{artifact_id}}",
  "extension": {
    "operational_state": "{{operational_state}}",
    "state_reason": "{{state_reason}}"
  }
}
```

---

## Tool 5: artifact_promote

**Description:** Change a project's lifecycle stage. Creates a snapshot automatically.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| artifact_id | string | Yes | UUID of project to promote |
| transition | string | Yes | One of: seed_to_sapling, sapling_to_tree, tree_to_retired |
| reason | string | No | Reason for promotion |

**Output Schema:**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "{{artifact_id}}",
  "transition": "{{transition}}",
  "reason": "{{reason}}"
}
```

---

## n8n Implementation Notes

In n8n's AI Agent node, these tools can be implemented as:

1. **Custom Code Tools** - JavaScript functions that return the payload
2. **HTTP Request Tools** - Direct calls to internal workflow webhooks
3. **Workflow Tools** - Call sub-workflows that handle each action

**Recommended approach for Phase 1.5:**
Use a single Code node after the AI Agent that takes the agent's structured output and routes to existing Gateway logic.

---

## Testing Checklist

- [ ] artifact_list returns journal list
- [ ] artifact_query returns specific artifact
- [ ] artifact_save creates journal
- [ ] artifact_save creates project
- [ ] artifact_update changes operational_state
- [ ] artifact_promote changes lifecycle
