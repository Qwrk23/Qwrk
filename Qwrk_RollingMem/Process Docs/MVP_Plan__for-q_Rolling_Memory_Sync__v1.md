# MVP Plan: for-q Rolling Memory Sync

**Version:** 1.0
**Date:** 2026-02-04
**Status:** DRAFT — Awaiting Approval
**Phase:** Crawl

---

## 1. Purpose

Prevent Qwrk from forgetting behavioral truth by maintaining a human-curated rolling markdown file derived from `for-q` tagged artifacts in Supabase.

**Guiding Principle:** Remember what matters, not everything.

---

## 2. End-to-End MVP Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     HUMAN-TRIGGERED PROCESS                      │
└─────────────────────────────────────────────────────────────────┘

Step 1: TRIGGER (Human)
    └─→ User decides to refresh Q's memory
    └─→ Runs query script (PowerShell or SQL)

Step 2: DISCOVER (Query)
    └─→ Query Supabase: SELECT * FROM qxb_artifact WHERE 'for-q' = ANY(tags)
    └─→ Order by created_at DESC
    └─→ Return full artifact payloads

Step 3: EXTRACT (Transform)
    └─→ For each artifact, extract Universal Contract fields
    └─→ Deterministic: same input → same output
    └─→ No summarization outside contract

Step 4: ASSEMBLE (Generate)
    └─→ Build rolling markdown file with 3 sections
    └─→ Active window: most recent N artifacts (default: 10)
    └─→ Registry: older artifacts (ID + title + one-liner)

Step 5: REVIEW (Human)
    └─→ Human reviews generated markdown
    └─→ Confirms accuracy, adjusts if needed
    └─→ No blind upload

Step 6: UPSERT (Human)
    └─→ Human manually uploads to Qwrk project files
    └─→ Replaces previous version
    └─→ Q reads on next session start
```

---

## 3. Universal Extraction Contract

Every `for-q` artifact is transformed into this fixed structure:

| Field | Type | Description |
|-------|------|-------------|
| `artifact_id` | uuid | Unique identifier (for traceability) |
| `artifact_type` | string | Always `snapshot` in MVP |
| `title` | string | Human-readable name |
| `created_at` | timestamp | When artifact was created |
| `why_q_needs_this` | string | One sentence: why Q must know this |
| `behavioral_impact` | string | What Q must do or must not do |
| `scope` | string | Where/when this applies (global, specific workflow, etc.) |
| `sunset` | string or null | Expiry condition, if any ("until Phase 3", "permanent", etc.) |

### Extraction Rules

1. **`why_q_needs_this`** — **MUST be explicitly present in the snapshot payload.** If missing, extraction **FAILS** and requires human correction before proceeding. No inference from title, tags, or surrounding context is permitted.

2. **`behavioral_impact`** — Must be actionable. Format: "Q MUST..." or "Q MUST NOT..." or "Q SHOULD..." Must be explicitly stated in payload.

3. **`scope`** — One of:
   - `global` — applies everywhere
   - `gateway` — applies to Gateway operations only
   - `session` — applies to session management only
   - `[specific]` — named scope (e.g., "artifact.save workflow")

4. **`sunset`** — If not specified in artifact, default to `null` (permanent until explicitly revoked).

### Hard Rule: No Inference

`for-q` is an explicit opt-in signal. The extraction process:
- **MUST NOT** infer missing fields from title, context, or related artifacts
- **MUST NOT** summarize or interpret beyond what is explicitly stated
- **MUST FAIL** loudly if required fields are missing, prompting human correction

---

## 4. Rolling Markdown File Structure

Filename: `Qwrk_Rolling_Memory__for-q__YYYY-MM-DD.md`

```markdown
# Qwrk Rolling Memory — for-q Sync

**Generated:** YYYY-MM-DD HH:MM UTC
**Source:** Supabase qxb_artifact (tags contains 'for-q')
**Active Window:** 10 most recent
**Total for-q Artifacts:** N

---

## Section A: Authoritative Operating State (READ FIRST)

**Token Budget:** Target 500–1,000 tokens | Hard ceiling 1,500 tokens

These are the active constraints and invariants you MUST honor.
Do not contradict these under any circumstances.

### Active Constraints

1. **[Title from most critical artifact]**
   - Impact: [behavioral_impact]
   - Scope: [scope]

2. **[Next critical]**
   - Impact: ...
   - Scope: ...

[Max 5 items in this section — curator picks the most critical. Section A must remain ruthlessly small to protect context quality.]

---

## Section B: Active for-q Entries (Expanded)

These artifacts are in your active memory window.

### Entry 1: [Title]

| Field | Value |
|-------|-------|
| Artifact ID | `uuid` |
| Type | snapshot |
| Created | YYYY-MM-DD |
| Why Q Needs This | [why_q_needs_this] |
| Behavioral Impact | [behavioral_impact] |
| Scope | [scope] |
| Sunset | [sunset or "Permanent"] |

---

### Entry 2: [Title]

[Same structure...]

---

[Repeat for all active window entries, max 10]

---

## Section C: Registry (Index Only)

Older for-q artifacts. Not loaded as active context.
Query Supabase by artifact_id if needed.

| # | Artifact ID | Title | Created | One-Liner |
|---|-------------|-------|---------|-----------|
| 1 | `uuid` | [title] | YYYY-MM-DD | [single sentence summary] |
| 2 | `uuid` | [title] | YYYY-MM-DD | [single sentence summary] |
| ... | ... | ... | ... | ... |

---

## Metadata

- **Process Version:** MVP v1 (Crawl)
- **Next Refresh:** Human-triggered
- **Authoritative Source:** Supabase (this file is derived)
```

---

## 5. Rolling Window and Registry Rules

### Active Window (Section B)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Default size | 10 | Conservative start, expandable |
| Max size | 20 | Beyond this, context competition risk |
| Selection | Most recent by `created_at` | Deterministic, no curation bias |
| Override | Human can pin/unpin | Critical items stay active regardless of age |

### Registry (Section C)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Retention | All `for-q` artifacts ever | No deletion, full traceability |
| Display | ID + title + one-liner | Minimal footprint, queryable |
| Retrieval | On-demand via Gateway query | Not loaded into context automatically |

### Promotion/Demotion Rules

1. New `for-q` artifact → enters Active Window at position 1
2. Oldest Active Window item → moves to Registry
3. Human can **pin** an item to stay in Active Window permanently
4. Human can **archive** an item (remove `for-q` tag) to remove from both sections

---

## 6. Failure Modes and Guardrails

### Failure Mode 1: Markdown file lost or corrupted

**Impact:** Q loses behavioral context
**Mitigation:** Supabase remains source of truth. Re-run process to regenerate.
**Guardrail:** Never delete `for-q` artifacts. File is derived, not authoritative.

### Failure Mode 2: Stale file uploaded (old version)

**Impact:** Q operates on outdated constraints
**Mitigation:** File includes `Generated:` timestamp. Q should note staleness.
**Guardrail:** Human must review before upload. Consider adding "stale if older than N days" warning.

### Failure Mode 3: Over-tagging (too many `for-q` artifacts)

**Impact:** Active window bloated, context competition
**Mitigation:** Discipline: only tag what Q MUST know to avoid incorrect behavior
**Guardrail:** Rolling window caps at 20. Registry absorbs overflow.

### Failure Mode 4: Under-tagging (critical artifact not tagged)

**Impact:** Q forgets something important
**Mitigation:** Periodic human audit of recent snapshots
**Guardrail:** Q may surface the existence of new `for-q` snapshots **only when the user explicitly initiates a new session, governance review, or related mode**. No autonomous prompting.

### Failure Mode 5: Extraction drift (contract fields interpreted inconsistently)

**Impact:** Entries vary in quality/format
**Mitigation:** Contract is fixed and documented. Extractor (human or script) follows spec.
**Guardrail:** Validate each entry against contract before assembly.

### Failure Mode 6: Human uploads without review

**Impact:** Errors propagate to Q
**Mitigation:** Process explicitly includes REVIEW step
**Guardrail:** Consider adding checksum or "Reviewed by: [name]" field

---

## 7. Walk Phase Preview (Future)

When this works reliably, "walk" introduces:

| Category | Load Timing | Content |
|----------|-------------|---------|
| **A — Startup** | Session init | Section A only (~3-5k tokens) |
| **B — Triggered** | On-demand query | Section B + C via Gateway |

This means:
- Q starts light (only critical constraints)
- Q queries for context when needed
- Supabase becomes live memory, not just archive

---

## 8. Implementation Checklist (For Approval)

Before implementation, confirm:

- [ ] Rolling window size confirmed (recommend: 10)
- [ ] Output folder confirmed: `Qwrk_RollingMem/`
- [ ] First `for-q` artifacts identified for tagging
- [ ] Query script approach decided (PowerShell via Gateway or direct SQL)
- [ ] Human reviewer identified (Joel or delegate)

---

## Confirm Understanding and Propose the Plan

**Summary:**

1. Query Supabase for `for-q` tagged artifacts
2. Extract using fixed Universal Contract (8 fields)
3. Assemble into 3-section rolling markdown file
4. Human reviews and uploads to Qwrk project files
5. Q reads at session start

**Key Decisions Locked:**
- Snapshots only (MVP)
- 10-item active window (conservative)
- Manual trigger, human review required
- Markdown is derived, Supabase is truth

**Ready to proceed with implementation when approved.**

---

## CHANGELOG

### v1.1 — 2026-02-04
- **APPROVED** with tightening changes
- Extraction: No inference permitted. `why_q_needs_this` must be explicit in payload or extraction fails.
- Session prompting: No autonomous ask. Q surfaces new `for-q` only on explicit user-initiated session/governance mode.
- Section A: Token budget locked (target 500-1,000, ceiling 1,500)

### v1 — 2026-02-04
- Initial draft
- Locked: Universal Contract, file structure, rolling window rules
- Pending: User approval, first `for-q` artifacts to tag
