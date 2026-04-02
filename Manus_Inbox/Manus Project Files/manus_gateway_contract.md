# Manus Reference — Gateway Contract Summary

**Purpose:** Reviewer-oriented Gateway contract summary. Not a canonical contract source.
**Date:** 2026-03-22
**Canonical sources:** `docs/workflows/NQxb_Gateway_v1__README.md`, `docs/contracts/AAA_New_Qwrk__Gateway_Contract__v1.0__2026-01-03.md`

---

## What the Gateway Is

The Gateway is an n8n webhook endpoint that serves as the **single entry point** for all artifact and messaging operations. Every client (Chrome Extension, Sidebar, scripts) talks to the Gateway — never directly to the database.

**Current endpoint:** `POST https://n8n.halosparkai.com/webhook/nqxb/gateway/v2`

The Gateway:
- Accepts standardized JSON envelope requests
- Validates action, workspace, artifact type, and permissions
- Routes to specialized sub-workflows (Save, Query, List, Update, Promote, etc.)
- Returns standardized success or error responses
- Uses `service_role` credentials (bypasses RLS by design)

---

## Supported Actions (10 total, Gateway v68)

### Artifact Operations (8)

| Action | Purpose | Mutates Data |
|--------|---------|:------------:|
| `artifact.save` | Insert a new artifact (spine + extension) | Yes |
| `artifact.query` | Fetch a single artifact by ID | No |
| `artifact.list` | List artifacts with filtering/pagination | No |
| `artifact.update` | Update mutable fields on existing artifact | Yes |
| `artifact.promote` | Transition project lifecycle (seed→sapling→tree→archive) | Yes |
| `artifact.delete` | Soft-delete an artifact | Yes |
| `artifact.restore` | Restore a soft-deleted artifact | Yes |
| `artifact.list_deleted` | List soft-deleted artifacts | No |

### Messaging Operations (2)

| Action | Purpose | Mutates Data |
|--------|---------|:------------:|
| `messaging.send_email` | Send email via Gmail | External |
| `messaging.create_calendar_event` | Create Google Calendar event | External |

---

## Request Envelope

Every Gateway request includes:

```json
{
  "gw_action": "artifact.save | artifact.query | ...",
  "gw_workspace_id": "<uuid>",
  "artifact_type": "<type>",
  ...action-specific fields...
}
```

- `gw_action` — required, determines routing
- `gw_workspace_id` — required, tenancy boundary
- `artifact_type` — required for most actions
- Additional fields vary by action (e.g., `artifact_id` for query, `extension` for save)

---

## Response Patterns

### Success

```json
{
  "artifact": {
    "artifact_id": "...",
    "workspace_id": "...",
    "artifact_type": "...",
    ...merged spine + extension fields...
  }
}
```

### Error

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable description",
    "details": { ...context... }
  }
}
```

Common error codes: `TYPE_MISMATCH`, `NOT_FOUND`, `VALIDATION_ERROR`, `JOURNAL_INSERT_ONLY`, `IMMUTABLE_TYPE`.

---

## Key Gateway Behaviors

### Spine-First Pattern
For all single-artifact operations, Gateway fetches the spine record first, validates the type against the request, then routes to the appropriate extension table.

### Type Mismatch Guard
If the `artifact_type` in the request does not match the stored `artifact_type` for that `artifact_id`, the Gateway returns `TYPE_MISMATCH` error. This prevents accidental cross-type operations.

### Save Normalization
The Save sub-workflow normalizes incoming payloads — flattening, defaulting priority, validating required fields — before inserting into spine and extension tables.

### Extension-Only vs Spine+Extension Updates
Updates can target spine fields, extension fields, or both. The Update sub-workflow determines which surfaces are affected and routes accordingly.

### Promote Lifecycle Guards
Lifecycle transitions (seed→sapling→tree→archive) are directional and validated. Backward transitions are rejected. The Promote sub-workflow handles atomic lifecycle state changes.

---

## Gateway Architecture — Sub-Workflows

The Gateway routes to specialized sub-workflows:

| Sub-Workflow | Handles |
|-------------|---------|
| `NQxb_Artifact_Save_v1` | artifact.save |
| `NQxb_Artifact_Query_v1` | artifact.query |
| `NQxb_Artifact_List_v1` | artifact.list |
| `NQxb_Artifact_Update_v1` | artifact.update |
| `NQxb_Artifact_Promote_v1` | artifact.promote |

Each sub-workflow has response shapers that format output before returning to the Gateway.

### Deployment Coupling
When a sub-workflow is updated, the Gateway's "Execute Workflow" node must be updated to point to the new version. Forgetting this means the Gateway still calls the old version — the fix appears to have no effect.

---

## Multi-Gateway Topology

Two Gateway instances exist:

| Gateway | Endpoint | Purpose |
|---------|----------|---------|
| **Qwrk** (primary) | `/webhook/nqxb/gateway/v2` | All production workspaces |
| **Qwrk Beta** | `/webhook/nqxb/gateway/v2/beta` | Beta user workspaces |

Both use the same contract. Changes to one must be rolled out to the other.

---

## Review Implications

When reviewing plans that touch the Gateway:

- **New actions** require: Gatekeeper update, sub-workflow creation, response shaper, Gateway routing
- **Field additions** require: Gatekeeper field allow-listing, Normalize_Request update, sub-workflow handling
- **Type additions** require: Gatekeeper type allow-listing, extension table handling in Save/Query/Update
- **Deployment** requires: sub-workflow version update → Gateway "Execute Workflow" node update → both gateways
- Plans should specify which gateways are affected (primary, beta, or both)

---

## CHANGELOG

### v1 — 2026-03-22
Initial creation for Manus plan reviewer role.
