# Qwrk Irreducible Core — v1 (DRAFT)

**Created:** 2026-01-29
**Status:** DRAFT — Awaiting Master Joel approval
**Purpose:** Define what Qwrk will NEVER trade away

---

## What This Document Is

This document defines Qwrk's **non-negotiable principles** — the things that make Qwrk what it is. These principles govern ALL design decisions, feature additions, and tradeoffs.

If a proposed feature or optimization violates any principle in this document, the answer is **no**.

---

## The Irreducible Core

### 1. Artifacts Own Reality

**Principle:** Artifacts are the source of truth. The Gateway is a conduit, not the authority.

**What this means:**
- Truth lives in the database, in structured artifact records
- The Gateway routes, validates, and enforces — it does not define reality
- If the Gateway crashes, reality is not lost
- Artifacts can be queried directly; Gateway is not required for truth retrieval

**What this prevents:**
- "Gateway as source of truth" patterns (Moltbot)
- Session state that exists only in memory
- Truth that requires a running process to access

---

### 2. Historical Truth Is Immutable

**Principle:** Once created, snapshots and restarts cannot be modified or deleted.

**What this means:**
- Snapshots preserve the exact state at lifecycle transitions
- Restarts preserve the exact state at ad-hoc freezes
- Neither can be edited, even by admins
- Soft delete is allowed (hidden from views), but the record persists

**What this prevents:**
- Rewriting history to hide mistakes
- "Fixing" embarrassing decisions after the fact
- Audit trail corruption
- Loss of trust in historical records

---

### 3. Mistakes Are Recorded, Not Erased

**Principle:** Errors, bad decisions, and failed attempts are part of the record.

**What this means:**
- No "quiet rewriting" of state
- Changes are explicit (new version, new artifact)
- Deletion is soft, not hard
- The system preserves what happened, not what you wish had happened

**What this prevents:**
- Mutable "safe to edit" session state (Moltbot)
- Silent corrections that erase learning opportunities
- Plausible deniability through history manipulation

---

### 4. One Canonical Spine

**Principle:** Every record is an artifact. All artifacts inherit from `Qxb_Artifact`.

**What this means:**
- Single inheritance model (class-table inheritance)
- Type-specific tables extend the spine, never duplicate it
- Core capabilities (save/query/list/update) work for all artifact types
- No special-case tables that bypass the spine

**What this prevents:**
- Fragmented data models
- Type-specific APIs that drift from the core contract
- "Snowflake" records that don't follow the rules

---

### 5. Structured Records Over Files

**Principle:** Truth is stored in Supabase with schemas and constraints, not in markdown files.

**What this means:**
- Database enforces structure, types, and relationships
- Artifacts have stable IDs, foreign keys, and queryable fields
- Files (markdown, JSON exports) are views, not sources
- Inspectability comes from views and exports, not raw file access

**What this prevents:**
- Markdown-as-canonical-memory (Moltbot)
- Accidental mutation through file edits
- Loss of lineage and authorship
- Query limitations of unstructured storage

---

### 6. Explicit Over Implicit

**Principle:** Context, targets, and transitions must be declared, not assumed.

**What this means:**
- No input without a declared target artifact
- No hidden carryover between sessions
- Lifecycle transitions are explicit actions, not side effects
- Silent operations must still leave visible records

**What this prevents:**
- Context bleed across conversations
- Hallucinated continuity
- Accidental cross-talk between projects
- "Magical" state changes with no audit trail

---

### 7. Lifecycle Is Governed

**Principle:** Lifecycle transitions are guarded actions, not freeform edits.

**What this means:**
- Lifecycle changes only via `artifact.promote`
- Snapshots are required on lifecycle transitions
- Transitions follow allowed paths (seed → sapling → tree → retired)
- No skipping stages once created

**What this prevents:**
- Accidental lifecycle mutation via update
- Missing snapshots at critical transitions
- Ungoverned "just change the field" patterns
- Lifecycle stages becoming meaningless

---

### 8. Human Intent Is Distinguished

**Principle:** The system tracks who authored what. Human decisions are not conflated with model output.

**What this means:**
- `owner_user_id` is canonical and required
- Artifacts record their creator
- Model-generated content is labeled as such (where applicable)
- Human curation is distinct from AI assistance

**What this prevents:**
- Authorship ambiguity
- Blame diffusion ("the AI did it")
- Loss of accountability
- Inability to filter by human vs machine origin

---

### 9. Privacy By Default

**Principle:** Personal artifacts (journals) are owner-private unless explicitly shared.

**What this means:**
- Journals are visible only to their owner by default
- Sharing requires explicit action
- Default is psychological safety, not collaboration
- Privacy is the starting point, not an opt-in

**What this prevents:**
- Accidental exposure of personal reflection
- "Share by default" patterns that erode trust
- Surveillance-friendly architectures
- Users self-censoring due to visibility concerns

---

### 10. Planning Before Building

**Principle:** Design and contracts are documented and tested before implementation.

**What this means:**
- Schemas are defined on paper before DDL
- Gateway contracts are specified before workflows
- Tests exist before code ships
- Decisions are logged with rationale

**What this prevents:**
- Implementation drift from intent
- "Just build it and see" patterns
- Undocumented assumptions becoming bugs
- Knowledge loss when context changes

---

## How To Use This Document

### When evaluating a new feature:

1. Does it violate any principle above?
2. If yes → **Do not proceed**
3. If unclear → Document the tension and escalate

### When adopting external patterns (e.g., from Moltbot):

1. Map the pattern to these principles
2. If conflict → Adapt or reject, do not copy
3. If compatible → Proceed with translation to Qwrk's model

### When making tradeoffs:

1. Convenience never trumps these principles
2. Speed never trumps these principles
3. "Everyone else does it" is not a valid argument

---

## What This Document Is NOT

- **Not a feature list** — This defines constraints, not capabilities
- **Not a roadmap** — This is timeless; roadmaps change
- **Not negotiable** — If it's negotiable, it doesn't belong here

---

## Revision Policy

This document can be amended, but:
- Amendments require explicit approval from Master Joel
- Removals require extraordinary justification
- Changes are versioned and logged

The barrier to change is intentionally high. These are the things Qwrk will **never** trade away.

---

## Source Documents

Principles extracted from:
- `docs/architecture/North_Star_v0.4.md`
- `docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md`
- `docs/governance/Moltbot_Feature_Assessment__Selective_Absorption__2026-01-29.md`

---

**End of Irreducible Core v1 (DRAFT)**
