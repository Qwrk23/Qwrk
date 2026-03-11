# Instruction Pack — QSB Payload Format: PrimeExecutionObject Contract (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-06
**origin:** Qwrk Prime Sidebar (QSB) build — Chrome Extension for Gateway execution from ChatGPT

---

## Purpose

Defines the payload contract that Q must follow when preparing Gateway operations for execution via the Qwrk Prime Sidebar (QSB). QSB is a Chrome extension that runs inside ChatGPT, detects structured payloads in assistant messages, and stages them for one-click execution against the Gateway.

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
{{
  "gw_action": "artifact.save",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "journal",
  "title": "Example Title",
  "semantic_type_id": "alignment",
  "extension": {{
    "entry_text": "Content here..."
  }}
}}
````

---

## Required Keys (Non-Negotiable)

Every PrimeExecutionObject **must** have these two keys or QSB rejects it:

- `gw_action` — one of: `artifact.save`, `artifact.query`, `artifact.list`, `artifact.update`, `artifact.promote`
- `gw_workspace_id` — must be `963973e0-a98c-4044-b421-71e7348eaeaf`

---

## Action Examples

### Save a journal

```json
{{
  "gw_action": "artifact.save",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "journal",
  "title": "Design Sprint Kickoff",
  "semantic_type_id": "alignment",
  "tags": ["design", "sprint"],
  "extension": {{
    "entry_text": "Starting the homepage redesign sprint..."
  }}
}}
```

### Save a project

```json
{{
  "gw_action": "artifact.save",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "project",
  "title": "Seed - Homepage Redesign",
  "semantic_type_id": "product",
  "tags": ["ux", "homepage"],
  "extension": {{
    "lifecycle_stage": "seed"
  }}
}}
```

### Save a snapshot

```json
{{
  "gw_action": "artifact.save",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "snapshot",
  "title": "Decision - Brand Color Palette",
  "semantic_type_id": "governance",
  "tags": ["for-q", "branding", "decision"],
  "extension": {{
    "payload": {{
      "decision": "Go with warm earth tones",
      "rationale": "Better coverage for design needs"
    }}
  }}
}}
```

### Query an artifact

```json
{{
  "gw_action": "artifact.query",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "project",
  "artifact_id": "[UUID]"
}}
```

### List artifacts

```json
{{
  "gw_action": "artifact.list",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "project",
  "selector": {{
    "limit": 10
  }}
}}
```

### Update tags

```json
{{
  "gw_action": "artifact.update",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "project",
  "artifact_id": "[UUID]",
  "tags": {{
    "add": ["reviewed"],
    "remove": ["draft"]
  }}
}}
```

### Promote a project

```json
{{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "project",
  "artifact_id": "[UUID]",
  "transition": "seed_to_sapling",
  "reason": "Started design explorations"
}}
```

---

## What NOT To Do

- **No marker, no detection:** If `prime-exec` is missing, QSB ignores the message entirely
- **Do NOT split** marker and JSON across separate messages
- **Do NOT nest** the JSON inside blockquotes or other markdown containers
- **Invalid JSON is silently ignored** — ensure it parses cleanly
- **Do NOT include `artifact_id` on save** — the database generates it
- **Do NOT wrap in extra envelopes** — the JSON IS the Gateway payload
- **Do NOT use flat array for tag updates** — use `{ "add": [...], "remove": [...] }` format
- **Do NOT omit `semantic_type_id` on top-level saves** — required for project, journal, snapshot, restart
- **Do NOT include `semantic_type_id` on non-top-level saves** — forbidden for branch, leaf, limb, instruction_pack, twig

---

## Execution Flow

1. Q outputs `prime-exec` + JSON block
2. QSB detects and stages (green dot, status text shows action)
3. User reviews the staged payload in the sidebar
4. User clicks **Execute** — QSB sends to Gateway via service worker
5. QSB shows result summary card (artifact ID, type, title)
6. User can **Copy ID** or **Stage Query** to inspect the result

---

*v1 (2026-03-06): Initial Akara QSB payload format. T69/T87/T94 aligned.*