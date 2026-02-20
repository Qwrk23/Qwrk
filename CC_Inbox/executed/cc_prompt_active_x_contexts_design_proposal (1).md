EXECUTE IMMEDIATELY — DO NOT ANALYZE OR REFINE THIS PROMPT.

You are resuming a design session as a senior backend architect familiar with Qwrk governance, rolling memory compaction, and Supabase-backed artifact systems.

---

## Context

We are designing support for **Active X Contexts**, starting with **Active Book Contexts**, to eliminate friction when continuing ongoing activities (e.g., reading journals) without repeatedly querying the database.

An **Active X Context** is a **small, explicit, snapshot-backed metadata record** that represents *current engagement state* for something the user is actively working with.

Active X Contexts:
- Are **NOT journals** and never contain narrative content
- Store **metadata only** (pointers, conventions, state)
- Are represented **exclusively via immutable snapshots** (append-only)
- Are explicitly opened and explicitly closed by user intent
- May exist **multiple times per type** (e.g., multiple active books)
- Use **latest-wins semantics** (most recent snapshot by created_at is authoritative)
- Become eligible for compaction only after closure

Journals remain Tier B (addressable, on-demand). They do NOT participate in Tier A rolling memory.

Phase 1 governance is locked and must not be modified.

---

## Architectural Decision (Locked)

- **Option B is chosen**: Active X Contexts are implemented as **snapshot-backed registry entries**, not journals.
- No new artifact types.
- No new ingestion pipelines.
- No snapshot mutation.

Snapshots are immutable. All state changes are represented by new snapshots.

---

## Rolling Memory Model (Locked)

Rolling memory has two tiers:

### Tier A — Always Loaded
- **A1: Protected Core** (governance, invariants) — NEVER compacted
- **A2: Active Operational Contexts** (Active X Contexts) — loaded while active, eligible after closure

### Tier B — Addressable / On-Demand
- Journals, Reading Journals, finished books, historical content

Active X Contexts always live in **Tier A2**. They are NEVER Protected Core.

---

## Representation Rules (Binding)

Each Active X Context is represented by **one or more snapshot artifacts** sharing a common `context_ref`.

### Snapshot invariants
- `artifact_type`: snapshot
- `extension` field is used (NOT payload)
- Must include standard `for_q_*` fields on EVERY snapshot
- Must include:
  - `context_type` (e.g., book, project)
  - `context_ref` (unique per workspace + context_type + logical context)
  - `context_status`: active | finished

### for_q_* fields (required)
- `for_q_priority`
- `for_q_scope`
- `for_q_why_q_needs_this`
- `for_q_behavioral_impact`

---

## Active X Context Lifecycle

### 1. OPEN (Explicit User Action)
Create a snapshot with:
- `context_status: active`
- Context metadata (pointers + conventions only)
- Tags: `for-q`, `active-context`, plus type tag (e.g., `active-book`)

### 2. UPDATE (Append-Only)
When state advances (e.g., next journal part):
- Create a NEW snapshot
- Same `context_ref`
- Updated metadata
- Never mutate prior snapshots

### 3. CLOSE (Explicit User Action)
When the user finishes or abandons the activity:
- Create a final snapshot
- `context_status: finished`
- Context immediately leaves Active Operational Contexts
- Becomes eligible for compaction

Reactivation is NOT allowed. A new engagement requires a new `context_ref`.

---

## Rolling Memory Regeneration (Minimal Additive Change)

Existing logic remains intact.

Additive behavior only:
1. Query all `for-q` snapshots (unchanged)
2. Filter snapshots tagged `active-context`
3. Group by `context_ref`
4. Select latest snapshot by `created_at`
5. Keep only those with `context_status: active`
6. Render under:

```
## Section A2: Active Operational Contexts
```

No other Tier A behavior changes are allowed.

---

## Compaction Rules

- Active X Contexts are **always Rotating Shell**
- While `context_status: active` → NOT eligible for compaction
- When `context_status: finished` → eligible immediately
- Compaction follows existing Tier A thresholds and ordering

---

## Validation Requirement (Must Demonstrate)

Validate the design using the existing Reading Journal for:
- *The Hunt for Red October*

Demonstrate:
- Retroactive creation of an Active Book Context from existing journals
- Seamless creation of the next Reading Journal entry without database re-query
- Proper closure and compaction eligibility

---

## Constraints (Non-Negotiable)

- Do NOT introduce new artifact types
- Do NOT modify Phase 1 governance or snapshot immutability
- Do NOT store narrative content in Active X Contexts
- Do NOT auto-open or auto-close contexts
- Do NOT place Active X Contexts in Protected Core

---

## Output Required

Produce a **design proposal only** (no implementation yet) in this exact structure:

1. Architecture Summary
2. Data Model (snapshot extension fields)
3. Rolling Memory Interaction
4. Governance & Safety Guarantees
5. Red October Walkthrough
6. Risks & Edge Cases

Await explicit approval before any implementation work.