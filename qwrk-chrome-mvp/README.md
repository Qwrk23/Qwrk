# Qwrk Chrome Extension - JSON Command Console

Minimal Chrome Extension for sending JSON payloads to Qwrk Gateway.

## Setup

### 1. Add Credentials

Edit `popup.js` line 9 and replace the placeholder:

```javascript
const BASIC_AUTH_CREDENTIAL = "YOUR_BASE64_CREDENTIALS_HERE";
```

Generate the base64 value in your browser console:
```javascript
btoa("username:password")
```

### 2. Load Extension in Chrome

1. Open `chrome://extensions/`
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked"
4. Select this folder (`qwrk-chrome-mvp`)

If already loaded, click the refresh icon on the extension card.

## Usage

1. Click the extension icon in toolbar
2. Paste a JSON payload into the textarea
3. Click "Send to Qwrk"
4. View response in the panel below

## Example Payloads

### Save a Journal

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "artifact_type": "journal",
  "title": "My Journal Entry",
  "tags": ["chrome", "test"],
  "content": { "note": "Content here" }
}
```

### List Journals

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "selector": { "limit": 5 }
}
```

### Query an Artifact

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "artifact_id": "YOUR_ARTIFACT_ID_HERE"
}
```

## Files

| File | Purpose |
|------|---------|
| manifest.json | MV3 manifest with host permissions |
| popup.html | Textarea + button + response panel |
| popup.js | JSON validation + POST logic |
