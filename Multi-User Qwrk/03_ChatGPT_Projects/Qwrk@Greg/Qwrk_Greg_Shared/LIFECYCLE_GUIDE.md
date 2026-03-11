# Qwrk Project Lifecycle Guide

Projects grow through stages: **Seed → Sapling → Tree → Archive**

## Stages

| Stage | Meaning | Promotion Trigger |
|-------|---------|------------------|
| **Seed** | Idea captured | Just created |
| **Sapling** | Active work begun | "Starting development" |
| **Tree** | Core complete, in use | "MVP working" |
| **Archive** | Done or deprecated | "Project complete" |

## Mutability (T87)

| Stage | Title | Summary | Priority | Extension | Tags |
|-------|-------|---------|----------|-----------|------|
| Seed/Sapling | Yes | Yes | Yes | Yes | Yes |
| Tree | **FROZEN** | Yes | Yes | Yes | Yes |
| Archive | No | No | No | No | No |

## Promote

```
{"gw_action":"artifact.promote","gw_workspace_id":"970d0df8-ab84-47f5-926c-3e784ba5dfa2","artifact_type":"project","artifact_id":"[UUID]","transition":"seed_to_sapling","reason":"Started planning"}
```

Cannot skip stages or go backwards.

---

*v1 (2026-03-10): Initial Greg lifecycle guide.*
