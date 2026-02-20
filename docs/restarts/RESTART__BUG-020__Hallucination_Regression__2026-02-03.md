# Restart: BUG-020 Hallucination Regression Investigation

**Date:** 2026-02-03
**Priority:** High
**Thread:** T9 (BUG-020) + T8 (BUG-019 regression)

---

## Current State

The BUG-020 workflow fix (v25) is **technically correct** and deployed:
- Extension node changed from UPDATE to INSERT
- `artifact_id` added to field list
- `pack_format` hardcoded to `'json'`

**Test Results:**
| Test | Title | Result | Notes |
|------|-------|--------|-------|
| 1 | "Fresh Test Pack ABC" | PASS | artifact_id `21b3f7a4-d9ce-4564-8d47-8d968c2aad0c` exists in both tables |
| 2 | "Fresh Test Pack XYZ" | FAIL | Telegram reported success with `5d9c9e5e-4b4f-4b2e-bc9b-0c3d1c5f9e3e` but artifact NOT in DB |

---

## Hallucination Evidence

The artifact_id from Test 2 has suspicious patterns:
```
5d9c9e5e-4b4f-4b2e-bc9b-0c3d1c5f9e3e
     ^^^^ ^^^^ ^^^^       ^^^^^^^^^^^
     9e5e 4b4f 4b2e       repeating patterns
```

Real `gen_random_uuid()` output has better entropy. This UUID was AI-generated (hallucinated).

---

## Root Cause Hypothesis

BUG-019 verification enforcement (v8-no-sanitizer) removed the sanitizer from non-save paths but kept verification on save paths. However, the AI Agent is sometimes:

1. **Skipping the tool call entirely** — decides not to call Gateway and makes up response
2. **Or** — calling Gateway but something in the response chain is broken

---

## Investigation Steps

### Step 1: Check n8n Execution Logs
Look for executions around the time of "Fresh Test Pack XYZ" test:
- Was `NQxb_Gateway_Telegram_v1` executed?
- Was `NQxb_Gateway_v1` executed?
- Was `NQxb_Artifact_Save_v1` executed?

If Gateway/Save workflows were NOT executed, the AI skipped the tool call.

### Step 2: Check Telegram Workflow Tool Call
In `NQxb_Gateway_Telegram_v1`, examine:
- AI Agent node output — did it generate a tool call or just text?
- Verification node — did it receive a save response to verify?

### Step 3: Determine Fix Path

**If AI skipped tool call:**
- Strengthen verification to detect AI-generated responses (entropy check on UUIDs?)
- Add explicit instruction to AI model about always calling tools
- Consider model upgrade (gpt-4o vs gpt-4o-mini)

**If Gateway was called but returned bad data:**
- Check Gateway response envelope
- Check if Save workflow response is being propagated correctly

---

## Key Files

| File | Purpose |
|------|---------|
| `workflows/NQxb_Artifact_Save_v1 (25).json` | Current KGB (workflow fix correct) |
| `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (6).json` | Telegram workflow with AI Agent |
| `docs/Qwrk_Bug_Tracker.md` | BUG-020 and BUG-019 status |

---

## Test Data

**Artifact that DOES exist (Test 1 - PASSED):**
```sql
SELECT * FROM qxb_artifact WHERE artifact_id = '21b3f7a4-d9ce-4564-8d47-8d968c2aad0c';
SELECT * FROM qxb_artifact_instruction_pack WHERE artifact_id = '21b3f7a4-d9ce-4564-8d47-8d968c2aad0c';
```

**Artifact that does NOT exist (Test 2 - HALLUCINATED):**
```sql
SELECT * FROM qxb_artifact WHERE artifact_id = '5d9c9e5e-4b4f-4b2e-bc9b-0c3d1c5f9e3e';
-- Expected: 0 rows
```

---

## Restart Prompt

```
New session

Continue: BUG-020 hallucination regression investigation

Workflow fix (v25) deployed. Test 1 passed, Test 2 hallucinated.

First step: Check n8n execution logs for "Fresh Test Pack XYZ" test.
Was Gateway actually called, or did AI skip the tool?
```
