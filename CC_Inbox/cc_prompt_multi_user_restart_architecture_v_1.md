# CC Implementation Prompt

## Objective
Design and implement the newly defined Multi-User Restart architecture for Qwrk, introducing explicit Restart types while preserving Prime Re-anchor semantics. This pass targets Multi-User Qwrk only (Qwrk@Wrk and future clones). QBeta inherits at build time.

This is an instruction-layer + semantic implementation. No database schema changes. No workflow changes unless strictly required (and justify if so).

---

# Architectural Decisions (Locked)

## 1. Restart Semantics (Multi-User)

"Restart" = Continuity tool (NOT cognitive reset).

Two explicit commands:

- `restart artifact`
- `conversation restart command`

If user says only "restart", Q must ask:

> "Do you want a restart artifact (persistent) or a conversation restart command (context compression)?"

No inference.
No auto-detection.
Explicit confirmation required.

---

## 2. Re-anchor (Prime Only)

Re-anchor replaces the previous philosophical Restart concept.

Re-anchor is:
- Non-artifact
- Cognitive reset
- No Gateway save
- No persistence

This prompt does NOT modify Prime Re-anchor behavior.
Only Multi-User Restart semantics change.

---

## 3. Scope Boundary — QBeta

QBeta inherits this Restart architecture at build time. No QBeta files or surfaces are modified in this pass. All implementation tasks target Multi-User Qwrk (Qwrk@Wrk and future clones).

---

# Restart Types (Multi-User)

## A. Restart Artifact (Persistent)

Purpose:
Operational continuity checkpoint.
Must be fully self-sufficient.

### Flow

1. Review the FULL conversation buffer (not just latest turns).
2. Detect durable decision density.
3. Suggest journal save only if durable architectural/governance decisions detected.
4. Upon confirmation, generate Gateway payload(s).

### Journal Suggestion Rule

Do NOT suggest journal save based on length.
Only suggest journal save if:
- Governance decisions were made
- Architecture defined
- Lifecycle transitions discussed
- Multi-user boundary clarified
- System design altered

If tactical/debug-only conversation:
Restart alone is sufficient.

---

## Restart Artifact Payload Structure

Use existing schema:

artifact_type: restart
extension.payload: object

DO NOT create new DB fields.
DO NOT alter DDL.
Reference LIVE_DDL__Kernel_v1__2026-01-04.sql to confirm canonical structure.

Restart payload MUST contain:

{
  "objective": "string",
  "summary_of_state": "string",
  "key_decisions": ["string"],
  "active_threads": ["string"],
  "unresolved_questions": ["string"],
  "constraints": ["string"],
  "next_action": "string",
  "source_journal_id": "uuid | null"
}

Rules:
- Self-sufficient (must allow resumption without journal retrieval)
- No raw transcript embedded
- source_journal_id optional
- Deterministic structure

**Known Limitation (T41):** Restart artifacts are currently subject to the same tag mutation limitation as other immutable artifact types. Tag add/remove operations may fail until T41 (Tag Update Regression) is resolved. This is a known limitation and does not block Restart creation.

### Restart Artifact Title Rule

Autogenerate title using:

`Restart - <Primary Objective>`

Primary Objective must be extracted from full conversation analysis. No user-provided title required.

---

### Restart Artifact Ordering (If Journal Recommended)

Correct sequence:

Step 1 — Save Journal (full transcript)
Step 2 — Restart Artifact referencing journal UUID

Restart must never precede journal save.

---

## B. Conversation Restart Command (Surface Only)

Purpose:
Context window compression.
No Gateway interaction.
No artifact creation.

Output:
- Canvas block
- Structured resume prompt
- Must review FULL conversation buffer
- Must not bias toward latest turns

Must capture:
- Core objective
- Key decisions
- Active threads
- Constraints
- What we were about to do

Concise but complete.
Optimized for copy/paste into new conversation.

---

# Implementation Tasks

## 1. Create New Instruction Pack

**Canonical location (ONLY):**

`Multi-User Qwrk/04_Instruction_Packs/Restart_Semantics_v1.md`

Do NOT duplicate into project folders. Projects must reference this instruction pack rather than embedding restart logic directly.

Must conform to `Multi-User Qwrk/04_Instruction_Packs/INSTRUCTION_PACK_TEMPLATE.md` structure. Must not violate existing Gateway contract definitions.

Must define:
- Explicit command handling (restart artifact vs conversation restart command)
- Restart Artifact rules (Gateway artifact creation)
- Conversation Restart Command rules (surface-only, no persistence)
- Journal suggestion detection criteria
- Full-buffer extraction requirement
- Prohibition of latest-turn bias
- Restart Artifact title auto-generation rule

---

## 2. Update QW System Instructions

**File:**

`Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/qwrk_work_system_instructions_v_1.md`

Updates required:
- Remove any philosophical Restart framing
- Insert explicit command routing:
  - If user types "restart": Ask "Do you want a restart artifact (persistent) or a conversation restart (context compression)?"
- Define Re-anchor as Prime-only (not available in QW)
- Reference `Restart_Semantics_v1` instruction pack for full behavioral rules
- Clarify that only Restart Artifact creates a Gateway artifact; Conversation Restart Command performs no persistence

---

## 3. Update Clone Template

**File:**

`Multi-User Qwrk/03_ChatGPT_Projects/SYSTEM_INSTRUCTIONS_TEMPLATE.md`

Ensure all future clones inherit:
- Explicit restart command disambiguation (restart artifact vs conversation restart command)
- Restart Artifact rules (Gateway save with deterministic payload)
- Conversation Restart Command rules (surface-only, no persistence)
- No philosophical restart framing
- Reference to `Restart_Semantics_v1` instruction pack

If no restart logic currently exists in the template, insert the new block deterministically.

---

## 4. Confirm No Workflow Changes Needed

Validate:
- artifact.save supports restart type (already exists)
- extension.payload object fully supported
- No selector stripping issues
- Tag update regression acknowledged (T41 known limitation — does not block creation)

If workflow change required, document why.
Default assumption: none required.

---

# Extraction Discipline Requirement

Restart generation MUST:

- Scan full conversation buffer
- Extract high-signal threads
- Identify unresolved loops
- Identify decisions already made
- Identify immediate next action

Must NOT:
- Summarize only last 10–15 turns
- Default to shallow recap
- Embed transcript

---

# Validation Checklist

After implementation:

1. Run restart artifact on:
   - Tactical thread
   - Architectural thread

2. Confirm journal suggestion triggers only on durable decisions.

3. Confirm restart artifact self-sufficient (resume without journal).

4. Run conversation restart command on long thread.

5. Confirm full-buffer extraction.

6. Confirm no Prime Re-anchor behavior changed.

7. Confirm clone inherits behavior.

---

# Non-Goals

- No DDL changes
- No new DB columns
- No workflow redesign
- No Prime Re-anchor modification
- No automatic archival based on conversation size
- No QBeta files or surfaces modified in this pass

---

# Deliverables

1. New instruction pack file
2. Updated QW system instructions
3. Updated template
4. Summary of changes
5. Explicit confirmation that no schema/workflow changes were required

---

End of prompt.

Proceed deterministically.

