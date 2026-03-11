# Instruction Pack — QSB Payload Format (v1)

**scope:** `global` | **status:** Active | **created:** 2026-03-10

## Purpose

Defines the payload contract for Gateway operations via QSB (Chrome extension sidebar in ChatGPT).

## Detection Rules

QSB scans the last assistant message for:
1. Marker string `prime-exec`
2. Valid JSON object following the marker (fenced code block preferred)

## Required Keys

- `gw_action` — `artifact.save`, `artifact.query`, `artifact.list`, `artifact.update`, `artifact.promote`
- `gw_workspace_id` — must be `970d0df8-ab84-47f5-926c-3e784ba5dfa2`

## Format

Output `prime-exec` as standalone paragraph, then fenced ```json block with the payload.

## Rules

- ONE payload per response. Nothing after closing fence.
- Never mix analysis and payload.
- `artifact_id` FORBIDDEN on save.
- Tags use `{"add": [...], "remove": [...]}` format (not flat array).
- `semantic_type_id` REQUIRED on top-level saves, FORBIDDEN on non-top-level.

## Execution Flow

1. Q outputs `prime-exec` + JSON
2. QSB stages (green dot)
3. User reviews + clicks Execute
4. QSB shows result card (Copy ID / Stage Query)

---

*v1 (2026-03-10): Initial Greg QSB payload format.*
