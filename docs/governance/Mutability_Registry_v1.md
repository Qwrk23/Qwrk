# Mutability Registry (v1)

**Version**: 1
**Created**: 2026-01-01
**Purpose**: Memory audit consolidation - binding, immutable reference for artifact field mutation rules
**Status**: Locked

---

## Mutation Rules Table

| Artifact Type | Field Path | Operation | Notes | Source |
|--------------|------------|-----------|-------|--------|
| **snapshot** | (all fields) | CREATE_ONLY | Fully immutable after creation | Phase 1 — Kernel Semantics Lock (D2) |
| **snapshot** | extension.payload | CREATE_ONLY | Frozen payload, no updates allowed | Phase 2 — Type Schemas (D2.3) |
| **restart** | (all fields) | CREATE_ONLY | Fully immutable after creation | Phase 1 — Kernel Semantics Lock (D3) |
| **restart** | extension.payload | CREATE_ONLY | Frozen payload, no updates allowed | Phase 2 — Type Schemas (D2.4) |
| **project** | lifecycle_status | PROMOTE_ONLY | Must change only via artifact.promote, not via update | Phase 3 — Gateway Contract (P3-D1) |
| **project** | extension.operational_state | UPDATE_ALLOWED | PATCH semantics allowed | Phase 1 Invariants, Phase 2 — Type Schemas (D2.2) |
| **project** | extension.state_reason | UPDATE_ALLOWED | PATCH semantics allowed | Phase 1 Invariants, Phase 2 — Type Schemas (D2.2) |
| **journal** | (all fields) | UNDECIDED_BLOCKED | Mutability policy not yet locked | Phase 2 — Deferred Unknowns |
| **(all types)** | artifact_id | SYSTEM_ONLY | Never user-mutable, set at creation | North Star — Canonical Spine |
| **(all types)** | workspace_id | SYSTEM_ONLY | Never user-mutable, set at creation | Workspace-first invariants |
| **(all types)** | owner_user_id | SYSTEM_ONLY | Never user-mutable, set at creation | Ownership invariants |
| **(all types)** | artifact_type | SYSTEM_ONLY | Never user-mutable, set at creation | North Star — Canonical Spine |
| **(all types)** | created_at | SYSTEM_ONLY | Never user-mutable, set at creation | North Star — Canonical Spine |
| **(all types)** | updated_at | SYSTEM_ONLY | Never user-mutable, auto-updated by triggers | North Star — Canonical Spine |
| **(all types)** | version | SYSTEM_ONLY | Never user-mutable, managed by system | North Star — Canonical Spine |
| **(all types)** | deleted_at | UNDECIDED_BLOCKED | Soft delete mutability not yet locked | Explicit non-decision |

---

## Operation Definitions

- **CREATE_ONLY**: Field can only be set during artifact creation (INSERT). No updates allowed after creation.
- **UPDATE_ALLOWED**: Field can be updated via artifact.save with PATCH semantics (only explicitly provided fields are modified).
- **PROMOTE_ONLY**: Field can only be changed via artifact.promote operation, not via artifact.save/update.
- **SYSTEM_ONLY**: Field is managed exclusively by the system. Never user-mutable (not even at creation for some fields like artifact_id).
- **UNDECIDED_BLOCKED**: Mutability policy has not been locked. Updates are blocked until explicit decision is made.

---

## Enforcement Notes

### Immutable Artifact Types (snapshot, restart)

**Rule**: These artifact types are fully immutable after creation. The Gateway's `artifact.save` workflow enforces this via the `Check_Immutability` node, which returns an `IMMUTABILITY_ERROR` envelope if UPDATE is attempted.

**Rationale**: Snapshots and restarts represent point-in-time frozen states. Allowing updates would violate their semantic purpose as historical records.

**Implementation**: `NQxb_Artifact_Save_v1` workflow (v1.2 locked) prevents all UPDATE operations on these types before any DB writes occur.

### Project Lifecycle Promotion

**Rule**: The `lifecycle_status` field on project artifacts must change only via the `artifact.promote` Gateway action, not via `artifact.save` UPDATE operations.

**Rationale**: Lifecycle transitions (seed → sapling → tree → retired) represent significant milestone changes that may trigger workflow automation, notifications, or business logic. These must be intentional, explicit operations separate from general field updates.

**Implementation**: The `artifact.promote` action (not yet implemented) will be the exclusive mechanism for lifecycle_status changes. The `artifact.save` workflow currently allows lifecycle_status updates (v1.2) but this will be locked down when artifact.promote is implemented.

**Alignment Note**: The `lifecycle_stage` field on the project extension table (qxb_artifact_project) is aligned with spine `lifecycle_status` on INSERT but follows the same PROMOTE_ONLY rule for changes.

### Journal Artifacts (Deferred)

**Rule**: Journal artifact mutability policy is explicitly UNDECIDED and blocked from updates pending design decision.

**Rationale**: Journals may be append-only (immutable entries) or editable (correcting typos). The semantic choice affects privacy model, audit trail, and user expectations. This decision was deferred in Phase 2.

**Blocked Behavior**: Until decided, journal UPDATE operations should be blocked or clearly marked as experimental/unstable.

### System-Managed Fields

**Rule**: Fields marked SYSTEM_ONLY are never user-mutable. These include identity fields (artifact_id, workspace_id, owner_user_id, artifact_type) and system timestamps (created_at, updated_at, version).

**Enforcement**:
- `artifact_id`: Auto-generated by PostgreSQL (uuid default)
- Workspace/owner/type: Required at INSERT, ignored on UPDATE (immutable by design)
- Timestamps: Managed by database triggers (`update_updated_at_column()`)
- `version`: Reserved for future optimistic locking (currently defaults to 1)

**Rationale**: These fields form the artifact's identity and audit trail. User mutation would violate referential integrity, workspace scoping, and ownership invariants.

### Soft Delete (Undecided)

**Rule**: The `deleted_at` field mutability is UNDECIDED_BLOCKED pending explicit decision on soft delete semantics.

**Open Questions**:
- Should users be able to set `deleted_at` directly (soft delete), or must deletion go through `artifact.delete` action?
- Should `deleted_at` be reversible (undelete by setting to null), or permanent?
- How do soft-deleted artifacts interact with RLS policies and list views?

**Blocked Behavior**: Until decided, `deleted_at` updates should be blocked or handled only via dedicated `artifact.delete` / `artifact.undelete` actions.

---

## Compliance & Updates

**This registry is LOCKED as of v1 (2026-01-01).**

Any changes to mutation rules require:
1. Explicit design decision documented in versioned specification
2. Update to this registry with version increment (v2, v3, etc.)
3. Gateway workflow updates to enforce new rules
4. KGB regression to verify no breakage
5. Truth hierarchy approval (Phase 1-3 lock compliance)

**How to propose a change**:
1. Create versioned design doc (e.g., `AAA_New_Qwrk__Mutability_Change_Proposal__[Field]__v1.0__YYYY-MM-DD.md`)
2. Document rationale, affected workflows, migration path
3. Get Master Joel approval
4. Implement + test + KGB regression
5. Update this registry to v2 with changelog

---

## Related Documents

- **Phase 1 — Kernel Semantics Lock**: Defines immutability for snapshot, restart
- **Phase 2 — Type Schemas**: Extension table field definitions and constraints
- **Phase 3 — Gateway Contract**: Operation semantics (save, query, list, promote)
- **NQxb_Artifact_Save_v1__README.md**: Documents PATCH semantics and immutability enforcement
- **CLAUDE.md**: Governance rules for Claude Code working with Qwrk artifacts

---

**End of Mutability Registry v1**
