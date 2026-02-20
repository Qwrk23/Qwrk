# Qxb_Video_Ingest_Transcribe_Save__Worker_v1 — Workflow Specification

**Version:** v1 (2026-01-04)
**Status:** Specification (Pre-Build)
**Purpose:** Canonical worker workflow for video ingest, transcription, and save operations

---

## Overview

This workflow is the **core video processing pipeline** for Qwrk Video Artifacts v1. It handles:
- YouTube video download (audio-only)
- Audio chunking for whisper-1 API limits
- Transcription with OpenAI whisper-1
- Transcript stitching and normalization
- Database save (spine + extension)
- Idempotency and deduplication
- Status lifecycle tracking
- Error capture and cleanup

**Architecture:** This is a **worker workflow** (Execute Workflow trigger only) called by:
- Standalone form/webhook trigger
- Gateway-triggered ingest

---

## Trigger

**Type:** Execute Workflow (no direct HTTP/webhook trigger)

**Called by:**
- `Qxb_Video_Ingest_Transcribe_Save_v1` (standalone)
- `Qxb_Video_Ingest_Transcribe_Save__Gateway_v1` (Gateway-triggered)

---

## Input Contract

### Required Fields

```json
{
  "source_url": "string (required) - YouTube video URL",
  "workspace_id": "uuid (required) - FK to qxb_workspace",
  "owner_user_id": "uuid (required) - FK to qxb_user"
}
```

### Optional Fields

```json
{
  "title_override": "string (optional) - Custom title instead of auto-generated",
  "tags": "array<string> (optional) - Additional tags beyond auto-added video/youtube",
  "notes": "string (optional) - User notes to store in artifact.summary"
}
```

### Input Validation Rules

- `source_url` must be non-empty string
- `workspace_id` must be valid UUID format
- `owner_user_id` must be valid UUID format
- `tags` if provided, must be array (normalized from comma-separated string if needed)

---

## Output Contract

### Success (New Artifact)

```json
{
  "ok": true,
  "deduped": false,
  "artifact_id": "uuid",
  "status": "complete",
  "idempotency_key": "youtube:<video_id> or youtube_url_hash:<sha256>"
}
```

### Success (Deduplicated)

```json
{
  "ok": true,
  "deduped": true,
  "artifact_id": "uuid",
  "status": "complete|queued|downloading|...",
  "idempotency_key": "youtube:<video_id> or youtube_url_hash:<sha256>"
}
```

### Failure

```json
{
  "ok": false,
  "artifact_id": "uuid or null",
  "status": "failed",
  "error": {
    "stage": "normalize|dedup|create_spine|download|chunk|transcribe|stitch|save",
    "message": "Human-readable error message",
    "details": "Additional error context (optional)"
  }
}
```

---

## Status Lifecycle

Video artifacts transition through the following status values (stored in `qxb_artifact_video.status`):

1. **queued** - Initial state after DB insert
2. **downloading** - yt-dlp download in progress
3. **chunking** - ffmpeg chunking in progress
4. **transcribing** - OpenAI API transcription in progress
5. **stitching** - Concatenating transcript segments
6. **saving** - Updating DB with final transcript
7. **complete** - Successfully completed (terminal state)
8. **failed** - Error occurred (terminal state)

**Status update strategy:**
- Status is persisted to DB **before** each stage begins
- If stage fails, status is set to `failed` and error JSONB is populated
- Terminal states (complete/failed) are never overwritten

---

## Node-by-Node Specification

### Node 1: Normalize_Input
**Type:** Code (JavaScript)
**Purpose:** Validate and normalize input fields

**Input:**
- `$json.source_url`
- `$json.workspace_id`
- `$json.owner_user_id`
- `$json.title_override` (optional)
- `$json.tags` (optional)
- `$json.notes` (optional)

**Logic:**
```javascript
// Validate required fields
if (!$json.source_url || !$json.workspace_id || !$json.owner_user_id) {
  return {
    ok: false,
    error: {
      stage: 'normalize',
      message: 'Missing required fields: source_url, workspace_id, owner_user_id'
    }
  };
}

// Normalize tags to array
let tags = ['video', 'youtube'];
if ($json.tags) {
  if (Array.isArray($json.tags)) {
    tags = tags.concat($json.tags);
  } else if (typeof $json.tags === 'string') {
    tags = tags.concat($json.tags.split(',').map(t => t.trim()));
  }
}

// Extract YouTube video_id (best effort)
const urlMatch = $json.source_url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&?\/]+)/);
const video_id = urlMatch ? urlMatch[1] : null;

// Compute idempotency_key
const idempotency_key = video_id
  ? `youtube:${video_id}`
  : `youtube_url_hash:${crypto.createHash('sha256').update($json.source_url).digest('hex')}`;

// Generate title if not provided
const title = $json.title_override || (video_id ? `Video: ${video_id}` : `Video: ${idempotency_key.slice(0, 16)}...`);

return {
  ok: true,
  source_url: $json.source_url,
  source_platform: 'youtube',
  source_video_id: video_id,
  workspace_id: $json.workspace_id,
  owner_user_id: $json.owner_user_id,
  title: title,
  summary: $json.notes || 'Video transcript (ingested)',
  tags: tags,
  idempotency_key: idempotency_key
};
```

**Output:**
- `ok: true/false`
- `source_url`, `source_platform`, `source_video_id`
- `workspace_id`, `owner_user_id`
- `title`, `summary`, `tags`
- `idempotency_key`
- `error` (if validation failed)

**Error Handling:**
- If validation fails, output `ok: false` and skip to final error output

---

### Node 2: Guard_Validation_Error
**Type:** IF
**Purpose:** Short-circuit if validation failed

**Condition:**
```
{{ $json.ok === false }}
```

**Branches:**
- **TRUE** → Route directly to final error output (skip all processing)
- **FALSE** → Continue to dedup check

---

### Node 3: Check_Dedup
**Type:** Supabase (SELECT)
**Purpose:** Query for existing artifact by idempotency_key

**Credentials:** "Qwrk Supabase – Kernel v1"

**Table:** `qxb_artifact_video`

**Query:**
- **Filter:** `idempotency_key` = `{{ $json.idempotency_key }}`
- **Return fields:** `artifact_id`, `status`
- **Limit:** 1

**Output:**
- If found: `artifact_id`, `status`
- If not found: empty result

---

### Node 4: Guard_Dedup_Found
**Type:** IF
**Purpose:** Check if dedup record exists

**Condition:**
```
{{ $json.artifact_id !== undefined && $json.artifact_id !== null }}
```

**Branches:**
- **TRUE** → Return deduped response (skip processing)
- **FALSE** → Continue to spine creation

---

### Node 5: Return_Deduped
**Type:** Code (JavaScript)
**Purpose:** Format deduped success response

**Logic:**
```javascript
return {
  ok: true,
  deduped: true,
  artifact_id: $json.artifact_id,
  status: $json.status,
  idempotency_key: $('Normalize_Input').item.json.idempotency_key
};
```

**Output:** Deduped success envelope (routes to final output)

---

### Node 6: Insert_Spine
**Type:** Supabase (INSERT)
**Purpose:** Create qxb_artifact record (spine-first pattern)

**Credentials:** "Qwrk Supabase – Kernel v1"

**Table:** `qxb_artifact`

**Insert Data:**
```json
{
  "workspace_id": "={{ $('Normalize_Input').item.json.workspace_id }}",
  "owner_user_id": "={{ $('Normalize_Input').item.json.owner_user_id }}",
  "artifact_type": "video",
  "title": "={{ $('Normalize_Input').item.json.title }}",
  "summary": "={{ $('Normalize_Input').item.json.summary }}",
  "priority": 3,
  "tags": "={{ $('Normalize_Input').item.json.tags }}",
  "content": {
    "kind": "video",
    "source_platform": "youtube"
  }
}
```

**Options:**
- **Return fields:** ALL
- **UPSERT:** No (fail on conflict)

**Output:**
- `artifact_id` (generated by DB)
- `workspace_id`, `owner_user_id`, `artifact_type`, `title`, etc.
- `created_at`, `updated_at`

**Error Handling:**
- If INSERT fails (FK violation, RLS denial), route to error handler

---

### Node 7: Normalize_Spine_ID
**Type:** Code (JavaScript)
**Purpose:** Extract artifact_id deterministically from Supabase response

**Logic:**
```javascript
// Fallback chain for Supabase response shape variations
const artifact_id = $json.artifact_id
  || $json.id
  || ($json.data && $json.data[0] && $json.data[0].artifact_id)
  || ($json.data && $json.data[0] && $json.data[0].id);

if (!artifact_id) {
  return {
    ok: false,
    error: {
      stage: 'create_spine',
      message: 'Failed to extract artifact_id from spine INSERT response'
    }
  };
}

return {
  ok: true,
  artifact_id: artifact_id
};
```

**Output:**
- `ok: true/false`
- `artifact_id`
- `error` (if extraction failed)

---

### Node 8: Guard_Spine_ID_Error
**Type:** IF
**Purpose:** Short-circuit if artifact_id extraction failed

**Condition:**
```
{{ $json.ok === false }}
```

**Branches:**
- **TRUE** → Route to error output
- **FALSE** → Continue to extension insert

---

### Node 9: Insert_Extension
**Type:** Supabase (INSERT)
**Purpose:** Create qxb_artifact_video record

**Credentials:** "Qwrk Supabase – Kernel v1"

**Table:** `qxb_artifact_video`

**Insert Data:**
```json
{
  "artifact_id": "={{ $('Normalize_Spine_ID').item.json.artifact_id }}",
  "source_url": "={{ $('Normalize_Input').item.json.source_url }}",
  "source_platform": "={{ $('Normalize_Input').item.json.source_platform }}",
  "source_video_id": "={{ $('Normalize_Input').item.json.source_video_id }}",
  "status": "queued",
  "idempotency_key": "={{ $('Normalize_Input').item.json.idempotency_key }}",
  "content": {}
}
```

**Options:**
- **Return fields:** ALL
- **UPSERT:** No

**Output:**
- `artifact_id`, `source_url`, `status`, `idempotency_key`
- `created_at`, `updated_at`

**Error Handling:**
- If INSERT fails, route to error handler (artifact_id should be cleaned up ideally, but acceptable to leave orphaned spine row in MVP)

---

### Node 10: Update_Status_Downloading
**Type:** Supabase (UPDATE)
**Purpose:** Set status = 'downloading' before download begins

**Table:** `qxb_artifact_video`

**Filter:** `artifact_id` = `{{ $('Normalize_Spine_ID').item.json.artifact_id }}`

**Update Data:**
```json
{
  "status": "downloading",
  "updated_at": "={{ $now }}"
}
```

---

### Node 11: Download_Audio
**Type:** Execute Command
**Purpose:** Download YouTube audio using yt-dlp

**Command:**
```bash
yt-dlp -f 'bestaudio[ext=m4a]' \
  --output '/tmp/qwrk-video/{{ $('Normalize_Input').item.json.idempotency_key }}.%(ext)s' \
  --no-playlist \
  --quiet \
  '{{ $('Normalize_Input').item.json.source_url }}'
```

**Working Directory:** `/tmp`

**Environment Variables:** (none required)

**Output:**
- Exit code 0 on success
- stderr/stdout for diagnostics

**Error Handling:**
- If exit code != 0, capture error and route to failed status update

---

### Node 12: Get_Audio_File_Path
**Type:** Code (JavaScript)
**Purpose:** Determine downloaded file path

**Logic:**
```javascript
const idempotency_key = $('Normalize_Input').item.json.idempotency_key;
// yt-dlp typically downloads as .m4a or .webm
const basePath = `/tmp/qwrk-video/${idempotency_key}`;
const possibleExtensions = ['m4a', 'webm', 'opus', 'mp3'];

// Check which file exists (in real implementation, use fs.existsSync in Execute Command)
// For spec purposes, assume m4a
const audioFilePath = `${basePath}.m4a`;

return {
  audio_file_path: audioFilePath,
  idempotency_key: idempotency_key
};
```

**Output:**
- `audio_file_path`
- `idempotency_key`

---

### Node 13: Update_Status_Chunking
**Type:** Supabase (UPDATE)
**Purpose:** Set status = 'chunking'

**Table:** `qxb_artifact_video`

**Filter:** `artifact_id` = `{{ $('Normalize_Spine_ID').item.json.artifact_id }}`

**Update Data:**
```json
{
  "status": "chunking",
  "updated_at": "={{ $now }}"
}
```

---

### Node 14: Chunk_Audio
**Type:** Execute Command
**Purpose:** Split audio into chunks safely below whisper-1 25MB limit

**Command:**
```bash
ffmpeg -i '{{ $('Get_Audio_File_Path').item.json.audio_file_path }}' \
  -f segment \
  -segment_time 600 \
  -c copy \
  -reset_timestamps 1 \
  '/tmp/qwrk-video/{{ $('Get_Audio_File_Path').item.json.idempotency_key }}_chunk_%03d.m4a'
```

**Notes:**
- `-segment_time 600` = 10 minute chunks (well below 25MB for typical audio bitrates)
- Output files: `<idempotency_key>_chunk_000.m4a`, `_chunk_001.m4a`, etc.

**Output:**
- Exit code 0 on success
- Chunk files created in `/tmp/qwrk-video/`

**Error Handling:**
- If exit code != 0, route to failed status

---

### Node 15: List_Chunk_Files
**Type:** Execute Command
**Purpose:** Get list of chunk files for iteration

**Command:**
```bash
ls /tmp/qwrk-video/{{ $('Get_Audio_File_Path').item.json.idempotency_key }}_chunk_*.m4a | sort
```

**Output:**
- stdout: newline-separated list of chunk file paths

---

### Node 16: Parse_Chunk_List
**Type:** Code (JavaScript)
**Purpose:** Convert chunk file list to array for loop

**Logic:**
```javascript
const chunkList = $json.stdout.trim().split('\n').filter(f => f.length > 0);
return chunkList.map((filePath, index) => ({
  chunk_index: index,
  file_path: filePath
}));
```

**Output:**
- Array of objects: `[{ chunk_index: 0, file_path: "..." }, ...]`

---

### Node 17: Update_Status_Transcribing
**Type:** Supabase (UPDATE)
**Purpose:** Set status = 'transcribing'

**Table:** `qxb_artifact_video`

**Filter:** `artifact_id` = `{{ $('Normalize_Spine_ID').item.json.artifact_id }}`

**Update Data:**
```json
{
  "status": "transcribing",
  "updated_at": "={{ $now }}"
}
```

---

### Node 18: Loop_Chunks (Loop)
**Type:** Loop Over Items
**Purpose:** Iterate over each audio chunk for transcription

**Input:** Array from Parse_Chunk_List

**Loop Body:** Nodes 19-20

---

### Node 19: Transcribe_Chunk
**Type:** OpenAI (Audio Transcription)
**Purpose:** Transcribe single audio chunk using whisper-1

**Credentials:** "OpenAi account"

**Parameters:**
- **Model:** whisper-1
- **Audio File:** `{{ $json.file_path }}`
- **Response Format:** verbose_json
- **Language:** (auto-detect, leave blank)

**Output:**
- `text` (transcript text for this chunk)
- `segments` (array of segment objects with timestamps)
- `duration`

**Error Handling:**
- If API call fails, capture error and route to failed status
- Consider retry logic for transient API errors (429, 5xx)

---

### Node 20: Normalize_Chunk_Transcript
**Type:** Code (JavaScript)
**Purpose:** Format chunk transcript with metadata

**Logic:**
```javascript
return {
  chunk_index: $json.chunk_index,
  text: $json.text,
  segments: $json.segments || [],
  duration: $json.duration
};
```

**Output:**
- `chunk_index`, `text`, `segments`, `duration`

---

### Node 21: Update_Status_Stitching
**Type:** Supabase (UPDATE)
**Purpose:** Set status = 'stitching'

**Table:** `qxb_artifact_video`

**Filter:** `artifact_id` = `{{ $('Normalize_Spine_ID').item.json.artifact_id }}`

**Update Data:**
```json
{
  "status": "stitching",
  "updated_at": "={{ $now }}"
}
```

---

### Node 22: Stitch_Transcripts
**Type:** Code (JavaScript)
**Purpose:** Concatenate all chunk transcripts and normalize

**Logic:**
```javascript
const chunks = $('Normalize_Chunk_Transcript').all();

// Sort by chunk_index to ensure order
chunks.sort((a, b) => a.json.chunk_index - b.json.chunk_index);

// Concatenate full text
const full_text = chunks.map(c => c.json.text).join(' ');

// Merge all segments with adjusted timestamps if needed
const all_segments = [];
let cumulative_offset = 0;

chunks.forEach(chunk => {
  const segments = chunk.json.segments || [];
  segments.forEach(seg => {
    all_segments.push({
      chunk_index: chunk.json.chunk_index,
      start: seg.start + cumulative_offset,
      end: seg.end + cumulative_offset,
      text: seg.text
    });
  });
  cumulative_offset += chunk.json.duration || 0;
});

// Normalize whitespace
const normalized_text = full_text.replace(/\s+/g, ' ').trim();

return {
  transcription: {
    engine: 'openai',
    model: 'whisper-1',
    response_format: 'verbose_json',
    segments: all_segments,
    full_text: normalized_text
  },
  ingest: {
    idempotency_key: $('Normalize_Input').item.json.idempotency_key,
    source_platform: $('Normalize_Input').item.json.source_platform,
    source_url: $('Normalize_Input').item.json.source_url,
    source_video_id: $('Normalize_Input').item.json.source_video_id
  }
};
```

**Output:**
- `transcription` object (with segments and full_text)
- `ingest` object (metadata)

---

### Node 23: Update_Status_Saving
**Type:** Supabase (UPDATE)
**Purpose:** Set status = 'saving'

**Table:** `qxb_artifact_video`

**Filter:** `artifact_id` = `{{ $('Normalize_Spine_ID').item.json.artifact_id }}`

**Update Data:**
```json
{
  "status": "saving",
  "updated_at": "={{ $now }}"
}
```

---

### Node 24: Save_Final_Transcript
**Type:** Supabase (UPDATE)
**Purpose:** Update extension with complete transcript and mark complete

**Table:** `qxb_artifact_video`

**Filter:** `artifact_id` = `{{ $('Normalize_Spine_ID').item.json.artifact_id }}`

**Update Data:**
```json
{
  "status": "complete",
  "content": "={{ $('Stitch_Transcripts').item.json }}",
  "error": null,
  "updated_at": "={{ $now }}"
}
```

---

### Node 25: Cleanup_Temp_Files
**Type:** Execute Command
**Purpose:** Delete temporary audio files

**Command:**
```bash
rm -f /tmp/qwrk-video/{{ $('Get_Audio_File_Path').item.json.idempotency_key }}*
```

**Error Handling:**
- Non-critical; log but don't fail workflow if cleanup fails

---

### Node 26: Return_Success
**Type:** Code (JavaScript)
**Purpose:** Format final success response

**Logic:**
```javascript
return {
  ok: true,
  deduped: false,
  artifact_id: $('Normalize_Spine_ID').item.json.artifact_id,
  status: 'complete',
  idempotency_key: $('Normalize_Input').item.json.idempotency_key
};
```

**Output:** Success envelope

---

### Error Handling Nodes

### Node 27: Catch_Error (Error Trigger)
**Type:** Error Trigger
**Purpose:** Catch any unhandled errors in workflow

**Connected to:** All nodes that can fail

---

### Node 28: Update_Status_Failed
**Type:** Supabase (UPDATE)
**Purpose:** Set status = 'failed' and capture error details

**Table:** `qxb_artifact_video`

**Filter:** `artifact_id` = `{{ $('Normalize_Spine_ID').item.json.artifact_id }}`

**Update Data:**
```json
{
  "status": "failed",
  "error": {
    "stage": "={{ $json.stage || 'unknown' }}",
    "message": "={{ $json.error.message || $json.message || 'Unknown error' }}",
    "timestamp": "={{ $now }}"
  },
  "updated_at": "={{ $now }}"
}
```

**Notes:**
- Only update if artifact_id exists (spine was created)
- If spine creation failed, skip DB update

---

### Node 29: Cleanup_On_Error
**Type:** Execute Command
**Purpose:** Delete temp files even if processing failed

**Command:**
```bash
rm -f /tmp/qwrk-video/{{ $('Get_Audio_File_Path').item.json.idempotency_key || '' }}* 2>/dev/null || true
```

---

### Node 30: Return_Failure
**Type:** Code (JavaScript)
**Purpose:** Format final error response

**Logic:**
```javascript
return {
  ok: false,
  artifact_id: $('Normalize_Spine_ID').item.json.artifact_id || null,
  status: 'failed',
  error: {
    stage: $json.stage || 'unknown',
    message: $json.error?.message || $json.message || 'Workflow failed',
    details: $json.error?.details || null
  }
};
```

**Output:** Failure envelope

---

## Workflow Flow Diagram

```
Start (Execute Workflow Trigger)
  ↓
1. Normalize_Input
  ↓
2. Guard_Validation_Error (IF)
  ↓ (ok=false)              ↓ (ok=true)
30. Return_Failure      3. Check_Dedup (Supabase SELECT)
                           ↓
                        4. Guard_Dedup_Found (IF)
                          ↓ (found)            ↓ (not found)
                        5. Return_Deduped   6. Insert_Spine (Supabase INSERT)
                                               ↓
                                            7. Normalize_Spine_ID
                                               ↓
                                            8. Guard_Spine_ID_Error (IF)
                                              ↓ (ok=false)    ↓ (ok=true)
                                            30. Return_Failure  9. Insert_Extension
                                                                ↓
                                                             10. Update_Status_Downloading
                                                                ↓
                                                             11. Download_Audio (yt-dlp)
                                                                ↓
                                                             12. Get_Audio_File_Path
                                                                ↓
                                                             13. Update_Status_Chunking
                                                                ↓
                                                             14. Chunk_Audio (ffmpeg)
                                                                ↓
                                                             15. List_Chunk_Files
                                                                ↓
                                                             16. Parse_Chunk_List
                                                                ↓
                                                             17. Update_Status_Transcribing
                                                                ↓
                                                             18. Loop_Chunks
                                                                ↓ (for each chunk)
                                                             19. Transcribe_Chunk (OpenAI)
                                                                ↓
                                                             20. Normalize_Chunk_Transcript
                                                                ↓ (loop continues)
                                                                ↓ (all chunks done)
                                                             21. Update_Status_Stitching
                                                                ↓
                                                             22. Stitch_Transcripts
                                                                ↓
                                                             23. Update_Status_Saving
                                                                ↓
                                                             24. Save_Final_Transcript
                                                                ↓
                                                             25. Cleanup_Temp_Files
                                                                ↓
                                                             26. Return_Success

Error Path (from any node):
  ↓
27. Catch_Error (Error Trigger)
  ↓
28. Update_Status_Failed
  ↓
29. Cleanup_On_Error
  ↓
30. Return_Failure
```

---

## Failure Modes

### 1. Validation Failure
- **Trigger:** Missing required fields
- **Status:** Never reaches DB (no artifact created)
- **Response:** `ok: false, error: { stage: 'normalize', ... }`

### 2. Deduplication Hit
- **Trigger:** Idempotency key already exists
- **Status:** Returns existing artifact (not a failure)
- **Response:** `ok: true, deduped: true, artifact_id, status`

### 3. Spine Creation Failure
- **Trigger:** FK violation, RLS denial, DB error
- **Status:** No artifact created
- **Response:** `ok: false, error: { stage: 'create_spine', ... }`

### 4. Download Failure
- **Trigger:** yt-dlp error (invalid URL, geo-restriction, network issue)
- **Status:** `failed` (artifact exists in DB)
- **Response:** `ok: false, artifact_id, status: 'failed', error: { stage: 'downloading', ... }`

### 5. Chunking Failure
- **Trigger:** ffmpeg error (corrupted audio, codec issue)
- **Status:** `failed`
- **Response:** `ok: false, artifact_id, status: 'failed', error: { stage: 'chunking', ... }`

### 6. Transcription Failure
- **Trigger:** OpenAI API error (quota exceeded, network timeout, unsupported audio format)
- **Status:** `failed`
- **Response:** `ok: false, artifact_id, status: 'failed', error: { stage: 'transcribing', ... }`

### 7. Stitch/Save Failure
- **Trigger:** DB update error, memory overflow
- **Status:** `failed`
- **Response:** `ok: false, artifact_id, status: 'failed', error: { stage: 'saving', ... }`

---

## Retry Behavior

**Current Spec (MVP):** No automatic retry

**Recommended Future Enhancement:**
- Retry download failures (3 attempts with exponential backoff)
- Retry transcription API failures for transient errors (429, 503)
- Do NOT retry validation failures or deduplication hits

---

## Temp File Management

**Directory:** `/tmp/qwrk-video/`

**Files Created:**
- `<idempotency_key>.m4a` (full audio download)
- `<idempotency_key>_chunk_000.m4a`, `_chunk_001.m4a`, ... (audio chunks)

**Cleanup Strategy:**
- **Success path:** Node 25 deletes all files after save complete
- **Error path:** Node 29 deletes all files (best effort)
- **Orphan cleanup:** Consider cron job to delete files older than 1 hour

**Storage Requirements:**
- Typical YouTube video: 3-5 MB per 10 minutes (audio-only m4a)
- Chunks: roughly same total size
- Peak storage: 2x original file size during chunking
- Example: 60-minute video ≈ 20-30 MB peak

---

## Performance Characteristics

**Typical Processing Times (estimates):**
- Download (10-min video): 5-15 seconds
- Chunking: 2-5 seconds
- Transcription per chunk: 10-30 seconds (depends on OpenAI API latency)
- Total for 60-min video (6 chunks): 2-5 minutes

**Bottlenecks:**
- OpenAI API latency (parallel chunk processing not supported in MVP)
- Network speed for download

---

## Dependencies

**External Services:**
- YouTube (source video availability)
- OpenAI API (whisper-1 transcription)
- Supabase (database)

**System Binaries:**
- yt-dlp (YouTube download)
- ffmpeg (audio chunking)

**n8n Credentials:**
- "Qwrk Supabase – Kernel v1" (Supabase)
- "OpenAi account" (OpenAI API)

---

## Testing Strategy

**Unit Tests (per node):**
- Normalize_Input: valid/invalid inputs
- Dedup: existing/non-existing idempotency_key
- Spine/Extension inserts: FK validation, RLS policies
- Download: valid/invalid URLs
- Transcribe: mock API responses

**Integration Tests (end-to-end):**
1. **Happy path:** New video, successful download → transcribe → save
2. **Deduplication:** Same URL submitted twice
3. **Download failure:** Invalid YouTube URL
4. **Transcription failure:** Mock OpenAI API error
5. **Missing credentials:** OpenAI credential not configured

**KGB Tests (production-like):**
- Ingest real YouTube video (public domain test video)
- Verify transcript quality
- Verify status transitions logged correctly
- Verify temp files cleaned up

---

## Known Limitations (MVP)

1. **No parallel chunk transcription** (sequential processing increases latency)
2. **No retry logic** (transient failures require manual re-submission)
3. **No progress tracking** (status is coarse-grained: downloading vs 60% downloaded)
4. **No video metadata extraction** (duration, channel, publish date not auto-populated)
5. **YouTube-only** (no Vimeo, direct URL support)
6. **No audio quality selection** (uses yt-dlp best audio default)

---

## Future Enhancements

1. **Parallel chunk transcription** (use n8n Split In Batches + Execute Workflow)
2. **Progress webhooks** (notify caller of status changes)
3. **Video metadata enrichment** (extract duration, channel, publish date from yt-dlp JSON)
4. **Multi-platform support** (Vimeo, direct MP4/MP3 URLs)
5. **Audio quality control** (configurable bitrate, format)
6. **Transcript post-processing** (speaker diarization, punctuation correction)

---

**End of Specification**

**Next Steps:**
1. Review and approve this spec
2. Build workflow in n8n GUI following node-by-node specification
3. Test locally with KGB test video
4. Export JSON and commit to repo
5. Create companion README with usage examples
