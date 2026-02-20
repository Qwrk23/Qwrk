# RESTART — Update Workflow Error Path Fixes

**Date:** 2026-01-25
**Status:** READY FOR MANUAL TESTING + CORRECTION
**Workflow:** `NQxb_Artifact_Update_v1` (ID: `ZMiwnwHm2AL96HhK`)

---

## Context

Gateway test suite ran on 2026-01-25 with these results:

| Suite | Score | Status |
|-------|-------|--------|
| Query | 7/7 | ✅ Perfect |
| List | 10/10 | ✅ Perfect |
| Save | 6/8 | ⚠️ Minor issues |
| **Update** | **2/7** | ❌ **5 failures** |
| Promote | 2/5 | ❌ 3 failures |

**Root cause identified:** Error paths in the Update workflow are not wired to return responses. Tests U3-U7 return empty strings (`""`) instead of proper error JSON.

---

## Issues Found (2 Total)

### Issue 1: Guard_Error_ShortCircuit Mis-wired

**Node:** `NQxb_Artifact_Update_v1__Guard_Error_ShortCircuit`
**Type:** IF node
**Condition:** `$json.ok === false`

**Current Wiring:**
- Output 0 (ok IS false = validation error) → `Build_Query_Request` ❌ WRONG
- Output 1 (ok IS true = continue) → `Lookup_Type_Registry` ✓ Correct

**Problem:** Validation errors route to success path instead of error return.

---

### Issue 2: Check_Mutability_Rules Has No Error Guard

**Node:** `NQxb_Artifact_Update_v1__Check_Mutability_Rules`

This node returns error JSON (`ok: false`) for:
- `NOT_FOUND` — artifact doesn't exist
- `IMMUTABILITY_ERROR` — snapshot/restart are immutable
- `JOURNAL_MUTABILITY_UNDECIDED` — journal update blocked
- `MUTABILITY_ERROR` — lifecycle_stage is PROMOTE_ONLY
- `MUTABILITY_ERROR` — disallowed fields in extension

**Current Wiring:**
```
Check_Mutability_Rules → Switch_Type_For_Update → (only "project" output)
```

**Problem:** Error payloads don't match `artifact_type === "project"`, so they fall through with no output = empty response.

---

## Part 1: Manual Testing (Verify Issues)

Before making changes, verify the issues exist by running these tests in n8n.

### Test A: Verify Issue 1 (Guard_Error_ShortCircuit)

**Purpose:** Confirm validation errors don't return proper responses.

1. Open `NQxb_Artifact_Update_v1` in n8n
2. Use this test payload (missing `extension` object):

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534"
}
```

3. Execute workflow
4. **Expected (broken):** Empty response or wrong path taken
5. **Expected (fixed):** Error response with `VALIDATION_ERROR` code

---

### Test B: Verify Issue 2 (Mutability Errors - IMMUTABILITY_ERROR)

**Purpose:** Confirm immutable artifact updates don't return error responses.

1. Use this test payload (update snapshot - should fail):

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "artifact_id": "610e16d1-c5bb-468c-bd35-57eadf9f2e38",
  "extension": {
    "payload": {"test": "should fail"}
  }
}
```

2. Execute workflow
3. Observe which nodes execute
4. **Expected (broken):** Flow reaches `Switch_Type_For_Update`, then dead-ends (empty response)
5. **Expected (fixed):** Error response with `IMMUTABILITY_ERROR` code

---

### Test C: Verify Issue 2 (Mutability Errors - PROMOTE_ONLY)

**Purpose:** Confirm lifecycle_stage update returns PROMOTE_ONLY error.

1. Use this test payload:

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
  "extension": {
    "lifecycle_stage": "tree"
  }
}
```

2. Execute workflow
3. **Expected (broken):** Empty response
4. **Expected (fixed):** Error response with `MUTABILITY_ERROR` code and `PROMOTE_ONLY` in details

---

### Test D: Verify Issue 2 (Mutability Errors - NOT_FOUND)

**Purpose:** Confirm non-existent artifact returns NOT_FOUND error.

1. Use this test payload:

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "00000000-0000-0000-0000-000000000000",
  "extension": {
    "operational_state": "active"
  }
}
```

2. Execute workflow
3. **Expected (broken):** Empty response
4. **Expected (fixed):** Error response with `NOT_FOUND` code

---

## Part 2: Workflow Corrections

### Fix 1: Rewire Guard_Error_ShortCircuit

**Location:** `NQxb_Artifact_Update_v1__Guard_Error_ShortCircuit` node

**Steps:**

1. Select the `Guard_Error_ShortCircuit` node
2. Find the connection from **Output 0** (TRUE branch = ok is false)
3. **Delete** the connection to `Build_Query_Request`
4. **Create new connection** from Output 0 to `Return_Error_Passthrough`

**Visual Before:**
```
Guard_Error_ShortCircuit
  ├── Output 0 (ok=false) → Build_Query_Request  ❌
  └── Output 1 (ok=true)  → Lookup_Type_Registry ✓
```

**Visual After:**
```
Guard_Error_ShortCircuit
  ├── Output 0 (ok=false) → Return_Error_Passthrough ✓
  └── Output 1 (ok=true)  → Lookup_Type_Registry     ✓
```

---

### Fix 2: Add Error Guard After Check_Mutability_Rules

**Location:** Between `Check_Mutability_Rules` and `Switch_Type_For_Update`

**Steps:**

1. **Add new IF node** named `NQxb_Artifact_Update_v1__Guard_Mutability_Error`
2. **Configure condition:** `{{ $json.ok }}` equals `false`
3. **Rewire connections:**
   - Delete: `Check_Mutability_Rules` → `Switch_Type_For_Update`
   - Add: `Check_Mutability_Rules` → `Guard_Mutability_Error`
   - Add: `Guard_Mutability_Error` Output 0 (ok=false) → `Return_Error_Passthrough`
   - Add: `Guard_Mutability_Error` Output 1 (ok=true) → `Switch_Type_For_Update`

**IF Node Configuration:**
```
Name: NQxb_Artifact_Update_v1__Guard_Mutability_Error
Type: IF
Condition:
  - Value 1: {{ $json.ok }}
  - Operation: equals
  - Value 2: false
```

**Visual Before:**
```
Check_Mutability_Rules → Switch_Type_For_Update → ...
```

**Visual After:**
```
Check_Mutability_Rules → Guard_Mutability_Error
                           ├── Output 0 (ok=false) → Return_Error_Passthrough
                           └── Output 1 (ok=true)  → Switch_Type_For_Update → ...
```

---

## Part 3: Verification Tests (After Fixes)

Re-run the same tests from Part 1 to confirm fixes work.

### Expected Results After Fixes:

| Test | Payload | Expected Response |
|------|---------|-------------------|
| Test A | Missing extension | `{"ok": false, "error": {"code": "VALIDATION_ERROR", ...}}` |
| Test B | Update snapshot | `{"ok": false, "error": {"code": "IMMUTABILITY_ERROR", ...}}` |
| Test C | Update lifecycle_stage | `{"ok": false, "error": {"code": "MUTABILITY_ERROR", ...}}` |
| Test D | Non-existent artifact | `{"ok": false, "error": {"code": "NOT_FOUND", ...}}` |

---

## Part 4: Full Test Suite

After manual verification passes, run the full Gateway test suite:

```powershell
cd "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"
.\docs\testing\run-tests.ps1 -Password '<your-password>' -TestSuite 'Update'
```

**Target:** 7/7 Update tests passing

---

## Node Reference (Quick Lookup)

| Node Name | Purpose |
|-----------|---------|
| `NQxb_Artifact_Update_v1__In` | Entry point |
| `NQxb_Artifact_Update_v1__Normalize_Request` | Normalizes incoming request |
| `NQxb_Artifact_Update_v1__Validate_Request` | Validates required fields |
| `NQxb_Artifact_Update_v1__Guard_Error_ShortCircuit` | Routes validation errors |
| `NQxb_Artifact_Update_v1__Lookup_Type_Registry` | Checks type registry |
| `NQxb_Artifact_Update_v1__Type_Registry_Guard` | Enforces type registration |
| `NQxb_Artifact_Update_v1__Switch_Type_Registry` | Routes registry errors |
| `NQxb_Artifact_Update_v1__Fetch_Existing_Spine` | Fetches artifact from DB |
| `NQxb_Artifact_Update_v1__Check_Mutability_Rules` | Enforces mutability rules |
| `NQxb_Artifact_Update_v1__Switch_Type_For_Update` | Routes by artifact type |
| `NQxb_Artifact_Update_v1__Return_Error_Passthrough` | Terminal: returns error JSON |
| `NQxb_Artifact_Update_v1__Return_Update_Ack` | Terminal: returns success JSON |

---

## Success Criteria

- [ ] Test A returns VALIDATION_ERROR
- [ ] Test B returns IMMUTABILITY_ERROR
- [ ] Test C returns MUTABILITY_ERROR with PROMOTE_ONLY
- [ ] Test D returns NOT_FOUND
- [ ] Full Update test suite: 7/7

---

## Post-Fix Actions

1. Export corrected workflow JSON
2. Save to `workflows/NQxb_Artifact_Update_v1 (9).json`
3. Archive previous version with `__SUPERSEDED__` suffix
4. Run full test suite (`-TestSuite 'All'`) to confirm no regressions

---

*Generated by Claude Code — 2026-01-25*
