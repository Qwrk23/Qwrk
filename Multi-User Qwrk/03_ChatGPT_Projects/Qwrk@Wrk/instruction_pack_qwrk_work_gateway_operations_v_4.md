# Instruction Pack — Qwrk@Work Gateway Operations v4.1

**Workspace:** Qwrk@Work
**Workspace UUID:** 635bb8d7-7b93-4bea-8ca6-ee2c924c9557
**Purpose:** Authoritative mechanical reference for all Gateway operations in Qwrk@Work.
**Version:** v4.1
**Supersedes:** Gateway Operations v4
**Gateway:** v59
**DDL:** v2.9

---

## CHANGELOG

### v4.1 (2026-03-09) — T112 List Filter Enhancement

- Two new optional filters for `artifact.list`: `selector.filters.lifecycle_status` and `selector.filters.execution_status`
- `lifecycle_status` allowed: `seed`, `sapling`, `tree`, `archive` (string or array)
- `execution_status` allowed: `not_started`, `in_progress`, `blocked`, `complete` (string or array)
- Invalid values return `VALIDATION_ERROR`. NULL `execution_status` rows excluded from filter matches.
- Selector options table updated (Section 7.2)

### v4 (2026-03-06) — T87 Spine Field Routing + Lifecycle Mutability Governance

- `title`, `summary`, `priority` now updateable via `artifact.update` (new `spine_only` and `mixed` update modes)
- Lifecycle-scoped mutability: archive = ALL FROZEN, tree = title FROZEN, seed/sapling = fully mutable
- `design_spine` added to project extension allowlist (freeform JSONB, no schema validation)
- Journal permanent doctrine: `JOURNAL_INSERT_ONLY` replaces `JOURNAL_MUTABILITY_UNDECIDED`
- `instruction_pack` extension update now returns `IMMUTABILITY_ERROR` (was silent dead-end)
- 3 new error codes: `ARCHIVE_IMMUTABLE`, `FIELD_FROZEN`, `JOURNAL_INSERT_ONLY`
- Section 3 rewritten: lifecycle-scoped mutability matrix replaces flat "Disallowed" list
- Section 5 rewritten: 5-mode update routing replaces 3-mode model
- Previous version: `Archive/instruction_pack_qwrk_work_gateway_operations_v_3__2026-03-06.md`

### v3 (2026-03-04) — T69 Semantic Type Registry Enforcement

- `semantic_type_id` added as REQUIRED field for top-level artifact saves (project, snapshot, journal, restart)
- `semantic_type_id` FORBIDDEN for non-top-level types (branch, leaf, limb, instruction_pack)
- New dedicated `semantic_type` update mode in artifact.update (Section 5.5)
- 4 new error codes: `INVALID_SEMANTIC_TYPE`, `SEMANTIC_TYPE_INACTIVE`, `MIXED_UPDATE_NOT_ALLOWED`, `SEMANTIC_TYPE_NOT_APPLICABLE`
- All save payload examples updated with `semantic_type_id` field
- Tag update format clarified: structured `{ "add": [...], "remove": [...] }` (flat array NOT supported)
- Immutability enforcement documented for snapshot/restart extension updates
- Error code inventory expanded (Section 8)
- Previous version: `Archive/instruction_pack_qwrk_work_gateway_operations_v_2_1__2026-03-04.md`

### v2.1 (2026-02-18)

- Removed hard-coded priority assumption
- Sealed lifecycle mutation path
- Clarified journal linkage requirements
- Reinforced Gateway as enforcement boundary

---

## 1. Core Execution Rules

- All Gateway commands must be emitted as a single fenced ```json code block.
- Exactly one payload per response.
- No commentary after closing fence.
- Never assume persistence without returned `artifact_id`.
- Never invent UUIDs.
- Sequential operations require confirmation of returned `artifact_id` before continuing.

---

## 2. artifact.save — Create Artifact

### 2.1 Required Fields

| Field | Type | Notes |
|-------|------|-------|
| `gw_action` | `"artifact.save"` | |
| `gw_workspace_id` | uuid | Always `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` |
| `artifact_type` | text | Must be in TYPE_ALLOWLIST |
| `title` | text | Non-empty string |
| `semantic_type_id` | text | **REQUIRED for top-level types** (project, snapshot, journal, restart). **FORBIDDEN for non-top-level types** (branch, leaf, limb, instruction_pack). See 2.3. |
| `extension` | object | Type-specific. See 2.2 for requirements per type. |

### 2.2 Extension Requirements by Artifact Type

| Type | Required Extension Fields | Notes |
|------|--------------------------|-------|
| `project` | `lifecycle_stage` (string: `seed`, `sapling`, `tree`, `archive`) | Normalizer aligns `lifecycle_status` from this value |
| `journal` | `entry_text` (non-empty string) | **Strict allow-list: ONLY `entry_text` permitted.** Any other key triggers `JOURNAL_EXTENSION_INVALID`. |
| `snapshot` | `payload` (non-null, non-array object) | Extension must contain a `payload` object with the snapshot content |
| `restart` | `payload` (non-null, non-array object) | Extension must contain a `payload` object with the restart content |
| `instruction_pack` | `scope`, `active`, `priority`, `pack_format` | 4 fields required on INSERT |
| `branch` | *(none — spine-only)* | No extension table write. Extension object is ignored. |
| `leaf` | *(none — spine-only)* | No extension table write. Extension object is ignored. |
| `limb` | *(none required)* | Shell INSERT: only `artifact_id` written to extension table |
| `twig` | *(none — spine-only)* | No extension table. Lifecycle: `proposed` → `active` → `promoted` \| `pruned` |

### 2.3 Semantic Type Classification (T69)

**Top-level types** (REQUIRE `semantic_type_id` on INSERT):
- `project`, `snapshot`, `journal`, `restart`

**Non-top-level types** (MUST NOT provide `semantic_type_id`):
- `branch`, `leaf`, `limb`, `instruction_pack`, `twig`

The `semantic_type_id` must reference an **active** entry in the semantic type registry. If the entry does not exist or is inactive, the save is rejected.

**Registry values (9 active):**

| Key | Domain |
|-----|--------|
| `execution-core` | Operational execution and task management |
| `governance` | Rules, policies, structural decisions |
| `infrastructure` | Technical systems and tooling |
| `platform` | Platform capabilities and integration |
| `product` | Product features and user-facing functionality |
| `alignment` | Strategic alignment and prioritization |
| `sales` | Sales strategy and pipeline |
| `marketing` | Marketing strategy and outreach |
| `exploratory` | Exploration, experimentation, discovery |

### 2.4 Optional Spine Fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `summary` | text | `null` | |
| `priority` | integer 1-5 | `3` | Workflow defaults to 3 if omitted. DB CHECK enforces range. |
| `tags` | array of strings | `null` | Normalized: trimmed, lowercased, deduplicated. Recommended (2-4 tags). |
| `content` | object | `{}` | Must be an object (not string/array) |
| `parent_artifact_id` | uuid | `null` | Links to parent artifact |
| `execution_status` | text | `null` | One of: `not_started`, `in_progress`, `blocked`, `complete` (or null) |

### 2.5 Save Payload Templates

**Project (seed):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "title": "Seed — My New Project",
  "semantic_type_id": "execution-core",
  "priority": 3,
  "tags": ["seed", "topic"],
  "extension": {
    "lifecycle_stage": "seed"
  }
}
```

**Journal:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "journal",
  "title": "Morning Reflection",
  "semantic_type_id": "alignment",
  "priority": 3,
  "tags": ["reflection"],
  "extension": {
    "entry_text": "Today I reflected on..."
  }
}
```

**Snapshot:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "snapshot",
  "title": "Decision — API Approach",
  "semantic_type_id": "governance",
  "priority": 3,
  "tags": ["decision", "for-q"],
  "extension": {
    "payload": {
      "decision": "Use REST over GraphQL",
      "rationale": "Simpler for MVP"
    }
  }
}
```

**Restart:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "restart",
  "title": "Restart — Planning Session",
  "semantic_type_id": "execution-core",
  "priority": 3,
  "tags": ["restart"],
  "extension": {
    "payload": {
      "thread_inventory": "...",
      "resume_instructions": "..."
    }
  }
}
```

**Branch (spine-only, no semantic_type_id):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "branch",
  "title": "Branch 1 — Planning Phase",
  "parent_artifact_id": "<project_artifact_id>"
}
```

**Leaf (spine-only, no semantic_type_id):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "leaf",
  "title": "Task — Write tests",
  "parent_artifact_id": "<branch_artifact_id>"
}
```

---

## 3. Project Mutability Rules (Authoritative — T87)

For `artifact.update` on `project` artifacts:

### 3.1 Allowed Extension Fields
- `operational_state`
- `state_reason`
- `summary` (also on spine — see 3.3)
- `design_spine` — freeform JSONB object, no schema validation

### 3.2 Lifecycle Stage Mutation
- `lifecycle_stage` — returns `MUTABILITY_ERROR` with `PROMOTE_ONLY` hint
- Lifecycle may **only** change via `artifact.promote`.

### 3.3 Spine Field Update (T87)

`title`, `summary`, and `priority` are now updateable via `artifact.update` using `spine_only` or `mixed` mode (see Section 5.2).

**Lifecycle-Scoped Mutability:**

| Lifecycle Stage | `title` | `summary` | `priority` |
|----------------|---------|-----------|------------|
| `seed` | Mutable | Mutable | Mutable |
| `sapling` | Mutable | Mutable | Mutable |
| `tree` | **FROZEN** (`FIELD_FROZEN`) | Mutable | Mutable |
| `archive` | **ALL FROZEN** (`ARCHIVE_IMMUTABLE`) | **FROZEN** | **FROZEN** |

**Rules:**
- `archive` projects reject ALL mutations (spine, extension, tags) with `ARCHIVE_IMMUTABLE`
- `tree` projects allow all updates EXCEPT `title` (returns `FIELD_FROZEN`)
- `seed` and `sapling` projects are fully mutable

---

## 4. Seed to Sapling Promotion Rule

Promotion requires:

- `lifecycle_status == "seed"`
- At least one linked `journal` child (via `parent_artifact_id`) OR non-empty `summary` on spine

Tag-only association does **not** qualify.

---

## 5. artifact.update — Update Artifact

### 5.1 Required Fields

| Field | Type | Notes |
|-------|------|-------|
| `gw_action` | `"artifact.update"` | |
| `gw_workspace_id` | uuid | |
| `artifact_type` | text | |
| `artifact_id` | uuid | |
| At least one of: `extension`, `tags`, `title`, `summary`, `priority` | varies | See 5.2 for mode selection. |

### 5.2 Mode Selection (T87 — 5 Modes)

The workflow determines mode automatically based on which fields are present:

| Mode | Trigger | What It Updates |
|------|---------|-----------------|
| **spine_only** | One or more of `title`, `summary`, `priority` present; NO `extension`, NO `tags` | Spine fields only |
| **mixed** | Spine fields (`title`/`summary`/`priority`) + `tags` present; NO `extension` | Spine fields + tags atomically |
| **tags_only** | `tags` is non-null AND no spine fields AND `extension` has zero keys | Tags only |
| **semantic_type** | `extension` contains `semantic_type_id` key (see 5.6) | Semantic type via RPC |
| **extension** | `extension` has at least one key (not `semantic_type_id`) AND no spine fields | Extension fields only |

**Combining extension + spine fields is NOT allowed** — the Gateway rejects this combination.

**Combining extension + tags is NOT allowed** — requires two separate calls.

**Combining semantic_type + anything is NOT allowed** — returns `MIXED_UPDATE_NOT_ALLOWED`.

### 5.3 Tags-Only Update

Works for **ALL artifact types** including immutable ones (snapshot, restart, journal).

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "snapshot",
  "artifact_id": "{{uuid}}",
  "tags": {
    "add": ["new-tag"],
    "remove": ["old-tag"]
  }
}
```

**Tag format:** Must use structured `{ "add": [...], "remove": [...] }`. Flat array `"tags": [...]` causes `VALIDATION_ERROR`.

**Semantics:**
- Tags in `add` are appended (deduplicated)
- Tags in `remove` are deleted
- Remove wins over add if same tag in both
- Final tags sorted alphabetically, trimmed, lowercased

### 5.4 Extension Update

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "artifact_id": "{{uuid}}",
  "extension": {
    "operational_state": "paused",
    "state_reason": "Waiting on dependency resolution"
  }
}
```

#### Mutability Registry (T87)

| Type | Extension Update Behavior |
|------|--------------------------|
| `project` | Allowed. `operational_state`, `state_reason`, `summary`, `design_spine`. Subject to lifecycle guards (Section 3.3). |
| `snapshot` | **BLOCKED** — `IMMUTABILITY_ERROR` (CREATE_ONLY) |
| `restart` | **BLOCKED** — `IMMUTABILITY_ERROR` (CREATE_ONLY) |
| `journal` | **BLOCKED** — `JOURNAL_INSERT_ONLY` (permanent doctrine) |
| `instruction_pack` | **BLOCKED** — `IMMUTABILITY_ERROR` |
| `branch` | Returns `UPDATE_CONFIRMED` ack but **NO database write, NO version increment** |
| `limb` | Returns `UPDATE_CONFIRMED` ack but **NO database write, NO version increment** |
| `leaf` | Returns `UPDATE_CONFIRMED` ack but **NO database write, NO version increment** |
| `twig` | Returns `UPDATE_CONFIRMED` ack. Twig lifecycle (`proposed`→`active`→`promoted`\|`pruned`) enforced by Check_Mutability_Rules. Terminal states block further updates (`INVALID_TRANSITION`). |

### 5.5 Spine-Only Update (T87)

Updates `title`, `summary`, and/or `priority` on the spine table directly.

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "artifact_id": "{{uuid}}",
  "title": "Updated Project Title",
  "summary": "New summary text",
  "priority": 2
}
```

**Rules:**
- Applies to `project` type (subject to lifecycle guards — see Section 3.3)
- `archive` projects reject ALL spine updates with `ARCHIVE_IMMUTABLE`
- `tree` projects reject `title` updates with `FIELD_FROZEN`
- Cannot be combined with `extension` — use separate calls
- Can be combined with `tags` (becomes `mixed` mode)

### 5.5.1 Mixed Update (Spine + Tags)

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "artifact_id": "{{uuid}}",
  "title": "Updated Title",
  "priority": 1,
  "tags": {
    "add": ["urgent"],
    "remove": ["low-priority"]
  }
}
```

Spine fields and tags are applied atomically in a single call.

### 5.6 Semantic Type Update (Dedicated Path — T69)

Changes the `semantic_type_id` of an existing **top-level** artifact. This is a **dedicated, isolated update path** — it cannot be combined with tags or other extension fields.

**Applies to:** `project`, `snapshot`, `journal`, `restart` only. Non-top-level types return `SEMANTIC_TYPE_NOT_APPLICABLE`.

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "artifact_id": "{{uuid}}",
  "extension": {
    "semantic_type_id": "governance",
    "reason": "Reclassified from execution-core after scope review"
  }
}
```

**Rules:**
- `reason` is REQUIRED (non-empty string explaining the reclassification)
- `semantic_type_id` and `reason` must be the ONLY keys in `extension` — any other key returns `MIXED_UPDATE_NOT_ALLOWED`
- `tags` must NOT be present — combining tags with semantic type returns `MIXED_UPDATE_NOT_ALLOWED`
- The new value must be a valid, active entry in `qxb_semantic_type_registry`
- If the new value equals the current value, the operation is a **noop** (no version increment, no audit entry)

### 5.7 Update Constraints Summary

- No empty updates.
- Spine fields (`title`, `summary`, `priority`) updateable via `spine_only` or `mixed` mode.
- Extension + spine fields cannot be combined in one call.
- No lifecycle manipulation via update — use `artifact.promote`.
- Semantic type + tags cannot be combined in one call.
- Semantic type update applies only to top-level types.
- Archive projects reject ALL mutations (`ARCHIVE_IMMUTABLE`).
- Tree projects reject `title` mutations (`FIELD_FROZEN`).
- Journal extensions are permanently INSERT-ONLY (`JOURNAL_INSERT_ONLY`).

---

## 6. artifact.promote — Lifecycle Transition

```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "artifact_id": "{{uuid}}",
  "transition": "seed_to_sapling",
  "reason": "Clear justification"
}
```

### Valid Transitions

| Transition | From | To |
|-----------|------|----|
| `seed_to_sapling` | `seed` | `sapling` |
| `sapling_to_tree` | `sapling` | `tree` |
| `tree_to_archive` | `tree` | `archive` |

Stages may not be skipped. `reason` is required (1-280 characters).

### QPM Guards

| Transition | Guard | Requirement |
|-----------|-------|-------------|
| `seed_to_sapling` | Summary OR journal child | Non-empty `summary` on spine, OR at least 1 journal child (via `parent_artifact_id`) |
| `sapling_to_tree` | Execution anatomy children | At least 1 `branch` or `leaf` child. `limb` NOT counted. |
| `tree_to_archive` | *(none)* | Passes unconditionally |

---

## 7. artifact.query / artifact.list

### 7.1 Query (Single Artifact)

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "artifact_id": "{{uuid}}"
}
```

Hydration is on by default. Use `"selector": { "hydrate": false }` to skip extension data.

### 7.2 List (Multiple Artifacts)

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "selector": {
    "limit": 20
  }
}
```

**Selector options:**

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `selector.limit` | integer | `50` | Max: 200. Must be >= 1. |
| `selector.offset` | integer | `0` | Must be >= 0. |
| `selector.hydrate` | boolean | `false` | `true` fetches extension data. |
| `selector.filters.tags_any` | array | `null` | Set containment: artifact must contain ALL specified tags. |
| `selector.filters.lifecycle_status` | string/array | `null` | Filter by stage: `seed`, `sapling`, `tree`, `archive`. |
| `selector.filters.execution_status` | string/array | `null` | Filter by status: `not_started`, `in_progress`, `blocked`, `complete`. NULL rows excluded. |
| `selector.parent_artifact_id` | uuid | `null` | Filter by parent artifact. |

**Pagination cap:** `offset + limit + 1` must not exceed 500. Violation returns `PAGINATION_WINDOW_EXCEEDED`.

---

## 8. Error Code Inventory

### 8.1 Gateway-Level Errors

| Code | Trigger |
|------|---------|
| `VALIDATION_ERROR` | Missing/invalid required field |
| `ACTION_NOT_ALLOWED` | `gw_action` not in allowlist |
| `WORKSPACE_FORBIDDEN` | Workspace not permitted |
| `ARTIFACT_TYPE_NOT_ALLOWED` | Type not in allowlist |

### 8.2 Sub-Workflow Errors

| Code | Trigger |
|------|---------|
| `NOT_FOUND` | Artifact not found for workspace_id + artifact_id |
| `TYPE_MISMATCH` | Requested type does not match stored type |
| `CONFLICT` | Unique constraint violation (duplicate key) |
| `IMMUTABLE_RECORD` | UPDATE attempted on snapshot/restart via save path |
| `IMMUTABILITY_ERROR` | Extension update on snapshot/restart/instruction_pack |
| `JOURNAL_EXTENSION_INVALID` | Journal INSERT with invalid extension keys |
| `JOURNAL_INSERT_ONLY` | Extension update on journal (permanent doctrine — T87) |
| `MUTABILITY_ERROR` | Disallowed field in project extension, or lifecycle_stage |
| `ARCHIVE_IMMUTABLE` | Any mutation attempted on archive-stage project (T87) |
| `FIELD_FROZEN` | Title update on tree-stage project (T87) |
| `UPDATE_ONLY` | artifact_id missing on update |
| `INVALID_SEMANTIC_TYPE` | `semantic_type_id` not found in registry |
| `SEMANTIC_TYPE_INACTIVE` | Target semantic type is inactive |
| `MIXED_UPDATE_NOT_ALLOWED` | `semantic_type_id` combined with tags or other extension fields |
| `SEMANTIC_TYPE_NOT_APPLICABLE` | `semantic_type_id` update on non-top-level type |
| `LIFECYCLE_TRANSITION_NOT_ALLOWED` | Invalid transition key |
| `LIFECYCLE_STATE_MISMATCH` | Current lifecycle does not match expected from_state |
| `PROMOTION_BLOCKED_SEED_NOT_READY` | seed_to_sapling: no summary or journal child |
| `PROMOTION_BLOCKED_NO_ANATOMY` | sapling_to_tree: no branch/leaf children |
| `PAGINATION_WINDOW_EXCEEDED` | offset + limit + 1 > 500 |
| `DEPENDENCY_INCOMPLETE` | Leaf completion blocked by incomplete dependencies (T71) |

### 8.3 Error Envelope Shape

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "<ERROR_CODE>",
    "message": "<human readable>",
    "details": { ... }
  }
}
```

---

## 9. Governance Notes

- Workspace lock is absolute — all payloads must use `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`.
- `priority` is optional (default 3). Explicit is recommended.
- Never chain multiple Gateway commands in a single response.
- Dependent actions require confirmation of returned `artifact_id`.
- Lifecycle authority resides in Gateway, not client logic.
- `semantic_type_id` is always stored as UUID. Keys (like `execution-core`) are resolved to UUIDs by the Gateway.

---

This version is governance-grade: deterministic, explicit, and phase-aligned.
