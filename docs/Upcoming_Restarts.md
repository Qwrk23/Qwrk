# Upcoming Restarts

Quick reference for build session handoffs.

**Trigger phrases:** "Good morning" | "Let's go!" | "Restart" | "What's next?" | "Morning briefing"

---

## Ready to Execute

### BUG-011 Completion: Telegram Tags + QP1 Auto-Tagging
**File:** `docs/restarts/RESTART__BUG-011__Telegram_Tags_and_QP1_Instructions__2026-02-01.md`
**Target:** 2026-02-01 or 2026-02-02
**Est. Time:** 30-45 min

**Summary:**
1. Re-add tags to Telegram save tools (with strict "always provide" rule)
2. Update Gateway_Telegram system prompt for tag extraction + auto-generation
3. Create QP1 tags instruction document

**Context:** Gateway-side BUG-011 is complete (Save v25, List v27, Schema v2.2.0). This session completes Telegram integration.

---

### Trust Restoration Week - Remaining Items
**Artifact ID:** `29f2f0d7-69bd-4759-ae2c-d003c9685f3e`
**Status:** Partially complete

**Completed:**
- [x] BUG-012 (project content persistence)
- [x] BUG-011 Gateway (tags normalization + filter)

**Remaining:**
- [ ] Soft-delete 15 duplicate seeds
- [ ] Promote Gateway+Telegram to Tree
- [ ] Add monthly dead seed archival governance rule

---

## Queued (Not Yet Scheduled)

### RAG Seed - Walking the Ground - Baby Steps 1-3
**Artifact ID:** `d0669388-31e2-432a-8aba-4d31b58cfcf7`
**Type:** Journal
**Parent Seed:** `c02b26b5-2a5f-48e6-9928-dd5aea1c6be2`

**Pending decisions:**
- Confirm RAG boundary definition (retrieval, not authority)
- Pick 2-3 use cases from: Withering awareness, Active focus, Decision recall, Topic recall, Workspace grounding

---

## Completed

_(Move restarts here after execution)_

---

## How to Use

1. At session start, ask CC: "What should we work on this morning?"
2. CC automatically queries Qwrk for last 24 hours of artifact activity and presents summary
3. CC reads this file and retrieves the top "Ready to Execute" restart from Qwrk
4. CC presents the combined briefing: recent activity + queued action plan
5. After completing a restart, move it to "Completed" with date

**Morning Briefing includes:**
- Artifacts created/updated in last 24 hours
- Duplicates or anomalies flagged
- Top restart from queue with full content

**Last Updated:** 2026-02-01
