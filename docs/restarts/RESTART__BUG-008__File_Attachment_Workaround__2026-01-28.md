# Restart Prompt: BUG-008 File Attachment Workaround

**Created:** 2026-01-28
**Bug Reference:** BUG-008 (GPT Actions serialization fails on complex content)
**Bug Tracker:** `docs/Qwrk_Bug_Tracker.md`

---

## Context

BUG-008 is caused by an undocumented ~760-token limit in ChatGPT's function-call wrapper for GPT Actions `params` JSON. Boot mode consumes tokens for instructions, leaving approximately ~1KB for journal payload. Non-boot mode has higher limits (~1.5KB+) but still constrained.

QP1 research (2026-01-28) identified **file attachment** as a promising workaround that bypasses the token limit entirely.

---

## File Attachment Approach

### Capability

GPT Actions support:
- Up to **10 file attachments** per request
- Files can be **hundreds of MB**
- Files are passed via `openaiFileIdRefs` in the action payload
- Backend receives signed URLs to retrieve file content

### How It Would Work

1. User provides journal content to Qwrk (conversation, paste, or dictation)
2. Qwrk creates a temporary file containing the journal content
3. Qwrk calls `artifact.save` with file reference instead of inline `entry_text`
4. Gateway (n8n) receives `openaiFileIdRefs` array
5. Gateway fetches file content from OpenAI signed URL
6. Gateway stores content in `extension.entry_text` or `extension.payload`

### Benefits

- **No size limit** — files can be hundreds of MB
- **No token budget competition** — file content not counted against params limit
- **Works in boot mode** — instructions don't affect file size
- **Single call** — no chunking/reassembly complexity

### Challenges to Investigate

1. **qfe instruction changes** — How to instruct Qwrk to create and attach files?
2. **n8n file retrieval** — Can n8n fetch from OpenAI signed URLs?
3. **File format** — Plain text? JSON? Markdown?
4. **Signed URL expiration** — How long are URLs valid?
5. **User experience** — Is file creation seamless or awkward?

---

## Research Tasks

### Task 1: Understand `openaiFileIdRefs` Structure

Research the exact JSON structure GPT Actions uses for file attachments:
```json
{
  "openaiFileIdRefs": [
    {
      "id": "file-xxxx",
      "name": "journal_entry.txt",
      "mime_type": "text/plain",
      "download_url": "https://..."
    }
  ]
}
```

### Task 2: Test File Creation in ChatGPT

Determine if ChatGPT can programmatically create files for attachment:
- Can Code Interpreter create a file and attach it to an action call?
- Can the model instruct the user to "save as file" and attach?
- Is there an automatic file-from-conversation feature?

### Task 3: n8n File Retrieval

Test if n8n HTTP Request node can:
- Fetch from OpenAI signed URLs
- Handle authentication/headers if required
- Process file content into database fields

### Task 4: Prototype Gateway Changes

If viable, design the Gateway modification:
- New field in normalize request: `file_refs`
- Conditional: if `file_refs` present, fetch and extract content
- Map fetched content to `entry_text` / `payload`

---

## Test Plan

1. **Manual file attachment test** — Attach a .txt file to a GPT Action call manually and inspect what n8n receives
2. **Signed URL fetch test** — Use n8n HTTP Request to fetch from the URL
3. **End-to-end prototype** — Modify Gateway to handle file refs and store content

---

## Success Criteria

- [ ] Journal content >10KB successfully saved via file attachment
- [ ] Works in boot mode without hitting token limit
- [ ] Single API call (no chunking)
- [ ] Content persists correctly in database

---

## Alternative If File Attachment Fails

Fall back to **chunking strategy**, which requires:
1. Fix BUG-010 (UPDATE path not working)
2. Implement chunk reassembly in Gateway
3. qfe sends multiple sequential calls with chunk metadata

---

## Related Files

- `docs/Qwrk_Bug_Tracker.md` — BUG-008 documentation
- `workflows/NQxb_Artifact_Save_v1 (24).json` — Current Save workflow
- `docs/qwrk-instructions/` — qfe instruction packs (if modifying prompts)

---

## Start Command

To begin this investigation, ask:

> "I'm exploring the file attachment workaround for BUG-008. First, help me understand how GPT Actions handle file attachments via `openaiFileIdRefs`. What does the payload structure look like when a file is attached to an action call?"
