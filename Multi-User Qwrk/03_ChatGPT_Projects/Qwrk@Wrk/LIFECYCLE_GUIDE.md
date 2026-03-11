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

## Mutability by Stage (T87)

What you can change at each stage:

| Stage | Title | Summary | Priority | Extension Fields | Tags | Semantic Type |
|-------|-------|---------|----------|-----------------|------|---------------|
| **Seed** | Yes | Yes | Yes | Yes | Yes | Yes |
| **Sapling** | Yes | Yes | Yes | Yes | Yes | Yes |
| **Tree** | **No** (FROZEN) | Yes | Yes | Yes | Yes | Yes |
| **Archive** | **No** | **No** | **No** | **No** | **No** | **No** |

**Key rules:**
- **Tree:** Title is locked — it represents the shipped identity. Everything else remains mutable for ongoing refinement.
- **Archive:** Fully immutable. No updates of any kind. If you need to change something, consider whether the project should be un-archived (not currently supported — create a new project instead).
- **Seed/Sapling:** Fully mutable. Rename, reprioritize, retag freely.

**Error codes:**
- Updating anything on an archived project → `ARCHIVE_IMMUTABLE`
- Updating title on a tree project → `FIELD_FROZEN`

---

## Promotion Commands (JSON)

```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
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

## Twig Lifecycle (T94)

Twigs are lightweight micro-initiatives — small experiments or explorations attached to a Limb. They have their own lifecycle, separate from the project lifecycle above.

### Twig Stages

| Stage | Meaning |
|-------|---------|
| **proposed** | Idea captured, not yet active |
| **active** | Actively being explored |
| **promoted** | Graduated to a full project or merged into parent (TERMINAL) |
| **pruned** | Abandoned or deemed not viable (TERMINAL) |

### Valid Transitions

| From | To |
|------|-----|
| proposed | active |
| active | promoted |
| active | pruned |

**Terminal states:** `promoted` and `pruned` cannot transition further.

### Twig vs Project

- Twigs do NOT use `artifact.promote` — lifecycle is managed via `artifact.update`
- Twigs have NO extension table (spine-only, like branch/leaf)
- Twigs do NOT require `semantic_type_id` (non-top-level)
- Twigs are cheap — create many, promote few

---

## Best Practices

1. **Don't rush promotions** - Let projects earn their stage
2. **Document the "why"** - Add a journal entry when promoting
3. **Seeds are cheap** - Create many, promote few
4. **Archive thoughtfully** - Capture lessons before archiving
5. **Rename before tree** - Title freezes at tree stage (T87)

---

## Tracking Project Progress

To see all projects:
```json
{"gw_action":"artifact.list","gw_workspace_id":"635bb8d7-7b93-4bea-8ca6-ee2c924c9557","artifact_type":"project","selector":{"limit":20}}
```

To see a specific project's details:
```json
{"gw_action":"artifact.query","gw_workspace_id":"635bb8d7-7b93-4bea-8ca6-ee2c924c9557","artifact_type":"project","artifact_id":"[UUID]","selector":{"hydrate":true}}
```

The extension will show current `lifecycle_stage`.

---

*CHANGELOG: v3 (2026-03-06): T87 Lifecycle Mutability — added "Mutability by Stage" section with full matrix (seed/sapling=mutable, tree=title frozen, archive=all frozen). Error codes documented. Best practice added: "Rename before tree." Previous version: `Archive/LIFECYCLE_GUIDE__v2__2026-03-06.md`. v2 (2026-02-18): Removed "Oak" stage (not in canonical lifecycle — stages are seed/sapling/tree/archive). Replaced Telegram NL promote commands with JSON Gateway payloads. Replaced "Telegram bot" references with "Gateway". Added JSON list/query examples. Previous version: included 5 stages and Telegram command syntax.*
