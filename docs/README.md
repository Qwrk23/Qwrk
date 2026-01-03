# Documentation — New Qwrk Kernel v1

**Authoritative documentation for Qwrk V2 architecture, governance, design, and operations**

---

## Overview

This directory contains all governing and operational documentation for New Qwrk Kernel v1. All files from the former `AAA_New_Qwrk` folder have been consolidated here for unified versioning and discovery.

---

## Directory Structure

```
docs/
├── design/             # Feature design documents (Crawl/Walk/Run stages)
├── prd/                # Product Requirements Documents
├── runbooks/           # Step-by-step operational guides
├── snapshots/          # Canonical Restart and Snapshot artifacts
├── schema/             # QXB database table design files
├── restart-prompts/    # Session continuation prompts
├── playbooks/          # SQL/JSON formatting conventions
├── kgb/                # Known Good Baseline test artifacts
├── contracts/          # API contracts and decision records
├── templates/          # Artifact and process templates
├── trees/              # Build Trees for implementation planning
├── marketing/          # Marketing materials and user communications
├── project-files/      # Project management artifacts
├── workflows/          # n8n workflow documentation
└── README.md           # This file
```

---

## Truth Hierarchy

When conflicts arise, documents are resolved in this order:

1. **Behavioral Controls (Constitution)**
2. **North Star + Phase 1-3 Locks**
3. **Mutability Registry + Doctrines**
4. **Implementation Documentation**

No lower layer may contradict a higher layer.

---

## Key Documentation by Purpose

### `/design/`
Feature design specifications for staged implementation (Crawl/Walk/Run).

**Key Files:**
- `Design__Onboarding_Walk_Stage__Enhanced_MVP__v1.1__2026-01-03.md`
- `Design__Onboarding_Run_Stage__Beta_Ready__v1.1__2026-01-03.md`

### `/prd/`
Product Requirements Documents for major features.

**Key Files:**
- `PRD__Qwrk_World_Separation__Multi_World_Isolation__v1.md` - Multi-world isolation architecture
- `PRD__Operational_Knowledge_Sync__Qwrk_to_CC_GitHub__v1.md` - GitHub sync strategy

### `/runbooks/`
Step-by-step guides for activating and managing features.

**Key Files:**
- `Runbook__Activate_MVP_Signup__Crawl_Stage__v1.1__2026-01-03.md` - Crawl MVP activation guide
- `Runbook__CC_Workflow_Build.md` - Claude Code workflow build process
- `Runbook__Snapshot_and_GitHub_Mirror.md` - Snapshot creation and GitHub sync

### `/snapshots/`
Canonical Restart and Snapshot artifacts capturing frozen system states.

**Key Files:**
- `AAA_New_Qwrk__Restart__People_Intake_Signup_NDA_MVP__2026-01-02__v1.md`
- `AAA_New_Qwrk__Restart__2025-12-30__PostSeed_RLSFix__v1.0.md`
- `[SUPERSEDED]__AAA_New_Qwrk__Restart__BetaSignup_NDA_v1__2026-01-02.md`

### `/schema/`
QXB (Qwrk Execution Baseline) database table design files.

**Key Files:**
- `AAA_New_Qwrk__Schema__Kernel_v1__BUNDLE__v1.0__2025-12-30.sql`
- `AAA_New_Qwrk__RLS_Patch__Kernel_v1__v1.2__2025-12-30.sql`
- `AAA_New_Qwrk__KGB__Kernel_v1__SQL_Pack__v1.0__2025-12-30.sql`
- `AAA_New_Qwrk__Execution_Order__Kernel_v1__v1.0__2025-12-30.md`

### `/restart-prompts/`
Session continuation prompts for resuming work with full context.

**Usage:** Paste into new conversation to resume build sessions.

### `/playbooks/`
Formatting conventions and patterns for SQL, JSON, and Qwrk artifacts.

**Contents:** KGB SQL save patterns, formatting standards.

### `/kgb/`
Known Good Baseline (KGB) test results and validation artifacts.

**Key Files:**
- `KGB__Gateway_EndToEnd__CustomGPT__v1.md`
- `KGB__Save_Project__v1.md`

### `/contracts/`
API contracts and decision records for Gateway and system interfaces.

**Key Files:**
- `Gateway_v1_1__Writes_Enablement__Decision_Record.md`

### `/templates/`
Templates for common artifacts and processes.

**Key Files:**
- `Artifact__History_Report__Template__v1.md`
- `PR__Checklist__v1.md`

### `/trees/`
Build Trees for planning and tracking multi-step implementation work.

**Contents:** Save/Query/List build trees, feature implementation planning.

### `/marketing/`
Marketing materials, update emails, and user-facing communications.

**Contents:**
- Qwrk update emails
- NDA and beta signup materials

### `/project-files/`
Project management artifacts and operational tracking documents.

**Contents:** Thorns and Grass (ops artifacts), archived project files.

### `/workflows/`
n8n workflow documentation and archived workflow JSON files.

**Contents:** Workflow changelogs, archived versions.

---

## Root Documentation Files

### `Doctrine_Journal_InsertOnly_Temporary.md`
Temporary doctrine blocking journal UPDATE operations until permanent mutability policy is locked.

### `Mutability_Gaps_Decision_Packet_v1.md`
Documents unresolved mutability decisions awaiting explicit resolution.

### `Mutability_Registry_v1.md`
Registry of mutability rules for all artifact types and system entities (CREATE_ONLY, UPDATE_ALLOWED, PROMOTE_ONLY, SYSTEM_ONLY).

### `README_BuildTreePack.md`
README for the Qwrk Build Tree Pack for Claude Code.

### `Qwrk_V2.01_Alpha_Custom_Instructions_v1.docx`
Custom instructions document for Qwrk V2 alpha version.

---

## Documentation Governance

Per **CLAUDE.md Section 7.5: Documentation & Derivation Contract**, all documentation follows a single-source-of-truth model:

**Canonical Documentation** (this directory):
- Precise, technical, and complete
- Describes what the system DOES and DOES NOT do
- Written for builders and auditors
- The sole source of truth

**Derived Documentation** (generated downstream):
- User guides
- Marketing guides
- Sales or positioning copy
- Demo scripts or "self-demo" instructions

**Required Metadata:**
Every canonical documentation update MUST include:
- Feature or capability name
- Stage: Crawl / Walk / Run
- Capabilities (what is supported)
- Non-capabilities (what is explicitly not supported)
- User-facing summary (plain language, 1–2 paragraphs)
- Demo safety classification (demo-safe / demo-unsafe / demo-partial)

---

## Finding Documentation

**By Type:**
- Design specs → `/design/`
- PRDs → `/prd/`
- How-to guides → `/runbooks/`
- Historical snapshots → `/snapshots/`
- Database schema → `/schema/`
- Test validation → `/kgb/`

**By Feature:**
- Onboarding system → `/design/`, `/runbooks/`, `/snapshots/`
- Qwrk World Separation → `/prd/PRD__Qwrk_World_Separation__Multi_World_Isolation__v1.md`
- Gateway operations → `/kgb/`, `/contracts/`, `/workflows/`
- Database design → `/schema/`

**By Stage:**
- Crawl MVP → `/runbooks/Runbook__Activate_MVP_Signup__Crawl_Stage__v1.1__2026-01-03.md`
- Walk design → `/design/Design__Onboarding_Walk_Stage__Enhanced_MVP__v1.1__2026-01-03.md`
- Run design → `/design/Design__Onboarding_Run_Stage__Beta_Ready__v1.1__2026-01-03.md`

---

## How to Use This Documentation

### For Developers

1. **Start with**: North Star (in `/schema/` or legacy architecture docs) for vision
2. **Understand**: Phase 1-3 Locks for semantics
3. **Check**: Mutability Registry before updating fields
4. **Follow**: CLAUDE.md (repo root) for file versioning rules

### For AI Assistants (Claude Code)

1. **MUST READ**: `../CLAUDE.md` before ANY file operations
2. **MUST CONSULT**: Truth hierarchy when conflicts arise
3. **MUST FOLLOW**: No-overwrite rule, pre-write confirmation, changelog requirements
4. **MUST RESPECT**: Locked documents (no edits without versioning)

### For Resume/Restart

1. Read latest restart prompt from `/restart-prompts/`
2. Review relevant design/prd docs for context
3. Check governance docs (`Mutability_Registry_v1.md`, `Doctrine_*`) for current rules

---

## Document Versioning

All authoritative documents use semantic versioning:

- `v0.1` - Initial draft
- `v1.0` - Locked for implementation
- `v1.1`, `v1.2` - Minor updates (backward compatible)
- `v2.0` - Major changes (breaking)

**Versioning Pattern**: `[Name]__v[Version]__[Date].[ext]`

---

## Changelog

### 2026-01-03

**What changed:** Consolidated all AAA_New_Qwrk documentation into new-qwrk-kernel/docs/

**Why:** Establish monorepo pattern - documentation lives WITH the code it documents (industry standard)

**Scope of impact:**
- All documentation now versioned in git
- Single source of truth for all Qwrk docs
- CLAUDE.md and .claude/ moved to repo root (where Claude Code expects them)

**Migration:**
- Copied (not moved) all files from AAA_New_Qwrk
- AAA_New_Qwrk remains as backup until validated
- Created comprehensive folder structure for all doc types

**How to validate:**
- Verify all doc types accessible in new structure
- Confirm git tracking all new files
- Test Claude Code recognizes CLAUDE.md at repo root

### 2026-01-02

- Organized documentation into governance/architecture/restart_prompts/snapshots
- Created comprehensive README with truth hierarchy
- Established document versioning conventions

### 2026-01-01

- Added Mutability Registry v1
- Added Journal INSERT-ONLY doctrine
- Added Mutability Gaps decision packet
- Updated CLAUDE.md with governance rules

### 2025-12-30

- Initial documentation structure
- North Star v0.1 locked
- Phase 1-3 documentation completed
- Behavioral Constitution locked
- Forest/Thicket structure locked

---

## References

- [Main README](../README.md)
- [CLAUDE.md (Governance)](../CLAUDE.md)
- [Schema Documentation](../schema/README.md)
- [Workflow Documentation](../workflows/README.md)

---

**Last Updated**: 2026-01-03
**Documentation Version**: Kernel v1 (Consolidated)
**Repository:** [Qwrk23/Qwrk](https://github.com/Qwrk23/Qwrk)
