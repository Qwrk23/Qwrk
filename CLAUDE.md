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
- Currently implements: `artifact.query` (v1 MVP complete)
- Planned: `artifact.list`, enhanced error handling, response envelopes

### Database Schema Architecture

**Class-Table Inheritance Pattern:**
- `qxb_artifact` is the canonical "spine" table containing all core artifact fields
- Type-specific tables extend via PK=FK relationship:
  - `qxb_artifact_project` - lifecycle + operational state tracking
  - `qxb_artifact_snapshot` - immutable jsonb payload
  - `qxb_artifact_restart` - immutable jsonb payload
  - `qxb_artifact_journal` - owner-private text/payload storage
- `qxb_artifact_event` - append-only audit log (protected by triggers)

**Core Tables Dependency Order:**
1. `qxb_user` (maps Supabase auth to Qwrk identity)
2. `qxb_workspace` (every artifact requires workspace_id)
3. `qxb_workspace_user` (role-based membership: owner/admin/member)
4. `qxb_artifact` (spine)
5. Type tables + event log

**Artifact Types:**
- `project` - lifecycle_stage: seed → sapling → tree → retired
- `journal` - owner-private by RLS policy
- `snapshot` - immutable lifecycle snapshots
- `restart` - manual session continuation artifacts

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

---

## CHANGELOG - CLAUDE.md Updates

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
