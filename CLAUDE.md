# CLAUDE.md

> **PROTECTED FILE — DO NOT DELETE OR EDIT WITHOUT CONSENT**
>
> This file is critical project infrastructure. Claude Code MUST:
> - **NEVER** delete this file under any circumstances
> - **NEVER** edit this file without explicit user consent in the current conversation
> - **IMMEDIATELY STOP** and alert the user if this file is missing or corrupted
>
> A git pre-commit hook blocks deletion. Bypass requires `--no-verify` (emergency only).

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Last verified against live system:** 2026-04-05 · **Gateway:** v2 (build 4) · **DDL:** v2.10 · **Last reconciliation:** 2026-04-05

## Instruction File Drift Rule

If any of the following change, CLAUDE.md must be updated in the same session:

- Gateway version
- Supported Gateway actions
- Artifact types in CHECK constraint
- DDL version
- Truth hierarchy version references

No architectural or governance edits may be made during drift reconciliation. This file must reflect reality, not aspiration.

## Project Overview

**Qwrk V2** (New Qwrk Kernel) - A workspace-first, artifact-centric system built on Supabase with n8n workflow automation for gateway operations.

### Core Architecture

**Backend: Supabase Kernel v1**
- Database: PostgreSQL with Row Level Security (RLS) enabled on all tables
- Project ref: `npymhacpmxdnkqdzgxll`
- Authentication: Supabase Auth integrated with custom user mapping

**Gateway Layer: n8n Workflows (v2)**
- Workflow: `NQxb_Gateway_v2` handles all artifact and messaging operations (v1 decommissioned 2026-03-26)
- Implements: `artifact.save`, `artifact.query`, `artifact.list`, `artifact.update`, `artifact.promote`, `artifact.delete`, `artifact.restore`, `artifact.list_deleted`, `messaging.send_email`, `messaging.create_calendar_event`

### Database Schema Architecture

**Class-Table Inheritance Pattern:**
- `qxb_artifact` is the canonical "spine" table containing all core artifact fields
- Type-specific tables extend via PK=FK relationship:
  - `qxb_artifact_project` - lifecycle + operational state tracking
  - `qxb_artifact_journal` - owner-private text/payload storage
  - `qxb_artifact_snapshot` - immutable jsonb payload
  - `qxb_artifact_restart` - immutable jsonb payload
  - `qxb_artifact_video` - long-form media with transcripts/insights
  - `qxb_artifact_grass` - operational issue tracking
  - `qxb_artifact_thorn` - exception tracking
  - `qxb_artifact_instruction_pack` - instruction pack storage
  - `qxb_artifact_limb` - shell extension for execution anatomy (Phase 2)
  - `qxb_artifact_person` - identity, contact, professional, interaction tracking (T150)
- `qxb_artifact_event` - append-only audit log (protected by triggers)

**Core Tables Dependency Order:**
1. `qxb_user` (maps Supabase auth to Qwrk identity)
2. `qxb_workspace` (every artifact requires workspace_id)
3. `qxb_workspace_user` (role-based membership: owner/admin/member)
4. `qxb_artifact` (spine)
5. Type tables + event log

**Artifact Types (CHECK v8 — 15 types):**
- `project` - lifecycle_stage: seed → sapling → tree → archive
- `journal` - owner-private reflective entries (RLS: owner-only)
- `snapshot` - immutable lifecycle snapshots
- `restart` - manual session continuation artifacts
- `grass` - operational issue tracking
- `thorn` - exception tracking
- `branch` - execution anatomy (North Star v0.4)
- `leaf` - execution anatomy (North Star v0.4)
- `limb` - execution anatomy (North Star v0.4, Phase 2)
- `instruction_pack` - instruction pack storage
- `person` - real individuals in operator's network (T150, full extension table)
- `forest`, `thicket`, `flower` - in CHECK constraint; no extension tables
- `twig` - experimental micro-initiative (T94, pilot: Mother Tree)

### Row Level Security (RLS) Model

**Critical RLS Rules:**
- All tables have RLS enabled (deny-by-default)
- Helper function: `qxb_current_user_id()` maps `auth.uid()` → `qxb_user.user_id`
- Workspace visibility: users see only workspaces where they have membership
- Artifact visibility: workspace members can read (except journals = owner-only)
- Type table policies delegate to `qxb_artifact` spine

**Access Control Model — Qwrk v2 (Decision locked 2026-03-22, T150):**
- Gateway (n8n) is the **primary access control layer**, using `service_role` credentials
- `service_role` **bypasses RLS by design** — database RLS is not enforced at runtime
- RLS policies exist for: structural correctness, defense-in-depth, future JWT-based access
- `qxb_current_user_id()` returns NULL in SQL Editor / service_role context — this is expected
- Testing RLS enforcement requires an authenticated JWT context (not SQL Editor)
- **Future:** if PostgREST or direct client access is introduced, validate RLS with real JWT context

### n8n Gateway Workflow Rules

**Hard Rules (CRITICAL - DO NOT VIOLATE):**

1. **Expression syntax:** DO NOT type a leading `=` in n8n expressions; n8n adds it automatically
2. **Supabase nodes are dumb column writers:** Flatten payloads before DB nodes; don't auto-map wrapped payloads
3. **Node naming discipline:** Use `Qxb`-prefixed names consistently
4. **Switch comparison safety:** Guard against hidden whitespace/newlines using `.trim()`
5. **No guessing:** Do not guess schemas, enums, endpoints, or commands. Stop and ask for canonical source if unclear.
6. **No manual expression edits:** Do NOT edit n8n expressions directly in the UI for production workflows. All expression changes must go through a build script or auditable patch artifact that verifies intended-diff-only. Manual UI edits require explicit Joel approval. Source: T165 (`3def7e3b`).

### Next-Touch Hardening Check

Before modifying any of the following workflows:
- NQxb_Artifact_Save_*
- Update sub-workflows (T140+)
- Query sub-workflows

You MUST:

1. Search for artifacts tagged:
   - "hardening"
   - "next-touch"

2. Review any matching twigs or snapshots

3. Determine whether a required hardening fix applies to the workflow being modified

4. If applicable:
   - Include the hardening fix in the same change set
   - OR explicitly document why it is being deferred

This check is mandatory and must occur before implementation begins.

Rationale: Prevents known non-blocking defects from persisting due to lack of recall. Source: T165 risk sweep (2026-03-29).

**Gateway Architecture:**
- **Spine-first pattern:** Fetch `qxb_artifact` by `workspace_id + artifact_id` first
- **Type validation:** Compare requested `artifact_type` vs stored type using `compare_key` / trim-safe logic
- **Type branching:** Route to type-specific extension table based on stored `artifact_type`
- **Response merging:** Strip redundant `artifact_type` from extension payload before merge

### Workflow Deployment Checklist (CRITICAL)

When updating ANY sub-workflow called by Gateway (Save, Query, List, Update, Promote):

1. **Archive current version** to `workflows/Archive/`
2. **Apply fix and save** with incremented version number (e.g., `(24)` → `(25)`)
3. **Update Gateway workflow** — The Gateway's "Execute Workflow" node must point to the new version
   - Example: If Save goes from `(24)` → `(25)`, update `NQxb_Gateway_v2` node `call_save` to reference `(25)`
   - The Gateway workflow ID references are in the "Execute Workflow" nodes
4. **Export updated Gateway** with incremented version
5. **Import BOTH workflows** to n8n (sub-workflow first, then Gateway)
6. **Activate both**

**Forgetting step 3 means the Gateway still calls the old version — fix will appear to have no effect!**

### Phase 2C — Certification Harness (Gateway Contract Protection)

**Purpose:**
Black-box regression harness validating Gateway + Save + Update + Promote contract surfaces.

**Harness Location:**
`Phase2C_Cert/Run-Phase2C-Cert.ps1`

**Scope:**
- Gateway boundary behavior
- Save normalization logic
- Update mutation determinism
- Promote lifecycle enforcement
- Immutability enforcement
- Error contract stability

**PASS Standard:**
- 100% tests passing
- 0 systemic failures
- 0 nondeterministic behavior
- 0 contract drift

**When To Run (Current Phase — Qwrk Prime):**
Run after any change to:
- Gateway
- Save
- Update
- Promote
- Registry / lifecycle logic

Mandatory gating is deferred until QBeta Dev/Prod environment is stood up.

**Future State (QBeta Launch):**
Certification becomes a required deployment gate prior to promotion from Dev → Prod.

## Schema Truth Policy — DDL-as-Truth

**Effective Date:** 2026-01-04
**Purpose:** Eliminate schema drift and ensure all SQL/payload mappings are correct on first attempt

### Authoritative Schema Source (Non-Negotiable)

**`docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`**

This file is the **ONLY** authoritative schema reference for Kernel v1. Do not rely on:
- Memory or assumptions about schema
- Older repo schema docs (historical reference only)
- `information_schema` exports (supporting evidence only)

### Hard Rules (CRITICAL - DO NOT VIOLATE)

1. **Before generating ANY SQL touching `qxb_*` tables:**
   - Open and reference `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`
   - Verify table names, column names, data types, constraints, defaults

2. **Never assume from memory:**
   - Column names (e.g., `owner_id` vs `owner_user_id`)
   - Column existence (e.g., `payload` vs `tags` + `content`)
   - Enum/check values (e.g., artifact_type allowed values)
   - Default values or auto-generated columns

3. **If unclear or absent in DDL:**
   - STOP immediately
   - Request refreshed DDL export from live database
   - Do NOT guess or infer

4. **Front-end clients do NOT generate SQL:**
   - Clients interact via Gateway contract (n8n workflows)
   - SQL is internal persistence concern
   - Gateway validates and routes to correct tables

5. **Maintain NoFail discipline:**
   - Schema-accurate inserts with correct JSONB shapes
   - Correct extension table writes (PK=FK pattern)
   - Use `gen_random_uuid()` for artifact_id (never manual assignment)
   - Use `RETURNING` clause to capture generated IDs

### Pre-Flight Checklist (Required Before SQL Generation)

Before writing ANY SQL:

✅ **Table exists** in LIVE DDL?
✅ **All columns exist** in LIVE DDL?
✅ **Constraints relevant** to this operation verified?
✅ **JSONB keys** match downstream expectations (Gateway contract / Qxb rules)?
✅ **Data types** match exactly (uuid vs text, jsonb vs json, etc.)?
✅ **NOT NULL constraints** satisfied?
✅ **CHECK constraints** respected (artifact_type enum, priority range, etc.)?

### Supporting Documentation

- **Human-readable reference:** `docs/schema/Schema_Reference__Kernel_v1__v2.10.md`
- **SQL templates:** `docs/sql_templates/Kernel_v1__NoFail_Inserts__v1.md`
- **Historical schemas:** `docs/schema/AAA_New_Qwrk__Schema__*.sql` (reference only)

### Consequences of Violation

Violating DDL-as-Truth results in:
- ❌ SQL syntax errors (wrong column names)
- ❌ Constraint violations (wrong types, missing required fields)
- ❌ Data corruption (wrong JSONB structures)
- ❌ Gateway failures (schema mismatch)
- ❌ Wasted development time debugging avoidable errors

**When in doubt: Check the DDL first.**

### Drift Prevention Rule (2026-02-20)

**Any DDL version change requires a corresponding Schema Reference update in the same commit.**

This applies to:
- Changes to `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` (DDL source)
- Must be accompanied by update to `docs/schema/Schema_Reference__Kernel_v1__v2.10.md` (or successor)

Rationale: Schema Reference v1.2 drifted from DDL for 7 weeks (2026-01-04 to 2026-02-20), accumulating 13 discrepancies. Co-committing prevents recurrence.

---

## Development Workflow

**Session Restart Protocol:**
1. Read latest restart prompt from `docs/restart-prompts/`
2. Confirm which next-stage option to implement
3. Provide 1-2 steps at a time, wait for confirmation
4. Use "we/our issue" phrasing during troubleshooting

**Current Build Priorities:**
- See `sessions/OPEN_THREADS.md` for active work items

**File Naming Convention:**
- Format: `AAA_New_Qwrk__[Type]__[Name]__[Version]__[Date].ext`
- Types: Schema, RLS_Patch, KGB, Snapshot, Execution_Order
- Always use versioning (v1.0, v1.1, etc.)

### Qwrk Operator Console (qwrk-console/)

Next.js web app for artifact browsing, hydration, and operator workflows. Active development (T172). Uses Supabase direct reads + Gateway hydration proxy. See T172 in OPEN_THREADS for current state.

## Session Management

**Governance:** Session continuity is managed via `sessions/README.md`. This section defines CC trigger behavior.

### Session Trigger Phrases

When user's **first message** contains any of these phrases (or close variations):
- "New session"
- "Start session"
- "I'm back"
- "Let's go"
- "Starting fresh"

### Subsession Trigger Phrases (Quick Start)

When user's **first message** contains any of these phrases:
- "nsub"
- "sub"
- "newsub"
- "go" (without "let's" — "let's go" remains a full session trigger)

### Required Behavior on Subsession Trigger

1. **Read `sessions/OPEN_THREADS.md`** — active surface table only
2. **Present lightweight context:**
   - Active surface thread table
   - Last session ID + date (from latest `session-end` snapshot title — query with `-Limit 1`, do NOT hydrate; if unavailable, skip)
3. **Ask for session intent** — or jump directly to referenced thread if user included a T-number (e.g., "go T150")

**Skipped (daily items — run only on full session):**
- CmdCtr briefing (MCP queries + snapshot payloads)
- Rolling memory sync
- for-cc work queue sweep
- CC memory harvest

**Disambiguation:** If uncertain whether user wants full session or subsession, ask: "Full session or quick start?"

### Required Behavior on Session Trigger

1. **Read prior context:**
   - Load `sessions/OPEN_THREADS.md` (canonical thread list)
   - Query latest session-end snapshot from Prime:
     ```
     powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType snapshot -Tags "session-end" -Limit 1 -Hydrate -Raw
     ```
   - If Gateway unavailable or no snapshot exists: proceed without prior session context (non-blocking)
2. **Run `/cmdctr-briefing` for Qwrk Prime and Q@W:**
   - Execute `cmdctr_operator_briefing()` for Prime (`be0d3a48-...`)
   - Execute `cmdctr_operator_briefing('635bb8d7-...')` for Q@W
   - Present forest health, active surface (blocked/stalled/ready), and delta summary
   - Generate QSB-ready snapshot save payload for each workspace (see CmdCtr Snapshot Contract below)
   - If briefing reveals structural issues (cycles, stalls, orphans), flag before asking for session intent
   - If MCP/SQL unavailable: skip silently (non-blocking), note in handoff summary
3. **Present handoff summary:**
   - Last session summary (from session-end snapshot `context` + `next_session_entry`)
   - Open threads from `OPEN_THREADS.md`
   - CmdCtr briefing highlights (from step 2)
   - Any blockers or carry-over reminders (from snapshot `open_loops`)
4. **Ask for session intent** — Offer options derived from open threads + CmdCtr active surface
5. **Rolling Memory Verification (DB-backed)** — Query latest `rolling-memory` snapshot per active workspace. Verification only — do NOT regenerate.

   **Qwrk Personal (Prime — `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`):**
   - List snapshots with `tags_any: ["rolling-memory"]`, ordered by `created_at DESC`, limit 1
   - Report presence + timestamp of the latest snapshot

   **Qwrk Resolve / Q@W (`635bb8d7-7b93-4bea-8ca6-ee2c924c9557`):**
   - List snapshots with `tags_any: ["rolling-memory"]`, ordered by `created_at DESC`, limit 1
   - Report presence + timestamp of the latest snapshot
   - (Q@W migration to DB-backed Rolling Memory pending Joel decision; if no snapshot exists yet, skip silently.)

   If no snapshot found or Gateway unavailable: skip silently (non-blocking). See "Rolling Memory (DB-backed)" section below for the SLP v1 retrieval contract. Source decisions: `0cb18b07`, `3248263c`.
6. **for-cc Work Queue Sweep** — Process artifacts tagged `for-cc` as pre-execution work queue items

   **Protocol:**
   1. Query all artifacts where tags contains `for-cc`
      - Do NOT hardcode artifact types — query by tag only
   2. Compare each artifact_id against OPEN_THREADS.md
      - Deduplication key: artifact_id present in Notes column
   3. Filter to artifacts not yet referenced in OPEN_THREADS
   4. For each new artifact:
      - Hydrate title and content/payload
      - Present to Joel: artifact_id, title, artifact_type, short summary of requested work
   5. Joel explicitly approves which artifacts to convert into threads
   6. Upon approval:
      - Create OPEN_THREADS entry prefixed `**FROM Q (for-cc).**`
      - Include source artifact_id in Notes
   7. Once referenced in OPEN_THREADS, artifact is considered consumed and will not re-surface

   **Constraints:**
   - Pre-execution only — `for-cc` does NOT authorize execution. Joel must approve before CC acts.
   - Non-blocking: if query fails, log warning and continue session
   - No rolling memory file required (OPEN_THREADS.md is the tracking surface)
   - No compaction logic required (thread lifecycle governs cleanup)
   - **Structured Handoffs:** Artifacts with BOTH `for-cc` AND `cc-handoff` tags are structured Q → CC work packets. Follow `docs/design/Design__Artifact_Handoff_Protocol__v1.md` for retrieval, execution, and response protocol.
7. **CC Memory Harvest** — For each **new** for-q artifact found in the delta (step 5), scan for operational data relevant to CC's persistent memory (`~/.claude/projects/.../memory/MEMORY.md`):

   **Tier 1 — Auto-save (no human gate required):**
   The following categories are purely factual and low-risk. CC may write these to MEMORY.md immediately upon detection:
   - New workspace IDs, names, or workspace-user mappings → Operational Facts
   - New principal names or auth_user_id mappings → Operational Facts
   - Deployed workflow versions or sub-workflow IDs → Deployed State
   - New Gateway endpoint URLs or credential references → Deployed State
   - Schema version bumps (e.g., "DDL v2.9 → v2.10") → Deployed State

   **Tier 2 — Human-gated (present proposal, wait for confirmation):**
   The following require judgment and may affect CC behavior. Present a compact proposal and **wait for user confirmation** before writing:
   - Implementation details diverging from design docs → Drift Log
   - New behavioral rules or session management changes → Governance-adjacent
   - Schema structural changes (new tables, column renames, constraint changes) → Deployed State
   - Anything ambiguous or interpretive

   **Common rules (both tiers):**
   - If no delta in step 5, skip silently
   - **Do NOT duplicate governance rules** — those belong in CLAUDE.md, not MEMORY.md
   - Auto-saved entries should be logged in the session summary (so Joel can audit)
   - If an auto-save contradicts an existing MEMORY.md entry, **delete the old entry and write the new one** (delete-on-contradiction, not accumulate)

### CmdCtr Snapshot Contract (Locked)

After each CmdCtr briefing run (step 2), CC generates a QSB-ready snapshot save payload per workspace.

**Payload rules (non-negotiable):**

| Field | Value |
|-------|-------|
| `gw_action` | `artifact.save` |
| `artifact_type` | `snapshot` |
| `semantic_type_id` | `40a5060b-1a80-4e8b-b7b7-1e102026efc0` (governance) |
| `tags` | `["cmdctr", "session-context", "for-q"]` |
| `title` | `CmdCtr Session Context — <YYYY-MM-DD>` |
| `gw_workspace_id` | Workspace-specific (Prime or Q@W) |
| `extension.payload` | Full structured JSONB session context from `cmdctr_build_session_context()` |
| `artifact_id` | NEVER included (server generates) |
| `priority` | `3` |

**Execution:** Joel executes via QSB. CC does NOT execute Gateway saves (Section 2.5).

**Delta baseline:** Each saved snapshot becomes the comparison baseline for the next session's `cmdctr_build_session_context()` call. First-run delta is empty (expected).

**Workspaces in scope:**
- Qwrk Prime: `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- Q@W: `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`

### Uncertainty Rule

If uncertain whether user wants formal session mode, ask:
> "Would you like me to open a formal session?"

**Do NOT proceed with other work until session mode is resolved.**

### Session End

On phrases like "end session", "wrap up", "close out":
1. **Update `sessions/OPEN_THREADS.md`:**
   - Add new threads discovered this session
   - Close resolved threads (move to Closed table)
   - Update notes/priorities as needed
2. **Generate session-end snapshot payload** using the Session End Snapshot Contract below
3. **Present the payload to Joel** for QSB execution (CC does NOT execute saves — Section 2.5)
4. **Do NOT write `LATEST_END_SESSION.md`** — session state lives in Qwrk snapshots, not files

### Session End Snapshot Contract (Locked)

Each session end produces a QSB-ready snapshot save payload.

**Payload rules (non-negotiable):**

| Field | Value |
|-------|-------|
| `gw_action` | `artifact.save` |
| `gw_workspace_id` | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` (Prime only) |
| `artifact_type` | `snapshot` |
| `semantic_type_id` | `governance` |
| `title` | `CC Session End — <YYYY-MM-DD> — Session <ID>` |
| `tags` | `["session-end", "cc", "for-q"]` |
| `priority` | `3` |
| `artifact_id` | NEVER included (server generates) |
| `extension.payload` | Structured JSONB (schema below) |

**Extension payload schema (locked):**

```json
{
  "session_id": "<string>",
  "timestamp": "<ISO datetime>",
  "context": "<short summary of session type and what was done>",
  "key_outputs": "<artifacts created, files written, deployments made>",
  "decisions": "<decisions locked this session>",
  "open_loops": "<unresolved items, blockers, carry-forward>",
  "next_session_entry": "<how to resume — options with specific actions>"
}
```

**Rules:**
- All fields required. Keep concise but information-dense.
- `session_id`: best-effort metadata. If latest snapshot available, increment. If not, use timestamp-based ID (e.g., `"2026-04-05T23:15"`). Do not block session on missing prior snapshot.
- No schema drift without explicit approval.
- This snapshot is immutable once saved — no updates.
- Multi-tab safe: each session creates its own snapshot (no shared mutable state).

**Execution:** Joel executes via QSB. CC does NOT execute Gateway saves.

**Retrieval:** To find the latest session-end snapshot:
```
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType snapshot -Tags "session-end" -Limit 1 -Hydrate -Raw
```
Filter on `session-end` tag only. Do not depend on full tag set for retrieval.

### Session Checkpoint Protocol

**Context usage thresholds:**

| % Used | Action |
|--------|--------|
| **70-75%** | Proactive checkpoint — ideal time to save session state |
| **80%** | Soft deadline — save and restart before next major topic |
| **85%+** | Danger zone — context compression may lose planning nuance |

**Why checkpoint early for planning work:**
- As context fills, earlier details get summarized/compressed
- Planning requires holding multiple threads (governance, saplings, constraints) simultaneously
- Recovery buffer prevents forced save mid-thought

**Checkpoint procedure:**
1. Notify user of context usage level
2. Offer to save session state now
3. If user agrees: run normal session end procedure (generate snapshot payload)

**Mid-session staleness rule:**
- Accept that governance/constraint changes during a session take effect next session
- Simpler and safer than mid-session rule updates
- User can always force restart if urgent

### Rolling Memory (DB-backed)

**Effective Date:** 2026-04-24

Rolling Memory is persisted as immutable snapshot artifacts in Supabase, not local files. This section supersedes the prior file-based Rolling Memory Sync Protocol.

**Snapshot contract (locked):**

| Field | Value |
|-------|-------|
| `artifact_type` | `snapshot` |
| `semantic_type_id` | `governance` |
| `tags` | `["rolling-memory", "for-q"]` |
| Canonicality | Latest by `created_at` (latest-wins) |
| Mutability | Immutable; new versions = new snapshot |

**Workspaces in scope:**
- Qwrk Personal (Prime): `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` — DB-backed since 2026-04-24 (`6576de56` is v15, the first DB-backed instance)
- Qwrk Resolve / Q@W: `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` — migration to DB-backed pending Joel decision

**Retrieval contract:** Per Session Lifecycle Protocol v1 (Crawl Phase Lock — snapshot `3248263c`). Q absorbs Rolling Memory at session start via deterministic startup trigger. Q must NOT proceed with normal reasoning until Rolling Memory is loaded or explicitly skipped.

**CC behavior:**
- Verifies presence at session start (Session Trigger step 5 above) via `artifact.list`.
- May reference snapshot content via `artifact.list` / `artifact.query` when relevant.
- Does NOT generate, mutate, or rewrite Rolling Memory snapshots — that is a Q + Joel responsibility (Section 2.5 read-only rule).

**Manual override:** User can request `regenerate rolling memory` mid-session. Q produces save payload via QSB; Joel executes.

**Source decisions:**
- `0cb18b07` — Source Record: Rolling Memory Migration Correction (registry deprecated, RM confirmed)
- `6576de56` — Rolling Memory v15 (first DB-backed snapshot, 2026-04-24)
- `3248263c` — Decision: Session Lifecycle Protocol v1 (Crawl Phase Lock)

**Local files (historical only):** `Qwrk_RollingMem/Qwrk_Rolling_Memory__for-q__*.md` and `Multi-User Qwrk/.../Q@W Rolling Mem/Qwrk_Rolling_Memory__for-q-work__*.md` are retained for audit. They are NOT authoritative and MUST NOT be regenerated as Rolling Memory.

### Tier A Memory Compaction Protocol

**Purpose:** Maintain bounded active memory window while preserving foundational governance.

#### Two-Layer Model

| Layer | Description | Compaction Eligible |
|-------|-------------|---------------------|
| **Protected Core** | Foundational governance and execution invariants | NEVER |
| **Rotating Shell** | Tactical, contextual, or transitional rules | YES |

#### Tier A2: Active Operational Contexts

Snapshot-backed engagement-state records (e.g., book being read, project being executed). Always Rotating Shell.

**Lifecycle:**

| Phase | Trigger | Action |
|-------|---------|--------|
| OPEN | Explicit user intent | Create snapshot with `context_status: active` |
| UPDATE | State advances (e.g., next part) | Create NEW snapshot, same `context_ref` (latest wins) |
| CLOSE | User finishes/abandons | Create snapshot with `context_status: finished` |

**Invariants:**
- Snapshots are immutable — all updates create new snapshots
- Latest snapshot by `created_at` is authoritative (latest-wins)
- Reactivation forbidden — new engagement requires new `context_ref`
- Active X Contexts are always Rotating Shell (never Protected Core)
- `context_status: active` → NOT compaction-eligible (protected while in use)
- `context_status: finished` → eligible immediately

#### Size Governance

Compact Rotating Shell when entry count ≥ 50 (target: 35). Current state: ~100kb / 29 entries — under threshold.

Full compaction algorithm, Rolling Memory Regeneration steps, eligibility rules, and audit requirements preserved in `Archive/CLAUDE__v26__2026-03-24.md` and git history. Restore if entry count ≥ 40 OR compaction is being considered.

## Artifact Registry (Deprecated)

**Effective Date:** 2026-04-24

The local CSV artifact registry is deprecated. Discovery is now via Gateway `artifact.list` / `artifact.query` and the Artifact Discovery Playbook (canonical file `Instruction_Pack__Artifact_Discovery_Playbook__v1.md` per workspace's ChatGPT/Q project files; internal `pack_version: v1.3` deployed across Prime + Q@W + BlaggLife + Akara per T209 Crawl-1 Pass 1 + Pass 2 on 2026-05-12; Greg deferred).

**The system MUST NOT depend on any registry artifact for correctness.** Source decision: `0cb18b07` (Rolling Memory Migration Correction Prompt — registry concept retired).

**Replacement guidance:**
- Discovery: `artifact.list` with tag/type/lifecycle filters; `artifact.query` for hydration
- Reference: Artifact Discovery Playbook (canonical file `Instruction_Pack__Artifact_Discovery_Playbook__v1.md` per workspace; internal version v1.3) — canonical retrieval patterns. Earlier CLAUDE.md citations of a Playbook snapshot UUID were unverified; T209 Crawl-1 reconciliation established the file as authoritative surface (Option A: no mirror snapshot).
- Schema reference: `docs/schema/Schema_Reference__Kernel_v1__v2.10.md`
- CC query helper: `scripts/CC-Gateway-Query.ps1` (Section 2.6)

**Skill status:** `/registry-refresh` and `/rolling-mem-sync` are marked deprecated with replacement guidance in their skill files. They are retained for historical/audit reference only and should not be invoked in normal operation.

**Historical files (audit-only):** Existing `artifact_registry__*.csv` files in `Qwrk_RollingMem/` and `Multi-User Qwrk/.../Q@W Rolling Mem/` are retained. Do NOT regenerate.

## Important Constraints

**Immutability Rules:**
- Snapshot and Restart **extension tables** are immutable (no UPDATE policies on `qxb_artifact_snapshot` / `qxb_artifact_restart`)
- Spine-level `content_append` and `tags` updates ARE allowed on these types — append_log entries are timestamped, preserving original extension payload integrity
- Event log is append-only (triggers block UPDATE/DELETE)
- Do NOT create UPDATE/DELETE policies for extension tables of immutable types

**Destructive Operations Discipline (Session 125 incident — PERMANENT):**
- NEVER use `git checkout --`, `git restore`, or `git reset --hard` on files with uncommitted working-tree changes — this destroyed OPEN_THREADS.md (3 weeks of session data) in session 125
- Before editing CLAUDE.md or OPEN_THREADS.md: create a physical backup copy (`<filename>__BACKUP__<date>.md`)
- Commit session files (OPEN_THREADS.md, CLAUDE.md) at every session end
- ExitPlanMode does NOT equal execution approval when external review (Manus, Q) is specified — execution waits for review feedback
- When reverting CC's own edits: use Edit tool to reverse specific changes, never destructive git commands

**Schema Integrity:**
- Always validate workspace membership before artifact operations
- Respect artifact ownership for private types (journal)
- Event log must reference valid workspace_id + artifact_id
- All timestamps use `timestamptz` with automatic `updated_at` triggers

---

## New Qwrk Governance Rules for CC

**Effective Date:** 2026-01-01

### 1) Binding Truth Hierarchy (must obey; never contradict)

1. Behavioral Controls — Governing Constitution
2. Qwrk V2 — North Star (v1.0)
3. Kernel v1 Snapshots (Pre/Post KGB)
4. Phase 1–3 Locks (Kernel semantics, type schemas, Gateway contract)
5. Known-Good n8n Workflow Snapshots / KGB results

**On conflict**: STOP and report:
- What conflicts
- Which document is higher truth
- One clean resolution: "needs versioned update" vs "implementation mistake—correct it"

### 2) No-Guessing Rule (hard stop)

Do NOT invent schemas, enums, tables, endpoints, Gateway actions, lifecycle rules, or payload shapes.

If you lack authoritative truth, STOP and ask for the exact file/section.

### 2.5) Database Read-Only Rule (CRITICAL)

Claude Code MUST NOT execute any operation that modifies database state. Gateway access is restricted to `artifact.query` and `artifact.list` ONLY.

**Allowed (READ only):**
- `artifact.query` via Gateway (PowerShell)
- `artifact.list` via Gateway (PowerShell)

**NOT Allowed:**
- `artifact.save` via Gateway
- `artifact.promote` via Gateway
- `artifact.update` via Gateway
- Any INSERT, UPDATE, DELETE SQL execution
- Any operation that modifies database state

**Required behavior for writes:**
1. Generate the SQL or Gateway payload
2. Present it to the user for review
3. User executes manually (Supabase SQL Editor, PowerShell, etc.)
4. CC verifies result via READ query after user confirms execution

**Rationale:** Write and delete operations are irreversible and require human oversight. CC provides the payload; human executes.

### 2.6) CC Gateway Query Script (How to Query)

**Problem:** Inline PowerShell commands via Bash have escaping issues that cause query failures.

**Solution:** Use the helper script `scripts/CC-Gateway-Query.ps1` which handles all escaping correctly.

**Usage Examples:**

```powershell
# List snapshots with for-q tag
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType snapshot -Tags "for-q" -Limit 10

# Query specific artifact (artifact_type is REQUIRED)
powershell -File "scripts/CC-Gateway-Query.ps1" -Action query -ArtifactType snapshot -ArtifactId "6b0b1bf4-76e4-4baf-b2eb-5af044fb4b01" -Hydrate

# List all projects
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType project -Limit 20

# Raw JSON output for parsing
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType journal -Raw
```

**Script Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-Action` | Yes | `list` or `query` |
| `-ArtifactType` | For query | `project`, `journal`, `snapshot`, `restart`, `grass`, `thorn`, `branch`, `leaf`, `instruction_pack`, `forest`, `thicket`, `flower` |
| `-ArtifactId` | For query | UUID of artifact to retrieve |
| `-Tags` | No | Comma-separated tags for list filtering |
| `-Hydrate` | No | Include extension table data (default: false for list, true for query) |
| `-Limit` | No | Max results for list (default: 20) |
| `-Offset` | No | Pagination offset (default: 0) |
| `-Raw` | No | Output raw JSON instead of formatted |

**DO NOT** attempt inline PowerShell Gateway calls through Bash — escaping will break.

### 2.7) Retry Cap Rule (hard stop after 3 attempts)

**Effective Date:** 2026-03-11
**Inspired by:** Industry-wide agent patterns (Devin, Cursor) that cap retry loops to prevent spin.

When any operation fails (Gateway query, script execution, file operation, API call), CC MUST:

1. **Attempt 1:** Execute normally
2. **Attempt 2:** Diagnose the failure, adjust approach, retry
3. **Attempt 3:** Try one final alternative approach

**After 3 failed attempts:** STOP immediately and report:
- What was attempted (all 3 approaches)
- What failed and why (if known)
- Suggested next steps for Joel

**Hard rules:**
- Do NOT sleep-and-retry the same command unchanged
- Do NOT attempt a 4th variation without explicit user direction
- Each attempt MUST differ from the previous (different approach, not just re-run)
- This applies to: Gateway queries, PowerShell scripts, SQL execution, file operations, build/test commands

**Rationale:** Unbounded retry loops waste context, obscure root causes, and delay human intervention. Three attempts with escalating intelligence is sufficient to distinguish transient failures from structural problems.

### 3) Absolute No-Overwrite Rule

**CRITICAL:** You MUST NOT overwrite any existing file in-place.

All changes follow ONE of these allowed patterns:

#### **Pattern C: Archive-based Versioning (PREFERRED DEFAULT)**

Use this pattern for all documentation and file updates unless specific circumstances require Pattern A or B.

**Steps:**
1. Create `Archive/` subfolder in the same directory if it doesn't exist
2. Move current file to Archive with version suffix: `<filename>__v<OLD_VERSION>__<DATE>.<ext>`
3. Write new file using original canonical filename (no version suffix)
4. Update CHANGELOG in new file to reference archived version

**Example:**
```
Before update:
/runbooks/Runbook__Activate_MVP.md (v1 content)

After update:
/runbooks/
├── Runbook__Activate_MVP.md (v2 content, updated CHANGELOG)
└── Archive/
    └── Runbook__Activate_MVP__v1__2026-01-03.md (original v1)
```

**Benefits:**
- Active folder contains only current versions (clean discovery)
- Canonical filename stays consistent (no version guessing)
- Full history preserved in Archive
- Git tracks all changes

#### **Pattern A: Versioned Clone (when both versions needed in main folder)**

Use when you need temporary side-by-side comparison or parallel versions.

**Steps:**
- Leave the original file untouched
- Write a new file using: `<base_name>__vNEXT__YYYY-MM-DD.<ext>`

**When to use:**
- Temporary parallel versions during migration
- Explicit side-by-side comparison requested by user

#### **Pattern B: Canonical-name Preservation (legacy, rare)**

Use when renaming old version without Archive folder structure.

**Steps:**
- First rename the existing file to: `<base_name>__vPREV__YYYY-MM-DD.<ext>`
- Then write the updated file using the original canonical filename

**When to use:**
- Working in directories without Archive folder (external dependencies)
- Explicitly requested by user

If none of these patterns fit, STOP and ask.

### 4) Pre-Write Confirmation Gate

**Before writing or renaming any file**, you must output:
- The exact list of files you intend to touch
- Files being moved to Archive/ (with new version suffix)
- The new filenames you will create
- Which pattern (A, B, or C) you are using for each

Then WAIT for explicit approval.

### 5) Changelog Requirement (mandatory)

Every new or updated file must include either:
- A CHANGELOG section at the top, or
- A companion README entry

**Minimum contents:**
- What changed
- Why
- Scope of impact
- How to validate / regress

**Archive folder behavior:**
- Archived files preserve their original CHANGELOG intact
- New file adds new CHANGELOG entry referencing archived version
- Example: "Previous version: `Archive/Filename__v1__2026-01-03.md`"

### 6) n8n Workflow Editing Rules (strict)

- Preserve pinned test data unless explicitly told otherwise
- Maintain node naming: `NQxb_<Workflow>__<Purpose>`
- Prefer Switch nodes over IF nodes
- Do not introduce cross-branch node dependencies
- Respect n8n response constraints (no leading `=` in JSON expressions)
- Keep response envelopes aligned with Gateway contract

### 7) Known-Good Discipline

Treat latest KGB output as sacred:
- Make changes minimal and surgical
- If behavior changes, update docs and provide regression steps
- After a coherent change-set, recommend creating a new Snapshot

### 7.5) Documentation & Derivation Contract (GLOBAL)

Documentation in this repository follows a **single-source-of-truth model**.

#### Canonical Documentation (Authoritative)
Claude Code MUST update **canonical technical documentation** for every behavior, workflow, or governance change.

Canonical documentation:
- Is precise, technical, and complete
- Describes what the system DOES and DOES NOT do
- Is written for builders and auditors
- Is the sole source of truth

If a behavior is not documented canonically, it is considered incomplete.

#### Derived Documentation (Never Authored Directly)
The following are **derived artifacts** and must NOT be authored or edited directly by Claude Code:

- User guides
- Marketing guides
- Sales or positioning copy
- Demo scripts or "self-demo" instructions

These outputs are generated downstream from canonical documentation using interpretation rules.

#### Required Metadata for Derivation
Every canonical documentation update MUST include, explicitly:

- Feature or capability name
- Stage: Crawl / Walk / Run
- Capabilities (what is supported)
- Non-capabilities (what is explicitly not supported)
- User-facing summary (plain language, 1–2 paragraphs)
- Demo safety classification:
  - Demo-safe
  - Demo-unsafe
  - Demo-partial (with notes)

If this metadata is missing, work is not complete.

#### Conflict Rule
If canonical documentation and any derived narrative diverge:
- Canonical documentation wins
- Derived outputs must be regenerated or corrected

### 8) Documentation Duties (required)

For every change:
- Update the relevant README (or create one if missing)
- Include: scope, decisions touched (should be none unless approved), tests, and rollback instructions

### 9) Parallel Build Safety Rule (CRITICAL)

When adding new functionality to any system component that is already in active use, CC MUST default to a parallel, isolated build-and-test approach rather than modifying the live implementation directly.

**Core Requirements (Non-Negotiable):**

1. **Protection of existing functionality is first-class**
   - Live or production-used workflows must not be modified directly when introducing new capabilities
   - "Production" includes anything currently in use, even if labeled MVP

2. **Parallel workflow/environment is the default**
   - When feasible, CC must create a cloned or parallel workflow, instance, or environment that is contract-identical to the live system
   - All new functionality is implemented and validated in the parallel version first

3. **No-regression guarantee**
   - Existing functionality must remain operational and unchanged throughout development
   - Validation must explicitly confirm that the live path still works as before

4. **Controlled merge-back**
   - New functionality is merged into the live system only after validation succeeds
   - Merge-back is a deliberate, approved step — not implicit or automatic

5. **Scope discipline**
   - Parallel builds are for feature addition only
   - Cleanup, refactors, or architectural "improvements" to the live path are out of scope unless explicitly authorized

### 10) Parallel Mutation Guardrail

When multiple CC or Q sessions are active simultaneously, structural mutations must remain serialized even if reasoning is parallel. (Mutation discipline only — no automation or session detection mechanism.)

#### 10.1 Session Scope Declaration (Required)

At the beginning of any CC implementation session that may modify repository state, the session must explicitly declare its primary mutation surface (DDL/migrations, Gateway workflows, system instructions, CLAUDE.md, rolling memory files, type registry, or documentation affecting lifecycle governance).

If the declared surface overlaps a potentially active parallel session, CC must pause and request confirmation before proceeding.

#### 10.2 Structural Surfaces (High-Risk)

Concurrent modification of these surfaces is prohibited:

- `CLAUDE.md`
- System instruction files
- Gateway workflow definitions
- Database DDL / migrations
- Rolling memory files
- Type registry logic

#### 10.3 Serialized Mutation Rule

Parallel reasoning is permitted. Parallel structural mutation is not.

Before performing any structural change, CC must request confirmation that no other active session is modifying the same surface. If confirmation cannot be established, CC must defer execution.

#### 10.4 Merge Order Doctrine

When multiple workstreams converge:

1. Governance documentation merges first.
2. Workflow/code changes merge second.
3. Deployment or activation occurs last.

Merge order must never be reversed.

### 11) Planning Gate for Complex Threads

CC must gather sufficient context and propose a plan before acting on threads that cross multiple surfaces or involve 3+ files.

#### When the Planning Gate Applies

The Planning Gate is **required** when a thread meets ANY of these criteria:

- Touches **3 or more files**
- Crosses **2 or more structural surfaces** (e.g., DDL + Gateway, or CLAUDE.md + system instructions)
- Involves a **for-cc work queue item** that requires interpretation (not a simple, unambiguous task)
- Is explicitly flagged by Joel as "plan first"

The Planning Gate is **NOT required** for:

- Single-file edits with clear scope
- Registry refreshes, rolling memory syncs, or other routine operations
- Bug fixes where the root cause and fix are already identified
- Tasks where Joel has said "just do it" or equivalent

#### Two-Phase Protocol

**Phase 1 — Gather (no mutations):** Read all relevant files/docs/prior context; query database/Gateway if needed for current state; identify affected surfaces, files, and dependencies; assess risk (what could break, what's irreversible).

**Phase 2 — Propose Plan.** Present to Joel:

| Section | Content |
|---------|---------|
| **Scope** | What this thread accomplishes |
| **Surfaces touched** | Which structural surfaces are affected |
| **Files to create/modify** | Exact file list with patterns (A/B/C) |
| **Dependencies** | What must happen in order |
| **Risk assessment** | What could go wrong, reversibility |
| **Estimated steps** | Numbered list of implementation steps |

Then **WAIT for explicit approval** before executing any mutations.

#### Plan Amendments

If execution reveals the plan needs to change: STOP execution, report what changed and why, present amended plan, wait for approval before continuing. Do NOT silently deviate from an approved plan.

#### Interaction with Existing Rules

- **§4 (Pre-Write Confirmation Gate):** still applies per-file during execution; Planning Gate is the higher-level gate.
- **§9 (Parallel Build Safety):** Planning Gate may recommend parallel build as part of the plan.
- **§10 (Parallel Mutation Guardrail):** Planning Gate should declare mutation surfaces upfront (satisfies 10.1).

---

## CHANGELOG - CLAUDE.md Updates

### v34 - 2026-05-12
**What changed:** Drift cleanup — removed stale snapshot UUID references for Artifact Discovery Playbook.

**Why:**
- T209 Crawl-1 reconciliation determined that an unverified Playbook snapshot UUID was being cited as authority — the Artifact Discovery Playbook is actually governed by a file in each workspace's ChatGPT/Q project file context (canonical filename `Instruction_Pack__Artifact_Discovery_Playbook__v1.md`), not by a Qwrk snapshot artifact.
- T209 Crawl-1 Pass 1 (2026-05-12) landed Playbook v1.3 in Prime + Q@W; Pass 2 (same day) propagated to BlaggLife + Akara. All four workspaces now carry internal `pack_version: v1.3`. Greg explicitly deferred.
- Per Option A from the reconciliation: stale snapshot UUID references replaced with file-path authority; no mirror snapshot created (avoids duplicate authority + ongoing sync maintenance burden).

**Scope of impact:**
- Section "Artifact Registry (Deprecated)" — both stale Playbook snapshot UUID references replaced with file-path authority pointers.
- Unchanged: all governance rules §1–§11 (No-Guessing, Read-Only §2.5, No-Overwrite §3, Pre-Write Gate §4, Changelog Requirement §5, n8n Editing §6, KGB Discipline §7, Doc & Derivation §7.5, Doc Duties §8, Parallel Build Safety §9, Parallel Mutation Guardrail §10, Planning Gate §11); Schema Truth Policy / DDL-as-Truth; session management; Tier A Memory Compaction; Important Constraints; all CHANGELOG entries v2–v33.

**How to validate:**
- Grep CLAUDE.md for the deprecated Playbook snapshot UUID — must return zero matches.
- Confirm Playbook authority references at the Artifact Registry section now name the file path with internal v1.3 version.
- No other CLAUDE.md sections changed.

**Hard scope boundary:** Drift cleanup only. No governance, Gateway, DDL, runtime, session management, or schema behavior changes. No Pass 2 Playbook propagation included in this v34 — that was completed separately as 4 Pattern C operations on BlaggLife + Akara before this CLAUDE.md edit.

**Previous version:** `Archive/CLAUDE__v33__2026-05-12.md`

### v33 - 2026-05-09
**What changed:** Tier 1 size reduction. Tightened §9 Rationale paragraph, §10 Purpose preamble + Examples list, §11 Effective-Date / Inspired-by / Purpose preamble; condensed CHANGELOG v30/v31/v32 to one-liners.

**Why:**
- File at 57.4 kB vs Claude Code's ~40 kB heuristic; every conversation paid the full cost
- §9 had a trailing Rationale paragraph; §10 had a Purpose preamble + duplicate Examples list; §11 had Effective Date, "Inspired by Devin AI", and a Purpose preamble before the trigger criteria
- v30/v31/v32 CHANGELOG entries averaged ~30 lines each; detail already preserved in Archive copies (`v31`, `v32`) and git history

**Scope of impact:**
- Tightened: §9 Parallel Build Safety (Rationale paragraph removed)
- Tightened: §10 Parallel Mutation Guardrail (Purpose section removed; Examples list inlined; 10.3 sentences consolidated)
- Tightened: §11 Planning Gate (Effective Date, Inspired-by, Purpose removed; Phase 1 numbered list and Plan Amendments inlined)
- Compressed: CHANGELOG v30, v31, v32 → one-line summaries with archive pointers
- Unchanged: All governance §1–8 (incl. DDL-as-Truth, Read-Only §2.5, Pre-Write Gate §4, No-Overwrite §3); all numbered rules and MUST/NEVER language in §9/§10/§11; triggers, two-phase protocol, decision tables; session management; destructive-ops rules; header dates and Gateway/DDL versions

**How to validate:**
- Grep §9 for "Core Requirements (Non-Negotiable)" + 5 numbered rules — present
- Grep §10 for "10.1", "10.2", "10.3", "10.4" sub-sections + the 6-item structural surfaces list — present
- Grep §11 for "Required" + "NOT required" + "Two-Phase Protocol" + "WAIT for explicit approval" — present
- Byte count: target ≤ 50 kB (from 57.4 kB)
- Full v30/v31/v32 text recoverable via `Archive/CLAUDE__v32__2026-05-05.md` and git history

**Hard scope boundary:** Documentation/governance text only. No Gateway, DB, workflow, schema, runtime, session-management, snapshot-contract, or DDL-as-Truth behavior changes.

**Previous version:** `Archive/CLAUDE__v32__2026-05-05.md`

### v32 - 2026-05-05
Replaced file-based Rolling Memory Sync Protocol + Artifact Registry Discipline with DB-backed snapshot pointers per SLP v1 (`3248263c`); registry concept fully deprecated (`0cb18b07`); workspace labeling tightened. Previous: `Archive/CLAUDE__v31__2026-04-05.md`

### v31 - 2026-04-05
Session state moved from `LATEST_END_SESSION.md` to immutable Qwrk snapshots tagged `session-end`; Session End Snapshot Contract added; subsession context now reads snapshot title query. Previous: `Archive/CLAUDE__v30__2026-04-02.md`

### v30 - 2026-04-02
Streamlining pass — removed stale operational state (KGB/response examples), compressed dormant Tier A protocol, added qwrk-console pointer; Manus external review incorporated (Tier A invariants preserved). Previous: `Archive/CLAUDE__v29__2026-03-26.md`

### v29 - 2026-03-26
**What changed:** Gateway v1 decommissioned — all references updated to Gateway v2

**Why:**
- Gateway v2 has been the active production gateway across all 6 workspaces since T122
- v1 was single-workspace (Prime-only), hardcoded, and no longer aligned with multi-forest architecture
- Mobile Qx was the last remaining v1 consumer — migrated to v2 (Option A: clean cut)
- 37 historical test scripts in `work/` still referenced v1 endpoints — bulk-updated to prevent debugging friction

**Scope of impact:**
- Header: Gateway v68 → v2 (build 2), reconciliation date 2026-03-26
- Core Architecture: `NQxb_Gateway_v1` → `NQxb_Gateway_v2` with decommission note
- Workflow Deployment Checklist: v1 node reference → v2
- KGB: `Gateway v68` → `Gateway v2`
- Archived: `workflows/NQxb_Gateway_v1 (68).json` → `workflows/Archive/NQxb_Gateway_v1__v68__2026-03-26.json`
- Updated: 37 `work/*.ps1` scripts (v1 → v2 endpoint), `qwrk-prime-sidebar/README.md` (v1 → v2)
- Unchanged: All governance rules (1–11), session protocol, DDL-as-Truth, schema references

**How to validate:**
- Zero `gateway/v1` references in active scripts (`scripts/`, `work/`)
- Chrome extensions (QX, QSB) confirmed on v2
- v1 workflow archived, v2 active in n8n
- `grep -r "gateway/v1" work/ scripts/` returns zero matches

**Previous version:** v28

### v28 - 2026-03-25
**What changed:** Added Subsession Quick-Start protocol — lightweight session entry path

**Why:**
- Multi-tab CC usage requires a fast entry path that skips daily operational loop (CmdCtr, rolling mem sync, for-cc sweep, memory harvest)
- Full 7-step session protocol is correct for first-of-day sessions but excessive for subsequent tabs
- Joel requested; plan reviewed and approved

**Scope of impact:**
- Added: "Subsession Trigger Phrases" section (triggers: nsub, sub, newsub, go)
- Added: "Required Behavior on Subsession Trigger" section (3-step lightweight protocol)
- Unchanged: Full session protocol, all governance rules (1–11), all other session management
- Disambiguation: "go" (subsession) vs "let's go" (full session) — documented

**How to validate:**
- Say "nsub" or "go" — CC loads OPEN_THREADS active surface + last session header only, no CmdCtr/sync
- Say "new session" — full 7-step protocol runs as before
- "let's go" still triggers full session (not subsession)

**Previous version:** v27

### v27 - 2026-03-24
**What changed:** Cognitive load reduction — removed ~590 lines of dormant/historical content

**Why:**
- CLAUDE.md was 1723 lines. ~34% was dormant compaction algorithm detail, one-time database setup commands, and changelog entries v2–v24 that had zero operational value
- Every conversation paid the full governance tax regardless of session type
- Design analysis (session 110) identified Load Distribution as primary friction category
- Content removal chosen over structural splitting — simpler, no path-loading assumptions

**Scope of impact:**
- Removed: CHANGELOG entries v2–v24 (~490 lines) — audit trail, not operational guidance
- Removed: Database Commands section (~17 lines) — one-time setup, already executed
- Removed: Compaction algorithm detail (~83 lines) — dormant (29 entries, threshold 50), replaced with archive pointer
- Kept: All governance rules (Sections 1–11), session protocol, safety-critical constraints, KGB, DDL-as-Truth
- Kept: Tier A2 Active Operational Contexts, Size Governance thresholds, Two-Layer Model summary
- Compaction restore trigger: entry count ≥ 40 OR compaction is being considered

**How to validate:**
- All governance sections 1–11 present and unchanged
- Session startup protocol (steps 1–7) present and unchanged
- Safety-critical rules present: DDL-as-Truth, Read-Only (2.5), No-Guessing (2), No-Overwrite (3)
- CmdCtr Snapshot Contract present
- KGB test IDs present
- Full pre-reduction content in `Archive/CLAUDE__v26__2026-03-24.md`

**Previous version:** `Archive/CLAUDE__v26__2026-03-24.md`

### v26 - 2026-03-24
CmdCtr integrated into session start protocol with snapshot persistence contract. Previous: `Archive/CLAUDE__v25__2026-03-24.md`

### v25 - 2026-03-22
T150 Person artifact type deployed (DDL v2.9→v2.10, CHECK v7→v8, Access Control Model documented). Previous: `Archive/CLAUDE__v24__2026-03-22.md`

> **Changelog entries v2–v24 archived.** Full history preserved in `Archive/CLAUDE__v26__2026-03-24.md` and git.
