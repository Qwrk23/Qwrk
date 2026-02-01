# Phase 1-3 Documentation — Kernel Semantics Lock (v1)

---

## Phase 1: Kernel Semantics Lock

### Purpose

Lock the meaning of Kernel v1 records and their governing rules before designing schemas, Gateway contracts, or workflows—so downstream work is deterministic and non-guessy.

### Scope (Kernel v1)

Artifact types in scope:
- `project`
- `snapshot`
- `restart`
- `journal` (included as first-class, schema details later)
- `instruction_pack` (GPT front-end instruction extensions)

**Core principle enforced:**
- One canonical spine: `Qxb_Artifact`
- Type-specific tables extend via 1:1 PK=FK on `artifact_id`

---

### Decisions Locked

#### D1 — Retired projects can be unretired (admin-only)

- `retired` projects are archival by default (hidden from standard lists; read-only behavior for non-admins by policy)
- Unretire is allowed but:
  - Admin-only
  - Explicit action required
  - Must be audited (event record later)
  - Must require a snapshot on the unretire transition

**Rationale:** Enables recovery from premature retirement without turning "retired" into a reversible tag.

#### D2 — Snapshots are lifecycle-only (no ad-hoc snapshots)

- Snapshots are created **only** on lifecycle transitions
- Snapshots are **required** on every lifecycle transition
- Snapshots are **immutable** once created
- No "manual snapshot" capability exists in Kernel v1

**Rationale:** Prevents meaning drift, list noise, storage bloat, and governance complexity. Preserves snapshots as high-signal historical truth.

#### D3 — Restarts are the sanctioned ad-hoc freeze mechanism

- Restarts are manual, immutable, ad-hoc "freeze + next step" records
- Restart does not imply a lifecycle change
- Restart includes contextual fields (e.g., why / next step) plus frozen project state (hydrated payload strategy to be decided later)

**Rationale:** Provides a disciplined manual capture mechanism without diluting snapshot semantics.

#### D4 — Creation-time flexible lifecycle; transitions strict afterward (recommended model chosen)

**Creation rules:**
- A project may be created directly at lifecycle stage:
  - `seed` or `sapling` or `tree`
- A project may not be created as `retired`
- No snapshot is generated at creation (snapshots remain lifecycle-only)

**Transition rules (post-creation):**
- Lifecycle transitions are strictly linear:
  - `seed → sapling`
  - `sapling → tree`
  - `tree → retired`
- No skipping transitions once created
- Unretire path:
  - `retired → tree` (admin-only) with required snapshot

**Rationale:** Allows pragmatic maturity assignment at creation while preserving lifecycle as a governed maturity path thereafter.

---

### Invariants (Must Hold Everywhere Downstream)

#### Lifecycle & History Invariants

- Lifecycle transitions are guarded actions (not freeform edits)
- Snapshots are created on every lifecycle transition, including admin unretire
- Snapshots and restarts are immutable
- "Retired" is archival-by-default and not a casual toggle

#### Separation-of-Axes Invariants

- Lifecycle status is distinct from operational state
- Operational state changes do not require snapshots
- Restart is optional for operational shifts, but snapshots remain lifecycle-only

---

### Artifact Semantic Definitions — Execution Anatomy

**Supersedes:** Branch/Leaf Governance Lock (2026-01-18)
**Updated:** 2026-01-24 — Added Limb as optional intermediate layer

#### Branch (artifact_type = branch)

**Semantic role**
A Branch is a strategic or functional module under a Project (Tree/Sapling).
It exists to organize work into coherent domains but is not itself executable.

**Required parent**
- A Branch MUST have a parent artifact of type `project`

**Disallowed parents**
- `forest`
- `thicket`
- `flower`
- `branch`
- `limb`
- `leaf`
- `snapshot`
- `restart`
- `journal`

**Allowed children**
- `limb`
- `leaf`

**Disallowed children**
- `forest`
- `thicket`
- `flower`
- `project`
- `snapshot`
- `restart`
- `journal`
- `branch`

#### Limb (artifact_type = limb) — Reserved

**Semantic role**
A Limb is a coherent workstream or phase within a Branch.
Limbs provide an optional intermediate layer for organizing related work.

**Implementation status:** Reserved for future use (schema deferred)

**Required parent**
- A Limb MUST have a parent artifact of type `branch`

**Disallowed parents**
- `forest`
- `thicket`
- `flower`
- `project`
- `limb`
- `leaf`
- `snapshot`
- `restart`
- `journal`

**Allowed children**
- `leaf`

**Disallowed children**
- `forest`
- `thicket`
- `flower`
- `project`
- `snapshot`
- `restart`
- `journal`
- `branch`
- `limb`

#### Leaf (artifact_type = leaf)

**Semantic role**
A Leaf is an executable action item under a Branch or Limb.
Leaves represent concrete, actionable work.

**Required parent**
- A Leaf MUST have a parent artifact of type `branch` OR `limb`

**Disallowed parents**
- `forest`
- `thicket`
- `flower`
- `project`
- `leaf`
- `snapshot`
- `restart`
- `journal`

**Disallowed children**
- Any artifact type (Leaves are terminal)

---

### Canonical Execution Anatomy Rule

**Canonical project execution anatomy (non-negotiable)**

```
Tree/Sapling (project)
  → Branch
    → Limb (optional)
      → Leaf
```

**Limbs are OPTIONAL.** Simple projects may use `Branch → Leaf` directly.

Valid patterns:
```
# Simple (no Limbs)
Project → Branch → Leaf

# Complex (with Limbs)
Project → Branch → Limb → Leaf
```

Any deviation from these patterns is an invalid state.

---

### Invalid-State Rules — Execution Anatomy

- A Branch cannot exist without a Project parent
- A Limb cannot exist without a Branch parent
- A Leaf cannot exist without a Branch or Limb parent
- A Branch cannot parent another Branch
- A Limb cannot parent another Limb
- A Leaf cannot parent any artifact
- A Project cannot directly parent a Leaf
- A Project cannot directly parent a Limb

These rules are semantic locks, regardless of current enforcement mechanism.

---

### Backward Compatibility

- Existing `Branch → Leaf` relationships remain valid
- Limbs are additive — no migration required

---

### Flower Exclusion Rule (Binding)

- Flowers are not part of project execution trees
- Flowers MUST NOT appear under Projects, Branches, Limbs, or Leaves
- Limbs MUST NOT appear under Flowers
- Flowers remain lightweight, non-execution artifacts outside the Branch/Limb/Leaf execution anatomy

Any Flower found within a project execution lineage represents a governance violation.

---

### Artifact Semantic Definitions — System Extensions

#### Instruction Pack (artifact_type = instruction_pack)

**Semantic role**
An Instruction Pack stores structured instruction extensions for GPT front-ends.
It allows rich behavioral rules, templates, and examples to be loaded dynamically at session initialization, extending base system instructions beyond character limits.

**Required parent**
- `parent_artifact_id` MUST be NULL (instruction_packs are root-level)

**Disallowed parents**
- All artifact types (instruction_packs cannot be parented)

**Disallowed children**
- All artifact types (instruction_packs do not parent other artifacts)

**Scope constraint (binding)**
- Each instruction pack has a `scope` stored in `content.scope`
- Valid scopes: `global`, `view:list`, `view:detail`, `action:save`, `action:update`, `action:promote`
- One active instruction_pack per (workspace_id, scope) enforced by DB constraint

**Mutability**
- Mutable — content can be updated, packs can be deactivated or replaced
- Unlike snapshot/restart, instruction_pack is not immutable

**Content structure (content jsonb, required fields):**
- `pack_version` — Version identifier
- `scope` — Scope key (must match extension table)
- `invariants` — Hard rules that must never be violated
- `rules` — Behavioral rules and constraints
- `templates` — Output formatting templates
- `examples` — Example interactions or payloads

**Initialization protocol**
- GPT front-ends call `artifact.list` with `artifact_type=instruction_pack` at session start
- Filter by scope tags and merge into session memory
- Must complete before any other actions are permitted

---

### Known Unknowns (Explicitly Deferred to Phase 2+)

- Exact `Qxb_Artifact_Project` structured fields vs content jsonb split
- Snapshot storage strategy (inline frozen payload jsonb vs reference/blob)
- Restart storage strategy (same question as snapshot, plus context fields)
- Journal minimum schema (entry_type/linking/tagging, share defaults)
- Role model allow-lists and permission matrix (workspace roles vs artifact roles)
- Audit/event table design and required fields
- Gateway action set, envelope finalization, and error model
- Hydration rules (base-only vs merged type responses)

---

### Tests (Acceptance Criteria for Phase 1)

Phase 1 is considered complete when:

- These lifecycle rules can be stated unambiguously in one page
- No downstream schema or Gateway design decision contradicts these locks
- We can derive deterministic "allowed/denied" outcomes for:
  - create project at seed/sapling/tree
  - attempt create at retired (denied)
  - seed→tree (denied)
  - retired→tree by non-admin (denied)
  - retired→tree by admin (allowed + snapshot required)

---

### Next Step Gate

Phase 2 may begin only after:

- Phase 1 locks above are accepted as binding
- We proceed to type schema design on paper, starting with `Qxb_Artifact_Project`

---

## Phase 2: Kernel v1 Type Schemas (Paper Design) — v1

### Purpose

Define Kernel v1 type table schemas (paper-only) that extend the canonical spine `Qxb_Artifact`, aligned to the Phase 1 semantic locks and the North Star. No SQL/DDL, no workflows—design truth only.

### Scope (Kernel v1 Types)

- `project`
- `snapshot`
- `restart`
- `journal`
- `instruction_pack`

All types extend `Qxb_Artifact` using class-table inheritance:
- Type table PK = FK: `artifact_id → Qxb_Artifact.artifact_id`
- No duplication of base columns inside type tables

---

### Decisions Locked in Phase 2

#### D2.1 — Project operational_state is expanded

**operational_state allow-list:**
- `active | paused | blocked | waiting`

**Rationale:** Supports real-world execution states without conflating lifecycle.

#### D2.2 — Project state reason is structured

Add a single optional field:
- `state_reason` (text, nullable)

**Usage:** Intended when `operational_state` IN ('blocked','waiting').

**Rationale:** Enables triage and list-view clarity without enum creep or dependency modeling.

#### D2.3 — Snapshot frozen payload stored inline

`Qxb_Artifact_Snapshot` stores:
- `frozen_payload` as jsonb inline in the snapshot row

**Rationale:** Kernel v1 volume is naturally capped (lifecycle-only). Inline keeps truth inspectable and simple.

#### D2.4 — Restart frozen payload stored inline (same pattern as snapshot)

`Qxb_Artifact_Restart` stores:
- `frozen_payload` as jsonb inline

**Rationale:** Consistency across historical truth artifacts; restart differs by intent/context, not storage mechanics.

#### D2.5 — Journals are private by default

Journals are owner-private by default, with explicit sharing later if added.

**Rationale:** Psychological safety and trust; avoids day-one collaboration complexity.

---

### Paper Schema Definitions (Kernel v1)

#### 1) Qxb_Artifact_Project

**Extends:** `Qxb_Artifact`

**Structured fields:**
- `operational_state` (text) — active|paused|blocked|waiting
- `state_reason` (text, nullable)
- `start_date` (date, nullable)
- `target_date` (date, nullable)
- `retired_at` (timestamptz, nullable)
- `last_lifecycle_change_at` (timestamptz)
- `lifecycle_notes` (text, nullable)

**Content (content jsonb) examples:**
- goals/outcomes, constraints, success criteria, plans, narrative notes, rich project details

**Invariants:**
- Lifecycle is governed per Phase 1; operational_state changes do not require snapshots

#### 2) Qxb_Artifact_Snapshot

**Extends:** `Qxb_Artifact`

**Structured fields:**
- `project_artifact_id` (uuid, FK → Qxb_Artifact.artifact_id)
- `lifecycle_from` (text)
- `lifecycle_to` (text)
- `captured_version` (int)
- `frozen_payload` (jsonb) ✅ inline
- `capture_reason` (text, nullable)

**Invariants:**
- Immutable once created
- Created only by Gateway on lifecycle transition
- Lifecycle-only (no ad-hoc snapshots)

#### 3) Qxb_Artifact_Restart

**Extends:** `Qxb_Artifact`

**Structured fields:**
- `project_artifact_id` (uuid, FK → Qxb_Artifact.artifact_id)
- `restart_reason` (text)
- `next_step` (text, nullable)
- `frozen_payload` (jsonb) ✅ inline

**Invariants:**
- Immutable once created
- Manual/ad-hoc
- Does not change lifecycle

#### 4) Qxb_Artifact_Journal

**Extends:** `Qxb_Artifact`

**Structured fields (minimum viable):**
- `entry_type` (text, nullable) — free text in v1
- `related_project_id` (uuid, nullable, FK → Qxb_Artifact.artifact_id)

**Content (content jsonb) examples:**
- main body (markdown/transcript), mood/energy notes, gratitude, insights, decisions, freeform reflection metadata

**Invariants:**
- Owner-private by default
- No lifecycle semantics in Kernel v1

#### 5) Qxb_Artifact_Instruction_Pack

**Extends:** `Qxb_Artifact`

**Structured fields:**
- `scope` (text, not null) — scope key (global, view:list, view:detail, action:save, etc.)
- `pack_version` (text, nullable) — version identifier for the instruction pack
- `active` (boolean, default true) — whether this pack is currently active

**Content (content jsonb) required structure:**
- `pack_version` — Version identifier (mirrored in structured field for query convenience)
- `scope` — Scope key (must match structured field)
- `invariants` — Hard rules that must never be violated
- `rules` — Behavioral rules and constraints
- `templates` — Output formatting templates
- `examples` — Example interactions or payloads

**Constraints:**
- Partial unique index: one active instruction_pack per (workspace_id, scope)
- Trigger enforces content.scope matches extension.scope

**Invariants:**
- Mutable (unlike snapshot/restart)
- Root-level only (parent_artifact_id must be NULL)
- One active pack per scope per workspace

---

### Unknowns / Deferred (Explicit)

- Exact gw_action allow-list, request/response envelope, error model
- Hydration semantics (base-only vs merged responses)
- Workspace/role allow-lists and permission matrix
- RLS policy definitions and "owner override" rules
- Audit/event log tables and required fields
- Index plan (workspace/type/lifecycle/priority/tags/date)
- Tag strategy (jsonb only vs normalized later)
- Journal mutability policy (mutable vs append-only) — not locked yet

---

### Tests (Design Acceptance Criteria for Phase 2)

A Phase 2 design is accepted when:

- Every field has a stated purpose and governance/query justification
- No type table duplicates base columns
- Snapshot/restart immutability remains intact
- Project operational state remains separate from lifecycle
- Journal privacy-by-default is preserved

---

## Phase 3: Gateway Contract v1 (Planning Lock)

### Purpose

Define the Gateway Contract v1 for New Qwrk before implementation.

This contract governs what actions are allowed, how requests and responses are shaped, and how lifecycle, history, and safety rules are enforced—independent of workflow tooling.

**The Gateway is the behavioral governor, not the persistence layer.**

---

### Governing Inputs

- North Star v0.1
- Phase 1 Snapshot — Kernel Semantics Lock
- Phase 2 Snapshot — Kernel Type Schemas (Paper)

All decisions below are binding for Kernel v1 unless explicitly versioned later.

---

### Decisions Locked

#### P3-D1 — Lifecycle transitions use a dedicated action

- Lifecycle transitions occur only via: `artifact.promote`
- Lifecycle changes do **not** occur via `artifact.update`

**Rationale:** Makes snapshot creation unavoidable, prevents accidental lifecycle mutation, and simplifies auditability.

#### P3-D2 — Gateway generates artifact IDs

- On `artifact.save`, the Gateway generates `artifact_id`
- Client-supplied IDs are not allowed

**Rationale:** Avoids collisions, edge cases, and client complexity. Keeps the system deterministic.

#### P3-D3 — Error codes are a locked allow-list

- Gateway errors return stable machine codes from an explicit allow-list
- Free-text or ad-hoc error codes are not permitted

**Rationale:** Error codes become contracts immediately; stability prevents downstream brittleness.

#### P3-D4 — Hydration + projection model (real-world optimized)

**artifact.list:**
- Returns **Base (spine-only)** by default
- Supports:
  - `selector.include_fields` (allow-listed projection)
  - `selector.hydrate = true` (full hydration)

**artifact.query:**
- Returns **Hydrated** by default
- Supports `selector.base_only = true`

**Rationale:** Fast lists by default, rich objects when explicitly requested.

#### P3-D5 — include_fields are allow-listed per artifact_type

- `selector.include_fields` must be validated against an allow-list per `artifact_type`
- Initial allow-list defined for `project`

**Rationale:** Prevents accidental field exposure and contract drift.

---

### Gateway Action Allow-List (v1)

- `artifact.save`
- `artifact.update`
- `artifact.promote`
- `artifact.query`
- `artifact.list`

**Notes:**
- No hard delete action
- Soft delete / archival handled via update + policy later

---

### Request Envelope (v1 — Flat)

**Required (all actions):**
- `gw_user_id` (uuid)
- `gw_workspace_id` (uuid)
- `gw_action` (text)

**Optional (all actions):**
- `gw_request_id` (text)
- `gw_policy` (jsonb)

**Routing / payload fields:**
- `artifact_type` (text)
  - Required for save and list
  - Recommended required for update and promote
- `artifact_id` (uuid)
  - Required for query, update, promote
- `artifact_payload` (jsonb)
  - Required for save, update, promote
- `selector` (jsonb)
  - Used for list and query

---

### Response Envelope (v1)

**Success (single artifact):**
- `ok = true`
- `gw_request_id` (optional echo)
- `artifact` (jsonb)
- `meta` (jsonb, optional)

**Success (list):**
- `ok = true`
- `gw_request_id` (optional echo)
- `items` (array of jsonb)
- `meta`:
  - `count`
  - `next_cursor` (optional)

**Error:**
- `ok = false`
- `gw_request_id` (optional echo)
- `error`:
  - `code` (text, allow-listed)
  - `message` (text)
  - `details` (jsonb, optional)

---

### Error Code Allow-List (v1)

- `AUTH_REQUIRED`
- `WORKSPACE_FORBIDDEN`
- `ARTIFACT_TYPE_NOT_ALLOWED`
- `ACTION_NOT_ALLOWED`
- `VALIDATION_ERROR`
- `NOT_FOUND`
- `CONFLICT`
- `IMMUTABLE_RECORD`
- `LIFECYCLE_TRANSITION_NOT_ALLOWED`
- `SNAPSHOT_REQUIRED`
- `INTERNAL_ERROR`

---

### Selector Schema (v1)

#### artifact.list.selector

- `filters` (jsonb)
- `sort` (jsonb)
- `limit` (int)
- `cursor` (text)
- `include_fields` (array of text, allow-listed)
- `hydrate` (boolean)

**Rules:**
- If `hydrate = true`, ignore `include_fields`
- Otherwise return base fields + requested projections

#### artifact.query.selector

- `base_only` (boolean)

---

### Project include_fields Allow-List (v1)

**Allowed:**
- `operational_state`
- `state_reason`
- `start_date`
- `target_date`
- `retired_at`
- `last_lifecycle_change_at`
- `lifecycle_notes`

---

### Phase 3 Status

✅ Design complete.
❌ No workflows, schemas, or implementation have begun.

---

### Version Note

**2026-01-24:** Added `limb` as reserved artifact type for Structure Layer. Limbs are an optional intermediate layer between Branches and Leaves, representing coherent workstreams or phases. Updated execution anatomy to `Project → Branch → Limb (optional) → Leaf`. Updated parent/child rules: Leaf can now parent to Branch OR Limb. Supersedes 2026-01-18 Branch/Leaf lock.

**2026-01-19:** Added `instruction_pack` as Kernel v1 artifact type for GPT front-end instruction extensions. Defined semantic role, scope constraints, mutability rules, and paper schema.

**2026-01-18:** Added semantic locks for Branch and Leaf execution anatomy; clarified invalid states and Flower exclusion.

---

**End of Phase 1-3 Documentation**
