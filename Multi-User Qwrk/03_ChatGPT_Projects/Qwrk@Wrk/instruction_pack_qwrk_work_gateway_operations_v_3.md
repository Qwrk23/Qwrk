# Instruction Pack — Qwrk@Work Gateway Operations v3

**Workspace:** Qwrk@Work
**Workspace UUID:** 635bb8d7-7b93-4bea-8ca6-ee2c924c9557
**Purpose:** Authoritative mechanical reference for all Gateway operations in Qwrk@Work.
**Version:** v3
**Supersedes:** Gateway Operations v2.1
**Gateway:** v59
**DDL:** v2.6

---

## CHANGELOG

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

### 2.3 Semantic Type Classification (T69)

**Top-level types** (REQUIRE `semantic_type_id` on INSERT):
- `project`, `snapshot`, `journal`, `restart`

**Non-top-level types** (MUST NOT provide `semantic_type_id`):
- `branch`, `leaf`, `limb`, `instruction_pack`

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

## 3. Project Mutability Rules (Authoritative)

For `artifact.update` on `project` artifacts:

### Allowed `extension` fields
- `operational_state`
- `state_reason`

### Disallowed (Immutable After Creation)
- `summary`, `lifecycle_status`, `priority`, `title`, `content`
- `lifecycle_stage` — returns `MUTABILITY_ERROR` with `PROMOTE_ONLY` hint

### Lifecycle Enforcement

- `lifecycle_status` may **only** change via `artifact.promote`.
- Direct mutation of lifecycle via `artifact.update` is prohibited.

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
| `extension` OR `tags` | object | At least one required. See 5.2 for mode selection. |

### 5.2 Mode Selection

The workflow determines mode automatically:
- **Tags-only:** `tags` is non-null AND `extension` has zero keys
- **Semantic type (dedicated):** `extension` contains `semantic_type_id` key (see 5.5)
- **Extension:** `extension` has at least one key (not `semantic_type_id`)

**There is no combined update path.** Tags + extension = two separate calls. Semantic type updates cannot be combined with anything.

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

#### Mutability Registry

| Type | Extension Update Behavior |
|------|--------------------------|
| `project` | Allowed. Only `operational_state` and `state_reason`. |
| `snapshot` | **BLOCKED** — `IMMUTABILITY_ERROR` (CREATE_ONLY) |
| `restart` | **BLOCKED** — `IMMUTABILITY_ERROR` (CREATE_ONLY) |
| `journal` | **BLOCKED** — `JOURNAL_MUTABILITY_UNDECIDED` |
| `branch` | Returns `UPDATE_CONFIRMED` ack but **NO database write, NO version increment** |
| `limb` | Returns `UPDATE_CONFIRMED` ack but **NO database write, NO version increment** |
| `leaf` | Returns `UPDATE_CONFIRMED` ack but **NO database write, NO version increment** |

### 5.5 Semantic Type Update (Dedicated Path — T69)

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

### 5.6 Update Constraints Summary

- No empty updates.
- No top-level spine field mutation (title, summary, priority, etc.).
- No lifecycle manipulation via update — use `artifact.promote`.
- Semantic type + tags cannot be combined in one call.
- Semantic type update applies only to top-level types.

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
| `IMMUTABILITY_ERROR` | Extension update on snapshot/restart |
| `JOURNAL_EXTENSION_INVALID` | Journal INSERT with invalid extension keys |
| `JOURNAL_MUTABILITY_UNDECIDED` | Extension update on journal |
| `MUTABILITY_ERROR` | Disallowed field in project extension, or lifecycle_stage |
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
