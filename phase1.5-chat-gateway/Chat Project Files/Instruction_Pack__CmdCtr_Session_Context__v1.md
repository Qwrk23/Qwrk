# Instruction Pack — CmdCtr Session Context (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-07
**origin:** CmdCtr operational observability layer — session context briefing for Qwrk Prime

---

## A. What CmdCtr Is

CmdCtr is Qwrk's operational observability layer. It continuously crawls the artifact forest to derive execution state, detect anomalies, and produce planning-ready summaries. At session start, Q may receive a **session context briefing** — a single distilled JSONB document representing current system health, active work surface, changes since the last session, and an operator note. CmdCtr is read-only. It does not mutate artifacts, execute workflows, or replace direct artifact queries.

---

## B. When CmdCtr Appears

**Current mode:** Manual. Joel or CC runs the session context builder and shares the briefing as a snapshot or pasted JSON at session start.

**Future mode (T100):** A downstream automation will build, save, render, and surface the briefing automatically at session start. T100 is the thread tracking this downstream flow.

**If absent:** Q proceeds with normal Qwrk planning behavior. CmdCtr is additive — its absence changes nothing about existing session protocol.

---

## C. Session Context Briefing Structure

The briefing is a versioned JSONB object. Current version: `1`.

Top-level fields:

| Field | Type | Purpose |
|-------|------|---------|
| `version` | integer | Contract version (currently `1`) |
| `crawl_ts` | timestamptz | When the underlying crawl data was generated |
| `crawl_duration_ms` | integer or null | Crawl execution time (null until persisted by future crawl engine update) |
| `prior_session_ts` | timestamptz or null | Timestamp of the prior session briefing used for delta computation |

### C.1 — `health`

System-level health snapshot. Read this first to gauge overall state.

| Field | Type | Meaning |
|-------|------|---------|
| `forest_rows` | integer | Total artifacts in the forest |
| `execution_rows` | integer | Total artifacts with derived execution state |
| `signal_total` | integer | Total active signals across all types |
| `signals_by_type` | object | Signal counts keyed by signal type (see Section D) |
| `has_cycles` | boolean | Any dependency cycles detected |
| `has_blockers` | boolean | Any dependency-blocked artifacts |
| `has_stalls` | boolean | Any execution-stalled artifacts |

**How Q should use it:** Scan the booleans first. If all three are `false`, the forest is structurally clean — say so and proceed. If any are `true`, surface them before proposing new work.

### C.2 — `active_surface`

The work that matters right now. This is the primary planning surface.

| Field | Type | Meaning |
|-------|------|---------|
| `in_progress` | array | Up to 20 items currently being executed (excludes stalled). Each: `artifact_id`, `title`, `artifact_type`, `depth` |
| `blocked` | array | Up to 20 items blocked by unmet dependencies. Each: `artifact_id`, `title`, `artifact_type`, `blocked_by` |
| `stalled` | array | Up to 10 items in-progress but with all children complete (needs parent-level action). Each: `artifact_id`, `title`, `artifact_type`, `complete_children`, `total_children` |
| `cycles` | array | Up to 20 artifacts involved in dependency cycles. Each: `artifact_id`, `title`, `artifact_type` |
| `ready_summary` | object | Aggregate counts for ready-state artifacts (see below) |

**`ready_summary` fields:**

| Field | Type | Meaning |
|-------|------|---------|
| `total` | integer | Total artifacts in ready state |
| `by_type` | object | Ready counts keyed by artifact_type |
| `execution_anatomy_ready` | integer | Ready count for execution-layer types only (project, branch, leaf, limb, twig) |

**`execution_anatomy_ready`** is a derived planning metric, not a signal type. It filters the ready surface to actionable execution-layer artifacts, excluding journals, snapshots, restarts, and other non-execution types. Use it to distinguish real execution candidates from general ready-state noise.

**How Q should use it:**
- Surface `in_progress` items first — these are the current work surface.
- Flag `blocked` and `cycles` immediately — these need operator attention.
- Surface `stalled` items as needing parent-level resolution.
- Use `execution_anatomy_ready` count to gauge actionable backlog depth.
- Do NOT enumerate individual ready items. Summarize counts. The ready surface can be large.

### C.3 — `delta`

Changes since the last session briefing. Requires a prior session-context snapshot tagged `cmdctr + session-context + for-q`.

| Field | Type | Meaning |
|-------|------|---------|
| `new_blockers` | array | Artifacts now blocked that were not in prior briefing (max 20) |
| `cleared_blockers` | array | Artifacts no longer blocked (max 20) |
| `newly_in_progress` | array | Artifacts now in-progress that were not in prior briefing (max 20) |
| `newly_completed` | array | Artifacts that were in-progress in prior and are now complete (max 20) |
| `new_signals` | object | Signal types with increased counts (positive deltas) |
| `cleared_signals` | object | Signal types with decreased counts (absolute reduction) |
| `forest_row_change` | integer | Net change in forest size |
| `summary` | string | Plain-language delta summary |

**Special cases:**
- First briefing (no prior): `summary` = `"First session briefing. No prior context for delta comparison."`
- Version mismatch: `summary` = `"Prior briefing version mismatch — delta unavailable."`
- All delta arrays will be empty in both cases.

**How Q should use it:** Lead with `summary` for quick orientation. Then surface `new_blockers` and `newly_completed` as the most decision-relevant deltas. `cleared_blockers` is good news — mention it. `newly_in_progress` shows momentum.

### C.4 — `operator_note`

A plain-language status line generated from the briefing data. Covers: cycles, blockers, stalls, in-progress count, execution-anatomy ready count.

**How Q should use it:** Treat as a pre-built summary. Q may paraphrase or extend it but should not contradict it.

### C.5 — `operator_priorities` (Proposed — Additive)

**Status:** Not yet implemented. This section describes a future additive enhancement to the session context model.

When present, `operator_priorities` provides an explicit planning surface:

```json
{
  "operator_priorities": {
    "focus_in_progress": [],
    "attention_required": [],
    "recommended_next_execution": []
  }
}
```

| Field | Meaning |
|-------|---------|
| `focus_in_progress` | The primary active work surface — what should be continued or reviewed first |
| `attention_required` | Blockers, stalls, anomalies, or issues needing operator decision |
| `recommended_next_execution` | Good next-execution candidates derived from ready state |

**How Q should use it when present:** Treat as the authoritative planning cue list. `focus_in_progress` first, `attention_required` second, `recommended_next_execution` third.

**Graceful degradation when absent:** If `operator_priorities` is absent but a CmdCtr briefing is present, Q should derive planning cues from:
1. `active_surface.in_progress` — current work
2. `active_surface.blocked` — immediate attention
3. `active_surface.stalled` — needs resolution
4. `delta` — what changed
5. `operator_note` — summary orientation

If the full CmdCtr briefing is absent, Q falls back to normal Qwrk planning behavior.

---

## D. Signal Glossary

CmdCtr v1 produces five canonical signal types. These appear in `health.signals_by_type` as counts and drive `active_surface` arrays.

### `ready_to_execute`

**Meaning:** Artifact has no unmet dependencies and is not in-progress or complete. Eligible for execution.
**Priority:** Informational. Large counts are normal — most artifacts without dependencies derive as ready.
**Q response:** Do not enumerate. Use `execution_anatomy_ready` to gauge actionable backlog. Mention count if relevant to planning.

### `dependency_blocked`

**Meaning:** Artifact has at least one unmet dependency preventing execution.
**Priority:** Cautionary. Blocked work may indicate a stuck pipeline.
**Q response:** Surface blocked items from `active_surface.blocked`. Identify what they depend on. Flag for Joel if resolution path is unclear.

### `dependency_cycle`

**Meaning:** Artifact is part of a circular dependency chain. Cannot be resolved by normal execution ordering.
**Priority:** High. Cycles are structural anomalies requiring operator intervention.
**Q response:** Surface immediately. Show cycle participants from `active_surface.cycles`. Recommend operator review to break the cycle.

### `execution_stalled`

**Meaning:** Artifact is in-progress but all its children are complete. The parent may need closure, promotion, or re-evaluation.
**Priority:** Cautionary. Stalls indicate work that may be done but not recognized as done.
**Q response:** Surface stalled items from `active_surface.stalled`. Ask whether the parent should be completed, promoted, or has remaining undeclared work.

### `orphan_execution`

**Meaning:** Artifact is in-progress but has no parent artifact. May be intentional (top-level initiative) or accidental (lost context).
**Priority:** Informational. Common for top-level projects. Only notable if unexpected.
**Q response:** Mention count if non-trivial. Do not alarm unless the artifact appears misplaced.

---

## E. Decision Guidance for Q

When a CmdCtr briefing is present at session start, use the following decision framework:

### In-progress work exists
Surface it first. Name the items. Before proposing new work, ask whether current in-progress items should continue, be reviewed, or be deprioritized. Do not bury active work under new proposals.

### Blockers exist
Flag them clearly and immediately after acknowledging in-progress work. Identify what each blocked item depends on. If the blocker is another artifact, name it. If the resolution path is unclear, ask Joel.

### Cycles exist
Escalate. Cycles are structural — they cannot self-resolve. Name the participants. Recommend breaking the cycle. This takes precedence over new execution proposals.

### Stalled work exists
Surface after blockers. Stalled items are in-progress with all children complete — they likely need parent-level action (completion, promotion, or scope expansion). Ask Joel which outcome is correct.

### Large ready surface
Do not enumerate. Use `execution_anatomy_ready` to distinguish actionable items from noise. State the count. If Joel asks for recommendations, pull from execution-anatomy types first (project, branch, leaf, limb, twig).

### Structurally clean forest
If `has_cycles`, `has_blockers`, and `has_stalls` are all `false`: say so clearly. Example: "Forest is structurally clean — no blockers, cycles, or stalls." Then proceed to in-progress work or await direction.

### General principle
Prefer operational clarity over dumping counts. One clear sentence about state is better than a table of numbers. Lead with what matters, summarize what does not.

---

## F. Precedence Rule

**When a CmdCtr session context briefing is present at session start, Q should treat it as the primary operational frame for current system state and session planning.**

It is the first-read view of system state, not the last word.

Boundaries:
- CmdCtr guides operational planning. It does not override system invariants, governance rules, or Joel's judgment.
- CmdCtr does not replace artifact retrieval when deeper detail is needed. Query specific artifacts when the briefing raises questions that require full context.
- CmdCtr is a summary and control surface. If Q needs to verify a specific artifact's state, payload, or history — query it directly.

---

## G. Operator Priorities

### What it is
`operator_priorities` is a proposed additive section for the session context briefing that provides explicit, ranked planning cues derived from system state. It separates the "what to look at" question from the raw data.

### Why it helps Q
The existing four sections (health, active_surface, delta, operator_note) provide comprehensive data. But Q still needs to synthesize planning priorities from that data. `operator_priorities` pre-computes the synthesis:
- What is the primary active work surface?
- What needs immediate attention?
- What are good next candidates for execution?

### How Q should use it when present
1. Start with `focus_in_progress` — acknowledge and confirm current work direction.
2. Surface `attention_required` — flag blockers, stalls, or anomalies for Joel.
3. Offer `recommended_next_execution` only if Joel asks or if no in-progress work exists.

### How Q should fall back when absent
Derive the same three planning layers manually:
1. **Focus:** `active_surface.in_progress`
2. **Attention:** `active_surface.blocked` + `active_surface.stalled` + `active_surface.cycles`
3. **Next candidates:** `active_surface.ready_summary.execution_anatomy_ready` (count only)

This degradation is lossless — all data is available in the base briefing. `operator_priorities` is a convenience, not a dependency.

---

## H. Limits and Non-Goals

CmdCtr does NOT:
- Mutate artifacts, trigger workflows, or execute Gateway actions
- Provide full artifact hydration (titles are included, payloads are not)
- Replace Gateway queries or direct artifact retrieval
- Override governance rules, behavioral controls, or system invariants
- Serve as the sole source of truth for any specific artifact's state

CmdCtr DOES:
- Provide a distilled operational picture at session start
- Surface anomalies (cycles, blockers, stalls) that might otherwise go unnoticed
- Track changes between sessions (delta computation)
- Help Q prioritize planning based on current system reality

When CmdCtr says an artifact is blocked, and Q needs to know why or what it depends on — query the artifact. CmdCtr tells Q where to look, not everything there is to know.

---

*CHANGELOG: v1 (2026-03-07): Initial version. Covers CmdCtr session context briefing format (version 1), five canonical signal types, decision guidance, precedence rule, operator_priorities conceptual design (additive, not yet implemented), graceful degradation rules.*
