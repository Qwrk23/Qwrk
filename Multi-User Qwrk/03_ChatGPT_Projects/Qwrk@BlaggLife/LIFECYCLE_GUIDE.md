# Qwrk Project Lifecycle Guide

Projects in Qwrk follow a "grow" metaphor, progressing through stages as they mature.

---

## The Four Stages

### 1. Seed
**What it means:** An idea, concept, or potential initiative
**Entry criteria:** Just created
**Typical activities:**
- Initial brainstorming
- Capturing the core concept
- Early exploration

**Example:** "I have an idea for a new feature"

---

### 2. Sapling
**What it means:** Active development has begun
**Entry criteria:** Committed to pursuing, work has started
**Typical activities:**
- Building MVP/prototype
- Active development
- Regular iteration

**Promotion trigger:** "We're going to build this" or "Development started"

---

### 3. Tree
**What it means:** Core functionality complete, in active use
**Entry criteria:** Usable product/feature exists
**Typical activities:**
- Refinement and polish
- User feedback integration
- Bug fixes and improvements

**Promotion trigger:** "MVP is working" or "Feature shipped"

---

### 4. Archive
**What it means:** Completed or deprecated
**Entry criteria:** No longer actively developed
**Typical activities:**
- Historical reference
- Lessons learned captured
- May inform future projects

**Promotion trigger:** "Project complete" or "Deprecated - replaced by X"

---

## Promotion Commands (JSON)

```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "b4e7f648-96d5-44a7-80b9-c39cac4efbd1",
  "artifact_type": "project",
  "artifact_id": "[UUID from prior query]",
  "transition": "seed_to_sapling",
  "reason": "Development started"
}
```

The Gateway will:
1. Find the project by artifact_id
2. Verify current stage allows the transition
3. Execute the promotion
4. Return the updated artifact

---

## Valid Transitions

| From | To | Transition Value | Typical Reason |
|------|-----|-----------------|----------------|
| seed | sapling | `seed_to_sapling` | "Starting development" |
| sapling | tree | `sapling_to_tree` | "MVP complete" |
| tree | archive | `tree_to_archive` | "Project completed" |

**Note:** You cannot skip stages or go backwards. Each transition is recorded in the event log.

---

## Content Mutability by Stage (T140)

| Stage | `content` (merge/replace) | `content_append` | Tags/Spine |
|-------|--------------------------|-------------------|------------|
| Seed | Mutable types only | Immutable types only | Allowed |
| Sapling | Mutable types only | Immutable types only | Allowed |
| Tree | Mutable types only | Immutable types only | Allowed (title frozen) |
| Archive | **BLOCKED** | **BLOCKED** | **BLOCKED** |

Archive = fully frozen. No content mutations of any kind.

---

## Best Practices

1. **Don't rush promotions** - Let projects earn their stage
2. **Document the "why"** - Add a journal entry when promoting
3. **Seeds are cheap** - Create many, promote few
4. **Archive thoughtfully** - Capture lessons before archiving

---

## Tracking Project Progress

To see all projects:
```json
{"gw_action":"artifact.list","gw_workspace_id":"b4e7f648-96d5-44a7-80b9-c39cac4efbd1","artifact_type":"project","selector":{"limit":20}}
```

To see a specific project's details:
```json
{"gw_action":"artifact.query","gw_workspace_id":"b4e7f648-96d5-44a7-80b9-c39cac4efbd1","artifact_type":"project","artifact_id":"[UUID]","selector":{"hydrate":true}}
```

The extension will show current `lifecycle_stage`.

---

*CHANGELOG: v3 (2026-03-26): Added Content Mutability by Stage table (T140) — archive freeze covers content and content_append. Previous: `Archive/LIFECYCLE_GUIDE__v2__2026-03-26.md`. v2 (2026-02-18): Removed "Oak" stage (not in canonical lifecycle — stages are seed/sapling/tree/archive). Replaced Telegram NL promote commands with JSON Gateway payloads. Replaced "Telegram bot" references with "Gateway". Added JSON list/query examples. Previous version: included 5 stages and Telegram command syntax.*
