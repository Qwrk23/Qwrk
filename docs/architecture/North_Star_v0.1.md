# Qwrk V2 — North Star Document

**Guiding architecture and build plan for "New Qwrk" (greenfield rebuild)**

**Version:** 0.1 (Conversation Lock)
**Date:** December 30, 2025
**Owner:** Master Joel

---

## Executive Summary

Qwrk V2 ("New Qwrk") is a governed, multi-user-ready operating system for projects, reflection, and execution. It is being rebuilt from scratch on a new Supabase project and a new Gateway, using a single canonical record spine: `Qxb_Artifact`. All record types spawn from `Qxb_Artifact` and inherit core capabilities (save/query/list/update), similar to how ServiceNow uses Task as a base table for many record types.

**Build approach:** Hybrid cutover. The current Qwrk system remains as an archived reference. New Qwrk is built greenfield (new Supabase + new Gateway). Cutover occurs only after Kernel v1 passes contract tests and governance checks.

---

## What Qwrk Is (Definition)

Qwrk is a **disciplined, governed system for turning intent into execution**. It captures and manages projects and the thinking that supports them (journals, restarts, snapshots), with strong rules around lifecycle, accountability, and historical truth. Qwrk favors **clarity over cleverness** and prioritizes **trust**: the system must reliably retrieve what it saves and enforce its own contracts.

---

## Operating Principles (V2)

- **One canonical spine:** every record is an artifact and spawns from `Qxb_Artifact`
- **Separation of concerns:** lifecycle (maturity) is distinct from operational state (current condition)
- **Governance at the boundary:** Gateway enforces behavioral rules; database enforces access control (RLS)
- **Historical truth:** snapshots and restarts are immutable; deletion is soft
- **Planning-first:** design and contracts are documented and tested before building workflows

---

## Rebuild Scope and Approach

Decisions locked for the rebuild approach:

- New Supabase project (greenfield)
- New Gateway (not reusing the existing Gateway)
- Old Qwrk remains archived as reference; it will not evolve
- Kernel v1 focuses on **Project + Snapshot** with supporting types **Restart** and **Journal**
- QPM (Qwrk Project Management) will be used to track the build project of New Qwrk itself once that functionality is built

---

## Core Data Model — `Qxb_Artifact` Spine

`Qxb_Artifact` is the canonical supertype table. Type-specific tables extend it with a 1:1 relationship using `artifact_id` as both primary key and foreign key.

**Inheritance model (class-table inheritance):**

- Base table: `Qxb_Artifact`
- Type tables: `Qxb_Artifact_Project`, `Qxb_Artifact_Snapshot`, `Qxb_Artifact_Restart`, `Qxb_Artifact_Journal`
- Type table PK = FK: `artifact_id → Qxb_Artifact.artifact_id`
- No duplication of base columns in type tables

---

## `Qxb_Artifact` — Locked Base Columns (v1)

The base table is intentionally lean but indexed for list/query ergonomics. Type-specific fields live in extension tables.

| Column | Type | Purpose |
|--------|------|---------|
| `artifact_id` | uuid | Primary key for the artifact (stable for life) |
| `workspace_id` | uuid | Required. FK to `Qxb_Workspace`. Enforces tenancy boundaries |
| `owner_user_id` | uuid | Required. FK to `Qxb_User`. Canonical ownership |
| `artifact_type` | text | Allow-listed type identifier (Kernel v1: project, snapshot, restart, journal) |
| `title` | text | Human-readable title |
| `summary` | text | Short description for list views and scanning |
| `priority` | int | 1–5 canonical mapping (see below) |
| `lifecycle_status` | text | Canonical lifecycle stage for the artifact (project lifecycle is defined below) |
| `tags` | jsonb | Tag set for filtering and organization |
| `content` | jsonb | Flexible payload (kept minimal; type tables hold structured fields) |
| `parent_artifact_id` | uuid | Optional FK to `Qxb_Artifact`. Used for lineage/spawn relationships |
| `version` | int | Starts at 1; increments on every update |
| `deleted_at` | timestamptz | Soft delete timestamp (null means active) |
| `created_at` | timestamptz | Creation timestamp |
| `updated_at` | timestamptz | Last update timestamp |

**Priority canon (binding):**

- 1 = Critical
- 2 = High
- 3 = Medium
- 4 = Low
- 5 = Plan

---

## Kernel v1 Artifact Types — Semantics

Kernel v1 allow-list for `artifact_type` is locked to four values:

- `project`
- `snapshot`
- `restart`
- `journal`

### Type: project

Projects are execution containers tracked in QPM and governed by lifecycle and operational state.

**Project lifecycle (canonical, binding):**

- **Seed** (idea) → **sapling** (structured idea not yet ready to implement) → **tree** (once a sapling is ready to implement it becomes a tree, i.e. project, with its first "leaf" or work task. Leaves may hang off of "branches" which are different functionality of tree) → **retired**
- `retired` behaves as archived (hidden from default lists; read-only by policy)

**Operational state (separate axis, v1):**

- `active | paused`

**Lifecycle governance:**

- Lifecycle transitions are guarded (not freeform)
- Snapshots are required on lifecycle transitions
- Operational state changes do not require snapshots (use restart when useful)

### Type: snapshot

Snapshots are immutable, lifecycle-triggered records that preserve historical truth. Kernel v1 snapshots apply to projects only.

- **Applies to:** projects only (v1)
- **Created by:** Gateway enforcement (not ad-hoc)
- **Immutability:** fully immutable once created
- **Content:** frozen, fully hydrated project state at the moment of capture
- **Purpose:** audit trail and reflection at meaningful lifecycle transitions

### Type: restart

Restart is a manual, ad-hoc, immutable "freeze + next step" record. It captures state when you need to pause or resume outside of a formal lifecycle transition.

- Created manually via Gateway (`artifact.save` with `artifact_type=restart`)
- Does not imply a lifecycle transition
- Captures frozen hydrated project state (like snapshot) plus restart context (why, next step)
- Immutable once created

### Type: journal

Journals are first-class input records for reflection, intention, and insight. They are included in Kernel v1 to avoid creating special-case ingestion paths later.

- **Note:** journal-specific schema, lifecycle behavior, and linking/spawn rules are still to be defined

---

## Multi-User Foundations (Tenancy + Roles)

The system is **workspace-first** from day one.

- Every artifact has `workspace_id` (required)
- Each user has a default personal workspace created automatically
- Ownership is canonical on `Qxb_Artifact.owner_user_id`
- Collaboration and roles will be represented via join tables (role-ready)
- Authorization is enforced in two places: **Gateway (behavior)** and **database RLS (access)**

### Minimum Identity and Membership Tables (Planned)

- `Qxb_User` (user_id uuid PK; auth mapping fields; status; display metadata)
- `Qxb_Workspace` (workspace_id uuid PK; name; timestamps)
- `Qxb_Workspace_User` (workspace_id + user_id + workspace_role; timestamps)
- `Qxb_Artifact_User_Role` (artifact_id + user_id + artifact_role; timestamps)

---

## Gateway V2 — Contract Decisions

Gateway is rebuilt from scratch (V2) and is **artifact-first**.

- **Artifact-first routing:** all requests are `artifact.{action}` with `artifact_type` parameter
- **Envelope is flat** (n8n-friendly) with `gw_*` prefixed gateway fields
- **Authorization checks** occur at Gateway and are also enforced by database RLS

### Proposed Gateway Envelope (v1 draft)

This is a draft shape; exact required/optional fields remain to be finalized.

| Field | Type | Notes |
|-------|------|-------|
| `gw_user_id` | uuid | Caller identity (maps to `Qxb_User.user_id`) |
| `gw_workspace_id` | uuid | Target workspace for the request (must match membership) |
| `gw_action` | text | save \| query \| list \| update (to be locked) |
| `gw_request_id` | text | Optional correlation id for tracing |
| `gw_policy` | jsonb | Policy flags (e.g., include_deleted, include_archived) |
| `artifact_type` | text | project \| snapshot \| restart \| journal |
| `artifact_id` | uuid | Target id for query/update (optional for save) |
| `artifact_payload` | jsonb | Type-specific payload |
| `selector` | jsonb | Query selectors (id, parent_id, filters) |

---

## Using QPM to Build New Qwrk

As QPM is built out, it will be used to track the project of building New Qwrk. New Qwrk will therefore "self-host" its own build plan, using project artifacts, snapshots at key milestones, restarts for daily handoffs, and journals for reflection and decisions.

---

## Planning-First Documentation Pack (Build-Assist Project Folder)

A dedicated ChatGPT Project will be used as a build-assist workspace. All authoritative documents and schemas will be saved there to prevent drift.

### Recommended Folder/File Set (Create and Maintain)

| File | Purpose |
|------|---------|
| `00_NORTHSTAR_Qwrk_V2.docx` | This North Star document (authoritative) |
| `01_DECISION_LOG.md` | Chronological decision log with rationale and date/version |
| `02_TYPE_REGISTRY.yml` | Allow-listed artifact_type values; required fields; validation rules; hydration rules |
| `03_SCHEMA_DDL.sql` | Authoritative Supabase/Postgres schema for all tables in Kernel v1 |
| `04_RLS_POLICIES.sql` | Row-level security policies for workspace and artifact access |
| `05_GATEWAY_CONTRACT.json` | Gateway request/response schema; error codes; examples |
| `06_LIFECYCLE_RULES.yml` | Allowed lifecycle transitions; snapshot requirements; operational state rules |
| `07_WORKFLOW_SPECS.md` | Gateway workflows by action (save/query/list/update) and contract tests |
| `08_TEST_PLAN.md` | Contract tests, regression checklist, and acceptance criteria |
| `09_INDEX_PLAN.md` | Indexes to support query patterns; performance targets |
| `10_MIGRATION_STRATEGY.md` | Hybrid cutover plan; what (if anything) migrates from old Qwrk; archive policy |
| `11_GLOSSARY.md` | Definitions of terms (artifact, snapshot, restart, lifecycle vs state, etc.) |
| `12_RELEASE_NOTES.md` | Version history and incremental releases for V2 |

---

## Everything Still to Decide (As Complete a List as Possible)

The items below are intentionally open. They must be decided and documented before implementation begins.

### A. Gateway Action Set + Error Model

- Lock the exact `gw_action` allow-list (e.g., save/query/list/update) and define request/response envelopes per action
- Standardize error codes, error payload structure, and retry behavior
- Define correlation/logging fields (gw_request_id, trace ids)

### B. Type Table Schemas (Kernel v1)

- Define `Qxb_Artifact_Project` fields (structured fields vs content jsonb)
- Define `Qxb_Artifact_Snapshot` fields: lifecycle_from/to, captured_version, capture_reason, frozen_payload storage strategy
- Define `Qxb_Artifact_Restart` fields: restart_reason, next_step, frozen_payload strategy
- Define `Qxb_Artifact_Journal` fields: entry_type, mood tags, gratitude, a-ha line, link to projects, etc.

### C. Lifecycle Transition Map (Projects)

- Define allowed transitions among seed/sapling/tree/retired
- Define snapshot-required transitions (likely all lifecycle transitions) and whether additional snapshots are allowed
- Define whether operational_state changes are allowed at each lifecycle stage

### D. Hydration Policy and Query Semantics

- Define when query returns base-only vs base+type merged objects
- Define list view fields (what is returned by default)
- Define selectors: by artifact_id, by parent_artifact_id, by tags, by priority, by lifecycle, by operational_state (project)

### E. Indexing + Search Strategy

- Index plan for common queries (workspace, type, lifecycle, priority, created_at)
- Tag query strategy (jsonb containment vs normalized tags table)
- Full-text search and/or embedding search strategy (if needed later)

### F. Workspace and Role Model Details

- Define workspace roles (owner/admin/member/guest) and artifact roles (owner/editor/viewer) allow-lists
- Define permission matrix: who can save/update/promote lifecycle/create snapshot/restart
- Define invitation model (invites table, expiry, acceptance) for future collaboration

### G. RLS Policy Design

- Define canonical RLS rules for each table (artifact, project, snapshot, restart, journal)
- Decide whether owner has implicit full rights regardless of join roles
- Decide how archived/soft-deleted records are handled (include_deleted/include_archived policy flags)

### H. Audit Logging and Event History

- Decide if/when to add `Qxb_Audit_Event` and/or lifecycle event tables
- Define what is logged for updates (who, when, before/after summary)
- Define immutable event retention and export needs

### I. Environments and Release Discipline

- Dev/staging/prod strategy in Supabase; schema migrations approach
- API/versioning strategy for Gateway contract
- Backup, restore, and disaster recovery expectations

### J. Data Retention + Archival Policies

- Retention by artifact_type; long-term storage for snapshots and journals
- Rules for retiring projects and whether retirement is reversible (recommended: no)

### K. File Attachments and External Artifacts (Optional)

- Whether artifacts can have attachments (Supabase Storage) and how those are referenced
- How to handle rich content (images, PDFs) associated with journals/projects

### L. QPM Alignment Checks

- Compare existing QPM assumptions and tables to this V2 North Star
- Decide what changes are needed so QPM operates naturally on the new spine

---

## Immediate Next Planning Steps (Recommended)

1. Finalize Kernel v1 schemas for `Qxb_Artifact_Project`, `_Snapshot`, `_Restart`, `_Journal`
2. Lock the project lifecycle transition map and snapshot requirements
3. Finalize the Gateway contract (required fields, action set, error model) and write contract tests
4. Draft RLS policies for workspace isolation and artifact access, then validate against the role model
5. Create the QPM build project in New Qwrk (once minimally available) to self-track implementation

---

## Clarifications Requested (Answer When Convenient)

- Do you want 'retired' to be strictly irreversible (recommended) or allow 'unretire' under admin policy?
- Should journals be purely personal to the owner by default, or shareable within a workspace from day one?
- For tags: do you prefer jsonb tags in v1 (fast to ship) or a normalized tags table (more formal)?
- Should snapshots store the frozen payload directly in the snapshot table (jsonb) or reference a separate blob/table for large payloads?

---

**End of North Star Document v0.1**
