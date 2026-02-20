# Qxb_Video_Get_v1 — Workflow Specification

**Version:** v1 (2026-01-04)
**Status:** Specification (Pre-Build)
**Purpose:** Get single video artifact by ID with full transcript (Gateway subworkflow)

---

## Overview

This workflow implements the **get/query operation** for a single video artifact. It fetches the spine and extension, merges them, and returns the complete artifact including the full transcript.

**Architecture:** Gateway read subworkflow (called by NQxb_Gateway_v1 for `artifact.query` + `artifact_type=video`)

---

## Trigger

**Type:** Execute Workflow (called by Gateway)

**Invocation Context:** Gateway `artifact.query` action with `artifact_type='video'`

---

## Input Contract

### Gateway Request

```json
{
  "action": "artifact.query",
  "workspace_id": "uuid (required)",
  "artifact_id": "uuid (required)",
  "artifact_type": "video"
}
```

---

## Output Contract

### Success Response

```json
{
  "status": "ok",
  "artifact": {
    "artifact_id": "uuid",
    "workspace_id": "uuid",
    "owner_user_id": "uuid",
    "artifact_type": "video",
    "title": "...",
    "summary": "...",
    "priority": 3,
    "tags": ["video", "youtube"],
    "created_at": "2026-01-04T10:00:00Z",
    "updated_at": "2026-01-04T10:05:00Z",
    "video": {
      "source_url": "https://www.youtube.com/watch?v=...",
      "source_platform": "youtube",
      "source_video_id": "dQw4w9WgXcQ",
      "source_channel": "Example Channel",
      "source_published_at": "2025-01-01T00:00:00Z",
      "duration_seconds": 212,
      "status": "complete",
      "idempotency_key": "youtube:dQw4w9WgXcQ",
      "transcription": {
        "engine": "openai",
        "model": "whisper-1",
        "response_format": "verbose_json",
        "segments": [
          {
            "chunk_index": 0,
            "start": 0.0,
            "end": 5.2,
            "text": "Never gonna give you up..."
          }
        ],
        "full_text": "Never gonna give you up..."
      },
      "ingest": {
        "idempotency_key": "youtube:dQw4w9WgXcQ",
        "source_platform": "youtube",
        "source_url": "https://...",
        "source_video_id": "dQw4w9WgXcQ"
      },
      "error": null,
      "created_at": "2026-01-04T10:00:00Z",
      "updated_at": "2026-01-04T10:05:00Z"
    }
  }
}
```

### Error Response - NOT_FOUND

```json
{
  "status": "error",
  "error": {
    "code": "NOT_FOUND",
    "message": "Video artifact not found",
    "artifact_id": "uuid"
  }
}
```

### Error Response - TYPE_MISMATCH

```json
{
  "status": "error",
  "error": {
    "code": "TYPE_MISMATCH",
    "message": "Artifact exists but is not type 'video'",
    "artifact_id": "uuid",
    "actual_type": "project"
  }
}
```

---

## Node-by-Node Specification

### Node 1: Validate_Input
**Type:** Code (JavaScript)
**Purpose:** Validate required fields

**Input:**
- `$json.workspace_id`
- `$json.artifact_id`
- `$json.artifact_type` (should be 'video')

**Logic:**
```javascript
if (!$json.workspace_id || !$json.artifact_id) {
  return {
    ok: false,
    error: {
      code: 'VALIDATION_ERROR',
      message: 'workspace_id and artifact_id are required'
    }
  };
}

return {
  ok: true,
  workspace_id: $json.workspace_id,
  artifact_id: $json.artifact_id,
  artifact_type: $json.artifact_type || 'video'
};
```

**Output:**
- `ok: true/false`
- `workspace_id`, `artifact_id`, `artifact_type`
- `error` (if validation failed)

---

### Node 2: Guard_Validation_Error
**Type:** IF
**Purpose:** Short-circuit if validation failed

**Condition:**
```
{{ $json.ok === false }}
```

**Branches:**
- **TRUE** → Return error envelope
- **FALSE** → Continue to spine query

---

### Node 3: Query_Spine
**Type:** Supabase (SELECT)
**Purpose:** Fetch artifact from spine table

**Credentials:** "Qwrk Supabase – Kernel v1"

**Table:** `qxb_artifact`

**Filters:**
- `workspace_id` = `{{ $json.workspace_id }}`
- `artifact_id` = `{{ $json.artifact_id }}`
- `deleted_at` IS NULL

**Return Fields:** ALL

**Output:**
- Spine record (or empty if not found)

---

### Node 4: Guard_Not_Found
**Type:** IF
**Purpose:** Check if artifact exists

**Condition:**
```
{{ $json.artifact_id === undefined || $json.artifact_id === null }}
```

**Branches:**
- **TRUE** → Return NOT_FOUND error
- **FALSE** → Continue to type check

---

### Node 5: Return_Not_Found
**Type:** Set
**Purpose:** Format NOT_FOUND error response

**Set Fields:**
```json
{
  "status": "error",
  "error": {
    "code": "NOT_FOUND",
    "message": "Video artifact not found",
    "artifact_id": "={{ $('Validate_Input').item.json.artifact_id }}"
  }
}
```

**Routes to:** Final output

---

### Node 6: Check_Type_Match
**Type:** Code (JavaScript)
**Purpose:** Verify artifact_type is 'video'

**Logic:**
```javascript
const storedType = $json.artifact_type?.trim();
const requestedType = $('Validate_Input').item.json.artifact_type?.trim();

if (storedType !== 'video') {
  return {
    ok: false,
    error: {
      code: 'TYPE_MISMATCH',
      message: `Artifact exists but is not type 'video'`,
      artifact_id: $json.artifact_id,
      requested_type: requestedType,
      actual_type: storedType
    }
  };
}

return {
  ok: true,
  spine: $json
};
```

**Output:**
- `ok: true/false`
- `spine` (if type matches)
- `error` (if type mismatch)

---

### Node 7: Guard_Type_Mismatch
**Type:** IF
**Purpose:** Short-circuit if type mismatch

**Condition:**
```
{{ $json.ok === false }}
```

**Branches:**
- **TRUE** → Return TYPE_MISMATCH error
- **FALSE** → Continue to extension query

---

### Node 8: Return_Type_Mismatch
**Type:** Set
**Purpose:** Format TYPE_MISMATCH error response

**Set Fields:**
```json
{
  "status": "error",
  "error": "={{ $json.error }}"
}
```

**Routes to:** Final output

---

### Node 9: Query_Extension
**Type:** Supabase (SELECT)
**Purpose:** Fetch video extension data

**Credentials:** "Qwrk Supabase – Kernel v1"

**Table:** `qxb_artifact_video`

**Filters:**
- `artifact_id` = `{{ $('Validate_Input').item.json.artifact_id }}`

**Return Fields:** ALL

**Output:**
- Extension record (should always exist if spine exists)

---

### Node 10: Merge_Artifact
**Type:** Code (JavaScript)
**Purpose:** Merge spine and extension into final artifact object

**Logic:**
```javascript
const spine = $('Check_Type_Match').item.json.spine;
const extension = $json;

// Extract transcription and ingest from content JSONB
const content = extension.content || {};
const transcription = content.transcription || null;
const ingest = content.ingest || null;

return {
  artifact_id: spine.artifact_id,
  workspace_id: spine.workspace_id,
  owner_user_id: spine.owner_user_id,
  artifact_type: spine.artifact_type,
  title: spine.title,
  summary: spine.summary,
  priority: spine.priority,
  tags: spine.tags,
  created_at: spine.created_at,
  updated_at: spine.updated_at,
  video: {
    source_url: extension.source_url,
    source_platform: extension.source_platform,
    source_video_id: extension.source_video_id,
    source_channel: extension.source_channel,
    source_published_at: extension.source_published_at,
    duration_seconds: extension.duration_seconds,
    status: extension.status,
    idempotency_key: extension.idempotency_key,
    transcription: transcription,
    ingest: ingest,
    error: extension.error,
    created_at: extension.created_at,
    updated_at: extension.updated_at
  }
};
```

**Output:** Complete merged artifact

---

### Node 11: Format_Response
**Type:** Set
**Purpose:** Wrap artifact in Gateway success envelope

**Set Fields:**
```json
{
  "status": "ok",
  "artifact": "={{ $json }}"
}
```

**Output:** Gateway-compliant success response

---

## Workflow Flow Diagram

```
Start (Called by Gateway)
  ↓
1. Validate_Input
  ↓
2. Guard_Validation_Error (IF)
  ↓ (ok=false)        ↓ (ok=true)
Return Error       3. Query_Spine
                      ↓
                   4. Guard_Not_Found (IF)
                     ↓ (not found)     ↓ (found)
                   5. Return_Not_Found  6. Check_Type_Match
                                          ↓
                                       7. Guard_Type_Mismatch (IF)
                                         ↓ (mismatch)      ↓ (match)
                                       8. Return_Type_Mismatch  9. Query_Extension
                                                                  ↓
                                                               10. Merge_Artifact
                                                                  ↓
                                                               11. Format_Response
                                                                  ↓
                                                               Return to Gateway
```

---

## Response Payload Details

### Transcription Object Structure

```json
{
  "engine": "openai",
  "model": "whisper-1",
  "response_format": "verbose_json",
  "segments": [
    {
      "chunk_index": 0,
      "start": 0.0,
      "end": 5.2,
      "text": "Segment text"
    }
  ],
  "full_text": "Complete concatenated transcript"
}
```

### Ingest Object Structure

```json
{
  "idempotency_key": "youtube:dQw4w9WgXcQ",
  "source_platform": "youtube",
  "source_url": "https://www.youtube.com/watch?v=...",
  "source_video_id": "dQw4w9WgXcQ"
}
```

### Error Object (if status = failed)

```json
{
  "stage": "download|chunk|transcribe|stitch|save",
  "message": "Human-readable error message",
  "timestamp": "2026-01-04T10:00:00Z"
}
```

---

## Error Handling

### NOT_FOUND Scenarios
1. Artifact doesn't exist in `qxb_artifact`
2. Artifact exists but belongs to different workspace
3. Artifact was soft-deleted (`deleted_at IS NOT NULL`)

### TYPE_MISMATCH Scenarios
1. Artifact exists but `artifact_type != 'video'`
2. Caller requested `artifact_type=video` but stored type is different

### VALIDATION_ERROR Scenarios
1. Missing `workspace_id`
2. Missing `artifact_id`

---

## RLS Policy Compliance

**Workspace Isolation:**
- Query filters by `workspace_id` to respect RLS
- Users can only query videos in workspaces they have membership

**Video Visibility:**
- Videos are **workspace-visible** (not owner-private like journals)
- Any workspace member can query video artifacts

---

## Performance

**Expected Query Time:**
- < 20ms for single artifact fetch (indexed by PK)
- Transcript size typically 10-50KB for 10-minute video
- No performance concerns for typical use cases

---

## Testing

### Test Cases

1. **Valid video artifact**
   ```json
   {
     "action": "artifact.query",
     "workspace_id": "...",
     "artifact_id": "<valid-video-artifact-id>",
     "artifact_type": "video"
   }
   ```
   **Expected:** Success, full transcript returned

2. **Non-existent artifact_id**
   ```json
   {
     "action": "artifact.query",
     "workspace_id": "...",
     "artifact_id": "00000000-0000-0000-0000-000000000000",
     "artifact_type": "video"
   }
   ```
   **Expected:** NOT_FOUND error

3. **Type mismatch (request video, artifact is project)**
   ```json
   {
     "action": "artifact.query",
     "workspace_id": "...",
     "artifact_id": "<project-artifact-id>",
     "artifact_type": "video"
   }
   ```
   **Expected:** TYPE_MISMATCH error

4. **Wrong workspace_id**
   ```json
   {
     "action": "artifact.query",
     "workspace_id": "<different-workspace>",
     "artifact_id": "<video-artifact-id>",
     "artifact_type": "video"
   }
   ```
   **Expected:** NOT_FOUND (RLS blocks cross-workspace access)

5. **Failed video artifact**
   ```json
   {
     "action": "artifact.query",
     "workspace_id": "...",
     "artifact_id": "<failed-video-id>",
     "artifact_type": "video"
   }
   ```
   **Expected:** Success, `status: 'failed'`, `error` object populated, `transcription: null`

---

## Integration with NQxb_Gateway_v1

### Gateway Routing Logic (to be implemented)

In **NQxb_Gateway_v1**, add routing for `artifact.query` with `artifact_type='video'`:

**Switch Condition:**
```
artifact_type === 'video' AND action === 'artifact.query'
```

**Route to:**
`Qxb_Video_Get_v1`

**Pass through:** Gateway envelope

---

## Future Enhancements

1. **Partial Transcript** (return only segments, not full_text, for bandwidth optimization)
2. **Transcript Formatting** (SRT, VTT export formats)
3. **Segment Search** (query specific time ranges)
4. **Related Artifacts** (show child gems/snapshots spawned from this video)

---

**End of Specification**

**Next Steps:**
1. Review and approve
2. Build in n8n GUI
3. Integrate routing in NQxb_Gateway_v1
4. Test with completed/failed/non-existent artifacts
5. Export JSON and commit
