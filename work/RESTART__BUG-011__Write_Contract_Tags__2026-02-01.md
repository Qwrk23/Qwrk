# RESTART: BUG-011 — Write Contract Blocks Spine Fields

**Date:** 2026-02-01
**Context:** Continuing from Gateway Telegram bug fix session

---

## Session Summary (Just Completed)

**Bugs Closed:**
- BUG-012: Project summary placeholder (Telegram)
- BUG-013: Restart save uses extension.payload.body
- BUG-014: parent_artifact_id placeholder (Telegram)
- S2: Empty UUID → null normalization in Save workflow
- L3: List limit parameter added to Telegram

**Commit:** `183a2ae`
**Snapshot:** `7443c016-61e7-4367-b596-986a4042d00d`

---

## BUG-011: Write Contract Registry blocks spine fields

**Status:** Open
**Severity:** High (blocks first-class tags; prevents search by tag)
**Component:** qfe Write Contract Registry + Gateway validator + artifact.list

### Symptoms
- `artifact.save` with `tags` rejected at qfe preflight (never reaches Gateway)
- `artifact.save` with `summary` rejected: "Field is not defined in the project write contract"
- Structured content JSON mapped to `extension` instead of `content`
- Write Contract only allows `title` + `extension.lifecycle_stage`

### Root Cause
qfe Write Contract Registry is overly restrictive. Only allows:
- `title`
- `extension.lifecycle_stage`

Rejects legitimate spine fields: `summary`, `tags`, `content`, `parent_artifact_id`, `priority`

### Required Fixes (ALL REQUIRED — no partial ship)

| # | Component | Change |
|---|-----------|--------|
| 1 | qfe Write Contract | Update CREATE allow-lists for ALL types to permit spine fields |
| 2 | Gateway validator | Accept top-level `tags`, persist to `qxb_artifact.tags` with normalization |
| 3 | Gateway artifact.list | Add `selector.filters.tags_any` filter support |
| 4 | Tests | Tag filtering regression tests |

### Spine Fields to Allow
- `title` (required for most types)
- `summary` (optional)
- `tags` (optional) — NEW
- `content` (optional)
- `parent_artifact_id` (optional, type-governed)
- `priority` (optional)

### Tag Normalization Rules
- Trim strings
- Drop empty
- De-dupe
- Lowercase for deterministic search

### Acceptance Criteria
- [ ] Create journal with `tags: ["conversation"]` succeeds
- [ ] `artifact.list` with `tags_any: ["conversation"]` returns only matching journals
- [ ] Tags persisted in `qxb_artifact.tags` and hydrated correctly
- [ ] Unknown top-level fields still rejected

---

## Key Files

- **Bug Tracker:** `docs/Qwrk_Bug_Tracker.md`
- **Specification:** `CC_Inbox/cc_prompt_tags.md` (if exists)
- **Gateway Save:** `workflows/NQxb_Artifact_Save_v1 (24).json`
- **Gateway List:** `workflows/NQxb_Artifact_List_v1 (26).json`
- **Telegram Workflow:** `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1.json`

---

## Open Bugs (Other)

| Bug | Severity | Description |
|-----|----------|-------------|
| BUG-003 | Medium | Query hydrates when hydrate: false |
| BUG-004 | Medium | instruction_pack Update not implemented |
| BUG-008 | Medium | GPT Actions serialization (OpenAI issue) |
| BUG-015 | Medium | Promote has no validation |

---

## Next Steps

1. Check if `CC_Inbox/cc_prompt_tags.md` exists with full spec
2. Identify qfe Write Contract location (may be in different repo)
3. Start with Gateway-side changes (tags normalization + list filter)
4. Coordinate qfe changes separately if needed
