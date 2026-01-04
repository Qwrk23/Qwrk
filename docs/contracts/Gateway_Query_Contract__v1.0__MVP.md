# Gateway Query Contract v1.0 — MVP

**Date:** 2026-01-04
**Status:** Active — MVP Complete
**Scope:** Read-only artifact.query semantics

---

## Purpose

This document defines the **Gateway Query Contract v1.0** for read operations in Qwrk. It governs how external callers (CustomGPT, Claude Code, n8n workflows) may retrieve individual artifacts from the system.

This contract:
- Defines `artifact.query` action semantics
- Specifies request/response envelopes
- Lists allowed artifact types for query operations
- Documents spine-first retrieval architecture

**Complement to Write Contract:** Write semantics (artifact.save) are defined in `AAA_New_Qwrk__Gateway_Contract__v1.0__2026-01-03.md`.

---

## Allowed Artifact Types (Read)

The following `artifact_type` values are allowed for query operations:

- `project` — Lifecycle-tracked project artifacts
- `journal` — Owner-private reflective entries
- `snapshot` — Immutable lifecycle captures
- `restart` — Session continuation artifacts
- `video` — Long-form media artifacts with transcripts and derived insights

**Note:** Additional types (forest, thicket, flower, thorn, grass) are defined in database schema but not yet enabled for query in Gateway v1.0 MVP.

**Video Type Distinction**: Video artifacts are first-class content artifacts (not journals) that can spawn child artifacts. Transcripts and segments are stored in `qxb_artifact_video.content`.

---

## Action: `artifact.query`

### Description
Retrieve a single artifact by `artifact_id` and `artifact_type`.

### Semantics
- **Spine-first:** Fetches `qxb_artifact` by `workspace_id` + `artifact_id` first
- **Type validation:** Compares requested `artifact_type` vs stored type
- **Type branching:** Routes to type-specific extension table based on stored `artifact_type`
- **Response merging:** Merges spine + extension fields into single payload
- **RLS enforced:** Only workspace members can query artifacts (journals are owner-only)

---

## Request Envelope

```json
{
  "gw_user_id": "uuid",
  "gw_workspace_id": "uuid",
  "gw_action": "artifact.query",
  "artifact_id": "uuid",
  "artifact_type": "string"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `gw_user_id` | uuid | ✅ | Acting user's qxb_user.user_id (mapped from auth.uid()) |
| `gw_workspace_id` | uuid | ✅ | Target workspace ID |
| `gw_action` | string | ✅ | Must be `"artifact.query"` |
| `artifact_id` | uuid | ✅ | Unique artifact identifier |
| `artifact_type` | string | ✅ | Expected artifact type (validated against stored type) |

### Selector Pattern

The combination of `gw_workspace_id` + `artifact_id` forms the **selector** for retrieval. The `artifact_type` parameter is used for **type validation** to prevent type mismatch errors.

---

## Response Envelope (Success)

```json
{
  "artifact": {
    "artifact_id": "uuid",
    "workspace_id": "uuid",
    "owner_user_id": "uuid",
    "artifact_type": "string",
    "title": "string",
    "summary": "string | null",
    "tags": ["array", "of", "strings"] | null,
    "content": { /* jsonb */ } | null,
    "created_at": "timestamptz",
    "updated_at": "timestamptz",
    "lifecycle_status": "string | null",
    "priority": "integer | null",
    "parent_artifact_id": "uuid | null",

    /* Type-specific extension fields merged here */
    /* Example for project: */
    "lifecycle_stage": "seed | sapling | tree | retired",
    "operational_state": { /* jsonb */ }
  }
}
```

### Response Notes
- Spine fields (`qxb_artifact`) are always included
- Extension fields are merged based on `artifact_type`
- Redundant `artifact_type` field is stripped from extension payload before merge
- All timestamps are in ISO 8601 format with timezone

---

## Response Envelope (Error)

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "string",
    "message": "string",
    "details": {
      /* context-specific details */
    }
  }
}
```

### Standard Error Codes

| Code | Description | Example Scenario |
|------|-------------|------------------|
| `TYPE_MISMATCH` | Requested artifact_type does not match stored type | Query for "project" but artifact is "journal" |
| `NOT_FOUND` | Artifact not found or access denied (RLS) | artifact_id doesn't exist or user lacks workspace access |
| `VALIDATION_ERROR` | Missing or invalid request parameters | Missing `artifact_id` or invalid UUID format |
| `UNAUTHORIZED` | User lacks permission to query this artifact | Non-owner attempting to query journal artifact |

---

## Example: Query Project Artifact

### Request
```json
{
  "gw_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "gw_action": "artifact.query",
  "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
  "artifact_type": "project"
}
```

### Expected Response
```json
{
  "artifact": {
    "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
    "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
    "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
    "artifact_type": "project",
    "title": "Walk Phase 1: Email Automation",
    "summary": "Build automated email sequences for signup flow",
    "tags": ["walk-stage", "email-automation"],
    "content": {
      "phase": "walk-phase-1",
      "crawl_completion": "2026-01-03"
    },
    "created_at": "2025-12-30T10:00:00Z",
    "updated_at": "2025-12-30T10:00:00Z",
    "lifecycle_status": "seed",
    "priority": null,
    "parent_artifact_id": null,
    "lifecycle_stage": "seed",
    "operational_state": {
      "status": "ready_to_activate",
      "deliverables": ["Email sequences workflow", "Runbook"]
    }
  }
}
```

---

## Example: Type Mismatch Error

### Request
```json
{
  "gw_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "gw_action": "artifact.query",
  "artifact_id": "db428a32-1afa-4e6b-a649-347b0bffd46c",
  "artifact_type": "project"
}
```

### Expected Response (Error)
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "TYPE_MISMATCH",
    "message": "Requested artifact_type does not match stored artifact_type for this artifact_id.",
    "details": {
      "artifact_id": "db428a32-1afa-4e6b-a649-347b0bffd46c",
      "requested_artifact_type": "project",
      "stored_artifact_type": "journal"
    }
  }
}
```

---

## Spine-First Architecture

Gateway v1 implements **spine-first retrieval pattern**:

1. **Fetch spine:** Query `qxb_artifact` by `workspace_id` + `artifact_id`
2. **Type validation:** Compare requested `artifact_type` vs `qxb_artifact.artifact_type`
3. **Type branching:** Route to appropriate extension table:
   - `project` → `qxb_artifact_project`
   - `journal` → `qxb_artifact_journal`
   - `snapshot` → `qxb_artifact_snapshot`
   - `restart` → `qxb_artifact_restart`
   - `video` → `qxb_artifact_video`
4. **Response merge:** Combine spine + extension fields, strip redundant `artifact_type`

This pattern ensures:
- Single source of truth for artifact_type (stored in spine)
- Type safety at API boundary
- Efficient joins (indexed workspace_id + artifact_id)

---

## RLS Enforcement

Row Level Security policies enforce access control:

- **Workspace members:** Can query artifacts in workspaces where they have membership
- **Owner-only artifacts:** Journals are restricted to `owner_user_id` only
- **Forbidden access:** Returns `NOT_FOUND` error (does not leak artifact existence)

RLS is enforced at database level; Gateway workflows inherit these policies.

---

## Known-Good Baseline (KGB)

**KGB Test IDs** (workspace: `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`):
- journal: `db428a32-1afa-4e6b-a649-347b0bffd46c`
- project: `668bd18f-4424-41e6-b2f9-393ecd2ec534`
- snapshot: `610e16d1-c5bb-468c-bd35-57eadf9f2e38`
- restart: `ac1d6294-2bd7-4a9d-823e-827562b56e26`

All KGB artifacts have been validated for end-to-end query operations.

---

## CHANGELOG

### v1.0 — 2026-01-04
**What changed:** Initial query contract definition

**Why:** Establish canonical read semantics for Gateway v1 MVP; separate query operations from write operations (artifact.save)

**Scope:** artifact.query action only (read operations)

**How to validate:** Execute KGB test suite against known artifact IDs; verify response envelopes match contract

**Previous version:** None (initial version)

---

**Version:** v1.0
**Status:** Active — MVP Complete
**Last Updated:** 2026-01-04
