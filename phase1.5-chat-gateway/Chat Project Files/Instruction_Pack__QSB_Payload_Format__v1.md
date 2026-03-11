# Instruction Pack — QSB Payload Format: PrimeExecutionObject Contract (v1)

**artifact_id:** `78855749-d9d0-4cc1-b28d-2e0e47eb6d4b`
**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-02-23
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
  "extension": {
    "entry_text": "Today's session covered..."
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

### Update an artifact

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "<uuid>",
  "tags": ["updated-tag"]
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

### v1 — 2026-02-23
- Initial version
- Covers all 5 Gateway actions: save, query, list, update, promote
- Detection rules: `prime-exec` marker + fenced JSON block
- Workspace IDs for Personal and Work
