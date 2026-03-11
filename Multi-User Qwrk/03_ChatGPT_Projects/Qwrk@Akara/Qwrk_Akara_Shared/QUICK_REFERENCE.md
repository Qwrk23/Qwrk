# Akara Quick Reference

## Save (JSON)

**Project (seed):**
```
{"gw_action":"artifact.save","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"project","title":"Seed - Homepage Redesign","semantic_type_id":"product","priority":3,"tags":["design","website"],"extension":{"lifecycle_stage":"seed"}}
```

**Journal:**
```
{"gw_action":"artifact.save","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"journal","title":"Design Session Notes","semantic_type_id":"alignment","priority":3,"tags":["design","notes"],"extension":{"entry_text":"Today I worked on..."}}
```

**Snapshot:**
```
{"gw_action":"artifact.save","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"snapshot","title":"Decision - Color Palette","semantic_type_id":"governance","priority":3,"tags":["for-q","design","decision"],"extension":{"payload":{"context":"...","decision":"..."}}}
```

**Restart:**
```
{"gw_action":"artifact.save","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"restart","title":"Restart - Design Sprint","semantic_type_id":"execution-core","priority":3,"tags":["restart","design"],"extension":{"payload":{"current_state":"...","next_steps":"..."}}}
```

**Important:**
* `artifact_id` is **FORBIDDEN** on save — the database generates and returns it
* `semantic_type_id` is **REQUIRED** for top-level types (project, journal, snapshot, restart) — **FORBIDDEN** for non-top-level (branch, leaf, limb, instruction_pack, twig)
* `priority` is optional (default: `3`, range 1-5)
* `tags` are recommended (2-4, lowercase)

**Registry values (9 active):** `execution-core`, `governance`, `infrastructure`, `platform`, `product`, `alignment`, `sales`, `marketing`, `exploratory`

---

## List (JSON)

```
{"gw_action":"artifact.list","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"project","selector":{"limit":10}}
```

With tag filter:
```
{"gw_action":"artifact.list","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"snapshot","selector":{"limit":10,"filters":{"tags_any":["for-q"]}}}
```

---

## Query (JSON)

```
{"gw_action":"artifact.query","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"project","artifact_id":"[UUID]","selector":{"hydrate":true}}
```

---

## Update Tags (JSON)

```
{"gw_action":"artifact.update","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"project","artifact_id":"[UUID]","tags":{"add":["reviewed"],"remove":["draft"]}}
```

Tags MUST use `{"add": [...], "remove": [...]}` format. Flat array causes error.

---

## Spine Field Update (JSON)

```
{"gw_action":"artifact.update","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"project","artifact_id":"[UUID]","title":"New Title","summary":"Updated summary","priority":2}
```

Can combine with `tags` but NOT with `extension`.

---

## Promote (JSON)

```
{"gw_action":"artifact.promote","gw_workspace_id":"963973e0-a98c-4044-b421-71e7348eaeaf","artifact_type":"project","artifact_id":"[UUID]","transition":"seed_to_sapling","reason":"Started design work"}
```

Transitions: `seed_to_sapling`, `sapling_to_tree`, `tree_to_archive`.

---

*v1.0 (2026-03-06): Initial Akara quick reference. T94/T87/T69 aligned.*