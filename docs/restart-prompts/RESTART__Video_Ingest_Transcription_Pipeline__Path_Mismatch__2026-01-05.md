# RESTART DOCUMENT — Qwrk Video Ingest / Transcription Pipeline
Date: 2026-01-05
Context: Restart + troubleshooting continuation

## Purpose
Create a precise restart point capturing the current failure state in the Qwrk video ingest workflow so troubleshooting can resume without re-discovery or guesswork.

This document must be saved as a Markdown file and treated as the authoritative restart reference.

---

## Current Goal
Ingest a YouTube video, extract audio via yt-dlp on a VPS, download the resulting audio file into n8n binary data, and pass it to the Transcribe node.

---

## What IS Working (Verified)
1. **Video ID extraction**
   - Video ID correctly resolves to: `dQw4w9WgXcQ`
   - Canonical watch URL generated correctly.

2. **yt-dlp execution**
   - yt-dlp successfully downloads audio as `audio.m4a`
   - Terminal verification confirms file exists at:
     ```
     /root/qwrk-video-mvp/dQw4w9WgXcQ/audio.m4a
     ```
   - Manual VPS command:
     ```
     find /root -type f -name "audio.m4a"
     ```
     confirms presence.

3. **SSH Execute Command node**
   - Runs successfully.
   - stdout confirms correct destination path.
   - File is present immediately after command execution.

---

## What Is NOT Working
**The "Download a file" (SSH → File → Download) node consistently errors with:**
```
No such file
```

This occurs even though the file exists on the VPS.

---

## Root Cause (Identified)
There is a **path mismatch between nodes**:

- yt-dlp writes to:
  ```
  /root/qwrk-video-mvp/<video_id>/audio.m4a
  ```

- The Code_Extract_Video_ID node and downstream nodes were at various times outputting:
  ```
  /tmp/qwrk-video-mvp/<video_id>
  /qwrk-video-mvp/<video_id>
  ```

This causes the Download node to request a path that does not exist in the SSH-visible filesystem.

Additionally:
- n8n SFTP access appears restricted to `/root/...`
- `/tmp` and root-level `/qwrk-video-mvp` paths are unreliable for SFTP reads in this environment

---

## Current Workflow State (Important)
⚠️ **None of the suggested fixes have been applied yet.**

The system is paused intentionally to:
- Capture a clean restart snapshot
- Avoid compounding changes
- Resume with a single authoritative path strategy

---

## Required Next Actions (Deferred)
Do NOT implement yet — listed for restart clarity only:

1. Canonicalize all paths to:
   ```
   /root/qwrk-video-mvp/<video_id>
   ```
2. Update Code_Extract_Video_ID to emit this path exactly.
3. Ensure SSH Execute Command and Download File nodes reference the same path.
4. Re-test SFTP download with explicit absolute path.

---

## Restart Instruction
When resuming:
- Assume audio file exists and yt-dlp works.
- Focus exclusively on path consistency and SFTP visibility.
- Do not rework video parsing or transcription logic until Download succeeds.

---

## Status
🟡 Paused intentionally
🧭 Ready for restart from this exact point
