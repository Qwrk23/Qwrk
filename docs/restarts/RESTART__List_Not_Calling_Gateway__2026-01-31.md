# RESTART: List Not Calling Gateway from Telegram

**Date:** 2026-01-31
**Priority:** High (blocking normal operations)
**Status:** RESOLVED

**Resolution:** Chat Memory was causing AI to skip tool calls. Fixed by:
1. Reduced contextWindowLength temporarily to test
2. Added "CRITICAL RULE: Always call tools" to system prompt
3. Permanent fix deployed to Gateway_Telegram workflow

---

## Context: What Was Accomplished This Session

### Completed
- [x] Tag Backfill v2 executed (all artifacts tagged)
- [x] BUG-011 Telegram tags implementation complete
- [x] Soft-delete feature implemented (delete/restore/list_deleted)
- [x] Soft-delete tested and verified via Telegram
- [x] Cleaned up ~20 test project artifacts via soft-delete

### Bug Discovered During Cleanup
After soft-deleting test projects, `list projects` via Telegram returns "no projects available" even though:
- Direct Supabase query confirms 10+ non-deleted projects exist
- List workflow tested directly in n8n returns correct results (10 projects)

---

## Current Bug Analysis

**Symptom:** Telegram "list projects" returns empty

**Root Cause Identified:** The AI (gpt-4o-mini) is NOT calling Tool_List at all. It's making an assumption based on chat memory.

**Evidence:**
- Gateway_Telegram workflow executed (AI Agent ran)
- Gateway workflow never executed (no webhook call received)
- AI responded "no projects available" without checking

**Likely Cause: Chat Memory**
The `Chat_Memory` node has `contextWindowLength: 12`, meaning the AI remembers the last 12 conversation turns. This includes the session where ~20 projects were deleted. The AI "remembers" deleting all projects and assumes none exist, skipping the Tool_List call entirely.

**Verified Working:**
- `NQxb_Artifact_List_v1` - tested directly in n8n, returns 10 projects correctly
- `NQxb_Gateway_v1` - has correct Shape_List_Response pass-through logic
- Direct Supabase query with `deleted_at=is.null` returns correct data
- Tool_List configuration is correct (URL, auth, JSON body all verified)

---

## Fix Options (Try in Order)

### Option A: Clear Chat Memory (Quick Test)
1. In n8n, open `NQxb_Gateway_Telegram_v1`
2. Find `Chat_Memory` node
3. Temporarily set `contextWindowLength: 1`
4. Save and test "list projects" again
5. If it works, the memory was the issue

### Option B: Force Tool Calls in System Prompt (Permanent Fix)
Add this to the system prompt after the capabilities section:
```
## CRITICAL RULE
ALWAYS call the appropriate tool to check current state. NEVER assume based on previous conversation. The database may have changed between messages.
```

### Option C: Verify Tool is Being Called
1. In n8n, look at execution history for Gateway_Telegram
2. Check if Tool_List node shows in the execution trace
3. If Tool_List is missing from trace, the AI definitely skipped it

---

## Key Files

| File | Purpose | Status |
|------|---------|--------|
| `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (3).json` | Telegram workflow (latest) | Chat memory likely causing AI to skip tool |
| `workflows/NQxb_Gateway_v1 (37).json` | Main Gateway | Verified working |
| `workflows/NQxb_Artifact_List_v1 (26).json` | List sub-workflow | Verified working |

### Tool_List Configuration (Verified Correct)
```json
{
  "url": "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1",
  "jsonBody": {
    "gw_action": "artifact.list",
    "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
    "artifact_type": "{artifact_type}",
    "selector": { "limit": "{limit}", "hydrate": false }
  }
}
```

### Chat_Memory Configuration (Suspect)
```json
{
  "sessionKey": "={{ $('Telegram_Trigger').item.json.message.chat.id }}",
  "contextWindowLength": 12
}
```

---

## Recent Commits

```
729a258 Gateway: Add soft-delete, restore, and list_deleted actions
34f298d Docs: Mark soft-delete feature complete in tracker
```

---

## Test Commands

**Telegram test:**
```
list projects
```

**Expected:** 10 projects including "Tags Test - Project Save", "Seed — Gateway List Pagination", etc.

**Direct n8n List test (pinned input):**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "selector": {
    "limit": 10,
    "hydrate": false
  }
}
```

---

## Trust Restoration Week Status

- [x] BUG-012 (project content persistence)
- [x] BUG-011 (full tags implementation)
- [x] Soft-delete feature implemented
- [ ] **BLOCKED:** List not working via Telegram (this bug)
- [ ] Soft-delete test artifacts (deferred)
- [ ] Promote Gateway+Telegram to Tree
- [ ] Add monthly dead seed archival governance rule
