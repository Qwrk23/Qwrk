# Telegram Gateway Payload Rules

**Critical:** The Telegram Gateway uses n8n placeholder substitution which parses content as JSON. Special characters break JSON parsing.

---

## FAILED Format (Do NOT use)

```
Save snapshot titled "KGB Proof - CC Direct Supabase Access via RLS - 2026-01-30":

## Summary

CC (Claude Code) has been granted direct read access...

## Implementation Details

- **Supabase URL:** https://npymhacpmxdnkqdzgxll.supabase.co
- **Credentials location:** new-qwrk-kernel/.env.supabase

```powershell
.\Query-Supabase.ps1 -Table "qxb_artifact" -Limit 10
```

## KGB Verification Results

- Test 1: 10 rows ✅
- Test 2: 376 artifacts ✅
```

**Why it failed:**
- Markdown headers (`##`)
- Bullet points with special chars (`**bold**`)
- Code blocks with triple backticks
- Newlines create control characters in JSON
- Emojis (✅) can cause encoding issues

**Error received:**
```
Could not replace placeholders in body: Bad control character in string literal in JSON at position 334 (line 10 column 26)
```

---

## WORKING Format (Use this pattern)

```
Save snapshot titled "KGB Proof - CC Direct Supabase Access via RLS - 2026-01-30": CC has been granted direct read access to Qwrk Supabase via REST API with RLS enforcement. Implementation: Supabase URL is npymhacpmxdnkqdzgxll.supabase.co, credentials stored in new-qwrk-kernel/.env.supabase (anon key only), query script at phase1.5-chat-gateway/scripts/Query-Supabase.ps1. Scope limited to Master Joel Workspace (be0d3a48-c764-44f9-90c8-e846d9dbbd0a). Tables with CC read access: qxb_artifact, qxb_workspace, qxb_artifact_project, qxb_artifact_journal, qxb_artifact_snapshot, qxb_artifact_restart. Security posture: anon key only, RLS enforced, read-only (no writes), all writes remain Gateway-only. KGB Verification (2026-01-30): Test 1 list journals returned 10 rows, Test 2 count artifacts returned 376 total, Test 3 fake workspace returned 0 rows confirming RLS is working. Implements seed cb506bc8-497a-4eca-8a2a-68a77c07e8cd (CC Read Access via RLS).
```

**Why it works:**
- Single continuous paragraph
- No newlines within content
- No markdown formatting (no `#`, `**`, `-`, backticks)
- No emojis or special unicode
- Plain punctuation only (periods, commas, colons, parentheses)
- Colons used as separators instead of bullets

---

## Rules for Telegram Prompts

1. **Single paragraph** — No line breaks within content
2. **No markdown** — No headers, bold, italic, code blocks, bullets
3. **No emojis** — Avoid unicode symbols
4. **Plain text only** — Use colons and commas for structure
5. **Use periods to separate sections** — Instead of newlines
6. **Parentheses for grouped info** — (like this)
7. **Keep it readable** — Short phrases, clear structure

---

## Template Pattern

```
Save [type] titled "[TITLE]": [First section]. [Second section]: [details]. [Third section]: [more details]. [Final section].
```

**Example:**
```
Save journal titled "Architecture Discussion - Jan 2026": We discussed the auth approach for Phase 2. Key decisions: use Supabase Auth for MVP, defer OAuth integration to Phase 3. Next steps: implement login flow, add session handling, test RLS policies. Participants: Joel, CC.
```

---

## When Content Must Have Structure

If complex content is required, save it as a journal first (journals are more forgiving), then reference it in snapshots:

```
Save journal titled "Detailed Implementation Notes - Feature X": [full structured content here]
```

Then for the formal snapshot:
```
Save snapshot titled "Feature X Complete": Feature X implementation finished. See journal "Detailed Implementation Notes - Feature X" for full details. Summary: [brief plain-text summary].
```
