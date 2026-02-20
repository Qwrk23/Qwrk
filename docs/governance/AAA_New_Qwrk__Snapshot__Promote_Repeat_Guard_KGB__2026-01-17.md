# AAA_New_Qwrk — Snapshot — Promote Repeat Guard KGB

---

## Snapshot Metadata

| Field | Value |
|-------|-------|
| Snapshot artifact_id | 1130c92d-3fa1-417b-8e91-d2449b4c5487 |
| Workspace | be0d3a48-c764-44f9-90c8-e846d9dbbd0a |
| Date | 2026-01-17 |
| Phase | BUILD / EXECUTION |
| Status | KGB-LOCKED |

---

## 1. Objective

This snapshot locks the following behaviors as Known-Good Baseline:

- Canonical lifecycle handling via `qxb_artifact.lifecycle_status`
- Promote repeat-guard correctness (deterministic rejection of duplicate promotes)
- Non-empty error propagation from Promote workflow

These behaviors are now immutable. Any modification requires a new KGB proof with explicit versioning.

---

## 2. Governing Constraints

The following constraints are authoritative and binding:

| Constraint | Status |
|------------|--------|
| North Star v0.1 is authoritative | Binding |
| Kernel v1 is LOCKED | Binding |
| Canonical lifecycle lives only on `qxb_artifact.lifecycle_status` | Binding |
| Only `artifact.promote` mutates lifecycle | Binding |
| `artifact.update` must never mutate lifecycle | Binding |
| `extension.lifecycle_stage` is non-authoritative (legacy) | Binding |

---

## 3. Final Design Decisions (KGB)

### Save Path Fix

`artifact.save` initializes `qxb_artifact.lifecycle_status` using normalized `$json.lifecycle_status`.

- On INSERT: defaults to `seed`
- Ensures spine row has canonical lifecycle from creation

### Promote DB Fix

Removed `lifecycle_status = from_state` filter from `DB_Update_Lifecycle` node.

- Previous behavior: UPDATE failed silently when filter didn't match
- Fixed behavior: UPDATE targets artifact by `artifact_id` only
- Lifecycle state validation occurs in Gatekeeper before DB mutation

### Promote Gating

Switch node gates on `$json.ok`:

- Success path (`ok: true`): Mutates lifecycle + inserts event
- Failure path (`ok: false`): Returns error item only, no DB mutation

### Execution Fix

Explicit error-return node added to Promote workflow.

- Failed promotes now return JSON error body
- No empty 200 responses on failure
- Error structure includes `code`, `message`, and `details`

---

## 4. KGB Receipts

The following IDs are authoritative evidence of KGB state:

| Receipt | Value |
|---------|-------|
| Promoted artifact | `7a0492cb-7fc5-4bca-b29c-17040803ddd7` |
| First promote event | `e9280784-87ab-4429-8fef-edc0c45e4d01` |
| First promote request_id | `f059dddd-11e4-43a1-8026-5ac2e2960e7c` |
| Repeat promote request_id | `23587ff6-87b5-43e8-9177-ecc223144387` |
| Repeat promote error | `LIFECYCLE_STATE_MISMATCH` |

---

## 5. Proven Behaviors

### First Promote

- Transition: `seed → sapling`
- Result: Succeeds
- Canonical lifecycle updated in `qxb_artifact.lifecycle_status`
- Event appended to `qxb_artifact_event`

### Repeat Promote

- Transition: `seed → sapling` (attempted again)
- Result: Fails deterministically
- Error code: `LIFECYCLE_STATE_MISMATCH`
- No lifecycle mutation occurs
- No event insertion occurs
- Non-empty JSON error body returned

---

## 6. Known Non-Goals / Out of Scope

The following are explicitly excluded from this KGB snapshot:

- No new schema changes
- No actor FK redesign
- No changes to query behavior
- No lifecycle semantics beyond Promote
- No additional lifecycle transitions (sapling → tree, tree → retired)
- No rollback or demotion semantics

---

## 7. Restart Instructions

### How to Restart from Here

1. **Load this snapshot** as authoritative context for Promote + Save lifecycle behavior

2. **Treat as KGB-locked:**
   - `artifact.save` lifecycle initialization
   - `artifact.promote` lifecycle mutation
   - Promote repeat-guard logic
   - Non-empty error propagation

3. **Next safe objectives (in priority order):**
   - `artifact.update` KGB verification (if not already complete)
   - Query normalization to consume top-level `lifecycle_status`
   - Additional lifecycle transitions (`sapling → tree`, `tree → retired`)
   - Actor model decision for `actor_user_id`

4. **Do not modify:**
   - Promote Gatekeeper logic
   - Save lifecycle initialization
   - Event append behavior
   - Error return structure

5. **If changes are required:**
   - Create new KGB proof document
   - Version explicitly (v1.1, v2, etc.)
   - Reference this snapshot as baseline

---

**End of Snapshot**
