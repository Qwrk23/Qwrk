# BUG-004 Fix Specification: instruction_pack Update Implementation

**Date:** 2026-01-27
**Status:** Planned (not implemented)
**Workflow:** NQxb_Artifact_Update_v1
**Current Version:** v10
**Target Version:** v11

---

## Problem Statement

The Update workflow (`NQxb_Artifact_Update_v1`) does not support updating `instruction_pack` artifacts. Attempting to update an instruction_pack falls through the `Switch_Type_For_Update` node with no handler.

**User Impact:** Cannot modify instruction packs from within Qwrk. For example, cannot run:
> "Qwrk - add this new shortcut to the appropriate instruction_pack"

---

## Current Architecture

### Switch_Type_For_Update (lines 226-261 in v10)

Only one branch exists:
- `project` → Prepare_Project_Extension_Update → DB_Update_Project_Extension

No branch for `instruction_pack`.

### Check_Mutability_Rules (lines 212-223 in v10)

Handles:
- `snapshot` → IMMUTABLE (rejected)
- `restart` → IMMUTABLE (rejected)
- `journal` → UNDECIDED_BLOCKED (rejected)
- `project` → Only `operational_state` and `state_reason` allowed

`instruction_pack` is not mentioned, so it passes mutability checks but then dead-ends at the Switch.

---

## Schema Reference

### Spine Table: `qxb_artifact`

| Field | Description | Mutability |
|-------|-------------|------------|
| `content` | JSON object containing actual instructions | **UPDATE_ALLOWED** |
| `title` | Pack title | UPDATE_ALLOWED (future) |
| `summary` | Pack description | UPDATE_ALLOWED (future) |

### Extension Table: `qxb_artifact_instruction_pack`

| Field | Description | Mutability |
|-------|-------------|------------|
| `scope` | Activation scope (e.g., "mode:troubleshooting") | **IMMUTABLE** |
| `active` | Boolean - enable/disable pack | **UPDATE_ALLOWED** |
| `priority` | Number - load order | **UPDATE_ALLOWED** |
| `pack_format` | Schema version (e.g., "v1") | **IMMUTABLE** |
| `workspace_id` | FK to workspace | IMMUTABLE |
| `artifact_id` | FK to spine | IMMUTABLE |

---

## Approved Mutability Rules for instruction_pack

```
instruction_pack Mutability Registry:
├── content (spine)      → UPDATE_ALLOWED
├── active (extension)   → UPDATE_ALLOWED
├── priority (extension) → UPDATE_ALLOWED
├── scope (extension)    → IMMUTABLE
└── pack_format (ext)    → IMMUTABLE
```

**Rationale:**
- `content`: Must be mutable so Qwrk can add/modify instructions (shortcuts, rules, etc.)
- `active`: Toggle packs on/off without deleting
- `priority`: Change load order for debugging/tuning
- `scope`: Immutable because changing scope fundamentally changes when the pack activates
- `pack_format`: Immutable because it defines the schema version

---

## Implementation Plan

### Step 1: Update Check_Mutability_Rules

Add instruction_pack handling after the journal block (~line 180):

```javascript
// RULE: instruction_pack - allow content, active, priority updates
if (artifact_type === 'instruction_pack') {
  const extension = normalizeNode.extension || {};
  const allowedExtFields = ['active', 'priority'];
  const immutableExtFields = ['scope', 'pack_format'];

  // Check for immutable extension fields
  const providedExtFields = Object.keys(extension);
  const blockedFields = providedExtFields.filter(f => immutableExtFields.includes(f));

  if (blockedFields.length > 0) {
    return [{
      json: {
        ok: false,
        _gw_route: "error",
        error: {
          code: "IMMUTABILITY_ERROR",
          message: `Fields are immutable for instruction_pack: ${blockedFields.join(', ')}`,
          details: {
            blocked_fields: blockedFields,
            artifact_type: 'instruction_pack',
            artifact_id: existing.artifact_id,
            registry_rule: 'IMMUTABLE',
            source: 'Mutability Registry v1',
          },
        },
      },
    }];
  }

  // Note: content updates are on spine, handled separately
}
```

### Step 2: Add instruction_pack Branch to Switch_Type_For_Update

Add new condition to the Switch node:
```json
{
  "leftValue": "={{ $json.artifact_type }}",
  "rightValue": "instruction_pack",
  "operator": { "type": "string", "operation": "equals" }
}
```

### Step 3: Create Prepare_Instruction_Pack_Update Node

```javascript
// NQxb_Artifact_Update_v1__Prepare_Instruction_Pack_Update
// Extract allowed fields for instruction_pack UPDATE

const normalizeNode = $json._normalized_request;
const extension = normalizeNode.extension || {};
const content = normalizeNode.content || null; // From spine

const updateSpine = content !== null;
const updateExt = 'active' in extension || 'priority' in extension;

return [{
  json: {
    artifact_id: $json.artifact_id,
    workspace_id: $json.workspace_id,

    // Spine update (content)
    _update_spine: updateSpine,
    _spine_content: content,

    // Extension update (active, priority)
    _update_extension: updateExt,
    _ext_active: extension.active,
    _ext_priority: extension.priority,
    _has_active: 'active' in extension,
    _has_priority: 'priority' in extension,
  }
}];
```

### Step 4: Create DB_Update_Spine_Content Node (Conditional)

**New capability**: Update `qxb_artifact.content` for the artifact.

Use HTTP Request to PostgREST (similar to BUG-001 fix) or Supabase node:
- Table: `qxb_artifact`
- Filter: `artifact_id = {{artifact_id}}`
- Update: `content = {{_spine_content}}`

### Step 5: Create DB_Update_Instruction_Pack_Extension Node

Use Supabase node:
- Table: `qxb_artifact_instruction_pack`
- Filter: `artifact_id = {{artifact_id}}`
- Update: `active`, `priority` (only if provided)

### Step 6: Wire Nodes Together

```
Switch_Type_For_Update
  └── instruction_pack branch
        └── Prepare_Instruction_Pack_Update
              ├── [If _update_spine] → DB_Update_Spine_Content
              └── [If _update_extension] → DB_Update_Instruction_Pack_Extension
                    └── Prepare_Query_Call → Return_Update_Ack
```

### Step 7: Update Normalize_Request

Ensure `content` field is extracted from the request for instruction_pack updates:

```javascript
// For instruction_pack, also capture content for spine update
if (artifact_type === 'instruction_pack') {
  canonical.content = req.content ?? null;
}
```

---

## Request/Response Examples

### Example Request: Add Shortcut

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-...",
  "artifact_type": "instruction_pack",
  "artifact_id": "abc123-...",
  "content": {
    "scope": "global",
    "shortcuts": {
      "wsy": "what say you? (asking for your opinion)"
    }
  }
}
```

### Example Request: Disable Pack

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-...",
  "artifact_type": "instruction_pack",
  "artifact_id": "abc123-...",
  "extension": {
    "active": false
  }
}
```

### Example Response

```json
{
  "ok": true,
  "gw_action": "artifact.update",
  "operation": "UPDATE",
  "artifact_id": "abc123-...",
  "artifact_type": "instruction_pack",
  "gw_workspace_id": "be0d3a48-...",
  "updated_fields": ["content"],
  "_kgb": {
    "status": "UPDATE_CONFIRMED"
  }
}
```

---

## Testing Checklist

- [ ] Update content only → spine updated, extension unchanged
- [ ] Update active only → extension updated, spine unchanged
- [ ] Update priority only → extension updated, spine unchanged
- [ ] Update content + active + priority → both tables updated
- [ ] Attempt to update scope → IMMUTABILITY_ERROR
- [ ] Attempt to update pack_format → IMMUTABILITY_ERROR
- [ ] Update non-existent artifact → NOT_FOUND error

---

## Notes

- This fix introduces a new capability: updating spine fields (content) from the Update workflow. Previously, only extension fields were updated.
- The spine update uses the same artifact_id filter as extension updates.
- Content updates should be **merged** not replaced (PATCH semantics). Implementation should deep-merge the provided content with existing content unless full replacement is explicitly requested.

---

**End of specification.**
