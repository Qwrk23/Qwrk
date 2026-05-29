# Qwrk Workflow Patterns

Reference file for common artifact creation patterns. See system instructions for core rules.

**Concept distinction (sessions):** `/wake` (full startup), **Subsession** (in-conversation lane, no loads, no persists), **Conversation Restart** (context-compression handoff in a new chat). See `Instruction_Pack__Session_Lifecycle__QW__v3.md` for the full distinction table.

---

## Workbench

**Trigger (add):** "add this to the workbench" / "workbench this" / "put this on the workbench" while engaging an artifact.

**Trigger (remove):** "remove from workbench" / "done with this" / "off the workbench" / "clear this off the workbench".

**Eligible types:** `project`, `snapshot`, `twig`.

**Action (add, existing artifact):** `artifact.update` with structured tags — `{ "tags": { "add": ["workbench"] } }`. Flat array forbidden on update.

**Action (add, new/unsaved artifact):** include `"workbench"` in tags on the save payload.

**Action (remove):** `artifact.update` with structured tags — `{ "tags": { "remove": ["workbench"] } }`.

**Effect:** Workbench-tagged artifacts are surfaced at `/wake` as the active working set (3 list calls — one per eligible type). On selection, Q hydrates the chosen item.

**Canonical spec:** `Instruction_Pack__Session_Lifecycle__QW__v3.md` → Workbench.

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

---

## Subsession

**Triggers:** `new subsession`, `subsession`, `start subsession`, `clean lane`, `new working lane`, `/new sub`, `new sub`, `nsub`, `sub` — fire only when the phrase is the **leading/bare** message in a Joel turn (embedded mentions do not trigger).

**Behavior:** In-conversation clean working lane. Q acknowledges, asks for Primary Outcome if missing, proceeds. **No Gateway calls. No persistence. Preserves all `/wake` context (End Session + Rolling Memory + Workbench).**

**Workbench in subsession:** Q may reference the already-loaded Workbench summary or ask once whether the lane anchors to a Workbench item. Q does NOT re-list. Q hydrates only on selection.

**Lane close:** `end subsession`, `close lane`, `back to main`, `exit lane` → Q acknowledges, discards lane-local context, returns to parent session. No save.

**Fresh-tab refusal:** If triggered before `/wake` context is loaded, Q refuses: `"Subsession requires loaded session context. Run /wake first, or start a full session."`

**Canonical spec:** `Instruction_Pack__Session_Lifecycle__QW__v3.md` → Subsession Protocol.

---

## Twig Exploration (T94)

**Trigger:** Small experiment, micro-initiative, or exploratory thread worth tracking but not yet project-worthy.

**Artifact:** Twig
**Title:** `Twig — [IDEA]`
**Tags:** `twig`, `[topic]`, `[parent-context]`
**Parent:** Typically attached to a Limb via `parent_artifact_id`

**Lifecycle:**
1. Created as `proposed` (default)
2. When actively exploring → update to `active`
3. If it graduates → update to `promoted` (create a real project)
4. If abandoned → update to `pruned`

**Note:** Twigs are spine-only (no extension table) and do NOT require `semantic_type_id`.
