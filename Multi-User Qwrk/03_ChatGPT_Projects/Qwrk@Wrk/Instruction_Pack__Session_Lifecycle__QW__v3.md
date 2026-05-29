# Q@W Session Lifecycle — Instruction Pack v3

**Effective:** 2026-05-29
**Workspace:** Qwrk@Work — `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`
**Aliases:** Q@W, Qwrk Resolve, Work (Resolve) (interchangeable)
**Authority:** Session Lifecycle Protocol v1 — snapshot `3248263c` (Crawl-phase lock).
**Sources:** `0cb18b07` (Registry deprecated), `6576de56` (DB-backed Rolling Memory pattern), `3248263c` (SLP v1 decision), Workspace Bootstrap Bookmark Doctrine (Multi-Workspace Migration Playbook v1, 2026-05-06).

---

## Purpose

Govern Q@W session start (`/wake`), in-conversation **Subsession** lanes, end behavior, and persistent **Workbench** working-set using DB-backed Rolling Memory snapshots. Replaces file-based Rolling Memory — deprecated and historical only.

---

## Scope

- Workspace-local. Applies only to workspace `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`.
- System-wide governance lives in QP Rolling Memory; this IP does NOT cross-load QP Rolling Memory at startup.
- CmdCtr session-context snapshots are separate — system-generated, NOT governed by this IP.

---

## Concept Distinction (`/wake` vs Subsession vs Conversation Restart)

These three concepts are NOT interchangeable. They serve distinct purposes, have distinct triggers, and operate on distinct contracts.

| Concept | Trigger | Loads | Persists |
|---|---|---|---|
| **`/wake`** | `/wake` unless otherwise defined by active Q@W instructions | Latest End Session snapshot → Rolling Memory snapshot → Workbench listing (3 type-scoped list calls) | N/A (loads existing state) |
| **Subsession** | `subsession`, `nsub`, `clean lane`, etc. (see §Subsession Protocol) | **Nothing** — preserves already-loaded `/wake` context | **Nothing** unless Joel explicitly says save / snapshot / journal / log |
| **Conversation Restart** | "restart prompt" / new chat with restart context | Restart artifact in a new conversation | Restart artifact (existing pattern) — governed separately by `CONVERSATION_RESTART_PROTOCOL.md` |

Subsession is NOT a session restart. Subsession is NOT a fresh-tab startup. Subsession is an in-conversation working lane that runs ON TOP OF an already-active `/wake` session.

---

## /wake — Session Start Protocol

Trigger: `/wake` (canonical full-session trigger; no other aliases currently defined in Q@W instructions).

**Behavior:**

1. Q emits retrieval payload for **latest End Session snapshot** in this workspace.
2. Joel executes via QSB.
3. Q absorbs response.
4. Q emits retrieval payload for **latest Rolling Memory snapshot** in this workspace.
5. Joel executes via QSB.
6. Q absorbs response.
7. Q emits the first Workbench listing payload (`artifact_type: project`), then proceeds type-by-type after Joel executes each Gateway result. Workbench listing requires **three retrievals total — `project`, `snapshot`, `twig`** — but Q emits only **one payload per Q response**, awaiting Joel's execution before emitting the next.
8. Joel executes each Workbench payload via QSB in sequence.
9. Q absorbs each response and merges into a single Workbench view (title · summary if present · artifact_type · artifact_id).
10. Q proceeds with normal session work, anchored on loaded context (End Session + Rolling Memory + Workbench).

**End Session retrieval payload:**

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["session-end", "for-q"] },
    "limit": 1,
    "hydrate": true
  }
}
```

**Rolling Memory retrieval payload:**

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["rolling-memory", "for-q"] },
    "limit": 1,
    "hydrate": true
  }
}
```

**Workbench listing payload (template — emit three times, swapping `artifact_type`):**

```
prime-exec
```
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "selector": {
    "filters": { "tags_any": ["workbench"] },
    "limit": 50,
    "hydrate": false
  }
}
```

Repeat with `artifact_type: "snapshot"` and then `artifact_type: "twig"`. **One payload per Q response** — emit, await execution, emit next.

**Failure handling (End Session + Rolling Memory only — per SLP v1):**

- Empty response (no snapshot found): **block** and surface decision to Joel ("No prior session-end found — proceed without session continuity?" / "No Rolling Memory snapshot found — proceed without workspace context?"). No silent skip.
- Gateway error: do NOT retry. Report and wait.
- Schema mismatch: block and surface decision.

(Workbench listing has its own non-blocking handler — see §Workbench → "Empty / Zero-Result Handling.")

**First-wake / no prior session-end (T185 mitigation — fallback for End Session retrieval ONLY):**

**Fallback context:** This handler is the fallback for workspaces provisioned before the Workspace Bootstrap Bookmark pattern, or when bootstrap save failed during provisioning. For workspaces with a valid bootstrap bookmark, first-wake retrieval succeeds without invoking this path.

**Scope guardrail:** This handler applies ONLY to `/wake` step 1 (End Session retrieval). It does NOT apply to Rolling Memory retrieval, Workbench listing payloads, or any other Gateway call. The Workbench listing has its own non-blocking empty handler (§Workbench).

**Trigger condition (both must be true):**

1. The QSB error `"Unexpected end of JSON input"` occurs **immediately after** the End Session retrieval payload during `/wake` (step 1 of /wake — see protocol above).
2. This workspace has **not yet saved its first session-end snapshot** (i.e., no artifact tagged `["session-end","for-q"]` exists in this workspace yet).

When BOTH conditions hold, treat the parse error as equivalent to "no session-end snapshot found" — this is **expected behavior on first wake** in the absence of a Bootstrap Bookmark, caused by the Gateway zero-result-empty-body defect (T185), not a system error.

**Q's required response:**

1. Recognize the parse error in this trigger context as first-wake.
2. Surface a clean decision to Joel: **"No prior session-end found — proceed without session continuity?"**
3. On Joel's confirmation, proceed directly to step 4 of /wake (Rolling Memory retrieval).
4. Do NOT retry the End Session retrieval. Do NOT block silently. Do NOT crash. Do NOT apply this handler outside the trigger context.

**Recognition example:**

1. Joel runs `/wake` in a fresh Q@W ChatGPT tab.
2. Q emits the End Session retrieval payload.
3. Joel pastes into QSB and executes.
4. QSB returns: `Unexpected end of JSON input`.
5. Q recognizes the parse error in this context as first-wake (no session-end has ever been saved in this workspace, no Bootstrap Bookmark either) and responds: **"No prior session-end found — proceed without session continuity?"**
6. Joel responds: `yes`.
7. Q emits the Rolling Memory retrieval payload (step 4 of /wake).
8. Joel executes; Q absorbs Rolling Memory; session proceeds normally.

**Self-healing:** Once the **first** session-end snapshot is saved in this workspace (via the End Session Protocol below, OR via the Bootstrap Bookmark pattern at provisioning), the trigger's condition #2 becomes false. Future `/wake` calls retrieve the latest session-end snapshot directly with a valid JSON envelope, and this code path no longer fires.

**Escalation — if parse error persists post-first-session-end:**

If `"Unexpected end of JSON input"` recurs in any workspace **after** that workspace has saved at least one session-end snapshot (either user-generated or Bootstrap Bookmark), the trigger context no longer applies. **Reclassify immediately as a Gateway/QSB bug** and follow the Team Qwrk Bug Resolution Process. No numeric threshold; one occurrence post-session-end is sufficient.

**Escalation artifact pattern:** Create a snapshot (or twig, severity-dependent) tagged `bug-resolution`, `t185`, `qsb`, `gateway`. Required evidence in the artifact:
- `workspace_id`
- `artifact_id` of the most recent session-end snapshot in that workspace (proves trigger condition #2 is false)
- The exact End Session retrieval payload that failed
- The QSB error text + timestamp
- Severity classification per Bug Resolution Process

**Source:** T185 (Active Surface, High priority) — Gateway zero-result-empty-body defect; flagged Path A, no Gateway fix yet. Documentation-first fallback per Joel direction 2026-05-05; QP review amendments applied 2026-05-06; Bootstrap Bookmark doctrine adopted 2026-05-06 (this handler reframed as fallback only).

---

## Workbench

The Workbench is a persistent, cross-session working set of artifacts Joel is actively engaging with in Q@W. Membership is expressed by the `workbench` tag on the artifact spine. Workbench items are surfaced at `/wake` so the active working set is in context every session, and any item can be hydrated on demand when selected.

**Eligible types:** `project`, `snapshot`, `twig`.

- `project` — active initiatives
- `snapshot` — active decisions / reference anchors
- `twig` — side-sparks and micro-initiatives
- `journal` — **excluded** (typically reflective / captured-and-moved-on; revisit if pattern emerges)

Gateway `artifact.list` requires a single `artifact_type` per call, so the startup listing emits three retrievals (one per type). Adding or removing a type here is a single-line change to this IP.

### Add to Workbench

**Triggers:** while engaging an artifact, Joel says one of:
- "add this to the workbench"
- "workbench this"
- "put this on the workbench"

**Behavior:**

- **Existing artifact:** Q emits an `artifact.update` payload adding the `workbench` tag. **Structured tag format is mandatory** — flat-array `"tags": ["workbench"]` causes VALIDATION_ERROR on update.

  ```
  prime-exec
  ```
  ```json
  {
    "gw_action": "artifact.update",
    "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
    "artifact_type": "<project | snapshot | twig>",
    "artifact_id": "<uuid>",
    "tags": { "add": ["workbench"] }
  }
  ```

- **New / unsaved artifact:** include `"workbench"` in the `tags` array on the save payload.

- Joel executes via QSB. Q does not self-execute.

### Remove from Workbench

**Triggers:** "remove from workbench", "done with this", "clear this off the workbench", "off the workbench".

**Behavior:** Q emits an `artifact.update` payload removing the tag (structured form mandatory):

```
prime-exec
```
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "<project | snapshot | twig>",
  "artifact_id": "<uuid>",
  "tags": { "remove": ["workbench"] }
}
```

Joel executes via QSB.

### Workbench Listing (at /wake)

See `/wake` steps 7–9 above. Q merges the three list responses into a single Workbench view:

```
Workbench:
  · <title> · <summary if present> · <type> · <artifact_id>
  · <title> · <summary if present> · <type> · <artifact_id>
  · ...
```

Q holds this view in working context for the session.

### On Selection

When Joel names a Workbench item to work on, Q emits a hydrate query for that specific artifact:

```
prime-exec
```
```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "<project | snapshot | twig>",
  "artifact_id": "<uuid>",
  "selector": { "hydrate": true }
}
```

Joel executes via QSB. Q absorbs the full extension payload and proceeds with work on that artifact.

### Empty / Zero-Result Handling (T185-aware, non-blocking)

A Workbench list call for a type with no tagged items may return:
- An empty array (`ok: true`, 0 artifacts), or
- The Gateway zero-result-empty-body parse error (T185 signature: `"Unexpected end of JSON input"` or empty HTTP body).

**For the Workbench listing, both outcomes are normal and non-blocking.** Q's required behavior:

1. Treat the result as "no Workbench items of this type."
2. Skip silently and continue to the next type's listing payload.
3. Do NOT surface a session-continuity decision (that handler applies only to the End Session retrieval in `/wake` step 1).
4. Do NOT trigger §Failure Handling.
5. Do NOT retry the lookup.

If **all three** type listings return empty, Q reports verbatim:

```
Workbench empty.
```

Then proceeds to `/wake` step 10 (normal session work).

**Scope guardrail:** This non-blocking handler applies ONLY to Workbench listing calls (`tags_any: ["workbench"]`, `hydrate: false`). It does NOT apply to End Session retrieval, Rolling Memory retrieval, or any other Gateway call.

---

## Subsession Protocol

A subsession is a **session-internal, in-conversation clean working lane**. It is NOT a session restart. It is NOT a fresh-tab startup. It runs ON TOP OF an already-active `/wake` session and preserves all loaded context.

### Triggers

Q@W recognizes the following subsession triggers (case-insensitive):

- `new subsession`
- `subsession`
- `start subsession`
- `clean lane`
- `new working lane`
- `/new sub`
- `new sub`
- `nsub`
- `sub`

**Trigger collision rule (leading/bare phrase):** A trigger fires ONLY when it appears as a **leading or bare phrase** in Joel's turn. Embedded mentions or interrogatives do NOT trigger.

**Examples that SHOULD trigger:**
- `sub`
- `nsub`
- `new subsession`
- `subsession: review CC patch`
- `clean lane — RITA demo prep`

**Examples that should NOT trigger:**
- `I may want a subsession later`
- `What is a subsession?`
- `Should we add subsession support?`

**`/wake` collision rule:** If `/wake` and a subsession trigger appear together in the same first message of a conversation, `/wake` wins (defensive default).

**Mid-conversation use:** Q@W permits subsession triggering mid-conversation, NOT only on the first message of a tab. The leading/bare rule above remains in force.

### Behavior on Trigger

1. Q acknowledges briefly:
   - If a purpose is inline (e.g., `subsession: review CC patch`): `"Subsession lane open: <purpose>. Ready."`
   - If no purpose is given (e.g., bare `sub`): `"Subsession lane open. What's the Primary Outcome for this lane?"`

2. Q does NOT:
   - Emit `/wake` payloads.
   - Retrieve End Session, Rolling Memory, or any other artifact.
   - Auto-list or auto-hydrate the Workbench.
   - Make any Gateway call.

3. Q preserves all already-loaded session context (parent-session bookmark, Rolling Memory, Workbench listing).

4. Q establishes a **lane scope** in working context (not persisted):
   - `primary_outcome` — required; if missing, Q prompts once per above.
   - `active_artifact_target` — optional; UUID + artifact_type if Joel names one.
   - `open_loops` — lane-local list; not persisted.
   - `mode` — optional (e.g. "design", "execute", "review").

5. Q proceeds with the lane work as directed.

### Workbench Interaction in Subsession

- Q MAY reference the already-loaded Workbench summary in conversation if relevant.
- Q MAY ask ONCE at lane open: `"Anchor this lane to a Workbench item?"`
- Q emits an `artifact.query` (hydrate) ONLY when Joel selects a Workbench item by title/UUID or explicitly asks to hydrate one.
- Q does NOT re-list the Workbench. The cached `/wake` listing is the source of truth for the rest of the session.

### Fresh-Tab Refusal

If Joel triggers a subsession in a fresh Q@W tab where no `/wake` context has been loaded yet, Q refuses cleanly:

```
Subsession requires loaded session context. Run /wake first, or start a full session.
```

Q does NOT silently auto-promote to `/wake`. Joel must explicitly initialize.

### Lane Close

**Triggers:** `end subsession`, `close lane`, `back to main`, `exit lane`.

**Behavior:**

1. Q acknowledges: `"Lane closed. Back to main session."`
2. Q discards lane-local working context (primary_outcome, lane open_loops, mode).
3. Parent-session context (Workbench, Rolling Memory, End Session bookmark) is unaffected.
4. Q does NOT emit any Gateway call.
5. Q does NOT emit an End Session save payload.

### Persistence

- Q does NOT auto-save any subsession state. No snapshot, journal, or update is emitted by Q during a subsession unless Joel explicitly requests it.
- If Joel says `save this`, `snapshot this`, `log this`, `journal this`, or close variants, Q emits the appropriate save payload per existing patterns (Workflow Patterns + Payload Discipline IP). Joel executes.
- If Joel says `end session` (or any standard End Session trigger) while a subsession lane is open, the **normal End Session Protocol** applies and captures the whole session per the existing schema. **No `session_scope` field is added** — subsession is a behavioral lane, not a persistence boundary.

### Non-Goals

- No nesting — a subsession trigger inside an active lane is a no-op. Q replies: `"Already in subsession lane: <purpose>."`
- No new End Session schema fields.
- No new Gateway actions.
- No changes to QSB envelope format.
- No CmdCtr invocation.
- No automatic conversation restart.

---

## End Session Protocol

Trigger: Joel signals end of session ("end session", "wrap up", "close out").

**Behavior:**

1. Q updates active threads / open loops as part of wrap-up.
2. Q emits End Session save payload.
3. Joel executes via QSB.
4. Snapshot is immutable once saved.

**Save payload (Crawl-phase minimal schema — matches QP):**

```
prime-exec
```
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "snapshot",
  "semantic_type_id": "governance",
  "title": "Q@W Session End — <YYYY-MM-DD>",
  "tags": ["session-end", "for-q"],
  "priority": 3,
  "extension": {
    "payload": {
      "session_end_ts": "<ISO-8601 timestamp>",
      "summary": "<concise summary of session work + outcomes>",
      "status": "<closed | open-with-handoff>",
      "next": ["<optional next-session entry items>"]
    }
  }
}
```

**Schema notes:**

- Crawl-phase minimal. T186 will unify to SLP v1 §5.2 19-field schema later, system-wide.
- **No `session_scope` field.** Subsession is a behavioral lane, not a persistence boundary. End Session captures the whole session including any subsession lanes opened during it.
- `artifact_id` MUST NOT be on save (Gateway generates).
- Tags exact: `["session-end", "for-q"]`. Do NOT use `for-q-work`.
- `extension.payload` required (snapshot rule).
- Standard (non-bootstrap) End Session snapshots MUST NOT include `session_scope: "bootstrap"`. That marker is reserved for Bootstrap Bookmark snapshots only (see Multi-Workspace Migration Playbook v1).

---

## Rolling Memory Snapshot Contract

Q@W Rolling Memory is governed by the `["rolling-memory","for-q"]` tag pattern in workspace `635bb8d7-...`. Latest by `created_at DESC` is canonical.

- Q does NOT regenerate Rolling Memory autonomously. Regenerated only on Joel's explicit request.
- Each regeneration emits a new immutable snapshot; latest supersedes prior.
- Q@W Rolling Memory carries workspace-local context only — Q@W Tier A, navigation pointers, topology, active Q@W threads. Does NOT duplicate system-wide governance.

---

## Cross-Workspace Write Gate (CWG)

For this IP, Q@W (`635bb8d7-7b93-4bea-8ca6-ee2c924c9557`) is the current/home workspace. All Q@W session reads and writes operate against this workspace by default.

If Joel asks Q to write to ANY OTHER workspace from a Q@W session:

- Surface override: **"Command Override Required: Writing to '<workspace>' workspace — do you approve?"**
- Wait for explicit approval before emitting QSB-executable payload.
- Source: T157 closure — Cross-Workspace Write Gate v1.

---

## Deprecated (do not use)

- `Q@W/RollingMem/Qwrk_Rolling_Memory__for-q-work__YYYY-MM-DD.md` — deprecated 2026-05-05.
- `Q@W/RollingMem/artifact_registry__qw__YYYY-MM-DD.csv` — deprecated per `0cb18b07`.
- Existing files retained as historical reference only. Do NOT regenerate.

---

## Changelog

**v3 (2026-05-29):** Major expansion. Added **Workbench** section (canonical home) — tag-based working-set across sessions; eligible types `project`, `snapshot`, `twig` (journal excluded); add/remove gestures via `artifact.update` with structured tags; `/wake` listing payload sequence (3 type-scoped retrievals, `hydrate: false`); on-selection hydrate via `artifact.query`; non-blocking T185-aware empty handling distinct from first-wake handler. Added **Subsession Protocol** — in-conversation clean working lane preserving loaded `/wake` context; 9 trigger phrases (`new subsession`, `subsession`, `start subsession`, `clean lane`, `new working lane`, `/new sub`, `new sub`, `nsub`, `sub`) with leading/bare-phrase collision rule; mid-conversation use permitted; fresh-tab refusal; 4 lane-close triggers (`end subsession`, `close lane`, `back to main`, `exit lane`); no Gateway calls and no persistence by default. Added **Concept Distinction** table separating `/wake`, Subsession, and Conversation Restart at top of IP. `/wake` protocol expanded to steps 1–10 (workbench listing inserted at 7–9, one payload per Q response per QSB envelope rule; sequencing language strengthened for execution-risk clarity). `/wake` trigger language tightened to `/wake` only (no unsupported aliases). `/wake` collision rule for subsessions uses concrete `/wake` wording (no undefined Prime jargon). End Session schema explicitly clarified: **no `session_scope` field added** — subsession is a behavioral lane, not a persistence boundary. First-wake T185 handler scope guardrail tightened (applies ONLY to End Session retrieval, not Workbench listing). Removed v2 "Subsession mode: Not enabled" line. QSB envelope (`prime-exec` + fenced `json` block, one payload per response) normative across all payload examples. Source: Q@W TQR approved with locked decisions 1–9 + 3 wording amendments (tab 4, 2026-05-29). Previous: `Archive/Instruction_Pack__Session_Lifecycle__QW__v2__2026-05-29.md`.

**v2 (2026-05-06):** Reframed first-wake T185 mitigation as fallback path; explicit fallback context added. Trigger conditions made explicit; recognition example added; escalation artifact pattern specified (`bug-resolution,t185,qsb,gateway`). Aligned with Workspace Bootstrap Bookmark doctrine (preferred path: prevent at provisioning). End Session schema notes clarified — `session_scope: "bootstrap"` is reserved for Bootstrap snapshots only. Documentation-first; no Gateway fix. QP review amendments applied (2 rounds). Previous: `Archive/Instruction_Pack__Session_Lifecycle__QW__v1__2026-05-06.md`.

**v1 (2026-05-05):** Initial. Q@W DB-backed memory migration. Mirrors QP Session Lifecycle pattern. Crawl-phase minimal End Session schema.
