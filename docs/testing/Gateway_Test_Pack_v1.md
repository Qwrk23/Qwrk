# Gateway Test Pack v1

**Version:** 1.0
**Date:** 2026-01-24
**Status:** Authoritative
**Scope:** Gateway v1 (KGB-Locked) — Full Regression Suite

---

## Table of Contents

1. [Purpose](#1-purpose)
2. [Prerequisites](#2-prerequisites)
3. [Environment Setup](#3-environment-setup)
4. [Known-Good IDs](#4-known-good-ids)
5. [Gateway Test Pack Procedure](#5-gateway-test-pack-procedure)
6. [Test Matrix](#6-test-matrix)
7. [PowerShell Test Execution](#7-powershell-test-execution)
8. [Front-End Prompt Tests](#8-front-end-prompt-tests)
9. [Pass/Fail Criteria](#9-passfail-criteria)
10. [Regression Checklist](#10-regression-checklist)
11. [Record Receipts](#11-record-receipts)
12. [How to Extend This Pack](#12-how-to-extend-this-pack)
13. [Appendix A: Known Failure Patterns](#appendix-a-known-failure-patterns)
14. [Appendix B: Canonical Error Codes](#appendix-b-canonical-error-codes)
15. [Operator Notes](#operator-notes)

---

## 1. Purpose

This document defines a **complete, repeatable regression test suite** for Gateway v1. It covers:

- All five KGB-locked actions: `artifact.query`, `artifact.list`, `artifact.save`, `artifact.update`, `artifact.promote`
- All core artifact types: `project`, `journal`, `snapshot`, `restart`, `instruction_pack`
- Both happy-path and negative (error) scenarios
- PowerShell automation scripts and front-end prompt tests

**Use this pack:**
- Before deploying any Gateway workflow change
- After any n8n workflow modification
- As part of release validation
- To diagnose reported Gateway failures

---

## 2. Prerequisites

### 2.1 Access Requirements

| Requirement | Details |
|-------------|---------|
| Gateway endpoint | `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1` |
| Auth credentials | Basic Auth: `qwrk-gateway` / (password from secure store) |
| Workspace membership | Must be member of workspace `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |
| PowerShell | Version 5.1+ or PowerShell Core 7+ |
| Custom GPT access | Qwrk front-end GPT (for prompt tests) |

### 2.2 Required Files

| File | Location |
|------|----------|
| Test harness | `docs/testing/Qwrk.Gateway.TestHarness.ps1` |
| This document | `docs/testing/Gateway_Test_Pack_v1.md` |

### 2.3 Canonical References

| Document | Purpose |
|----------|---------|
| `docs/governance/Qwrk_Gateway_JSON_Payload_Canonical_v1.md` | Payload shapes |
| `docs/governance/CLAUDE.md` | KGB lock status, known-good IDs |

---

## 3. Environment Setup

### 3.1 PowerShell Environment

```powershell
# Option A: Set environment variable (persists for session)
$env:QWRK_GATEWAY_BASEURL = "https://n8n.halosparkai.com/webhook"

# Option B: Let harness prompt you (default behavior)
# Just run the harness; it will ask for base URL if not set
```

### 3.2 Load Test Harness

```powershell
# Navigate to repo root
cd "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"

# Dot-source the harness
. .\docs\testing\Qwrk.Gateway.TestHarness.ps1

# Initialize (prompts for password once)
Initialize-QwrkGateway
```

### 3.3 Verify Setup

```powershell
# Quick smoke test — should return project list
Invoke-QwrkList -ArtifactType "project"
```

---

## 4. Known-Good IDs

These IDs are **known to exist** and can be used for deterministic tests.

### 4.1 Workspace

| Field | Value |
|-------|-------|
| `gw_workspace_id` | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |
| Name | Master Joel Workspace |

### 4.2 Known Artifacts (KGB Test IDs)

| Artifact Type | artifact_id | Notes |
|---------------|-------------|-------|
| `project` | `668bd18f-4424-41e6-b2f9-393ecd2ec534` | KGB baseline project |
| `journal` | `db428a32-1afa-4e6b-a649-347b0bffd46c` | Owner-private |
| `snapshot` | `610e16d1-c5bb-468c-bd35-57eadf9f2e38` | Immutable |
| `restart` | `ac1d6294-2bd7-4a9d-823e-827562b56e26` | Immutable |
| `instruction_pack` | `f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779` | Read Access Enablement v1.2 |

### 4.3 Known Project for Promote Tests

| Field | Value |
|-------|-------|
| `artifact_id` | `e9601873-9f71-4843-bd81-9ecaccbbf9e3` |
| Notes | Verified project for lifecycle tests |

---

## 5. Gateway Test Pack Procedure

Follow these steps in order for a complete regression run.

### Step 1: Environment Preparation

1. Open PowerShell terminal
2. Navigate to repo: `cd "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"`
3. Dot-source harness: `. .\docs\testing\Qwrk.Gateway.TestHarness.ps1`
4. Initialize: `Initialize-QwrkGateway`
5. Verify password prompt appears and is accepted

### Step 2: Run Query Tests

```powershell
# Run all query tests
Invoke-QwrkQueryTests
```

**Expected:** All 5 artifact types return `ok: true`; negative tests return expected error codes.

### Step 3: Run List Tests

```powershell
# Run all list tests
Invoke-QwrkListTests
```

**Expected:** Lists return `ok: true` with `data.artifacts` array.

### Step 4: Run Save Tests

```powershell
# Run save tests (creates new artifacts)
Invoke-QwrkSaveTests
```

**Expected:** New artifacts created; capture returned `artifact_id` values.

### Step 5: Run Update Tests

```powershell
# Run update tests
Invoke-QwrkUpdateTests
```

**Expected:** Project updates succeed; immutable types return `IMMUTABILITY_ERROR`.

### Step 6: Run Promote Tests

```powershell
# Run promote tests
Invoke-QwrkPromoteTests
```

**Expected:** Valid transitions succeed; invalid transitions return `LIFECYCLE_TRANSITION_NOT_ALLOWED`.

### Step 7: Run Front-End Prompt Tests

1. Open Qwrk Custom GPT
2. Execute each prompt from Section 8
3. Record whether GPT called correct action and received expected response

### Step 8: Record Results

1. Save all PowerShell output to receipt file
2. Document any failures in `docs/testing/receipts/` folder
3. Update regression status

---

## 6. Test Matrix

### 6.1 artifact.query Tests

| # | artifact_type | Scenario | Expected Outcome |
|---|---------------|----------|------------------|
| Q1 | project | Happy path (known ID) | `ok: true`, artifact returned |
| Q2 | journal | Happy path (known ID) | `ok: true`, artifact returned |
| Q3 | snapshot | Happy path (known ID) | `ok: true`, artifact returned |
| Q4 | restart | Happy path (known ID) | `ok: true`, artifact returned |
| Q5 | instruction_pack | Happy path (known ID) | `ok: true`, artifact returned |
| Q6 | project | Wrong artifact_type for ID | `TYPE_MISMATCH` |
| Q7 | project | Non-existent artifact_id | `NOT_FOUND` |
| Q8 | project | Missing artifact_id | `VALIDATION_ERROR` |
| Q9 | project | Invalid UUID format | `VALIDATION_ERROR` |

### 6.2 artifact.list Tests

| # | artifact_type | Scenario | Expected Outcome |
|---|---------------|----------|------------------|
| L1 | project | Default (no selector) | `ok: true`, artifacts array |
| L2 | project | With limit=5 | `ok: true`, ≤5 artifacts |
| L3 | project | With offset=1 | `ok: true`, skips first |
| L4 | project | With hydrate=true | `ok: true`, extension fields included |
| L5 | project | With hydrate=false | `ok: true`, spine only |
| L6 | instruction_pack | Default | `ok: true`, artifacts array |
| L7 | instruction_pack | With limit/offset | `ok: true`, pagination works |
| L8 | journal | Default | `ok: true`, owner's journals only |
| L9 | snapshot | Default | `ok: true`, artifacts array |
| L10 | restart | Default | `ok: true`, artifacts array |

### 6.3 artifact.save Tests

| # | artifact_type | Scenario | Expected Outcome |
|---|---------------|----------|------------------|
| S1 | project | Valid create | `ok: true`, new artifact_id returned |
| S2 | journal | Valid create | `ok: true`, new artifact_id returned |
| S3 | snapshot | Valid create | `ok: true`, new artifact_id returned |
| S4 | restart | Valid create | `ok: true`, new artifact_id returned |
| S5 | instruction_pack | Valid create | `ok: true` or extension table error |
| S6 | project | With artifact_id (forbidden) | `VALIDATION_ERROR` |
| S7 | project | Missing title | `VALIDATION_ERROR` |
| S8 | project | Missing extension.lifecycle_stage | `VALIDATION_ERROR` |
| S9 | invalid_type | Unregistered artifact_type | `ARTIFACT_TYPE_NOT_ALLOWED` |

### 6.4 artifact.update Tests

| # | artifact_type | Scenario | Expected Outcome |
|---|---------------|----------|------------------|
| U1 | project | Update operational_state | `ok: true` |
| U2 | project | Update state_reason | `ok: true` |
| U3 | project | Update lifecycle_stage (forbidden) | `IMMUTABILITY_ERROR` |
| U4 | snapshot | Any update | `IMMUTABILITY_ERROR` |
| U5 | restart | Any update | `IMMUTABILITY_ERROR` |
| U6 | journal | Any update | `IMMUTABILITY_ERROR` (UNDECIDED_BLOCKED) |
| U7 | project | Non-existent artifact_id | `NOT_FOUND` |
| U8 | project | Missing artifact_id | `VALIDATION_ERROR` |

### 6.5 artifact.promote Tests

| # | artifact_type | Scenario | Expected Outcome |
|---|---------------|----------|------------------|
| P1 | project | seed_to_sapling (valid) | `ok: true`, lifecycle updated |
| P2 | project | sapling_to_tree (valid) | `ok: true`, lifecycle updated |
| P3 | project | seed_to_tree (skip) | `LIFECYCLE_TRANSITION_NOT_ALLOWED` |
| P4 | project | Repeat same transition | `LIFECYCLE_STATE_MISMATCH` |
| P5 | snapshot | Any promote | `ACTION_NOT_ALLOWED` |
| P6 | project | Missing transition | `VALIDATION_ERROR` |
| P7 | project | Invalid transition key | `LIFECYCLE_TRANSITION_NOT_ALLOWED` |

---

## 7. PowerShell Test Execution

### 7.1 Quick Reference

```powershell
# Initialize (do once per session)
Initialize-QwrkGateway

# Individual action tests
Invoke-QwrkQueryTests
Invoke-QwrkListTests
Invoke-QwrkSaveTests
Invoke-QwrkUpdateTests
Invoke-QwrkPromoteTests

# Run all tests
Invoke-QwrkAllTests

# Individual calls (ad-hoc)
Invoke-QwrkQuery -ArtifactType "project" -ArtifactId "668bd18f-4424-41e6-b2f9-393ecd2ec534"
Invoke-QwrkList -ArtifactType "project" -Limit 10
Invoke-QwrkSave -ArtifactType "project" -Title "Test Project" -Extension @{lifecycle_stage="seed"}
```

### 7.2 Harness Location

```
docs/testing/Qwrk.Gateway.TestHarness.ps1
```

See Section 12 for harness implementation.

---

## 8. Front-End Prompt Tests

### 8.1 Query Prompts

| # | Prompt | Expected Action | Expected Result | Status |
|---|--------|-----------------|-----------------|--------|
| FQ1 | "Show me the project with ID 668bd18f-4424-41e6-b2f9-393ecd2ec534" | `artifact.query` | `ok: true`, project details | Runnable |
| FQ2 | "Query the instruction pack f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779" | `artifact.query` | `ok: true`, instruction pack details | Runnable |
| FQ3 | "Get the snapshot 610e16d1-c5bb-468c-bd35-57eadf9f2e38" | `artifact.query` | `ok: true`, snapshot details | Runnable |

### 8.2 List Prompts

| # | Prompt | Expected Action | Expected Result | Status |
|---|--------|-----------------|-----------------|--------|
| FL1 | "List all projects" | `artifact.list` | `ok: true`, project list | Runnable |
| FL2 | "Show me the first 5 projects" | `artifact.list` + selector | `ok: true`, ≤5 projects | Runnable |
| FL3 | "List all instruction packs" | `artifact.list` | `ok: true`, instruction_pack list | Runnable |
| FL4 | "List snapshots" | `artifact.list` | `ok: true`, snapshot list | Runnable |

### 8.3 Save Prompts (Future)

| # | Prompt | Expected Action | Expected Result | Status |
|---|--------|-----------------|-----------------|--------|
| FS1 | "Create a new project called Test Alpha" | `artifact.save` | `ok: true`, new artifact_id | Future (blocked) |
| FS2 | "Save a new journal entry about today's work" | `artifact.save` | `ok: true`, new artifact_id | Future (blocked) |

### 8.4 Update Prompts (Future)

| # | Prompt | Expected Action | Expected Result | Status |
|---|--------|-----------------|-----------------|--------|
| FU1 | "Pause project 668bd18f..." | `artifact.update` | `ok: true`, state changed | Future (blocked) |
| FU2 | "Update the project state to blocked" | `artifact.update` | `ok: true` | Future (blocked) |

### 8.5 Promote Prompts (Future)

| # | Prompt | Expected Action | Expected Result | Status |
|---|--------|-----------------|-----------------|--------|
| FP1 | "Promote project X from seed to sapling" | `artifact.promote` | `ok: true`, lifecycle updated | Future (blocked) |

---

## 9. Pass/Fail Criteria

### 9.1 Test Pass Criteria

A test **PASSES** when:
- Response contains `ok: true` for happy-path tests
- Response contains expected error code for negative tests
- Response envelope matches canonical format: `{ok, _gw_route, data/error}`

### 9.2 Test Fail Criteria

A test **FAILS** when:
- Happy-path returns `ok: false`
- Negative test returns wrong error code
- Response is malformed or missing required fields
- HTTP error (4xx/5xx) without proper error envelope
- Timeout (>30 seconds)

### 9.3 Suite Pass Criteria

The full suite **PASSES** when:
- All happy-path tests pass
- All negative tests return expected error codes
- No unexpected errors or timeouts

---

## 10. Regression Checklist

**Minimum tests to run before/after ANY Gateway workflow change:**

### Critical Path (Must Pass)

- [ ] Q1: Query project (known ID)
- [ ] Q5: Query instruction_pack (known ID)
- [ ] L1: List projects (default)
- [ ] L6: List instruction_packs (default)
- [ ] S1: Save project (creates new)
- [ ] U1: Update project operational_state
- [ ] P1: Promote project (if seed available)

### Error Handling (Must Return Correct Code)

- [ ] Q6: TYPE_MISMATCH
- [ ] Q7: NOT_FOUND
- [ ] U4: IMMUTABILITY_ERROR (snapshot)
- [ ] S6: VALIDATION_ERROR (artifact_id in save)

### Front-End Smoke Test

- [ ] FL1: "List all projects" → returns list without asking for workspace

---

## 11. Record Receipts

### 11.1 What to Capture

For each test run, capture:

| Item | Format | Example |
|------|--------|---------|
| Timestamp | ISO 8601 | `2026-01-24T14:30:00Z` |
| Test ID | From matrix | `Q1`, `L3`, `S1` |
| Request JSON | Full payload | `{gw_action: "artifact.query", ...}` |
| Response JSON | Full response | `{ok: true, data: {...}}` |
| Pass/Fail | Boolean | `PASS` or `FAIL` |
| Notes | Free text | Any anomalies |

### 11.2 Receipt File Pattern

```
docs/testing/receipts/YYYY-MM-DD__Gateway_Test_Run__[operator].json
```

### 11.3 Receipt Structure

```json
{
  "run_id": "2026-01-24T14:30:00Z",
  "operator": "Joel",
  "harness_version": "1.0",
  "results": [
    {
      "test_id": "Q1",
      "action": "artifact.query",
      "artifact_type": "project",
      "request": {...},
      "response": {...},
      "pass": true,
      "notes": ""
    }
  ],
  "summary": {
    "total": 30,
    "passed": 28,
    "failed": 2
  }
}
```

---

## 12. How to Extend This Pack

### 12.1 Adding a New Artifact Type

1. Add known-good artifact_id to Section 4.2
2. Add rows to Test Matrix (Section 6) for all 5 actions
3. Add test cases to harness functions
4. Add front-end prompts to Section 8
5. Update regression checklist if critical

### 12.2 Adding a New Test Scenario

1. Determine which action and artifact_type
2. Add row to appropriate Test Matrix table
3. Implement in harness test function
4. Document expected outcome

### 12.3 Adding a New Error Code

1. Verify error code is canonical (in Gateway contract)
2. Add to Appendix B
3. Add negative test case to matrix
4. Implement in harness

---

## Appendix A: Known Failure Patterns

### A.1 TYPE_MISMATCH

**Symptom:** Query returns `TYPE_MISMATCH` error

**Cause:** Requested `artifact_type` doesn't match stored type for the `artifact_id`

**Diagnosis:**
```powershell
# Query without type filter to see actual type
Invoke-QwrkQuery -ArtifactType "project" -ArtifactId "..."
# If fails, try other types
```

**Fix:** Use correct artifact_type for the ID

---

### A.2 NOT_FOUND

**Symptom:** Query/Update returns `NOT_FOUND`

**Causes:**
1. artifact_id doesn't exist
2. RLS blocks access (not in workspace)
3. Artifact was deleted

**Diagnosis:**
- Verify artifact_id exists in Supabase
- Check workspace membership
- Check RLS policies

---

### A.3 IMMUTABILITY_ERROR

**Symptom:** Update returns `IMMUTABILITY_ERROR`

**Causes:**
1. Attempting to update immutable type (snapshot, restart)
2. Attempting to update lifecycle_stage via update (must use promote)
3. Attempting to update journal (UNDECIDED_BLOCKED)

**Fix:** Use correct action (promote for lifecycle) or accept immutability

---

### A.4 VALIDATION_ERROR

**Symptom:** Save/Update returns `VALIDATION_ERROR`

**Causes:**
1. Missing required field (title, artifact_type, etc.)
2. Invalid field format (bad UUID, etc.)
3. Forbidden field included (artifact_id in save)

**Diagnosis:** Check request payload against canonical contract

---

### A.5 ARTIFACT_TYPE_NOT_ALLOWED

**Symptom:** Save returns `ARTIFACT_TYPE_NOT_ALLOWED`

**Cause:** artifact_type not in Type Registry or disabled

**Diagnosis:**
- Check qxb_artifact_type_registry table
- Verify type is enabled

---

## Appendix B: Canonical Error Codes

| Code | Action(s) | Meaning |
|------|-----------|---------|
| `NOT_FOUND` | query, update, promote | Artifact doesn't exist or RLS-filtered |
| `TYPE_MISMATCH` | query | Requested type ≠ stored type |
| `VALIDATION_ERROR` | all | Missing/invalid required fields |
| `IMMUTABILITY_ERROR` | update | Field or type cannot be modified |
| `ARTIFACT_TYPE_NOT_ALLOWED` | save | Type not in registry or disabled |
| `LIFECYCLE_STATE_MISMATCH` | promote | Current state doesn't match transition's from_state |
| `LIFECYCLE_TRANSITION_NOT_ALLOWED` | promote | Invalid transition key or skip |
| `ACTION_NOT_ALLOWED` | promote | Type doesn't support promote |

---

## Operator Notes

### Capturing Results for Diff

1. **Always save receipts** — Use consistent filename pattern
2. **Include timestamps** — Enables chronological comparison
3. **Capture full payloads** — Request AND response
4. **Note environment** — Gateway URL, harness version

### Comparing Runs

```powershell
# Compare two receipt files
$run1 = Get-Content "receipts/2026-01-24__run1.json" | ConvertFrom-Json
$run2 = Get-Content "receipts/2026-01-25__run2.json" | ConvertFrom-Json

# Find differences
$run1.results | Where-Object {
    $id = $_.test_id
    $r2 = $run2.results | Where-Object { $_.test_id -eq $id }
    $_.pass -ne $r2.pass
}
```

### When Tests Fail

1. **Don't panic** — Check if it's a known failure pattern
2. **Capture full response** — Include in receipt
3. **Check Gateway logs** — n8n execution history
4. **Check canonical contract** — Is test expectation correct?
5. **File issue** — If confirmed regression

### Maintenance Cadence

- **Weekly:** Run regression checklist
- **Pre-deploy:** Run full suite
- **Post-incident:** Run affected action tests
- **Monthly:** Review and update known-good IDs

---

**End of Gateway Test Pack v1**
