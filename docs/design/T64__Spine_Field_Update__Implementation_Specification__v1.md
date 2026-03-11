# T64 — Spine-Field Update Mode: Full Implementation Specification

**Thread:** T64 — Spine-Field Update Path for Non-Project Types
**Scope:** Full (Wave 2) — Strict state machine, parent completion, concurrency, no-op detection
**Baseline:** Update sub-workflow v37 (`NQxb_Artifact_Update_v1 (17).json`), 23 nodes
**Prepared by:** CC
**Date:** 2026-03-01
**For Review by:** Manus (External Architectural Review)

---

## CHANGELOG

- **v1.1 (2026-03-01):** Added D13 certification test (child addition during parent completion window). Added operational integrity note to Section 7. Updated gating criteria D01-D13.
- **v1 (2026-03-01):** Initial specification. Full T64 implementation design for Manus review.

---

## 1. Objective

T64 adds a **spine_fields** update mode to the existing `artifact.update` Gateway action, enabling controlled mutation of `execution_status` on walk-anatomy artifact types (`branch`, `limb`, `leaf`).

**What T64 enables:**
- Strict state-machine transitions for `execution_status` on branch/limb/leaf artifacts
- Parent completion enforcement: branch and limb cannot transition to `complete` unless all direct children are `complete`
- No-op detection: identical state requests return acknowledgement without database write or version increment
- Optimistic concurrency: version-filtered PATCH prevents lost-update race conditions

**What T64 does NOT enable:**
- No new Gateway actions (uses existing `artifact.update`)
- No new artifact types
- No schema changes (execution_status already exists on spine, DDL v2.4)
- No lifecycle_status mutations (still PROMOTE_ONLY)
- No title/summary/priority mutations on walk types
- No cross-tree dependency enforcement (T71 scope)
- No rollup query changes (T70 scope)

---

## 2. Scope Boundaries

### Explicit Non-Goals

| Non-Goal | Rationale |
|----------|-----------|
| New artifact types | T64 operates on existing branch/limb/leaf only |
| Lifecycle changes | lifecycle_status is PROMOTE_ONLY per Mutability Registry |
| Schema changes | execution_status column already exists (DDL v2.4, line 159) |
| Cross-tree dependency logic | T71 (Dependency Enforcement) is a separate thread, NOT STARTED |
| Rollup query changes | T70 (Rollup Query) is a separate parallel thread |
| Combined tags + execution_status in single request | Follows existing contract: tags-only or extension-only, not both simultaneously |
| execution_status on project type | Project uses lifecycle_stage (PROMOTE_ONLY) and operational_state (UPDATE_ALLOWED) |
| execution_status on journal/snapshot/restart | These types are immutable or INSERT-ONLY per Mutability Registry |
| title, summary, priority mutation on branch/limb/leaf | Future T64 scopes (not this implementation) |

### Preserved Behaviors (No Regression)

| Behavior | Verification |
|----------|-------------|
| Tags-only updates on all types | Tags path unchanged, routed before spine_fields check |
| Project extension update (operational_state, state_reason, summary) | Project path unchanged, routed before T64 step |
| Immutability enforcement (snapshot, restart, instruction_pack) | Checked before T64 step in mutability order |
| Journal INSERT-ONLY block | Checked before T64 step in mutability order |
| Type registry validation | Unchanged, runs before spine fetch |
| Error passthrough for all existing error codes | Return_Error_Passthrough terminal unchanged |

---

## 3. Allowed Artifact Types

### Eligible Types

| Artifact Type | extension_status Mutation | Parent Check on Complete |
|--------------|--------------------------|------------------------|
| `branch` | ALLOWED | YES — must verify all direct children are `complete` |
| `limb` | ALLOWED | YES — must verify all direct children are `complete` |
| `leaf` | ALLOWED | NO — leaf is terminal; has no children |

### Rejected Types (Explicit)

| Artifact Type | Rejection Point | Error Code |
|--------------|----------------|------------|
| `project` | Check_Mutability_Rules step 6 (existing) | Routes to project extension path |
| `journal` | Check_Mutability_Rules step 4 (existing) | `JOURNAL_MUTABILITY_UNDECIDED` |
| `snapshot` | Check_Mutability_Rules step 3 (existing) | `IMMUTABILITY_ERROR` |
| `restart` | Check_Mutability_Rules step 3 (existing) | `IMMUTABILITY_ERROR` |
| `instruction_pack` | Check_Mutability_Rules step 3 (existing) | `IMMUTABILITY_ERROR` |
| `grass` | Check_Mutability_Rules step 7 fallthrough → Switch_Type_For_Update fallback | `EXTENSION_ROUTING_UNHANDLED_TYPE` |
| `thorn` | Same as grass | `EXTENSION_ROUTING_UNHANDLED_TYPE` |
| `forest` | Same as grass | `EXTENSION_ROUTING_UNHANDLED_TYPE` |
| `thicket` | Same as grass | `EXTENSION_ROUTING_UNHANDLED_TYPE` |
| `flower` | Same as grass | `EXTENSION_ROUTING_UNHANDLED_TYPE` |

**Allowlist enforcement:** Step 6.7 in Check_Mutability_Rules explicitly checks `['branch', 'limb', 'leaf']`. Any type not in this list falls through to the existing step 7 generic extension path.

---

## 4. execution_status Canonical Enum

### Allowed Values (DDL v2.4, line 170)

```sql
CONSTRAINT qxb_artifact_execution_status_check CHECK (
  (execution_status IS NULL OR
   (execution_status = ANY (ARRAY['not_started'::text, 'in_progress'::text, 'blocked'::text, 'complete'::text])))
)
```

| Value | Meaning |
|-------|---------|
| `NULL` | Never initialized (default on INSERT) |
| `not_started` | Explicitly initialized but work not begun |
| `in_progress` | Active execution |
| `blocked` | Execution paused due to impediment |
| `complete` | Terminal — execution finished |

### NULL Behavior Post-T64

- `NULL` remains valid as a starting state (artifacts created before T64 have `NULL`)
- `NULL → not_started` is the ONLY valid transition from NULL
- `NULL → NULL` is a no-op (no write)
- Setting execution_status TO `NULL` from any non-NULL state is **PROHIBITED** (NULL reset)
- T64 does NOT set execution_status on INSERT; it only mutates existing artifacts via UPDATE

### Enum Locked

These 4 values plus NULL are the complete enum. No additional values are permitted without DDL migration. The CHECK constraint is enforced at the database level.

---

## 5. Transition Matrix (Authoritative)

### Full Matrix

| From \ To | `not_started` | `in_progress` | `blocked` | `complete` | `NULL` |
|-----------|:------------:|:-------------:|:---------:|:----------:|:------:|
| **`NULL`** | ALLOWED | REJECTED | REJECTED | REJECTED | NO-OP |
| **`not_started`** | NO-OP | ALLOWED | ALLOWED | REJECTED | REJECTED |
| **`in_progress`** | REJECTED | NO-OP | ALLOWED | ALLOWED* | REJECTED |
| **`blocked`** | REJECTED | ALLOWED | NO-OP | REJECTED | REJECTED |
| **`complete`** | REJECTED | REJECTED | REJECTED | NO-OP | REJECTED |

`*` = Subject to parent completion check for branch/limb types.

### Transition Rules (Narrative)

**Forward transitions (ALLOWED):**
1. `NULL → not_started` — Initialize execution tracking. This is the only exit from NULL.
2. `not_started → in_progress` — Begin execution.
3. `not_started → blocked` — Mark blocked before work begins (valid: may be blocked by dependency or resource).
4. `in_progress → blocked` — Pause due to impediment.
5. `in_progress → complete` — Finish execution. For branch/limb: requires all direct children complete.
6. `blocked → in_progress` — Resume after impediment resolved.

**No-op transitions (same state):**
7. `NULL → NULL` — No write, no version increment. Return current state.
8. `not_started → not_started` — No write, no version increment.
9. `in_progress → in_progress` — No write, no version increment.
10. `blocked → blocked` — No write, no version increment.
11. `complete → complete` — No write, no version increment.

**Rejected transitions (INVALID_TRANSITION):**
12. `NULL → in_progress` — Must initialize via not_started first.
13. `NULL → blocked` — Must initialize via not_started first.
14. `NULL → complete` — Must initialize via not_started first.
15. `not_started → complete` — Cannot skip in_progress. Must execute before completing.
16. `in_progress → not_started` — Backward transition prohibited.
17. `blocked → not_started` — Backward transition prohibited.
18. `blocked → complete` — Cannot complete directly from blocked. Must resume (→ in_progress) first.
19. `complete → not_started` — Complete is terminal.
20. `complete → in_progress` — Complete is terminal.
21. `complete → blocked` — Complete is terminal.

**NULL reset (REJECTED — subclass of INVALID_TRANSITION):**
22. `not_started → NULL` — NULL reset prohibited.
23. `in_progress → NULL` — NULL reset prohibited.
24. `blocked → NULL` — NULL reset prohibited.
25. `complete → NULL` — NULL reset prohibited (also: complete is terminal).

### Transition Enforcement Location

All transition enforcement occurs in **Check_Mutability_Rules step 6.7** (Code node), BEFORE any database write attempt. Invalid transitions never reach the PATCH endpoint.

### Archive Behavior

If the artifact's spine `lifecycle_status` equals `'archive'`, ALL execution_status mutations are rejected with `ARCHIVE_TERMINAL`, regardless of the requested transition. This check precedes transition validation.

**Note:** For branch/limb/leaf artifacts, `lifecycle_status` is typically `NULL` (DDL CHECK on lifecycle_status is conditional: project-only). This guard activates only if future governance extends lifecycle_status to walk types, or if a walk artifact's lifecycle_status is set to `'archive'` through a future mechanism.

---

## 6. Rejection Matrix

### 6.1 VALIDATION_ERROR — Invalid Enum Value

**Trigger:** `extension.execution_status` is not one of `['not_started', 'in_progress', 'blocked', 'complete']` and is not null/undefined.

**Detection point:** Check_Mutability_Rules step 6.7, enum validation sub-step.

**Response payload:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid execution_status value: 'finished'",
    "details": {
      "field": "execution_status",
      "provided_value": "finished",
      "allowed_values": ["not_started", "in_progress", "blocked", "complete"],
      "artifact_type": "branch",
      "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
      "hint": "execution_status must be one of: not_started, in_progress, blocked, complete"
    }
  }
}
```

### 6.2 VALIDATION_ERROR — Disallowed Extension Fields

**Trigger:** Extension object contains fields other than `execution_status` for branch/limb/leaf types.

**Detection point:** Check_Mutability_Rules step 6.7, allowlist sub-step.

**Response payload:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Disallowed fields in extension for branch UPDATE: title, priority",
    "details": {
      "disallowed_fields": ["title", "priority"],
      "allowed_fields": ["execution_status"],
      "artifact_type": "branch",
      "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
      "source": "T64",
      "hint": "Only execution_status is UPDATE_ALLOWED for branch artifacts. Use tags.add/tags.remove for tag updates."
    }
  }
}
```

### 6.3 INVALID_TRANSITION — Illegal State Change

**Trigger:** Requested from→to transition is not in the ALLOWED set of the transition matrix. Includes:
- Backward transitions (in_progress → not_started, blocked → not_started)
- Skip transitions (not_started → complete, blocked → complete, NULL → in_progress/blocked/complete)
- Complete terminal violations (complete → anything except complete)
- NULL reset attempts (any non-NULL → NULL)

**Detection point:** Check_Mutability_Rules step 6.7, transition matrix sub-step.

**Response payload:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "INVALID_TRANSITION",
    "message": "execution_status transition not allowed: 'in_progress' → 'not_started'",
    "details": {
      "field": "execution_status",
      "from_status": "in_progress",
      "to_status": "not_started",
      "artifact_type": "branch",
      "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
      "reason": "backward_transition",
      "hint": "execution_status transitions are forward-only. Allowed from 'in_progress': blocked, complete."
    }
  }
}
```

**NULL reset variant:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "INVALID_TRANSITION",
    "message": "Cannot reset execution_status to NULL once initialized",
    "details": {
      "field": "execution_status",
      "from_status": "in_progress",
      "to_status": null,
      "artifact_type": "leaf",
      "artifact_id": "aaaaaaaa-0000-0000-0000-000000000002",
      "reason": "null_reset_prohibited",
      "hint": "execution_status cannot be set back to NULL. Once initialized, only forward transitions are allowed."
    }
  }
}
```

**Complete terminal variant:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "INVALID_TRANSITION",
    "message": "execution_status transition not allowed: 'complete' → 'in_progress'",
    "details": {
      "field": "execution_status",
      "from_status": "complete",
      "to_status": "in_progress",
      "artifact_type": "branch",
      "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
      "reason": "complete_is_terminal",
      "hint": "Complete is a terminal state. No transitions are allowed from complete."
    }
  }
}
```

### 6.4 ARCHIVE_TERMINAL — Archived Artifact

**Trigger:** The artifact's spine `lifecycle_status` is `'archive'`.

**Detection point:** Check_Mutability_Rules step 6.7, archive check sub-step (runs BEFORE transition validation).

**Response payload:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "ARCHIVE_TERMINAL",
    "message": "Cannot mutate execution_status on archived artifact",
    "details": {
      "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
      "artifact_type": "branch",
      "lifecycle_status": "archive",
      "hint": "Archived artifacts are read-only. No mutations are permitted."
    }
  }
}
```

### 6.5 INCOMPLETE_CHILDREN — Parent Completion Blocked

**Trigger:** branch or limb artifact transitions to `complete`, but at least one direct child has `execution_status` that is NOT `complete` (including NULL).

**Detection point:** Guard_Children_Complete node, after DB_Query_Incomplete_Children.

**Response payload:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "INCOMPLETE_CHILDREN",
    "message": "Cannot complete branch: 1 or more children have incomplete execution_status",
    "details": {
      "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
      "artifact_type": "branch",
      "incomplete_child_sample": {
        "artifact_id": "bbbbbbbb-0000-0000-0000-000000000001",
        "execution_status": "in_progress"
      },
      "hint": "All direct children must have execution_status = 'complete' before parent can be marked complete."
    }
  }
}
```

### 6.6 CONCURRENCY_CONFLICT — Version Mismatch

**Trigger:** The PATCH to `qxb_artifact` with `version=eq.{currentVersion}` matches 0 rows, meaning another writer incremented the version between our read (Fetch_Existing_Spine) and our write (DB_Update_Spine_Fields).

**Detection point:** Return_Spine_Update_Ack terminal node, checking PATCH response.

**Response payload:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "CONCURRENCY_CONFLICT",
    "message": "Artifact was modified by another operation. Retry with fresh version.",
    "details": {
      "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
      "artifact_type": "branch",
      "expected_version": 5,
      "hint": "Re-fetch the artifact and retry the update with the current version."
    }
  }
}
```

### Rejection Summary Table

| # | Error Code | HTTP (Gateway) | Detection Node | Precedence |
|---|-----------|---------------|----------------|------------|
| 1 | `VALIDATION_ERROR` (disallowed fields) | 200 | Check_Mutability_Rules (step 6.7) | 1st |
| 2 | `VALIDATION_ERROR` (empty extension) | 200 | Check_Mutability_Rules (step 6.7) | 2nd |
| 3 | `VALIDATION_ERROR` (invalid enum) | 200 | Check_Mutability_Rules (step 6.7) | 3rd |
| 4 | `ARCHIVE_TERMINAL` | 200 | Check_Mutability_Rules (step 6.7) | 4th |
| 5 | `INVALID_TRANSITION` (incl. NULL reset) | 200 | Check_Mutability_Rules (step 6.7) | 5th |
| 6 | `INCOMPLETE_CHILDREN` | 200 | Guard_Children_Complete | 6th (post-routing) |
| 7 | `CONCURRENCY_CONFLICT` | 200 | Return_Spine_Update_Ack | 7th (post-write) |

**Precedence note:** Within step 6.7, checks are ordered: allowlist → empty check → enum validation → archive check → no-op detection → transition matrix → parent check flagging. The first failing check returns immediately (short-circuit).

---

## 7. Parent Completion Enforcement

### Which Types Require Child Completion Validation

| Artifact Type | Parent Check Required | Rationale |
|--------------|----------------------|-----------|
| `branch` | YES | Branch is a container; may have limb or leaf children |
| `limb` | YES | Limb is a container; may have leaf children |
| `leaf` | NO | Leaf is terminal in the containment tree; has no children by design |

### Parent Check Trigger Condition

Parent completion check fires ONLY when:
1. `artifact_type` is `branch` or `limb`, AND
2. Requested `to_status` is `complete`, AND
3. Transition is otherwise valid (not a no-op, not rejected by matrix)

If any of these conditions is false, the parent check is skipped entirely.

### PostgREST Query (Exact)

```
GET https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact
  ?parent_artifact_id=eq.{artifact_id}
  &workspace_id=eq.{workspace_id}
  &deleted_at=is.null
  &or=(execution_status.is.null,execution_status.neq.complete)
  &select=artifact_id,execution_status
  &limit=1
```

**Authentication:** Predefined credential type `supabaseApi`, credential ID `n4R4JdOIV9zrCGIT` ("Qwrk Supabase - Kernel v1").

**Query explanation:**
- `parent_artifact_id=eq.{artifact_id}` — Only direct children of the artifact being completed
- `workspace_id=eq.{workspace_id}` — Scoped to workspace (RLS alignment)
- `deleted_at=is.null` — Exclude soft-deleted children
- `or=(execution_status.is.null,execution_status.neq.complete)` — Find children where execution_status is NULL (never initialized) OR not 'complete'
- `select=artifact_id,execution_status` — Minimal columns (performance)
- `limit=1` — We only need to know if ANY incomplete child exists, not enumerate all

### What Qualifies as "Incomplete"

A child is incomplete if:
- `execution_status IS NULL` (never initialized), OR
- `execution_status != 'complete'` (any non-terminal state)

This is intentionally strict. ALL children must be explicitly `complete` — no implicit completion.

### Zero-Child Case

If the query returns 0 rows, the parent has no incomplete children. This covers two cases:
1. **All children are complete** — Correct, allow completion
2. **No children exist** — Vacuously true. A branch/limb with zero children MAY be marked complete.

The zero-child case is intentionally allowed. Rationale: branches/limbs may be created as placeholders before children are added. Preventing completion of empty containers adds friction without safety benefit (the container can always be completed, then a child added later — there's no mechanism to "uncomplete" the parent because complete is terminal).

### Operational Integrity Note

Parent completion enforcement guarantees correctness relative to the observed child set at query time. It does not guarantee atomic immutability of the child set between read and write operations. This is an intentional Phase 2 architectural choice favoring workflow-layer governance over database-level atomic enforcement.

### Performance Considerations

- Query uses `limit=1`: at most 1 row returned, regardless of child count
- Query is filtered by `parent_artifact_id` (indexed via `qxb_artifact_parent_fk` FK) and `workspace_id`
- Only fires for branch/limb → complete transitions (narrow trigger)
- Typical walk trees have <50 children per node; query is fast even without limit

---

## 8. No-op Detection Logic

### Where No-op Detection Occurs

No-op detection occurs in **Check_Mutability_Rules step 6.7**, AFTER transition matrix validation, BEFORE routing to database write.

### Exact Comparison Method

```javascript
const currentStatus = existing.execution_status;  // from Fetch_Existing_Spine (may be null)
const requestedStatus = extension.execution_status; // from Normalize_Request

// No-op: requested status equals current status (including both null)
const isNoop = (currentStatus === requestedStatus) ||
               (currentStatus === null && requestedStatus === null) ||
               (currentStatus === null && requestedStatus === undefined);
```

**Cases that are no-op:**
- Current: `NULL`, Requested: `NULL` (or undefined/not provided) → no-op
- Current: `"not_started"`, Requested: `"not_started"` → no-op
- Current: `"in_progress"`, Requested: `"in_progress"` → no-op
- Current: `"blocked"`, Requested: `"blocked"` → no-op
- Current: `"complete"`, Requested: `"complete"` → no-op

### Response Payload Returned for No-op

```json
{
  "ok": true,
  "gw_action": "artifact.update",
  "operation": "NOOP",
  "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
  "artifact_type": "branch",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "execution_status": "in_progress",
  "version": 5,
  "_kgb": {
    "status": "NOOP_CONFIRMED",
    "note": "Requested execution_status matches current value. No mutation performed. Version unchanged."
  }
}
```

### Confirmation: Version Does NOT Increment

On no-op:
- `_update_mode` is set to `"noop"` (not `"spine_fields"`)
- Switch_Update_Mode routes to Return_Noop_Ack terminal
- **No database write occurs** — no PATCH, no version increment, no updated_at change
- Response `version` reflects the current (unchanged) version from Fetch_Existing_Spine
- This is a read-only path through the workflow

---

## 9. Concurrency Handling

### PATCH Endpoint Format

```
PATCH https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact
  ?artifact_id=eq.{artifact_id}
  &workspace_id=eq.{workspace_id}
  &version=eq.{currentVersion}
```

**Headers:**
- `Prefer: return=representation` — Return the updated row(s) in the response body
- Standard Supabase auth headers (handled by predefined credential)

**Body:**
```json
{
  "execution_status": "in_progress",
  "version": 6
}
```

### Version Filter Mechanism

The `version=eq.{currentVersion}` filter in the PATCH URL ensures that the write only succeeds if the row's current version matches what we read in Fetch_Existing_Spine. If another writer has incremented the version between our read and write, the filter matches 0 rows.

This is standard optimistic concurrency control (OCC). No locks are held between read and write.

### How Version Increments

Version computation occurs in **Prepare_Spine_Field_Update** (Code node):

```javascript
const currentVersion = typeof existing.version === 'number' ? existing.version : 1;
const nextVersion = currentVersion + 1;
```

The `nextVersion` is included in the PATCH body alongside `execution_status`. Both fields are written atomically in a single PostgREST PATCH call.

**Version increment is exactly +1.** No gaps, no skips. The `updated_at` trigger (`qxb_artifact_set_updated_at`) fires automatically on the PATCH.

### What Response Confirms Success

With `Prefer: return=representation`:

**Success (version matched, 1 row updated):**
PostgREST returns `200 OK` with body: `[{"artifact_id": "...", "execution_status": "in_progress", "version": 6, ...}]`

n8n HTTP Request node parses this as 1 item. `$json.artifact_id` is truthy → success confirmed.

**Failure (version mismatch, 0 rows updated):**
PostgREST returns `200 OK` with body: `[]`

With `alwaysOutputData: true` on the HTTP Request node, n8n produces 1 item with `$json = {}`. `$json.artifact_id` is falsy → concurrency conflict detected.

### How Concurrency Conflict is Detected and Surfaced

Detection occurs in **Return_Spine_Update_Ack** (Code node, terminal):

```javascript
const patchResult = $json;

if (!patchResult || !patchResult.artifact_id) {
  // PostgREST returned [] — version mismatch
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'CONCURRENCY_CONFLICT',
        message: 'Artifact was modified by another operation. Retry with fresh version.',
        details: {
          artifact_id: prepare.artifact_id,
          artifact_type: prepare.artifact_type,
          expected_version: prepare.next_version - 1,
          hint: 'Re-fetch the artifact and retry the update with the current version.'
        }
      }
    }
  }];
}

// Success — return acknowledgement with actual written data
return [{
  json: {
    ok: true,
    gw_action: 'artifact.update',
    operation: 'SPINE_FIELD_UPDATE',
    artifact_id: patchResult.artifact_id,
    artifact_type: patchResult.artifact_type,
    gw_workspace_id: patchResult.workspace_id,
    execution_status: patchResult.execution_status,
    version: patchResult.version,
    _kgb: {
      status: 'SPINE_FIELD_UPDATE_CONFIRMED',
      note: 'execution_status updated. Version incremented. updated_at set by trigger.'
    }
  }
}];
```

**Note:** On success, the response uses ACTUAL data from the PostgREST response (not computed values). This ensures the response reflects database truth.

---

## 10. Determinism Guarantees

### Single Mutation Surface

T64 writes to exactly ONE table: `qxb_artifact` (spine). There is no extension table write for branch/limb/leaf execution_status updates, because `execution_status` is a spine field.

Contrast with the project extension path which writes to TWO tables sequentially (`qxb_artifact_project` then `qxb_artifact`). T64's single-write path eliminates partial-failure risk.

### No Hidden Side Effects

The PATCH writes exactly two fields:
1. `execution_status` — the requested new value
2. `version` — currentVersion + 1

The `updated_at` field is updated by the database trigger `qxb_artifact_set_updated_at` (DDL line 572), not by the PATCH body. This is automatic and correct.

No other spine fields are modified. No extension tables are touched. No event log entries are created (T64 does not write to `qxb_artifact_event`; audit logging for execution_status changes is a future concern).

### Version Monotonicity Preserved

| Scenario | Version Change | Guarantee |
|----------|---------------|-----------|
| Successful transition | +1 exactly | Monotonic |
| No-op (same state) | 0 (unchanged) | Monotonic (no decrement) |
| Rejected transition | 0 (no write) | Monotonic (no decrement) |
| Concurrency conflict | 0 (no write) | Monotonic (another writer incremented) |

Version never decreases. The optimistic concurrency filter (`version=eq.{current}`) prevents phantom decrements.

### updated_at Correctness

- On write: `updated_at = now()` set by trigger (accurate to transaction start)
- On no-op: `updated_at` unchanged (no write → no trigger)
- On rejection: `updated_at` unchanged (no write → no trigger)
- On concurrency conflict: `updated_at` unchanged from T64's perspective (the other writer's trigger fired)

### No Double-Write Paths

There is exactly one code path from Check_Mutability_Rules step 6.7 to DB_Update_Spine_Fields:

```
Check_Mutability_Rules (step 6.7, _update_mode: "spine_fields")
  → Switch_Update_Mode (output: spine_fields)
    → Switch_Parent_Check (IF)
      ├── needs_parent_check=true → DB_Query → Guard → [ok] → Prepare → DB_Update → Ack
      └── needs_parent_check=false → Prepare → DB_Update → Ack
```

Both branches of Switch_Parent_Check converge at Prepare_Spine_Field_Update. There is one and only one DB_Update_Spine_Fields node. No branching ambiguity.

### No Branching Ambiguity

Every decision point in the T64 path has exactly two outcomes, each terminating deterministically:

| Decision Point | Outcome A | Outcome B |
|---------------|-----------|-----------|
| Step 6.7 allowlist | Error (return) | Continue |
| Step 6.7 enum | Error (return) | Continue |
| Step 6.7 archive | Error (return) | Continue |
| Step 6.7 no-op | Route to noop | Continue |
| Step 6.7 transition | Error (return) | Route to spine_fields |
| Switch_Parent_Check | Skip to Prepare | Query children |
| Guard_Children_Complete | Error (return) | Continue to Prepare |
| Return_Spine_Update_Ack | Concurrency error | Success ack |

No fallthrough, no implicit defaults, no silent drops.

---

## 11. Node-Level Workflow Diff

### Modified Nodes (2)

#### 11.1 Check_Mutability_Rules (Node ID: `3d106896`)

**Before (v37):**
Steps 1-6 + 6.5 (project operational_state CHECK) + step 7 (generic extension fallthrough).

Relevant current behavior for branch/limb/leaf: falls through step 6 (project-specific) and step 7 returns `_update_mode: "extension"`, which routes to Switch_Type_For_Update → Return_Unimplemented_Type_Error.

**After (T64):**
Steps 1-6 + 6.5 unchanged. NEW step 6.7 inserted BEFORE step 7:

```
Step 6.7: Branch/Limb/Leaf spine-field validation (T64)
  6.7.1 — Type match: artifact_type in ['branch', 'limb', 'leaf']
  6.7.2 — Allowlist: only 'execution_status' permitted in extension
  6.7.3 — Empty check: extension must contain at least one field
  6.7.4 — Enum validation: value must be in DDL CHECK set
  6.7.5 — Archive guard: lifecycle_status != 'archive'
  6.7.6 — No-op detection: requested == current → _update_mode: 'noop'
  6.7.7 — NULL reset prohibition: non-NULL → NULL rejected
  6.7.8 — Transition matrix: from→to must be in ALLOWED set
  6.7.9 — Parent check flagging: if to_status == 'complete' && type in ['branch','limb'] → _needs_parent_check: true
  6.7.10 — Return: _update_mode: 'spine_fields', _spine_update: {...}, _needs_parent_check: bool
```

Step 7 (generic extension fallthrough) remains as defense-in-depth for types not caught by steps 3-6.7.

**Full step 6.7 code:**

```javascript
// 6.7 RULE: branch/limb/leaf — spine-field update only (T64)
// execution_status is a SPINE field on qxb_artifact (DDL v2.4).
// Route to spine PATCH instead of extension table write.
const executionAnatomyTypes = ['branch', 'limb', 'leaf'];
if (executionAnatomyTypes.includes(artifact_type)) {
  const extension = normalizeNode.extension || {};
  const allowedSpineFields = ['execution_status'];
  const providedFields = Object.keys(extension);

  // 6.7.2 Allowlist check: reject unknown fields
  const disallowedFields = providedFields.filter(f => !allowedSpineFields.includes(f));
  if (disallowedFields.length > 0) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Disallowed fields in extension for ' + artifact_type + ' UPDATE: ' + disallowedFields.join(', '),
          details: {
            disallowed_fields: disallowedFields,
            allowed_fields: allowedSpineFields,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            source: 'T64',
            hint: 'Only execution_status is UPDATE_ALLOWED for ' + artifact_type + ' artifacts. Use tags.add/tags.remove for tag updates.'
          }
        }
      }
    }];
  }

  // 6.7.3 Must provide at least one field
  if (providedFields.length === 0) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: 'No updateable fields provided in extension for ' + artifact_type + ' UPDATE.',
          details: {
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            allowed_fields: allowedSpineFields,
            hint: 'Provide execution_status in extension object.'
          }
        }
      }
    }];
  }

  // 6.7.4 Validate execution_status value against CHECK constraint
  const execStatus = extension.execution_status;
  const validStatuses = ['not_started', 'in_progress', 'blocked', 'complete'];
  if (execStatus !== null && execStatus !== undefined && !validStatuses.includes(execStatus)) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'VALIDATION_ERROR',
          message: "Invalid execution_status value: '" + execStatus + "'",
          details: {
            field: 'execution_status',
            provided_value: execStatus,
            allowed_values: validStatuses,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            hint: 'execution_status must be one of: not_started, in_progress, blocked, complete'
          }
        }
      }
    }];
  }

  // 6.7.5 Archive guard: lifecycle_status = 'archive' rejects all mutations
  if (existing.lifecycle_status === 'archive') {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'ARCHIVE_TERMINAL',
          message: 'Cannot mutate execution_status on archived artifact',
          details: {
            artifact_id: existing.artifact_id,
            artifact_type: artifact_type,
            lifecycle_status: 'archive',
            hint: 'Archived artifacts are read-only. No mutations are permitted.'
          }
        }
      }
    }];
  }

  // 6.7.6 No-op detection: same state → no write
  const currentStatus = existing.execution_status ?? null;
  const requestedStatus = execStatus ?? null;
  if (currentStatus === requestedStatus) {
    return [{
      json: {
        ok: true,
        _gw_route: 'ok',
        _update_mode: 'noop',
        gw_action: normalizeNode.gw_action ?? 'artifact.update',
        gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
        artifact_id: existing.artifact_id,
        workspace_id: existing.workspace_id,
        artifact_type: artifact_type,
        execution_status: currentStatus,
        version: existing.version,
      }
    }];
  }

  // 6.7.7 NULL reset prohibition: cannot set back to NULL once initialized
  if (currentStatus !== null && requestedStatus === null) {
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'INVALID_TRANSITION',
          message: 'Cannot reset execution_status to NULL once initialized',
          details: {
            field: 'execution_status',
            from_status: currentStatus,
            to_status: null,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            reason: 'null_reset_prohibited',
            hint: 'execution_status cannot be set back to NULL. Once initialized, only forward transitions are allowed.'
          }
        }
      }
    }];
  }

  // 6.7.8 Transition matrix enforcement
  const allowedTransitions = {
    'null': ['not_started'],
    'not_started': ['in_progress', 'blocked'],
    'in_progress': ['blocked', 'complete'],
    'blocked': ['in_progress'],
    'complete': []
  };

  const fromKey = currentStatus === null ? 'null' : currentStatus;
  const allowed = allowedTransitions[fromKey] || [];

  if (!allowed.includes(requestedStatus)) {
    // Determine reason for better error messaging
    let reason = 'invalid_transition';
    if (currentStatus === 'complete') {
      reason = 'complete_is_terminal';
    } else if (
      (currentStatus === 'in_progress' && requestedStatus === 'not_started') ||
      (currentStatus === 'blocked' && requestedStatus === 'not_started')
    ) {
      reason = 'backward_transition';
    } else if (
      (currentStatus === null && requestedStatus !== 'not_started') ||
      (currentStatus === 'not_started' && requestedStatus === 'complete') ||
      (currentStatus === 'blocked' && requestedStatus === 'complete')
    ) {
      reason = 'skip_transition';
    }

    const allowedMsg = allowed.length > 0 ? allowed.join(', ') : '(none — terminal state)';
    return [{
      json: {
        ok: false,
        _gw_route: 'error',
        error: {
          code: 'INVALID_TRANSITION',
          message: "execution_status transition not allowed: '" + (currentStatus ?? 'NULL') + "' → '" + requestedStatus + "'",
          details: {
            field: 'execution_status',
            from_status: currentStatus,
            to_status: requestedStatus,
            artifact_type: artifact_type,
            artifact_id: existing.artifact_id,
            reason: reason,
            allowed_from_current: allowed,
            hint: "Allowed from '" + (currentStatus ?? 'NULL') + "': " + allowedMsg + "."
          }
        }
      }
    }];
  }

  // 6.7.9 Parent check flagging
  const needsParentCheck = (requestedStatus === 'complete') &&
                           (artifact_type === 'branch' || artifact_type === 'limb');

  // 6.7.10 Route to spine-field update
  return [{
    json: {
      ok: true,
      _gw_route: 'ok',
      _update_mode: 'spine_fields',
      gw_action: normalizeNode.gw_action ?? 'artifact.update',
      gw_workspace_id: normalizeNode.gw_workspace_id ?? null,
      artifact_id: existing.artifact_id,
      workspace_id: existing.workspace_id,
      artifact_type: artifact_type,
      _normalized_request: normalizeNode,
      _existing_artifact: existing,
      _spine_update: {
        execution_status: requestedStatus,
      },
      _needs_parent_check: needsParentCheck,
      _gw_debug: {
        ...(normalizeNode._gw_debug ?? {}),
        mutability: 'spine_fields_allowed',
        operation: 'UPDATE',
        transition: (currentStatus ?? 'NULL') + ' → ' + requestedStatus,
        needs_parent_check: needsParentCheck,
      }
    }
  }];
}
```

#### 11.2 Switch_Update_Mode (Node ID: `0ce3a56e`)

**Before (v37, 2 outputs):**
- Output 0: `_update_mode == "tags_only"` → Compute_Tag_Merge
- Fallback: → Switch_Type_For_Update

**After (T64, 4 outputs):**
- Output 0: `_update_mode == "tags_only"` → Compute_Tag_Merge (UNCHANGED)
- Output 1: `_update_mode == "spine_fields"` → Switch_Parent_Check (NEW)
- Output 2: `_update_mode == "noop"` → Return_Noop_Ack (NEW)
- Fallback: → Switch_Type_For_Update (UNCHANGED)

**New rules to add (JSON):**

```json
{
  "conditions": {
    "options": {
      "caseSensitive": true,
      "leftValue": "",
      "typeValidation": "strict",
      "version": 3
    },
    "conditions": [
      {
        "leftValue": "={{ $json._update_mode }}",
        "rightValue": "spine_fields",
        "operator": {
          "type": "string",
          "operation": "equals"
        },
        "id": "route-spine-fields"
      }
    ],
    "combinator": "and"
  }
}
```

```json
{
  "conditions": {
    "options": {
      "caseSensitive": true,
      "leftValue": "",
      "typeValidation": "strict",
      "version": 3
    },
    "conditions": [
      {
        "leftValue": "={{ $json._update_mode }}",
        "rightValue": "noop",
        "operator": {
          "type": "string",
          "operation": "equals"
        },
        "id": "route-noop"
      }
    ],
    "combinator": "and"
  }
}
```

### New Nodes (8)

#### 11.3 Return_Noop_Ack (NEW — Code node)

**Name:** `NQxb_Artifact_Update_v1__Return_Noop_Ack`
**Type:** `n8n-nodes-base.code`, typeVersion 2
**Purpose:** Terminal node for no-op responses. No database interaction.

```javascript
// NQxb_Artifact_Update_v1__Return_Noop_Ack
// T64: Terminal for no-op execution_status updates (same state).
// No DB write, no version increment.

return [{
  json: {
    ok: true,
    gw_action: 'artifact.update',
    operation: 'NOOP',
    artifact_id: $json.artifact_id,
    artifact_type: $json.artifact_type,
    gw_workspace_id: $json.gw_workspace_id ?? $json.workspace_id,
    execution_status: $json.execution_status,
    version: $json.version,
    _kgb: {
      status: 'NOOP_CONFIRMED',
      note: 'Requested execution_status matches current value. No mutation performed. Version unchanged.'
    }
  }
}];
```

#### 11.4 Switch_Parent_Check (NEW — IF node)

**Name:** `NQxb_Artifact_Update_v1__Switch_Parent_Check`
**Type:** `n8n-nodes-base.if`, typeVersion 2
**Purpose:** Route based on `_needs_parent_check` flag.

**Configuration:**

```json
{
  "conditions": {
    "options": {
      "caseSensitive": true,
      "leftValue": "",
      "typeValidation": "strict"
    },
    "conditions": [
      {
        "id": "needs-parent-check",
        "leftValue": "={{ $json._needs_parent_check }}",
        "rightValue": true,
        "operator": {
          "type": "boolean",
          "operation": "true"
        }
      }
    ],
    "combinator": "and"
  }
}
```

**Routing:**
- True (output 0): → DB_Query_Incomplete_Children
- False (output 1): → Prepare_Spine_Field_Update

#### 11.5 DB_Query_Incomplete_Children (NEW — HTTP Request node)

**Name:** `NQxb_Artifact_Update_v1__DB_Query_Incomplete_Children`
**Type:** `n8n-nodes-base.httpRequest`, typeVersion 4.2
**Purpose:** Query for children with non-complete execution_status.

**Configuration:**

| Setting | Value |
|---------|-------|
| Method | GET |
| URL | `=https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact?parent_artifact_id=eq.{{ $json.artifact_id }}&workspace_id=eq.{{ $json.workspace_id }}&deleted_at=is.null&or=(execution_status.is.null,execution_status.neq.complete)&select=artifact_id,execution_status&limit=1` |
| Authentication | Predefined Credential Type |
| Credential Type | Supabase API |
| Credential | `Qwrk Supabase – Kernel v1` (id: `n4R4JdOIV9zrCGIT`) |
| On Error | Continue (Error Output) |
| Always Output Data | true |

#### 11.6 Guard_Children_Complete (NEW — Code node)

**Name:** `NQxb_Artifact_Update_v1__Guard_Children_Complete`
**Type:** `n8n-nodes-base.code`, typeVersion 2
**Purpose:** Check query result. If any incomplete child found, return error. Otherwise pass through.

```javascript
// NQxb_Artifact_Update_v1__Guard_Children_Complete
// T64: Check if parent completion query found any incomplete children.
// DB_Query_Incomplete_Children returns [] (0 items) if all complete.
// With alwaysOutputData, 0 items → {json:{}} (no artifact_id).

const queryResult = $json;
const parentData = $node['NQxb_Artifact_Update_v1__Switch_Parent_Check'].json;

if (queryResult && queryResult.artifact_id) {
  // Found an incomplete child — block completion
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'INCOMPLETE_CHILDREN',
        message: 'Cannot complete ' + parentData.artifact_type + ': 1 or more children have incomplete execution_status',
        details: {
          artifact_id: parentData.artifact_id,
          artifact_type: parentData.artifact_type,
          incomplete_child_sample: {
            artifact_id: queryResult.artifact_id,
            execution_status: queryResult.execution_status ?? null
          },
          hint: "All direct children must have execution_status = 'complete' before parent can be marked complete."
        }
      }
    }
  }];
}

// All children complete (or no children) — pass through parent data for spine update
return [{ json: parentData }];
```

#### 11.7 Switch_Children_Result (NEW — Switch node)

**Name:** `NQxb_Artifact_Update_v1__Switch_Children_Result`
**Type:** `n8n-nodes-base.switch`, typeVersion 3.4
**Purpose:** Route Guard_Children_Complete output: ok → Prepare, error → Return_Error_Passthrough.

**Configuration:**

```json
{
  "rules": {
    "values": [
      {
        "conditions": {
          "options": {
            "caseSensitive": true,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 3
          },
          "conditions": [
            {
              "leftValue": "={{ $json.ok }}",
              "rightValue": false,
              "operator": {
                "type": "boolean",
                "operation": "equals"
              },
              "id": "children-error"
            }
          ],
          "combinator": "and"
        }
      },
      {
        "conditions": {
          "options": {
            "caseSensitive": true,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 3
          },
          "conditions": [
            {
              "leftValue": "={{ $json.ok }}",
              "rightValue": true,
              "operator": {
                "type": "boolean",
                "operation": "equals"
              },
              "id": "children-ok"
            }
          ],
          "combinator": "and"
        }
      }
    ]
  },
  "options": {
    "fallbackOutput": "extra"
  }
}
```

**Routing:**
- Output 0 (ok=false): → Return_Error_Passthrough
- Output 1 (ok=true): → Prepare_Spine_Field_Update
- Fallback: → Return_Error_Passthrough (defense-in-depth)

#### 11.8 Prepare_Spine_Field_Update (NEW — Code node)

**Name:** `NQxb_Artifact_Update_v1__Prepare_Spine_Field_Update`
**Type:** `n8n-nodes-base.code`, typeVersion 2
**Purpose:** Build the PATCH payload with execution_status + version.

```javascript
// NQxb_Artifact_Update_v1__Prepare_Spine_Field_Update
// T64: Prepare spine-field PATCH payload for branch/limb/leaf.
// All validation done upstream (Check_Mutability_Rules step 6.7).
// Combines execution_status + version into single spine PATCH.

const existing = $json._existing_artifact;
const spineUpdate = $json._spine_update;

const currentVersion = typeof existing.version === 'number' ? existing.version : 1;
const nextVersion = currentVersion + 1;

return [{
  json: {
    artifact_id: $json.artifact_id,
    workspace_id: $json.workspace_id,
    artifact_type: $json.artifact_type,
    execution_status: spineUpdate.execution_status,
    current_version: currentVersion,
    next_version: nextVersion,
    _spine_debug: {
      version_before: currentVersion,
      version_after: nextVersion,
      field_updated: 'execution_status',
      new_value: spineUpdate.execution_status,
    }
  }
}];
```

#### 11.9 DB_Update_Spine_Fields (NEW — HTTP Request node)

**Name:** `NQxb_Artifact_Update_v1__DB_Update_Spine_Fields`
**Type:** `n8n-nodes-base.httpRequest`, typeVersion 4.2
**Purpose:** PATCH qxb_artifact with optimistic concurrency.

**Configuration:**

| Setting | Value |
|---------|-------|
| Method | PATCH |
| URL | `=https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact?artifact_id=eq.{{ $json.artifact_id }}&workspace_id=eq.{{ $json.workspace_id }}&version=eq.{{ $json.current_version }}` |
| Authentication | Predefined Credential Type |
| Credential Type | Supabase API |
| Credential | `Qwrk Supabase – Kernel v1` (id: `n4R4JdOIV9zrCGIT`) |
| Body Content Type | JSON |
| JSON Body | `={{ JSON.stringify({ execution_status: $json.execution_status, version: $json.next_version }) }}` |
| Send Headers | true |
| Header: Prefer | `return=representation` |
| On Error | Continue (Error Output) |
| Always Output Data | true |

**Critical differences from Scope A design:**
1. URL includes `&version=eq.{{ $json.current_version }}` (optimistic concurrency)
2. Header `Prefer: return=representation` (enables response body inspection)
3. Terminal node (Return_Spine_Update_Ack) checks response for concurrency detection

#### 11.10 Return_Spine_Update_Ack (NEW — Code node)

**Name:** `NQxb_Artifact_Update_v1__Return_Spine_Update_Ack`
**Type:** `n8n-nodes-base.code`, typeVersion 2
**Purpose:** Terminal node. Returns success or CONCURRENCY_CONFLICT.

```javascript
// NQxb_Artifact_Update_v1__Return_Spine_Update_Ack
// T64: Terminal for spine-field update path.
// Inspects PATCH response to detect concurrency conflict.
// With Prefer: return=representation:
//   - Success: PostgREST returns [{...updated row...}] → $json has artifact_id
//   - Conflict: PostgREST returns [] → with alwaysOutputData, $json = {} (no artifact_id)

const patchResult = $json;
const prepare = $node['NQxb_Artifact_Update_v1__Prepare_Spine_Field_Update'].json;

if (!patchResult || !patchResult.artifact_id) {
  // Version mismatch — 0 rows updated
  return [{
    json: {
      ok: false,
      _gw_route: 'error',
      error: {
        code: 'CONCURRENCY_CONFLICT',
        message: 'Artifact was modified by another operation. Retry with fresh version.',
        details: {
          artifact_id: prepare.artifact_id,
          artifact_type: prepare.artifact_type,
          expected_version: prepare.current_version,
          hint: 'Re-fetch the artifact and retry the update with the current version.'
        }
      }
    }
  }];
}

// Success — return ack with actual DB data
return [{
  json: {
    ok: true,
    gw_action: 'artifact.update',
    operation: 'SPINE_FIELD_UPDATE',
    artifact_id: patchResult.artifact_id,
    artifact_type: patchResult.artifact_type,
    gw_workspace_id: patchResult.workspace_id,
    execution_status: patchResult.execution_status,
    version: patchResult.version,
    _kgb: {
      status: 'SPINE_FIELD_UPDATE_CONFIRMED',
      note: 'execution_status updated. Version incremented. updated_at set by trigger.'
    }
  }
}];
```

### Node Count Delta

| Metric | Before (v37) | After (T64) | Delta |
|--------|-------------|-------------|-------|
| Total nodes | 23 | 31 | +8 |
| Code nodes | 10 | 14 | +4 |
| HTTP Request nodes | 2 | 4 | +2 |
| Switch nodes | 3 | 4 | +1 |
| IF nodes | 1 | 2 | +1 |
| Supabase nodes | 3 | 3 | 0 |
| Execute Workflow Trigger | 1 | 1 | 0 |

### Full New Execution Path Diagram

```
NQxb_Artifact_Update_v1__In
  │
  ▼
Normalize_Request
  │
  ▼
Validate_Request
  │
  ▼
Guard_Error_ShortCircuit ──[ok=false]──► Return_Error_Passthrough
  │ [ok=true]
  ▼
Lookup_Type_Registry
  │
  ▼
Type_Registry_Guard
  │
  ▼
Switch_Type_Registry ──[error/fallback]──► Return_Error_Passthrough
  │ [ok]
  ▼
Fetch_Existing_Spine
  │
  ▼
Check_Mutability_Rules (steps 1-6.7)
  │   ├── step 1: NOT_FOUND → error return
  │   ├── step 2: tags_only → _update_mode: "tags_only"
  │   ├── step 3: immutable → error return
  │   ├── step 4: journal → error return
  │   ├── step 5: deleted_at → error return
  │   ├── step 6: project → _update_mode: "extension"
  │   ├── step 6.7: branch/limb/leaf (T64)
  │   │     ├── allowlist fail → error return
  │   │     ├── empty extension → error return
  │   │     ├── invalid enum → error return
  │   │     ├── archive → error return (ARCHIVE_TERMINAL)
  │   │     ├── no-op → _update_mode: "noop"
  │   │     ├── NULL reset → error return (INVALID_TRANSITION)
  │   │     ├── transition fail → error return (INVALID_TRANSITION)
  │   │     └── OK → _update_mode: "spine_fields"
  │   └── step 7: generic fallthrough → _update_mode: "extension"
  │
  ▼
Switch_Mutability_Result ──[ok=false / fallback]──► Return_Error_Passthrough
  │ [ok=true]
  ▼
Switch_Update_Mode
  │
  ├── [tags_only] ──► Compute_Tag_Merge → DB_Update_Spine_Tags
  │                     │                    ├──[success]──► Return_Tags_Ack
  │                     │                    └──[error]───► Return_Error_Passthrough
  │
  ├── [spine_fields] ──► Switch_Parent_Check (IF)                              ◄── NEW
  │                       │
  │                       ├── [true: needs check] ──► DB_Query_Incomplete_Children  ◄── NEW
  │                       │                            │
  │                       │                            ▼
  │                       │                          Guard_Children_Complete         ◄── NEW
  │                       │                            │
  │                       │                            ▼
  │                       │                          Switch_Children_Result          ◄── NEW
  │                       │                            ├── [error] ──► Return_Error_Passthrough
  │                       │                            └── [ok] ────┐
  │                       │                                         │
  │                       └── [false: skip check] ─────────────────┤
  │                                                                 │
  │                                                                 ▼
  │                                                    Prepare_Spine_Field_Update   ◄── NEW
  │                                                                 │
  │                                                                 ▼
  │                                                    DB_Update_Spine_Fields       ◄── NEW
  │                                                       ├──[success]──► Return_Spine_Update_Ack  ◄── NEW
  │                                                       └──[error]───► Return_Error_Passthrough
  │
  ├── [noop] ──► Return_Noop_Ack                                    ◄── NEW
  │
  └── [fallback: extension] ──► Switch_Type_For_Update
                                  ├── [project] → Prepare_Project_Extension_Update
                                  │                → DB_Update_Project_Extension
                                  │                → Prepare_Spine_Version_Increment
                                  │                → DB_Increment_Spine_Version
                                  │                   ├──[success]──► Return_Update_Ack
                                  │                   └──[error]───► Return_Error_Passthrough
                                  ├── [branch] → Return_Unimplemented_Type_Error (defense-in-depth)
                                  ├── [limb]   → Return_Unimplemented_Type_Error (defense-in-depth)
                                  ├── [leaf]   → Return_Unimplemented_Type_Error (defense-in-depth)
                                  └── [fallback] → Return_Unhandled_Type_Error
```

### Connection Wiring (New/Modified)

**New connections:**

| From Node | Output | To Node | Input |
|-----------|--------|---------|-------|
| Switch_Update_Mode | Output 1 (spine_fields) | Switch_Parent_Check | 0 |
| Switch_Update_Mode | Output 2 (noop) | Return_Noop_Ack | 0 |
| Switch_Parent_Check | Output 0 (true) | DB_Query_Incomplete_Children | 0 |
| Switch_Parent_Check | Output 1 (false) | Prepare_Spine_Field_Update | 0 |
| DB_Query_Incomplete_Children | Output 0 (success) | Guard_Children_Complete | 0 |
| DB_Query_Incomplete_Children | Output 1 (error) | Return_Error_Passthrough | 0 |
| Guard_Children_Complete | Output 0 | Switch_Children_Result | 0 |
| Switch_Children_Result | Output 0 (error) | Return_Error_Passthrough | 0 |
| Switch_Children_Result | Output 1 (ok) | Prepare_Spine_Field_Update | 0 |
| Switch_Children_Result | Fallback | Return_Error_Passthrough | 0 |
| Prepare_Spine_Field_Update | Output 0 | DB_Update_Spine_Fields | 0 |
| DB_Update_Spine_Fields | Output 0 (success) | Return_Spine_Update_Ack | 0 |
| DB_Update_Spine_Fields | Output 1 (error) | Return_Error_Passthrough | 0 |

**Modified connections:**

| Connection | Before | After |
|-----------|--------|-------|
| Switch_Update_Mode fallback | Output 1 → Switch_Type_For_Update | Output 3 (fallback) → Switch_Type_For_Update |

**Unchanged connections:** All existing connections (tags path, project extension path, error passthrough paths) remain unchanged.

---

## 12. Certification Test Plan

### Test Infrastructure Notes

- All tests use workspace_id: `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- Test artifacts must exist before running tests (created via `artifact.save`)
- Tests should be run sequentially (state dependencies between some tests)
- Version expectations assume clean starting state

### D01 — NULL → not_started (branch)

**Test name:** `D01_branch_null_to_not_started`
**Initial state:** branch artifact with `execution_status: NULL`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_ID>",
  "extension": {
    "execution_status": "not_started"
  }
}
```
**Expected result:** `ok: true`, `operation: "SPINE_FIELD_UPDATE"`, `execution_status: "not_started"`
**Version expectation:** N+1
**DB write expectation:** WRITE (execution_status + version PATCH)

---

### D02 — not_started → in_progress (limb)

**Test name:** `D02_limb_not_started_to_in_progress`
**Initial state:** limb artifact with `execution_status: "not_started"`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "limb",
  "artifact_id": "<LIMB_ID>",
  "extension": {
    "execution_status": "in_progress"
  }
}
```
**Expected result:** `ok: true`, `operation: "SPINE_FIELD_UPDATE"`, `execution_status: "in_progress"`
**Version expectation:** N+1
**DB write expectation:** WRITE

---

### D03 — in_progress → complete (leaf, no parent check)

**Test name:** `D03_leaf_in_progress_to_complete`
**Initial state:** leaf artifact with `execution_status: "in_progress"`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "leaf",
  "artifact_id": "<LEAF_ID>",
  "extension": {
    "execution_status": "complete"
  }
}
```
**Expected result:** `ok: true`, `operation: "SPINE_FIELD_UPDATE"`, `execution_status: "complete"`
**Version expectation:** N+1
**DB write expectation:** WRITE
**Note:** Leaf has no parent check — completes immediately regardless of children.

---

### D04 — in_progress → complete (branch, all children complete)

**Test name:** `D04_branch_complete_children_pass`
**Precondition:** branch artifact has 1+ children, ALL with `execution_status: "complete"`
**Initial state:** branch with `execution_status: "in_progress"`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_WITH_COMPLETE_CHILDREN>",
  "extension": {
    "execution_status": "complete"
  }
}
```
**Expected result:** `ok: true`, `operation: "SPINE_FIELD_UPDATE"`, `execution_status: "complete"`
**Version expectation:** N+1
**DB write expectation:** WRITE (parent check passes, then PATCH executes)

---

### D05 — in_progress → complete (branch, incomplete children)

**Test name:** `D05_branch_complete_children_fail`
**Precondition:** branch artifact has 1+ children, at least one NOT `execution_status: "complete"`
**Initial state:** branch with `execution_status: "in_progress"`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_WITH_INCOMPLETE_CHILDREN>",
  "extension": {
    "execution_status": "complete"
  }
}
```
**Expected result:** `ok: false`, `error.code: "INCOMPLETE_CHILDREN"`, includes `incomplete_child_sample`
**Version expectation:** N (unchanged)
**DB write expectation:** NO-WRITE (blocked before PATCH)

---

### D06 — in_progress → not_started (backward rejection)

**Test name:** `D06_leaf_backward_transition_rejected`
**Initial state:** leaf with `execution_status: "in_progress"`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "leaf",
  "artifact_id": "<LEAF_ID>",
  "extension": {
    "execution_status": "not_started"
  }
}
```
**Expected result:** `ok: false`, `error.code: "INVALID_TRANSITION"`, `error.details.reason: "backward_transition"`
**Version expectation:** N (unchanged)
**DB write expectation:** NO-WRITE

---

### D07 — complete → in_progress (terminal rejection)

**Test name:** `D07_branch_complete_terminal_rejected`
**Initial state:** branch with `execution_status: "complete"`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_COMPLETE>",
  "extension": {
    "execution_status": "in_progress"
  }
}
```
**Expected result:** `ok: false`, `error.code: "INVALID_TRANSITION"`, `error.details.reason: "complete_is_terminal"`
**Version expectation:** N (unchanged)
**DB write expectation:** NO-WRITE

---

### D08 — blocked → complete (skip rejection)

**Test name:** `D08_branch_blocked_to_complete_rejected`
**Initial state:** branch with `execution_status: "blocked"`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_BLOCKED>",
  "extension": {
    "execution_status": "complete"
  }
}
```
**Expected result:** `ok: false`, `error.code: "INVALID_TRANSITION"`, `error.details.reason: "skip_transition"`
**Version expectation:** N (unchanged)
**DB write expectation:** NO-WRITE

---

### D09 — in_progress → in_progress (no-op)

**Test name:** `D09_limb_noop_same_state`
**Initial state:** limb with `execution_status: "in_progress"`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "limb",
  "artifact_id": "<LIMB_ID>",
  "extension": {
    "execution_status": "in_progress"
  }
}
```
**Expected result:** `ok: true`, `operation: "NOOP"`, `execution_status: "in_progress"`
**Version expectation:** N (unchanged — no DB write)
**DB write expectation:** NO-WRITE (no-op path, no PATCH issued)

---

### D10 — Archive terminal rejection

**Test name:** `D10_branch_archive_terminal_rejected`
**Precondition:** branch artifact with `lifecycle_status: "archive"` (requires direct DB setup as walk types don't normally have lifecycle_status)
**Initial state:** branch with `lifecycle_status: "archive"`, `execution_status: "in_progress"`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_ARCHIVED>",
  "extension": {
    "execution_status": "complete"
  }
}
```
**Expected result:** `ok: false`, `error.code: "ARCHIVE_TERMINAL"`
**Version expectation:** N (unchanged)
**DB write expectation:** NO-WRITE
**Note:** This test requires manual DB setup to set lifecycle_status='archive' on a branch. This is an edge case guard for future governance extension.

---

### D11 — Concurrency conflict detection

**Test name:** `D11_concurrency_conflict`
**Precondition:** Requires two concurrent update attempts (simulate by manually incrementing version between operations)
**Setup:**
1. Read branch artifact, note version N
2. Manually increment version to N+1 in DB (simulating concurrent write)
3. Send update with stale version context

**Payload:** Same as D01/D02 (any valid transition)
**Expected result:** `ok: false`, `error.code: "CONCURRENCY_CONFLICT"`, `error.details.expected_version: N`
**Version expectation:** N+1 (set by the simulated concurrent write, not by T64)
**DB write expectation:** NO-WRITE from T64 (the PATCH matches 0 rows)
**Note:** This test requires DB manipulation to simulate. In production, conflicts arise from genuine concurrent Gateway calls.

---

### D12 — NULL → in_progress (skip rejection)

**Test name:** `D12_leaf_null_to_in_progress_rejected`
**Initial state:** leaf with `execution_status: NULL`, `version: N`
**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "leaf",
  "artifact_id": "<LEAF_NULL>",
  "extension": {
    "execution_status": "in_progress"
  }
}
```
**Expected result:** `ok: false`, `error.code: "INVALID_TRANSITION"`, `error.details.reason: "skip_transition"`, `error.details.from_status: null`, `error.details.to_status: "in_progress"`
**Version expectation:** N (unchanged)
**DB write expectation:** NO-WRITE

---

### D13 — Child Addition During Parent Completion Window

**Test name:** `D13_child_addition_during_parent_completion_window`
**Test intent:** Validate operational integrity when a new child is inserted between the parent's child-check query and the parent's PATCH write.

**Setup:**
1. Create a branch artifact with 1+ children, ALL with `execution_status: "complete"`
2. Set branch to `execution_status: "in_progress"`, note version N
3. Send parent completion request (`in_progress → complete`)
4. Between child-check query and PATCH: insert a new child under the same parent with default `execution_status` (NULL or `not_started`)

**Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "<BRANCH_WITH_COMPLETE_CHILDREN>",
  "extension": {
    "execution_status": "complete"
  }
}
```

**Expected result:**
- Parent MAY transition to `complete` (child-check query saw all children complete at query time)
- New child remains with its default incomplete execution_status
- No crash, no double-write
- Version increments correctly (N+1)
- Behavior is deterministic and documented

**Rationale:** This test validates the documented operational integrity stance: parent completion enforcement guarantees correctness relative to the observed child set at query time, not atomic immutability of the child set between read and write. Workflow-layer governance (not database-level atomic enforcement) manages child-set consistency.

**Note:** This test requires coordinated timing or DB manipulation to simulate the race condition. In production, the window between child-check GET and spine PATCH is <100ms.

---

### Test Coverage Matrix

| Test | Transition | Type | Parent Check | Concurrency | Expected |
|------|-----------|------|-------------|-------------|----------|
| D01 | NULL→not_started | branch | N/A | N/A | PASS (write) |
| D02 | not_started→in_progress | limb | N/A | N/A | PASS (write) |
| D03 | in_progress→complete | leaf | Skipped | N/A | PASS (write) |
| D04 | in_progress→complete | branch | PASS | N/A | PASS (write) |
| D05 | in_progress→complete | branch | FAIL | N/A | REJECT (INCOMPLETE_CHILDREN) |
| D06 | in_progress→not_started | leaf | N/A | N/A | REJECT (INVALID_TRANSITION) |
| D07 | complete→in_progress | branch | N/A | N/A | REJECT (INVALID_TRANSITION) |
| D08 | blocked→complete | branch | N/A | N/A | REJECT (INVALID_TRANSITION) |
| D09 | in_progress→in_progress | limb | N/A | N/A | NOOP |
| D10 | (any, archived) | branch | N/A | N/A | REJECT (ARCHIVE_TERMINAL) |
| D11 | (any, stale version) | branch | N/A | CONFLICT | REJECT (CONCURRENCY_CONFLICT) |
| D12 | NULL→in_progress | leaf | N/A | N/A | REJECT (INVALID_TRANSITION) |
| D13 | in_progress→complete (race) | branch | PASS (at query time) | N/A | PASS (write, operational) |

---

## 13. Merge Safety Plan

### Parallel Workflow File

**Filename:** `workflows/NQxb_Artifact_Update_v1__T64.json`

This is a complete, importable n8n workflow JSON containing all 31 nodes. It is a copy of production v37 with T64 modifications applied. The production workflow (`NQxb_Artifact_Update_v1 (17).json`) is NOT modified.

### No Modification of Production Workflow

Per CLAUDE.md Section 9 (Parallel Build Safety Rule):
- Production v37 remains untouched throughout T64 development
- All changes are implemented in the parallel file
- The parallel file can be imported, tested, and validated independently
- Only after D01-D13 certification passes does the parallel file replace production

### Import Plan

1. **Export production v37** as backup: `workflows/Archive/NQxb_Artifact_Update_v1 (17)__v37_backup.json`
2. **Import** `workflows/NQxb_Artifact_Update_v1__T64.json` into n8n
   - This creates a new workflow (new n8n internal ID)
   - Credential references use id `n4R4JdOIV9zrCGIT` — verify match
3. **Deactivate** production Update v37
4. **Activate** T64 Update workflow
5. **Update Gateway** `NQxb_Gateway_v1` Execute Workflow node for `artifact.update`:
   - Change workflow reference to the new T64 workflow ID
6. **Save and activate** Gateway (version increment: v58 → v59)
7. **Export** both updated workflows for version control:
   - Update: save as `NQxb_Artifact_Update_v1 (18).json` (version 38 = T64)
   - Gateway: save as `NQxb_Gateway_v1 (59).json`

### Certification Gating Criteria

**T64 deployment is BLOCKED until:**

| Gate | Requirement | Status |
|------|-----------|--------|
| D01-D13 | All 13 certification tests PASS | PENDING |
| Regression | Existing Phase 2C harness passes (tags, project extension, immutability, promote) | PENDING |
| Structural | Node count = 31, all connections verified | PENDING |
| Concurrency | D11 demonstrates version conflict detection | PENDING |

**Deployment is NOT permitted with any test failures.** All 13 must pass. Regression suite must show 0 new failures.

### Rollback Plan

If T64 deployment fails:
1. Deactivate T64 Update workflow
2. Reactivate production v37
3. Update Gateway to reference v37 workflow ID
4. Save and activate Gateway
5. Verify regression suite passes on v37

Rollback is clean because production v37 was never modified.

---

## Appendix A: Payload Contract Examples

### A.1 Successful Transition

**Request:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
  "extension": {
    "execution_status": "in_progress"
  }
}
```

**Response:**
```json
{
  "ok": true,
  "gw_action": "artifact.update",
  "operation": "SPINE_FIELD_UPDATE",
  "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
  "artifact_type": "branch",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "execution_status": "in_progress",
  "version": 6,
  "_kgb": {
    "status": "SPINE_FIELD_UPDATE_CONFIRMED",
    "note": "execution_status updated. Version incremented. updated_at set by trigger."
  }
}
```

### A.2 No-op Response

**Request:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "limb",
  "artifact_id": "bbbbbbbb-0000-0000-0000-000000000001",
  "extension": {
    "execution_status": "in_progress"
  }
}
```

**Response (current status is already in_progress):**
```json
{
  "ok": true,
  "gw_action": "artifact.update",
  "operation": "NOOP",
  "artifact_id": "bbbbbbbb-0000-0000-0000-000000000001",
  "artifact_type": "limb",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "execution_status": "in_progress",
  "version": 5,
  "_kgb": {
    "status": "NOOP_CONFIRMED",
    "note": "Requested execution_status matches current value. No mutation performed. Version unchanged."
  }
}
```

### A.3 Tags-Only on Walk Type (Unchanged Behavior)

**Request:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "branch",
  "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
  "tags": {
    "add": ["active-sprint"],
    "remove": ["backlog"]
  }
}
```

**Response (tags-only path, no T64 involvement):**
```json
{
  "ok": true,
  "gw_action": "artifact.update",
  "operation": "TAG_UPDATE",
  "artifact_id": "aaaaaaaa-0000-0000-0000-000000000001",
  "artifact_type": "branch",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "tags": ["active-sprint"],
  "version": 7,
  "_tag_changes": {
    "added": ["active-sprint"],
    "removed": ["backlog"]
  }
}
```

---

## Appendix B: Node Position Map (Suggested)

For clean visual layout in n8n editor, suggested positions:

| Node | X | Y | Row |
|------|---|---|-----|
| Return_Noop_Ack | -656 | 336 | Tags row (reuse Y) |
| Switch_Parent_Check | -880 | 528 | Spine path start |
| DB_Query_Incomplete_Children | -656 | 400 | Parent check branch |
| Guard_Children_Complete | -432 | 400 | After query |
| Switch_Children_Result | -208 | 400 | Route result |
| Prepare_Spine_Field_Update | -208 | 528 | Converge point |
| DB_Update_Spine_Fields | 16 | 528 | PATCH |
| Return_Spine_Update_Ack | 240 | 528 | Terminal |

These positions avoid overlapping with existing nodes (tags row at Y=336, project row at Y=736, unimplemented at Y=960/1184).

---

End of specification.
