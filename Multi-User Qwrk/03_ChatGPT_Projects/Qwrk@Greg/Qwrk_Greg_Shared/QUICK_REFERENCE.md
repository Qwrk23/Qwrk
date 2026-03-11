# Greg's Qwrk Quick Reference

## Save (JSON)

**Project (seed):**
```
{"gw_action":"artifact.save","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","title":"Seed - My Idea","semantic_type_id":"execution-core","priority":3,"tags":["project","idea"],"extension":{"lifecycle_stage":"seed"}}
```

**Journal:**
```
{"gw_action":"artifact.save","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"journal","title":"Today's Thoughts","semantic_type_id":"alignment","priority":3,"tags":["reflection"],"extension":{"entry_text":"What I'm thinking about..."}}
```

**Snapshot:**
```
{"gw_action":"artifact.save","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"snapshot","title":"Decision - X","semantic_type_id":"governance","priority":3,"tags":["decision","for-q"],"extension":{"payload":{"context":"...","decision":"..."}}}
```

**Important:**
* `artifact_id` is **FORBIDDEN** on save
* `semantic_type_id` is **REQUIRED** for top-level types (project, journal, snapshot, restart)
* `priority` is optional (default: `3`, range 1-5)
* `tags` are recommended (2-4, lowercase)

**Registry values (9 active):** `execution-core`, `governance`, `infrastructure`, `platform`, `product`, `alignment`, `sales`, `marketing`, `exploratory`

---

## List / Query / Update / Promote

```
{"gw_action":"artifact.list","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","selector":{"limit":10}}
```

```
{"gw_action":"artifact.query","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","artifact_id":"[UUID]","selector":{"hydrate":true}}
```

```
{"gw_action":"artifact.update","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"snapshot","artifact_id":"[UUID]","tags":{"add":["reviewed"],"remove":["draft"]}}
```

```
{"gw_action":"artifact.promote","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","artifact_id":"[UUID]","transition":"seed_to_sapling","reason":"Started planning"}
```

Transitions: `seed_to_sapling`, `sapling_to_tree`, `tree_to_archive`.

---

*v1.0 (2026-03-10): Initial Greg quick reference. T94/T87/T69 aligned.*
