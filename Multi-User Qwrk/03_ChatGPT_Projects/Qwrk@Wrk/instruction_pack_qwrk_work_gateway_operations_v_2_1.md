# Instruction Pack — Qwrk@Work Gateway Operations v2.1

**Workspace:** Qwrk@Work  
**Workspace UUID:** 635bb8d7-7b93-4bea-8ca6-ee2c924c9557  
**Purpose:** Authoritative mechanical reference for all Gateway operations in Qwrk@Work.  
**Version:** v2.1  
**Supersedes:** Gateway Operations v2  

---

## 1. Core Execution Rules

- All Gateway commands must be emitted as a single fenced ```json code block.
- Exactly one payload per response.
- No commentary after closing fence.
- All `artifact.save` operations must include explicit `priority` (integer 1–5).  
  - Default to `3` unless otherwise specified.
- Never assume persistence without returned `artifact_id`.
- Never invent UUIDs.
- Sequential operations require confirmation of returned `artifact_id` before continuing.
- `artifact.update` must include:
  - Non-empty `extension`, OR
  - `tags.add` / `tags.remove`.

Top-level mutable fields are not permitted in `artifact.update`.

---

## 2. artifact.save — Create Artifact

### Required Fields

- `gw_action`
- `gw_workspace_id`
- `artifact_type`
- `title`
- `priority` (1–5, explicit)
- `tags`
- `extension` (object; may be empty if allowed by type)

### Base Template

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "{{type}}",
  "title": "Descriptive title",
  "priority": 3,
  "tags": ["tag1", "tag2"],
  "extension": {}
}
```

---

## 3. Project Mutability Rules (Authoritative)

For `artifact.update` on `project` artifacts:

### Allowed `extension` fields
- `operational_state`
- `state_reason`

### Disallowed (Immutable After Creation)
- `summary`
- `lifecycle_status`
- `priority`
- `title`
- `content`

### Lifecycle Enforcement

- `lifecycle_status` may **only** change via `artifact.promote`.
- Direct mutation of lifecycle via `artifact.update` is prohibited.

Lifecycle transitions are Gateway-validated, not client-simulated.

---

## 4. Seed → Sapling Promotion Rule (Revised & Clarified)

Promotion requires:

- `lifecycle_status == "seed"`
- At least one linked `journal` child

### Definition of “Linked Journal Child”

A valid journal child must:

- Have `artifact_type = journal`
- Have `parent_artifact_id` pointing directly to the project being promoted

Tag-only association does **not** qualify.

Summary content alone is **not** a valid readiness signal.

If conditions are not satisfied → promotion must fail.

---

## 5. artifact.update — Update Artifact

### Update Extension Template

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "{{type}}",
  "artifact_id": "{{uuid}}",
  "extension": {
    "allowed_field": "new_value"
  }
}
```

### Tag Operations Template

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "{{type}}",
  "artifact_id": "{{uuid}}",
  "tags": {
    "add": ["new-tag"],
    "remove": ["old-tag"]
  }
}
```

### Update Constraints

- No empty updates.
- No top-level field mutation.
- No lifecycle manipulation.
- No priority changes post-creation.
- No implicit mutation through malformed extension payloads.

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

- `seed_to_sapling`
- `sapling_to_tree`
- `tree_to_archive`

Stages may not be skipped.

Promotion readiness is validated by Gateway rules. Clients must not assume readiness or bypass validation logic.

---

## 7. Governance Notes

- Workspace lock is absolute.
- `priority` must always be explicit on INSERT.
- Never chain multiple Gateway commands in a single response.
- Dependent actions require confirmation of returned `artifact_id`.
- Instruction packs are immutable once registered unless versioned.
- Structural rule discoveries require new version (v3, v4, etc.).
- Lifecycle authority resides in Gateway, not client logic.

---

# What This Version Fixes

- Removes hard-coded priority assumption.
- Explicitly seals lifecycle mutation path.
- Clarifies journal linkage requirements.
- Reinforces Gateway as enforcement boundary.
- Prevents future semantic drift.

---

This version is governance-grade: deterministic, explicit, and phase-aligned.

