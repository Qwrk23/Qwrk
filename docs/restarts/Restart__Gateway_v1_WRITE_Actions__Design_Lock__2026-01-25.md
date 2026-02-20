# RESTART — Gateway v1 WRITE Actions (Design Lock & Usability Mapping)
**Date:** 2026-01-25 (CST)
**Parent Project:** KGB Promote Proof – Fresh Seed (Init lifecycle_status)
**parent_project_id:** `7a0492cb-7fc5-4bca-b29c-17040803ddd7`

---

## Why this Restart Exists

This restart freezes the **design-level decisions** for Gateway v1 WRITE actions (`artifact.save`, `artifact.update`, `artifact.promote`) before any workflow edits or enforcement changes are made.

Goals:
- Lock semantics and invariants
- Align usability ("human verbs") with strict Gateway enforcement
- Prevent re-litigation and drift
- Provide a durable reference for future workflow guards + contract tests

**Scope:** Design truth only — no implementation in this record.

---

## Decisions Locked (Authoritative)

### 1) Write action separation (non-overlapping)

- **`artifact.save`**
  - **CREATE ONLY**
  - `artifact_id` is **forbidden**
  - Establishes initial state only
  - No "update via save" behavior

- **`artifact.update`**
  - **UPDATE ONLY**
  - Requires `artifact_id`
  - Restricted to allow-listed mutable fields
  - Kernel v1: only **project** is mutable (operational axis only)
  - Lifecycle mutation is forbidden

- **`artifact.promote`**
  - **LIFECYCLE ONLY**
  - Applies to **project** only
  - Requires valid transition key
  - Snapshot creation is mandatory and atomic with the transition

**Rule:** No shortcuts; no overlap; no exceptions.

---

### 2) Lifecycle & history invariants (re-confirmed)

- Lifecycle changes occur **only** via `artifact.promote`
- Snapshots are:
  - lifecycle-only
  - immutable
  - never ad-hoc
- Restarts are:
  - manual/ad-hoc
  - immutable
  - "freeze + next step"
  - do **not** change lifecycle
- Operational state is separate from lifecycle; operational edits do not require snapshots

---

### 3) Usability model (human-first, contract-safe)

Humans should interact using **verbs**, not gateway action names:

- "Create" → `artifact.save`
- "Edit status/details" → `artifact.update`
- "Advance lifecycle" → `artifact.promote`
- "Freeze + handoff" → `artifact.save` (`artifact_type=restart`)

**Client/agent layer responsibility:** map user intent to correct action.
**Gateway responsibility:** strict validation + deterministic refusal.

---

### 4) Explicit non-decisions (deferred on purpose)

Out of scope for this restart (still undecided):
- Journal mutability policy
- Soft delete/archive semantics (`deleted_at` handling)
- Actor identity modeling in promote events
- Branch/Limb/Leaf execution anatomy build-out

---

## What This Restart Is NOT

- Not a snapshot (no lifecycle transition occurred)
- Not implementation or workflow edits
- Not enabling writes
- Not authorizing CC execution

---

## Next Steps (Gated path: Design → Build)

1) Use this restart as the single reference for:
   - Gateway write enforcement (save/update/promote)
   - refusal cases
   - contract tests
   - frontend/agent instruction mapping

2) When entering build mode:
   - update Gateway workflows to enforce these rules
   - extend KGB test pack to cover all write paths
   - optionally create an instruction_pack to encode "verb → action" mapping

3) Any deviation requires a versioned update + a new restart/snapshot as appropriate.

---

## Suggested Restart

**When to resume:** When ready to implement write action enforcement in Gateway workflows.

**How to resume:** Reference this restart as the authoritative design lock, then proceed with workflow updates.

---

*Source: Qwrk Restart (to be saved when writes are enabled)*
