# ChatGPT Prompt: Build Video Worker Workflow MVP (n8n Manual Guide)

**Context:** I'm building an n8n workflow to download YouTube audio, transcribe it with OpenAI whisper-1, and return the full transcript text. This is a barebones MVP to test functionality before adding database integration, status tracking, and error handling.

**Your Role:** Guide me step-by-step through building this workflow in the n8n GUI, one node at a time. After I confirm each node is created and configured correctly, provide the next node.

---

## Workflow Goal (MVP)

**Input:** YouTube video URL
**Process:** Download audio → Transcribe with OpenAI whisper-1
**Output:** Full transcript text

**Constraints:**
- Manual trigger (for testing)
- No database operations (DB integration comes later)
- No status tracking (keep it simple)
- No deduplication (single-run testing only)
- Assume video is short enough to transcribe without chunking (< 10 minutes)
- Use Switch nodes (not IF nodes)
- Avoid Execute Command nodes if possible (prefer HTTP/API solutions)

---

## Nodes to Build (High-Level)

1. **Manual Trigger** - Start workflow manually with test data
2. **Extract Video ID** (Code node) - Parse YouTube URL to get video ID
3. **Download Audio** (HTTP node or workaround) - Get audio file from YouTube
4. **Transcribe Audio** (OpenAI node) - Send audio to whisper-1
5. **Format Output** (Code node) - Return clean transcript object
6. **Return Result** - Display final output

---

## Step-by-Step Build Instructions

### Setup Context

Before we start, tell me:
1. Do you have access to a YouTube download API/service (like a self-hosted youtube-dl API, RapidAPI, or similar)?
   - If YES: Provide the endpoint URL
   - If NO: We'll use a workaround approach

2. Is your OpenAI credential already configured in n8n?
   - Credential name: "OpenAi account" (confirm this exists)

3. What is your test YouTube URL? (Prefer a short video < 3 minutes for MVP testing)
   - Example: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`

---

## Node 1: Manual Trigger

**Task:** Create a Manual Trigger node to start the workflow

**Instructions:**
1. In n8n, create a new workflow
2. Add a **Manual Trigger** node (search for "Manual" in the node palette)
3. Configure it to accept JSON input
4. Set the **test input data** to:

```json
{
  "source_url": "https://www.youtube.com/watch?v=YOUR_TEST_VIDEO_ID"
}
```

**When complete, confirm:**
- ✅ Manual Trigger node created
- ✅ Test data configured with a real YouTube URL
- ✅ You can execute the trigger and see the JSON output

**Then say:** "Node 1 complete, ready for Node 2"

---

## Node 2: Extract Video ID (Code Node)

**Task:** Parse the YouTube URL to extract the video ID

**Instructions:**
1. Add a **Code** node after the Manual Trigger
2. Set **Language** to JavaScript
3. Paste this code:

```javascript
const sourceUrl = $input.item.json.source_url;

if (!sourceUrl) {
  throw new Error('source_url is required');
}

// Extract YouTube video ID
const urlMatch = sourceUrl.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&?\/]+)/);
const videoId = urlMatch ? urlMatch[1] : null;

if (!videoId) {
  throw new Error('Could not extract video ID from URL');
}

return {
  source_url: sourceUrl,
  video_id: videoId
};
```

**When complete, confirm:**
- ✅ Code node created and connected to Manual Trigger
- ✅ Code extracts video_id correctly when you test execute
- ✅ Output shows `{ source_url: "...", video_id: "..." }`

**Then say:** "Node 2 complete, ready for Node 3"

---

## Node 3: Download Audio (Approach Depends on Your Setup)

**STOP:** Before building this node, tell me which approach you're using:

**Option A: You have a YouTube download API/service**
- You'll use an HTTP Request node to call the API
- API returns audio file URL or binary data

**Option B: No API available - Use yt-dlp via Execute Command (workaround for MVP)**
- We'll use Execute Command to run yt-dlp locally
- This violates the "no Execute Command" preference but is the simplest MVP path
- We can replace it later with an HTTP-based service

**Option C: Skip download, use a pre-downloaded test audio file**
- You manually download a test audio file
- Place it in a known location (e.g., `/tmp/test-audio.m4a`)
- Workflow references this static file for testing
- This is fastest for MVP validation

**Which option do you prefer? Reply with A, B, or C.**

---

## Node 4: Transcribe Audio (OpenAI Node)

**Task:** Send audio file to OpenAI whisper-1 for transcription

**Instructions will depend on Node 3 approach. Wait for your choice before proceeding.**

**General steps:**
1. Add an **OpenAI** node
2. Select operation: **Transcribe Audio**
3. Configure:
   - **Model:** `whisper-1`
   - **Audio File:** (path/URL from Node 3)
   - **Response Format:** `verbose_json` (to get segments + full text)
   - **Credential:** Select "OpenAi account"

**When complete, confirm:**
- ✅ OpenAI node created and connected
- ✅ Transcription returns successfully when tested
- ✅ Output contains `text` field with transcript

**Then say:** "Node 4 complete, ready for Node 5"

---

## Node 5: Format Output (Code Node)

**Task:** Format the OpenAI response into a clean output structure

**Instructions:**
1. Add a **Code** node after OpenAI node
2. Paste this code:

```javascript
const transcriptText = $input.item.json.text || '';
const segments = $input.item.json.segments || [];
const duration = $input.item.json.duration || 0;

return {
  ok: true,
  video_id: $('Extract Video ID').item.json.video_id,
  source_url: $('Extract Video ID').item.json.source_url,
  transcript: {
    full_text: transcriptText,
    segments: segments,
    duration: duration,
    engine: 'openai',
    model: 'whisper-1'
  }
};
```

**When complete, confirm:**
- ✅ Code node created and connected
- ✅ Output shows clean structure with `transcript.full_text`
- ✅ Full text is readable and accurate

**Then say:** "Node 5 complete, MVP workflow done"

---

## Testing the MVP

**Test Execution:**
1. Click "Execute Workflow" in n8n
2. Manual trigger runs with your test YouTube URL
3. Workflow processes through all nodes
4. Final output shows the complete transcript

**Success Criteria:**
- ✅ No errors during execution
- ✅ Transcript text is readable and matches video content
- ✅ Execution completes in reasonable time (< 2 minutes for short video)

**If successful, say:** "MVP test passed, ready to expand"

**If errors occur, provide:**
- Which node failed
- Error message
- I'll help you debug

---

## After MVP Success - Next Steps

Once the MVP works, we'll expand it to add:

1. **Database Integration**
   - Save to qxb_artifact (spine)
   - Save to qxb_artifact_video (extension)

2. **Status Tracking**
   - Update status at each stage (queued → downloading → transcribing → complete)

3. **Deduplication**
   - Check idempotency_key before processing

4. **Error Handling**
   - Catch failures and save error state
   - Cleanup temp files

5. **Chunking for Long Videos**
   - Split audio into segments
   - Loop over chunks for transcription
   - Stitch results together

6. **Switch Trigger to Execute Workflow**
   - Replace Manual Trigger with Execute Workflow Trigger
   - Accept standardized input contract

---

## Ready to Start?

**Reply with:**
1. Your OpenAI credential name (confirm it exists)
2. Your test YouTube URL (short video < 3 minutes preferred)
3. Which download approach you want to use (A, B, or C)

Then I'll guide you through building Node 1.
