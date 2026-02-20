# Conversation Restart Prompt — T1 Phase 2 QPM Implementation

**Date:** 2026-02-14
**Session Type:** Execution + Troubleshooting
**Execution Surface:** CC + Chrome Extension + n8n

---

## Session Context

Working on **T1 — Phase 2 QPM Implementation** (reopened this session — was prematurely closed, only BUG-003 had been resolved). This session focused on diagnosing and fixing BUG-015 (promote transition/reason not forwarded through Gateway).

---

## Thread Inventory

| Thread | Status | Notes |
|--------|--------|-------|
| Gateway v50 fix (transition/reason passthrough) | **COMPLETE** | Deployed, imported, verified. `workflows/NQxb_Gateway_v1 (50).json`. v49 archived. |
| BUG-015 root cause confirmed | **COMPLETE** | Same bug class as T26 — `Normalize_Request` stripped `transition`/`reason`. Fix: 2 lines added after `selector`. |
| QPM `seed_to_sapling` validation test | **COMPLETE** | `PROMOTION_BLOCKED_SEED_NOT_READY` confirmed on `b8616b40` (no summary, no journal children). |
| Q + Joel live testing | **IN PROGRESS** | Joel and Q are running additional promote tests via Chrome Extension. Results not yet reported back to CC. |
| Remaining QPM verification tests | **PENDING** | `sapling_to_tree` (needs execution anatomy guard), `tree_to_retired` (should pass unconditionally). |
| 4-stage vs 5-stage lifecycle decision | **PENDING** | DB CHECK allows: seed/sapling/tree/retired (4 stages). Phase 2 scope aspires to 5 (adds oak, archive). CC asked user for decision — not yet answered. |
| Dead seed archival governance | **NOT STARTED** | Phase 2 acceptance criteria item. |
| Journal mutability policy | **NOT STARTED** | Phase 2 acceptance criteria item. |

---

## Decisions Locked

1. **Gateway v50 fix is the correct approach** — add `transition: raw.transition ?? null` and `reason: raw.reason ?? null` to Normalize_Request output. Same pattern as v48 selector fix.
2. **Normalize_Promote_Request already handled the downstream shaping** — no changes needed there. It reads `j.transition ?? j.artifact_payload?.transition` with correct fallback.
3. **T1 was reopened** — only BUG-003 (Query v17 hydrate gate) was truly resolved from Phase 2. 4 of 5 acceptance criteria still open.

---

## Constraints Discovered

1. **Normalize_Request is a field-stripping normalizer** — any new field the client sends MUST be explicitly listed in the output object. Known instances: `selector` (fixed v48), `transition`/`reason` (fixed v50). Watch for future additions.
2. **QPM `executeQuery` nodes in Promote v17** — uses `executeQuery` operation on Supabase typeVersion 1, which is documented as unsupported in MEMORY.md. Works currently but fragile. If QPM queries break, replace with HTTP Request + PostgREST pattern.
3. **Execute Workflow node has `convertFieldsToString: true`** — this stringifies `artifact_payload` before passing to sub-workflow. Works because Normalize_Promote_Request puts transition/reason at TOP LEVEL as well as inside artifact_payload. Sub-workflow's Normalize_request reads from `j.artifact_payload?.transition` — may get stringified version. Monitor.
4. **Verify_Current_State has empty filter condition `{}`** — harmless but messy. Pre-existing, not from v50.

---

## Files Touched This Session

### Created
- `workflows/NQxb_Gateway_v1 (50).json` — Gateway with transition/reason passthrough fix
- `work/verify_fix.ps1` — Verification script for Normalize_Request jsCode
- `work/validate_json.ps1` — JSON structure validation
- `work/check_escape.ps1` — Byte-level escape verification
- This restart prompt

### Modified
- `sessions/OPEN_THREADS.md` — T1 reopened with corrected status
- `Qwrk_RollingMem/Qwrk_Rolling_Memory__for-q__2026-02-13.md` — Entry 36 added (Rolling Memory Tier Model Staging Protocol)
- `MEMORY.md` — Gateway v49→v50, drift log entry added

### Archived
- `workflows/Archive/NQxb_Gateway_v1 (49).json` — Previous Gateway version

---

## BUG-015 Diagnostic Summary (for context)

**Problem:** `artifact.promote` returned `VALIDATION_ERROR: "transition is required"` even when client sent valid `transition` field.

**Root Cause:** Gateway `Normalize_Request` node explicitly constructs its output object. Any field NOT listed is dropped. `transition` and `reason` were not listed → dropped → Promote sub-workflow received null → validation failed.

**Fix (v50):** Added after the `selector` line in Normalize_Request jsCode:
```javascript
// --- Promote fields ---
transition: raw.transition ?? null,
reason: raw.reason ?? null,
```

**Verification:** Sent promote request for test seed `b8616b40` → received `PROMOTION_BLOCKED_SEED_NOT_READY` (correct QPM behavior, not VALIDATION_ERROR).

---

## QPM Validation Rules (Promote v17 — Current State)

| Transition | Validation Rule | Status |
|-----------|----------------|--------|
| `seed_to_sapling` | summary (non-empty, trimmed) OR linked journal child | **VERIFIED** — correctly blocks |
| `sapling_to_tree` | execution anatomy child (branch, limb, or leaf) | **PENDING VERIFICATION** |
| `tree_to_retired` | No validation (always pass) | **PENDING VERIFICATION** |
| `retired_to_tree` | **REMOVED** in QPM Phase 2 (retired is terminal) | Confirmed in Resolve_Transition code |

---

## Test Artifacts

| Artifact | UUID | Type | Lifecycle | Purpose |
|----------|------|------|-----------|---------|
| BUG015 Test Seed - Empty | `b8616b40-e48b-49b0-960c-cf417202cb17` | project | seed | QPM test — no summary, no children. Correctly blocked. |

---

## Open Questions

1. **4-stage or 5-stage lifecycle?** DB CHECK allows seed/sapling/tree/retired. Phase 2 scope mentions oak + archive. If 5-stage: requires ALTER TABLE, new transitions in Resolve_Transition, new QPM rules.
2. **What did Q's testing reveal?** Joel was testing with Q when this restart was written. Results may include successful promotes, additional edge cases, or new bugs.
3. **`executeQuery` nodes — are they actually working?** The `PROMOTION_BLOCKED_SEED_NOT_READY` response suggests QPM_Validate_Rules ran, but it might be using `_spine_summary` (from Enforce_Verified_State) rather than the executeQuery journal count. Need to test with a seed that HAS a journal child but NO summary to confirm the query path works.

---

## Resume Instructions

### Option A: Continue QPM Testing (Directed)
1. Ask Joel for Q's test results
2. Run remaining verification tests: `sapling_to_tree`, `tree_to_retired`
3. Design test for journal-child path (seed with journal child, no summary → should promote)
4. Get lifecycle decision (4-stage vs 5-stage)

### Option B: Await Direction (Open)
Joel may return with new priorities from Q's testing session. Wait for instructions.
