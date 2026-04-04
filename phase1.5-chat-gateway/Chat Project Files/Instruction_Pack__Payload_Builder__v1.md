# Instruction Pack — Payload Builder (v1)

**artifact_id:** `pending`
**scope:** `global`
**pack_version:** `v1`
**status:** Draft — Testing in CC Inbox
**created:** 2026-04-04
**updated:** 2026-04-04
**origin:** T175 (Salience Amplification Doctrine) — payload.build v1.1 certified, Gateway v2 (8) deployed

---

## Purpose

Teaches Q how to use `payload.build`, a Gateway action that assembles correct, canonical payloads from simplified intent objects. Replaces manual field-by-field payload construction for saves, updates, and promotes.

---

## Trigger

Use this pack whenever building a payload for `artifact.save`, `artifact.update`, or `artifact.promote` via QSB.

---

## How It Works

Send a simplified intent object via QSB with `"gw_action": "payload.build"`. The builder validates your intent, applies all type rules, defaults, and field routing — then returns the assembled payload.

### Two Modes

| Mode | Behavior | When to Use |
|------|----------|-------------|
| `"dry_run"` (default) | Validates and returns assembled payload. Nothing is saved. | Confirm shape before executing. |
| `"execute"` | Validates, assembles, AND executes the save/update/promote in one step. | When confident in the intent. |

**Recommended pattern:** `dry_run` first → review response → `execute`.

---

## Intent Field Reference

### Universal Fields (All Actions)

| Field | Required | Notes |
|-------|----------|-------|
| `gw_action` | Always | `"payload.build"` |
| `action` | Always | `"artifact.save"`, `"artifact.update"`, or `"artifact.promote"` |
| `type` | Always | Artifact type (see Type-Specific Rules below) |
| `gw_workspace_id` | Always | Workspace UUID |
| `mode` | Optional | `"dry_run"` (default) or `"execute"` |

### Save Fields

| Field | Required | Notes |
|-------|----------|-------|
| `title` | Yes | Required for new artifacts |
| `semantic_type` | Varies | Required for: project, journal, snapshot, restart. Forbidden for: branch, leaf, limb, twig. |
| `parent` | Varies | Required for: branch, leaf, limb, twig. Optional for others. |
| `tags` | Optional | Array of strings |
| `content` | Varies | Format depends on type (see Content Rules below) |
| `priority` | Optional | 1–5, defaults to 3 |
| `summary` | Optional | Spine-level summary |
| `extension` | Optional | Type-specific extension fields |

### Update Fields

| Field | Required | Notes |
|-------|----------|-------|
| `artifact_id` | Yes | UUID of artifact to update |
| `tags` | Optional | `{"add": [], "remove": []}` structured format |
| `content` | Optional | At least one mutation field required |
| `extension` | Optional | Type-specific extension fields |
| `summary` | Optional | Spine-level summary |

### Promote Fields

| Field | Required | Notes |
|-------|----------|-------|
| `artifact_id` | Yes | UUID of artifact to promote |
| `transition` | Yes | `"seed_to_sapling"`, `"sapling_to_tree"`, or `"tree_to_archive"` |
| `reason` | Yes | Max 280 characters |

---

## Type-Specific Rules

### Top-Level Types (semantic_type REQUIRED on save)

| Type | `semantic_type` | `parent` | `content` format | Notes |
|------|----------------|----------|-------------------|-------|
| `project` | Required | Optional | String (→ spine) | Auto-injects `lifecycle_stage: seed` |
| `journal` | Required | Optional | String (→ extension.entry_text) | Owner-private |
| `snapshot` | Required | Optional | Object (→ extension.payload) | Immutable extension |
| `restart` | Required | Optional | Object (→ extension.payload) | Immutable extension |

### Execution Anatomy Types (semantic_type FORBIDDEN on save)

| Type | `semantic_type` | `parent` | `content` format | Notes |
|------|----------------|----------|-------------------|-------|
| `branch` | Forbidden | Required | String (→ spine) | Auto-injects `execution_status: not_started` |
| `leaf` | Forbidden | Required | String (→ spine) | Auto-injects `execution_status: not_started` |
| `limb` | Forbidden | Required | String (→ spine) | Auto-injects `execution_status: not_started` |
| `twig` | Forbidden | Required | Intent bundle object (→ spine) | See Twig Content Rules |

### Special Types

| Type | `semantic_type` | `parent` | `content` format | Notes |
|------|----------------|----------|-------------------|-------|
| `instruction_pack` | Forbidden | Optional | String (→ spine) | Extension auto-created with `scope`, `active`, `priority`, `pack_format`, `payload` |
| `person` | Required | Optional | Extension-direct | Required: `full_name`, `preferred_name`, `relationship_type`. 25 allowed extension fields. |

---

## Content Rules

The builder routes `content` to the correct destination based on type. **Do not pre-wrap content** in `extension.payload` or `extension.entry_text` — just put it in `content`.

| Type | What `content` should be | Where it goes |
|------|--------------------------|---------------|
| project, branch, leaf, limb | Plain text string | Spine `content` field |
| journal | Plain text string | `extension.entry_text` |
| snapshot, restart | JSON object | `extension.payload` |
| twig | Intent bundle object (see below) | Spine `content` field |
| person | N/A — use `extension` fields directly | Extension table |

### Twig Intent Bundle (Required Fields)

Twig content must be an object with all four fields as non-empty strings:

```json
{
  "idea": "What the twig captures",
  "why_now": "Why this matters right now",
  "problem_touched": "What problem or gap this addresses",
  "future_hook": "Where this could lead"
}
```

---

## Canonical Semantic Types (9 Active)

Use exactly one of these values for `semantic_type`:

`governance` · `execution-core` · `infrastructure` · `platform` · `product` · `alignment` · `sales` · `marketing` · `exploratory`

---

## Workspace IDs

| Workspace | UUID |
|-----------|------|
| Qwrk Prime | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |
| Q@W (Resolve) | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` |

---

## Examples

### Save a Twig (dry_run)

```json
{
  "gw_action": "payload.build",
  "action": "artifact.save",
  "type": "twig",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "title": "Explore caching layer for query performance",
  "parent": "dec0597b-8edc-4387-95e7-025960f3cedc",
  "tags": ["for-q", "infrastructure"],
  "content": {
    "idea": "Add a caching layer to reduce repeated Gateway queries",
    "why_now": "Query volume increasing with multi-user onboarding",
    "problem_touched": "Gateway response times degrade under repeated identical queries",
    "future_hook": "Feeds into Phase 3 query optimization and CmdCtr performance"
  },
  "mode": "dry_run"
}
```

### Save a Journal (execute)

```json
{
  "gw_action": "payload.build",
  "action": "artifact.save",
  "type": "journal",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "title": "Session reflection — April planning",
  "semantic_type": "alignment",
  "tags": ["for-q"],
  "content": "Reflected on branch prioritization today. The website sapling needs design spine before any execution begins.",
  "mode": "execute"
}
```

### Save a Snapshot (execute)

```json
{
  "gw_action": "payload.build",
  "action": "artifact.save",
  "type": "snapshot",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "title": "Design decision — auth approach for console",
  "semantic_type": "governance",
  "tags": ["for-q", "T172"],
  "content": {
    "decision": "Supabase Auth with RLS",
    "rationale": "Already integrated, reduces new dependencies",
    "alternatives_considered": ["NextAuth", "Clerk", "Custom JWT"]
  },
  "mode": "execute"
}
```

### Promote (execute)

```json
{
  "gw_action": "payload.build",
  "action": "artifact.promote",
  "type": "project",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_id": "uuid-here",
  "transition": "seed_to_sapling",
  "reason": "Design spine locked, branches scaffolded, ready for execution",
  "mode": "execute"
}
```

### Update Tags (execute)

```json
{
  "gw_action": "payload.build",
  "action": "artifact.update",
  "type": "snapshot",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_id": "uuid-here",
  "tags": {"add": ["reviewed"], "remove": ["draft"]},
  "mode": "execute"
}
```

---

## What the Builder Does For You

- Routes `content` to the correct location (spine, extension.entry_text, extension.payload) based on type
- Injects defaults (`execution_status: not_started`, `lifecycle_stage: seed` for new projects)
- Validates required fields per type (twig intent bundle, person required fields, etc.)
- Enforces semantic_type rules (required vs forbidden per type)
- Warns about missing tags, out-of-range priority, empty content
- Rejects unknown extension fields
- Unwraps pre-wrapped content (if you accidentally put `content.payload`, it fixes it)

---

## What the Builder Does NOT Do

- `artifact.delete` / `artifact.restore` / `artifact.list` / `artifact.query` — use those actions directly
- Messaging actions (`messaging.send_email`, `messaging.create_calendar_event`) — use directly
- Cross-workspace validation — you must supply the correct `gw_workspace_id`

---

## Error Response Format

When validation fails, the builder returns:

```json
{
  "ok": false,
  "gw_action": "payload.build",
  "spec_version": "1.1",
  "mode": "dry_run",
  "validation": {
    "errors": ["type 'foo' is not supported", "title is required for artifact.save"],
    "warnings": []
  }
}
```

**On error:** Present the error to Joel. Do not retry with guessed corrections — read the error message, fix the specific field, and resubmit.

---

## Rules

1. **Always include `gw_workspace_id`** — the builder needs it for the assembled payload
2. **Use `dry_run` first** when unsure about shape — it costs nothing and shows exactly what will be sent
3. **Trust the builder for field routing** — put content in `content`, not in `extension.payload` or `extension.entry_text`
4. **The builder validates, not just assembles** — clear error messages tell you exactly what's wrong
5. **Start with `payload.build` for all new saves, updates, and promotes** — hand-constructed payloads are still accepted but the builder eliminates most assembly errors

---

*CHANGELOG: v1 (2026-04-04): Initial draft. Created from T175 payload.build v1.1 spec (certified 9/9 tests, Gateway v2 build 8). Draft status — testing in CC Inbox before promotion to Qwrk Prime SI and Akara.*
