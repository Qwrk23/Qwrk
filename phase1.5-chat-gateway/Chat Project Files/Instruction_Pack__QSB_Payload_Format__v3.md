# Instruction Pack — QSB Payload Format: PrimeExecutionObject Contract (v3)

**artifact_id:** `78855749-d9d0-4cc1-b28d-2e0e47eb6d4b`
**scope:** `global`
**pack_version:** `v3`
**status:** Active
**created:** 2026-02-23
**updated:** 2026-03-06
**origin:** Qwrk Prime Sidebar (QSB) build — Chrome Extension for Gateway execution from ChatGPT

---

## Purpose

Defines the payload contract that Q must follow when preparing Gateway operations for execution via the Qwrk Prime Sidebar (QSB). QSB is a Chrome extension that runs inside ChatGPT, detects structured payloads in assistant messages, and stages them for one-click execution against the Gateway.

This is a Q-facing operational contract. No schema changes. No lifecycle changes. No Gateway changes.

---

## What Is QSB?

The Qwrk Prime Sidebar (QSB) is a Chrome extension injected into the ChatGPT UI. It watches assistant messages for a specific marker + JSON pattern, stages the payload in a sidebar widget, and lets Joel execute it against the Gateway with one click.

---

## Detection Rules

The QSB parser scans the **most recent assistant message** for:

1. The marker string `prime-exec` must appear in the message text
2. A valid JSON object must follow the marker — either inside a fenced code block (preferred) or as raw JSON

If both conditions are met, QSB stages the payload automatically. The status dot turns green.

---

## Required Format

Say `prime-exec` before the JSON block, then output a fenced code block:

```
prime-exec
```

````json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "title": "Example Title",
  "semantic_type_id": "alignment",
  "extension": {
    "entry_text": "Content here..."
  }
}
````

---

## Required Keys (Non-Negotiable)

Every PrimeExecutionObject **must** have these two keys or QSB rejects it:

- `gw_action` — one of: `artifact.save`, `artifact.query`, `artifact.list`, `artifact.update`, `artifact.promote`
- `gw_workspace_id` — the target workspace UUID

---

## Workspace IDs

- **Qwrk Personal:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` (default)
- **Work (Resolve):** `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`

Use Qwrk Personal unless Joel specifies otherwise.

---

## Action Examples

### Save a journal

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "title": "Session reflection",
  "semantic_type_id": "alignment",
  "extension": {
    "entry_text": "Today's session covered..."
  }
}
```

### Save a project

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "title": "New Feature Build",
  "semantic_type_id": "execution-core",
  "extension": {
    "lifecycle_stage": "seed"
  }
}
```

### Save a snapshot

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "title": "Decision — Architecture Choice",
  "semantic_type_id": "governance",
  "tags": ["for-q"],
  "extension": {
    "payload": {
      "decision": "Use REST over GraphQL",
      "rationale": "Simpler for MVP"
    }
  }
}
```

### Query an artifact

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "artifact_id": "db428a32-1afa-4e6b-a649-347b0bffd46c"
}
```

### List artifacts

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "limit": 10
  }
}
```

### Update spine fields (T87)

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<uuid>",
  "title": "Updated Project Title",
  "summary": "New project summary",
  "priority": 2
}
```

### Mixed update — spine + tags (T87)

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<uuid>",
  "summary": "Updated summary",
  "tags": {
    "add": ["reviewed"],
    "remove": ["draft"]
  }
}
```

### Update tags

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<uuid>",
  "tags": {
    "add": ["updated-tag"],
    "remove": ["old-tag"]
  }
}
```

### Update semantic type

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<uuid>",
  "extension": {
    "semantic_type_id": "governance",
    "reason": "Reclassified after scope review"
  }
}
```

### Promote a project

```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<uuid>",
  "transition": "seed_to_sapling",
  "reason": "MVP validated"
}
```

---

## What NOT To Do

- **No marker, no detection:** If `prime-exec` is missing, QSB ignores the message entirely
- **Do NOT split** marker and JSON across separate messages
- **Do NOT nest** the JSON inside blockquotes or other markdown containers
- **Invalid JSON is silently ignored** — ensure it parses cleanly
- **Do NOT include `artifact_id` on save** — the database generates it
- **Do NOT wrap in extra envelopes** — the JSON IS the Gateway payload, nothing else around it
- **Do NOT use flat array for tag updates** — use `{ "add": [...], "remove": [...] }` format
- **Do NOT omit `semantic_type_id` on top-level saves** — required for project, journal, snapshot, restart
- **Do NOT include `semantic_type_id` on non-top-level saves** — forbidden for branch, leaf, limb, instruction_pack, twig
- **Do NOT combine spine fields + extension in one call** — use separate requests (T87)
- **Do NOT update title on tree-lifecycle projects** — returns `FIELD_FROZEN` (T87)
- **Do NOT attempt any update on archived projects** — returns `ARCHIVE_IMMUTABLE` (T87)

---

## Execution Flow

1. Q outputs `prime-exec` + JSON block
2. QSB detects and stages (green dot, status text shows action)
3. Joel reviews the staged payload in the sidebar
4. Joel clicks **Execute** — QSB sends to Gateway via service worker
5. QSB shows result summary card (artifact ID, type, title)
6. Joel can **Copy ID** or **Stage Query** to inspect the result

---

## CHANGELOG

### v3 — 2026-03-06

- T87 Spine Field Routing
- New "Update spine fields" example (title/summary/priority as top-level fields)
- New "Mixed update — spine + tags" example
- "What NOT To Do" expanded: spine+extension combination, title freeze at tree, archive immutability
- Previous version: `Archive/Instruction_Pack__QSB_Payload_Format__v2__2026-03-06.md`

### v2 — 2026-03-03

- T69 Semantic Type Registry enforcement
- `semantic_type_id` added to all top-level save examples (journal, project, snapshot)
- New "Update semantic type" example added
- Tag update example corrected: flat array → structured `{ "add": [...], "remove": [...] }` format
- "What NOT To Do" section expanded with semantic_type_id and tag format rules
- Save project example added (was missing in v1)
- Previous version: `Archive/Instruction_Pack__QSB_Payload_Format__v1__2026-03-03.md`

### v1 — 2026-02-23
- Initial version
- Covers all 5 Gateway actions: save, query, list, update, promote
- Detection rules: `prime-exec` marker + fenced JSON block
- Workspace IDs for Personal and Work