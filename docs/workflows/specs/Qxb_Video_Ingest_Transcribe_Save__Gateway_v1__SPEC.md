# Qxb_Video_Ingest_Transcribe_Save__Gateway_v1 — Workflow Specification

**Version:** v1 (2026-01-04)
**Status:** Specification (Pre-Build)
**Purpose:** Gateway-triggered video ingest (called from NQxb_Gateway_v1)

---

## Overview

This workflow is invoked by **NQxb_Gateway_v1** when it receives an `artifact.save` request with `artifact_type='video'`.

It extracts `source_url` from the Gateway payload envelope and delegates processing to the Worker workflow.

**Architecture:** Gateway adapter → Worker delegation

---

## Trigger

**Type:** Execute Workflow (called by NQxb_Gateway_v1)

**Invocation Context:** Gateway routing logic for `artifact_type='video'`

---

## Input Contract

### Gateway Envelope (Canonical)

```json
{
  "action": "artifact.save",
  "workspace_id": "uuid (required)",
  "owner_user_id": "uuid (required)",
  "artifact_type": "video",
  "title": "string (optional)",
  "payload": {
    "source_url": "string (required)"
  }
}
```

### Field Extraction Rules

- `source_url` → Extract from `payload.source_url`
- `workspace_id` → Extract from top-level `workspace_id`
- `owner_user_id` → Extract from top-level `owner_user_id`
- `title_override` → Use top-level `title` if provided
- `notes` → Use top-level `summary` if provided (optional)
- `tags` → Merge top-level `tags` with Worker auto-tags (optional)

---

## Output Contract

### Success Response (Gateway-Wrapped)

```json
{
  "status": "ok",
  "artifact_id": "uuid",
  "artifact_type": "video",
  "ingest_status": "complete",
  "deduped": false,
  "idempotency_key": "youtube:<video_id>"
}
```

### Error Response (Gateway-Wrapped)

```json
{
  "status": "error",
  "error": {
    "code": "VIDEO_INGEST_FAILED",
    "message": "Failed to ingest video",
    "details": {
      "stage": "download|transcribe|...",
      "worker_error": "..."
    }
  }
}
```

---

## Node-by-Node Specification

### Node 1: Extract_Payload
**Type:** Code (JavaScript)
**Purpose:** Extract and validate Gateway envelope fields

**Input:**
- `$json.action`
- `$json.workspace_id`
- `$json.owner_user_id`
- `$json.artifact_type`
- `$json.title` (optional)
- `$json.summary` (optional)
- `$json.tags` (optional)
- `$json.payload` (required, should contain `source_url`)

**Logic:**
```javascript
// Validate required Gateway fields
if (!$json.workspace_id || !$json.owner_user_id) {
  return {
    ok: false,
    error: {
      code: 'VALIDATION_ERROR',
      message: 'workspace_id and owner_user_id are required'
    }
  };
}

// Extract source_url from payload
const source_url = $json.payload?.source_url;
if (!source_url) {
  return {
    ok: false,
    error: {
      code: 'VALIDATION_ERROR',
      message: 'payload.source_url is required for video artifacts'
    }
  };
}

// Map Gateway fields to Worker inputs
return {
  ok: true,
  source_url: source_url,
  workspace_id: $json.workspace_id,
  owner_user_id: $json.owner_user_id,
  title_override: $json.title || null,
  notes: $json.summary || null,
  tags: $json.tags || null
};
```

**Output:**
- `ok: true/false`
- `source_url`, `workspace_id`, `owner_user_id`
- `title_override`, `notes`, `tags`
- `error` (if validation failed)

---

### Node 2: Guard_Validation_Error
**Type:** IF
**Purpose:** Short-circuit if Gateway payload is invalid

**Condition:**
```
{{ $json.ok === false }}
```

**Branches:**
- **TRUE** → Return Gateway error envelope
- **FALSE** → Continue to Worker call

---

### Node 3: Return_Validation_Error
**Type:** Set
**Purpose:** Format Gateway-compliant error response

**Set Fields:**
```json
{
  "status": "error",
  "error": {
    "code": "={{ $('Extract_Payload').item.json.error.code }}",
    "message": "={{ $('Extract_Payload').item.json.error.message }}"
  }
}
```

**Routes to:** Final output

---

### Node 4: Call_Worker
**Type:** Execute Workflow
**Purpose:** Delegate to Worker workflow

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

**Wait for Completion:** Yes

**Output:** Worker response envelope

---

### Node 5: Map_Worker_Response
**Type:** Code (JavaScript)
**Purpose:** Transform Worker response to Gateway envelope format

**Input:** Worker response

**Logic:**
```javascript
const workerResponse = $json;

if (workerResponse.ok) {
  // Success - map to Gateway success envelope
  return {
    status: 'ok',
    artifact_id: workerResponse.artifact_id,
    artifact_type: 'video',
    ingest_status: workerResponse.status, // 'complete' or current status
    deduped: workerResponse.deduped || false,
    idempotency_key: workerResponse.idempotency_key
  };
} else {
  // Failure - map to Gateway error envelope
  return {
    status: 'error',
    error: {
      code: 'VIDEO_INGEST_FAILED',
      message: `Failed to ingest video: ${workerResponse.error?.message || 'Unknown error'}`,
      details: {
        stage: workerResponse.error?.stage,
        artifact_id: workerResponse.artifact_id || null,
        worker_error: workerResponse.error
      }
    }
  };
}
```

**Output:** Gateway-compliant success or error envelope

---

## Workflow Flow Diagram

```
Start (Called by NQxb_Gateway_v1)
  ↓
1. Extract_Payload (validate & extract source_url from payload)
  ↓
2. Guard_Validation_Error (IF)
  ↓ (ok=false)              ↓ (ok=true)
3. Return_Validation_Error  4. Call_Worker
                               ↓
                            5. Map_Worker_Response
                               ↓
                            Return to Gateway
```

---

## Integration with NQxb_Gateway_v1

### Gateway Routing Logic (to be implemented)

In **NQxb_Gateway_v1**, add a new branch to the `artifact_type` Switch node:

**Switch Condition:**
```
artifact_type === 'video'
```

**Route to:**
`Qxb_Video_Ingest_Transcribe_Save__Gateway_v1`

**Pass through:** Entire Gateway envelope

---

## Gateway Contract Alignment

### Request Contract (from Gateway_Contract__v1.0)

```json
{
  "action": "artifact.save",
  "workspace_id": "uuid",
  "owner_user_id": "uuid",
  "artifact_type": "video",
  "title": "My Video Title",
  "summary": "Optional notes about the video",
  "tags": ["custom-tag"],
  "payload": {
    "source_url": "https://www.youtube.com/watch?v=..."
  }
}
```

### Response Contract (success)

```json
{
  "status": "ok",
  "artifact_id": "uuid",
  "artifact_type": "video",
  "ingest_status": "complete",
  "deduped": false,
  "idempotency_key": "youtube:<video_id>"
}
```

### Response Contract (error)

```json
{
  "status": "error",
  "error": {
    "code": "VIDEO_INGEST_FAILED",
    "message": "...",
    "details": { ... }
  }
}
```

---

## Error Handling

### Validation Errors
- **Missing source_url:** `VALIDATION_ERROR`
- **Missing workspace_id/owner_user_id:** `VALIDATION_ERROR`

### Worker Errors
- **All Worker failures:** Wrapped in `VIDEO_INGEST_FAILED` envelope with details

---

## Testing

### Test via Gateway

**Request:**
```bash
curl -X POST https://n8n.example.com/webhook/gateway \
  -H "Content-Type: application/json" \
  -d '{
    "action": "artifact.save",
    "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
    "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
    "artifact_type": "video",
    "title": "Test Video via Gateway",
    "payload": {
      "source_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    }
  }'
```

**Expected Response:**
```json
{
  "status": "ok",
  "artifact_id": "<uuid>",
  "artifact_type": "video",
  "ingest_status": "complete",
  "deduped": false
}
```

### KGB Tests

1. **Valid video ingest** (first submission)
2. **Deduplication** (same video_id)
3. **Missing source_url** (validation error)
4. **Invalid YouTube URL** (Worker download failure)

---

## Future Enhancements

1. **Async Processing** (return 202 Accepted, use status polling or webhooks)
2. **Streaming Status Updates** (WebSocket or Server-Sent Events for progress)
3. **Batch Ingest** (accept array of source_urls)

---

**End of Specification**

**Next Steps:**
1. Review and approve
2. Build in n8n GUI
3. Integrate routing in NQxb_Gateway_v1
4. Test end-to-end via Gateway
5. Export JSON and commit
