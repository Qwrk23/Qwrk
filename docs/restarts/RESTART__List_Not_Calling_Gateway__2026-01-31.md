# RESTART: List Not Calling Gateway from Telegram

**Date:** 2026-01-31
**Priority:** High (blocking normal operations)
**Status:** Debugging in progress

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

**Root Cause Identified:** Gateway_Telegram workflow's Tool_List is not reaching the main Gateway workflow. The Telegram AI runs, but Gateway/List never executes.

**Verified Working:**
- `NQxb_Artifact_List_v1` - tested directly in n8n, returns 10 projects correctly
- `NQxb_Gateway_v1` - has correct Shape_List_Response pass-through logic
- Direct Supabase query with `deleted_at=is.null` returns correct data

**Not Working:**
- `NQxb_Gateway_Telegram_v1` → Tool_List → Gateway chain

---

## Debugging Next Steps

1. **Check Tool_List in Telegram workflow**
   - Open `NQxb_Gateway_Telegram_v1` in n8n
   - Inspect `Tool_List` node configuration
   - Verify URL: should be `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1`
   - Verify JSON body includes correct `gw_action: "artifact.list"`

2. **Test Tool_List directly**
   - In n8n, manually trigger Tool_List with test input
   - Check if it reaches Gateway webhook

3. **Check n8n execution logs**
   - Look at recent executions of Gateway_Telegram
   - See if Tool_List is being called and what response it gets

4. **Possible issues to check:**
   - Tool_List URL might be wrong
   - Authentication credentials might be missing/invalid
   - The AI might not be calling the tool at all (check AI Agent output)

---

## Key Files

| File | Purpose | Status |
|------|---------|--------|
| `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1.json` | Telegram workflow | Suspect - Tool_List not calling Gateway |
| `workflows/NQxb_Gateway_v1 (37).json` | Main Gateway | Verified working |
| `workflows/NQxb_Artifact_List_v1 (26).json` | List sub-workflow | Verified working |

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
