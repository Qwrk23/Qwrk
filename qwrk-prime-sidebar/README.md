# Qwrk Prime Sidebar (QSB) v1.0

Internal Prime Operator execution sidebar for Qwrk Gateway.

**This extension is NOT public-facing.** QX (Qwrk Command Console) remains installed and operational as fallback.

## Install

1. Open Chrome → `chrome://extensions/`
2. Enable **Developer mode** (top-right toggle)
3. Click **Load unpacked**
4. Select the `qwrk-prime-sidebar/` folder
5. Navigate to [chatgpt.com](https://chatgpt.com)

The QSB bar appears above ChatGPT's message input area.

## How It Works

1. **Prime emits** a `prime-exec` code block in a ChatGPT response:

   ````
   ```prime-exec
   {
     "gw_action": "artifact.save",
     "gw_workspace_id": "be0d3a48-...",
     "owner_user_id": "c52c7a57-...",
     "artifact_type": "journal",
     "title": "My Entry",
     "tags": ["test"],
     "content": { "note": "Hello" }
   }
   ```
   ````

2. **QSB detects** the block and stages the payload (green indicator)
3. **You click Execute** → payload is sent to the selected Gateway workspace
4. **Result appears** in the execution log (click to expand raw JSON)

## Bar Controls

| Control | Action |
|---------|--------|
| **Execute** | Send staged payload to Gateway |
| **Clear** | Discard staged payload |
| **Workspace dropdown** | Select target Gateway endpoint + credentials |
| **Gear icon** | Toggle QX Debug panel (raw JSON viewer + manual paste) |

## QX Debug Panel

Click the gear icon to open the debug panel:

- **Staged Payload** — read-only view of the staged JSON
- **Manual JSON (QX Mode)** — paste raw JSON and click Stage (same workflow as QX)
- **Copy Staged** / **Copy Last Response** — clipboard helpers
- **Last Request** — shows endpoint, masked auth header, HTTP status

## Workspace Profiles

Profiles are configured in `profiles.js`. Same model as QX:

```javascript
{
  id: "qwrk-personal",
  label: "Qwrk Prime",
  endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1",
  credential: "<base64>",
  auth_mode: "basic"    // "basic" (v1) | "bearer" (future)
}
```

Selected workspace persists via `chrome.storage.local`.

## Rules

- QSB sends payloads exactly as received — no mutation, no inference
- Exactly one staged operation at a time
- No auto-execution — manual Execute click required
- Staged payload clears on successful execution
- Staged payload clears on conversation/thread switch
- Failed execution retains staged payload for retry

## Auth

v1 ships with **Basic Auth** (`Authorization: Basic <base64>`).

Per-profile `auth_mode` switch supports future Bearer migration. Auth logic is isolated in `auth.js`.

## File Structure

```
qwrk-prime-sidebar/
├── manifest.json      MV3 manifest
├── profiles.js        Workspace profiles + selection persistence
├── auth.js            Auth provider (basic/bearer abstraction)
├── state.js           Staged object state machine
├── parser.js          prime-exec block scanner (MutationObserver)
├── executor.js        Gateway fetch handler
├── ui.js              Shadow DOM UI (bar + log + debug panel)
├── content.js         Entry point + SPA navigation watcher
├── styles.css         Isolated styles (loaded into Shadow DOM)
└── README.md          This file
```

## Troubleshooting

**Bar not visible:**
- Reload the ChatGPT page after installing
- Check `chrome://extensions/` for errors
- Verify the extension matches `chatgpt.com` or `chat.openai.com`

**prime-exec block not detected:**
- Ensure the code block uses the exact label `prime-exec`
- Check Chrome DevTools console for `[QSB]` prefixed messages
- The parser scans only the most recent assistant message

**Gateway errors:**
- Expand the error entry in the execution log for raw JSON
- Open the debug panel to see the masked request details
- Verify the correct workspace is selected

**QX still works:**
- QSB and QX are independent extensions with no cross-communication
- Both can be installed and used simultaneously
