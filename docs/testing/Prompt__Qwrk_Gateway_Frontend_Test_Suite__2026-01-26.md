# Qwrk PROMPT — Gateway v1 Front-End Test Suite

**Date:** 2026-01-26
**System:** Qwrk Alpha (Gateway v1 — Full Access)
**Target:** ChatGPT Custom GPT with v2.1 instructions
**Mode:** Structured validation, escalating difficulty

---

## Instructions for Qwrk Chat

You will guide the user through a structured test suite for Qwrk's Gateway v1 front-end.

**Testing Protocol:**
1. Present each test one at a time
2. User executes in Qwrk (ChatGPT), reports result
3. You record PASS/FAIL and any observations
4. For READ tests: note failures, continue to next test
5. For WRITE tests: stop on first unexpected failure, diagnose before continuing
6. For ERROR tests: failures are expected — verify error codes match

**Artifact IDs:** Some tests require IDs from prior tests. Track them as you go.

---

## Phase 1: READ Operations (Non-Destructive)

### Test R1: List Projects (Basic)
**Prompt to Qwrk:**
> List all projects.

**Expected:**
- Returns list of projects (may be empty or populated)
- Response includes `ok: true`
- No errors

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test R2: List Projects (With Limit)
**Prompt to Qwrk:**
> List projects, limit 3.

**Expected:**
- Returns at most 3 projects
- `meta.limit` = 3

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test R3: List Journals
**Prompt to Qwrk:**
> List all journals.

**Expected:**
- Returns journal list
- No errors

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test R4: List Snapshots
**Prompt to Qwrk:**
> List snapshots.

**Expected:**
- Returns snapshot list (may be empty)
- No errors

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test R5: List Restarts
**Prompt to Qwrk:**
> List restarts.

**Expected:**
- Returns restart list
- No errors

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test R6: Query Known Project
**Prompt to Qwrk:**
> Show me the project with ID d30bda32-9149-4bba-a2f8-194fca71a265

**Expected:**
- Returns "Qwrk — System History & Evolution" project
- Hydrated response with extension data
- `lifecycle_status` visible

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test R7: Query Known Journal
**Prompt to Qwrk:**
> Show me journal 44cff1d8-c2c3-42be-9133-a2aeef5ea925

**Expected:**
- Returns "HISTORY · Qwrk · Capabilities Overview" journal
- `entry_text` visible in response

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test R8: List with Hydration
**Prompt to Qwrk:**
> List projects with full details (hydrated).

**Expected:**
- Returns projects with extension fields merged
- More fields visible than basic list

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

## Phase 2: WRITE Operations — Simple Creates

⚠️ **STOP on unexpected failure. Diagnose before continuing.**

### Test W1: Create Journal (Minimal)
**Prompt to Qwrk:**
> Create a journal entry titled "Gateway Test W1" with entry text "Testing basic journal creation."

**Expected:**
- Qwrk confirms intent before saving
- Returns `artifact_id` on success
- `ok: true`

**Record:** [ ] PASS  [ ] FAIL
**artifact_id:** ___
**Notes:** ___

---

### Test W2: Create Project (Minimal)
**Prompt to Qwrk:**
> Create a new project called "Gateway Test Project W2".

**Expected:**
- Qwrk confirms intent
- Project created with `lifecycle_status: seed`
- Returns `artifact_id`

**Record:** [ ] PASS  [ ] FAIL
**artifact_id:** ___
**Notes:** ___

---

### Test W3: Query Created Project
**Prompt to Qwrk:**
> Show me project [artifact_id from W2]

**Expected:**
- Returns the project just created
- Title matches "Gateway Test Project W2"
- `lifecycle_status: seed`

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

## Phase 3: WRITE Operations — Updates

### Test U1: Update Project operational_state
**Prompt to Qwrk:**
> Pause project [artifact_id from W2]. Reason: "Testing update functionality."

**Expected:**
- Qwrk confirms intent
- `operational_state` changed to "paused"
- `state_reason` set

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test U2: Verify Update Persisted
**Prompt to Qwrk:**
> Show me project [artifact_id from W2]

**Expected:**
- `operational_state: paused`
- `state_reason` contains test text

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test U3: Resume Project
**Prompt to Qwrk:**
> Resume project [artifact_id from W2]. Reason: "Update test complete."

**Expected:**
- `operational_state` changed to "active" (or similar)

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

## Phase 4: WRITE Operations — Promote

### Test P1: Promote seed → sapling
**Prompt to Qwrk:**
> Promote project [artifact_id from W2] to sapling. Reason: "Testing lifecycle promotion."

**Expected:**
- Qwrk queries current state first
- Confirms transition is valid
- Asks for confirmation
- After confirm: `lifecycle_status: sapling`

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test P2: Verify Promotion
**Prompt to Qwrk:**
> Show me project [artifact_id from W2]

**Expected:**
- `lifecycle_status: sapling`

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test P3: Promote sapling → tree
**Prompt to Qwrk:**
> Promote project [artifact_id from W2] to tree. Reason: "Completing lifecycle test."

**Expected:**
- Successful transition to `tree`

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

## Phase 5: ERROR Handling (Expected Failures)

These tests verify Qwrk handles errors correctly. **Failures are expected.**

### Test E1: Update Immutable Journal
**Prompt to Qwrk:**
> Update journal [artifact_id from W1] with new text "Modified content."

**Expected:**
- Error: IMMUTABILITY_ERROR or JOURNAL_MUTABILITY_UNDECIDED
- Qwrk explains journals are immutable

**Record:** [ ] PASS (error returned)  [ ] FAIL (unexpected success)
**Error code:** ___
**Notes:** ___

---

### Test E2: Invalid Promote Transition
**Prompt to Qwrk:**
> Promote project [artifact_id from W2] to seed. Reason: "Invalid transition test."

**Expected:**
- Error: LIFECYCLE_TRANSITION_NOT_ALLOWED
- Cannot go from tree → seed

**Record:** [ ] PASS (error returned)  [ ] FAIL (unexpected success)
**Error code:** ___
**Notes:** ___

---

### Test E3: Query Non-Existent Artifact
**Prompt to Qwrk:**
> Show me project 00000000-0000-0000-0000-000000000000

**Expected:**
- Error: NOT_FOUND
- Qwrk does not fabricate data

**Record:** [ ] PASS (error returned)  [ ] FAIL (unexpected behavior)
**Error code:** ___
**Notes:** ___

---

### Test E4: Type Mismatch
**Prompt to Qwrk:**
> Show me the journal with ID [project artifact_id from W2]

**Expected:**
- Error: TYPE_MISMATCH or NOT_FOUND
- Artifact exists but is a project, not journal

**Record:** [ ] PASS (error returned)  [ ] FAIL (unexpected behavior)
**Error code:** ___
**Notes:** ___

---

### Test E5: Update Blocked Field (lifecycle_stage)
**Prompt to Qwrk:**
> Update project [artifact_id from W2] to change lifecycle_stage to "seed".

**Expected:**
- Error: MUTABILITY_ERROR
- Qwrk explains to use promote instead

**Record:** [ ] PASS (error returned)  [ ] FAIL (unexpected success)
**Error code:** ___
**Notes:** ___

---

## Phase 6: Edge Cases

### Test X1: List with Large Limit
**Prompt to Qwrk:**
> List projects, limit 1000.

**Expected:**
- Request succeeds (clamped to max 500)
- No error thrown

**Record:** [ ] PASS  [ ] FAIL
**Notes:** ___

---

### Test X2: Create Restart
**Prompt to Qwrk:**
> Create a restart point titled "Gateway Test Checkpoint" with payload containing the text "Test checkpoint data".

**Expected:**
- Qwrk confirms intent
- Restart created with payload
- Returns `artifact_id`

**Record:** [ ] PASS  [ ] FAIL
**artifact_id:** ___
**Notes:** ___

---

### Test X3: Create Snapshot
**Prompt to Qwrk:**
> Create a snapshot titled "Gateway Test Snapshot" capturing current test state.

**Expected:**
- Qwrk confirms intent
- Snapshot created
- Returns `artifact_id`

**Record:** [ ] PASS  [ ] FAIL
**artifact_id:** ___
**Notes:** ___

---

## Results Summary

After completing all tests, fill in:

| Phase | Total | Passed | Failed |
|-------|-------|--------|--------|
| READ (R1-R8) | 8 | ___ | ___ |
| WRITE Create (W1-W3) | 3 | ___ | ___ |
| WRITE Update (U1-U3) | 3 | ___ | ___ |
| WRITE Promote (P1-P3) | 3 | ___ | ___ |
| ERROR Handling (E1-E5) | 5 | ___ | ___ |
| Edge Cases (X1-X3) | 3 | ___ | ___ |
| **TOTAL** | **25** | ___ | ___ |

---

## Issues Log

List any failures or unexpected behaviors:

| Test | Issue | Severity | Notes |
|------|-------|----------|-------|
| ___ | ___ | Critical/Warning/Minor | ___ |

---

## Next Steps

Based on results:
- **All pass:** Gateway v1 front-end validated. Proceed to production readiness.
- **Critical failures:** Stop, diagnose, fix, re-run failed tests.
- **Minor issues:** Document, prioritize, continue with known limitations.

---

*Test suite designed for Qwrk Alpha validation — 2026-01-26*
