# PRD: Governance Document Artifact Type (governance_doc)

**Version:** 1.0
**Date:** 2026-01-22
**Status:** Design Only (No Implementation)
**Author:** Claude Code (CC) — Build Assist for New Qwrk

---

## Document Governance

This PRD is a **design document only**. No SQL execution, no Gateway workflow changes.

Aligns with:
- Qwrk V2 North Star v0.3
- Kernel v1 Semantics Lock
- History / Report Artifact Strategy
- Known-Good Baseline (KGB) discipline

**Old-bull rule applies:** clarity > cleverness, governance > speed.

---

## 1. Purpose

The `governance_doc` artifact type represents **authoritative system documentation** — the normative truth about how Qwrk works and decides.

**Examples of governance documents:**
- North Star (system architecture and principles)
- Kernel Semantics Lock (binding semantic decisions)
- Gateway Contract (behavioral rules)
- Behavioral Constitution (agent guidelines)
- Registry behavior specifications

**Key distinction from existing types:**

| Type | Purpose | Mutability |
|------|---------|------------|
| `snapshot` | Lifecycle-triggered historical truth | Immutable |
| `restart` | Ad-hoc freeze + next step | Immutable |
| `instruction_pack` | GPT front-end instruction extensions | Mutable |
| `governance_doc` | System normative truth with versioned history | Mutable with auto-archive |

---

## 2. Scope

### In Scope

- Artifact type definition and extension table schema
- Automatic versioning semantics
- Auto-archive behavior on update
- Version history query model
- Export/mirror design (Markdown, GitHub)
- Security and authority model
- Triggers for creation/update

### Non-Goals

- SQL execution or Gateway implementation
- Replacing Snapshot or Restart semantics
- UI design or front-end integration
- Multi-workspace federation of governance docs
- Real-time collaboration on document editing

---

## 3. Artifact Definition

### 3.1 Artifact Type

```
artifact_type = 'governance_doc'
```

### 3.2 Semantic Role

A `governance_doc` is a **mutable normative artifact** with **automatic version archiving**.

- **Mutable:** Content can be updated (unlike snapshot/restart)
- **Auto-archive:** Each update creates an immutable archive record of the prior version
- **Versioned:** Full version history is queryable
- **Authoritative:** Represents binding system truth

### 3.3 Base Artifact Usage

The `qxb_artifact` spine provides:

| Field | Usage for governance_doc |
|-------|--------------------------|
| `artifact_id` | Stable identifier (does not change across versions) |
| `workspace_id` | Workspace scope (see Security section) |
| `owner_user_id` | Document owner (typically admin/service account) |
| `artifact_type` | `'governance_doc'` |
| `title` | Document title (e.g., "North Star v0.3") |
| `summary` | Brief description of document purpose |
| `priority` | Not used (nullable) |
| `lifecycle_status` | `'draft' \| 'active' \| 'superseded' \| 'retired'` |
| `tags` | Document classification tags |
| `content` | Full document content (see Content Structure) |
| `parent_artifact_id` | NULL (governance_docs are root-level) |
| `version` | Increments on each update |
| `deleted_at` | Soft delete timestamp |
| `created_at` | Creation timestamp |
| `updated_at` | Last update timestamp |

---

## 4. Extension Table Schema (Paper Design)

### 4.1 qxb_artifact_governance_doc

```sql
-- PAPER SCHEMA ONLY — DO NOT EXECUTE

create table if not exists public.qxb_artifact_governance_doc (
  artifact_id uuid primary key,

  -- Document classification
  doc_type text not null
    check (doc_type in (
      'north_star',
      'semantics_lock',
      'gateway_contract',
      'behavioral_constitution',
      'registry_spec',
      'other'
    )),

  -- Version metadata
  doc_version text not null,           -- Semantic version (e.g., "v0.3", "v1.0")
  effective_date timestamptz null,     -- When this version became effective
  supersedes_version text null,        -- Previous doc_version this replaces

  -- Archive linkage
  is_current boolean not null default true,  -- Is this the current active version?
  archived_from_id uuid null,          -- If archived, points to the live artifact_id

  -- Export tracking
  last_exported_at timestamptz null,   -- Last Markdown export timestamp
  github_mirror_url text null,         -- GitHub file URL if mirrored
  github_commit_sha text null,         -- Last GitHub commit SHA

  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint qxb_artifact_governance_doc_fk
    foreign key (artifact_id)
    references public.qxb_artifact (artifact_id)
    on delete cascade
);
```

### 4.2 Field Justification

| Field | Purpose | Governance/Query Justification |
|-------|---------|-------------------------------|
| `doc_type` | Classifies document category | Query: "list all north_star versions" |
| `doc_version` | Human-readable version string | Display and reference |
| `effective_date` | When version became binding | Audit: "what was active on date X?" |
| `supersedes_version` | Links to prior version | Version chain traversal |
| `is_current` | Fast filter for active version | Query: "get current North Star" |
| `archived_from_id` | Links archive to live doc | Version history retrieval |
| `last_exported_at` | Export tracking | Sync status |
| `github_mirror_url` | GitHub location | Cross-reference |
| `github_commit_sha` | Commit tracking | Verify sync state |

### 4.3 Constraints

```sql
-- PAPER SCHEMA ONLY — DO NOT EXECUTE

-- One current version per (workspace_id, doc_type)
create unique index idx_governance_doc_current_per_type
on public.qxb_artifact_governance_doc (artifact_id)
where is_current = true;

-- Actually, we need workspace_id from the parent table
-- This would be implemented as a partial unique index via a function or trigger
```

**Constraint intent:** Only one `governance_doc` with `is_current = true` per `(workspace_id, doc_type)` combination.

---

## 5. Versioning & Archive Semantics

### 5.1 Version Increment Model

On every `artifact.update` to a `governance_doc`:

1. **Spine `version` increments** (existing mechanism)
2. **Auto-archive triggered** (new behavior)

### 5.2 Auto-Archive Behavior

When a `governance_doc` is updated:

1. **Before update commits:**
   - Create a new `governance_doc` artifact as archive copy
   - Archive copy receives:
     - New `artifact_id` (different from live doc)
     - Same `workspace_id`, `owner_user_id`
     - `lifecycle_status = 'superseded'`
     - `is_current = false`
     - `archived_from_id = <live_artifact_id>`
     - Frozen `content` from pre-update state
   - Archive copy is **immutable** after creation

2. **Live document updated:**
   - `version` increments
   - `doc_version` may change (e.g., "v0.2" → "v0.3")
   - `supersedes_version` set to prior `doc_version`
   - `updated_at` refreshed

### 5.3 Version History Query

```
-- Pseudocode: Get full version history for a governance doc
SELECT * FROM qxb_artifact a
JOIN qxb_artifact_governance_doc g ON a.artifact_id = g.artifact_id
WHERE g.archived_from_id = '<live_artifact_id>'
   OR a.artifact_id = '<live_artifact_id>'
ORDER BY a.created_at DESC;
```

### 5.4 Immutability Rules

| Record State | Mutable? | Notes |
|--------------|----------|-------|
| Live (`is_current = true`) | Yes | Updates trigger auto-archive |
| Archived (`is_current = false`) | No | Immutable once created |
| Superseded (`lifecycle_status = 'superseded'`) | No | Historical record |

---

## 6. Relationship to Snapshot / Restart / History

### 6.1 Clear Distinctions

| Aspect | Snapshot | Restart | governance_doc |
|--------|----------|---------|----------------|
| **Purpose** | Lifecycle milestone | Ad-hoc freeze + next | Normative system truth |
| **Trigger** | Lifecycle transition | Manual | Document update |
| **Applies to** | Projects | Projects | System documentation |
| **Mutability** | Immutable | Immutable | Mutable (with archive) |
| **History** | Point-in-time | Point-in-time | Full version chain |

### 6.2 Non-Dilution Guarantees

- `governance_doc` does NOT replace Snapshot for project lifecycle
- `governance_doc` does NOT replace Restart for ad-hoc project freezes
- Snapshot remains "lifecycle-only" — governance_doc changes do not create snapshots
- Restart remains "manual freeze" — governance_doc has its own archive mechanism

### 6.3 History/Report Integration

Governance documents may spawn or reference:
- **History artifacts:** For tracking governance document changes over time
- **Report artifacts:** For generated compliance or change reports

However, `governance_doc` is NOT a History or Report — it IS the authoritative source that histories/reports reference.

---

## 7. Content Structure

### 7.1 Required Content Fields

```json
{
  "doc_version": "v0.3",
  "doc_type": "north_star",
  "effective_date": "2026-01-19T00:00:00Z",

  "metadata": {
    "author": "Master Joel",
    "reviewers": ["Claude Code"],
    "change_summary": "Added instruction_pack as Kernel v1 type"
  },

  "body": {
    "format": "markdown",
    "content": "# Full document content here..."
  },

  "changelog": [
    {
      "version": "v0.3",
      "date": "2026-01-19",
      "changes": ["Added instruction_pack"]
    },
    {
      "version": "v0.2",
      "date": "2026-01-18",
      "changes": ["Added Branch and Leaf"]
    }
  ]
}
```

### 7.2 Content Validation

Gateway should validate:
- `content.doc_version` matches extension `doc_version`
- `content.doc_type` matches extension `doc_type`
- `body.content` is non-empty
- `changelog` array exists (can be empty for v0.1)

---

## 8. Export / Mirror Model (Design Only)

### 8.1 Markdown Export

**Export action:** `artifact.export` (new Gateway action, design only)

```json
{
  "gw_action": "artifact.export",
  "artifact_type": "governance_doc",
  "artifact_id": "<uuid>",
  "export_format": "markdown"
}
```

**Export produces:**
- Full Markdown document with frontmatter
- Filename pattern: `<doc_type>__<title_slug>__<doc_version>.md`
- Example: `north_star__qwrk_v2__v0.3.md`

### 8.2 GitHub Mirror Strategy

**Qwrk remains canonical; GitHub is a mirror.**

Mirror workflow (conceptual):
1. On governance_doc update → trigger export
2. Export Markdown to local file system
3. Commit to GitHub repo (docs/ folder)
4. Update `github_mirror_url` and `github_commit_sha`

**Mirror location:**
```
github.com/qwrk/qwrk-kernel/
└── docs/
    └── governance/
        ├── CURRENT_STATE.md          # Pointer to current versions
        ├── north_star/
        │   ├── current.md            # Symlink or copy of latest
        │   └── archive/
        │       ├── v0.1.md
        │       ├── v0.2.md
        │       └── v0.3.md
        └── gateway_contract/
            ├── current.md
            └── archive/
                └── v1.0.md
```

### 8.3 CURRENT_STATE.md Pointer

A generated index file listing all current governance documents:

```markdown
# Qwrk Governance Documents — Current State

Last updated: 2026-01-22T15:00:00Z

## Active Documents

| Document | Version | Effective | Link |
|----------|---------|-----------|------|
| North Star | v0.3 | 2026-01-19 | [View](north_star/current.md) |
| Gateway Contract | v1.0 | 2026-01-03 | [View](gateway_contract/current.md) |
| Kernel Semantics Lock | v1.0 | 2025-12-30 | [View](semantics_lock/current.md) |

## Version History

[Link to full archive index]
```

---

## 9. Security & Authority Model

### 9.1 Scope Decision: Workspace-Scoped

`governance_doc` is **workspace-scoped**, not system-global.

**Rationale:**
- Aligns with existing artifact model (all artifacts are workspace-scoped)
- Enables workspace-specific governance (e.g., team-specific rules)
- System-wide governance achieved via canonical "master" workspace
- Simpler RLS implementation

### 9.2 Write Restrictions

Writes to `governance_doc` are restricted:

| Operation | Allowed Roles |
|-----------|---------------|
| `artifact.save` (create) | admin, service_role |
| `artifact.update` | admin, service_role |
| `artifact.delete` | admin only |

**Not allowed:**
- Standard users cannot create or modify governance docs
- Archive records cannot be updated or deleted

### 9.3 Read Access

Reads follow standard workspace RLS:

| Viewer | Access |
|--------|--------|
| Workspace members | Full read access |
| Claude Code (CC) | Read via service_role |
| External (unauthenticated) | No access |

### 9.4 RLS Policy (Paper Design)

```sql
-- PAPER SCHEMA ONLY — DO NOT EXECUTE

-- Read: workspace members
create policy governance_doc_select_workspace_member
on public.qxb_artifact_governance_doc
for select
using (
  exists (
    select 1 from public.qxb_artifact a
    join public.qxb_workspace_user wu
      on a.workspace_id = wu.workspace_id
    where a.artifact_id = qxb_artifact_governance_doc.artifact_id
      and wu.user_id = auth.uid()
  )
);

-- Write: admin/service only
create policy governance_doc_insert_admin
on public.qxb_artifact_governance_doc
for insert
with check (
  -- service_role bypass or admin role check
  current_setting('role') = 'service_role'
  or exists (
    select 1 from public.qxb_workspace_user wu
    where wu.user_id = auth.uid()
      and wu.workspace_role = 'admin'
  )
);
```

---

## 10. Triggers for Creation/Update

### 10.1 Creation Triggers

A `governance_doc` SHOULD be created when:

| Event | Document Type | Notes |
|-------|---------------|-------|
| North Star version bump | `north_star` | On authoritative changes |
| Kernel semantic lock | `semantics_lock` | On binding decision |
| Gateway contract change | `gateway_contract` | On API behavior change |
| Registry behavior change | `registry_spec` | On type allowlist change |
| Phase transition | Varies | On KGB pass |

### 10.2 Update Triggers

A `governance_doc` SHOULD be updated when:

| Event | Action |
|-------|--------|
| Document content changes | Update with new `doc_version` |
| Correction/clarification | Update, note in changelog |
| Superseded by new doc | Set `lifecycle_status = 'superseded'` |

### 10.3 Archive Trigger (Automatic)

Auto-archive is triggered **automatically** by Gateway on any `artifact.update` to a `governance_doc`. This is not a manual action.

---

## 11. Failure Modes

### 11.1 Archive Creation Failure

**Scenario:** Auto-archive fails during update

**Handling:**
- Update must be atomic with archive creation
- If archive fails, entire update rolls back
- No partial state (live doc updated but archive missing)

### 11.2 Export/Mirror Failure

**Scenario:** GitHub mirror fails

**Handling:**
- Export is not blocking — update succeeds even if mirror fails
- `last_exported_at` remains stale
- Manual re-export available
- Alert/log on repeated failures

### 11.3 Concurrent Updates

**Scenario:** Two updates to same governance_doc simultaneously

**Handling:**
- Optimistic locking via `version` field
- Second update fails with version conflict
- Client must re-fetch and retry

---

## 12. Acceptance Criteria

### 12.1 Design Acceptance

This design is accepted when:

- [ ] Every field has stated purpose and governance/query justification
- [ ] No type table duplicates base columns
- [ ] Snapshot/restart semantics remain undiluted
- [ ] Auto-archive behavior is fully specified
- [ ] Export/mirror strategy is coherent
- [ ] Security model is explicit
- [ ] Failure modes are documented

### 12.2 Implementation Prerequisites

Before implementation is allowed:

1. North Star updated to include `governance_doc` in Kernel v1 types
2. Gateway Contract updated with new actions (`artifact.export`)
3. Type Registry updated to include `governance_doc`
4. RLS policy design reviewed
5. KGB test definitions created

---

## 13. Recommendation

### 13.1 Final Artifact Type Name

**Recommended:** `governance_doc`

**Rationale:**
- Clear semantic distinction from `instruction_pack` (GPT instructions vs system truth)
- Descriptive and self-documenting
- Follows existing naming pattern (lowercase, underscore-separated)

**Rejected alternative:** `instruction_pack`
- Different semantic purpose (GPT behavior vs system documentation)
- Different mutability model (free update vs auto-archive)
- Would conflate two distinct concepts

### 13.2 Phase Timing

**Recommended introduction:** Phase 4 (Post-Kernel v1 MVP)

**Rationale:**
- Kernel v1 MVP focuses on project/snapshot/restart/journal/instruction_pack
- governance_doc is infrastructure tooling, not end-user functionality
- Can be introduced after core workflows are stable
- Low urgency — current markdown files in docs/ serve the purpose for now

### 13.3 Preconditions Before Implementation

1. **North Star v0.4+** explicitly adds `governance_doc` to artifact types
2. **Kernel Semantics Lock** updated with governance_doc invariants
3. **Gateway Contract** includes `artifact.export` action specification
4. **Type Registry** seeded with `governance_doc` (enabled)
5. **KGB tests** defined for governance_doc CRUD + archive behavior
6. **RLS policies** designed and reviewed

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-22 | Initial design document |

---

**End of PRD**
