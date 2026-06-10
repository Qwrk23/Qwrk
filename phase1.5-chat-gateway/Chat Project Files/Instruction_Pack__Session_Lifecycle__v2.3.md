# Instruction Pack — Session Lifecycle (v2.3)

**scope:** `global`
**pack_version:** `v2.3`
**status:** Active
**created:** 2026-04-24 (v1)
**updated:** 2026-06-10 (v2.3)
**phase:** Crawl Phase (atomic, non-cumulative)
**origin:** Session Lifecycle Protocol v1 — supersedes CmdCtr Session Context v1 by incorporating it as §3 (Startup Context Briefing). Governs session start, context retrieval, end-session snapshot creation, and crawl-phase boundaries.
**v2 patch:** Adds Primary vs Subsession startup mode distinction. Primary triggers run the full deterministic 8-step retrieval and post-startup Morning Flow integration. Subsession triggers run a lightweight retrieval and skip Morning Flow. Doctrine references: Operating Protocol — Morning Flow v2 (`68949bee-9651-4493-9a40-f454a2302b35`) and Addendum — Morning Flow v2 Daily Output and Idempotency Rule (`38e6c958-9715-4a27-ab73-7756bbfd991c`).
**v2.1 patch:** Adds T185 instruction-layer fallback handlers scoped to two daily-orientation lookup contexts: §1.5 (Primary, Post-startup Morning Flow integration) and §1.3 Step 7 (Subsession lightweight startup). Mode-differentiated outcomes preserved (Primary prompts Morning Flow v2; Subsession records `intention: none-today` and continues). New §1.7 captures shared scope guardrail. T185 remains an active Gateway defect; this patch is instruction-layer mitigation only and does NOT close T185.
**v2.2 patch:** Adds Workbench (Working Set) doctrine (§9), the workbench tag exclusion rule for session-close snapshots (§5.1a), documents the already-emitted `active_workbench[]` payload field (§5.2/§5.3), and canonicalizes the session-close spine tag to `session-end` (§5.1 — bounded terminology alignment; no historical retag, no retrieval or Gateway change). This patch is **additive doctrine + explicit prohibition + payload documentation + bounded tag-string alignment**. It introduces **no startup behavior change** (it does NOT require `/wake` or any startup step to list Workbench items), **no DB schema change**, **no schema-version bump**, and **no new Gateway action, table, enum, or runtime migration**. Corrected root cause: no prior instruction added `workbench` to session-close snapshots; the tag accumulated through habitual save-time tagging. Source: Workbench Purpose and Process Revision sapling `c75c4dbe-987d-43ed-a126-65f3222179d2`; TQR Synthesis `d89c9395-ea35-41ed-b161-dd18c770ab0a`; Correction — Workbench Tagging Root Cause `a067ec42-b4e0-4931-acde-ab075c636200`. Reviews: Manus TQR approve-with-amendments (incorporated) + final shape approval; Q approved with CD-1 (session-end canonicalization).
**v2.3 patch:** Restores retrieval-side alignment with v2.2 §5.1 save-side canonical `session-end` tag by introducing **two-query client-side union** retrieval in §1.2 Primary and §1.3 Subsession End Session lookups, expressed as **substeps** (Step 2a/2b/2c/2d in §1.2, Step 4a/4b in §1.3) so existing step numbers and all §2 cross-references remain valid. Adds new §1.8 transitional retrieval window with named narrowing trigger and transitional-observation telemetry. §1.2 Step 8 and §1.3 Step 8 verbatim reports gain a conditional `[ (transitional tag)]` slot triggered only when the merged top schema-valid bookmark carries only `end-session`. §5.1 save-side canonical tag (`["session-end", "for-q"]`) is **frozen** — no save-side change. §4.4 is **unchanged** and explicitly confirmed in §1.8 as containing no retrieval payload (it consumes already-loaded bookmark state via §2.1/§2.2). No DB schema change. No `schema_version` bump. No Gateway action change. No payload-shape change at save-side. No Workbench (§9), §5.1a, §5.2/§5.3 `active_workbench[]`, T185 fallback (§1.5, §1.3 Step 7, §1.7), Morning Flow v2 doctrine, §3 CmdCtr, §6 Failure Handling, §7 Crawl Phase Constraints, or §8 Surface Rendering change. **Driven by:** G coordination flag surfaced 2026-06-10 during Rolling Memory v16 cleanup — the 2026-06-09 end-session snapshot `36e86798-0074-4ad2-b957-b86b39033543` was tagged `end-session` while v2.2 §5.1 canonical is `session-end`, so canonical-only retrieval silently returned an older snapshot. Empirical Gateway behavior recorded in sister twig `b14f8027-5ab9-4010-a4f0-ab9461f79599` (Gateway v2 `tags_any` returns intersection not union) — structural reason for two-query client-side union rather than single dual-tag broadening. Sister thread is evidence-only and does NOT block this patch. Authorizing lane: project `46142606-ac00-416c-95a0-2e81e997b9e4` (Session Lifecycle / End Session Schema — Governance Lane). Related downstream work: Session Receipt Ledger branch `dd702a7f-9113-43ee-ab9f-cea1fdedacc0` (End Session Search Enrichment, parented under governance lane). Reviews: Manus TQR Amend (A1–A10 applied); Q approve with one wording polish (§1.8 future-collapse evaluation, applied) and parallel §1.8 sister-thread coordination wording polish (applied); Joel approval (applied).

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

**Step 2** — Q emits End Session retrieval as a **two-query client-side union** (see §1.8 for why two queries rather than one dual-tag query).

Emit each substep in QSB format per `Instruction_Pack__QSB_Payload_Format__v3.md`. The `prime-exec` marker is literal — it must appear in Q's output, not just in this documentation. Bare JSON is invalid and will be rejected by QSB.

**Step 2a** — Q emits End Session retrieval payload, **canonical-tag query**:

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["session-end"] },
    "hydrate": true,
    "limit": 3
  }
}
```

**Step 2b** — BLOCK until Joel executes Step 2a and pastes Gateway response. Q records the response as `bookmark_results_canonical` (do not absorb yet — merge happens at Step 4).

**Step 2c** — Q emits End Session retrieval payload, **transitional-tag query**:

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
    "limit": 3
  }
}
```

**Step 2d** — BLOCK until Joel executes Step 2c and pastes Gateway response. Q records the response as `bookmark_results_transitional`.

**Step 3** — Both paste responses received. Q proceeds to Step 4 merge. (Step 3 retained as the explicit transition gate to absorption so the §2 cross-reference "loaded in §1.2 Step 4" remains valid.)

**Step 4** — Q merges `bookmark_results_canonical` and `bookmark_results_transitional` using the deterministic algorithm below, then absorbs the resulting End Session bookmark.

**K semantics.** K=3 is the per-tag-query limit, so the merged pre-dedupe candidate pool is up to **6 candidates**. The K=10 bounded retry (Step 4.6 below) emits both queries again with `"limit": 10`, producing up to **20 pre-dedupe candidates**. Retry applies to **both** the `session-end` and `end-session` queries.

**Recency authority.** `created_at` is the sole recency authority for selecting the End Session bookmark. Do NOT use `updated_at` or `version` as the selector for "latest."

**Algorithm:**

1. **Union by `artifact_id`.** An artifact appearing in both result sets appears **once** in the merged set. Record its tag-source as `both`.
2. **Sort merged set by `created_at` descending.**
3. **Deterministic tiebreaker for identical `created_at`:** `artifact_id` ascending lexicographic (string comparison). Stable across Q instances.
4. **Define "schema-valid bookmark."** A merged candidate is schema-valid iff its hydrated `extension.payload` satisfies the End Session Snapshot schema per §5.2 (current `schema_version: v1`) and §5.3 field rules: required fields present (`schema_version`, `session_id`, `session_scope`, `session_date`, `session_start_ts`, `session_end_ts`, `workspace_id`, `workspace_name`, `session_summary`); `session_scope` value matches §5.3 enum (`primary` | `subsession` | `focused-thread`); `session_id` matches §5.3 ISO-8601 second-level format; `open_threads[].status` values match §5.3 enum; `prior_end_session_snapshot_id` either present or null per §5.3 rule. Anything failing these checks is schema-invalid.
5. **Scan from top, take first schema-valid candidate as the End Session bookmark.**
6. **Invalid-latest handling.** If the top (latest by `created_at`) candidate is schema-invalid but an older candidate in the merged set is schema-valid:
   - Use the **older valid candidate** as the bookmark; record `bookmark: loaded`.
   - Record session-note observation: *"End Session latest candidate `<latest-artifact-id>` is schema-invalid; using older schema-valid bookmark `<used-artifact-id>` (older by `created_at`)."*
   - This observation is **not** §6 Failure Handling unless schema-invalidity persists (Step 4.9). It is recorded so the malformed latest is not silently buried.
7. **Tag-source classification:**
   - Selected bookmark's tags contain `session-end` (with or without `end-session`): record `bookmark_tag_source: canonical` (or `canonical-plus-transitional` if both tags present).
   - Selected bookmark's tags contain only `end-session`: record `bookmark_tag_source: transitional`. Trigger transitional observation telemetry per §1.8 (session-note line + concise startup-report line in Step 8).
8. **Fallback if no schema-valid candidate in merged K=3 window:** single bounded retry — re-emit Step 2a and Step 2c with `"limit": 10`. Joel re-executes both. Q re-merges per Steps 1–5. If a schema-valid candidate is found in the K=10 merged window (up to 20 candidates pre-dedupe), proceed normally with bookmark + invalid-latest observation if applicable.
9. **§6 escalation:** If K=10 retry still yields no schema-valid candidate, route to §6 Failure Handling. Block until Joel selects. Do NOT silently treat as `bookmark: none`. Treat persistent schema-invalidity across K=10 as systemic.
10. **Genuine-absence handling:** If both queries return `count: 0` in initial K=3 AND the K=10 retry also returns `count: 0` on both: record `bookmark: none` and proceed normally. This is genuine absent-bookmark (e.g., first-ever session in a fresh workspace), distinct from schema-invalidity.

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
- Bookmark: <loaded | none>[ (transitional tag)]
- Memory: <loaded | none>
Ready.
```

Slot substitution:
- `<loaded | none>` replaced with literal `loaded` or `none` based on Step 4 / Step 7 outcomes.
- `[ (transitional tag)]` appears as literal text ` (transitional tag)` (leading space, in parentheses) **only when** `bookmark_tag_source == "transitional"` per Step 4.7. Omitted otherwise. Concise startup-report observation when the selected bookmark came only from `end-session`. Not a failure framing — bookmark is valid. Verbatim contract preserved: the slot is deterministic given Step 4's outcome.

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

**Step 4** — Q emits End Session header retrieval as a **two-query client-side union** (lightweight, `hydrate: false`; see §1.8):

**Step 4a** — Q emits End Session header retrieval payload, **canonical-tag query** (lightweight):

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["session-end"] },
    "hydrate": false,
    "limit": 3
  }
}
```

**Step 4b** — Q emits End Session header retrieval payload, **transitional-tag query** (lightweight):

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
    "limit": 3
  }
}
```

**Step 5** — BLOCK until Joel executes Steps 4a and 4b and pastes both Gateway responses. Q merges per §1.2 Step 4 algorithm (union by `artifact_id`, sort `created_at` DESC, tiebreaker `artifact_id` ASC, scan for first schema-valid candidate, invalid-latest handling, K=10 bounded retry, §6 escalation, genuine-absence handling). Q absorbs **spine fields only** of the merged top schema-valid candidate (title, `created_at`, `summary` if present). Q records `bookmark: header-loaded` or `bookmark: none`.

**Schema validation in lightweight mode.** Because Subsession retrieval uses `hydrate: false`, only spine-level schema validation applies: `artifact_type == "snapshot"`, `title` matches §5.1 format `End Session — <YYYY-MM-DD> — session <session_id>`, `tags` contain `session-end` and/or `end-session`. Full extension-payload schema validation is deferred until/unless Joel explicitly requests full hydration.

**Tag-source classification** per §1.2 Step 4.7 rules (`canonical` / `transitional` / `canonical-plus-transitional`). Transitional observation telemetry per §1.8 triggers session-note line and concise startup-report line in Step 8.

Q does NOT request full hydration unless Joel explicitly asks. Q does NOT retry the lookup beyond the K=10 bounded retry.

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
- **T185 zero-result signature on this exact lookup context** (see "T185 fallback handler — §1.3 Step 7 only" below): record `intention: none-today`. Continue lightweight subsession startup. Do NOT start Morning Flow. Do NOT trigger §6 Failure Handling. Do NOT retry the lookup.
- Failure (any cause OTHER than T185 zero-result signature on this exact lookup context): §6 handling.

**T185 fallback handler — §1.3 Step 7 only**

This handler applies ONLY when BOTH of the following are true:

1. **Error signature** — QSB returns one of: empty HTTP body, `"Unexpected end of JSON input"`, or other known T185 zero-result signature.
2. **Exact lookup context** — the failed request payload matches the §1.3 Step 6 daily-orientation lookup verbatim:

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

When BOTH conditions hold, the parse error is the documented T185 zero-result behavior on this lookup, not a system error.

**Required Q behavior:**

- Record `intention: none-today`.
- Continue lightweight subsession startup; proceed to Step 8.
- Step 8 final report renders the intention line as: `Today's intention: none yet`.
- Do NOT start Morning Flow. (Subsession is workbench-mode; no daily ritual rerun.)
- Do NOT trigger §6 Failure Handling.
- Do NOT retry the lookup.
- Do NOT apply this handler outside the §1.3 Step 7 lookup context.
- Do NOT classify generic QSB JSON parse errors on other payloads as harmless.

**Recognition example:**

1. Joel runs `/new sub` in a fresh Q tab before completing Morning Flow today.
2. Q completes §1.3 Steps 1–5 successfully (Rolling Memory loaded, End Session header loaded).
3. Q emits the daily-orientation lookup in Step 6 (matches the exact context above).
4. Joel pastes into QSB and executes.
5. QSB returns: `Unexpected end of JSON input`.
6. Q recognizes the error in this exact lookup context as the T185 zero-result signature, records `intention: none-today`, and proceeds to Step 8.
7. Step 8 reports verbatim:

```
Subsession started.
- Memory: loaded
- Bookmark: header-loaded
- Today's intention: none yet
Ready.
```

**Escalation — if T185 signature persists when daily-orientation snapshots are known to exist:**

If the T185 signature recurs on this lookup AND Joel has confirmed (via other Gateway query) that a `daily-orientation`-tagged snapshot exists in this workspace, the trigger context no longer applies cleanly. Reclassify immediately as a Gateway/QSB bug and follow the Team Qwrk Bug Resolution Process. Escalation artifact tags: `bug-resolution`, `t185`, `qsb`, `gateway`, `daily-orientation`, `subsession`. Required evidence: workspace_id, the exact Step 6 lookup payload that failed, the QSB error text and timestamp, the artifact_id of the most recent confirmed `daily-orientation` snapshot.

See §1.7 for the shared scope guardrail governing this and the §1.5 handler.

**Step 8** — Q reports verbatim:

```
Subsession started.
- Memory: <loaded | none>
- Bookmark: <header-loaded | none>[ (transitional tag)]
- Today's intention: <"<phrase>" | none yet>
Ready.
```

Slot substitution:
- `<loaded | none>`, `<header-loaded | none>`, `<"<phrase>" | none yet>` per v2.2 rules.
- `[ (transitional tag)]` appears as literal text ` (transitional tag)` **only when** Step 5's tag-source classification yielded `transitional`. Omitted otherwise. Mirrors §1.2 Step 8 behavior per §1.8.

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
| **T185 zero-result signature on this exact lookup context** (see "T185 fallback handler — §1.5 only" below) | **Treat as `0 artifacts`. Q prompts full Morning Flow v2 per snapshot `68949bee-9651-4493-9a40-f454a2302b35`. Do NOT trigger §6 Failure Handling. Do NOT retry the lookup.** |
| Failure (any cause OTHER than T185 zero-result signature on this exact lookup context) | §6 handling. |

**T185 fallback handler — §1.5 only**

This handler applies ONLY when BOTH of the following are true:

1. **Error signature** — QSB returns one of: empty HTTP body, `"Unexpected end of JSON input"`, or other known T185 zero-result signature.
2. **Exact lookup context** — the failed request payload matches the §1.5 daily-orientation lookup verbatim:

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

When BOTH conditions hold, the parse error is the documented T185 zero-result behavior on this lookup, not a system error.

**Required Q behavior:**

- Treat the result as equivalent to `0 artifacts`.
- Prompt full Morning Flow v2 per snapshot `68949bee-9651-4493-9a40-f454a2302b35`.
- Do NOT trigger §6 Failure Handling.
- Do NOT retry the §1.5 lookup.
- Do NOT apply this handler outside the §1.5 lookup context.
- Do NOT classify generic QSB JSON parse errors on other payloads as harmless.

**Recognition example:**

1. Joel runs `/wake` in a fresh Q tab.
2. Q completes §1.2 Steps 1–8 successfully.
3. Q emits the §1.5 daily-orientation lookup payload (matches the exact context above).
4. Joel pastes into QSB and executes.
5. QSB returns: `Unexpected end of JSON input`.
6. Q recognizes the error in this exact lookup context as the T185 zero-result signature and proceeds directly to prompting full Morning Flow v2 per snapshot `68949bee-9651-4493-9a40-f454a2302b35`.
7. Joel completes Morning Flow; Q assembles and presents the Daily Morning Flow output save payload per the addendum's save-handoff flow (`38e6c958-9715-4a27-ab73-7756bbfd991c`); Joel executes; snapshot persists.

**Escalation — if T185 signature persists when daily-orientation snapshots are known to exist:**

If the T185 signature recurs on the §1.5 lookup AND Joel has confirmed (via other Gateway query) that a `daily-orientation`-tagged snapshot exists in this workspace, the trigger context no longer applies cleanly. Reclassify immediately as a Gateway/QSB bug and follow the Team Qwrk Bug Resolution Process. Escalation artifact tags: `bug-resolution`, `t185`, `qsb`, `gateway`, `daily-orientation`. Required evidence: workspace_id, the exact §1.5 lookup payload that failed, the QSB error text and timestamp, the artifact_id of the most recent confirmed `daily-orientation` snapshot.

See §1.7 for the shared scope guardrail governing this and the §1.3 Step 7 handler.

**Morning Flow protocol details** are governed by snapshot `68949bee-9651-4493-9a40-f454a2302b35` (Operating Protocol — Morning Flow v2) and snapshot `38e6c958-9715-4a27-ab73-7756bbfd991c` (Addendum — Morning Flow v2 Daily Output and Idempotency Rule). When the protocol is run, Q follows the v2 doctrine — coherence reset, then 6-question sequence, one question at a time — and produces the Daily Morning Flow output snapshot save payload at close per the addendum's save-handoff flow. Joel executes the save via QSB; Q verifies persistence via the returned `artifact_id` before closing the orientation.

### 1.6 Pre-initialization substantive input

If Joel issues a substantive request before initialization completes OR before Branch C decision resolves, Q responds verbatim:

```
Input deferred.
Session not initialized.
Start a new session? (y/1 to load, n/2 to skip)
```

Q does NOT process the deferred request. Q repeats this verbatim until initialization resolves.

### 1.7 T185 fallback scope (shared guardrail)

The T185 fallback handlers in §1.3 Step 7 and §1.5 are instruction-pack mitigations for known T185 Gateway zero-result behavior on the `daily-orientation` artifact.list lookup only. These handlers:

- Apply ONLY to the exact `daily-orientation` lookup context defined in §1.3 Step 6 and §1.5.
- Do NOT generalize to other `artifact.list`, `artifact.query`, `artifact.save`, or any Gateway action.
- Do NOT apply to End Session retrieval, Rolling Memory retrieval, CmdCtr briefing, or any other lookup in this protocol.
- Do NOT normalize generic QSB JSON parse errors as harmless. Parse errors outside the §1.3 Step 7 / §1.5 trigger contexts continue to route through §6 Failure Handling.
- Do NOT change Gateway response requirements.
- Do NOT modify request or response payload shapes.
- Do NOT close T185.
- Do NOT alter Morning Flow v2 doctrine.

**Different outcomes per startup mode (preserved):**

- **Primary §1.5** outcome under T185 fallback: prompt full Morning Flow v2.
- **Subsession §1.3 Step 7** outcome under T185 fallback: record `intention: none-today` and continue lightweight subsession startup. Do NOT start Morning Flow.

**T185 status:** Active Gateway defect. Tracked as Active Surface, High priority. Documentation-first mitigation per Joel direction. Q@W IP v2 has a parallel fallback handler for first-wake End Session retrieval. This Prime IP v2.1 patch adds analogous handlers for the two `daily-orientation` lookup contexts only. T185 closure requires a Gateway-level fix to the List sub-workflow zero-result envelope; that fix is out of scope for this IP.

### 1.8 Transitional retrieval window and narrowing trigger

The two-query client-side union in §1.2 Steps 2a–4 and §1.3 Steps 4a–5 is **transitional**. Save-side canonicalization at §5.1 emits `["session-end", "for-q"]` exclusively (frozen from v2.2). The union-side retrieval temporarily accepts both `session-end` and `end-session` tag values to cover (a) historical snapshots saved before v2.2 §5.1 canonicalization landed, and (b) any in-window save-side drift during multi-instance Q convergence.

**Why two queries instead of one dual-tag query.** Empirical Gateway v2 testing 2026-06-10 (sister twig `b14f8027-5ab9-4010-a4f0-ab9461f79599`) demonstrated that `selector.filters.tags_any` with a multi-element array returns *intersection* (artifacts carrying ALL listed tags) rather than *union* (artifacts carrying ANY listed tag). A single dual-tag query would silently return only snapshots carrying both `session-end` AND `end-session` — the opposite of the broadening this transition requires. The two-query client-side union is the structural response. If the Gateway sister thread later closes with confirmed OR semantics, a future patch under this lane may evaluate whether retrieval should collapse to a single dual-tag query or narrow directly to the canonical `session-end` query, depending on the transition window and save-side telemetry at that time.

**K semantics.** K=3 is the per-tag-query limit; the merged pre-dedupe candidate pool is up to **6 candidates**. The bounded K=10 retry emits both queries again with `"limit": 10`, producing up to **20 pre-dedupe candidates**. The retry applies to **both** `session-end` and `end-session` queries (not one or the other).

**Recency authority.** `created_at` is the sole authority for selecting the latest End Session bookmark during merge. `updated_at` and `version` are not used as the recency selector. (Snapshots are immutable per §5.4; `updated_at` movement reflects spine `content_append` or `tags` updates rather than session-end recency.)

**Transitional observation telemetry.** When merge classifies the selected bookmark as `bookmark_tag_source: transitional`:

- **Session note (always):** Q records *"End Session bookmark loaded via transitional tag `end-session` only (sister twig `b14f8027`)."*
- **Concise startup report (always):** the §1.2 Step 8 or §1.3 Step 8 verbatim report slot `[ (transitional tag)]` appears.

This is **not a failure** when a schema-valid bookmark was found — the bookmark is fully usable. The observation is for narrowing-trigger telemetry and operator visibility. It does NOT imply authorization to re-tag the historical snapshot. Historical re-tagging is forbidden by v2.2 §5.1 doctrine and remains forbidden in v2.3.

When merge classifies the selected bookmark as `bookmark_tag_source: both` (an artifact carrying both tags, deduped to one record): treat as canonical for reporting (no transitional-tag observation; no startup-report variant). Tag-source `both` is informational only — recorded in session notes if useful for telemetry, but not surfaced in the verbatim report.

**Invalid-latest handling.** Per §1.2 Step 4.6 / §1.3 Step 5, if the latest merged candidate is schema-invalid but an older candidate is schema-valid, Q uses the older valid bookmark and records a session-note observation. The malformed-latest is not silently buried. §6 Failure Handling is invoked only when K=10 retry still yields no schema-valid candidate.

**§4.4 consumption note.** §4.4 contains no retrieval payload of its own. It references §2.1 (stale-bookmark handling) and §2.2 (absent-bookmark handling), both of which describe behavior on the already-loaded bookmark from §1.2 Step 4 (Primary) or §1.3 Step 5 (Subsession). The bookmark consumed by §2.1/§2.2 — and therefore by §4.4 — is the merged-union output per §1.2 Step 4 algorithm. v2.3 makes no edit to §4.4 body text.

**Narrowing trigger.** Retrieval narrows back to single-tag `session-end`-only via a future v2.4 patch under this governance lane when **all three** of the following are true:

1. **N = 5 consecutive new End Session saves** across **all save surfaces in this lane** (Prime workspace `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` and Q@W workspace `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`) carry the canonical `session-end` tag and **zero new saves carry `end-session`**. This tracks **save-side emission behavior** — not retrieval-side selection. Counting bookmarks selected by Q at session-start does NOT satisfy this criterion; what matters is what gets *saved* across both workspaces' End Session protocols.
2. **Calendar window:** ≥ 30 days elapsed since v2.3 landing date.
3. **Q@W parity:** Q@W workspace's Session Lifecycle IP (currently the Q@W v2 variant per T195) has reached an equivalent N=5 / 30-day milestone in its own retrieval canonicalization.

When all three met → file v2.4 patch under this lane: remove §1.2 Steps 2c, 2d, §1.3 Step 4b, restore §1.2 Step 2 and §1.3 Step 4 to single-payload form (sourced from §5.1 canonical tag), update §1.8 to closed. Pattern C archival of v2.3.

**Gateway sister-thread coordination.** If sister twig `b14f8027` is later promoted to a seed project and the Gateway selector semantics fix lands ahead of the narrowing trigger, a future patch under this lane may evaluate whether retrieval should collapse to a single dual-tag query or narrow directly to canonical `session-end`-only retrieval, depending on the transition window and save-side telemetry at that time. Both successor paths remain governed by project `46142606-ac00-416c-95a0-2e81e997b9e4`.

**What §1.8 does NOT do.**

- Does NOT modify save-side canonical tag (§5.1 frozen at `["session-end", "for-q"]`).
- Does NOT authorize historical re-tagging.
- Does NOT authorize Gateway patch.
- Does NOT authorize DB schema change.
- Does NOT generalize to other multi-tag retrievals (daily-orientation, rolling-memory, etc.). Those remain single-tag.
- Does NOT alter T185 fallback handlers (§1.5, §1.3 Step 7, §1.7).
- Does NOT change §4.3 End Session save sequence.
- Does NOT affect Workbench (§9) doctrine or §5.2/§5.3 `active_workbench[]` field.
- Does NOT change `schema_version`.
- Does NOT change Morning Flow v2 doctrine or its addendum references.

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

The End Session bookmark in §1.2 Step 4 and the End Session header in §1.3 Step 5 are produced by the two-query client-side union retrieval per §1.8 (transitional window). Tag-source classification (`canonical` / `transitional` / `both` / `canonical-plus-transitional`) is recorded as part of absorption per §1.2 Step 4 algorithm and §1.3 Step 5; transitional-source bookmarks surface a concise observation in the verbatim startup report per §1.2 Step 8 / §1.3 Step 8.

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
4. Q presents save payload as QSB-ready block (raw JSON inside `prime-exec` + fenced ```json). (End-session snapshots are not tagged `workbench` — see §5.1a.)
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
| `tags` | `["session-end", "for-q"]` |
| `priority` | `3` |
| `parent_artifact_id` | `null` |

### 5.1a Workbench tag exclusion

End-session snapshots — and any end-subsession or session-closeout snapshot, should one be saved — **MUST NOT** carry the `workbench` tag. Bench state at session close is recorded *inside* the snapshot as the `active_workbench[]` payload field (§5.2), never as a spine tag.

Rationale: `workbench` denotes a *live, curated* near-term continuation item (§9). A session-close snapshot is an automatic, per-session receipt — not a continuation item. No instruction ever mandated this tag; it accumulated through habitual save-time tagging (see Correction — Workbench Tagging Root Cause `a067ec42-b4e0-4931-acde-ab075c636200`). This rule is an explicit prohibition so the habit cannot return silently. It is independent of the canonical session-close tag string (§5.1); it forbids `workbench` regardless of which string is used.

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
  "active_workbench": [{ "artifact_id": "<uuid>", "title": "...", "artifact_type": "project | snapshot | restart | twig", "status": "...", "next_action": "..." }],
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
- `active_workbench[]`: **receipt only** — the bench state as of session close, for continuity reference. Optional; omit or use `[]` when the bench is empty. This array is **payload documentation only**: it is **not** the live workbench (the live bench is the set of artifacts currently carrying the `workbench` tag — §9), it carries **no DB schema change**, requires **no schema-version bump** (the field is already emitted under `schema_version: v1`; no hard requirement to bump was identified), and introduces no new Gateway action, table, or enum. Each entry SHOULD carry a `next_action` (mirrors §9.3). Recording `active_workbench[]` does **not** obligate any startup step to list Workbench items (§9.5).

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

## §9. Workbench (Working Set)

### 9.1 Definition
The Workbench is the curated set of artifacts intentionally available for **near-term, user-facing continuation**. Membership is expressed by the `workbench` tag on the artifact spine. An item belongs on the workbench iff (a) it has a clear `next_action` and (b) Joel would expect to see it when asking "what's on my bench right now?". Recency is not the criterion — curation is.

### 9.2 What the workbench is NOT
The `workbench` tag does not mean: every important artifact; every end-session/end-subsession snapshot; every supporting reference; every dependency map; every artifact worth keeping; everything that may matter someday. Those remain discoverable by type, tag, and recency without `workbench`.

Related but distinct surfaces:
- `active_workbench[]` (§5.2) — a session-close **receipt** of bench state. Not live authority in v0.
- `OPEN_THREADS.md` — broader operating awareness / cognitive active surface (CC-side). Not identical to the workbench; an item may live in OPEN_THREADS without being on the workbench.

### 9.3 Curated, not automatic
Items join only on explicit intent ("workbench this" / "add to workbench" / "put this on the workbench") and leave on explicit intent or supersession ("remove from workbench" / "done with this"; or when a newer anchor replaces an older one — untag the stale anchor). **No save path adds `workbench` automatically.** Each workbench item should represent one current thread; supporting artifacts are linked from their active anchor rather than separately tagged.

### 9.4 Eligible types (v0)
`project`, `snapshot`, `restart`, `twig`.
- **`project`, `twig`** — eligible when an active near-term continuation item.
- **`restart` — eligible ONLY when deliberately authored as a live resume handle for an active thread.** A restart is NOT eligible merely because it is a session receipt or an automatic closeout artifact. Once its context is absorbed into the active thread, untag it.
- **`snapshot` — eligible ONLY when deliberately curated as a continuation anchor** (e.g., a working definition or dependency map a thread is actively building on). End-session, end-subsession, and session-closeout snapshots are **excluded** from `workbench` (§5.1a).
- **`journal` — excluded** (reflective / captured-and-moved-on).
- Adding or removing an eligible type is a single-line change here under the T212 gate.

### 9.5 Retrieval rule
When the Workbench is listed, retrieval MUST enumerate **all** eligible types — never `project` only. Because Gateway `artifact.list` requires a single `artifact_type` per call, a complete listing emits one tag-only call per eligible type (`selector.filters.tags_any: ["workbench"]`, `hydrate: false`) and merges the results. A single-type result is incomplete by construction and must not be presented as the full workbench.

**No startup behavior change:** this rule governs *how* a Workbench listing is performed *if and when one is requested*. It does **not** add a Workbench listing to `/wake` or any startup sequence (§1.2/§1.3 are unchanged). Wiring an automatic startup listing, or a future single-call `artifact.search` primitive (T210), is out of scope for v2.2 and would require its own change under the T212 gate.

### 9.6 Validation expectations
A correct implementation satisfies: (1) a saved end-session snapshot's `tags` contain no `workbench`; (2) a saved end-session snapshot uses the canonical `session-end` tag; (3) `active_workbench[]` may still appear in that snapshot's payload; (4) a Workbench inventory (all eligible types, tag-only) shows no end-session/end-subsession/closeout leakage; (5) "workbench this" on a live artifact still adds the tag; (6) any Workbench listing enumerates all eligible types; (7) no `/wake` or startup step is required to list the Workbench.

---

*CHANGELOG:*

*v2.3 (2026-06-10): Restores retrieval-side alignment with v2.2 §5.1 save-side canonical `session-end` tag by introducing two-query client-side union retrieval, expressed as **substeps** to preserve existing step numbering and §2 cross-references. §1.2 Step 2 expands into substeps 2a (canonical-tag query, `tags_any: ["session-end"]`, hydrate: true, K=3), 2b (BLOCK canonical), 2c (transitional-tag query, `tags_any: ["end-session"]`, hydrate: true, K=3), 2d (BLOCK transitional). §1.2 Step 4 body updates to the merge-and-absorb algorithm: union by `artifact_id` (dedupe single-record for both-tag artifacts), sort by `created_at` DESC (recency authority — not `updated_at` or `version`), tiebreaker `artifact_id` ASC, define schema-valid bookmark per §5.2/§5.3, scan top-down for first schema-valid candidate, invalid-latest handling (use older valid + session-note observation; not silent burial), tag-source classification (canonical / transitional / both / canonical-plus-transitional), K=10 bounded retry per query (up to 20 pre-dedupe candidates), §6 Failure Handling escalation on persistent schema-invalidity, genuine-absence handling distinct from schema-invalidity. §1.2 Steps 1, 3, 5, 6, 7 unchanged; Step 8 verbatim report gains conditional slot `[ (transitional tag)]` triggered by transitional tag-source. §1.3 Step 4 expands into substeps 4a (canonical, hydrate: false, K=3) and 4b (transitional, hydrate: false, K=3). §1.3 Step 5 body updates to BLOCK + merge + absorb spine-only (mirrors §1.2 Step 4 algorithm with spine-only schema validation). §1.3 Steps 1, 2, 3, 6, 7 unchanged; T185 fallback handler at §1.3 Step 7 (daily-orientation lookup) unchanged verbatim. §1.3 Step 8 verbatim report gains the same conditional `[ (transitional tag)]` slot. New §1.8 documents transitional posture, K semantics, recency authority, transitional observation telemetry (session note always + verbatim startup-report slot always; not framed as failure when schema-valid bookmark found; does not authorize historical re-tagging), invalid-latest handling, and narrowing trigger (N=5 consecutive new End Session **saves** across Prime + Q@W carry `session-end` and zero carry `end-session` — save-side emission, not retrieval-side selection — AND ≥30 days since landing AND Q@W parity). §1.8 also explicitly confirms §4.4 contains no retrieval payload and only consumes already-loaded bookmark state. §2 Startup Context Absorption gains one clarifying sentence on tag-source classification; step-number references preserved. §4.4 body unchanged. **Save-side canonical tag (§5.1) frozen at `["session-end", "for-q"]`. No historical re-tagging. §5.1a workbench tag exclusion, §5.2/§5.3 `active_workbench[]` field, §5.4 immutability, §4.3 save sequence, Workbench (§9) doctrine, §3 CmdCtr Session Context Briefing, T185 fallback handlers (§1.5, §1.3 Step 7, §1.7), §6 Failure Handling base structure, §7 Crawl Phase Constraints, §8 Surface Rendering, payload shapes, `schema_version`, DB schema, DDL, Gateway actions, RLS, Morning Flow v2 doctrine references all unchanged.** T212 gate: Manus TQR Amend (A1–A10 applied); Q approve with one wording polish in §1.8 (future-collapse evaluation, applied) and parallel §1.8 sister-thread coordination wording polish (applied); Joel approval (applied). Authorizing lane: project `46142606-ac00-416c-95a0-2e81e997b9e4` (Session Lifecycle / End Session Schema — Governance Lane). Driven by: G coordination flag from Rolling Memory v16 cleanup 2026-06-10 — 2026-06-09 end-session snapshot `36e86798-0074-4ad2-b957-b86b39033543` tagged `end-session` while v2.2 §5.1 canonical is `session-end`; canonical-only retrieval silently returned older snapshot. Empirical Gateway behavior recorded in sister twig `b14f8027-5ab9-4010-a4f0-ab9461f79599` (Gateway v2 `tags_any` returns intersection not union) — structural reason for client-side union rather than dual-tag broadening; sister thread evidence-only and does NOT block this patch. Related downstream work: Session Receipt Ledger branch `dd702a7f-9113-43ee-ab9f-cea1fdedacc0` (End Session Search Enrichment, parented under governance lane). Archived: `Archive/Instruction_Pack__Session_Lifecycle__v2.2__2026-06-10.md`. IP Index reference: v19 → v20.*

*v2.2 (2026-06-07): Adds Workbench (Working Set) doctrine as new §9 (definition; what-it-is-not; curated-not-automatic; eligible types project/snapshot/restart/twig, with restart eligible only as a deliberately-authored live resume handle and snapshot excluding end-session/end-subsession/session-closeout; retrieval enumerates all eligible types; validation expectations). Adds §5.1a workbench tag exclusion for session-close snapshots. Documents the already-emitted `active_workbench[]` payload field in §5.2/§5.3 as a session-close receipt — payload documentation only: no DB schema change, no schema-version bump, no Gateway change. Canonicalizes §5.1 session-close spine tag `["end-session","for-q"]` → `["session-end","for-q"]` (CD-1; bounded terminology alignment; no historical retagging; no retrieval/Gateway change). §4.3 step 4 gains a cross-reference to §5.1a. No startup behavior change (§1.1–§1.7, §2, §3 startup paths unchanged); no change to §6, §7, §8, payload shapes, or Morning Flow v2 doctrine. T212 gate: Manus TQR approve-with-amendments + final shape approval; Q approved with CD-1. Source: Workbench Purpose and Process Revision sapling `c75c4dbe-987d-43ed-a126-65f3222179d2`; TQR Synthesis `d89c9395-ea35-41ed-b161-dd18c770ab0a`; Correction — Workbench Tagging Root Cause `a067ec42-b4e0-4931-acde-ab075c636200`. Archived: `Archive/Instruction_Pack__Session_Lifecycle__v2.1__2026-06-07.md`. IP Index reference: v18 → v19.*

*v2.1 (2026-05-08): Adds T185 fallback handlers scoped to two specific daily-orientation lookups: §1.5 (Post-startup Morning Flow integration, Primary) and §1.3 Step 7 (Subsession startup). Both handlers fire only when (1) QSB returns a known T185 zero-result signature (empty HTTP body, `"Unexpected end of JSON input"`, or equivalent) AND (2) the failed request matches the exact daily-orientation lookup payload context for that section. Outcomes differ by mode: Primary §1.5 prompts full Morning Flow v2 per snapshot `68949bee-9651-4493-9a40-f454a2302b35`; Subsession §1.3 Step 7 records `intention: none-today`, continues lightweight startup, and renders `Today's intention: none yet` in the Step 8 report — does NOT start Morning Flow. Neither handler triggers §6 Failure Handling, retries the lookup, or applies outside its named lookup context. New §1.7 captures the shared scope guardrail: handlers are instruction-pack mitigation only; do NOT close T185 at the Gateway level; do NOT generalize to End Session, Rolling Memory, CmdCtr, or other artifact.list calls; do NOT normalize generic QSB JSON parse errors. T185 remains an active Gateway defect; this is instruction-layer mitigation only. No change to §1.1, §1.2, §1.3 Steps 1–6 or Step 8, §1.4, §1.6, §2–§8, payload shapes, startup triggers, or Morning Flow v2 doctrine references. Source: real-time T185 propagation observed 2026-05-08 on first Primary `/wake` under IP v2 (no `daily-orientation` snapshot existed yet); Manus reviews 2026-05-08 (round 1: extend scope to §1.3 Step 7; round 2: strict context scoping, mode-differentiated outcomes, no Gateway-level claim, Markdown fence integrity, validation-language correction; round 3: final approval). Mirrors Q@W IP v2 first-wake fallback pattern. Archived: `Archive/Instruction_Pack__Session_Lifecycle__v2__2026-05-08.md`. IP Index reference: v16 → v17.*

*v2 (2026-05-07): Adds Primary vs Subsession startup mode distinction. §1.1 trigger recognition split into Branch A (Primary, current trigger list) and Branch B (Subsession: `/new sub`, `new sub`, `nsub`, `sub`); Branch C (no trigger) preserved. §1.2 renamed Primary deterministic startup; 8-step sequence unchanged; closes by referencing §1.5. §1.3 (new) Subsession lightweight startup: Rolling Memory full hydration, End Session header (no hydration), today's Daily Morning Flow `intention_short_phrase`, then ready report. §1.4 (renumbered from prior §1.3) Blocking enforcement now applies to both modes. §1.5 (new) Post-startup Morning Flow integration (Primary only): queries today's Daily Morning Flow output via `tags_any: ["daily-orientation"]`; branches on `run_date` match (resume offer) or absent/older (full Morning Flow v2 prompt). §1.6 (renumbered from prior §1.4) unchanged. §2 updated with subsession context absorption order. §5.3 `session_scope` rule updated with §1.1 trigger mapping. §6.3 expanded to include Daily Morning Flow output saves. §3, §4, §5.1, §5.2, §5.4, §7, §8 unchanged. Doctrine references: Operating Protocol — Morning Flow v2 (`68949bee-9651-4493-9a40-f454a2302b35`) and Addendum — Morning Flow v2 Daily Output and Idempotency Rule (`38e6c958-9715-4a27-ab73-7756bbfd991c`). Archived: `Archive/Instruction_Pack__Session_Lifecycle__v1__2026-05-07.md`. IP Index reference: v15 → v16.*

*v1 patch (2026-04-24, same-day): Explicit QSB format enforcement via reference to `Instruction_Pack__QSB_Payload_Format__v3.md` in §1.2 Step 2 and Step 5; clarified literal `prime-exec` requirement (must appear in Q's output, not just documentation). Bare JSON explicitly marked invalid. No logic change. Example blocks unchanged. Archived pre-patch snapshot: `Archive/Instruction_Pack__Session_Lifecycle__v1__2026-04-24.md`.*

*v1 (2026-04-24): Supersedes `Instruction_Pack__CmdCtr_Session_Context__v1.md`. Adds Session Lifecycle Protocol v1 (Crawl Phase): trigger recognition, deterministic 8-step startup retrieval, blocking enforcement, pre-init substantive input rule, End Session Protocol, End Session Snapshot schema v1, failure handling (3-option block), crawl phase constraints. CmdCtr Session Context v1 content preserved verbatim as §3. Archived predecessor: `Archive/Instruction_Pack__CmdCtr_Session_Context__v1__2026-04-24.md`. IP Index reference: v14 → v15 (swap CmdCtr entry for Session Lifecycle entry).*
