# QSB Onboarding Guide — Qwrk Beta

---

## What Is QSB?

QSB (Qwrk Sidebar) is a Chrome Extension that sits alongside your ChatGPT conversation. When Q generates a payload for you, QSB detects it and lets you execute it with one click.

You don't need to copy-paste URLs, manage API keys, or leave your conversation. QSB handles execution and shows you the result.

---

## Setup (3 Steps)

### Step 1: Install the Extension

1. You'll receive a folder called `qwrk-sidebar-beta`
2. Open Chrome and go to `chrome://extensions/`
3. Enable **Developer mode** (toggle in the top-right corner)
4. Click **Load unpacked**
5. Select the `qwrk-sidebar-beta` folder
6. The Qwrk icon will appear in your extensions bar

### Step 2: Verify Your Profile

Your extension comes pre-configured with your workspace. No setup needed.

To verify, open a ChatGPT conversation. You should see the QSB sidebar appear on the right side of the page. Your profile name ("Qwrk Beta") should be visible at the top.

### Step 3: Run Your First Test

Open your Qwrk Beta GPT conversation and type:

> "Save a journal: Testing my Qwrk setup"

Q will generate a `prime-exec` payload. In the QSB sidebar:

1. The payload will appear as a staged command
2. Click **Execute**
3. The result will show in the sidebar

Then verify it was saved:

> "Show me my recent journals"

Q will generate a list payload. Execute it, and you should see your test journal in the results.

If both steps work, you're all set.

---

## Per-User QSB Profile Configuration

Each beta user's extension ships with a single profile in `profiles.js`:

```javascript
QSB.profiles = [
  {
    id: "qwrk-beta",
    label: "Qwrk Beta",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2",
    credential: "<BASE64_CREDENTIAL>",
    auth_mode: "basic"
  }
];
```

**Configuration values (provided per user):**

| Field | Value |
|-------|-------|
| `id` | `"qwrk-beta"` |
| `label` | `"Qwrk Beta"` |
| `endpoint` | `"https://n8n.halosparkai.com/webhook/nqxb/gateway/v2"` |
| `credential` | Base64-encoded credential (provided to you) |
| `auth_mode` | `"basic"` |

Do not modify the endpoint or auth_mode. The credential is unique to your workspace.

---

## How QSB Works (Quick Reference)

1. **Q generates a payload** — You'll see a `prime-exec` code block in the conversation
2. **QSB detects it** — The sidebar highlights the staged payload
3. **You click Execute** — QSB sends it to the Gateway and shows the result
4. **You tell Q the result** — Copy the result back or just describe what happened

That's it. Q handles the thinking, you control the execution.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Sidebar doesn't appear | Refresh the ChatGPT page. Make sure the extension is enabled in `chrome://extensions/` |
| "Execute" button doesn't work | Check Developer mode is still on. Try reloading the extension |
| Error result after execution | Copy the error text and paste it to Q — Q will explain and fix it |
| Payload not detected | Make sure Q wrapped the JSON in a `prime-exec` code block. Ask Q to regenerate |

---

## CHANGELOG

### v1 — 2026-03-21
- Initial QSB onboarding guide
- 3-step setup (install, verify, test)
- Per-user profile configuration template
- First test flow: save journal → retrieve it
- Troubleshooting table
