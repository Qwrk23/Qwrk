# Qwrk Knowledge Pack — Tier 1: Core Operational

**Purpose:** Consolidated reference for GPT front-end file repository
**Created:** 2026-01-26
**Contents:** Known UUIDs, Global Instruction Pack, North Star v0.4, Mutability Registry v1

---

# SECTION 1: Known UUIDs — Canonical Reference

Use this payload to store the authoritative, frequently-used UUIDs for this Qwrk workspace.
This artifact is intended to prevent memory lookups, reduce errors, and serve as a stable reference.

## Workspace

| Key | UUID |
|-----|------|
| workspace_id | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |

## Identity

| Key | UUID |
|-----|------|
| user_id | `7097c16c-ed88-4e49-983f-1de80e5cfcea` |
| owner_user_id | `c52c7a57-74ad-433d-a07c-4dcac1778672` |

## Instruction Packs

| Pack | artifact_id | scope |
|------|-------------|-------|
| Global | `f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779` | global |
| Build Discipline | `749a965d-3bdb-42d5-9015-f93f637f7cd4` | mode:build |

## History Artifacts

| Artifact | artifact_id | type |
|----------|-------------|------|
| System History Project | `d30bda32-9149-4bba-a2f8-194fca71a265` | project |
| History Entry 001 | `44cff1d8-c2c3-42be-9133-a2aeef5ea925` | journal |

---

# SECTION 2: Instruction Pack — Global (v1)

**artifact_id:** `f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779`
**scope:** `global`
**pack_version:** `v1`
**status:** Active

## Purpose

Defines global behavioral rules that apply across all Qwrk interactions. Establishes shorthand tokens, prompt formatting requirements, and response patterns.

## Invariants

These rules are always enforced regardless of context:

1. **Shorthand Expansion** — Recognized shorthand tokens must be expanded to their defined meanings.
2. **Prompt Formatting** — If the user asks for a prompt of any kind, it must be delivered in a markdown code fence or canvas.
3. **No Unboxed Prompts** — Prompts must never be delivered as plain unboxed prose.

## Rules

### Rule: `shortcut-kg`

**When:** User message contains `kg`

**Then:**
- Interpret `kg` as "keep going"
- Proceed to the next step without re-confirmation unless governance requires it

### Rule: `shortcut-snr`

**When:** User message contains `snr`

**Then:**
- Interpret `snr` as "success, no rows returned"
- Acknowledge result and provide exactly one next query or check

### Rule: `prompt-formatting`

**When:** User message contains any of: `prompt`, `restart prompt`, `paste-ready`, `copy/paste`

**Then:**
- Deliver the prompt in a markdown code fence
- Use canvas only if explicitly requested

## Templates

### Template: `prompt-box-template`

```md
# <TITLE>

<PASTE-READY PROMPT>
```

### Template: `snr-response-template`

```
Acknowledged: success, no rows returned.

Implication: <WHAT THIS MEANS>.

Next step (single):
```sql
<NEXT QUERY>
```
```

## Examples

| Name | Input | Expected Behavior |
|------|-------|-------------------|
| kg shortcut | `kg` | Assistant continues the next step without re-asking |
| snr shortcut | `snr` | Assistant treats it as empty result set and proposes one next query |

---

# SECTION 3: Qwrk V2 — North Star (v0.4)

**Version:** 0.4 (Conversation Lock)
**Date:** January 24, 2026

## Changelog

**v0.4 — 2026-01-24:** Added `limb` as a reserved artifact type for the Structure Layer. Limbs are an optional intermediate layer between Branches and Leaves, representing coherent workstreams or phases within a Branch. Updated execution anatomy to `Project → Branch → Limb (optional) → Leaf`. Supersedes Branch/Leaf Governance Lock (2026-01-18) with updated parent/child rules.

**v0.3 — 2026-01-19:** Added `instruction_pack` as a Kernel v1 artifact type to support external instruction extensions for GPT front-ends.

**v0.2 — 2026-01-18:** Added Branch and Leaf as first-class artifact types to support project execution anatomy.

**v0.1 — 2025-12-30:** Initial North Star document.

## Executive Summary

Qwrk V2 ("New Qwrk") is a governed, multi-user-ready operating system for projects, reflection, and execution. It is being rebuilt from scratch on a new Supabase project and a new Gateway, using a single canonical record spine: `Qxb_Artifact`. All record types spawn from `Qxb_Artifact` and inherit core capabilities (save/query/list/update).

## What Qwrk Is (Definition)

Qwrk is a **disciplined, governed system for turning intent into execution**. It captures and manages projects and the thinking that supports them (journals, restarts, snapshots), with strong rules around lifecycle, accountability, and historical truth. Qwrk favors **clarity over cleverness** and prioritizes **trust**: the system must reliably retrieve what it saves and enforce its own contracts.

## Operating Principles (V2)

- **One canonical spine:** every record is an artifact and spawns from `Qxb_Artifact`
- **Separation of concerns:** lifecycle (maturity) is distinct from operational state (current condition)
- **Governance at the boundary:** Gateway enforces behavioral rules; database enforces access control (RLS)
- **Historical truth:** snapshots and restarts are immutable; deletion is soft
- **Planning-first:** design and contracts are documented and tested before building workflows

## Core Data Model — `Qxb_Artifact` Spine

`Qxb_Artifact` is the canonical supertype table. Type-specific tables extend it with a 1:1 relationship using `artifact_id` as both primary key and foreign key.

**Inheritance model (class-table inheritance):**
- Base table: `Qxb_Artifact`
- Type tables: `Qxb_Artifact_Project`, `Qxb_Artifact_Snapshot`, `Qxb_Artifact_Restart`, `Qxb_Artifact_Journal`, `Qxb_Artifact_Instruction_Pack`, `Qxb_Artifact_Video`
- Type table PK = FK: `artifact_id → Qxb_Artifact.artifact_id`

## Kernel v1 Artifact Types — Semantics

Kernel v1 scope for Gateway v1 MVP includes five artifact types:
- `project`
- `snapshot`
- `restart`
- `journal`
- `instruction_pack`

**Structure Layer (outside Kernel v1 MVP scope):**
- `branch` — Strategic or functional module under a Project
- `limb` — Coherent workstream or phase within a Branch (reserved)
- `leaf` — Executable action item under a Branch or Limb

### Type: project

Projects are execution containers tracked in QPM and governed by lifecycle and operational state.

**Project lifecycle (canonical, binding):**
- **Seed** (idea) → **sapling** (structured idea not yet ready to implement) → **tree** (project with execution structure) → **retired**
- `retired` behaves as archived (hidden from default lists; read-only by policy)

**Operational state (separate axis):**
- `active | paused`

**Lifecycle governance:**
- Lifecycle transitions are guarded (not freeform)
- Snapshots are required on lifecycle transitions
- Operational state changes do not require snapshots

### Type: snapshot

Snapshots are immutable, lifecycle-triggered records that preserve historical truth.
- **Applies to:** projects only (v1)
- **Immutability:** fully immutable once created
- **Content:** frozen, fully hydrated project state at capture

### Type: restart

Restart is a manual, ad-hoc, immutable "freeze + next step" record.
- Created manually via Gateway (`artifact.save` with `artifact_type=restart`)
- Does not imply a lifecycle transition
- Immutable once created

### Type: journal

Journals are first-class input records for reflection, intention, and insight.
- Journal-specific schema and linking rules are still being defined

### Type: instruction_pack

Instruction packs are structured instruction extensions for GPT front-ends.
- **Extension table:** `qxb_artifact_instruction_pack`
- **Scope constraint:** Each instruction pack has a `scope` (e.g., `global`, `view:list`, `action:save`)
- **Uniqueness:** One active instruction_pack per (workspace_id, scope)
- **Mutability:** Mutable — content can be updated

## Project Execution Anatomy (Branch / Limb / Leaf)

### Canonical anatomy (non-negotiable)

```
Tree/Sapling (project)
  → Branch
    → Limb (optional)
      → Leaf
```

**Limbs are OPTIONAL.** Simple projects may use `Branch → Leaf` directly.

### Parent / child rules (binding)

| Artifact | MUST Parent To |
|----------|----------------|
| Branch | Project |
| Limb | Branch |
| Leaf | Branch OR Limb |

### Explicit prohibitions (binding)

- Branch MUST NOT parent Branch
- Limb MUST NOT parent Limb
- Leaf MUST NOT parent any artifact
- Project MUST NOT directly parent Leaf
- Project MUST NOT directly parent Limb

---

# SECTION 4: Mutability Registry (v1)

**Version**: 1
**Status**: Locked

## Mutation Rules Table

| Artifact Type | Field Path | Operation | Notes |
|--------------|------------|-----------|-------|
| **snapshot** | (all fields) | CREATE_ONLY | Fully immutable after creation |
| **restart** | (all fields) | CREATE_ONLY | Fully immutable after creation |
| **project** | lifecycle_status | PROMOTE_ONLY | Must change only via artifact.promote |
| **project** | extension.operational_state | UPDATE_ALLOWED | PATCH semantics allowed |
| **project** | extension.state_reason | UPDATE_ALLOWED | PATCH semantics allowed |
| **journal** | (all fields) | UNDECIDED_BLOCKED | Mutability policy not yet locked |
| **(all types)** | artifact_id | SYSTEM_ONLY | Never user-mutable |
| **(all types)** | workspace_id | SYSTEM_ONLY | Never user-mutable |
| **(all types)** | owner_user_id | SYSTEM_ONLY | Never user-mutable |
| **(all types)** | artifact_type | SYSTEM_ONLY | Never user-mutable |
| **(all types)** | created_at | SYSTEM_ONLY | Never user-mutable |
| **(all types)** | updated_at | SYSTEM_ONLY | Auto-updated by triggers |
| **(all types)** | version | SYSTEM_ONLY | Managed by system |
| **(all types)** | deleted_at | UNDECIDED_BLOCKED | Soft delete mutability not yet locked |

## Operation Definitions

- **CREATE_ONLY**: Field can only be set during artifact creation. No updates allowed.
- **UPDATE_ALLOWED**: Field can be updated via artifact.save with PATCH semantics.
- **PROMOTE_ONLY**: Field can only be changed via artifact.promote, not via artifact.save/update.
- **SYSTEM_ONLY**: Field is managed exclusively by the system. Never user-mutable.
- **UNDECIDED_BLOCKED**: Mutability policy has not been locked. Updates are blocked until decision.

## Enforcement Notes

### Immutable Artifact Types (snapshot, restart)

These artifact types are fully immutable after creation. The Gateway's `artifact.save` workflow enforces this via the `Check_Immutability` node, which returns an `IMMUTABILITY_ERROR` envelope if UPDATE is attempted.

### Project Lifecycle Promotion

The `lifecycle_status` field on project artifacts must change only via the `artifact.promote` Gateway action, not via `artifact.save` UPDATE operations.

### Journal Artifacts (Deferred)

Journal artifact mutability policy is explicitly UNDECIDED and blocked from updates pending design decision.

### System-Managed Fields

Fields marked SYSTEM_ONLY are never user-mutable. These include identity fields (artifact_id, workspace_id, owner_user_id, artifact_type) and system timestamps.

---

**End of Tier 1 Knowledge Pack**
