# RESTART: BUG-019 Check_Has_Claim Fix

**Created:** 2026-02-03
**Priority:** HIGH — Currently debugging deployed workflow
**Session:** Continuation of BUG-019 structural hallucination fix

---

## Current State

We implemented verification-based enforcement for BUG-019 (AI hallucinating save success). The workflow is deployed and being tested. We found a bug in the verification flow.

**Deployed file:** `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (6).json`

---

## The Bug We're Fixing

**Node:** `Check_Has_Claim` (If node)

**Symptom:**
- `Extract_Claimed_ArtifactId` correctly outputs `has_claim: true`
- `Check_Has_Claim` takes the FALSE branch anyway
- Flow goes to `Build_No_ID_Failure` → user sees failure despite valid extraction

**Test Results (from execution logs):**

`Extract_Claimed_ArtifactId` output:
```json
{
  "claimed_artifact_id": "a2a33dcf-39dd-432c-b0c7-d3b40f896bee",
  "claimed_type": "project",
  "has_claim": true,
  "ai_output": "✓ Saved project\n\nartifact_id: a2a33dcf-39dd-432c-b0c7-d3b40f896bee..."
}
```

Despite `has_claim: true`, the If node routed to false branch.

**Suspected Cause:**
The `Check_Has_Claim` node uses `typeValidation: "strict"`. This may cause boolean `true` to fail comparison if n8n is treating it as string `"true"`.

---

## Immediate Next Step

**Fix the `Check_Has_Claim` node:**

Change from:
```json
"typeValidation": "strict"
```

To:
```json
"typeValidation": "loose"
```

Or change the condition to check `has_claim` as truthy (not strict boolean equals).

Then redeploy and retest.

---

## Test Command

```
Save project titled "Seed — BUG-019 Verification Test" with summary "Test artifact to verify structural hallucination fix. Created 2026-02-03." and tags test, bug019, verification
```

**Expected result after fix:**
- Flow: Check_Has_Claim → TRUE → Verify_Artifact → Check_Verification → Build_Verified_Success → Send_Verified_Success
- Telegram receives: "✅ Verified Save" with real artifact_id

---

## Files

| File | Purpose |
|------|---------|
| `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (6).json` | Workflow to fix |
| `docs/Qwrk_Bug_Tracker.md` | BUG-019 status |
| `docs/restarts/RESTART__BUG-019__Structural_Hallucination_Fix__2026-02-03.md` | Full implementation plan |

---

## Context: What BUG-019 Is

AI Agent (GPT-4o) can skip tool calls and hallucinate save responses with fake UUIDs. We implemented verification-based enforcement:

1. Detect save intent from original message
2. Extract claimed artifact_id from AI output (untrusted)
3. Query Gateway to verify artifact actually exists
4. Only send success if verification passes
5. Send explicit failure if verification fails

The implementation is correct — we just have a type comparison bug in step 3's routing logic.

---

## After This Fix

Once Check_Has_Claim routes correctly:
1. Verify_Artifact will query Gateway
2. Check_Verification will confirm artifact exists
3. Build_Verified_Success will construct message from verified data
4. User receives verified success (or explicit failure if hallucination)

The structural guarantee holds: **no execution path where Telegram shows success AND artifact doesn't exist.**
