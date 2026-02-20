# AAA_New_Qwrk — Snapshot — artifact.promote KGB

---

## 1. Snapshot Header

| Field | Value |
|-------|-------|
| Date | 2026-01-17 |
| Scope | artifact.promote |
| Status | KGB |
| Kernel | Gateway v1 |

---

## 2. Objective

### What artifact.promote Is Responsible For

- Advancing an artifact through its lifecycle stages
- Mutating `qxb_artifact.lifecycle_status` (the canonical lifecycle field)
- Appending a `lifecycle_promote` event to `qxb_artifact_event`
- Enforcing valid lifecycle transitions (e.g., `seed → sapling`)

### Why This Snapshot Exists

This snapshot records the Known-Good Baseline state of `artifact.promote` after resolving critical execution bugs. The workflow now correctly mutates lifecycle state and appends audit events. This document serves as the authoritative reference for the locked behavior.

---

## 3. Locked Decisions

| Decision | Binding Status |
|----------|----------------|
| Lifecycle mutation occurs only via `artifact.promote` | Locked |
| Canonical lifecycle status stored on `qxb_artifact.lifecycle_status` | Locked |
| `extension.lifecycle_stage` is non-authoritative / derived / legacy | Locked |
| `artifact.update` must never mutate lifecycle | Locked |
| `lifecycle_promote` events appended to `qxb_artifact_event` | Locked |
| Event payload frozen before DB insert | Locked |
| `DB_Insert_Event` node is terminal (no downstream mutation of insert data) | Locked |
| `actor_user_id` nullable for system promotes | Temporary (pending actor model decision) |

### Event Payload Structure (Frozen)

```json
{
  "event_type": "lifecycle_promote",
  "artifact_id": "<artifact_id>",
  "workspace_id": "<workspace_id>",
  "actor_user_id": null,
  "payload": {
    "transition": "<transition_key>",
    "from_state": "<previous_lifecycle_status>",
    "to_state": "<new_lifecycle_status>",
    "reason": "<optional_reason>",
    "request_id": "<request_uuid>",
    "artifact_type": "<artifact_type>",
    "gw_action": "artifact.promote"
  }
}
```

---

## 4. Known-Good Evidence

### Lifecycle Transition Verified

| Test | Result |
|------|--------|
| Transition `seed → sapling` | Succeeds |
| `qxb_artifact.lifecycle_status` updated | Confirmed |
| Query hydrate surfaces new lifecycle status | Confirmed |

### Event Append Verified

| Payload Field | Populated |
|---------------|-----------|
| `transition` | Yes |
| `from_state` | Yes |
| `to_state` | Yes |
| `reason` | Yes (or null if not provided) |
| `request_id` | Yes |
| `artifact_type` | Yes |
| `gw_action` | Yes |

### DB Insert Confirmed

- Event row present in `qxb_artifact_event`
- Payload fields intact (not stripped)
- FK constraints satisfied

---

## 5. Failure Modes Avoided

| Failure Mode | Resolution |
|--------------|------------|
| n8n merge data loss | Event payload frozen before merge nodes |
| JSON payload stripping in Supabase inserts | Payload constructed as explicit object, not passed through merge |
| FK violation on `actor_user_id` | Field made nullable; system promotes pass null |
| Response-branch contamination of insert data | `DB_Insert_Event` isolated as terminal node |
| Empty or malformed event payload | Payload shape validated before insert |

---

## 6. Out of Scope

The following are explicitly excluded from this KGB snapshot:

- Query tail behavior after promote (requires separate fix)
- Actor FK redesign (deferred to actor model decision)
- New lifecycle rules or transitions beyond `seed → sapling`
- Promote rollback or demotion semantics
- Multi-step lifecycle jumps (e.g., `seed → tree`)

---

## 7. Next Intended Work

| Item | Description |
|------|-------------|
| Fix Query tail | Query workflow must consume top-level `lifecycle_status` field correctly |
| Actor model decision | Determine long-term design for `actor_user_id` (user lookup vs. service account vs. nullable) |
| Additional transitions | Validate `sapling → tree` and `tree → retired` once Query tail is fixed |
| KGB expansion | Add promote transitions to KGB test suite |

---

**End of Snapshot**
