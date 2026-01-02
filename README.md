# New Qwrk Kernel (v1)

**A governed, workspace-first operating system for projects, reflection, and execution**

[![License](https://img.shields.io/badge/license-Proprietary-red.svg)]()
[![Status](https://img.shields.io/badge/status-Active%20Development-yellow.svg)]()

---

## Overview

Qwrk V2 ("New Qwrk Kernel") is a greenfield rebuild of the Qwrk system, built on:

- **Backend**: Supabase (PostgreSQL + Row Level Security)
- **Gateway**: n8n workflow automation
- **Architecture**: Artifact-centric with class-table inheritance

**Core Principle**: One canonical spine (`Qxb_Artifact`) that all record types extend.

---

## Project Status

**Current Phase**: Kernel v1 Implementation
**Last Updated**: 2026-01-02

### Completed ✅

- Phase 1: Kernel Semantics Lock
- Phase 2: Type Schema Design (Paper)
- Phase 3: Gateway Contract v1 (Planning)
- Database Schema v1 (BUNDLE + RLS + KGB)
- Gateway workflows: `artifact.query`, `artifact.list`, `artifact.save`, `artifact.create`, `artifact.update`

### In Progress 🚧

- Repository structure and GitHub integration
- Documentation consolidation
- Known-Good Baseline (KGB) validation

### Planned 📋

- `artifact.promote` workflow (lifecycle transitions)
- Structure Layer (Phase 2): Forest, Thicket, Flower types
- Multi-user collaboration features

---

## Repository Structure

```
new-qwrk-kernel/
├── schema/              # Database schemas (PostgreSQL/Supabase)
├── workflows/           # n8n Gateway workflows (JSON)
├── docs/                # Documentation
│   ├── governance/      # Mutability rules, doctrines
│   ├── architecture/    # Design documents
│   ├── restart_prompts/ # Session continuation prompts
│   └── snapshots/       # Immutable design snapshots (JSON)
├── CLAUDE.md            # AI collaboration rules
└── README.md            # This file
```

---

## Quick Start

### Prerequisites

- Supabase project (ref: `npymhacpmxdnkdgzxll`)
- n8n instance (workflow automation)
- PostgreSQL client (for schema execution)

### Database Setup

```bash
# Navigate to schema directory
cd schema

# Execute in order:
psql -f 01_bundle/AAA_New_Qwrk__Schema__Kernel_v1__BUNDLE__v1.0__2025-12-30.sql
psql -f 03_rls_policies/AAA_New_Qwrk__RLS_Patch__Kernel_v1__v1.2__2025-12-30.sql
psql -f 04_kgb/AAA_New_Qwrk__KGB__Kernel_v1__SQL_Pack__v1.0__2025-12-30.sql
```

See `schema/README.md` for detailed execution order.

### Workflow Import

1. Import Gateway workflow: `workflows/NQxb_Gateway_v1.json`
2. Import artifact workflows from `workflows/` directory
3. See `workflows/README.md` for configuration details

---

## Core Concepts

### Artifact Types (Kernel v1)

- **project**: Execution containers with lifecycle governance (seed → sapling → tree → retired)
- **snapshot**: Immutable lifecycle-triggered records (audit trail)
- **restart**: Manual ad-hoc "freeze + next step" records
- **journal**: First-class reflection and intention records (owner-private)

### Structure Layer (Phase 2 - Planned)

- **forest**: Major life domains (Work, Business, Personal)
- **thicket**: Groupings within forests
- **flower**: Lightweight to-do items

### Gateway Actions

- `artifact.save` - Create new artifacts (auto-detects INSERT)
- `artifact.update` - Update existing artifacts (PATCH semantics)
- `artifact.query` - Retrieve single artifact by ID
- `artifact.list` - List artifacts with filtering/pagination
- `artifact.promote` - Lifecycle transitions (planned)

---

## Architecture Principles

1. **One Canonical Spine**: Every record is an artifact extending `Qxb_Artifact`
2. **Separation of Concerns**: Lifecycle (maturity) ≠ operational state (condition)
3. **Governance at the Boundary**: Gateway enforces behavior; RLS enforces access
4. **Historical Truth**: Snapshots and restarts are immutable; deletion is soft
5. **Planning-First**: Design and contracts documented before implementation

---

## Documentation

- **[North Star](docs/architecture/North_Star_v0.1.md)** - Guiding architecture and vision
- **[Phase 1-3](docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md)** - Kernel semantics and design
- **[Behavioral Constitution](docs/architecture/Behavioral_Controls_Governing_Constitution.md)** - System behavior governance
- **[Mutability Registry](docs/governance/Mutability_Registry_v1.md)** - Field mutation rules
- **[CLAUDE.md](docs/governance/CLAUDE.md)** - AI collaboration rules and constraints

---

## Development Workflow

### Governance Rules

This project follows strict governance:

- **No file overwrites** - All changes use versioned clones
- **Pre-write confirmation** - File operations require explicit approval
- **Changelog requirement** - All changes must document rationale
- **Truth hierarchy** - Conflicts resolved via authoritative documents

See `docs/governance/CLAUDE.md` for complete rules.

### Restart Prompts

Session continuation prompts are in `docs/restart_prompts/` for context preservation.

---

## Contributing

This is a private project under active development by Master Joel.

External contributions are not currently accepted.

---

## License

Proprietary - All Rights Reserved

**Owner**: Master Joel
**Organization**: HaloSparkAI

---

## Contact

For questions or access requests, contact Master Joel.

---

**Last Updated**: 2026-01-02
**Version**: Kernel v1 (Active Development)
