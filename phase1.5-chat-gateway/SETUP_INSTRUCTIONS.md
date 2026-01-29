# Setup Instructions: Chat Gateway v1

**Version:** 1.0
**Created:** 2026-01-29

---

## Quick Start

### Step 1: Import the Workflow

1. Open n8n
2. Go to Workflows → Import from File
3. Select `NQxb_Gateway_Chat_v1.json`
4. The workflow will be created in inactive state

### Step 2: Configure OpenAI Credentials

1. In the imported workflow, click on `OpenAI_Chat_Model` node
2. Create or select your OpenAI API credentials
3. The workflow uses GPT-4o by default (can change to gpt-4o-mini for lower cost)

### Step 3: Fix Tool Workflow References

The tools reference sub-workflows by ID. You need to update these:

| Tool Node | Current ID | Update To |
|-----------|------------|-----------|
| Tool_Artifact_List | `Wbg4ciSwUSSTrO3C` | Your NQxb_Artifact_List_v1 workflow ID |
| Tool_Artifact_Query | `IsLBYjXJ5R2Djfrv` | Your NQxb_Artifact_Query_v1 workflow ID |
| Tool_Artifact_Save | `SYr4bZheUdCg2w1p` | Your NQxb_Artifact_Save_v1 workflow ID |

**To find workflow IDs:**
- Open each workflow in n8n
- Look at the URL: `https://your-n8n.com/workflow/WORKFLOW_ID`
- Or use the workflow list API

### Step 4: Create Tool Wrapper Nodes

**IMPORTANT:** The sub-workflows expect full Gateway payloads with `gw_workspace_id`. The AI Agent tool output won't have this.

You need to add a Code node before each workflow call that adds required fields:

```javascript
// Add before calling any sub-workflow
const WORKSPACE_ID = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a";
const OWNER_USER_ID = "7097c16c-ed88-4e49-983f-1de80e5cfcea";

return [{
  json: {
    ...$json,
    gw_workspace_id: WORKSPACE_ID,
    owner_user_id: OWNER_USER_ID,
    gw_action: "artifact.list", // or appropriate action
  }
}];
```

### Step 5: Test the Chat Interface

1. Activate the workflow
2. Click the "Chat" button in the workflow canvas (appears with Chat Trigger)
3. Type a test message: "Show me my recent journals"
4. Observe the execution and response

---

## Alternative: HTTP-Based Tools (Simpler)

Instead of calling sub-workflows directly, call your existing Gateway webhook:

### Tool Implementation (Code Tool)

```javascript
// Tool: artifact_list
const GATEWAY_URL = "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1";
const WORKSPACE_ID = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a";

const payload = {
  gw_action: "artifact.list",
  gw_workspace_id: WORKSPACE_ID,
  artifact_type: $input.artifact_type,
  selector: {
    limit: $input.limit || 10,
    hydrate: $input.hydrate || false
  }
};

const response = await fetch(GATEWAY_URL, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": "Basic " + btoa("qwrk-gateway:YOUR_PASSWORD")
  },
  body: JSON.stringify(payload)
});

return await response.json();
```

**Pros of HTTP approach:**
- Uses existing tested Gateway
- No workflow ID management
- Same auth/validation path

**Cons:**
- Extra HTTP hop
- Need to manage credentials in code

---

## Troubleshooting

### "Workflow not found" error
- Check that workflow IDs in tool nodes match your actual workflows
- Ensure referenced workflows are active

### AI Agent doesn't use tools
- Check the system prompt mentions available tools
- Try being more explicit: "Use the artifact_list tool to show my journals"

### Tools return errors
- Check n8n execution logs for the sub-workflow
- Verify required fields (gw_workspace_id) are being passed

### Chat interface not appearing
- Ensure Chat Trigger node is properly configured
- Workflow must be active for chat button to appear

---

## Next Steps After Basic Test Works

1. [ ] Add Tool_Artifact_Update
2. [ ] Add Tool_Artifact_Promote
3. [ ] Add memory/context to AI Agent (conversation history)
4. [ ] Test large content saves (journals >1KB)
5. [ ] Measure token costs per interaction
6. [ ] Document edge cases and improve system prompt

---

## Files in This Folder

| File | Purpose |
|------|---------|
| `README.md` | Overview and goals |
| `SETUP_INSTRUCTIONS.md` | This file |
| `NQxb_Gateway_Chat_v1.json` | Workflow to import |
| `ai-agent-system-prompt.md` | System prompt reference |
| `tool-schemas.md` | Tool definitions reference |
| `test-log.md` | (Create) Record test results |
| `iteration-notes.md` | (Create) Track changes and learnings |
