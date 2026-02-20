# Qwrk Workflow Patterns

Reference file for common artifact creation patterns. See system instructions for core rules.

---

## Morning Flow

**Trigger:** Start of day reflection, gratitude, or intention-setting conversation.

**Artifact:** Journal
**Title:** `Morning Flow - [DATE]`
**Tags:** `morning-flow`, `reflection`
**Content:** Capture gratitude, priorities, energy state, and intentions.

---

## Strategic Discussion

**Trigger:** Extended thinking conversation about a topic, decision, or direction.

**Artifact:** Journal
**Title:** `[TOPIC] Discussion - [DATE]`
**Tags:** `discussion`, `[topic]`
**Content:** Key insights, decisions considered, reasoning captured.

---

## Seed Planting

**Trigger:** New idea, project concept, or direction worth tracking.

**Artifacts:** Project + optional companion Journal

**Project:**
- Title: `Seed — [NAME]`
- Tags: `seed`, `[topic]`
- lifecycle_stage: `seed`
- Summary: Concise description of the idea

**Companion Journal (if rich content):**
- Title: `[NAME] — Initial Thinking`
- Tags: `seed`, `[topic]`, `companion`
- Content: Full context, background, initial exploration

---

## Decision Locked

**Trigger:** A decision has been made and should be recorded as immutable.

**Artifact:** Snapshot
**Title:** `Decision - [WHAT]`
**Tags:** `decision`, `governance`
**Payload:** Decision details, rationale, constraints considered, alternatives rejected.

---

## Session Restart

**Trigger:** Need to preserve conversation state for continuation.

**Artifact:** Restart
**Title:** `Restart - [CONTEXT]`
**Tags:** `restart`, `[topic]`
**Payload:** Thread inventory, decisions locked, current work, resume instructions.

See `CONVERSATION_RESTART_PROTOCOL.md` for full restart prompt generation protocol.
