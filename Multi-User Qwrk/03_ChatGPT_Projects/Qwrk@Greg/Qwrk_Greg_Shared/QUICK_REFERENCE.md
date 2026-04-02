# Qwrk Quick Reference Card

## Execution Doctrine

All execution uses JSON Gateway payloads.

**Desktop (QSB):** `prime-exec` marker + fenced ```json block. Default surface.
**Mobile (TG):** Raw JSON only — no marker, no fences, no commentary.

---

## Payload Object Invariant (Non-Negotiable)

> Governs the Gateway payload object. Surface rendering wraps the payload per Execution Doctrine above.

* **RAW JSON ONLY** — payload must start with `{` and end with `}`
* **NO** markdown fences, comments, labels, headings, or prose inside the payload
* **ONE payload per execution**
* If a second action depends on the first:
  1. Execute the first payload
  2. Wait for Gateway confirmation
  3. Extract the returned `artifact_id`
  4. Use that exact ID in the next payload

Never assume a save succeeded. Never invent UUIDs.

---

## Save (JSON)

**Journal:**
```
{"gw_action":"artifact.save","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"journal","title":"X","semantic_type_id":"alignment","priority":3,"tags":["tag1","tag2"],"extension":{"entry_text":"content"}}
```

**Project:**
```
{"gw_action":"artifact.save","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","title":"Seed - X","semantic_type_id":"execution-core","priority":3,"tags":["seed","topic"],"extension":{"lifecycle_stage":"seed"}}
```

**Snapshot:**
```
{"gw_action":"artifact.save","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"snapshot","title":"Decision - X","semantic_type_id":"governance","priority":3,"tags":["decision","for-q"],"extension":{"payload":{"context":"...","decision":"..."}}}
```

**Restart:**
```
{"gw_action":"artifact.save","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"restart","title":"Restart - X","semantic_type_id":"execution-core","priority":3,"tags":["restart","topic"],"extension":{"payload":{"current_state":"...","next_steps":"..."}}}
```

**Important:**
* `artifact_id` is **FORBIDDEN** on save — the database generates and returns it
* `semantic_type_id` is **REQUIRED** for top-level types (project, journal, snapshot, restart) — **FORBIDDEN** for non-top-level (branch, leaf, limb, instruction_pack, twig)
* `priority` is optional (default: `3`, range 1-5)
* `tags` are recommended (2-4, lowercase) — Q convention, not a Gateway hard requirement

**Registry values (9 active):** `execution-core`, `governance`, `infrastructure`, `platform`, `product`, `alignment`, `sales`, `marketing`, `exploratory`

---

## List (JSON)

```
{"gw_action":"artifact.list","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"journal","selector":{"limit":10}}
```

With tag filter:
```
{"gw_action":"artifact.list","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"snapshot","selector":{"limit":10,"filters":{"tags_any":["for-q"]}}}
```

With parent filter (find children of a known artifact):
```
{"gw_action":"artifact.list","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"journal","selector":{"limit":20,"parent_artifact_id":"3f3f9725-5761-4a47-8c9e-920b8a18a1bf"}}
```

With lifecycle_status filter:
```
{"gw_action":"artifact.list","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","selector":{"limit":20,"filters":{"lifecycle_status":"sapling"}}}
```

With execution_status filter:
```
{"gw_action":"artifact.list","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"branch","selector":{"limit":20,"filters":{"execution_status":"in_progress"}}}
```

With pagination:
```
{"gw_action":"artifact.list","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","selector":{"limit":20,"offset":20}}
```

**Filter caveats:**
* `tags_any` is set containment (AND) — artifact must have ALL specified tags, not any one
* All `selector.filters` fields combine with AND
* `execution_status` filter excludes NULL rows — most journals/snapshots/restarts have NULL execution_status
* `lifecycle_status` filter excludes NULL rows — non-project artifacts typically have NULL
* Pagination cap: `offset + limit + 1` must not exceed 500

**Discovery:** For structured search strategies, see `Instruction_Pack__Artifact_Discovery_Playbook__v1.md`.

---

## Query (JSON)

```
{"gw_action":"artifact.query","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"journal","artifact_id":"[UUID]","selector":{"hydrate":true}}
```

---

## Update (JSON)

**Spine-only update (title, summary, priority — T87):**
```
{"gw_action":"artifact.update","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","artifact_id":"[UUID]","title":"Updated Title","priority":2}
```

**Mixed update (spine + tags, atomic — T87):**
```
{"gw_action":"artifact.update","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","artifact_id":"[UUID]","summary":"Updated summary","tags":{"add":["reviewed"],"remove":["draft"]}}
```

**Semantic type update (dedicated path — standalone only):**
```
{"gw_action":"artifact.update","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","artifact_id":"[UUID]","extension":{"semantic_type_id":"governance","reason":"Reclassified after scope review"}}
```

**Tag update:**
```
{"gw_action":"artifact.update","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","artifact_id":"[UUID]","tags":{"add":["new-tag"],"remove":["old-tag"]}}
```

**Extension update:**
```
{"gw_action":"artifact.update","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","artifact_id":"[UUID]","extension":{"operational_state":"active"}}
```

**Content merge (T140 — mutable types, default deep merge):**
```
{"gw_action":"artifact.update","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"twig","artifact_id":"[UUID]","content":{"new_key":"value","nested":{"updated":true}}}
```

**Content replace (T140 — explicit full replacement):**
```
{"gw_action":"artifact.update","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"twig","artifact_id":"[UUID]","content":{"clean_slate":true},"content_mode":"replace"}
```

**Content append (T140 — immutable types only: snapshot, journal, restart):**
```
{"gw_action":"artifact.update","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"snapshot","artifact_id":"[UUID]","content_append":{"entries":[{"note":"supplementary context","actor":"joel"}]}}
```

`tags` and `extension` are top-level fields — no `changes` wrapper.

**Lifecycle mutability (T87):**
* `archive` projects: ALL mutations blocked (`ARCHIVE_IMMUTABLE`) — spine, extension, and tags
* `tree` projects: `title` frozen (`FIELD_FROZEN`); summary, priority, extension, tags remain mutable
* `seed`/`sapling`: fully mutable

**Content mutability (T140):**
* Mutable types (project, twig, branch, leaf, limb): `content` merge (default) or replace (`content_mode: "replace"`)
* Immutable types (snapshot, journal, restart): `content_append` only — adds entries to `append_log`
* `content` on immutable types → `CONTENT_UPDATE_NOT_ALLOWED`; `content_append` on mutable types → `CONTENT_APPEND_NOT_ALLOWED`
* `content` and `content_append` cannot be combined in one call
* `append_log` is reserved — never include in `content` payloads (`RESERVED_NAMESPACE`)
* Archived artifacts: ALL content operations blocked (`ARCHIVE_FROZEN`)
* `append_log` max: 100 entries

**Warning:** Semantic type + tags cannot be combined in one call (`MIXED_UPDATE_NOT_ALLOWED`). Spine + extension cannot be combined. Semantic type update applies only to top-level types (`SEMANTIC_TYPE_NOT_APPLICABLE` on branch/leaf/limb).

---

## Promote (JSON)

```
{"gw_action":"artifact.promote","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","artifact_id":"[UUID]","transition":"seed_to_sapling","reason":"Development started"}
```

**Valid transitions:** `seed_to_sapling`, `sapling_to_tree`, `tree_to_archive`

---

## Lifecycle Stages (Canonical)

```
seed -> sapling -> tree -> archive
```

---

## When to Use Each Artifact Type

| I want to...                          | Use      |
| ------------------------------------- | -------- |
| Capture a conversation or thinking    | Journal  |
| Track an initiative or idea           | Project  |
| Record a decision or governance state | Snapshot |
| Save where I left off                 | Restart  |

---

## Companion Journal Pattern (When Exploratory Context Exists)

Use this pattern when a journal captured exploratory thinking BEFORE you decided to create a seed. For direct seeds where intent is already clear, skip to the single-payload seed save — no companion journal needed.

Projects are for lifecycle tracking. Journals are for content.

**Step 1 — Create the project (save payload):**
```
{"gw_action":"artifact.save","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","title":"Seed - [NAME]","semantic_type_id":"execution-core","priority":3,"tags":["seed","topic"],"extension":{"lifecycle_stage":"seed"}}
```

**Step 2 — Save the rich content separately (after getting artifact_id from step 1):**
```
{"gw_action":"artifact.save","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"journal","title":"[NAME] - Initial Thinking","semantic_type_id":"alignment","priority":3,"tags":["seed","topic","companion"],"extension":{"entry_text":"Full context, background, initial exploration..."}}
```

This ensures:
* Clean lifecycle promotion (seed -> sapling -> tree)
* No loss of rich planning context
* Deterministic retrieval across sessions

---

**Rule of Thumb:**
If it needs governance, promote the project.
If it needs detail, write a journal.

---

## Workflow Patterns

Reference patterns for common artifact creation. See system instructions for core rules.

### Morning Flow

**Trigger:** Start of day reflection, gratitude, or intention-setting conversation.

**Artifact:** Journal
**Title:** `Morning Flow - [DATE]`
**Tags:** `morning-flow`, `reflection`
**Content:** Capture gratitude, priorities, energy state, and intentions.

### Strategic Discussion

**Trigger:** Extended thinking conversation about a topic, decision, or direction.

**Artifact:** Journal
**Title:** `[TOPIC] Discussion - [DATE]`
**Tags:** `discussion`, `[topic]`
**Content:** Key insights, decisions considered, reasoning captured.

### Seed Planting

**Trigger:** New initiative, project concept, or direction the user wants to track as a seed.

**Artifact:** Project (primary). Optional companion Journal only if exploratory thinking was captured first.

**Project:**
- Title: `Seed — [NAME]`
- Tags: `seed`, `[topic]`
- lifecycle_stage: `seed`
- Summary: Concise description of the idea

**Companion Journal (only when pre-existing thinking needs linking):**
- Title: `[NAME] — Initial Thinking`
- Tags: `seed`, `[topic]`, `companion`
- Content: Full context, background, initial exploration

### Navigation Snapshot (Project Map)

**Trigger:** Project promoted to sapling with execution branches/leaves, or execution tree structure changes.

**Artifact:** Snapshot
**Title:** `<Project Name> — Project Navigation Map`
**Tags:** `for-q`, `for-cc`, `navigation`
**Payload:** Project artifact_id + title + lifecycle, design snapshot pointer, full branch/limb/leaf tree with artifact_ids, builder guidance and constraints.

**Maintenance:** Update via `artifact.update` on the snapshot whenever the execution tree changes. See QPM Build Process §2.

### Decision Locked

**Trigger:** A decision has been made and should be recorded as immutable.

**Artifact:** Snapshot
**Title:** `Decision - [WHAT]`
**Tags:** `decision`, `governance`
**Payload:** Decision details, rationale, constraints considered, alternatives rejected.

### Session Restart

**Trigger:** Need to preserve conversation state for continuation.

**Artifact:** Restart
**Title:** `Restart - [CONTEXT]`
**Tags:** `restart`, `[topic]`
**Payload:** Thread inventory, decisions locked, current work, resume instructions.

See `CONVERSATION_RESTART_PROTOCOL.md` for full restart prompt generation protocol.

---

*CHANGELOG: v8 (2026-03-26): T140 Content Update — added content merge, content replace, and content_append examples. Added content mutability rules section. Previous: `Archive/QUICK_REFERENCE__v7__2026-03-26.md`. v7 (2026-03-25): Added Navigation Snapshot (Project Map) workflow pattern. Source: governance snapshot `c9cfb7e5`. Previous: `Archive/QUICK_REFERENCE__v6.1__2026-03-25.md`. v6.1 (2026-03-25): Renamed "Raw JSON Invariant" → "Payload Object Invariant" with scope clarifier (rendering vs transport). v6 (2026-03-25): Architecture refactor — absorbed WORKFLOW_PATTERNS.md content (5 patterns: Morning Flow, Strategic Discussion, Seed Planting, Decision Locked, Session Restart) into new "Workflow Patterns" section at end of file. Standalone WORKFLOW_PATTERNS.md deprecated. Previous: `Archive/QUICK_REFERENCE__v5__2026-03-25.md`. v5 (2026-03-11): Discovery support — parent_artifact_id, lifecycle_status, execution_status filter examples. v4 (2026-03-06): T87 Spine Field Routing. v3 (2026-03-03): T69 Semantic Type Registry. v2.1 (2026-02-20): Fixed Update payload structure. v2 (2026-02-18): Unified to JSON-only execution.*
