# Deterministic Hardening Sprint Report

**Date:** 2026-02-21
**Session:** `2026-02-21__011` (Execution — Implementation)
**Scope:** Switch dead-end elimination, neverError removal, Promote serialization, T51 resolution, priority validation
**Workflows Modified:** Update v12, Promote v2_HTTP, Save v31
**Regression Result:** 18/18 invariants PASS

---

## 1. Changes Made

### NQxb_Artifact_Update_v1 (12) — 9 edits

| # | Change | Category |
|---|--------|----------|
| 1 | Added `Return_Unimplemented_Type_Error` Code node — returns `UPDATE_NOT_IMPLEMENTED` for branch/limb/leaf | T51 fix |
| 2 | Added `Return_Unhandled_Type_Error` Code node — returns `UNHANDLED_TYPE_ERROR` for Switch fallback | Dead-end elimination |
| 3 | Added `fallbackOutput: "extra"` to `Switch_Type_For_Update` | Dead-end elimination |
| 4 | Removed `neverError: true` from `DB_Update_Spine_Tags`, replaced with `onError: "continueErrorOutput"` | neverError removal |
| 5 | Removed `neverError: true` from `DB_Increment_Spine_Version`, replaced with `onError: "continueErrorOutput"` | neverError removal |
| 6 | Rewired `Switch_Type_For_Update`: branch/limb/leaf → `Return_Unimplemented_Type_Error`, fallback → `Return_Unhandled_Type_Error` | T51 fix + dead-end |
| 7 | Added `fallbackOutput: "extra"` to `Switch_Type_Registry` | Dead-end elimination |
| 8 | Wired `Switch_Type_Registry` fallback (output 2) → `Return_Error_Passthrough` | Dead-end elimination |
| 9 | Wired `DB_Update_Spine_Tags` error output (index 1) → `Return_Error_Passthrough` | Error output wiring |
| 10 | Wired `DB_Increment_Spine_Version` error output (index 1) → `Return_Error_Passthrough` | Error output wiring |

**Note:** `Switch_Mutability_Result` and `Switch_Update_Mode` already had `fallbackOutput: "extra"` pre-sprint.

**Archive:** `workflows/Archive/NQxb_Artifact_Update_v1 (12)__pre-hardening__2026-02-21.json`

---

### NQxb_Artifact_Promote_v2_HTTP — 8 edits

| # | Change | Category |
|---|--------|----------|
| 1 | Added `fallbackOutput: "extra"` to `Switch_Type_Registry` | Dead-end elimination |
| 2 | Added `fallbackOutput: "extra"` to `Switch_OK` | Dead-end elimination |
| 3 | Added `fallbackOutput: "extra"` to `QPM_Switch` | Dead-end elimination |
| 4 | Added `onError: "continueErrorOutput"` to `DB_Update_Lifecycle` | Serialization safety |
| 5 | Fixed `Freeze_Event_Payload` jsCode: changed `$json` → `$node["NQxb_Artifact_Promote_v1__QPM_Validate_Rules"].json` | Serialization data-flow fix |
| 6 | Serialized QPM_Switch connections: removed parallel `Freeze_Event_Payload` from output 0 | Fire-and-forget elimination |
| 7 | Wired `DB_Update_Lifecycle` output 0 → `Freeze_Event_Payload`, output 1 → `Return_Error_Item` | Serialization + error wiring |
| 8 | Wired fallback outputs for all 3 Switch nodes → `Return_Error_Item` | Dead-end elimination |

**Critical fix (edit 5-7):** Before hardening, `QPM_Switch` output 0 fired `DB_Update_Lifecycle` AND `Freeze_Event_Payload` in parallel. This meant the event payload was frozen and inserted regardless of whether the lifecycle update succeeded — a fire-and-forget pattern. Now the chain is strictly serial: `QPM_Switch` → `DB_Update_Lifecycle` → (success) `Freeze_Event_Payload` → `DB_Insert_Event`. If lifecycle update fails, error routes to `Return_Error_Item` and no event is inserted.

**Data-flow implication:** After serialization, `$json` at `Freeze_Event_Payload` would contain the Supabase UPDATE response row (not the QPM context). Fixed by using explicit `$node["NQxb_Artifact_Promote_v1__QPM_Validate_Rules"].json` reference.

**Archive:** `workflows/Archive/NQxb_Artifact_Promote_v2_HTTP__pre-hardening__2026-02-21.json`

---

### NQxb_Artifact_Save_v1 (31) — 13 edits

| # | Change | Category |
|---|--------|----------|
| 1 | Added `fallbackOutput: "extra"` to `Switch` (ok/error) | Dead-end elimination |
| 2 | Added `fallbackOutput: "extra"` to `Switch_InsertOrUpdate` | Dead-end elimination |
| 3 | Added `fallbackOutput: "extra"` to `Switch_Type_For_Insert` | Dead-end elimination |
| 4 | Added `fallbackOutput: "extra"` to `Switch_Type_For_Update` | Dead-end elimination |
| 5 | Added `fallbackOutput: "extra"` to `Switch_Type_Registry` | Dead-end elimination |
| 6 | Wired `Switch` fallback (output 2) → `Return_Response` | Dead-end elimination |
| 7 | Wired `Switch_InsertOrUpdate` fallback (output 2) → `Return_Response` | Dead-end elimination |
| 8 | Wired `Switch_Type_Registry` fallback (output 2) → `Return_Response` | Dead-end elimination |
| 9 | Wired `Switch_Type_For_Insert` fallback (output 8) → `Return_Response` | Dead-end elimination |
| 10 | Wired `Switch_Type_For_Update` fallback (output 5) → `Return_Response` | Dead-end elimination |
| 11 | Added priority validation to `Validate_Request` jsCode | Priority validation |

**Priority validation logic:**
```javascript
if (req.priority !== undefined && req.priority !== null) {
  const p = Number(req.priority);
  if (!Number.isInteger(p) || p < 1 || p > 5) {
    errors.push({ field: 'priority', reason: 'must be integer 1-5', received: req.priority });
  }
}
```
- Allows `null`/`undefined` (DB applies `DEFAULT 3`)
- Rejects non-integer, out-of-range, and non-numeric values at the gateway level

**Note:** `Switch_Guard_Saved_ID` already had `fallbackOutput: "extra"` pre-sprint.

**Archive:** `workflows/Archive/NQxb_Artifact_Save_v1 (31)__pre-hardening__2026-02-21.json`

---

## 2. Invariants Eliminated

| Invariant | Before | After |
|-----------|--------|-------|
| **Switch dead-ends** | 10 Switch nodes across 3 workflows lacked fallback outputs | All 13 Switch nodes (across 3 workflows) have `fallbackOutput: "extra"` with wired connections to error terminals |
| **neverError suppression** | 2 DB write nodes in Update v12 silently swallowed errors | Zero `neverError: true` across all 3 workflows; replaced with `onError: "continueErrorOutput"` + wired error outputs |
| **Promote fire-and-forget** | `DB_Update_Lifecycle` and `Freeze_Event_Payload` fired in parallel — event inserted regardless of lifecycle update outcome | Strictly serialized: lifecycle must succeed before event is frozen and inserted |
| **T51 fake success** | branch/limb/leaf update returned `ok: true` via `Return_Update_Ack` | Returns `ok: false`, code `UPDATE_NOT_IMPLEMENTED` via dedicated error node |
| **Priority bypass** | No gateway validation — any value (string, negative, 999) passed through to DB | Integer 1-5 enforced at `Validate_Request` in Save workflow |

---

## 3. Regression Scan Results

### NQxb_Artifact_Update_v1 (12)

| Invariant | Result |
|-----------|--------|
| Every Switch has `fallbackOutput: "extra"` | PASS (4/4) |
| Every fallback output wired to error handler | PASS (4/4) |
| No `neverError: true` | PASS |
| No parallel fire-and-forget | PASS |
| branch/limb/leaf returns explicit error | PASS |
| All `continueErrorOutput` nodes have error output wired | PASS (2/2) |

### NQxb_Artifact_Promote_v2_HTTP

| Invariant | Result |
|-----------|--------|
| Every Switch has `fallbackOutput: "extra"` | PASS (3/3) |
| Every fallback output wired to error handler | PASS (3/3) |
| No `neverError: true` | PASS |
| Serialized promote chain, `$node[]` reference in Freeze | PASS |
| All `continueErrorOutput` nodes have error output wired | PASS (1/1) |
| No fake success routes | PASS |

### NQxb_Artifact_Save_v1 (31)

| Invariant | Result |
|-----------|--------|
| Every Switch has `fallbackOutput: "extra"` | PASS (6/6) |
| Every fallback output wired to error handler | PASS (6/6) |
| No `neverError: true` | PASS |
| Priority validation in Validate_Request | PASS |
| No silent drops on type Switch outputs | PASS (15/15 outputs) |
| No DB writes with `neverError`, error outputs wired | PASS |

**Overall: 18/18 PASS. Zero invariant violations.**

---

## 4. Nodes Added

| Workflow | Node Name | Type | Purpose |
|----------|-----------|------|---------|
| Update v12 | `Return_Unimplemented_Type_Error` | Code | Returns `UPDATE_NOT_IMPLEMENTED` for branch/limb/leaf |
| Update v12 | `Return_Unhandled_Type_Error` | Code | Returns `UNHANDLED_TYPE_ERROR` for Switch fallback |

No nodes were added to Promote or Save — all changes were configuration edits, connection rewiring, or code modifications to existing nodes.

---

## 5. Out-of-Scope / Deferred

| Item | Rationale |
|------|-----------|
| **Gateway v56 `Switch_Action` fallback** | Gatekeeper pre-validates actions before the Switch, making unrecognized values unlikely. Lower risk than sub-workflow dead-ends. Deferred to separate sprint. |
| **Query v18 / List v29 Switch hardening** | These are read-only workflows. Switch dead-ends in read paths produce empty results, not data corruption. Lower priority. |
| **`DB_Update_Project_Extension` (Update v12) default error handling** | Supabase node uses n8n default (halt on error) rather than `continueErrorOutput`. Acceptable — execution stops rather than silently continuing. Not a sprint invariant violation. Advisory only. |
| **`DB_Insert_Event` (Promote v2_HTTP) default error handling** | Same pattern — event insert failure halts execution. Acceptable for append-only audit log. |
| **Canonical v2 payload doc update** | Explicitly excluded from sprint scope per original prompt. |

---

## 6. Deployment Sequence

Per CLAUDE.md Workflow Deployment Checklist:

### Step 1: Archive current live versions
Already done — pre-hardening copies in `workflows/Archive/`.

### Step 2: Import sub-workflows to n8n (order does not matter between them)
1. Import `NQxb_Artifact_Update_v1 (12).json`
2. Import `NQxb_Artifact_Promote_v2_HTTP.json`
3. Import `NQxb_Artifact_Save_v1 (31).json`

### Step 3: Gateway reference check
**No Gateway update required.** Version numbers (v12, v2_HTTP, v31) are unchanged — these are in-place hardening edits to existing workflow versions, not new version increments. The Gateway's Execute Workflow nodes already reference these workflow IDs.

### Step 4: Activate all 3 sub-workflows

### Step 5: Smoke test
- **Save:** Create a test artifact with `priority: 0` — should return validation error
- **Save:** Create a test artifact with valid payload — should succeed
- **Update:** Update a branch artifact — should return `UPDATE_NOT_IMPLEMENTED`
- **Update:** Update a project with tags only — should succeed
- **Promote:** Promote a project through lifecycle — should succeed with event logged
- **Promote:** Send invalid promote — should return error envelope

### Rollback
Re-import pre-hardening archives from `workflows/Archive/` and activate.
