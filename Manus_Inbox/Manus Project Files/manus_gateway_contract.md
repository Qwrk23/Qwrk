# Manus Reference — Gateway Contract Summary

**Purpose:** Reviewer-oriented Gateway contract summary. Not a canonical contract source.
**Date:** 2026-05-06
**Canonical sources:** CLAUDE.md v32 (Workflow Deployment Checklist; n8n Gateway Workflow Rules; T165 manual-edit prohibition); MEMORY operational state for current sub-workflow versions; OPEN_THREADS Active Surface for in-flight contract work (T167, T175, T177, T185).

---

## What the Gateway Is

The Gateway is an n8n webhook endpoint that serves as the **single entry point** for all artifact and messaging operations. Every client (Chrome Extension, Sidebar, scripts, ChatGPT-side helpers) talks to the Gateway — never directly to the database.

**Current production gateway:** `NQxb_Gateway_v2` (build 4). v1 fully decommissioned 2026-03-26 (T122) — references to "Gateway v68" or `/v1` in older docs are tombstones.

**Endpoint:** `POST https://n8n.halosparkai.com/webhook/nqxb/gateway/v2`

The Gateway:
- Accepts standardized JSON envelope requests
- Validates action, workspace, artifact type, and permissions
- Routes via `CREDENTIAL_WORKSPACE_MAP` in Gatekeeper to resolve principal → workspace
- Routes to specialized sub-workflows (Save, Query, List, Update, Promote, etc.)
- Returns standardized success or error responses
- Uses `service_role` credentials (bypasses RLS by design — see CLAUDE.md "Access Control Model")

**Authentication:** Per-workspace Basic Auth principal (e.g., `qwrk-gateway` for Prime, `qwrk-gw-work` for Q@W, `qwrk-gw-blagglife`, `qwrk-gw-akara`, `qwrk-gw-greg`, `qwrk-gw-demo`).

---

## Supported Actions

The Gateway exposes **10 canonical actions** (8 artifact + 2 messaging), listed below. In addition, **`payload.build` is deployed under T175 but its action signature, route status (distinct `gw_action` vs. sub-route), validate-only vs. execute-mode contract, and canonical action-count classification are pending Joel/Q confirmation.** This file therefore lists `payload.build` separately, NOT in the canonical action table. Manus reviewing plans that invoke `payload.build` should request the canonical contract from Joel/Q before evaluating.

### Artifact Operations (8 canonical)

| Action | Purpose | Mutates Data |
|--------|---------|:------------:|
| `artifact.save` | Insert a new artifact (spine + extension). Save v50 enforces Strict Mode (T167 Tree B): extension allowlists, empty-object rejection, for-q auto-injection, execution_status default, parent requirement, twig completeness. | Yes |
| `artifact.query` | Fetch a single artifact by ID. TYPE_ALLOWLIST = 9 types (project, journal, restart, snapshot, instruction_pack, branch, limb, leaf, twig). `thorn` / `grass` return `ARTIFACT_TYPE_NOT_ALLOWED`. | No |
| `artifact.list` | List artifacts with filtering/pagination. List v30 supports tag filters, type filters, error passthrough. | No |
| `artifact.update` | Update mutable fields on existing artifact. Update T140 v2 includes spine preservation (T88 fix), F2 hardening, tags serialization fix, content/content_append path. | Yes |
| `artifact.promote` | Transition project lifecycle (seed→sapling→tree→archive). Promote v24 atomic via `promote_artifact_lifecycle()` RPC; T113 DB_Read filter fix. | Yes |
| `artifact.delete` | Soft-delete an artifact (sets `deleted_at`; never hard delete). | Yes |
| `artifact.restore` | Restore a soft-deleted artifact. | Yes |
| `artifact.list_deleted` | List soft-deleted artifacts. | No |

### Messaging Operations (2 canonical)

| Action | Purpose | Mutates Data |
|--------|---------|:------------:|
| `messaging.send_email` | Send email via Gmail. Payload: `body_html` + `body_text` (dual format), `to` accepts array for multi-recipient. Self-shaped envelope (Gateway passes through without reshaping). | External |
| `messaging.create_calendar_event` | Create Google Calendar event. v2 supports recurrence (RRULE), attendees, sendUpdates, timezone. | External |

### Additional capability — under verification (NOT in the canonical action table)

`payload.build` — payload assembler/validator deployed under T175 Salience Amplification. T175 reports v1.1 certified (9/9 tests, deployed to Gateway v2). T177 reports an `execute`-mode investigation in progress (Qx→payload.build execute path returned validation-only response).

**Status (do NOT treat as canonical until Joel/Q confirms):**
- Exact `gw_action` value: pending confirmation.
- Distinct action vs. sub-route status: pending confirmation.
- Validate-only vs. execute-mode contract: validate-only confirmed; execute-mode under investigation.
- Canonical action-count classification (11th canonical action vs. additional capability): pending confirmation.

**Manus posture:** When a plan invokes `payload.build`, Manus should reference this section, request the canonical contract from Joel/Q, and flag any plan that assumes the action signature is decided. Manus must not infer the contract by analogy with other actions.

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

Newer error codes Manus should recognize:
- `INVALID_SEMANTIC_TYPE` — semantic type value is not accepted by the current Gateway/semantic registry path (T69). Where supported by the current Gateway request contract, plans should pass registry keys (e.g., `"infrastructure"`, `"governance"`) rather than raw UUIDs; Gateway/schema behavior should be verified against the canonical Gateway contract when precision matters.
- `ARTIFACT_TYPE_NOT_ALLOWED` — type not in TYPE_ALLOWLIST for the requested action (commonly seen on `artifact.query` for `thorn` / `grass`).
- Strict Mode rejection codes (T167 Tree B) — extension-allowlist violation, empty-object rejection, missing required parent, twig completeness violation, missing for-q auto-injection target. Exact code names to be verified from Save v50 source.

---

## Key Gateway Behaviors

### Spine-First Pattern
For all single-artifact operations, Gateway fetches the spine record first, validates the type against the request, then routes to the appropriate extension table.

### Type Mismatch Guard
If the `artifact_type` in the request does not match the stored `artifact_type` for that `artifact_id`, the Gateway returns `TYPE_MISMATCH` error. This prevents accidental cross-type operations.

### Save Normalization (Strict Mode — T167 Tree B)
The Save sub-workflow normalizes incoming payloads — flattening, defaulting priority, validating required fields — before inserting into spine and extension tables. Save v50 also enforces Strict Mode invariants: extension allowlist enforcement, empty-object rejection, for-q auto-injection, execution_status default, parent artifact requirement, and twig completeness validation. Plans that produce save payloads without these properties will be rejected.

### Extension-Only vs Spine+Extension Updates
Updates can target spine fields, extension fields, or both. The Update sub-workflow determines which surfaces are affected and routes accordingly.

### Promote Lifecycle Guards
Lifecycle transitions (seed→sapling→tree→archive) are directional and validated. Backward transitions are rejected. The Promote sub-workflow handles atomic lifecycle state changes.

---

## Gateway Architecture — Sub-Workflows

The Gateway routes to specialized sub-workflows. Current production versions:

| Sub-Workflow | Handles | Current Version |
|-------------|---------|-----------------|
| `NQxb_Artifact_Save` | artifact.save | v50 (T167 Sapling B Strict Mode) |
| `NQxb_Artifact_Query` | artifact.query | v21 (T70 rollup view) |
| `NQxb_Artifact_List` | artifact.list | v30 (T112 error passthrough) |
| `NQxb_Artifact_Update` | artifact.update | T140 v2 (T88 spine preservation + F2 + tags fix) |
| `NQxb_Artifact_Promote` | artifact.promote | v24 (T113 DB_Read filter fix) |
| Gmail Send | messaging.send_email | (T123) |
| Calendar Event | messaging.create_calendar_event | v2 (T124) |

> Manus does NOT need to memorize sub-workflow IDs. CC maintains the authoritative ID registry in `memory/workflow-ids.md`. Plans should reference current version numbers; if Manus sees a plan citing a sub-workflow version that disagrees with this table, flag it for verification.

### Deployment Coupling (CRITICAL)

When a sub-workflow is updated, the Gateway's "Execute Workflow" node must be updated to point to the new version. Forgetting this means the Gateway still calls the old version — fixes appear to have no effect. Manus reviewing deployment plans should confirm the plan explicitly addresses Gateway "Execute Workflow" node updates.

### Production Editing Discipline (T165)

No manual expression edits to production workflows in the n8n UI. All expression changes must go through a build script or auditable patch artifact that verifies intended-diff-only. Manual UI edits require explicit Joel approval. Plans that propose direct UI edits without this discipline should be flagged.

### Execute Workflow Transport Hardening (Session 123)

`onError: continueRegularOutput` + `alwaysOutputData: true` are required on Save / Promote / Update Execute Workflow nodes in the Gateway. Plans that rebuild or re-import the Gateway must preserve these settings.

---

## Multi-Gateway Topology

| Gateway | Status | Routes |
|---------|--------|--------|
| **Qwrk** (primary) — `NQxb_Gateway_v2` | Production (build 4) | Routes the confirmed active workspaces (Prime, Q@W, BlaggLife, Akara, Greg) via credential→workspace resolution. **Demo** is also routed via this gateway, but Demo's operational category is to be confirmed by Joel — see `manus_current_state.md` for the workspace-status flag. |
| **Qwrk Beta** (provisioning surface) | Status to be verified with Joel | Beta workspace provisioning under T145 / T176. **Endpoint naming, current build, and operational categorization are NOT asserted in this file.** Confirm with Joel before reviewing any plan that touches the Beta gateway. Treat Beta as a provisioning surface distinct from production workspaces. |
| ~~v1 clones~~ | Decommissioned 2026-03-26 (T122) | All v1 workspace clones (Q@W, BlaggLife, Akara, Greg) retired; archived under `workflows/Archive/`. |

When a plan changes Gateway behavior, Manus should specify whether the change applies to primary, Beta provisioning surface, or both — and whether the plan acknowledges that v1 is dead.

---

## Review Implications

When reviewing plans that touch the Gateway:

- **New actions** require: Gatekeeper update, sub-workflow creation, response shaper, Gateway routing
- **Field additions** require: Gatekeeper field allow-listing, Normalize_Request update, sub-workflow handling
- **Type additions** require: Gatekeeper TYPE_ALLOWLIST update (currently 9 types for query), extension table handling in Save/Query/Update
- **Deployment** requires: sub-workflow version update → Gateway "Execute Workflow" node update → both gateways (where applicable, given Beta state pending confirmation)
- Plans should specify which gateways are affected (primary, Beta provisioning surface, or both)

---

## CHANGELOG

### Proposed v2 — 2026-05-06 (pending Q/Joel confirmation on versioning convention)

**Version number is a proposal, not an assumption.** If Joel prefers a different versioning style, the bump label changes accordingly; the body of the change set does not.

**What changed (proposed):** Replaced "Gateway v68" tombstone label with "Gateway v2 build 4" everywhere; updated What the Gateway Is to credential→workspace resolution detail; added "Additional capability — under verification" sub-section for `payload.build` (kept outside canonical action table); refreshed Sub-Workflow table with current versions (Save v50, Query v21, List v30, Update T140 v2, Promote v24); added Production Editing Discipline (T165) and Execute Workflow Transport Hardening (Session 123); restructured Multi-Gateway Topology to mark Beta as status-to-be-verified and v1 as decommissioned; added newer error codes (`INVALID_SEMANTIC_TYPE`, `ARTIFACT_TYPE_NOT_ALLOWED`, Strict Mode codes) — `INVALID_SEMANTIC_TYPE` wording revised per TQR amendment to avoid overstating key-vs-UUID behavior; extended Save Normalization paragraph with Strict Mode invariants (T167 Tree B). Preserved: Request Envelope, Response Patterns success/error shape, Spine-First Pattern, Type Mismatch Guard, Extension-Only/Spine+Extension Updates, Promote Lifecycle Guards.

**Why:** Prior v1 referenced Gateway v68 (decommissioned); listed `_v1` sub-workflow names without current versions; lacked Strict Mode framing for plans reviewed under T167-era contracts; lacked any payload.build framing despite T175 deployment.

**Previous version:** `Archive/manus_gateway_contract__v1__2026-03-22.md`

### v1 — 2026-03-22
Initial creation for Manus plan reviewer role.
