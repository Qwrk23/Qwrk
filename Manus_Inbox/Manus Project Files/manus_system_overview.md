# Manus Reference — Qwrk System Overview

**Purpose:** Reviewer-oriented architecture overview. Not a canonical source.
**Date:** 2026-03-22
**Canonical sources:** `CLAUDE.md`, `docs/architecture/North_Star_v0.4.md`, `docs/schema/Schema_Reference__Kernel_v1__v2.10.md`

---

## What Qwrk Is

Qwrk V2 is a **workspace-first, artifact-centric system** for turning intent into execution. It captures and manages projects and the thinking that supports them (journals, snapshots, restarts), with strong rules around lifecycle, accountability, and historical truth.

Qwrk favors **clarity over cleverness** and prioritizes **trust**: the system must reliably retrieve what it saves and enforce its own contracts.

---

## System Layers

```
┌─────────────────────────────────────────────┐
│  Execution Surfaces                         │
│  (Chrome Extension, QSB Sidebar, ChatGPT)   │
├─────────────────────────────────────────────┤
│  Gateway Layer (n8n Workflows)              │
│  Routes, validates, normalizes all requests │
├─────────────────────────────────────────────┤
│  Supabase Kernel                            │
│  PostgreSQL + RLS + Auth                    │
└─────────────────────────────────────────────┘
```

### Supabase Kernel
- PostgreSQL database with Row Level Security (RLS)
- All tables deny-by-default
- Service role (used by Gateway) bypasses RLS by design
- RLS exists for structural correctness and defense-in-depth

### Gateway Layer (n8n)
- n8n workflow automation platform
- Single webhook endpoint accepts all operations
- Routes to specialized sub-workflows (Save, Query, List, Update, Promote, Delete, etc.)
- Gateway is the **primary access control and validation layer**
- Enforces type allow-listing, workspace validation, field mutability

### Execution Surfaces
- **Qwrk Chrome Extension (Qx):** Raw JSON payload submission to Gateway
- **Qwrk Sidebar (QSB):** Structured UI for common operations
- **ChatGPT Projects (Q):** Governance and strategy via LLM sessions
- **Claude Code (CC):** Implementation and execution via CLI
- **Mobile:** Gateway access via phone browser

---

## Artifact Spine — Class-Table Inheritance

All data in Qwrk lives in **artifacts**. Every artifact is a row in the `qxb_artifact` spine table, with type-specific data in extension tables.

```
qxb_artifact (spine)
  ├── qxb_artifact_project (lifecycle + operational state)
  ├── qxb_artifact_journal (owner-private text)
  ├── qxb_artifact_snapshot (immutable payload)
  ├── qxb_artifact_restart (immutable payload)
  ├── qxb_artifact_person (identity + contact + relationship)
  ├── qxb_artifact_grass (operational issues)
  ├── qxb_artifact_thorn (exceptions)
  ├── qxb_artifact_instruction_pack (instruction storage)
  ├── qxb_artifact_limb (execution anatomy shell)
  └── qxb_artifact_video (long-form media)
```

**Key rules:**
- Extension tables link to spine via `artifact_id` (PK=FK)
- Spine holds shared fields (title, tags, priority, lifecycle_status, etc.)
- Extension tables hold type-specific fields only
- No duplication of spine columns in extension tables

---

## Artifact Types (15 total, CHECK v8)

| Type | Category | Extension Table | Key Characteristic |
|------|----------|----------------|--------------------|
| `project` | Core | Yes | Lifecycle stages: seed → sapling → tree → archive |
| `journal` | Core | Yes | Owner-private, insert-only |
| `snapshot` | Core | Yes | Immutable payload |
| `restart` | Core | Yes | Immutable session continuation |
| `person` | Core | Yes | Identity, contact, relationship tracking |
| `branch` | Execution | No (spine-only) | Strategic module under a project |
| `limb` | Execution | Yes (shell) | Workstream within a branch (optional) |
| `leaf` | Execution | No (spine-only) | Executable action item (terminal) |
| `grass` | Operational | Yes | Operational issue tracking |
| `thorn` | Operational | Yes | Exception tracking |
| `instruction_pack` | System | Yes | Instruction storage for LLM surfaces |
| `twig` | Experimental | No | Micro-initiative (pilot) |
| `forest` | Reserved | No | In CHECK constraint, no extension table |
| `thicket` | Reserved | No | In CHECK constraint, no extension table |
| `flower` | Reserved | No | In CHECK constraint, no extension table |

---

## Project Execution Anatomy

Projects use a tree metaphor for execution structure:

```
Project (Tree/Sapling)
  └── Branch (strategic module)
       └── Limb (optional workstream)
            └── Leaf (executable action — terminal)
```

- **Branches** must parent to Projects
- **Limbs** must parent to Branches (optional layer)
- **Leaves** must parent to Branches or Limbs
- Leaves are terminal — they cannot parent other artifacts
- No infinite nesting (branch→branch and limb→limb prohibited)

---

## Multi-Forest / Workspace Model

Qwrk supports multiple independent workspaces ("forests"):

| Workspace | Purpose |
|-----------|---------|
| **Prime** (Qwrk Personal) | Joel's primary workspace |
| **Q@W** (Work / Resolve) | Work-context workspace |
| **BlaggLife** | Family workspace |
| **Akara** | Collaborator workspace |
| **Greg** | Friend workspace |

Each workspace is a full tenancy boundary:
- Own artifacts, own membership, own Gateway access
- Gateway validates workspace membership on every request
- Artifacts cannot cross workspace boundaries

---

## Key Architectural Invariants

These are not aspirational — they are enforced:

1. **One canonical spine:** Every record is an artifact spawning from `qxb_artifact`
2. **Immutability where declared:** Snapshots and restarts cannot be updated or deleted
3. **Soft delete only:** `deleted_at` timestamp, never hard delete
4. **Append-only audit:** `qxb_artifact_event` blocks UPDATE and DELETE via triggers
5. **Version increment:** Every mutation increments `version`
6. **Governance at the boundary:** Gateway enforces behavioral rules; database enforces structural constraints

---

## CHANGELOG

### v1 — 2026-03-22
Initial creation for Manus plan reviewer role.
