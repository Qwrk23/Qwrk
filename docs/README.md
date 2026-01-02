# Documentation — New Qwrk Kernel v1

**Authoritative documentation for Qwrk V2 architecture, governance, and design**

---

## Overview

This directory contains all governing documentation for New Qwrk Kernel v1, organized by purpose and authority level.

---

## Directory Structure

```
docs/
├── governance/         # Binding rules and governance
├── architecture/       # Design documents and specifications
├── restart_prompts/    # Session continuation prompts
├── snapshots/          # Immutable design snapshots (JSON)
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

## Governance Documents

Located in `governance/`:

### CLAUDE.md

**Purpose**: Governance rules for Claude Code (AI) collaboration

**Key Rules**:
- No file overwrites (versioned clones only)
- Pre-write confirmation gate
- Changelog requirements
- Truth hierarchy compliance
- n8n workflow editing rules

**Status**: LOCKED (v2, 2026-01-01)

### Mutability_Registry_v1.md

**Purpose**: Binding mutation rules for all artifact fields

**Scope**: Defines which fields are:
- `CREATE_ONLY` (immutable after creation)
- `UPDATE_ALLOWED` (PATCH semantics)
- `PROMOTE_ONLY` (lifecycle transitions only)
- `SYSTEM_ONLY` (never user-mutable)
- `UNDECIDED_BLOCKED` (pending decision)

**Status**: LOCKED (v1, 2026-01-01)

### Doctrine_Journal_InsertOnly_Temporary.md

**Purpose**: Temporary doctrine blocking journal UPDATE operations

**Rule**: Journal artifacts are INSERT-ONLY until permanent mutability policy is locked

**Enforcement**: `NQxb_Artifact_Update_v1` workflow

**Status**: Temporary (pending mutability decision)

### Mutability_Gaps_Decision_Packet_v1.md

**Purpose**: Documents unresolved mutability decisions

**Open Questions**:
- Are project.tags mutable?
- Are project.summary/priority mutable?
- Is journal append-only or patchable?

**Status**: Open (awaiting explicit decisions)

---

## Architecture Documents

Located in `architecture/`:

### North_Star_v0.1.md

**Purpose**: Guiding architecture and build plan for New Qwrk

**Scope**: Executive vision, core principles, data model, multi-user foundations

**Key Sections**:
- Qxb_Artifact spine definition
- Kernel v1 artifact types (project, snapshot, restart, journal)
- Gateway V2 contract
- Multi-user foundations (tenancy + roles)
- Planning-first documentation pack

**Status**: LOCKED (v0.1, 2025-12-30)

### Phase_1-3_Kernel_Semantics_Lock.md

**Purpose**: Lock Kernel v1 semantics before implementation

**Phases**:
- **Phase 1**: Kernel semantics (lifecycle rules, invariants)
- **Phase 2**: Type schemas (paper design)
- **Phase 3**: Gateway contract (action set, envelopes, errors)

**Key Decisions**:
- Retired projects can be unretired (admin-only)
- Snapshots are lifecycle-only (no ad-hoc)
- Restarts are sanctioned ad-hoc freeze mechanism
- Creation-time flexible lifecycle; transitions strict afterward

**Status**: LOCKED (v1, Phase 1-3 complete)

### Behavioral_Controls_Governing_Constitution.md

**Purpose**: Behavioral constitution for Qwrk system

**Branches**:
1. **Core Behavioral Controls** (precision, KG discipline, pacing, governance-first)
2. **Modes** (named behavior packs)
3. **Qwrkflows (QFs)** (governed deterministic workflows)
4. **Personality Layer** (delivery style, not capability)

**Status**: LOCKED (all branches complete)

### Forest_Thicket_Structure_v1.0.md

**Purpose**: Lock Forest/Thicket/Flower structure as first-class artifacts

**Structure**:
- `forest` → major life domains
- `thicket` → groupings within forests
- `tree` (project) → execution containers
- `flower` → lightweight to-do items

**Lineage**: Enforced via `parent_artifact_id`

**Status**: LOCKED (v1.0, 2025-12-30) - Phase 2 implementation

### Future_Builds_v0.1.md

**Purpose**: Deferred features explicitly out of scope for Kernel v1

**Items**:
- Historical Records artifact type (🟡 Conceptual)
- Seed ↔ Flower similarity assist (🟢 Ready for build)

**Status**: Reference only (not binding)

---

## Restart Prompts

Located in `restart_prompts/`:

**Purpose**: Session continuation prompts for context preservation

**Files**:
- `2025-12-30_PostSeed_RLSFix.md` - Kernel v1 post-seed, RLS recursion fix
- `2025-12-31_Gateway.md` - Gateway v1 MVP status

**Usage**: Paste into new conversation to resume work with full context

---

## Snapshots

Located in `snapshots/`:

**Purpose**: Immutable JSON snapshots of design decisions and governance rules

**Files**:
- `Mutability_Registry_v1__snapshot_payload.json`
- `Doctrine_Journal_InsertOnly_Temporary.snapshot.json`
- `Mutability_Gaps_Decision_Packet_v1.snapshot.json`

**Usage**: Machine-readable truth for validation and contract enforcement

---

## How to Use This Documentation

### For Developers

1. **Start with**: [North Star](architecture/North_Star_v0.1.md) for vision
2. **Understand**: [Phase 1-3](architecture/Phase_1-3_Kernel_Semantics_Lock.md) for semantics
3. **Check**: [Mutability Registry](governance/Mutability_Registry_v1.md) before updating fields
4. **Follow**: [CLAUDE.md](governance/CLAUDE.md) for file versioning rules

### For AI Assistants (Claude Code)

1. **MUST READ**: [CLAUDE.md](governance/CLAUDE.md) before ANY file operations
2. **MUST CONSULT**: Truth hierarchy when conflicts arise
3. **MUST FOLLOW**: No-overwrite rule, pre-write confirmation, changelog requirements
4. **MUST RESPECT**: Locked documents (no edits without versioning)

### For Resume/Restart

1. Read latest restart prompt from `restart_prompts/`
2. Review relevant architecture docs for context
3. Check governance docs for current rules

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
- [Schema Documentation](../schema/README.md)
- [Workflow Documentation](../workflows/README.md)

---

**Last Updated**: 2026-01-02
**Documentation Version**: Kernel v1
