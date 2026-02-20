# DRAFT v0 — Video Workflows (Testing Only)

**Status:** NOT COMMIT-READY
**Purpose:** Import into n8n for testing and iteration
**Date:** 2026-01-04

---

## ⚠️ CRITICAL NOTICE

These workflow JSON files are **DRAFT v0** artifacts for testing purposes only.

**DO NOT:**
- ❌ Commit these files to main branch
- ❌ Open PR with these files
- ❌ Treat as production-ready
- ❌ Reference in documentation as final

**These files exist only to:**
- ✅ Import into n8n GUI for testing
- ✅ Validate workflow logic with real test data
- ✅ Iterate and fix issues discovered during testing
- ✅ Serve as starting point for final approved workflows

---

## Workflow Status

### 1. Qxb_Video_Ingest_Transcribe_Save__Worker_v1.json ✅ GENERATED

**Purpose:** Core video ingest, transcription, and save pipeline

**Nodes:** 30 nodes
- Normalize/validate inputs
- Deduplication check
- Spine + Extension DB inserts
- Status lifecycle tracking (queued → downloading → chunking → transcribing → stitching → saving → complete)
- yt-dlp audio download
- ffmpeg audio chunking
- OpenAI whisper-1 transcription (loop over chunks)
- Transcript stitching
- Error handling and cleanup

**Ready for:** Import and testing

**Known Uncertainties:**
- Supabase node response shape may vary (Normalize_Spine_ID has fallback logic)
- OpenAI transcription node parameter names may need adjustment
- Loop node behavior with splitInBatches needs validation

---

### 2. Qxb_Video_Ingest_Transcribe_Save_v1.json ⏳ PENDING

**Status:** Awaiting Worker test results before generation

---

### 3. Qxb_Video_Ingest_Transcribe_Save__Gateway_v1.json ⏳ PENDING

**Status:** Awaiting Worker test results before generation

---

### 4. Qxb_Video_List_v1.json ⏳ PENDING

**Status:** Awaiting Worker test results before generation

---

### 5. Qxb_Video_Get_v1.json ⏳ PENDING

**Status:** Awaiting Worker test results before generation

---

## Import Instructions

### Step 1: Import Worker Workflow

1. Open n8n GUI
2. Navigate to **Workflows** → **Import from File**
3. Select: `Qxb_Video_Ingest_Transcribe_Save__Worker_v1.json`
4. Verify credentials are mapped:
   - Supabase: "Qwrk Supabase – Kernel v1"
   - OpenAI: "OpenAi account"
5. Save workflow

### Step 2: Manual Test (Short Video)

**Test Input:**
```json
{
  "source_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "title_override": "Test Video - DRAFT v0",
  "tags": ["test", "draft"],
  "notes": "DRAFT v0 test run"
}
```

**Execute manually** from n8n GUI and observe:
- Status transitions in DB
- Transcript quality
- Error handling
- Temp file cleanup

### Step 3: Report Results

Document any issues found:
- Node parameter errors
- Credential mapping failures
- Logic errors
- Performance issues

---

## Testing Checklist

### Worker Workflow Tests

- [ ] **Happy Path:** Valid YouTube URL → complete status
- [ ] **Deduplication:** Same URL twice → deduped response
- [ ] **Validation Error:** Missing workspace_id → validation failure
- [ ] **Download Error:** Invalid URL → failed status, error captured
- [ ] **Status Lifecycle:** All status transitions logged correctly
- [ ] **Transcript Quality:** Readable, accurate transcription
- [ ] **Temp Files:** Cleaned up after success and failure
- [ ] **Database State:** Spine + extension records correct

---

## Known Issues (Pre-Test)

### Potential Issues to Watch For

1. **Supabase Response Shape**
   - `Normalize_Spine_ID` node has fallback logic
   - May need adjustment based on actual Supabase response

2. **OpenAI Node Configuration**
   - Parameter names for whisper-1 transcription may differ from spec
   - `audioFileUrl` vs `file` parameter naming

3. **Loop Node Behavior**
   - `splitInBatches` loop may behave differently than expected
   - Connection back to loop node may need adjustment

4. **Credential IDs**
   - JSON references credential by name, not ID
   - n8n may auto-map or require manual selection

5. **Execute Command Permissions**
   - yt-dlp and ffmpeg must be on PATH
   - /tmp/qwrk-video/ must be writable

---

## Iteration Process

After testing:

1. Document issues found
2. Fix JSON locally or in n8n GUI
3. Re-test
4. Export updated JSON from n8n
5. Replace DRAFT v0 JSON with fixed version
6. Repeat until all tests pass

**Only after all tests pass:**
- Mark workflows as FINAL
- Move to canonical workflows/ directory
- Commit with message: "Build: Video v1 ingest (worker + triggers) and gateway reads"

---

## Files in This Directory

```
DRAFT_v0/
├── README.md (this file)
└── Qxb_Video_Ingest_Transcribe_Save__Worker_v1.json (DRAFT v0)
```

---

**Next Steps:**
1. Import Worker JSON into n8n
2. Test with short video
3. Report results
4. Iterate if needed
5. Generate remaining workflow JSONs after Worker is stable
