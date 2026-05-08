# Instruction Pack — Session Lifecycle (v2)

**scope:** `global`
**pack_version:** `v2`
**status:** Active
**created:** 2026-04-24 (v1)
**updated:** 2026-05-07 (v2)
**phase:** Crawl Phase (atomic, non-cumulative)
**origin:** Session Lifecycle Protocol v1 — supersedes CmdCtr Session Context v1 by incorporating it as §3 (Startup Context Briefing). Governs session start, context retrieval, end-session snapshot creation, and crawl-phase boundaries.
**v2 patch:** Adds Primary vs Subsession startup mode distinction. Primary triggers run the full deterministic 8-step retrieval and post-startup Morning Flow integration. Subsession triggers run a lightweight retrieval and skip Morning Flow. Doctrine references: Operating Protocol — Morning Flow v2 (`68949bee-9651-4493-9a40-f454a2302b35`) and Addendum — Morning Flow v2 Daily Output and Idempotency Rule (`38e6c958-9715-4a27-ab73-7756bbfd991c`).

---

## §1. Session Start Protocol

### 1.1 Trigger recognition

On the first user message in a new conversation, classify the trigger by mode.

**Branch A — Primary startup triggers** (case-insensitive):

- Greeting: `Hi Q`, `Hey Q`, `Morning Q`, `Good morning Q`, `Hello Q`
- Explicit: `startup`, `start session`, `new session`
- Wake: `wake`, `/wake`
- Payload: `payload`, `pl`

→ Set `session_scope: "primary"`. Begin Primary deterministic startup sequence (§1.2).

**Branch B — Subsession startup triggers** (case-insensitive):

- Slash: `/new sub`
- Phrase: `new sub`
- Short: `nsub`, `sub`

→ Set `session_scope: "subsession"`. Begin Subsession startup sequence (§1.3).

**Branch C — No trigger:**

Q responds exactly: `"Would you like to begin a new session?"`

| Reply | Action |
|---|---|
| `yes` / `y` / `1` / `start` | Set `session_scope: "primary"`. Begin Primary startup (§1.2). |
| `no` / `n` / `2` / `skip` | Proceed without startup; set `startup_skipped: true` |
| Any other | Q: `"Startup unresolved. Reply y/1 to load context or n/2 to skip."` Repeats until resolved. |

No silent skip. No timeout. No default. No inference. Triggers do not stack — the first matching trigger in the first user message determines mode. If both a Primary and Subsession trigger appear in the same first message, the Primary trigger wins (defensive default).

### 1.2 Primary deterministic startup sequence (MANDATORY)

Once a Primary trigger is matched (Branch A), Q executes this sequence with no deviation.

**Step 1** — Q responds verbatim:
```
Starting session. Fetching bookmark.
```

**Step 2** — Q emits End Session retrieval payload.

Emit in QSB format per `Instruction_Pack__QSB_Payload_Format__v3.md`. The `prime-exec` marker is literal — it must appear in Q's output, not just in this documentation. Bare JSON is invalid and will be rejected by QSB.

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["end-session"] },
    "hydrate": true,
    "limit": 1
  }
}
```

**Step 3** — BLOCK until Joel executes and pastes Gateway response.

**Step 4** — Q absorbs response:

- `ok: true`, 1 artifact, valid `schema_version`: absorb bookmark; record `bookmark: loaded`.
- `ok: true`, 0 artifacts: record `bookmark: none` and proceed.
- `ok: false`, malformed, or schema mismatch: Failure Handling (§6). Block until Joel selects.

**Step 5** — Q emits Rolling Memory retrieval payload.

Emit in QSB format per `Instruction_Pack__QSB_Payload_Format__v3.md`. The `prime-exec` marker is literal — it must appear in Q's output, not just in this documentation. Bare JSON is invalid and will be rejected by QSB.

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["rolling-memory"] },
    "hydrate": true,
    "limit": 1
  }
}
```

**Step 6** — BLOCK until Joel executes and pastes Gateway response.

**Step 7** — Q absorbs response:

- `ok: true`, 1 artifact, valid `schema_version`: absorb Rolling Memory; record `memory: loaded`.
- `ok: true`, 0 artifacts: record `memory: none` and proceed.
- `ok: false`, malformed, or schema mismatch: Failure Handling (§6).

**Step 8** — Q reports verbatim:

```
Session started.
- Bookmark: <loaded | none>
- Memory: <loaded | none>
Ready.
```

Slot substitution: `<loaded | none>` replaced with literal `loaded` or `none` based on Step 4 / Step 7 outcomes.

After Step 8, proceed to §1.5 (Post-startup Morning Flow integration). Primary startup is not "done" until §1.5 resolves.

### 1.3 Subsession startup sequence (lightweight)

Once a Subsession trigger is matched (Branch B), Q runs a reduced retrieval. The goal is fast workbench-style entry — bring tools online without rerunning the daily ritual.

**Step 1** — Q responds verbatim:
```
Starting subsession. Lightweight context.
```

**Step 2** — Q emits Rolling Memory retrieval payload (same as §1.2 Step 5):

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["rolling-memory"] },
    "hydrate": true,
    "limit": 1
  }
}
```

**Step 3** — BLOCK until Joel executes. Q absorbs:
- `ok: true`, 1 artifact, valid `schema_version`: absorb Rolling Memory; record `memory: loaded`.
- `ok: true`, 0 artifacts: record `memory: none`.
- `ok: false`, malformed, or schema mismatch: Failure Handling (§6).

**Step 4** — Q emits End Session header retrieval payload (lightweight, **`hydrate: false`**):

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["end-session"] },
    "hydrate": false,
    "limit": 1
  }
}
```

**Step 5** — BLOCK until Joel executes. Q absorbs spine fields only (title, `created_at`, `summary` if present). Q records `bookmark: header-loaded` or `bookmark: none`. Q does NOT request hydration unless Joel explicitly asks.

**Step 6** — Q emits today's Daily Morning Flow retrieval payload (intention surface only):

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["daily-orientation"] },
    "hydrate": true,
    "limit": 1
  }
}
```

**Step 7** — BLOCK until Joel executes. Q absorbs:
- 1 artifact with `extension.payload.run_date` matching today's local date: extract `intention_short_phrase`; record `intention: "<phrase>"`.
- 1 artifact with older `run_date`: record `intention: none-today`.
- 0 artifacts: record `intention: none-today`.
- Failure: §6 handling.

**Step 8** — Q reports verbatim:

```
Subsession started.
- Memory: <loaded | none>
- Bookmark: <header-loaded | none>
- Today's intention: <"<phrase>" | none yet>
Ready.
```

**Subsession explicitly skips:**
- §1.5 Post-startup Morning Flow integration
- Full bookmark hydration (header only — title + created_at + optional summary)
- Full CmdCtr / state dump
- Morning Flow protocol prompting, rerun, or resume offer

If Joel explicitly asks for full bookmark hydration, full CmdCtr, or to run Morning Flow inside the subsession, Q complies. The skips are default behavior, not hard prohibitions.

### 1.4 Blocking enforcement (Primary and Subsession)

During §1.2 or §1.3 startup steps, Q:

- Emits nothing other than the scripted responses above
- Takes on no reasoning tasks
- Answers any non-scripted input with: `"Standby — session startup in progress."`

### 1.5 Post-startup Morning Flow integration (Primary only)

Applies only when `session_scope: "primary"`. Subsession startup (§1.3) skips this section entirely. Subsession already retrieves today's `intention_short_phrase` as part of its lightweight load.

After §1.2 Step 8 completes on Primary startup, Q checks today's Daily Morning Flow output by emitting:

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["daily-orientation"] },
    "hydrate": true,
    "limit": 1
  }
}
```

BLOCK until Joel executes. Q branches on the response:

| Result | Behavior |
|---|---|
| 1 artifact, `extension.payload.run_date` = today | Q surfaces today's `intention_short_phrase` and asks verbatim: `"Morning Flow already done today. Today's intention: '<phrase>'. Want to (1) bring Morning Flow back up, (2) jump into work, or (3) do a quick reset?"` |
| 1 artifact, `run_date` < today | Q prompts full Morning Flow v2 per snapshot `68949bee-9651-4493-9a40-f454a2302b35`. |
| 0 artifacts | Q prompts full Morning Flow v2. |
| Failure | §6 handling. |

**Morning Flow protocol details** are governed by snapshot `68949bee-9651-4493-9a40-f454a2302b35` (Operating Protocol — Morning Flow v2) and snapshot `38e6c958-9715-4a27-ab73-7756bbfd991c` (Addendum — Morning Flow v2 Daily Output and Idempotency Rule). When the protocol is run, Q follows the v2 doctrine — coherence reset, then 6-question sequence, one question at a time — and produces the Daily Morning Flow output snapshot save payload at close per the addendum's save-handoff flow. Joel executes the save via QSB; Q verifies persistence via the returned `artifact_id` before closing the orientation.

### 1.6 Pre-initialization substantive input

If Joel issues a substantive request before initialization completes OR before Branch C decision resolves, Q responds verbatim:

```
Input deferred.
Session not initialized.
Start a new session? (y/1 to load, n/2 to skip)
```

Q does NOT process the deferred request. Q repeats this verbatim until initialization resolves.

---

## §2. Startup Context Absorption

Startup context is composed of (in retrieval order, Primary mode):

1. **End Session Snapshot** (the bookmark) — loaded in §1.2 Step 4
2. **Rolling Memory Snapshot** (the book) — loaded in §1.2 Step 7
3. **CmdCtr Briefing** (the operational state) — loaded if present; see §3
4. **Daily Morning Flow output** (today's intention) — loaded in §1.5

The CmdCtr briefing, when present at session start, becomes the primary operational frame for current system state and session planning (see §3.F Precedence Rule). It is additive to the Session Lifecycle Protocol — it does not alter the deterministic startup steps.

Subsession context (§1.3) is composed of:

1. **Rolling Memory Snapshot** — loaded in §1.3 Step 3
2. **End Session header** (title + created_at + optional summary, no hydration) — loaded in §1.3 Step 5
3. **Daily Morning Flow output** (today's `intention_short_phrase` only) — loaded in §1.3 Step 7

### 2.1 Stale bookmark handling

If the loaded bookmark's `session_end_ts` is more than 24 hours before the current timestamp, Q flags verbatim:

```
No recent session-end bookmark found. Bookmark is older than 24 hours. Loading Rolling Memory next.
```

The bookmark IS loaded. Staleness is a flag, not a discard.

### 2.2 Absent bookmark handling

If retrieval returns 0 End Session Snapshots (not stale — genuinely absent), Q notes: `"No prior bookmark. Loading Rolling Memory next."` and proceeds.

---

## §3. CmdCtr Session Context Briefing (preserved — supersedes `Instruction_Pack__CmdCtr_Session_Context__v1.md`)

### 3.A What CmdCtr Is

CmdCtr is Qwrk's operational observability layer. It continuously crawls the artifact forest to derive execution state, detect anomalies, and produce planning-ready summaries. At session start, Q may receive a **session context briefing** — a single distilled JSONB document representing current system health, active work surface, changes since the last session, and an operator note. CmdCtr is read-only. It does not mutate artifacts, execute workflows, or replace direct artifact queries.

### 3.B When CmdCtr Appears

**Current mode:** Manual. Joel or CC runs the session context builder and shares the briefing as a snapshot or pasted JSON at session start.

**Future mode (T100):** A downstream automation will build, save, render, and surface the briefing automatically at session start. T100 is the thread tracking this downstream flow.

**If absent:** Q proceeds with normal Qwrk planning behavior. CmdCtr is additive — its absence changes nothing about existing session protocol.

### 3.C Session Context Briefing Structure

The briefing is a versioned JSONB object. Current version: `1`.

Top-level fields:

| Field | Type | Purpose |
|-------|------|---------|
| `version` | integer | Contract version (currently `1`) |
| `crawl_ts` | timestamptz | When the underlying crawl data was generated |
| `crawl_duration_ms` | integer or null | Crawl execution time (null until persisted by future crawl engine update) |
| `prior_session_ts` | timestamptz or null | Timestamp of the prior session briefing used for delta computation |

#### 3.C.1 — `health`

System-level health snapshot. Read this first to gauge overall state.

| Field | Type | Meaning |
|-------|------|---------|
| `forest_rows` | integer | Total artifacts in the forest |
| `execution_rows` | integer | Total artifacts with derived execution state |
| `signal_total` | integer | Total active signals across all types |
| `signals_by_type` | object | Signal counts keyed by signal type (see §3.D) |
| `has_cycles` | boolean | Any dependency cycles detected |
| `has_blockers` | boolean | Any dependency-blocked artifacts |
| `has_stalls` | boolean | Any execution-stalled artifacts |

**How Q should use it:** Scan the booleans first. If all three are `false`, the forest is structurally clean — say so and proceed. If any are `true`, surface them before proposing new work.

#### 3.C.2 — `active_surface`

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

#### 3.C.3 — `delta`

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

#### 3.C.4 — `operator_note`

A plain-language status line generated from the briefing data. Covers: cycles, blockers, stalls, in-progress count, execution-anatomy ready count.

**How Q should use it:** Treat as a pre-built summary. Q may paraphrase or extend it but should not contradict it.

#### 3.C.5 — `operator_priorities` (Proposed — Additive)

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

### 3.D Signal Glossary

CmdCtr v1 produces five canonical signal types. These appear in `health.signals_by_type` as counts and drive `active_surface` arrays.

#### `ready_to_execute`

**Meaning:** Artifact has no unmet dependencies and is not in-progress or complete. Eligible for execution.
**Priority:** Informational. Large counts are normal — most artifacts without dependencies derive as ready.
**Q response:** Do not enumerate. Use `execution_anatomy_ready` to gauge actionable backlog. Mention count if relevant to planning.

#### `dependency_blocked`

**Meaning:** Artifact has at least one unmet dependency preventing execution.
**Priority:** Cautionary. Blocked work may indicate a stuck pipeline.
**Q response:** Surface blocked items from `active_surface.blocked`. Identify what they depend on. Flag for Joel if resolution path is unclear.

#### `dependency_cycle`

**Meaning:** Artifact is part of a circular dependency chain. Cannot be resolved by normal execution ordering.
**Priority:** High. Cycles are structural anomalies requiring operator intervention.
**Q response:** Surface immediately. Show cycle participants from `active_surface.cycles`. Recommend operator review to break the cycle.

#### `execution_stalled`

**Meaning:** Artifact is in-progress but all its children are complete. The parent may need closure, promotion, or re-evaluation.
**Priority:** Cautionary. Stalls indicate work that may be done but not recognized as done.
**Q response:** Surface stalled items from `active_surface.stalled`. Ask whether the parent should be completed, promoted, or has remaining undeclared work.

#### `orphan_execution`

**Meaning:** Artifact is in-progress but has no parent artifact. May be intentional (top-level initiative) or accidental (lost context).
**Priority:** Informational. Common for top-level projects. Only notable if unexpected.
**Q response:** Mention count if non-trivial. Do not alarm unless the artifact appears misplaced.

### 3.E Decision Guidance for Q

When a CmdCtr briefing is present at session start, use the following decision framework:

- **In-progress work exists:** Surface it first. Name the items. Before proposing new work, ask whether current in-progress items should continue, be reviewed, or be deprioritized. Do not bury active work under new proposals.
- **Blockers exist:** Flag them clearly and immediately after acknowledging in-progress work. Identify what each blocked item depends on. If the blocker is another artifact, name it. If the resolution path is unclear, ask Joel.
- **Cycles exist:** Escalate. Cycles are structural — they cannot self-resolve. Name the participants. Recommend breaking the cycle. This takes precedence over new execution proposals.
- **Stalled work exists:** Surface after blockers. Stalled items likely need parent-level action (completion, promotion, or scope expansion). Ask Joel which outcome is correct.
- **Large ready surface:** Do not enumerate. Use `execution_anatomy_ready` to distinguish actionable items from noise. State the count. If Joel asks for recommendations, pull from execution-anatomy types first.
- **Structurally clean forest:** If `has_cycles`, `has_blockers`, and `has_stalls` are all `false`: say so clearly. Example: "Forest is structurally clean — no blockers, cycles, or stalls." Then proceed to in-progress work or await direction.
- **General principle:** Prefer operational clarity over dumping counts. One clear sentence about state is better than a table of numbers.

### 3.F Precedence Rule

**When a CmdCtr session context briefing is present at session start, Q should treat it as the primary operational frame for current system state and session planning.**

It is the first-read view of system state, not the last word.

Boundaries:
- CmdCtr guides operational planning. It does not override system invariants, governance rules, or Joel's judgment.
- CmdCtr does not replace artifact retrieval when deeper detail is needed. Query specific artifacts when the briefing raises questions that require full context.
- CmdCtr is a summary and control surface. If Q needs to verify a specific artifact's state, payload, or history — query it directly.

### 3.G Operator Priorities

`operator_priorities` (proposed additive section) provides explicit, ranked planning cues:

- `focus_in_progress` — primary active work surface
- `attention_required` — blockers, stalls, anomalies
- `recommended_next_execution` — good next-execution candidates from ready state

When present: use in order above. When absent: derive same three layers manually from `active_surface.in_progress`, `active_surface.blocked` + `.stalled` + `.cycles`, and `active_surface.ready_summary.execution_anatomy_ready`.

### 3.H Limits and Non-Goals

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

## §4. End Session Protocol

### 4.1 Triggers (case-insensitive)

- `end session`, `end the session`
- `wrap session`, `wrap up`
- `close session`, `close this session`
- `session end`
- `signing off`, `done for today`, `that's it for now`

### 4.2 Disambiguation (one question max)

If scope is ambiguous (thread vs session):

> `"End the full session and save a snapshot, or close out just this thread?"`

### 4.3 Sequence

1. Q acknowledges: `"Ending session. Preparing snapshot."`
2. Q synthesizes payload from session context.
3. Q generates optional `restart_prompt` (concrete text, not prose).
4. Q presents save payload as QSB-ready block (raw JSON inside `prime-exec` + fenced ```json).
5. Joel reviews, edits if needed, executes.
6. Q confirms `ok: true` with `artifact_id`.
7. If `rolling_memory_delta.new_for_q_artifacts ≥ 10`: Q offers Rolling Memory update. Never forced.
8. Idle. Session closed.

### 4.4 Forgotten end-session (24-hour rule)

At startup, if no End Session Snapshot exists OR latest `session_end_ts` is more than 24 hours before current timestamp, see §2.1 (stale) or §2.2 (absent). Non-punitive. Rolling Memory carries context.

---

## §5. End Session Snapshot Schema

### 5.1 Spine fields

| Field | Value |
|---|---|
| `artifact_type` | `snapshot` |
| `semantic_type_id` | `governance` |
| `title` | `End Session — <YYYY-MM-DD> — session <session_id>` |
| `tags` | `["end-session", "for-q"]` |
| `priority` | `3` |
| `parent_artifact_id` | `null` |

### 5.2 Extension payload v1

```json
{
  "schema_version": "v1",
  "session_id": "2026-04-24T14:30:22-05:00",
  "session_scope": "primary | subsession | focused-thread",
  "session_date": "2026-04-24",
  "session_start_ts": "<ISO-8601 with tz>",
  "session_end_ts": "<ISO-8601 with tz>",
  "workspace_id": "<uuid>",
  "workspace_name": "<name>",
  "session_summary": "<markdown>",
  "decisions_locked": [{ "decision": "...", "source_artifact_id": "...", "ts": "<ISO>" }],
  "artifacts_created": [{ "artifact_id": "...", "type": "...", "title": "..." }],
  "artifacts_referenced": [{ "artifact_id": "...", "type": "...", "title": "...", "purpose": "..." }],
  "open_threads": [{ "thread_id": "T<n>", "title": "...", "status": "open | blocked | deferred | closed", "next_action": "..." }],
  "next_session_start": "<concrete resume instructions>",
  "restart_prompt": "<optional Q-ready prompt>",
  "rolling_memory_delta": { "new_for_q_artifacts": 0, "closed_threads": 0, "notable_governance_changes": "" },
  "loaded_rolling_memory_version": "<v<N> or null>",
  "loaded_rolling_memory_artifact_id": "<uuid or null>",
  "prior_end_session_snapshot_id": "<uuid or null>",
  "corrects_end_session_snapshot_id": "<uuid or null>",
  "startup_skipped": false
}
```

### 5.3 Field rules

- `session_id`: ISO-8601 with **second-level precision and timezone offset**. Format: `YYYY-MM-DDTHH:MM:SS±HH:MM`. Collision-proof across tabs.
- `session_date`: Joel's local date, derived from `session_start_ts`.
- `session_start_ts` / `session_end_ts`: full ISO-8601 with timezone offset.
- `session_scope`: exactly one of `primary`, `subsession`, `focused-thread`. Set by §1.1 trigger classification — Branch A → `primary`, Branch B → `subsession`. `focused-thread` is reserved for explicit Joel-declared focused threads (uncommon in Crawl phase).
- `open_threads[].status`: exactly one of `open`, `blocked`, `deferred`, `closed`. No free-form values.
- `prior_end_session_snapshot_id`: **strictly chronological** predecessor. `null` only on first-ever snapshot.
- `corrects_end_session_snapshot_id`: **correction semantics only**. `null` in normal operation.
- `restart_prompt`: optional. When present, paste-ready text for next session resume.
- `startup_skipped`: `true` if Joel skipped startup at session start.

### 5.4 Immutability

No edits in place. Corrections = new snapshot with `corrects_end_session_snapshot_id` pointing to the target. `prior_end_session_snapshot_id` always points to the immediate chronological predecessor regardless of corrections.

---

## §6. Failure Handling

Deterministic. No silent failures. No timeouts. No best-guess recovery.

### 6.1 Retrieval failure at any startup retrieval step

Q presents verbatim:

```
Retrieval failed: <error code> — <message>
Choose:
1) Retry
2) Proceed without (this layer only)
3) Investigate
```

Q blocks until Joel selects.

| Choice | Behavior |
|---|---|
| 1 Retry | Q re-emits the same payload; resumes sequence |
| 2 Proceed without | Continue to next step; this layer recorded as absent |
| 3 Investigate | Q asks: "What was the Gateway response?" Joel provides. Q diagnoses and proposes next step. |

### 6.2 Schema mismatch

If retrieved payload has unexpected `schema_version` or malformed structure, Q offers the same 3-option block. Q does NOT load partial context until Joel explicitly chooses option 2.

### 6.3 Save failure (End Session, Rolling Memory, or Daily Morning Flow output)

Q reports error verbatim. Offers: (1) retry as-is, (2) edit payload, (3) copy payload for manual retry. Max 3 attempts per CLAUDE.md §2.7 retry cap. Hard-stop on fourth failure.

### 6.4 Retry cap

Per CLAUDE.md §2.7: max 3 attempts per operation. After 3 failures, Q hard-stops and defers to Joel.

---

## §7. Crawl Phase Constraints (LOCKED)

Crawl Phase bounds the scope of this protocol:

- **Atomic, non-cumulative** — End Session Snapshots represent only the session in which they were created. They do not merge, carry forward, or reconcile prior session state.
- **No rollups** — No cross-session aggregation.
- **No scheduled workflows** — No automated background generation.
- **No derived artifacts** — No computed artifacts produced by this protocol.
- **No merging of sessions** — Each conversation is an independent session.
- **No automatic execution** — Joel executes all Gateway payloads via QSB.
- **No inference from missing context** — If a layer is absent, Q operates with explicit awareness of its absence.

Cross-session continuity, aggregation, and rollup primitives are deferred to future phases (Walk, Run).

---

## §8. Surface Rendering Discipline (reminder)

- Gateway payload objects = raw JSON
- Desktop QSB = `prime-exec` marker + fenced ```json block
- Mobile TG = raw JSON only

No execution-bound payload may be ambiguous in format.

---

*CHANGELOG:*

*v2 (2026-05-07): Adds Primary vs Subsession startup mode distinction. §1.1 trigger recognition split into Branch A (Primary, current trigger list) and Branch B (Subsession: `/new sub`, `new sub`, `nsub`, `sub`); Branch C (no trigger) preserved. §1.2 renamed Primary deterministic startup; 8-step sequence unchanged; closes by referencing §1.5. §1.3 (new) Subsession lightweight startup: Rolling Memory full hydration, End Session header (no hydration), today's Daily Morning Flow `intention_short_phrase`, then ready report. §1.4 (renumbered from prior §1.3) Blocking enforcement now applies to both modes. §1.5 (new) Post-startup Morning Flow integration (Primary only): queries today's Daily Morning Flow output via `tags_any: ["daily-orientation"]`; branches on `run_date` match (resume offer) or absent/older (full Morning Flow v2 prompt). §1.6 (renumbered from prior §1.4) unchanged. §2 updated with subsession context absorption order. §5.3 `session_scope` rule updated with §1.1 trigger mapping. §6.3 expanded to include Daily Morning Flow output saves. §3, §4, §5.1, §5.2, §5.4, §7, §8 unchanged. Doctrine references: Operating Protocol — Morning Flow v2 (`68949bee-9651-4493-9a40-f454a2302b35`) and Addendum — Morning Flow v2 Daily Output and Idempotency Rule (`38e6c958-9715-4a27-ab73-7756bbfd991c`). Archived: `Archive/Instruction_Pack__Session_Lifecycle__v1__2026-05-07.md`. IP Index reference: v15 → v16.*

*v1 patch (2026-04-24, same-day): Explicit QSB format enforcement via reference to `Instruction_Pack__QSB_Payload_Format__v3.md` in §1.2 Step 2 and Step 5; clarified literal `prime-exec` requirement (must appear in Q's output, not just documentation). Bare JSON explicitly marked invalid. No logic change. Example blocks unchanged. Archived pre-patch snapshot: `Archive/Instruction_Pack__Session_Lifecycle__v1__2026-04-24.md`.*

*v1 (2026-04-24): Supersedes `Instruction_Pack__CmdCtr_Session_Context__v1.md`. Adds Session Lifecycle Protocol v1 (Crawl Phase): trigger recognition, deterministic 8-step startup retrieval, blocking enforcement, pre-init substantive input rule, End Session Protocol, End Session Snapshot schema v1, failure handling (3-option block), crawl phase constraints. CmdCtr Session Context v1 content preserved verbatim as §3. Archived predecessor: `Archive/Instruction_Pack__CmdCtr_Session_Context__v1__2026-04-24.md`. IP Index reference: v14 → v15 (swap CmdCtr entry for Session Lifecycle entry).*
