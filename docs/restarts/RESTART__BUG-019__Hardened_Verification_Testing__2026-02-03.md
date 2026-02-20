# RESTART: BUG-019 Hardened Verification Testing

**Created:** 2026-02-03
**Priority:** HIGH — Testing deployed workflow
**Session:** Continuation of BUG-019 hardening

---

## Current State

BUG-019 verification-based enforcement is complete and hardened. The workflow is ready for testing.

**Workflow file:** `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (6).json`
**Version:** `bug019-verification-enforcement-v2-hardened`

---

## What Was Implemented

### Core Verification Flow
1. `Check_Save_Intent` — Detects explicit save commands via regex
2. `Extract_AI_Claim` — Extracts claimed artifact_id from AI output (UNTRUSTED)
3. `Check_Has_Claim` — Routes based on whether AI returned an ID
4. `Verify_Persistence_Authoritative` — Queries Gateway to verify artifact exists (AUTHORITATIVE)
5. `Check_Verification` — Routes based on verification result
6. `Build_Verified_Success` — Constructs message from VERIFIED data only
7. `Send_Verified_Success` — Sends to Telegram

### Hardening Applied
| # | Change | Purpose |
|---|--------|---------|
| 1 | Explicit save intent regex | Only `^save (journal\|project\|...)` triggers verification |
| 2 | No untrusted data in failures | Claimed IDs removed from error messages |
| 3 | Non-save path sanitization | `Sanitize_Non_Save_Response` strips success language |
| 4 | Trust boundary naming | Node names indicate trusted vs untrusted sources |

---

## Testing Protocol

User will run tests via Telegram and provide results. For each test:

1. **User sends command** — Via Telegram bot
2. **User pastes response** — What Telegram returned
3. **CC verifies at database** — Confirm artifact state matches expectation

### Test Categories

**A. Happy Path (Save Intent Detected)**
- Explicit save command → AI calls tool → Verification passes → Verified success

**B. Verification Failure**
- Save command → AI skips tool/hallucinates → Verification fails → Explicit failure message

**C. Non-Save Path**
- Non-save message → AI responds → Sanitization strips any success language

**D. Edge Cases**
- Message contains "save" but not as command (e.g., "I want to save time")
- AI claims success but returns malformed UUID

---

## Database Verification Queries

**Check if artifact exists:**
```sql
SELECT artifact_id, title, artifact_type, created_at
FROM qxb_artifact
WHERE artifact_id = '<UUID>';
```

**Check recent artifacts:**
```sql
SELECT artifact_id, title, artifact_type, created_at
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
ORDER BY created_at DESC
LIMIT 5;
```

---

## Expected Outcomes

| Scenario | Expected Telegram Response |
|----------|---------------------------|
| Valid save command, tool called, artifact created | "Verified Save" with real artifact_id from DB |
| Valid save command, AI hallucinates | "SAVE VERIFICATION FAILED" with no UUID |
| Valid save command, no ID returned | "SAVE FAILED" with no UUID |
| Non-save message, AI says "Saved" | Warning banner + sanitized response |
| Non-save message, normal response | Normal AI response (no sanitization needed) |

---

## Files

| File | Purpose |
|------|---------|
| `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (6).json` | Workflow to test |
| `docs/Qwrk_Bug_Tracker.md` | BUG-019 status |
| `CC_Inbox/cc_follow_up_hardening_gateway_telegram_verification.md` | Hardening spec |

---

## Deployment Checklist

- [ ] Import `NQxb_Gateway_Telegram_v1 (6).json` to n8n
- [ ] Activate workflow
- [ ] Run Test A: Happy path save
- [ ] Run Test B: Forced verification failure (if possible)
- [ ] Run Test C: Non-save message with potential success language
- [ ] Confirm all tests pass

---

## Context for CC

When user provides test results:
1. Parse the Telegram response
2. If a UUID is shown, query database to verify it exists
3. Confirm the flow matched expectations
4. Report pass/fail for each test
