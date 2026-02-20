# Mutability Registry (v2)

**Version**: 2
**Created**: 2026-01-01
**Updated**: 2026-02-08
**Purpose**: Memory audit consolidation - binding, immutable reference for artifact field mutation rules
**Status**: Locked

---

## CHANGELOG

### v2 - 2026-02-08
**What changed:** Added universal spine-level tag updates (BUG-017 fix)

**Why:**
- Tags are organizational metadata, not extension content
- Users need to add/remove tags on existing artifacts (including snapshots, restarts)
- Extension immutability is preserved — only spine-level `tags` field is affected

**Scope of impact:**
- New row: `(all types) | tags | UPDATE_ALLOWED`
- Tags use add/remove semantics (not replace-all)
- Snapshots and restarts remain payload-immutable
- Gateway contract unchanged (uses `artifact.update`)

**How to validate:**
- Add tag to snapshot → succeeds
- Add tag to project → succeeds
- Extension update on snapshot → still blocked (IMMUTABILITY_ERROR)
- Tags + extension on snapshot → blocked (extension immutable, tags not applied)

**Previous version:** `Archive/Mutability_Registry_v1__v1__2026-02-08.md`

---

## Mutation Rules Table

| Artifact Type | Field Path | Operation | Notes | Source |
|--------------|------------|-----------|-------|--------|
| **(all types)** | tags | UPDATE_ALLOWED | Spine-level organizational metadata. Add/remove semantics. Does not violate extension immutability. | v2 — BUG-017 |
| **snapshot** | (all extension fields) | CREATE_ONLY | Fully immutable after creation | Phase 1 — Kernel Semantics Lock (D2) |
| **snapshot** | extension.payload | CREATE_ONLY | Frozen payload, no updates allowed | Phase 2 — Type Schemas (D2.3) |
| **restart** | (all extension fields) | CREATE_ONLY | Fully immutable after creation | Phase 1 — Kernel Semantics Lock (D3) |
| **restart** | extension.payload | CREATE_ONLY | Frozen payload, no updates allowed | Phase 2 — Type Schemas (D2.4) |
| **project** | lifecycle_status | PROMOTE_ONLY | Must change only via artifact.promote, not via update | Phase 3 — Gateway Contract (P3-D1) |
| **project** | extension.operational_state | UPDATE_ALLOWED | PATCH semantics allowed | Phase 1 Invariants, Phase 2 — Type Schemas (D2.2) |
| **project** | extension.state_reason | UPDATE_ALLOWED | PATCH semantics allowed | Phase 1 Invariants, Phase 2 — Type Schemas (D2.2) |
| **journal** | (all extension fields) | UNDECIDED_BLOCKED | Extension mutability policy not yet locked | Phase 2 — Deferred Unknowns |
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
- **UPDATE_ALLOWED**: Field can be updated via artifact.update. PATCH semantics for extension fields; add/remove semantics for tags.
- **PROMOTE_ONLY**: Field can only be changed via artifact.promote operation, not via artifact.update.
- **SYSTEM_ONLY**: Field is managed exclusively by the system. Never user-mutable.
- **UNDECIDED_BLOCKED**: Mutability policy has not been locked. Updates are blocked until explicit decision is made.

---

## Tag Update Semantics (v2)

### Add/Remove Model

Tags are updated using explicit add/remove operations, not replace-all:

```json
{
  "action": "artifact.update",
  "workspace_id": "...",
  "artifact_id": "...",
  "artifact_type": "snapshot",
  "tags": {
    "add": ["for-q", "decision"],
    "remove": ["draft"]
  }
}
```

### Rules

- Adding an existing tag is a no-op (idempotent)
- Removing a missing tag is a no-op (idempotent)
- Final stored tags are de-duplicated
- Order does not matter
- Tags are spine-level (`qxb_artifact.tags`), not extension-level

### Combined Updates

Tags can be combined with extension field updates in a single request:

```json
{
  "action": "artifact.update",
  "workspace_id": "...",
  "artifact_id": "...",
  "artifact_type": "project",
  "tags": { "add": ["priority"] },
  "extension": { "operational_state": "active" }
}
```

**Constraint:** If extension fields are present on an immutable type, the **entire request** is rejected. Tags are not partially applied. This prevents ambiguous partial success states.

---

## Enforcement Notes

### Immutable Artifact Types (snapshot, restart)

**Rule**: Extension fields are fully immutable after creation. Tags are updatable.

**Decision matrix:**
- Tags-only update → ALLOWED (bypass extension checks)
- Extension update → BLOCKED (IMMUTABILITY_ERROR)
- Tags + extension update → BLOCKED (extension immutability takes precedence; tags not applied)

**Rationale**: Tags are organizational metadata (labeling). They do not alter the frozen point-in-time record that snapshots and restarts represent.

### Project Lifecycle Promotion

**Rule**: The `lifecycle_status` field on project artifacts must change only via `artifact.promote`.

**Implementation**: The `artifact.promote` action is the exclusive mechanism for lifecycle_status changes. The `artifact.update` workflow returns `MUTABILITY_ERROR` with `PROMOTE_ONLY` hint if lifecycle_stage is provided in extension.

### Journal Artifacts (Deferred)

**Rule**: Journal extension mutability is UNDECIDED and blocked. Tags are updatable.

**Rationale**: Journal extension mutability (content editing) requires design decision on append-only vs editable semantics. Tags are organizational metadata unaffected by this decision.

### System-Managed Fields

**Rule**: Fields marked SYSTEM_ONLY are never user-mutable.

**Enforcement**:
- `artifact_id`: Auto-generated by PostgreSQL
- Workspace/owner/type: Required at INSERT, ignored on UPDATE
- Timestamps: Managed by database triggers
- `version`: Reserved for future optimistic locking

### Soft Delete (Undecided)

**Rule**: The `deleted_at` field mutability is UNDECIDED_BLOCKED.

---

## Compliance & Updates

**This registry is LOCKED as of v2 (2026-02-08).**

Any changes to mutation rules require:
1. Explicit design decision documented in versioned specification
2. Update to this registry with version increment (v3, v4, etc.)
3. Gateway workflow updates to enforce new rules
4. KGB regression to verify no breakage
5. Truth hierarchy approval (Phase 1-3 lock compliance)

---

## Related Documents

- **Phase 1 — Kernel Semantics Lock**: Defines immutability for snapshot, restart
- **Phase 2 — Type Schemas**: Extension table field definitions and constraints
- **Phase 3 — Gateway Contract**: Operation semantics (save, query, list, promote, update)
- **CLAUDE.md**: Governance rules for Claude Code working with Qwrk artifacts
- **BUG-017**: Original bug report — tags not updateable after creation

---

**End of Mutability Registry v2**
