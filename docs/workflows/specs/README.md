# Video Artifacts v1 — Workflow Specifications

**Date:** 2026-01-04
**Status:** Approved for Implementation
**Purpose:** Detailed node-by-node specifications for building Video v1 workflows in n8n

---

## Overview

This directory contains **authoritative workflow specifications** for Video Artifacts v1. These specs define the exact node structure, logic, inputs, outputs, and error handling for each workflow.

**Build Approach:**
1. Review and approve these specifications
2. Build workflows in n8n GUI following node-by-node instructions
3. Test end-to-end (KGB-style validation)
4. Export JSON from n8n
5. Commit exported JSON files to `workflows/` directory

---

## Workflow Specifications

### 1. Worker Workflow (Core Pipeline)

**File:** [`Qxb_Video_Ingest_Transcribe_Save__Worker_v1__SPEC.md`](./Qxb_Video_Ingest_Transcribe_Save__Worker_v1__SPEC.md)

**Purpose:** Canonical worker workflow for video ingest, transcription, and save operations

**Complexity:** High (30 nodes)
- Normalize and validate inputs
- Deduplication check
- Spine-first DB inserts
- yt-dlp audio download
- ffmpeg audio chunking
- OpenAI whisper-1 transcription (loop over chunks)
- Transcript stitching
- Status lifecycle tracking (queued → downloading → chunking → transcribing → stitching → saving → complete)
- Error capture and cleanup

**Trigger:** Execute Workflow only (called by triggers)

**Key Dependencies:**
- yt-dlp (YouTube download)
- ffmpeg (audio chunking)
- OpenAI API (whisper-1 transcription)
- Supabase (qxb_artifact + qxb_artifact_video)

---

### 2. Standalone Trigger

**File:** [`Qxb_Video_Ingest_Transcribe_Save_v1__SPEC.md`](./Qxb_Video_Ingest_Transcribe_Save_v1__SPEC.md)

**Purpose:** Standalone form/webhook trigger for manual video ingest

**Complexity:** Low (7 nodes)
- Webhook trigger
- Config injection (workspace_id/owner_user_id for MVP single-user)
- Input validation
- Call Worker
- Format response
- Return to caller

**Trigger:** Webhook (POST /video/ingest)

**Configuration Required:**
- `QWRK_DEFAULT_WORKSPACE_ID` environment variable
- `QWRK_DEFAULT_OWNER_USER_ID` environment variable

---

### 3. Gateway Trigger

**File:** [`Qxb_Video_Ingest_Transcribe_Save__Gateway_v1__SPEC.md`](./Qxb_Video_Ingest_Transcribe_Save__Gateway_v1__SPEC.md)

**Purpose:** Gateway-triggered video ingest (called from NQxb_Gateway_v1)

**Complexity:** Low (5 nodes)
- Extract `source_url` from Gateway `payload.source_url`
- Extract `workspace_id` and `owner_user_id` from Gateway envelope
- Validate Gateway payload
- Call Worker
- Map Worker response to Gateway envelope format

**Trigger:** Execute Workflow (called by Gateway)

**Integration Required:**
- Add routing in `NQxb_Gateway_v1` for `artifact_type='video'`

---

### 4. List Subworkflow

**File:** [`Qxb_Video_List_v1__SPEC.md`](./Qxb_Video_List_v1__SPEC.md)

**Purpose:** List video artifacts with filtering and pagination

**Complexity:** Medium (8 nodes)
- Normalize filters (status, source_platform, tags, search)
- Normalize pagination (limit, offset)
- Normalize sort (by, order)
- Query spine + extension (JOIN or separate queries + merge)
- Count total for pagination
- Format response (Gateway list envelope)

**Trigger:** Execute Workflow (called by Gateway)

**Default Behavior:**
- Filter: `status='complete'` (only show transcribed videos)
- Sort: `created_at DESC` (newest first)
- Limit: 50 items per page

---

### 5. Get Subworkflow

**File:** [`Qxb_Video_Get_v1__SPEC.md`](./Qxb_Video_Get_v1__SPEC.md)

**Purpose:** Get single video artifact by ID with full transcript

**Complexity:** Low (11 nodes)
- Validate input (workspace_id, artifact_id)
- Query spine
- Check NOT_FOUND
- Check TYPE_MISMATCH
- Query extension
- Merge spine + extension
- Include full transcript in response
- Format Gateway success envelope

**Trigger:** Execute Workflow (called by Gateway)

**Response Includes:**
- Full transcript (`transcription.full_text`)
- Transcript segments with timestamps
- Video metadata (source_url, duration, status)
- Error details (if status='failed')

---

## Workflow Dependencies

### External Services
- **YouTube** (video source availability)
- **OpenAI API** (whisper-1 transcription)
- **Supabase** (database)

### System Binaries
- **yt-dlp** (`/usr/bin/yt-dlp`) - YouTube download
- **ffmpeg** (`/usr/bin/ffmpeg`) - Audio chunking

### n8n Credentials
- **"Qwrk Supabase – Kernel v1"** (Supabase API)
- **"OpenAi account"** (OpenAI API)

---

## Build Order (Recommended)

1. **Worker** (build and test first - most complex, foundational)
2. **Standalone Trigger** (test Worker via webhook)
3. **Get** (read single artifact - simpler than list)
4. **List** (read multiple artifacts with filtering)
5. **Gateway Trigger** (integrate with Gateway last)

---

## Testing Strategy

### Phase 1: Worker Testing (Standalone)
1. Build Worker workflow
2. Call manually from n8n GUI with test payload
3. Use short test video (< 5 minutes) for fast iteration
4. Verify:
   - Deduplication works
   - Status transitions logged correctly
   - Transcript quality acceptable
   - Temp files cleaned up
   - Error handling works (invalid URL, API failures)

### Phase 2: Standalone Trigger Testing
1. Build Standalone trigger
2. Configure environment variables (workspace_id/owner_user_id)
3. Test via curl/Postman webhook POST
4. Verify end-to-end flow (webhook → Worker → response)

### Phase 3: Read Workflows Testing
1. Build Get workflow
2. Test with artifact_id from successful Worker run
3. Verify transcript returned correctly
4. Test error cases (NOT_FOUND, TYPE_MISMATCH)
5. Build List workflow
6. Test filters (status, tags, search)
7. Test pagination (limit, offset)

### Phase 4: Gateway Integration Testing
1. Build Gateway trigger
2. Add routing to NQxb_Gateway_v1
3. Test via Gateway webhook with `artifact_type='video'`
4. Verify Gateway envelope mapping correct
5. Test Get/List via Gateway (not just triggers)

---

## KGB Test Suite (Production Validation)

### Required KGB Tests

1. **Standalone Ingest - Happy Path**
   - Submit real YouTube video URL
   - Verify artifact created in DB
   - Verify transcript quality
   - Verify status = 'complete'

2. **Deduplication**
   - Submit same URL twice
   - Verify second call returns `deduped: true`
   - Verify no duplicate DB records

3. **Gateway Ingest**
   - Submit via Gateway with `artifact_type='video'`
   - Verify same behavior as standalone

4. **Gateway List**
   - Query list with default filters
   - Verify only completed videos returned
   - Verify pagination works

5. **Gateway Get**
   - Query single artifact by ID
   - Verify full transcript included
   - Verify video metadata correct

6. **Failure Modes**
   - Submit invalid YouTube URL
   - Verify status = 'failed'
   - Verify error JSONB populated
   - Verify temp files cleaned up

---

## Known Limitations (MVP)

1. **No parallel chunk transcription** (sequential processing = longer latency)
2. **No retry logic** (transient failures require manual re-submission)
3. **No progress tracking** (status is coarse-grained)
4. **No video metadata extraction** (duration, channel not auto-populated)
5. **YouTube-only** (no Vimeo, direct URL support)
6. **No audio quality selection** (uses yt-dlp default)

---

## Performance Expectations

### Typical Processing Times (estimates)
- **10-minute video:** 1-2 minutes total
- **60-minute video:** 3-5 minutes total

### Bottlenecks
- OpenAI API latency (10-30 seconds per chunk)
- Network speed for download

### Storage Requirements
- Peak: 2x original file size during chunking
- Example: 60-minute video ≈ 20-30 MB peak

---

## Configuration Checklist

Before building workflows, ensure:

✅ **Supabase Credential** configured in n8n ("Qwrk Supabase – Kernel v1")
✅ **OpenAI Credential** configured in n8n ("OpenAi account")
✅ **yt-dlp** installed on n8n server (`/usr/bin/yt-dlp`)
✅ **ffmpeg** installed on n8n server (`/usr/bin/ffmpeg`)
✅ **Temp directory** writable (`/tmp/qwrk-video/`)
✅ **Environment variables** set (for Standalone trigger):
  - `QWRK_DEFAULT_WORKSPACE_ID` (TBD by Master Joel)
  - `QWRK_DEFAULT_OWNER_USER_ID` (TBD by Master Joel)

---

## Next Steps

1. **Review Specs:** Master Joel approves all 5 workflow specifications
2. **Provide Config:** Master Joel provides canonical workspace_id/owner_user_id for Standalone trigger
3. **Build Worker:** Implement Worker workflow in n8n GUI following spec
4. **Test Worker:** Validate with short test video
5. **Build Remaining Workflows:** Implement triggers and read workflows
6. **End-to-End Testing:** Full KGB test suite
7. **Export JSON:** Export all workflows from n8n
8. **Commit:** Commit JSON files + READMEs with usage examples
9. **Documentation:** Update Gateway Contract, NoFail SQL templates, KGB tests

---

## Questions / Blockers

**Blocked on:**
- Canonical workspace_id and owner_user_id for Standalone trigger configuration

**Open Questions:**
- Should Worker have retry logic for transient failures? (Defer to future)
- Should we support parallel chunk transcription in v1? (No - MVP is sequential)
- Should List support full-text search on transcript content? (No - title/summary only for v1)

---

**End of Specifications Index**

**Status:** Ready for implementation ✅
