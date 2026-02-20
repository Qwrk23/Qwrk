# Gateway v1 — KGB Lock Status (2026-01-17)

Gateway v1 is **feature-complete and KGB-locked** for all five core artifact actions.

This document records the authoritative behavior and constraints as of 2026-01-17.
These rules are binding unless explicitly superseded by a future KGB proof.

---

## KGB-Locked Actions

The following Gateway actions are now locked at KGB state:

- artifact.save (previously locked)
- artifact.query (previously locked)
- artifact.update (locked 2026-01-17)
- artifact.list (locked 2026-01-17)
- artifact.promote (locked 2026-01-17)

---

## artifact.update — Mutability Rules

- UPDATE-ONLY semantics enforced
- Allowed fields:
  - operational_state
  - state_reason
- lifecycle_stage:
  - PROMOTE-ONLY
  - Explicitly blocked in update
- snapshot and restart artifacts:
  - Fully immutable
- journal artifacts:
  - INSERT-ONLY
  - Updates blocked (UNDECIDED_BLOCKED)
- Response:
  - Stable acknowledgment only
  - No internal query payload returned

---

## artifact.list — Canonical Listing Contract

- Canonical response envelope:
  - ok
  - gw_action
  - data: { artifacts }
  - meta
  - timestamp
- Pagination model:
  - limit
  - offset
  - as_of anchor (deterministic reads)
- Ordering:
  - created_at DESC
  - artifact_id DESC
- meta.has_more implemented
- total_count intentionally omitted
- Superset fetch capped at 500 rows

---

## artifact.promote — Lifecycle Authority

- Lifecycle mutation allowed ONLY via promote
- Authoritative field:
  - qxb_artifact.lifecycle_status
- extension.lifecycle_stage:
  - Non-authoritative (legacy)
- Promotion effects:
  - Append-only event written to qxb_artifact_event
  - Event payload frozen at write time
- actor_user_id:
  - Nullable (temporary; actor model TBD)

---

## Pinned Proof Artifacts

- Snapshot Artifact ID:
  - 0452fab4-cb93-438c-a706-856c1841769e
- Verified Project Artifact ID:
  - e9601873-9f71-4843-bd81-9ecaccbbf9e3

---

## Deferred (Explicitly Out of Scope for v1)

- Query tail update to consume top-level lifecycle_status
- Final actor model decision for actor_user_id
- Additional lifecycle transitions (sapling → tree → retired)
- Optional enhancements:
  - meta.total_count
  - selector.sort (v1.1+)

---

## Outcome

Gateway v1 is now KGB-locked and stable for:
save, query, update, list, and promote.

No further changes are permitted without a new KGB proof.

---

## Related Documents

- `2026-01-17__KGB_Proof__Gateway_v1__artifact.update__verified.md`
- `AAA_New_Qwrk — Snapshot — Gateway v1 artifact.list KGB Lock (v1.0).md`
- `AAA_New_Qwrk__Snapshot__artifact_promote_KGB__2026-01-17.md`
- `CLAUDE.md` (v9 — contains this content inline)

---

**End of KGB Lock Status**
