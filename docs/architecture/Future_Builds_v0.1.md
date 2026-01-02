# AAA_New_Qwrk__Future_Builds__v0.1

---

## Purpose

Capture intentionally deferred features and artifact types that are aligned with the Qwrk vision but explicitly out of scope for the current build phase. This document preserves ideas without polluting the North Star or active implementation plans.

---

## Status Legend

- 🟡 **Conceptual** — idea acknowledged, not designed
- 🔵 **Paper-designed** — schema/behavior sketched, not built
- 🟢 **Ready for build** — gated, approved, waiting for scheduling

---

## Future Build #1 — Historical Records (🟡 Conceptual)

### Concept

A first-class artifact representing a **timeboxed summary of work completed** during a defined window (build session, day, or week). The record acts as a curated digest of activity across projects, snapshots, restarts, and journals.

### Motivation

- Preserve a human-curated record of what was built during a period
- Support retrospectives, reflection, and progress reporting
- Avoid reconstructing meaningful history from low-level event logs later

### Why This Is Not Kernel v1

- Cross-artifact aggregation adds scope and complexity
- Requires mature linking and/or audit-event infrastructure
- Kernel v1 priority is save/query reliability and lifecycle governance

### Intended Long-Term Shape (Non-Binding)

- New artifact type: `history` (or `historical_period`)
- Structured time window: `window_start_at` / `window_end_at`
- Window kind: `session | day | week` (or free-text initially)
- Links to included artifacts (projects, snapshots, restarts, journals)
- Narrative summary capturing outcomes, decisions, and notable progress

### Explicit Decisions Locked

- This will **NOT** be modeled as a journal subtype long-term
- This will be a **distinct artifact type** when implemented
- No bridge implementation will be used in Kernel v1

### Promotion Criteria

- Kernel v1 is live and stable
- Gateway contract has proven reliability
- Artifact linking or audit-event capability exists or is planned
- Explicit decision is made to schedule Expansion work

---

## Seed ↔ Flower Similarity Assist (Future Enhancement)

🟢 **Ready for build**

**"Build Flowers as part of Gateway V2 + Structure Layer (Phase 2), immediately after Kernel v1 + KGB passes."**

### Problem

Ideas may initially be captured as **Seed Projects** but later recognized as better expressed as **Flowers (to-do items)**. We intentionally avoid modifying Kernel lifecycle semantics to support seed → flower transitions directly.

### Proposed Pattern (Non-Kernel, Assist-Level)

When creating a new Flower, Qwrk may optionally detect whether a **similar Seed Project** already exists and offer a helpful, non-binding suggestion.

### Behavior

- User creates a new Flower under a Thicket
- Qwrk checks for similar Seed Projects within the same Thicket (or optionally Forest)
- If a likely match is found, Qwrk presents an assist prompt:

  > "A similar seed project exists: <Seed Title>.
  > Would you like to retire that seed now that this Flower has been created?"

### User Choices

- **Retire Seed** — seed project is retired explicitly by user confirmation
- **Leave Seed Active** — no action taken
- **Open Seed** — user reviews the seed project before deciding

### Constraints / Invariants

- No automatic retirement of seeds
- No lifecycle or Kernel semantics changes
- No implicit linkage between seed and flower required
- This is a *suggestion-only* feature (assist layer)

### Initial Similarity Heuristics (v1)

- Same Thicket
- High title overlap
- Tag overlap (if present)

Future versions may use embeddings or semantic similarity once infrastructure supports it.

### Rationale

This preserves:

- Kernel stability
- Clear lifecycle meaning
- User agency
- A clean upgrade path to smarter behavior later

This feature belongs to **Future Builds / Assist Features**, not the Kernel or Structure Layer.

---

**End of Future Builds v0.1**
