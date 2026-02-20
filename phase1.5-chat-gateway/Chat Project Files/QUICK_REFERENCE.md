# Qwrk Quick Reference Card

## Execution Doctrine

All execution uses JSON Gateway payloads. Surface does not matter.

---

## Raw JSON Invariant (Non-Negotiable)

* **RAW JSON ONLY** — output must start with `{` and end with `}`
* **NO** markdown fences, comments, labels, headings, or prose
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
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"journal","title":"X","priority":3,"tags":["tag1","tag2"],"extension":{"entry_text":"content"}}
```

**Project:**
```
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","title":"Seed - X","priority":3,"tags":["seed","topic"],"extension":{"lifecycle_stage":"seed"}}
```

**Snapshot:**
```
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"snapshot","title":"Decision - X","priority":3,"tags":["decision","for-q"],"extension":{"payload":{"context":"...","decision":"..."}}}
```

**Restart:**
```
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"restart","title":"Restart - X","priority":3,"tags":["restart","topic"],"extension":{"payload":{"current_state":"...","next_steps":"..."}}}
```

**Important:**
* `artifact_id` is **FORBIDDEN** on save — the database generates and returns it
* `priority` is **REQUIRED** (default: `3`)
* `tags` are **REQUIRED** (2-4, lowercase)

---

## List (JSON)

```
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"journal","selector":{"limit":10}}
```

With tag filter:
```
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"snapshot","selector":{"limit":10,"filters":{"tags_any":["for-q"]}}}
```

With pagination:
```
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":10,"offset":10}}
```

---

## Query (JSON)

```
{"gw_action":"artifact.query","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"journal","artifact_id":"[UUID]","selector":{"hydrate":true}}
```

---

## Update (JSON)

**Tag update:**
```
{"gw_action":"artifact.update","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"[UUID]","tags":{"add":["new-tag"],"remove":["old-tag"]}}
```

**Extension update:**
```
{"gw_action":"artifact.update","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"[UUID]","extension":{"operational_state":"active"}}
```

`tags` and `extension` are top-level fields — no `changes` wrapper.

---

## Promote (JSON)

```
{"gw_action":"artifact.promote","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"[UUID]","transition":"seed_to_sapling","reason":"Development started"}
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

## Best Practice: Companion Journal Pattern (Strongly Recommended)

Projects are for lifecycle tracking. Journals are for content.

**Step 1 — Create the project (save payload):**
```
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","title":"Seed - [NAME]","priority":3,"tags":["seed","topic"],"extension":{"lifecycle_stage":"seed"}}
```

**Step 2 — Save the rich content separately (after getting artifact_id from step 1):**
```
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"journal","title":"[NAME] - Initial Thinking","priority":3,"tags":["seed","topic","companion"],"extension":{"entry_text":"Full context, background, initial exploration..."}}
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

*CHANGELOG: v2.1 (2026-02-20): Fixed Update payload structure — removed incorrect `changes` wrapper. `tags` and `extension` are top-level fields per Gateway Normalize_Update_Request (Update v12). Added extension update example. v2 (2026-02-18): Removed Session Surface Declaration and all Telegram NL sections. Unified to JSON-only execution. Added Query, Update, Promote JSON examples. Added `priority` field to all save examples. Previous version: pre-unification (this is a full rewrite).*
