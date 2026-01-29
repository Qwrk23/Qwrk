# Phase 1.5: Chat Gateway

**Created:** 2026-01-29
**Purpose:** Prove n8n AI Agent + Gateway pattern before building custom front-end

---

## Goal

Replace CustomGPT with n8n's native Chat Trigger + AI Agent to:
1. Bypass GPT Actions limitations (BUG-008)
2. Test AI Agent → Gateway payload generation
3. Validate token costs
4. Build reusable agent logic for Phase 2

---

## Architecture

```
Phase 1 (Current):
  User → CustomGPT → GPT Actions → n8n Gateway → Supabase
                          ↑
                    BUG-008 (~760 token limit)

Phase 1.5 (This):
  User → n8n Chat UI → AI Agent → Gateway Logic → Supabase
                          ↑
                    No payload limits
                    Direct LLM API control
```

---

## Quick Start

**Use `QUICK_START.md` for fastest path to testing.**

Import `NQxb_Gateway_Chat_v1_Complete.json`, add OpenAI creds, activate, and chat.

---

## Components

| Component | File | Status |
|-----------|------|--------|
| **Complete Workflow** | `NQxb_Gateway_Chat_v1_Complete.json` | **Ready to Import** |
| Quick Start Guide | `QUICK_START.md` | **Start Here** |
| Original Template | `NQxb_Gateway_Chat_v1.json` | Reference only |
| Detailed Setup | `SETUP_INSTRUCTIONS.md` | For troubleshooting |
| AI Agent System Prompt | `ai-agent-system-prompt.md` | Reference |
| Tool Schemas | `tool-schemas.md` | Reference |
| Test Log | `test-log.md` | Track results |
| Iteration Notes | `iteration-notes.md` | Not Started |

---

## Workflow Changes from Gateway v1

| Original | Chat Version |
|----------|--------------|
| Webhook Trigger | Chat Trigger |
| Expects structured JSON payload | AI Agent parses natural language |
| Returns JSON response | Formats response for chat |

---

## Success Criteria

- [ ] "Show me my recent journals" returns journal list
- [ ] "Save a journal about today's work" creates journal artifact
- [ ] "What projects am I working on?" lists projects
- [ ] Large content (>1KB) saves successfully
- [ ] Agent asks clarifying questions when intent is ambiguous
- [ ] Token costs tracked per interaction

---

## Next Steps

1. Clone NQxb_Gateway_v1
2. Add Chat Trigger
3. Add AI Agent with tool definitions
4. Test with artifact.query first
5. Iterate and expand

---

## Related Documents

- `docs/governance/ROADMAP__Moltbot_Inspired_Features__2026-01-29.md`
- `docs/Qwrk_Bug_Tracker.md` (BUG-008 context)
- Original Gateway: `workflows/NQxb_Gateway_v1 (33).json`
