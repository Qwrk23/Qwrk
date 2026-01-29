# Snapshot: Phase 1.5 Chat Gateway Validated

**Date:** 2026-01-29
**Status:** VALIDATED
**Author:** CC (Claude Code)

---

## Summary

Phase 1.5 successfully proves that n8n's Chat Trigger + AI Agent can replace CustomGPT as a front-end for the Qwrk Gateway, bypassing the BUG-008 payload size limitations entirely.

---

## What Was Built

**Workflow:** `phase1.5-chat-gateway/NQxb_Gateway_Chat_v1_HTTP.json`

**Architecture:**
```
User → n8n Chat UI → AI Agent (GPT-4o-mini) → HTTP Request Tools → Gateway → Supabase
```

**Tools Created:**
| Tool | Function | Status |
|------|----------|--------|
| qwrk_list_journals | List journal entries (hardcoded type) | ✅ Working |
| qwrk_query | Query specific artifact by ID | ✅ Working |
| qwrk_save_journal | Create journal entry | ✅ Working |
| qwrk_save_project | Create project | ✅ Ready |

---

## Key Technical Discovery

**n8n HTTP Request Tool parameter syntax:**

❌ **WRONG** (gets saved literally):
```json
"title": "{{ $fromAI('title', 'Title for entry', 'string') }}"
```

✅ **CORRECT** (parameters interpolated):
```json
"jsonBody": "{ \"title\": \"{title}\" }",
"placeholderDefinitions": {
  "values": [
    { "name": "title", "description": "Title for entry", "type": "string" }
  ]
}
```

---

## Issues Resolved

| Issue | Root Cause | Resolution |
|-------|------------|------------|
| Tools not calling Gateway | `toolCode` with `fetch()` unsupported | Use `toolHttpRequest` |
| 403 on all calls | Missing `owner_user_id` in payload | Added to all tools |
| 403 on save | Missing `content: {}` | Added to save payloads |
| Parameters saved literally | `{{ $fromAI() }}` not interpolated | Use `{placeholder}` + `placeholderDefinitions` |

---

## BUG-008 Bypass Confirmed

**Test:** Saved 850-character journal entry through Chat Gateway

**Result:** ✅ Success

This content would have failed through CustomGPT's GPT Actions due to the ~760 token payload limit after boot mode overhead.

---

## What This Validates

1. **AI Agent → Gateway pattern works** - Same Gateway, different front-end
2. **No payload size limits** - Content saves without GPT Actions restrictions
3. **Gateway is 100% reusable** - Zero backend changes required
4. **Path to Phase 2 is clear** - Custom front-end can use this same pattern

---

## Governance Impact

### Phase 1 (CustomGPT)
- Status: **Alpha for internal use only**
- Will NOT proceed to beta due to BUG-008 limitations
- Remains useful for testing Gateway operations

### Phase 1.5 (n8n Chat)
- Status: **Validated**
- Can be used for daily operations immediately
- Proves Phase 2 architecture

### Phase 2 (Custom Front-End)
- Status: **Ready to plan**
- Will use same Gateway + Supabase backend
- AI Agent logic is reusable

---

## Files Created/Modified

```
phase1.5-chat-gateway/
├── README.md
├── QUICK_START.md
├── SETUP_INSTRUCTIONS.md
├── NQxb_Gateway_Chat_v1_HTTP.json    ← Working workflow
├── NQxb_Gateway_Chat_v1_Complete.json ← Original (broken)
├── NQxb_Gateway_Chat_v1.json          ← Template
├── ai-agent-system-prompt.md
├── tool-schemas.md
└── test-log.md                        ← Full test results
```

---

## Setup Requirements

1. Import `NQxb_Gateway_Chat_v1_HTTP.json` into n8n
2. Create HTTP Basic Auth credential for Gateway
3. Configure OpenAI credential for AI Agent
4. Assign credentials to each tool node
5. Activate workflow
6. Click Chat button to test

---

## Next Steps

1. **Clean up test artifacts** - Remove entries with literal `{{ $fromAI() }}` titles
2. **Add list tools for other types** - list_projects, list_snapshots if needed
3. **Begin Phase 2 planning** - Custom web front-end design
4. **Consider Telegram integration** - Alternative chat interface option

---

## Verification SQL

```sql
-- Confirm working saves
SELECT a.title, j.entry_text, a.created_at
FROM qxb_artifact a
JOIN qxb_artifact_journal j ON a.artifact_id = j.artifact_id
WHERE a.created_at > '2026-01-29'
ORDER BY a.created_at DESC;
```

---

**Phase 1.5: VALIDATED**
