# Instruction Pack — Restart Semantics v1

**Purpose:** Behavioral rules for Restart command handling across all Multi-User Qwrk surfaces.
**Scope:** Multi-User Qwrk (Qwrk@Wrk and future clones). QBeta inherits at build time.
**Version:** v1
**Created:** 2026-02-19

---

## Command Routing

When user types "restart" without qualification, Q MUST ask:

> "Do you want a restart artifact (persistent) or a conversation restart (context compression)?"

No inference. No auto-detection. Explicit confirmation required.

Two valid commands:

| Command | Effect | Gateway Artifact |
|---------|--------|-----------------|
| `restart artifact` | Creates a persistent restart artifact via Gateway | Yes |
| `conversation restart` | Surface-only context compression for copy/paste | No |

---

## A. Restart Artifact (Persistent)

Creates a Gateway artifact of type `restart`. This is the ONLY restart command that produces persistence.

### Flow

1. Review the FULL conversation buffer (not just latest turns).
2. Detect durable decision density.
3. Suggest journal save only if durable architectural/governance decisions detected.
4. Upon confirmation, generate Gateway payload.

### Title Rule

Autogenerate title using:

```
Restart - <Primary Objective>
```

Primary Objective must be extracted from full conversation analysis. No user-provided title required.

### Payload Structure

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "restart",
  "title": "Restart - <Primary Objective>",
  "priority": 3,
  "tags": ["restart"],
  "extension": {
    "payload": {
      "objective": "string",
      "summary_of_state": "string",
      "key_decisions": ["string"],
      "active_threads": ["string"],
      "unresolved_questions": ["string"],
      "constraints": ["string"],
      "next_action": "string",
      "source_journal_id": "uuid | null"
    }
  }
}
```

**Required fields:** `gw_action`, `gw_workspace_id`, `artifact_type`, `title`, `priority`, `extension.payload`

### Payload Rules

- **Self-sufficient:** Must allow resumption without journal retrieval.
- **No raw transcript:** Never embed conversation text.
- **source_journal_id:** Optional. Populated only if companion journal was saved.
- **Deterministic:** All payload fields required. Use empty arrays `[]` if no entries.
- **Full-buffer extraction:** Must scan entire conversation, not just recent turns.

### Journal Suggestion Rule

Do NOT suggest journal save based on conversation length.

Only suggest journal save if:
- Governance decisions were made
- Architecture defined
- Lifecycle transitions discussed
- Multi-user boundary clarified
- System design altered

If tactical/debug-only conversation: Restart artifact alone is sufficient.

### Ordering (If Journal Recommended)

Correct sequence:

1. Save Journal first (with full transcript in `entry_text`)
2. Save Restart Artifact with `source_journal_id` referencing the journal UUID

Restart must never precede journal save.

### Known Limitation

Restart artifacts are immutable. Tag add/remove operations may fail until T41 (Tag Update Regression) is resolved. This does not block Restart creation. Set tags correctly at save time.

---

## B. Conversation Restart Command (Surface Only)

No Gateway interaction. No artifact creation. No persistence.

### Purpose

Context window compression. Produces a structured resume prompt for copy/paste into a new conversation.

### Output Format

Produce a structured resume prompt in a canvas block containing:

- **Core objective** — What we were working on
- **Key decisions made** — Decisions locked during this conversation
- **Active threads** — Work items in progress or pending
- **Constraints discovered** — Blockers, limitations, guardrails identified
- **Immediate next action** — What we were about to do

### Extraction Discipline

MUST:
- Scan full conversation buffer
- Extract high-signal threads
- Identify unresolved loops
- Identify decisions already made
- Identify immediate next action

MUST NOT:
- Summarize only last 10-15 turns
- Default to shallow recap
- Embed raw transcript
- Bias toward most recent turns at expense of earlier context

### Format

Concise but complete. Optimized for copy/paste into a new conversation window.

---

## Re-anchor (Not Available)

Re-anchor is a Prime-only cognitive reset concept. It is NOT available in Multi-User Qwrk surfaces.

If a user asks about Re-anchor, explain it is a Prime feature and offer restart artifact or conversation restart command instead.

---

## Constraints

- Do not modify DDL or database schema
- Do not modify Gateway workflows
- All restart artifacts use existing `restart` artifact_type
- `extension.payload` must be a valid JSONB object
- Always include `priority: 3` explicitly
- Title must follow auto-generation rule: `Restart - <Primary Objective>`
- One command at a time — stop and wait after emitting payload
