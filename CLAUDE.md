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

## Project Overview

**Qwrk V2** (New Qwrk Kernel) - A workspace-first, artifact-centric system built on Supabase with n8n workflow automation for gateway operations.

### Core Architecture

**Backend: Supabase Kernel v1**
- Database: PostgreSQL with Row Level Security (RLS) enabled on all tables
- Project ref: `npymhacpmxdnkqdzgxll`
- Authentication: Supabase Auth integrated with custom user mapping

**Gateway Layer: n8n Workflows**
- Workflow: `NQxb_Gateway_v1` handles all artifact operations
- Currently implements: `artifact.query` (v1 MVP complete)
- Planned: `artifact.list`, enhanced error handling, response envelopes

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
- `qxb_artifact_event` - append-only audit log (protected by triggers)

**Core Tables Dependency Order:**
1. `qxb_user` (maps Supabase auth to Qwrk identity)
2. `qxb_workspace` (every artifact requires workspace_id)
3. `qxb_workspace_user` (role-based membership: owner/admin/member)
4. `qxb_artifact` (spine)
5. Type tables + event log

**Artifact Types:**
- `project` - lifecycle_stage: seed → sapling → tree → retired
- `journal` - owner-private reflective entries (RLS: owner-only)
- `snapshot` - immutable lifecycle snapshots
- `restart` - manual session continuation artifacts
- `video` - long-form media artifacts (transcripts, insights); first-class (not journal)
- `grass` - operational issue tracking
- `thorn` - exception tracking
- `forest`, `thicket`, `flower` - reserved for future use

### Row Level Security (RLS) Model

**Critical RLS Rules:**
- All tables have RLS enabled (deny-by-default)
- Helper function: `qxb_current_user_id()` maps `auth.uid()` → `qxb_user.user_id`
- Workspace visibility: users see only workspaces where they have membership
- Artifact visibility: workspace members can read (except journals = owner-only)
- Type table policies delegate to `qxb_artifact` spine

**Known RLS Issue Fixed (v1.1):**
- Infinite recursion was detected in `qxb_workspace_user_select_member`
- Fixed by creating self-only select policy: `qxb_workspace_user_select_self`
- Workspace policy updated to use direct membership check

### n8n Gateway Workflow Rules

**Hard Rules (CRITICAL - DO NOT VIOLATE):**

1. **Expression syntax:** DO NOT type a leading `=` in n8n expressions; n8n adds it automatically
2. **Supabase nodes are dumb column writers:** Flatten payloads before DB nodes; don't auto-map wrapped payloads
3. **Node naming discipline:** Use `Qxb`-prefixed names consistently
4. **Switch comparison safety:** Guard against hidden whitespace/newlines using `.trim()`
5. **No guessing:** Do not guess schemas, enums, endpoints, or commands. Stop and ask for canonical source if unclear.

**Gateway Architecture:**
- **Spine-first pattern:** Fetch `qxb_artifact` by `workspace_id + artifact_id` first
- **Type validation:** Compare requested `artifact_type` vs stored type using `compare_key` / trim-safe logic
- **Type branching:** Route to type-specific extension table based on stored `artifact_type`
- **Response merging:** Strip redundant `artifact_type` from extension payload before merge

**Response Format Examples:**

Success (current):
```json
{
  "artifact": {
    "artifact_id": "...",
    "workspace_id": "...",
    "artifact_type": "project",
    "title": "...",
    ...spine fields...,
    ...extension fields...
  }
}
```

Error (TYPE_MISMATCH example):
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "TYPE_MISMATCH",
    "message": "Requested artifact_type does not match stored artifact_type for this artifact_id.",
    "details": {
      "artifact_id": "...",
      "requested_artifact_type": "...",
      "stored_artifact_type": "..."
    }
  }
}
```

### Workflow Deployment Checklist (CRITICAL)

When updating ANY sub-workflow called by Gateway (Save, Query, List, Update, Promote):

1. **Archive current version** to `workflows/Archive/`
2. **Apply fix and save** with incremented version number (e.g., `(24)` → `(25)`)
3. **Update Gateway workflow** — The Gateway's "Execute Workflow" node must point to the new version
   - Example: If Save goes from `(24)` → `(25)`, update `NQxb_Gateway_v1` node `call_save` to reference `(25)`
   - The Gateway workflow ID references are in the "Execute Workflow" nodes
4. **Export updated Gateway** with incremented version
5. **Import BOTH workflows** to n8n (sub-workflow first, then Gateway)
6. **Activate both**

**Forgetting step 3 means the Gateway still calls the old version — fix will appear to have no effect!**

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

- **Human-readable reference:** `docs/schema/Schema_Reference__Kernel_v1__Canonical.md`
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

---

## Database Commands

**Schema Execution Order:**
```bash
# Execute in QXB Table Design Files directory
# 1. Run bundle (includes pgcrypto extension + all tables)
psql -f "AAA_New_Qwrk__Schema__Kernel_v1__BUNDLE__v1.0__2025-12-30.sql"

# 2. Apply RLS policies (latest patch version)
psql -f "AAA_New_Qwrk__RLS_Patch__Kernel_v1__v1.2__2025-12-30.sql"

# 3. Run KGB (Known Good Baseline) validation
psql -f "AAA_New_Qwrk__KGB__Kernel_v1__SQL_Pack__v1.0__2025-12-30.sql"
```

**Safe dependency order (if running individual files):**
See `docs/schema/AAA_New_Qwrk__Execution_Order__Kernel_v1__v1.0__2025-12-30.md`

## Known-Good State (KGB)

**Current MVP Status:**
- `artifact.query` works end-to-end for all 4 artifact types
- Spine-first architecture validated
- Type mismatch guards in place

**KGB Test IDs (workspace_id: be0d3a48-c764-44f9-90c8-e846d9dbbd0a):**
- journal: `db428a32-1afa-4e6b-a649-347b0bffd46c`
- project: `668bd18f-4424-41e6-b2f9-393ecd2ec534`
- snapshot: `610e16d1-c5bb-468c-bd35-57eadf9f2e38`
- restart: `ac1d6294-2bd7-4a9d-823e-827562b56e26`

**KGB User Context:**
- auth_user_id: `7097c16c-ed88-4e49-983f-1de80e5cfcea`
- qxb_user.user_id: `c52c7a57-74ad-433d-a07c-4dcac1778672`
- workspace: "Master Joel Workspace"
- role: owner

## Development Workflow

**Session Restart Protocol:**
1. Read latest restart prompt from `docs/restart-prompts/`
2. Confirm which next-stage option to implement
3. Provide 1-2 steps at a time, wait for confirmation
4. Use "we/our issue" phrasing during troubleshooting

**Next Build Stage Options:**
- A) Implement `artifact.list` (MVP: minimal filters, pagination)
- B) Add explicit NOT_FOUND handling
- C) Standardize response envelopes (success/error format)

**File Naming Convention:**
- Format: `AAA_New_Qwrk__[Type]__[Name]__[Version]__[Date].ext`
- Types: Schema, RLS_Patch, KGB, Snapshot, Execution_Order
- Always use versioning (v1.0, v1.1, etc.)

## Session Management

**Governance:** Session continuity is managed via `sessions/README.md`. This section defines CC trigger behavior.

### Session Trigger Phrases

When user's **first message** contains any of these phrases (or close variations):
- "New session"
- "Start session"
- "I'm back"
- "Let's go"
- "Starting fresh"

### Required Behavior on Session Trigger

1. **Check for orphaned session** — Look for `sessions/CURRENT_SESSION.md`
   - If exists: Warn user and offer Resume / Summarize+Close / Discard options
2. **Read prior context:**
   - Load `sessions/OPEN_THREADS.md` (canonical thread list)
   - Load `sessions/LATEST_END_SESSION.md` (last session details)
3. **Present handoff summary:**
   - Open threads from `OPEN_THREADS.md`
   - Last session summary (from `LATEST_END_SESSION.md`)
   - Any blockers or carry-over reminders
4. **Ask for session intent** — Offer options derived from open threads
5. **Create session marker** — Write `sessions/CURRENT_SESSION.md` with timestamp and intent
6. **Rolling Memory Sync Check** — Compare `for-q` tagged artifacts against current rolling file
   - Read latest `Qwrk_RollingMem/Qwrk_Rolling_Memory__for-q__*.md` (by date)
   - Query Supabase for artifacts tagged `for-q` with valid `for_q_*` fields
   - If new artifacts exist not in rolling file: report delta, offer to regenerate
   - If Gateway unavailable: skip silently (non-blocking)

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
2. Archive `LATEST_END_SESSION.md` to `sessions/Archive/`
3. Write new `LATEST_END_SESSION.md` using **Restart Protocol Format** (see below)
4. Delete `CURRENT_SESSION.md` (if exists)

### Restart Protocol Format (for LATEST_END_SESSION.md)

The restart prompt section of `LATEST_END_SESSION.md` must include:

| Section | Content |
|---------|---------|
| Session Context | Session type (Planning/Execution/Troubleshooting/Mixed), execution surface |
| Thread Inventory | Table with Status: Complete / In-Progress / Blocked / Deferred |
| Decisions Locked | Decisions made this session — do not reopen unless explicitly asked |
| Constraints Discovered | Blockers, limitations, guardrails identified |
| Files Touched | Created / Modified / Archived this session |
| Open Questions | Raised but not resolved |
| Resume Instructions | **Option A** (Directed: specific next action) or **Option B** (Open: await direction) |

See `phase1.5-chat-gateway/Chat Project Files/CONVERSATION_RESTART_PROTOCOL.md` for full template.

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
3. If user agrees: run normal session end procedure
4. Write restart prompt with active planning context preserved

**Mid-session staleness rule:**
- Accept that governance/constraint changes during a session take effect next session
- Simpler and safer than mid-session rule updates
- User can always force restart if urgent

### Rolling Memory Sync Protocol

**Purpose:** Keep CC's rolling governance memory current with Supabase truth.

**Trigger:** Session start (after reading OPEN_THREADS.md, step 6 above)

**Process:**
1. Find latest rolling file: `Qwrk_RollingMem/Qwrk_Rolling_Memory__for-q__*.md`
2. Extract artifact_ids from Section B entries
3. Query Supabase: `SELECT artifact_id FROM qxb_artifact WHERE tags ? 'for-q'`
4. Compare: identify new artifacts not in rolling file
5. If delta exists:
   - Report: "Found X new for-q artifacts not in rolling memory"
   - Offer: "Regenerate rolling file now?"
6. If no delta: proceed silently

**Non-blocking:** If Gateway returns 403/error, log warning and continue session.

**Manual override:** User can always request `regenerate for-q rolling file` mid-session.

**Size Governance (monitor only):**

| Metric | X (Trigger) | Y (Target) | Notes |
|--------|-------------|------------|-------|
| Entry count | 50 entries | 35 entries | Roll off oldest 15 when triggered |
| File size | 150kb | 100kb | Equivalent threshold |

**Current state:** ~10kb / 9 entries — significant headroom remains.

**Roll-off procedure (when needed):**
1. Identify oldest entries by `created_at`
2. Move full entries to `Qwrk_RollingMem/Archive/Qwrk_Rolling_Memory__for-q__YYYY-MM-DD__rolled.md`
3. Keep only index reference in Section C (artifact_id + title + date)
4. Section A constraints always stay (compact summaries)

## Important Constraints

**Immutability Rules:**
- Snapshot and Restart artifacts are immutable (no UPDATE policies)
- Event log is append-only (triggers block UPDATE/DELETE)
- Do NOT create UPDATE/DELETE policies for these tables

**Schema Integrity:**
- Always validate workspace membership before artifact operations
- Respect artifact ownership for private types (journal)
- Event log must reference valid workspace_id + artifact_id
- All timestamps use `timestamptz` with automatic `updated_at` triggers

**n8n Troubleshooting:**
- When node references look wrong, check for wrapped payload issues
- Use Set node to flatten before Supabase insert/update
- Always trim() string comparisons in Switch nodes
- Reference nodes explicitly in expressions: `$node["NodeName"].json.field`

---

## New Qwrk Governance Rules for CC

**Effective Date:** 2026-01-01

### 1) Binding Truth Hierarchy (must obey; never contradict)

1. Behavioral Controls — Governing Constitution
2. Qwrk V2 — North Star (v0.1)
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

**Rationale:** Phase 1 established this pattern successfully (parallel Gateway workflows for bearer-auth). This rule makes it permanent governance, not ad-hoc.

---

## CHANGELOG - CLAUDE.md Updates

### v11 - 2026-02-05
**What changed:** Added Parallel Build Safety Rule (Section 9)

**Why:**
- Phase 1 successfully used parallel workflows to develop new functionality without breaking live systems
- This pattern must become permanent governance, not ad-hoc
- Protects production from regression during feature development

**Scope of impact:**
- New section 9 in "New Qwrk Governance Rules for CC"
- CC must now default to parallel builds when adding features to live systems
- Merge-back requires explicit approval

**How to validate:**
- When asked to add features to a live workflow, CC should propose parallel build
- CC should not modify live paths directly unless explicitly authorized
- Validation step must confirm live path still works

**Previous version:** `Archive/CLAUDE__v10__2026-02-05.md`

### v10 - 2026-02-05
**What changed:** Added Rolling Memory Sync Protocol to Session Management

**Why:**
- CC should automatically detect new `for-q` artifacts at session start
- Rolling memory file needs to stay current with Supabase truth
- Size governance needed for future when entry count grows

**Scope of impact:**
- New step 6 in "Required Behavior on Session Trigger": Rolling Memory Sync Check
- New subsection "Rolling Memory Sync Protocol" with full process
- Size thresholds: 50 entries trigger, 35 entries target (monitor only for now)
- Roll-off procedure documented for when limits are hit

**How to validate:**
- On "new session", CC should check for new for-q artifacts
- If new artifacts found, CC reports delta and offers regeneration
- If Gateway unavailable, CC continues silently (non-blocking)

**Previous version:** `Archive/CLAUDE__v9__2026-02-05.md`

### v9 - 2026-02-04
**What changed:** Added Restart Protocol Format to Session End section

**Why:**
- Designed robust Conversation Restart Protocol for Qwrk (ChatGPT)
- CC should use same structured format for session continuity
- Thread inventory, decisions locked, constraints, files touched ensure complete handoff

**Scope of impact:**
- Session End now references Restart Protocol Format
- New subsection documents required sections for LATEST_END_SESSION.md restart prompt
- References `CONVERSATION_RESTART_PROTOCOL.md` for full template

**How to validate:**
- On "end session", CC writes LATEST_END_SESSION.md with Thread Inventory table
- Restart prompt includes: Session Context, Decisions Locked, Constraints, Files Touched, Resume Instructions
- Next session can resume with full context preserved

**Previous version:** `Archive/CLAUDE__v8__2026-02-04.md`

### v8 - 2026-02-04
**What changed:** Added Database Read-Only Rule (Section 2.5)

**Why:**
- CC was executing Gateway write operations (save, promote, update) via PowerShell
- Write/delete operations are irreversible and require human oversight
- Need explicit governance preventing CC from modifying database state

**Scope of impact:**
- CC can ONLY use `artifact.query` and `artifact.list` via Gateway
- All write operations must be provided as SQL/payload for user to execute manually
- CC verifies results via read query after user confirms execution

**How to validate:**
- CC should never execute artifact.save, artifact.promote, or artifact.update
- CC should present SQL or Gateway payloads for user review
- CC should only run PowerShell for query/list operations

**Previous version:** `Archive/CLAUDE__v7__2026-02-03.md`

### v7 - 2026-02-03
**What changed:** Added Workflow Deployment Checklist to n8n Gateway Workflow Rules section

**Why:**
- When updating sub-workflows (Save, Query, List, etc.), the Gateway must also be updated to point to the new version
- Forgetting this step means the fix appears to have no effect (Gateway still calls old workflow)
- User identified this as a recurring risk during BUG-020 fix deployment

**Scope of impact:**
- New subsection under "n8n Gateway Workflow Rules"
- CC must now remind user to update Gateway when any sub-workflow is modified
- 6-step checklist ensures complete deployment

**How to validate:**
- When CC updates a sub-workflow, it should remind user about Gateway update
- Checklist appears in CLAUDE.md under n8n Gateway section

**Previous version:** `Archive/CLAUDE__v6__2026-02-03.md`

### v6 - 2026-02-03
**What changed:** Added OPEN_THREADS.md as single source of truth for cross-session thread tracking

**Why:**
- Open threads were scattered across end session docs
- Carry-over threads could get lost if one session's handoff was incomplete
- Needed single canonical list for unresolved work

**Scope of impact:**
- New file: `sessions/OPEN_THREADS.md`
- Session start now reads OPEN_THREADS.md + LATEST_END_SESSION.md
- Session end now updates OPEN_THREADS.md before writing end session record

**How to validate:**
- On "new session", CC presents threads from OPEN_THREADS.md
- On "end session", CC updates OPEN_THREADS.md (adds new, closes resolved)
- Threads persist correctly across multiple sessions

**Previous version:** `Archive/CLAUDE__v5__2026-02-03.md`

### v5 - 2026-02-03
**What changed:** Added Session Checkpoint Protocol to Session Management section

**Why:**
- Need documented guidance on when to proactively save session state
- Planning work degrades as context fills — need thresholds
- 70-75% identified as optimal checkpoint window through usage

**Scope of impact:**
- New subsection in Session Management: "Session Checkpoint Protocol"
- CC should now be aware of context thresholds and offer checkpoints
- Mid-session staleness rule documented (governance changes take effect next session)

**How to validate:**
- CC should proactively mention context usage when approaching 70%
- CC should offer to checkpoint before major new topics at high usage
- Planning continuity should improve across session boundaries

**Previous version:** `Archive/CLAUDE__v4__2026-02-03.md`

### v4 - 2026-02-02
**What changed:** Added Session Management section with trigger phrase recognition

**Why:**
- CC failed to recognize "New session" as session start trigger
- User had to explicitly remind CC to enter session mode
- Need deterministic behavior when session phrases are detected

**Scope of impact:**
- New section added after "Development Workflow", before "Important Constraints"
- CC must now check for session triggers on first message of conversation
- If uncertain, CC must ask before proceeding with other work

**How to validate:**
- Say "New session" as first message — CC should read LATEST_END_SESSION.md and present handoff
- CC should create CURRENT_SESSION.md and ask for session intent
- On "end session", CC should archive and write new end session record

**Previous version:** `Archive/CLAUDE__v3__2026-02-02.md`

### v3 - 2026-01-03
**What changed:** Added Pattern C (Archive-based versioning) as preferred default

**Why:**
- Cleaner folder structure - active folders only contain current versions
- Canonical filenames stay consistent (no version number guessing)
- Full version history preserved in Archive/ subfolders
- Better aligns with git versioning and discovery patterns

**Scope of impact:**
- Section 3 (Absolute No-Overwrite Rule) now has 3 patterns (C is preferred)
- Section 4 (Pre-Write Confirmation Gate) updated to mention Archive operations
- Section 5 (Changelog) updated with Archive folder changelog behavior
- All future file updates should use Pattern C unless specific need for A or B

**Pattern C details:**
- Archive folder naming: `Archive/` (capitalized, per directory)
- Archived filename format: `<filename>__v<VERSION>__<DATE>.<ext>`
- Current file uses canonical name (no version suffix)

**How to validate:**
- Review Section 3 for Pattern C definition
- Confirm Pre-Write Confirmation Gate mentions Archive operations
- Check Changelog section for Archive behavior
- Verify this file itself follows Pattern C (v2 in Archive/, v3 is current)

**Previous version:** `Archive/CLAUDE__v2__2026-01-03.md`

### v2 - 2026-01-01
**What changed:** Added "New Qwrk Governance Rules for CC" section

**Why:** Establish strict governance for file versioning, truth hierarchy, and workflow editing to prevent accidental overwrites and maintain Known-Good baseline integrity

**Scope of impact:** All future Claude Code operations in this repository must follow these rules

**How to validate:**
- Review governance rules section
- Confirm Pre-Write Confirmation Gate is clear
- Verify no-overwrite rule is absolute and unambiguous
- Check that truth hierarchy is established

**Previous version:** `CLAUDE__vPREV__2026-01-01.md` (location unknown, predates Archive pattern)
