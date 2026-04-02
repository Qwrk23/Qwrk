# Qwrk Beta — Akazanar Extension Install Guide

## What's In This Folder

| Folder | What It Does | When To Install |
|--------|-------------|-----------------|
| `qwrk-chrome-akazanar/` | **Qx** — JSON Command Console. Paste JSON payloads, send to Qwrk Gateway. | **Phase 1 — Install now** |
| `qwrk-sidebar-akazanar/` | **QSB** — Prime Sidebar. Auto-detects Qwrk commands in ChatGPT, one-click execute. | **Phase 2 — After 12 Qx executions** |

## Phase 1: Install Qx (Chrome Extension)

1. Open Chrome and go to `chrome://extensions/`
2. Toggle **Developer mode** ON (top-right switch)
3. Click **Load unpacked**
4. Select the `qwrk-chrome-akazanar` folder
5. The Qx icon appears in your Chrome toolbar — click it to open

### Using Qx

- Paste a JSON payload into the text area
- Click **Send to Akazanar (Beta)**
- The response appears below

### Example Test Payload

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "01c43873-9bfb-48fd-9eae-65a4d9e062f1",
  "artifact_type": "journal",
  "title": "My first Qwrk entry",
  "extension": {
    "entry_text": "Testing Qwrk Beta from Qx!"
  }
}
```

## Phase 2: Install QSB (After 12 Qx Executions)

1. Go to `chrome://extensions/`
2. Click **Load unpacked**
3. Select the `qwrk-sidebar-akazanar` folder
4. Open [ChatGPT](https://chatgpt.com) — the QSB bar appears above the chat input

### Using QSB

- When Qwrk (your Custom GPT) outputs a `prime-exec` block, QSB auto-detects it
- Click **Execute** to send it to the Gateway
- Results appear in the sidebar — click **Insert Into Chat** to paste back to Q

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Extension doesn't appear | Make sure Developer mode is ON, then reload the extension |
| "Network error" on send | Check your internet connection. The Gateway is at `n8n.halosparkai.com` |
| 401 Unauthorized | Contact Joel — your credential may need updating |
| QSB doesn't detect payloads | Make sure QSB is loaded on `chatgpt.com`. Try refreshing the page. |

## Important Notes

- **Only one sidebar extension** can be active at a time on ChatGPT. If you have Qwrk Prime Sidebar installed, disable it before enabling QSB Akazanar.
- Your workspace ID (`01c43873-9bfb-48fd-9eae-65a4d9e062f1`) is pre-configured. You don't need to include `gw_workspace_id` in QSB payloads — it's injected automatically.
- All your artifacts are stored in your own workspace. Other beta users cannot see them.
