# Qxb_Video_Ingest_Transcribe_Save_v1 — Workflow Specification

**Version:** v1 (2026-01-04)
**Status:** Specification (Pre-Build)
**Purpose:** Standalone form/webhook trigger for video ingest (calls Worker)

---

## Overview

This workflow provides a **standalone entry point** for video ingest operations, callable via:
- Manual n8n form submission (testing)
- External webhook (future integrations)

It normalizes user input and delegates all processing to the Worker workflow.

**Architecture:** Thin trigger wrapper around `Qxb_Video_Ingest_Transcribe_Save__Worker_v1`

---

## Trigger

**Type:** Webhook / Form

**HTTP Method:** POST

**Path:** `/video/ingest` (or similar, TBD based on n8n webhook configuration)

**Authentication:** None (MVP - add API key auth in future)

---

## Input Contract

### Form Fields / Webhook Payload

```json
{
  "source_url": "string (required) - YouTube video URL",
  "title_override": "string (optional) - Custom title",
  "tags": "string (optional) - Comma-separated tags or array",
  "notes": "string (optional) - User notes"
}
```

### Hardcoded Configuration (MVP Single-User)

Since this is a standalone trigger without Gateway authentication context, it requires **hardcoded workspace_id and owner_user_id**.

**Configuration Source:** Environment variables or Config node

**Required Values (to be provided by Master Joel):**
- `QWRK_DEFAULT_WORKSPACE_ID` - UUID for default workspace
- `QWRK_DEFAULT_OWNER_USER_ID` - UUID for default user

---

## Output Contract

### Success Response

```json
{
  "ok": true,
  "deduped": false,
  "artifact_id": "uuid",
  "status": "complete",
  "idempotency_key": "youtube:<video_id>",
  "message": "Video ingested and transcribed successfully"
}
```

### Failure Response

```json
{
  "ok": false,
  "artifact_id": "uuid or null",
  "status": "failed",
  "error": {
    "stage": "download|transcribe|etc",
    "message": "Error message"
  }
}
```

---

## Node-by-Node Specification

### Node 1: Trigger_Webhook
**Type:** Webhook
**Purpose:** Receive HTTP POST with video URL

**HTTP Response Mode:** Wait for workflow to finish (blocking)

**Input:** POST body JSON

**Output:**
- `source_url`
- `title_override` (optional)
- `tags` (optional)
- `notes` (optional)

---

### Node 2: Config_Default_User
**Type:** Set
**Purpose:** Inject hardcoded workspace_id and owner_user_id for MVP

**Set Fields:**
```json
{
  "workspace_id": "{{ $env.QWRK_DEFAULT_WORKSPACE_ID || 'PLACEHOLDER_UUID' }}",
  "owner_user_id": "{{ $env.QWRK_DEFAULT_OWNER_USER_ID || 'PLACEHOLDER_UUID' }}"
}
```

**Notes:**
- Use environment variables if available
- Fall back to placeholders that require manual configuration
- Future: Remove this node when user authentication is implemented

**Output:**
- All fields from webhook payload
- Plus: `workspace_id`, `owner_user_id`

---

### Node 3: Validate_Config
**Type:** IF
**Purpose:** Check if workspace_id/owner_user_id are configured

**Condition:**
```
{{ $json.workspace_id === 'PLACEHOLDER_UUID' || $json.owner_user_id === 'PLACEHOLDER_UUID' }}
```

**Branches:**
- **TRUE** → Return configuration error
- **FALSE** → Continue to Worker call

---

### Node 4: Return_Config_Error
**Type:** Respond to Webhook
**Purpose:** Return error if config missing

**Response:**
```json
{
  "ok": false,
  "error": {
    "stage": "config",
    "message": "QWRK_DEFAULT_WORKSPACE_ID and QWRK_DEFAULT_OWNER_USER_ID must be configured. See workflow README for setup instructions."
  }
}
```

**HTTP Status:** 500

---

### Node 5: Call_Worker
**Type:** Execute Workflow
**Purpose:** Delegate processing to Worker workflow

**Workflow:** `Qxb_Video_Ingest_Transcribe_Save__Worker_v1`

**Input Fields:**
```json
{
  "source_url": "={{ $json.source_url }}",
  "workspace_id": "={{ $json.workspace_id }}",
  "owner_user_id": "={{ $json.owner_user_id }}",
  "title_override": "={{ $json.title_override }}",
  "tags": "={{ $json.tags }}",
  "notes": "={{ $json.notes }}"
}
```

**Wait for Completion:** Yes (blocking call)

**Output:** Worker response envelope (`ok`, `artifact_id`, `status`, etc.)

---

### Node 6: Format_Response
**Type:** Set
**Purpose:** Add user-friendly message to response

**Logic:**
```javascript
const response = $json;
if (response.ok && !response.deduped) {
  response.message = 'Video ingested and transcribed successfully';
} else if (response.ok && response.deduped) {
  response.message = 'Video already exists (deduplication)';
} else {
  response.message = `Ingestion failed: ${response.error?.message || 'Unknown error'}`;
}
return response;
```

**Output:** Enhanced response envelope

---

### Node 7: Respond_Success
**Type:** Respond to Webhook
**Purpose:** Return final response to caller

**Response:** `{{ $json }}`

**HTTP Status:**
- 200 if `ok: true`
- 500 if `ok: false`

---

## Workflow Flow Diagram

```
1. Trigger_Webhook (POST /video/ingest)
  ↓
2. Config_Default_User (inject workspace_id/owner_user_id)
  ↓
3. Validate_Config (IF)
  ↓ (missing config)    ↓ (config OK)
4. Return_Config_Error   5. Call_Worker
                           ↓
                        6. Format_Response
                           ↓
                        7. Respond_Success
```

---

## Configuration Requirements

**Before first use, configure:**

**Option A: Environment Variables (recommended)**
1. In n8n Settings → Environment Variables, add:
   - `QWRK_DEFAULT_WORKSPACE_ID` = `<uuid>`
   - `QWRK_DEFAULT_OWNER_USER_ID` = `<uuid>`

**Option B: Node Editing (fallback)**
1. Edit Node 2 (Config_Default_User)
2. Replace `PLACEHOLDER_UUID` with actual UUIDs

**Canonical UUIDs (to be provided by Master Joel):**
- workspace_id: (TBD)
- owner_user_id: (TBD)

---

## Testing

### Manual Test via n8n GUI

1. Activate workflow
2. Open webhook URL in browser or use `curl`:

```bash
curl -X POST https://n8n.example.com/webhook/video/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "source_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "title_override": "Test Video",
    "tags": "test,youtube",
    "notes": "Test ingestion from standalone trigger"
  }'
```

3. Verify response:
   - `ok: true`
   - `artifact_id` returned
   - `status: complete`

### KGB Test

1. Submit real YouTube video URL (public domain test video)
2. Verify artifact created in `qxb_artifact` and `qxb_artifact_video`
3. Verify transcript in `content.transcription.full_text`
4. Submit same URL again, verify deduplication (`deduped: true`)

---

## Error Handling

### Configuration Error
- **Trigger:** Placeholder UUIDs not replaced
- **Response:** HTTP 500, `stage: 'config'`
- **Fix:** Configure environment variables or edit Config node

### Worker Error
- **Trigger:** Any Worker failure (download, transcribe, etc.)
- **Response:** HTTP 500, Worker error envelope passed through
- **Fix:** Check Worker logs, retry with valid URL

---

## Future Enhancements

1. **API Key Authentication** (protect webhook from public access)
2. **User Context from JWT** (replace hardcoded workspace_id/owner_user_id)
3. **Async Response** (return 202 Accepted, use webhook callback for completion)
4. **Rate Limiting** (prevent abuse)

---

**End of Specification**

**Next Steps:**
1. Obtain canonical workspace_id and owner_user_id from Master Joel
2. Build workflow in n8n GUI
3. Configure environment variables
4. Test with real YouTube URL
5. Export JSON and commit
