# Moltbot Feature Assessment: Selective Absorption

**Created:** 2026-01-29
**Source Research:** `CC_Inbox/moltbot_clawdbot_deep_dive.md`
**Assessment By:** Qwrk + QP1 + Master Joel

---

## Core Insight

> Moltbot solves: "How do we keep an agent operationally coherent over time?"
> Qwrk solves: "How do we keep a human's intent and decisions true over time?"

Where those overlap, borrow. Where they diverge, **do not compromise**.

---

## 1. Features to REPLICATE (clean wins)

These are good systems hygiene, not Moltbot's identity.

### 1.1 Pre-Compaction Durable Intent Capture

**Moltbot:** Before compaction/summarization, triggers silent turn to flush important info into durable memory.

**Why it matters:** Summaries destroy information unless you explicitly preserve intent first.

**Qwrk Translation:**
Before:
- snapshot creation
- restart creation
- lifecycle promotion

Force a **Durable Intent Capture** step:
- What changed?
- Why does it matter?
- What must not be lost?

**Recommendation:** Formalize `pre-transition durable intent check` as first-class invariant.

---

### 1.2 Append-Only Raw Transcripts (as derived evidence)

**Moltbot:** Append-only JSONL transcripts as raw session evidence.

**Why it matters:** Provides replay, debugging, audit trails.

**Qwrk Translation:**
- Treat raw interaction logs as **evidence**, never canonical truth
- Store as append-only, write-once, never user-edited
- Link TO snapshots/restarts, not instead of them

**Recommendation:** Introduce **non-authoritative Interaction Log** layer:
- Immutable
- Queryable
- Explicitly "not the record"

---

### 1.3 Deterministic Routing / Session Isolation

**Moltbot:** Strict sessionKey discipline and deterministic routing.

**Why it matters:** Prevents context bleed, accidental cross-talk, hallucinated continuity.

**Qwrk Translation:**
- Make context boundaries **explicit artifacts**, not implicit chat history
- Enforce: "this interaction belongs to THIS project/journal/restart"
- No hidden carryover

**Recommendation:** Adopt explicit context binding rule:
> No input without a declared target artifact.

---

## 2. Features to ADAPT (not copy)

Useful ideas, but Moltbot's implementation would damage Qwrk if copied directly.

### 2.1 Local-First Inspectability

**Moltbot Strength:** Markdown files as readable truth.

**Why NOT to copy directly:**
- Files blur authorship
- No lineage
- No guarantees
- Easy accidental mutation

**Qwrk Adaptation:**
- Keep Supabase as truth
- Add: human-readable views, exportable markdown, diff views, time-travel inspection

**Principle:**
> Inspectable ≠ mutable
> Readability ≠ authority

---

### 2.2 Silent System Turns (NO_REPLY concept)

**Moltbot:** Silent agent actions that don't surface to the user.

**Risk:** Silent actions can hide meaning.

**Qwrk Adaptation:**
- Allow silent *execution*
- Require **visible recording** — every silent action must leave a trace artifact
- Nothing happens "off ledger"

**Rule:**
> Silence in UI is allowed.
> Silence in history is not.

---

## 3. Features to EXPLICITLY NOT REPLICATE

These are seductive — and wrong for Qwrk's goals.

### 3.1 Markdown-as-Canonical-Memory

**Status:** HARD NO

**Why:**
- Destroys historical truth
- Collapses authorship
- Makes trust subjective

Qwrk's power comes from **structured, immutable records**.

---

### 3.2 Gateway-as-Source-of-Truth

**Status:** HARD NO

**Moltbot:** Gateway owns reality
**Qwrk:** Artifacts own reality; Gateway is just a conduit

This distinction is foundational.

---

### 3.3 Mutable "Safe to Edit" Session State

**Status:** ABSOLUTELY NOT

Qwrk's discipline:
- Mistakes are recorded
- Changes are explicit
- Nothing is quietly rewritten

This is why Qwrk can be trusted long-term.

---

## Recommended Next Steps (in order)

1. **Define Qwrk's Irreducible Core (v1)** — things it will NEVER trade away
2. **Add Durable Intent Capture invariant** — inspired by Moltbot's flush
3. **Design Interaction Log layer** — evidence, not truth
4. **Proceed to Coach Qwrk: A1C** — ignore everything else for now

---

## The Strategic Position

> You're not behind competitors.
> You're designing a system they literally cannot copy without changing who they are.
