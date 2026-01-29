# Quick Start: Chat Gateway v1 (Complete Version)

**Time to test:** ~5 minutes

---

## What's Included

The complete workflow (`NQxb_Gateway_Chat_v1_Complete.json`) includes:

- **Chat Trigger** - Built-in chat UI in n8n
- **AI Agent** - GPT-4o-mini with Qwrk system prompt
- **Chat Memory** - Remembers conversation context
- **4 Tools** (pre-configured with your Gateway credentials):
  - `qwrk_list` - List artifacts
  - `qwrk_query` - Get specific artifact
  - `qwrk_save_journal` - Create journal
  - `qwrk_save_project` - Create project

All tools call your existing Gateway webhook directly - no workflow ID configuration needed.

---

## Setup Steps

### Step 1: Import Workflow

1. Open n8n
2. Workflows → Import from File
3. Select `NQxb_Gateway_Chat_v1_Complete.json`

### Step 2: Add OpenAI Credentials

1. Click on `OpenAI_Chat_Model` node
2. Click "Create New Credential" (or select existing)
3. Enter your OpenAI API key
4. Save

### Step 3: Activate and Test

1. Toggle workflow to **Active**
2. Click the **Chat** button (speech bubble icon) in the canvas
3. Type: "Show me my recent journals"
4. Watch it work!

---

## Test Commands

Try these in the chat:

| Command | What Happens |
|---------|--------------|
| "Show me my journals" | Lists recent journals |
| "Show me my projects" | Lists projects |
| "Save a journal titled 'Test' with content 'Hello world'" | Creates journal |
| "Create a seed project called 'New Idea'" | Creates project |
| "Get details of journal [paste-an-id]" | Queries specific artifact |

---

## Key Test: Large Content Save

This proves BUG-008 is bypassed:

```
Save a journal titled "Architecture Discussion" with content:

Today we discussed the future of Qwrk's front-end architecture.
The key points were:

1. CustomGPT has hard limitations (~760 token limit on payloads)
2. A custom front-end would bypass these limits entirely
3. Phase 1.5 uses n8n's Chat Trigger as an intermediate step
4. This proves the AI Agent → Gateway pattern before building UI

We identified several reusable components:
- The Gateway (n8n workflows) carries forward 100%
- The Supabase schema is front-end agnostic
- The AI Agent system prompt and tools are reusable

The conversation helped clarify that Phase 1 (CustomGPT) is
alpha for internal use only. We won't take it to beta because
of the payload limitations.

Next steps:
- Test the Chat Gateway thoroughly
- Measure token costs
- If successful, plan Phase 2 (custom web front-end)

This journal entry is intentionally over 1KB to test that we've
bypassed the GPT Actions serialization limit that was blocking
large content saves in the CustomGPT front-end.
```

If this saves successfully, **Phase 1.5 works**.

---

## What's NOT Included (Yet)

- `artifact.update` - Can add if needed
- `artifact.promote` - Can add if needed
- Error retry logic
- Token usage logging

These can be added as we iterate.

---

## Troubleshooting

### "Credentials not found"
→ Configure OpenAI credentials in the `OpenAI_Chat_Model` node

### "Failed to call Gateway"
→ Check that your n8n instance can reach `https://n8n.halosparkai.com`
→ Verify the Gateway webhook is active

### Agent doesn't use tools
→ Be explicit: "Use the qwrk_list tool to show my journals"
→ Check system prompt is loaded (click AI Agent node)

### Chat button not appearing
→ Workflow must be **Active**
→ Refresh the page

---

## Files

| File | Use |
|------|-----|
| `NQxb_Gateway_Chat_v1_Complete.json` | **Import this one** |
| `NQxb_Gateway_Chat_v1.json` | Original template (ignore) |
| `test-log.md` | Track your test results |

---

## Next Steps After Testing

1. Record results in `test-log.md`
2. Note token usage from n8n execution logs
3. Try edge cases (errors, ambiguous requests)
4. Decide if ready for daily use or needs iteration
