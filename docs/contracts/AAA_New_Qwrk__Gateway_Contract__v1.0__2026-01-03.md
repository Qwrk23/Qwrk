# AAA_New_Qwrk — Gateway Contract v1.0
**Date:** 2026-01-03 (CST)
**Status:** DRAFT — Governance Review

---

**📌 Scope Note (2026-01-04):**
This contract governs **artifact.save** (write semantics only). Query semantics are defined in `Gateway_Query_Contract__v1.0__MVP.md`.

---

## 1. Purpose

This document defines the **canonical Gateway Contract v1.0** for Qwrk. It is the single source of truth for how external callers (including CustomGPT Actions and Claude Code) may create or update records in Qwrk.

This contract:
- Governs **what actions are allowed**
- Defines **request and response envelopes**
- Defines **error semantics**
- Maps allowed actions to **NoFail SQL Models**
- Prevents schema drift, column invention, and client-side lifecycle control

This contract is **authoritative**. All OpenAPI schemas, CustomGPT Actions, and workflow implementations must be derived from it.

---

## 2. Governing Invariants (Non-Negotiable)

1. **Spine First** — Every record write begins with `qxb_artifact`.
2. **Server Truth** — The server assigns `artifact_id`, `version`, and timestamps.
3. **Single Save Action** — Clients never choose create vs update semantics.
4. **Append-Only History** — Updates produce new versions/events; no destructive overwrites.
5. **No Column Invention** — Only columns defined in live Supabase schemas may be written.
6. **NoFail Alignment** — All writes must follow the NoFail SQL Models.

---

## 3. Allowed Artifact Types

The following `artifact_type` values are allowed and enforced by database constraints:

- `forest`
- `thicket`
- `project`
- `snapshot`
- `restart`
- `journal`
- `video` — Long-form media artifacts (e.g., YouTube videos) with transcripts and derived insights
- `flower`
- `thorn`
- `grass`

Any other value must be rejected with a validation error.

**Note on video type**: Video artifacts are first-class content artifacts that can spawn child artifacts (gems, snapshots, projects). Transcripts and derived insights are stored in the `qxb_artifact_video.content` JSONB field.

---

## 4. Allowed Actions

### 4.1 `artifact.save`

**Description:**  
Create or update an artifact. The Gateway determines create vs update semantics.

**Semantics:**
- `artifact_id` **absent** → Create new artifact
- `artifact_id` **present** → Update existing artifact (new version/event)

There are no separate create or update actions.

---

## 5. Request Envelope

All requests to the Gateway must conform to the following envelope:

```json
{
  "action": "artifact.save",
  "workspace_id": "uuid",
  "owner_user_id": "uuid",
  "artifact_type": "string",
  "artifact_id": "uuid | null",
  "parent_artifact_id": "uuid | null",
  "title": "string | null",
  "summary": "string | null",
  "entry_text": "string | null",
  "payload": { "json": "object" }
}
```

### Field Notes
- `artifact_id` is **optional** and ignored on create
- `version` is **never accepted** from the client
- `payload` and `entry_text` map directly to NoFail SQL models

---

## 6. Response Envelope

Successful responses return:

```json
{
  "status": "ok",
  "artifact_id": "uuid",
  "artifact_type": "string",
  "version": "integer",
  "created_at": "timestamp",
  "parent_artifact_id": "uuid | null"
}
```

Notes:
- `version` is always server-assigned
- Response fields are minimal and stable

---

## 7. Error Model

All errors use the following envelope:

```json
{
  "status": "error",
  "error": {
    "code": "string",
    "message": "string",
    "details": "string | null"
  }
}
```

### Standard Error Codes
- `validation_error`
- `artifact_type_not_allowed`
- `parent_not_found`
- `unauthorized`
- `conflict`
- `internal_error`

---

## 8. Per-Artifact Validation Matrix

| Artifact Type | Required Fields | Optional Fields | Notes |
|-------------|----------------|----------------|------|
| forest | title | summary, payload | Root-level container |
| thicket | title, parent_artifact_id | summary, payload | Parent must be forest |
| project | title, parent_artifact_id | summary, payload | Parent must be thicket |
| snapshot | parent_artifact_id, payload | title, summary | Parent must be project |
| restart | parent_artifact_id, payload | title, summary | Governance capture |
| journal | entry_text | parent_artifact_id, payload | Freeform text |
| flower | title | summary, payload | Lightweight artifact |

---

## 9. Mapping to NoFail SQL Models

Each `artifact.save` invocation maps to exactly one NoFail SQL model:

| Artifact Type | NoFail Model |
|--------------|-------------|
| forest | NoFail_Forest_Insert |
| thicket | NoFail_Thicket_Insert |
| project | NoFail_Project_Insert |
| snapshot | NoFail_Snapshot_Insert |
| restart | NoFail_Restart_Insert |
| journal | NoFail_Journal_Insert |
| flower | NoFail_Flower_Insert |

All models:
- Insert into `qxb_artifact`
- Insert into extension table if applicable
- Append event row

---

## 10. KGB Test Payload Examples

### Valid Create (Project)
```json
{
  "action": "artifact.save",
  "workspace_id": "uuid",
  "owner_user_id": "uuid",
  "artifact_type": "project",
  "parent_artifact_id": "uuid",
  "title": "Build Tree",
  "summary": "Initial build tree"
}
```

### Invalid (Client-Supplied Version)
```json
{
  "action": "artifact.save",
  "artifact_type": "project",
  "version": 7
}
```

Expected result: `validation_error`

---

## 11. Derived Artifacts

The following artifacts must be derived from this contract:
- OpenAPI schema
- CustomGPT Action definitions
- Gateway workflow implementations

No derived artifact may introduce fields, actions, or semantics not defined here.

---

**End of Gateway Contract v1.0**
