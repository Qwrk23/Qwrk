# Session Continuity and Handoff System

> **Governance Document** — Defines session management rules for cross-device continuity.
>
> This system is parallel to but separate from Qwrk artifact governance.
> CLAUDE.md contains high-level behavioral guardrails; this document governs session mechanics.

## Purpose

Preserve context, intent, and next steps across devices, tools, and working sessions through a deterministic, file-based handoff system.

## Design Goals

- **Externalized working memory** — Session state lives in files, not in any single tool's context
- **Deterministic handoff** — Every session ends with a known-good state that bootstraps the next
- **Low friction** — Zero-ceremony capture by default; manual input only when inference fails
- **Resilient recovery** — Orphaned sessions are detected and resolved, never silently lost

---

## Directory Structure

```
/sessions/
├── README.md                      ← This governance document
├── CURRENT_SESSION.md             ← Active session (exists only while session is open)
├── LATEST_END_SESSION.md          ← Canonical handoff document (most recent completed session)
└── Archive/
    └── Session__YYYY-MM-DD__NNN.md  ← Immutable archived sessions (NNN resets daily at 001)
```

---

## Session Lifecycle

### Session Start Flow

**Trigger:** User declares a new session (e.g., "new session", "I'm back, let's go", "new build session", or similar intent).

**Execution:**

1. **Check for orphaned session**
   - If `CURRENT_SESSION.md` exists, invoke Failure Recovery Rule (see below)

2. **Read prior context**
   - Load `LATEST_END_SESSION.md`
   - Extract: last session summary, open threads, blockers, notes

3. **Present handoff summary**
   - Brief summary of last session's work
   - List open threads and any blockers
   - Note device and timestamp of last session

4. **Ask for session intent**
   - Offer options derived from open threads
   - Include "Something new" option
   - Capture stated intent for end-of-session accountability

5. **Create session marker**
   - Write `CURRENT_SESSION.md` with:
     - Session start timestamp
     - Device identifier
     - Stated intent
   - Session is now open; begin tracking

### Session End Flow

**Trigger:** User declares session end (e.g., "end session", "that's it for now", "wrap up", or similar intent).

**Execution:**

1. **Synthesize end session record**
   - Compile authoritative summary from session activity
   - Do NOT rely on `CURRENT_SESSION.md` breadcrumbs as source of truth
   - Include all required fields (see End Session Record Format)

2. **Archive prior handoff**
   - Move current `LATEST_END_SESSION.md` to `Archive/`
   - Rename to `Session__YYYY-MM-DD__NNN.md` (scan archive to determine next NNN for today)

3. **Write new handoff**
   - Create new `LATEST_END_SESSION.md` with synthesized record

4. **Close session**
   - Delete `CURRENT_SESSION.md`
   - Session is now closed

---

## End Session Record Format

### Required Fields

| Field | Description |
|-------|-------------|
| `session_id` | Format: `YYYY-MM-DD__NNN` (NNN resets daily at 001) |
| `device` | Device identifier (auto-inferred or manual) |
| `started_at` | ISO 8601 timestamp |
| `ended_at` | ISO 8601 timestamp |
| `summary` | Concise summary of work performed |
| `files_touched` | List of files created, modified, or deleted |
| `decisions_made` | Key decisions with brief rationale |
| `tasks_completed` | What was accomplished |
| `open_threads` | Explicit next steps or unfinished work |
| `blockers` | Anything blocking progress (empty if none) |

### Optional Fields

| Field | Description |
|-------|-------------|
| `session_intent` | What the user stated they wanted to accomplish at session start |
| `energy_note` | Qualitative state: `clear`, `foggy`, `high-energy`, etc. |
| `notes` | Any additional context for future sessions |

---

## CURRENT_SESSION.md (Working Scratch)

During an active session, `CURRENT_SESSION.md` MAY contain lightweight breadcrumbs:

- Files touched
- Major actions taken
- Notable decisions

**Constraints:**

- Breadcrumbs are **append-only** during the session
- Content must be **minimal and factual** — no narrative, no synthesis
- This file is **not authoritative history** — it is working scratch
- End-of-session synthesis **must not rely** on this file being complete or accurate

**Purpose:** Aid to memory during long sessions, never a dependency.

---

## Device Identification

**Inference order:**

1. **Primary:** `$env:COMPUTERNAME` (Windows hostname)
2. **Fallback:** Cached value in local `.session-device` file (not synced)
3. **Last resort:** Prompt user once, cache result

Device labels are **descriptive, not authoritative**. Format example: `LAPTOP-J_BLA`

---

## Failure Recovery Rule

**Condition:** New session declared while `CURRENT_SESSION.md` exists.

**Response:** Warn user and offer three options:

| Option | Behavior |
|--------|----------|
| **Resume** (default) | Continue the existing session as-is |
| **Summarize and close** | Synthesize end record from available context, archive, then start fresh |
| **Discard and start fresh** | Delete orphaned session without archiving, start new |

If no choice is made within reasonable time, **default to Resume**.

**Rationale:** Protects against data loss from forgotten closures or sync delays between devices.

---

## Trigger Phrase Recognition

Session start and end triggers use **flexible intent recognition**, not hard-coded phrases.

**Example start triggers:**
- "New session"
- "New build session"
- "I'm back, let's go"
- "Starting fresh"

**Example end triggers:**
- "End session"
- "That's it for now"
- "Wrap up"
- "Close out"

**Early use logging:** Observed trigger phrases should be noted to potentially formalize a canonical set later. Do not prematurely constrain language.

---

## Relationship to Qwrk Governance

- Sessions are a **coordination layer**, not Qwrk artifacts
- Session records are **file-based and local** to the working repository
- This system is **parallel to** but **separate from** the Qwrk artifact spine
- CLAUDE.md governs behavioral guardrails; this README governs session mechanics

---

## CHANGELOG

### v1 — 2026-02-01

**Initial version**

- Defined session lifecycle (start flow, end flow)
- Established directory structure and file naming conventions
- Specified end session record format (required and optional fields)
- Documented CURRENT_SESSION.md constraints (breadcrumbs as aid, not dependency)
- Defined device identification inference order
- Established failure recovery rule with three options (resume/summarize/discard)
- Adopted flexible trigger phrase recognition with logging for future formalization

**Source:** Seed collaboration between QP1 and Claude Code on 2026-02-01
