# Qwrk Quick Reference Card

## Execution Doctrine

All execution uses JSON Gateway payloads.

**Desktop (QSB):** `prime-exec` marker + fenced ```json block. Default surface.
**Mobile (TG):** Raw JSON only — no marker, no fences, no commentary.

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
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"journal","title":"X","semantic_type_id":"alignment","priority":3,"tags":["tag1","tag2"],"extension":{"entry_text":"content"}}
```

**Project:**
```
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","title":"Seed - X","semantic_type_id":"execution-core","priority":3,"tags":["seed","topic"],"extension":{"lifecycle_stage":"seed"}}
```

**Snapshot:**
```
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"snapshot","title":"Decision - X","semantic_type_id":"governance","priority":3,"tags":["decision","for-q"],"extension":{"payload":{"context":"...","decision":"..."}}}
```

**Restart:**
```
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"restart","title":"Restart - X","semantic_type_id":"execution-core","priority":3,"tags":["restart","topic"],"extension":{"payload":{"current_state":"...","next_steps":"..."}}}
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

**Spine-only update (title, summary, priority — T87):**
```
{"gw_action":"artifact.update","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"[UUID]","title":"Updated Title","priority":2}
```

**Mixed update (spine + tags, atomic — T87):**
```
{"gw_action":"artifact.update","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"[UUID]","summary":"Updated summary","tags":{"add":["reviewed"],"remove":["draft"]}}
```

**Semantic type update (dedicated path — standalone only):**
```
{"gw_action":"artifact.update","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"[UUID]","extension":{"semantic_type_id":"governance","reason":"Reclassified after scope review"}}
```

**Tag update:**
```
{"gw_action":"artifact.update","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"[UUID]","tags":{"add":["new-tag"],"remove":["old-tag"]}}
```

**Extension update:**
```
{"gw_action":"artifact.update","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"[UUID]","extension":{"operational_state":"active"}}
```

`tags` and `extension` are top-level fields — no `changes` wrapper.

**Lifecycle mutability (T87):**
* `archive` projects: ALL mutations blocked (`ARCHIVE_IMMUTABLE`) — spine, extension, and tags
* `tree` projects: `title` frozen (`FIELD_FROZEN`); summary, priority, extension, tags remain mutable
* `seed`/`sapling`: fully mutable

**Warning:** Semantic type + tags cannot be combined in one call (`MIXED_UPDATE_NOT_ALLOWED`). Spine + extension cannot be combined. Semantic type update applies only to top-level types (`SEMANTIC_TYPE_NOT_APPLICABLE` on branch/leaf/limb).

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
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","title":"Seed - [NAME]","semantic_type_id":"execution-core","priority":3,"tags":["seed","topic"],"extension":{"lifecycle_stage":"seed"}}
```

**Step 2 — Save the rich content separately (after getting artifact_id from step 1):**
```
{"gw_action":"artifact.save","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"journal","title":"[NAME] - Initial Thinking","semantic_type_id":"alignment","priority":3,"tags":["seed","topic","companion"],"extension":{"entry_text":"Full context, background, initial exploration..."}}
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

*CHANGELOG: v4 (2026-03-06): T87 Spine Field Routing — spine_only and mixed update examples added. Lifecycle mutability warnings added (archive=ALL FROZEN, tree=title FROZEN). Pointer: Canonical v3→v4. Previous version: `Archive/QUICK_REFERENCE__v3__2026-03-06.md`. v3 (2026-03-03): T69 Semantic Type Registry — `semantic_type_id` added to all 6 save examples (4 main + 2 companion journal). New semantic type update example (placed before tag/extension updates per dedicated mode priority). 9 registry values listed. `priority` corrected from REQUIRED to optional. `tags` corrected from REQUIRED to recommended. Surface routing distinction added (QSB vs TG). MIXED_UPDATE_NOT_ALLOWED and SEMANTIC_TYPE_NOT_APPLICABLE warnings added. Previous version: `Archive/QUICK_REFERENCE__v2.1__2026-03-03.md`. v2.1 (2026-02-20): Fixed Update payload structure — removed incorrect `changes` wrapper. v2 (2026-02-18): Unified to JSON-only execution.*
