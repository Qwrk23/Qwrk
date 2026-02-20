# Restart: BUG-019 Hardblock Regression Fix

**Date:** 2026-02-03
**Context Usage at Save:** 87%
**Priority:** High (workflow broken for non-save operations)

---

## Problem Identified

The hardblock enhancement (v3-hardblock) deployed earlier today is too aggressive. It blocks ALL non-save responses because the keyword list includes artifact type names that appear in legitimate list/query output.

**Symptom:**
- User: "list journals"
- AI returns list of journals
- Hardblock detects word "journal" in output
- User receives: "No save was performed. To save something, please use an explicit save command."

**Root Cause:**
Keywords blocked include: `artifact`, `journal`, `project`, `snapshot`, `restart`

These words appear in normal list/query responses, not just hallucinated save claims.

---

## Proposed Fix

Narrow the keyword list to save-success indicators only:

```javascript
// Save-success indicators only (not artifact type names)
const saveAdjacentPatterns = [
  /\bsaved\b/i,
  /\bcreated\b/i,
  /\bpersisted\b/i
];
```

**Remove:** `artifact`, `journal`, `project`, `snapshot`, `restart`

Keep the structured field patterns as-is:
```javascript
const structuredFieldPatterns = [
  /title\s*:/i,
  /tags\s*:/i,
  /payload\s*:/i
];
```

---

## File to Modify

`phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (6).json`

Node: `Sanitize_Non_Save_Response` (id: `sanitize-non-save-001`)

---

## Instructions for Next Session

1. **WAIT for input from Qwrk and user** before applying fix
2. User may have additional constraints or alternative approach
3. Once approved, update the jsCode in Sanitize_Non_Save_Response
4. Update versionId to `bug019-verification-enforcement-v4-narrowed`
5. Test:
   - "list journals" → should return journal list
   - Failure Test 3 ("tell me this was saved...") → should still block
6. Update bug tracker with fix notes

---

## Key Files

| File | Purpose |
|------|---------|
| `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (6).json` | Workflow with regression |
| `docs/Qwrk_Bug_Tracker.md` | BUG-019 entry to update |
| `sessions/OPEN_THREADS.md` | T8 closed but may need addendum |

---

## Session Context

- Session `2026-02-03__009` completed successfully
- BUG-019 verification testing passed (4/4 saves verified in DB)
- Hardblock deployed and Failure Test 3 passed
- Regression discovered after session close during normal usage
- This restart captures the fix to apply next session
