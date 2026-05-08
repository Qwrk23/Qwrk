# Instruction Pack — Gardenomicon v1

> Plant-care memory and reference capability for Qwrk.

---

## 1. Purpose

Gardenomicon is a personal plant memory and reference system inside Qwrk. It provides structured storage and retrieval of plant care knowledge so users can quickly look up and maintain care requirements for their plants.

**Gardenomicon IS:**
- A personal plant memory / reference system
- A structured retrieval layer for plant care knowledge

**Gardenomicon is NOT:**
- A diagnosis engine
- A reminder or scheduling system
- An automation workflow
- A general horticultural expert system
- An image analysis tool
- An external plant database integration

---

## 2. Plant Record Model

- One plant = one `journal` artifact
- Each plant record is parented under the Gardenomicon project (container)
- The Gardenomicon container is a `project` artifact with standard lifecycle (seed > sapling > tree)

### Container

The Gardenomicon project UUID must be established when the container is first created. All plant records reference it via `parent_artifact_id`.

### Tagging

All plant records MUST include:
- `gardenomicon` — membership marker (required on every plant record)

Optional filterable tags (controlled namespace):
- `gdn:light:low`
- `gdn:light:medium`
- `gdn:light:bright-indirect`
- `gdn:light:direct`
- `gdn:indoor` / `gdn:outdoor`

---

## 3. Canonical Content Keys

Plant care data lives in spine `content` (JSONB). Use these exact keys. Do not invent alternatives.

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `quick_care` | string | YES | One-line care summary for fast retrieval |
| `aliases` | array of strings | no | Common names, nicknames, shorthand |
| `location` | string | no | Where the plant lives (room, window, outdoor area) |
| `light` | string | YES | Controlled vocabulary (see below) |
| `watering` | string | YES | Free text — frequency, method, signs |
| `soil` | string | no | Soil composition / mix |
| `fertilizer` | string | no | Fertilizer type, frequency, seasonal notes |
| `notes` | string | no | Anything else — observations, history, quirks |

### Spine Field Mapping

- `title` = plant display name (e.g., "Snake Plant")
- `summary` = botanical name if known (e.g., "Sansevieria trifasciata")
- `content` = structured JSONB per table above
- `tags` = `["gardenomicon"]` + optional `gdn:*` tags

Do NOT duplicate `title` or `summary` inside `content`.

---

## 4. Controlled Vocabulary

### Light

Use exactly one of:
- `low`
- `medium`
- `bright-indirect`
- `direct`

Do not invent variations. If a plant has mixed needs, use the primary requirement and clarify in `notes`.

---

## 5. Retrieval Behavior

When a user asks about a plant:

1. **Answer with `quick_care` first** — this is the headline
2. Then provide supporting detail from `light`, `watering`, `soil`, `fertilizer` as relevant
3. Use `aliases`, `title`, and `summary` (botanical name) to resolve which plant the user means
4. If the match is ambiguous, ask — do not guess

Prefer exact match on `title`, then `aliases`, then fallback to partial or semantic match.

**Prefer clarity and usefulness over dumping raw fields.** Conversational tone, not a data readout.

### Lookup Flow

1. `artifact.list` with `tags: "gardenomicon"` — returns all plant spines
2. Match on `title` / `aliases` / `summary`
3. `artifact.query` on matched `artifact_id` for full detail
4. Present `quick_care` first, then expand as needed

---

## 6. Save Behavior

When saving a new plant record, the payload must follow journal rules:

- `gw_action`: `artifact.save`
- `artifact_type`: `journal`
- `parent_artifact_id`: Gardenomicon project UUID
- `title`: plant display name
- `summary`: botanical name (or omit if unknown)
- `tags`: `["gardenomicon"]` + optional `gdn:*` tags
- `semantic_type_id`: `exploratory`
- `extension.entry_text`: `"Gardenomicon plant record"` (required for journal saves)

`extension.entry_text` is a required journal field but is not used for plant data. All plant care data must live exclusively in `content`.

- `content`: structured JSONB per Canonical Content Keys

**Do NOT omit `quick_care`, `light`, or `watering`.** If the user hasn't provided them, ask before saving.

---

## 7. Update Behavior

- **Current truth** lives in structured `content` JSONB
- Updates use T140 `content` mode (full object replacement)
- Read current content, modify changed fields, write back the full object
- `content_append` may be used later for timestamped observations (e.g., "Repotted 2026-04-09") but is not required at MVP
- Always write the full content object — no partial updates

---

## 8. MVP Boundary

Do NOT build, suggest, or imply:
- Watering reminders or schedules
- Seasonal intelligence or calendar-based adjustments
- Plant health diagnosis
- Image or photo analysis
- External plant database lookups or integrations
- Automation workflows

If a user asks for these, acknowledge the idea and note it as a future possibility. Do not attempt to deliver.

---

*CHANGELOG: v1 (2026-04-09): Initial. Gardenomicon plant-care memory capability for Qwrk. MVP scope: structured journal records, controlled vocabulary, retrieval-first behavior.*
