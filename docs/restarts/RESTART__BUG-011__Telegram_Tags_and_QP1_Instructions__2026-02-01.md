# RESTART: BUG-011 — Telegram Tags + QP1 Auto-Tagging

**Date:** 2026-02-01
**Priority:** High
**Estimated Scope:** 30-45 min

---

## Context: What Was Completed

BUG-011 Gateway-side implementation is **DONE**:
- **Save workflow (v25):** Tags normalized as lowercase, trimmed, deduped array
- **List workflow (v27):** `selector.filters.tags_any` filtering works
- **Actions Schema (v2.2.0):** Updated for tags array + tags_any
- **PowerShell tests:** Verified end-to-end

**Commits:**
- `119afee` — Gateway: tags normalization + list filter
- `d611f89` — Actions Schema: tags array + tags_any
- `fdfe410` — Bug tracker update

---

## What Remains: Telegram + QP1

### Architecture
```
QP1 (ChatGPT 5.2) → Telegram message → Gateway_Telegram (4o-mini) → Gateway
```

QP1 is the smart model that should decide tags. Gateway_Telegram just relays.

### Problem
Telegram tools don't have `tags` parameter (reverted due to n8n limitation where all placeholders are required).

---

## Tasks for This Session

### 1. Re-add tags to Telegram save tools

**File:** `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1.json`

Add `tags` parameter to:
- `Tool_Save_Journal`
- `Tool_Save_Project`

**Critical:** Update descriptions to state AI MUST always provide tags (use `[]` if none).

Example:
```json
{
  "name": "tags",
  "description": "REQUIRED: Array of tags. Use [] if no tags. Example: [\"planning\", \"q1\"]",
  "type": "json"
}
```

### 2. Update Gateway_Telegram system prompt

Update the AI Agent's system prompt to:

1. **Extract tags from user message** if specified (e.g., "tagged: x, y" or "tags: planning, review")
2. **Auto-generate tags** based on content/context if user doesn't specify
3. **Always pass tags array** to save tools (never omit)

Suggested tag extraction patterns:
- "tagged: tag1, tag2"
- "tags: [tag1, tag2]"
- "with tags tag1 and tag2"

Suggested auto-tag rules:
- Journal about a project → tag with project name
- Restart prompt → ["restart", "context"]
- Snapshot → ["snapshot", "milestone"]
- Contains "bug" or "fix" → ["bugfix"]

### 3. Create QP1 tags instruction document

**File:** `docs/qwrk-instructions/QP1_Tags_Guide.md`

Document for QP1 describing:
- Available tags (start with open vocabulary, can constrain later)
- How to specify tags in Telegram messages
- Auto-tagging conventions
- Examples

---

## Key Files

| File | Purpose |
|------|---------|
| `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1.json` | Telegram workflow (tools + system prompt) |
| `docs/qwrk-instructions/QP1_Tags_Guide.md` | New file: QP1 tagging instructions |
| `docs/Qwrk_Bug_Tracker.md` | Update when complete |

---

## Acceptance Criteria

- [ ] Telegram save tools have `tags` parameter
- [ ] Gateway_Telegram system prompt handles tag extraction + auto-generation
- [ ] QP1 tags guide document created
- [ ] Test: QP1 → Telegram → Gateway with explicit tags
- [ ] Test: QP1 → Telegram → Gateway with auto-generated tags
- [ ] Bug tracker updated to mark BUG-011 CLOSED

---

## Test Prompts (for QP1 via Telegram)

**Explicit tags:**
```
Save journal titled "Planning Session" tagged planning, q1: Today we discussed roadmap priorities...
```

**Auto-tags (AI decides):**
```
Save journal titled "Bug Investigation": Found the root cause of the hydration issue...
```
(AI should auto-tag with something like ["bugfix", "investigation"])

---

## Notes

- n8n `toolHttpRequest` requires all placeholders — AI must ALWAYS provide tags
- If AI fails to provide tags, tool call will error
- Consider fallback: catch error, retry with `[]`
