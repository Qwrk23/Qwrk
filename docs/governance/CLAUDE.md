# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Qwrk V2** (New Qwrk Kernel) - A workspace-first, artifact-centric system built on Supabase with n8n workflow automation for gateway operations.

### Core Architecture

**Backend: Supabase Kernel v1**
- Database: PostgreSQL with Row Level Security (RLS) enabled on all tables
- Project ref: `npymhacpmxdnkdgzxll`
- Authentication: Supabase Auth integrated with custom user mapping

**Gateway Layer: n8n Workflows**
- Workflow: `NQxb_Gateway_v1` handles all artifact operations
- KGB-locked actions (2026-01-17): `artifact.save`, `artifact.query`, `artifact.update`, `artifact.list`, `artifact.promote`
- Lifecycle hygiene (2026-01-18): Hydrated responses surface only `lifecycle_status` (canonical); `lifecycle_stage` stripped
- See "Gateway v1 — KGB Lock Status" section for authoritative behavior rules

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
  - `qxb_artifact_instruction_pack` - GPT front-end instruction extensions
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
- `instruction_pack` - GPT front-end instruction extensions (scoped, mutable)
- `branch` - structural execution module under a Project (Structure Layer)
- `limb` - coherent workstream or phase within a Branch (Structure Layer, reserved)
- `leaf` - executable action item under a Branch or Limb (Structure Layer)
- `forest`, `thicket`, `flower` - reserved for future use

### Database Query Rules (CRITICAL)

**MANDATORY: Read LIVE_DDL Before ANY SQL Query**

Before writing ANY SQL query (for user OR for internal verification), you MUST:

1. **Read the LIVE_DDL file first**: `docs/schema/LIVE_DDL__Kernel_v1__YYYY-MM-DD.sql`
2. **Extract exact table and column names** from the CREATE TABLE statements
3. **Verify constraints, enums, and data types** before building WHERE clauses
4. **Only then write the SQL query** using verified names

**NO EXCEPTIONS. NO GUESSING.**

If you write a query without reading LIVE_DDL first and it fails due to wrong column names, that is a **hard governance violation**.

**Why this rule exists:**
- Guessing column names wastes user time with broken queries
- LIVE_DDL is the authoritative source of truth for deployed schema
- Read-only QB access requires correct queries on first attempt

**Process:**
```
1. User asks for query
2. Read LIVE_DDL (use Grep to find specific CREATE TABLE)
3. Verify exact column names
4. Build query with verified names
5. Provide working query to user
```

### SQL Artifact Insertion Patterns (CRITICAL)

**MANDATORY: Complete Field Specification for Artifact INSERT**

When generating SQL to insert artifacts into QB, you MUST follow this pattern:

**Required Pattern:**
```sql
WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    artifact_id,
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags,
    content,           -- REQUIRED: Set to '{}'::jsonb if empty
    parent_artifact_id,
    lifecycle_status,
    priority           -- REQUIRED: Set to 3 (medium) if unspecified
  )
  VALUES (
    gen_random_uuid(),
    '<workspace_id>'::uuid,
    '<owner_user_id>'::uuid,
    '<artifact_type>',
    '<title>',
    '<summary>',
    '["tag1","tag2"]'::jsonb,  -- No spaces in JSON arrays
    '{}'::jsonb,                -- Empty object if no content
    '<parent_artifact_id>'::uuid,
    '<lifecycle_status>',
    3                           -- 1-5 priority scale (3=medium)
  )
  RETURNING artifact_id
)
INSERT INTO qxb_artifact_<type> (
  artifact_id,
  <type_specific_fields>
)
SELECT
  artifact_id,
  <type_specific_values>
FROM new_artifact;
```

**Critical Rules:**
1. **Always include `content` field** - Set to `'{}'::jsonb` if empty (never omit)
2. **Always include `priority` field** - Set to `3` if unspecified (1=lowest, 5=highest)
3. **Compact JSON formatting** - No spaces in arrays: `["tag1","tag2"]` not `["tag1", "tag2"]`
4. **No inline comments in VALUES** - Keep VALUES list clean; comments go above INSERT
5. **Use CTE pattern** - `WITH new_artifact AS (...)` to generate artifact_id once

**Why this pattern:**
- Explicit field specification prevents ambiguity
- Self-documenting INSERT statements
- Ensures consistent artifact creation across all contexts
- Avoids relying on database defaults for critical fields

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
See `QXB Table Design Files/AAA_New_Qwrk__Execution_Order__Kernel_v1__v1.0__2025-12-30.md`

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

## Gateway v1 — KGB Lock Status (2026-01-17)

Gateway v1 is **feature-complete and KGB-locked** for all five core artifact actions.

This section records the authoritative behavior and constraints as of 2026-01-17.
These rules are binding unless explicitly superseded by a future KGB proof.

---

### KGB-Locked Actions

The following Gateway actions are now locked at KGB state:

- artifact.save (previously locked)
- artifact.query (previously locked)
- artifact.update (locked 2026-01-17)
- artifact.list (locked 2026-01-17)
- artifact.promote (locked 2026-01-17)

---

### artifact.update — Mutability Rules

- UPDATE-ONLY semantics enforced
- Allowed fields:
  - operational_state
  - state_reason
- lifecycle_stage:
  - PROMOTE-ONLY
  - Explicitly blocked in update
- snapshot and restart artifacts:
  - Fully immutable
- journal artifacts:
  - INSERT-ONLY
  - Updates blocked (UNDECIDED_BLOCKED)
- Response:
  - Stable acknowledgment only
  - No internal query payload returned

---

### artifact.list — Canonical Listing Contract

- Canonical response envelope:
  - ok
  - gw_action
  - data: { artifacts }
  - meta
  - timestamp
- Pagination model:
  - limit
  - offset
  - as_of anchor (deterministic reads)
- Ordering:
  - created_at DESC
  - artifact_id DESC
- meta.has_more implemented
- total_count intentionally omitted
- Superset fetch capped at 500 rows

---

### artifact.promote — Lifecycle Authority

- Lifecycle mutation allowed ONLY via promote
- Authoritative field:
  - qxb_artifact.lifecycle_status
- extension.lifecycle_stage:
  - Non-authoritative (legacy)
- Promotion effects:
  - Append-only event written to qxb_artifact_event
  - Event payload frozen at write time
- actor_user_id:
  - Nullable (temporary; actor model TBD)

---

### Pinned Proof Artifacts

- Snapshot Artifact ID:
  - 0452fab4-cb93-438c-a706-856c1841769e
- Verified Project Artifact ID:
  - e9601873-9f71-4843-bd81-9ecaccbbf9e3

---

### Lifecycle Field Hygiene (2026-01-18)

- `artifact.query` and `artifact.list` (hydrated) both strip `extension.lifecycle_stage`
- Only `qxb_artifact.lifecycle_status` surfaces in Gateway responses
- Query and list are now symmetric on lifecycle handling
- KGB Proof: `docs/kgb/2026-01-18__KGB_Proof__Gateway_v1__artifact.list__hydrate_lifecycle_clean.md`
- Snapshot Artifact ID: `a98fdd14-ee5e-4b5f-bf03-0227ba3ab845`

---

### Branch/Limb/Leaf Execution Anatomy Governance Lock (2026-01-24)

Branch, Limb, and Leaf are first-class artifact types with locked semantic definitions.

**Supersedes:** Branch/Leaf Governance Lock (2026-01-18)

**Canonical Execution Anatomy (non-negotiable):**
```
Project (Tree/Sapling)
  → Branch
    → Limb (optional)
      → Leaf
```

**Limbs are OPTIONAL.** Simple projects may use `Branch → Leaf` directly.

**Semantic Definitions:**
- **Branch:** Strategic or functional module under a Project
- **Limb:** Coherent workstream or phase within a Branch
- **Leaf:** Executable action item under a Branch or Limb

**Parent/Child Rules (binding):**

| Artifact | MUST Parent To |
|----------|----------------|
| Branch | Project |
| Limb | Branch |
| Leaf | Branch OR Limb |

**Explicit Prohibitions (binding):**
- Branch MUST NOT parent Branch
- Limb MUST NOT parent Limb
- Leaf MUST NOT parent any artifact
- Project MUST NOT directly parent Leaf
- Project MUST NOT directly parent Limb

**Flower Exclusion (binding):**
- Flowers are NOT part of project execution trees
- Flowers MUST NOT appear under Projects, Branches, Limbs, or Leaves
- Limbs MUST NOT appear under Flowers

**Backward Compatibility:**
- Existing `Branch → Leaf` relationships remain valid
- Limbs are additive — no migration required

**Implementation Staging:**
- `limb` — reserved for future use (schema deferred)

**Governance Documents Updated:**
- North Star v0.4: `docs/architecture/North_Star_v0.4.md`
- PRD: `docs/prd/PRD__North_Star_v0.4__Limbs__v1.0.md`
- Kernel Semantics Lock: `docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md`

**Traceability Anchors:**
- DB Constraint: `qxb_artifact_artifact_type_check_v4` (limb not yet added)
- Previous Governance Snapshot Artifact ID: `051b4fcd-5575-4084-a52c-54b5b29d1e6f`
- Previous Structural Snapshot ID: `f587939c-ed35-4db4-ab1c-3873e5677a25`

---

### Instruction Pack Artifact Type (2026-01-19)

`instruction_pack` is now a Kernel v1 artifact type for GPT front-end instruction extensions.

**Purpose:**
Allows rich, detailed behavioral rules to be stored in Supabase and loaded dynamically at GPT session initialization, extending base system instructions beyond character limits.

**Extension Table:** `qxb_artifact_instruction_pack`

**Key Constraints:**
- One active instruction_pack per (workspace_id, scope) enforced by partial unique index
- Trigger enforces `content.scope` matches extension table scope
- `parent_artifact_id` MUST be NULL (instruction_packs are root-level)

**Scope Values:**
- `global` - applies to entire session
- `view:list` - list view formatting rules
- `view:detail` - detail view formatting rules
- `action:save` - save action payload rules
- `action:update` - update action payload rules
- `action:promote` - promote action rules

**Content Structure (content jsonb):**
- `pack_version` - Version identifier
- `scope` - Scope key (must match extension.scope)
- `invariants` - Hard rules that must never be violated
- `rules` - Behavioral rules and constraints
- `templates` - Output formatting templates
- `examples` - Example interactions or payloads

**Mutability:** Mutable (unlike snapshot/restart)

**Initialization Protocol:**
- GPT front-ends call `artifact.list` with `artifact_type=instruction_pack` at session start
- Filter by scope and merge into session memory
- Must complete before any other actions

**Governance Documents Updated:**
- North Star v0.3: `docs/architecture/North_Star_v0.3.md`
- Kernel Semantics Lock: `docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md`

**Status:** DB schema complete; Gateway artifact type allow-list update pending

---

### Deferred (Explicitly Out of Scope for v1)

- Final actor model decision for actor_user_id
- Additional lifecycle transitions (sapling → tree → retired)
- Optional enhancements:
  - meta.total_count
  - selector.sort (v1.1+)

---

**Outcome**

Gateway v1 is now KGB-locked and stable for:
save, query, update, list, and promote.

No further changes are permitted without a new KGB proof.

## Development Workflow

**Session Restart Protocol:**
1. Read latest restart prompt (`12_31_25_RESTART PROMPT — New Qwrk Gateway v.txt`)
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

## CC Inbox Rule v1

**Inbox Folder:** `C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\CC_Inbox`

The CC_Inbox folder is a **trusted ingress point** for intentional artifacts.

**Purpose:**
Any new file placed in CC_Inbox represents an intentional artifact that requires CC's attention.

**Expected Behavior:**
1. **Notice** new files in CC_Inbox (when mentioned or prompted to check)
2. **Read headers** to understand the artifact type and purpose
3. **Await instruction** before taking action

**Rules:**
- CC does NOT automatically process inbox files without explicit instruction
- CC does NOT modify or delete inbox files without explicit approval
- Inbox files are assumed to be authoritative and intentional
- After processing, CC may recommend archiving or moving the file

## Bug Tracker

**File:** `docs/Qwrk_Bug_Tracker.md`

**Purpose:**
Tracks known bugs, defects, and issues discovered during Qwrk development. Provides a persistent record across sessions so issues are not lost or forgotten.

**When to Update:**

| Trigger | Action |
|---------|--------|
| Bug discovered during session | Add new entry with symptoms, root cause (if known), severity |
| Root cause confirmed | Update entry with technical details |
| Fix designed/approved | Document approved fix approach |
| Fix deployed | Move to Closed section with resolution notes |
| Regression found | Reopen or create new entry |

**Severity Levels:**
- **Critical** — Blocks core functionality (e.g., pagination broken)
- **High** — Significant impact, workaround may exist (e.g., false-positive responses)
- **Medium** — Degraded experience but functional (e.g., hydrate flag ignored)
- **Low** — Minor issue or missing feature (e.g., Update not implemented for a type)

**CC Responsibility:**
- Proactively add bugs discovered during work
- Update existing entries when new information emerges
- Reference bug IDs (BUG-XXX) in restart prompts and session handoffs
- Do NOT close bugs without explicit user confirmation of fix deployment

## CC Active Seeds

**File:** `docs/governance/CC_Active_Seeds.md`

**Purpose:**
Tracks Qwrk Seeds that provide directional context for CC behavior. Seeds are not implementation specs—they capture architectural direction, philosophy, and constraints that CC should internalize.

**When to Reference:**
- At session start (read for awareness)
- When making infrastructure, scaling, or architectural recommendations
- When deciding between querying Supabase vs. creating local files

**Current Active Seeds:**

| Seed | UUID | Key Guidance |
|------|------|--------------|
| Infrastructure Capacity & Scaling Assumptions | `441ed127-113f-48e3-aedd-8874ae9ae19a` | Scale based on observed pain, not preemptive optimization |
| CC Read Access via RLS (No Service Role) | `cb506bc8-497a-4eca-8a2a-68a77c07e8cd` | Treat Supabase as authoritative; prefer queries over parallel files |

**CC Responsibility:**
- Internalize seed guidance for relevant recommendations
- Surface conflicts if proposals violate seed constraints
- Do NOT treat seeds as implementation specs—they are direction, not detail

---

## Upcoming Restarts (Build Session Queue)

**File:** `docs/Upcoming_Restarts.md`

**Purpose:**
Tracks queued restart prompts for upcoming build sessions. When Joel asks "What should we work on this morning?", CC reads this file and retrieves the top "Ready to Execute" restart from Qwrk.

**Session Start Protocol:**
1. User asks: "What should we work on this morning?" (or similar)
2. CC reads `docs/Upcoming_Restarts.md`
3. CC retrieves the full restart content from Qwrk using the artifact ID
4. CC presents the action plan and begins execution

**CC Responsibility:**
- ALWAYS check this file when user asks about next work or starts a build session
- Retrieve restart content from Qwrk database (not just the index file)
- After completing a restart, remind user to move it to "Completed" section
- Suggest adding new restarts when roadmap decisions are made

---

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

### 0) Irreducible Core (SUPREME CONSTRAINT)

**Before proposing ANY feature, optimization, or tradeoff, consult the Irreducible Core.**

Location: `docs/governance/Qwrk_Irreducible_Core__v1__DRAFT.md`

The Irreducible Core defines the 10 principles Qwrk will **NEVER** trade away:

| # | Principle | Violation Example |
|---|-----------|-------------------|
| 1 | Artifacts Own Reality | Gateway-as-source-of-truth patterns |
| 2 | Historical Truth Is Immutable | Editing snapshots or restarts |
| 3 | Mistakes Are Recorded, Not Erased | Silent state rewrites |
| 4 | One Canonical Spine | Snowflake tables bypassing qxb_artifact |
| 5 | Structured Records Over Files | Markdown-as-canonical-memory |
| 6 | Explicit Over Implicit | Hidden context carryover |
| 7 | Lifecycle Is Governed | Lifecycle changes via update (not promote) |
| 8 | Human Intent Is Distinguished | Conflating user and model authorship |
| 9 | Privacy By Default | Share-by-default for journals |
| 10 | Planning Before Building | Implementation without contracts |

**Hard Rule:**
If a proposed change violates ANY principle above → **STOP and reject**.

If unclear whether a change violates a principle → **Flag the tension and escalate**.

Convenience, speed, and "everyone else does it" are NOT valid overrides.

---

### 0.5) Build Session Governance (MANDATORY)

**When a build session starts, the Qwrk Build Manifesto is in force.**

Location: `docs/governance/Qwrk_Build_Manifesto_v1.1.md`

The manifesto is **binding operational law** — not aspirational, not motivational. It governs:
- What "on task" means (planning or building; solitaire is not allowed)
- Internal locus of control (blocked = skill issue, scope issue, or angle issue)
- Say-Do Law (collapse intention to action; ship halfway done)
- Shipping over elegance (working > beautiful; evidence > explanation)
- Governance as enabler (constraints make speed safe and compounding)
- History as first-class asset (snapshots, restarts, events capture state)
- Determinism over heroics (contracts > brilliance; system carries discipline)

**Non-negotiables from the manifesto:**
1. Ship something every build session, even if small
2. No new abstractions without a concrete use case
3. If stalled, reduce scope instead of increasing theory
4. If planning exceeds momentum, build immediately

**Old Bull Code applies at all times.**

---

### 1) Binding Truth Hierarchy (must obey; never contradict)

-1. **Qwrk Irreducible Core** — What Qwrk will NEVER trade away (supreme constraint)
0. **Qwrk Build Manifesto** — Operational law for build sessions (how to build)
1. Behavioral Controls — Governing Constitution
2. Qwrk V2 — North Star (v0.4)
3. Kernel v1 Snapshots (Pre/Post KGB)
4. Phase 1–3 Locks (Kernel semantics, type schemas, Gateway contract)
5. Known-Good n8n Workflow Snapshots / KGB results  

**On conflict**: STOP and report:
- What conflicts
- Which document is higher truth
- One clean resolution: “needs versioned update” vs “implementation mistake—correct it”

### 2) No-Guessing Rule (hard stop)

Do NOT invent schemas, enums, tables, endpoints, Gateway actions, lifecycle rules, or payload shapes.

If you lack authoritative truth, STOP and ask for the exact file/section.

---

### 2.5) Final Code Only Rule (System-Wide)

**Scope:** Global — applies to all responses where code or paste-ready artifacts are offered.  
**Binding Strength:** Hard rule (on par with No-Guessing, DDL-as-Truth, No-Overwrite).

#### Core Principle

If code is being offered, it must be **final**.

No additional clarification, decisions, edits, or follow-ups may be required after the code is presented.

If any uncertainty remains, **no code may be produced**.

#### What Counts as “Code”

This rule applies to any copy/paste-ready artifact, including but not limited to:

- SQL
- Bash / shell commands
- n8n JSON or workflow instructions
- Claude Code prompts
- Configuration files (.env, YAML, JSON)
- Markdown intended for commit
- Any content explicitly presented as executable or ready to run

#### Required Sequence

1. Ask all necessary clarification questions  
2. Resolve all ambiguity  
3. Explicitly lock decisions  
4. Produce a single, final code artifact  

#### Exception Handling (Explicit and Loud)

Exceptions are allowed **only** when explicitly invoked.

If an exception is used (e.g., illustrative example, pseudocode, discussion-only), the response **must begin** with the following banner **before any other text**:

🚨🚨🚨 **EXCEPTION IN EFFECT — READ FIRST** 🚨🚨🚨  
🚨🚨🚨 **THIS RESPONSE INTENTIONALLY VIOLATES THE “FINAL CODE ONLY” RULE** 🚨🚨🚨  

**Why you are seeing this:**  
This response contains **NON-FINAL / ILLUSTRATIVE / DISCUSSION-ONLY** material.

**Critical warnings:**  
- ❌ Code below is **NOT ready to execute or paste**  
- ❌ Additional decisions or clarification **ARE REQUIRED**  
- ❌ Treat all code as **conceptual only**

**If you expected final, executable output:**  
⛔ **STOP HERE. DO NOT USE THIS CODE.**

🚨🚨🚨 **EXCEPTION IN EFFECT — END NOTICE** 🚨🚨🚨

#### Enforcement

Violations of this rule are treated as **hard errors** and must be corrected immediately.

---

### 3) Absolute No-Overwrite Rule

**CRITICAL:** You MUST NOT overwrite any existing file in-place.

All changes follow ONE of these allowed patterns:

#### Pattern C: Archive-based Versioning (PREFERRED DEFAULT)
[unchanged]

#### Pattern A: Versioned Clone
[unchanged]

#### Pattern B: Canonical-name Preservation
[unchanged]

---

### 4) Pre-Write Confirmation Gate

**Before writing or renaming any file**, you must output:
- The exact list of files you intend to touch
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

---

## CHANGELOG - CLAUDE.md Updates

### v18 - 2026-01-30
**What changed:** Added **Upcoming Restarts (Build Session Queue)** section documenting `docs/Upcoming_Restarts.md` as the canonical queue for build session handoffs.

**Why:**
To establish a consistent protocol for starting build sessions. When Joel asks "What should we work on this morning?", CC reads the restart queue and retrieves the top action plan from Qwrk.

**Scope of impact:**
- Establishes `docs/Upcoming_Restarts.md` as canonical restart queue
- Defines session start protocol (read queue → retrieve from Qwrk → execute)
- Documents CC responsibilities for restart management

**How to validate:**
- Confirm "Upcoming Restarts (Build Session Queue)" section appears after "CC Active Seeds"
- Verify file path `docs/Upcoming_Restarts.md` is documented
- Confirm session start protocol is defined
- Check Upcoming_Restarts.md file exists with initial entries

**Previous version:** `CLAUDE.md` v17

### v17 - 2026-01-29
**What changed:** Added **CC Active Seeds** section documenting `docs/governance/CC_Active_Seeds.md` as the persistent tracking file for seeds that provide CC directional context.

**Why:**
Seeds capture architectural direction, scaling philosophy, and access constraints that CC should internalize across sessions. This ensures context persists and CC operates under consistent guidance.

**Scope of impact:**
- Establishes `docs/governance/CC_Active_Seeds.md` as canonical seed tracking location
- Documents two initial active seeds:
  - Infrastructure Capacity & Scaling Assumptions
  - CC Read Access via RLS (No Service Role)
- Defines when CC should reference seeds and CC responsibilities

**How to validate:**
- Confirm "CC Active Seeds" section appears after "Bug Tracker"
- Verify file path `docs/governance/CC_Active_Seeds.md` is documented
- Confirm both seed UUIDs listed in table
- Check CC_Active_Seeds.md file exists with both seeds documented

**Previous version:** `CLAUDE.md` v16

### v16 - 2026-01-29
**What changed:** Added **Irreducible Core (SUPREME CONSTRAINT)** section (Rule 0) and updated Binding Truth Hierarchy to include Irreducible Core at position -1.

**Why:**
The Irreducible Core defines the 10 principles Qwrk will NEVER trade away. This is the supreme constraint — if any proposed change violates these principles, the answer is NO. This prevents "death by a thousand compromises" and ensures Qwrk maintains its identity.

**Scope of impact:**
- Establishes `docs/governance/Qwrk_Irreducible_Core__v1__DRAFT.md` as supreme constraint
- All proposed features, optimizations, and tradeoffs must be checked against the 10 principles
- Updates truth hierarchy: Irreducible Core is position -1 (above Build Manifesto)
- Documents the 10 principles with violation examples

**How to validate:**
- Confirm "Irreducible Core (SUPREME CONSTRAINT)" appears as Rule 0
- Verify Irreducible Core path: `docs/governance/Qwrk_Irreducible_Core__v1__DRAFT.md`
- Confirm Irreducible Core is position -1 in Binding Truth Hierarchy
- Verify all 10 principles listed with violation examples

**Previous version:** `CLAUDE.md` v15

### v15 - 2026-01-27
**What changed:** Added **Bug Tracker** section documenting `docs/Qwrk_Bug_Tracker.md` as the persistent bug tracking file for Qwrk development.

**Why:**
To maintain a persistent record of known bugs across sessions, preventing issues from being lost or forgotten during context switches and session restarts.

**Scope of impact:**
- Establishes `docs/Qwrk_Bug_Tracker.md` as canonical bug tracking location
- Documents severity levels (Critical, High, Medium, Low)
- Defines when CC should update the tracker
- Clarifies CC responsibility for proactive bug tracking

**How to validate:**
- Confirm "Bug Tracker" section appears before "Important Constraints"
- Verify file path `docs/Qwrk_Bug_Tracker.md` is documented
- Confirm severity levels and update triggers are listed
- Check bug tracker file exists with initial entries

**Previous version:** `CLAUDE.md` v14

### v14 - 2026-01-24
**What changed:** Updated **Branch/Leaf Execution Anatomy Governance Lock** to **Branch/Limb/Leaf** (2026-01-24). Added `limb` as reserved artifact type in Structure Layer. Updated North Star reference to v0.4.

**Why:**
Limbs are a precision addition to Qwrk's execution anatomy that name an existing cognitive pattern (workstreams within strategic domains). They are optional — simple projects continue using Branch → Leaf. This supersedes the 2026-01-18 governance lock.

**Scope of impact:**
- Adds Limb as optional layer between Branch and Leaf
- Updates parent/child rules: Leaf can now parent to Branch OR Limb
- Reserves `limb` artifact type (schema deferred)
- Updates North Star reference to v0.4
- Backward compatible — no migration required

**How to validate:**
- Confirm "Branch/Limb/Leaf Execution Anatomy Governance Lock (2026-01-24)" section exists
- Verify `limb` added to Artifact Types list as reserved
- Confirm North Star reference is v0.4
- Verify PRD exists: `docs/prd/PRD__North_Star_v0.4__Limbs__v1.0.md`
- Verify North Star v0.4 exists: `docs/architecture/North_Star_v0.4.md`

**Previous version:** `CLAUDE.md` v13

### v13 - 2026-01-22
**What changed:** Added **Build Session Governance (MANDATORY)** section (Rule 0) referencing the Qwrk Build Manifesto v1.1. Updated Binding Truth Hierarchy to include manifesto at position 0. Fixed outdated North Star reference (v0.1 → v0.3).

**Why:**
The Qwrk Build Manifesto is binding operational law for all build sessions. It codifies the high-agency, ship-fast, governance-enabled philosophy that governs how we build Qwrk. This must be explicitly referenced in CLAUDE.md so CC operates under its constraints.

**Scope of impact:**
- Establishes manifesto as binding law during build sessions
- Updates truth hierarchy: manifesto is now position 0
- Documents non-negotiables: ship every session, no abstraction without use case, reduce scope when stalled
- References Old Bull Code as always-applicable

**How to validate:**
- Confirm "Build Session Governance (MANDATORY)" appears before Rule 1
- Verify manifesto path: `docs/governance/Qwrk_Build_Manifesto_v1.1.md`
- Confirm North Star reference updated to v0.3
- Verify manifesto is position 0 in Binding Truth Hierarchy

**Previous version:** `CLAUDE.md` v12

### v12 - 2026-01-19
**What changed:** Added **Instruction Pack Artifact Type (2026-01-19)** section documenting the new `instruction_pack` artifact type for GPT front-end instruction extensions. Added `instruction_pack` to Artifact Types list and `qxb_artifact_instruction_pack` to extension tables list.

**Why:**
`instruction_pack` enables GPT front-ends to load rich, detailed behavioral rules from Supabase at session initialization, extending base system instructions beyond the 8,000 character limit.

**Scope of impact:**
- Documents instruction_pack semantic definition, scope constraints, and content structure
- Records DB schema status (complete) and Gateway status (allow-list update pending)
- References updated governance documents (North Star v0.3, Kernel Semantics Lock)
- Updates Artifact Types list with instruction_pack
- Updates extension tables list with qxb_artifact_instruction_pack

**How to validate:**
- Confirm "Instruction Pack Artifact Type (2026-01-19)" section appears after Branch/Leaf section
- Verify `instruction_pack` added to Artifact Types list
- Verify `qxb_artifact_instruction_pack` added to extension tables list
- Confirm North Star v0.3 exists: `docs/architecture/North_Star_v0.3.md`

**Previous version:** `CLAUDE.md` v11

### v11 - 2026-01-18
**What changed:** Added **Branch/Leaf Execution Anatomy Governance Lock (2026-01-18)** section documenting the canonical governance lock for Branch and Leaf artifact types. Added `branch` and `leaf` to the Artifact Types list.

**Why:**
Branch and Leaf are now first-class artifact types in the Structure Layer, with locked semantic definitions, parent/child rules, and Flower exclusion. This governance lock is persisted in both local documentation and Supabase.

**Scope of impact:**
- Documents canonical execution anatomy: Project → Branch → Leaf
- Records binding parent/child rules and invalid states
- Records Flower exclusion from project execution trees
- References governance snapshot artifact ID: `051b4fcd-5575-4084-a52c-54b5b29d1e6f`
- Updates Artifact Types list with branch and leaf

**How to validate:**
- Confirm "Branch/Leaf Execution Anatomy Governance Lock (2026-01-18)" section appears after Lifecycle Field Hygiene
- Verify `branch` and `leaf` added to Artifact Types list
- Confirm governance snapshot file exists: `docs/snapshots/2026-01-18__SNAPSHOT__Branch_Leaf_Execution_Anatomy_Governance.md`
- Verify artifact ID `051b4fcd-5575-4084-a52c-54b5b29d1e6f` exists in Supabase

**Previous version:** `CLAUDE.md` v10

### v10 - 2026-01-18
**What changed:** Added **Lifecycle Field Hygiene (2026-01-18)** section documenting that hydrated list responses now strip `lifecycle_stage` and surface only canonical `lifecycle_status`. Removed "Query tail update" from Deferred list (now complete).

**Why:**
Gateway v1 achieved symmetric lifecycle handling between `artifact.query` and `artifact.list` (hydrated). Both now strip the non-authoritative `extension.lifecycle_stage` field.

**Scope of impact:**
- Documents lifecycle hygiene for hydrated responses
- Records KGB proof artifact ID for this milestone
- Updates Gateway Layer intro with lifecycle hygiene note
- Removes completed item from Deferred list

**How to validate:**
- Confirm "Lifecycle Field Hygiene (2026-01-18)" section appears after Pinned Proof Artifacts
- Verify KGB proof reference points to `docs/kgb/2026-01-18__KGB_Proof__Gateway_v1__artifact.list__hydrate_lifecycle_clean.md`
- Confirm "Query tail update" removed from Deferred section
- Check Gateway Layer intro includes lifecycle hygiene note

**Previous version:** `CLAUDE.md` v9

### v9 - 2026-01-17
**What changed:** Added **Gateway v1 — KGB Lock Status (2026-01-17)** section documenting the feature-complete lock of all five Gateway actions.

**Why:**
Gateway v1 reached KGB state for all core actions (save, query, update, list, promote). This section provides authoritative reference for locked behavior and constraints.

**Scope of impact:**
- Documents binding rules for all 5 Gateway actions
- Locks mutability rules for artifact.update
- Locks pagination semantics for artifact.list
- Locks lifecycle authority for artifact.promote
- Records pinned proof artifacts
- Lists explicitly deferred work

**How to validate:**
- Confirm "Gateway v1 — KGB Lock Status (2026-01-17)" section appears after "Known-Good State (KGB)"
- Verify all 5 actions listed under "KGB-Locked Actions"
- Confirm pinned artifact IDs match KGB proof documents
- Check "Gateway Layer" intro updated to reference new section

**Previous version:** `CLAUDE.md` v8

### v8 - 2026-01-09
**What changed:** Added **SQL Artifact Insertion Patterns (CRITICAL)** section mandating complete field specification for artifact INSERT statements.

**Why:**
To eliminate ambiguity in artifact creation SQL and enforce consistent, self-documenting INSERT patterns based on observed best practices.

**Scope of impact:**
- Applies to ALL artifact INSERT SQL generation
- Mandates inclusion of `content` field (set to `'{}'::jsonb` if empty)
- Mandates inclusion of `priority` field (set to `3` if unspecified)
- Requires compact JSON formatting (no spaces in arrays)
- Enforces CTE pattern for artifact_id generation

**How to validate:**
- Confirm "SQL Artifact Insertion Patterns (CRITICAL)" section appears after Database Query Rules, before RLS Model
- Verify 5 critical rules are documented
- Confirm pattern template includes all required fields
- Check example shows compact JSON and no inline comments in VALUES

**Previous version:** `CLAUDE.md` v7

### v7 - 2026-01-05
**What changed:** Added **CC Inbox Rule v1** - trusted ingress point for intentional artifacts.

**Why:**
To establish a formal pattern for Master Joel to drop files for CC to process, with clear behavioral expectations (notice, read, await instruction).

**Scope of impact:**
- Applies to files placed in `new-qwrk-kernel/CC_Inbox/`
- CC expected to notice new files when prompted
- CC must await instruction before processing
- Does NOT auto-process inbox files

**How to validate:**
- Confirm "CC Inbox Rule v1" section appears after Development Workflow
- Verify folder path is `new-qwrk-kernel/CC_Inbox`
- Confirm 3-step expected behavior documented (notice, read, await)
- Verify rules prevent auto-processing without approval

**Previous version:** `CLAUDE.md` v6

### v6 - 2026-01-05
**What changed:** Consolidated all valid governance rules from `AAA_New_Qwrk/CLAUDE.md` into this canonical file.

**Why:**
To establish a single authoritative CLAUDE.md for the new-qwrk-kernel project, eliminating confusion between two governance files.

**Sections merged from AAA_New_Qwrk:**
- Gateway Architecture (response format examples, spine-first pattern)
- Database Commands (schema execution order)
- Known-Good State (KGB test IDs, user context)
- Development Workflow (restart protocol, file naming)
- Important Constraints (immutability rules, schema integrity)
- Governance Rules 4-8:
  - Pre-Write Confirmation Gate
  - Changelog Requirement
  - n8n Workflow Editing Rules
  - Known-Good Discipline
  - **Documentation & Derivation Contract (GLOBAL)** ← Critical governance
  - Documentation Duties

**Scope of impact:**
- No semantic changes to existing rules
- All governance preserved and consolidated
- AAA_New_Qwrk/CLAUDE.md marked as SUPERSEDED

**How to validate:**
- Confirm all sections from AAA_New_Qwrk present in this file
- Verify Database Query Rules (v5) and Final Code Only Rule (v4) still intact
- Check AAA_New_Qwrk/CLAUDE.md has supersession header

**Previous version:** `CLAUDE.md` v5

### v5 - 2026-01-05
**What changed:** Added **Database Query Rules (CRITICAL)** section mandating LIVE_DDL verification before ANY SQL query.

**Why:**
To eliminate broken queries caused by guessing column names. CC has read-only QB access and must build working queries on first attempt.

**Scope of impact:**
- Applies to ALL SQL queries (user-requested OR internal verification)
- Mandates reading LIVE_DDL file before writing any SQL
- Treats query failures due to wrong column names as hard governance violations

**How to validate:**
- Confirm "Database Query Rules (CRITICAL)" section appears after artifact types, before RLS Model
- Confirm mandatory 4-step process is documented
- Verify "NO EXCEPTIONS. NO GUESSING." is clearly stated

**Previous version:** `CLAUDE.md` v4

### v4 - 2026-01-04
**What changed:** Added **Final Code Only Rule (System-Wide)** as Rule 2.5.

**Why:**  
To eliminate partial, premature, or ambiguous code delivery and enforce deterministic, paste-once execution across all system interactions.

**Scope of impact:**  
- Governs all future code, SQL, prompts, configs, and executable artifacts
- Applies globally (not CC-specific)
- Introduces mandatory exception signaling when illustrative content is used

**How to validate:**  
- Confirm Rule 2.5 appears between Rule 2 and Rule 3
- Confirm exception banner text matches approved version
- Confirm no other sections were modified

**Previous version:** `CLAUDE.md` (pre-v4, superseded)

### v3 - 2026-01-03
[unchanged]

### v2 - 2026-01-01
[unchanged]
