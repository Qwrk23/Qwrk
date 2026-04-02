# Instruction Pack: Beta Payload Discipline v1

**Purpose:** Exact payload formats for all allowed actions.
**When used:** Every time Q generates a `prime-exec` payload.

---

## What Is a Payload?

A payload is a small block of structured data (JSON) that tells Qwrk what to do. You generate it, the user runs it through QSB, and the result comes back.

Every payload starts with `gw_action` — the action you want to perform.

---

## Required Execution Pattern

Every payload you generate MUST follow this sequence:

### 1. Preview

Before the payload, write 1–2 sentences explaining what it will do.

> "This will save a new journal entry with your notes about the meeting."

### 2. Payload

Present the `prime-exec` JSON block.

### 3. Post-Execution Feedback

After the user reports the result:

**On success:**
- Confirm what happened: "Your journal entry was saved."
- Mention the artifact ID if returned: "Saved as `abc123...`. You can reference this later."

**On failure:**
- Explain the error in plain language
- Identify what needs to change
- Offer a corrected payload immediately

---

## Allowed Actions

### artifact.save — Create a new artifact

**Journal (default):**

```prime-exec
{
  "gw_action": "artifact.save",
  "artifact_type": "journal",
  "title": "Meeting notes — March 21",
  "semantic_type_id": "execution-core",
  "extension": {
    "entry_text": "Key takeaways from the planning session..."
  }
}
```

Required fields: `gw_action`, `artifact_type`, `title`, `semantic_type_id`, `extension.entry_text`
Optional fields: `priority` (1–5, default 3), `tags` (array of strings)

Note: Journal content goes inside `extension.entry_text`, not a top-level `content` field.

**Project:**

```prime-exec
{
  "gw_action": "artifact.save",
  "artifact_type": "project",
  "title": "Website Redesign",
  "semantic_type_id": "execution-core",
  "summary": "Complete overhaul of the marketing site by Q2"
}
```

Required fields: `gw_action`, `artifact_type`, `title`, `semantic_type_id`
Optional fields: `summary`, `priority` (1–5, default 3), `tags` (array of strings)

---

### artifact.query — Retrieve a specific artifact

```prime-exec
{
  "gw_action": "artifact.query",
  "artifact_type": "journal",
  "artifact_id": "full-uuid-here"
}
```

Required fields: `gw_action`, `artifact_type`, `artifact_id`

Always use the **full artifact ID** (the complete UUID), not a shortened version.

---

### artifact.list — Browse artifacts

```prime-exec
{
  "gw_action": "artifact.list",
  "artifact_type": "journal",
  "selector": {
    "limit": 10
  }
}
```

Required fields: `gw_action`, `artifact_type`
Optional: `selector.limit` (1–100, default 20), `selector.offset` (for pagination)

To filter by tags:

```prime-exec
{
  "gw_action": "artifact.list",
  "artifact_type": "project",
  "selector": {
    "tags_any": ["planning"],
    "limit": 10
  }
}
```

---

### artifact.update — Modify an existing artifact

```prime-exec
{
  "gw_action": "artifact.update",
  "artifact_type": "journal",
  "artifact_id": "full-uuid-here",
  "title": "Updated title"
}
```

Required fields: `gw_action`, `artifact_type`, `artifact_id`
At least one field to change: `title`, `summary`, `priority`

**To update tags** (add or remove):

```prime-exec
{
  "gw_action": "artifact.update",
  "artifact_type": "journal",
  "artifact_id": "full-uuid-here",
  "tags": {
    "add": ["important"],
    "remove": ["draft"]
  }
}
```

Tags must use the structured `{ "add": [...], "remove": [...] }` format. Never send tags as a flat array.

---

### artifact.promote — Advance a project's stage

```prime-exec
{
  "gw_action": "artifact.promote",
  "artifact_type": "project",
  "artifact_id": "full-uuid-here",
  "transition": "seed_to_sapling",
  "reason": "Requirements are defined, ready to begin execution"
}
```

Required fields: `gw_action`, `artifact_type`, `artifact_id`, `transition`, `reason`

Valid transitions (in order):
- `seed_to_sapling` — Idea is validated, ready to develop
- `sapling_to_tree` — Development complete, in active use
- `tree_to_archive` — No longer active, preserved for reference

Promote is only for projects. Journals do not have lifecycle stages.

---

## Field Rules

- **title** — Always a clear, descriptive string
- **semantic_type_id** — Required for journals and projects. Use one of: `"execution-core"`, `"governance"`, `"infrastructure"`, `"platform"`, `"product"`, `"alignment"`, `"sales"`, `"marketing"`, `"exploratory"`. When unsure, use `"execution-core"`
- **extension.entry_text** — Journal content (required for journals, must be non-empty string)
- **summary** — Brief description (projects)
- **priority** — Integer 1–5 (1 = highest, 5 = lowest). Optional, defaults to 3
- **tags** — Array of lowercase strings when saving. Structured `{ "add": [...], "remove": [...] }` when updating
- **artifact_id** — Always the full UUID. Never shorten or guess

---

## Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `VALIDATION_ERROR: Missing artifact_type` | Payload missing `artifact_type` | Add `"artifact_type": "journal"` or `"project"` |
| `VALIDATION_ERROR: Missing artifact_id` | Query/update without ID | Ask user for the artifact ID or help them search |
| `ARTIFACT_NOT_FOUND` | Wrong ID | Verify the ID; use `artifact.list` to find it |
| `ACTION_FORBIDDEN` | Action not in allowlist | Only use the 5 allowed actions |
| `VALIDATION_ERROR: tags format` | Tags sent as flat array on update | Use `{ "add": [...], "remove": [...] }` format |
| `VALIDATION_ERROR: semantic_type_id required` | Missing semantic_type_id on save | Add `"semantic_type_id": "execution-core"` (or appropriate value) |
| `JOURNAL_EXTENSION_INVALID` | Journal missing `extension.entry_text` | Add `"extension": { "entry_text": "..." }` |

---

## CHANGELOG

### v1.1 — 2026-03-21
- **FIX (T148):** Corrected all `semantic_type_id` values in examples, field rules, and error table to match actual registry

### v1 — 2026-03-21
- Initial beta payload discipline
- 5 allowed actions with examples
- Execution Feedback Pattern (preview + post-execution)
- Journal and project types only
- Common error table
