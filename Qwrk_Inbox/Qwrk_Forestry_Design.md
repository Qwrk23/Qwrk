# Qwrk Forestry Design — Gateway Multi-Forest Enablement

**Version:** 1.0
**Date:** 2026-02-08
**Status:** Design (not yet implemented)
**Governance Anchor:** `3f854e00-12d5-474a-83f1-e40b4c77e115` (Forestry Governance v2)
**Scope:** Evolve Gateway from MVP single-workspace lock to multi-forest model

---

## Overview

The Qwrk Gateway currently enforces a hard-coded single-workspace lock (`WORKSPACE_FORBIDDEN`) that rejects any workspace_id other than the default Master Joel Workspace. This design replaces that lock with a database-backed authorization model that supports multiple forests (workspaces) with scoped access per principal.

---

## Current State

### Gateway Authorization Flow

```
Webhook (Basic Auth)
  → Normalize_Request (extracts gw_action, gw_workspace_id, auth_username)
  → Gatekeeper_MVP_OwnerOnly
      ├─ Validates gw_action ∈ ACTION_ALLOWLIST (8 actions)
      ├─ Validates gw_workspace_id == "be0d3a48-..." (HARD-CODED)  ← THIS CHANGES
      ├─ Validates artifact_type ∈ TYPE_ALLOWLIST
      └─ Route-specific validation (artifact_id, extension, transition)
  → Switch_Action → [query|list|save|update|promote|delete|restore|list_deleted]
```

### Hard-Coded Lock (Gatekeeper Node)

```javascript
const OWNER_WORKSPACE_ID = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a";

if (gw_workspace_id !== OWNER_WORKSPACE_ID) {
  return fail("WORKSPACE_FORBIDDEN", "Workspace not permitted in MVP owner-only mode", {
    gw_workspace_id,
    allowed_workspace_id: OWNER_WORKSPACE_ID,
  });
}
```

### Existing Schema (Already in Kernel v1)

| Table | Purpose | Relevant Columns |
|-------|---------|-----------------|
| `qxb_workspace` | Workspace metadata | workspace_id, name, created_at, updated_at |
| `qxb_workspace_user` | Role-based membership | workspace_id, user_id, role (owner/admin/member) |

**Note:** `qxb_workspace` in LIVE DDL has no `owner_user_id` column (Schema Reference v1.1 lists it but DDL is truth). Ownership is determined by `qxb_workspace_user` role='owner'.

### Known Workspaces (Database)

| Workspace ID | Name | Artifacts |
|-------------|------|-----------|
| `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` | Master Joel Workspace | ~609 |
| `b4e7f648-96d5-44a7-80b9-c39cac4efbd1` | (unnamed — 2 journals, content null) | 2 |

---

## Target State

### Architecture (Target)

```
Webhook (Basic Auth)
  → Normalize_Request (extracts gw_action, gw_workspace_id, auth_username)
  → ACL_Lookup (NEW: HTTP GET qxb_gateway_acl by principal + workspace)
  → Gatekeeper_v2 (MODIFIED: checks ACL result instead of constant)
      ├─ Validates gw_action ∈ ACTION_ALLOWLIST
      ├─ Validates ACL_Lookup returned a match (replaces hard-coded check)
      ├─ Validates artifact_type ∈ TYPE_ALLOWLIST
      └─ Route-specific validation
  → Switch_Action → [query|list|save|update|promote|delete|restore|list_deleted]
```

### Authorization Matrix (Principal × Forest)

| Principal | Qwrk Personal | BlaggLife | Work (Resolve) |
|-----------|:------------:|:---------:|:--------------:|
| `qwrk-steward` (Joel/Qwrk) | R/W | R/W | R/W |
| `blagglife-head` | — | R/W | — |
| `work-head` | — | — | R/W |

**Implementation:** Each cell = a row in `qxb_gateway_acl`. Absence = WORKSPACE_FORBIDDEN.

### Forest → Workspace Mapping (1:1, Locked)

| Forest | Workspace ID | Status |
|--------|-------------|--------|
| Qwrk Personal | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` | Existing (default) |
| BlaggLife | `b4e7f648-96d5-44a7-80b9-c39cac4efbd1` | Existing (needs name + ACL) |
| Work (Resolve) | TBD (new workspace) | To be created |

---

## Data Model

### New Table: `qxb_gateway_acl`

**Purpose:** Maps Gateway principals (Basic Auth usernames) to authorized workspaces. Queried by the Gateway on every request to enforce scoped access.

```sql
CREATE TABLE public.qxb_gateway_acl (
    acl_id          uuid DEFAULT gen_random_uuid() NOT NULL,
    principal_name  text NOT NULL,
    workspace_id    uuid NOT NULL,
    granted_at      timestamptz DEFAULT now() NOT NULL,
    granted_by      text,
    notes           text,
    CONSTRAINT qxb_gateway_acl_pkey PRIMARY KEY (acl_id),
    CONSTRAINT qxb_gateway_acl_unique UNIQUE (principal_name, workspace_id),
    CONSTRAINT qxb_gateway_acl_workspace_fk FOREIGN KEY (workspace_id)
        REFERENCES public.qxb_workspace(workspace_id)
);

COMMENT ON TABLE public.qxb_gateway_acl IS
  'Gateway authorization control list. Maps API principals to permitted workspaces. No RLS — accessed only by service role.';
```

**Design decisions:**

1. **No RLS needed** — The Gateway uses the Supabase service role key (bypasses RLS). This table is only queried by the Gateway, never by end users.

2. **No `qxb_forest` table** — `qxb_workspace` already serves as the forest entity. Creating a parallel table would introduce redundancy. If forest-specific metadata is needed later (type, description, status), add columns to `qxb_workspace` via ALTER TABLE.

3. **No artifact-level ACLs** — Workspace-level authorization is sufficient for Phase 1 (per prompt constraints).

4. **`principal_name` is text, not FK** — Principals are n8n Basic Auth credentials, not Supabase users. No FK relationship to `qxb_user`. This is intentional: Gateway auth and Supabase auth are separate concerns.

5. **`granted_by` is freeform text** — Audit trail of who authorized access. Not enforced by FK (could be "joel", "system", etc.).

### Workspace Metadata Update

Update existing BlaggLife workspace name:

```sql
UPDATE public.qxb_workspace
SET name = 'BlaggLife'
WHERE workspace_id = 'b4e7f648-96d5-44a7-80b9-c39cac4efbd1';
```

Create Work Forest workspace:

```sql
INSERT INTO public.qxb_workspace (name)
VALUES ('Work - Resolve.io')
RETURNING workspace_id;
-- Save returned workspace_id for ACL seeding
```

---

## API Contract Changes

### Request Contract

**No changes.** `gw_workspace_id` remains required in all requests. No default workspace behavior. Clients must specify which forest they are operating in.

**Rationale:** Deterministic routing. No ambiguity about which forest a request targets. Prevents accidental cross-forest writes.

### Error Semantics

**WORKSPACE_FORBIDDEN** error is preserved with improved details:

```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "WORKSPACE_FORBIDDEN",
    "message": "Principal is not authorized for this workspace.",
    "details": {
      "gw_workspace_id": "...",
      "principal": "blagglife-head"
    }
  }
}
```

**Changes from current:**
- Message updated (no longer references "MVP owner-only mode")
- `details.principal` added (identifies which principal was denied)
- `details.allowed_workspace_id` removed (do not leak other workspace IDs)

### Forest Discovery

**Phase 1:** SQL-only / admin-only. No `forest.list` Gateway action.

```sql
-- Joel can query available forests directly
SELECT w.workspace_id, w.name, acl.principal_name
FROM qxb_workspace w
JOIN qxb_gateway_acl acl ON acl.workspace_id = w.workspace_id
ORDER BY w.name;
```

**Phase 2 (optional):** Add `forest.list` action that returns workspaces authorized for the calling principal.

---

## Gateway Implementation Plan

### Node Changes (3 nodes)

#### 1. NEW: `NQxb_Gateway_v1__ACL_Lookup` (HTTP Request node)

**Position:** Between `Normalize_Request` and Gatekeeper.

**Purpose:** Query `qxb_gateway_acl` for the requesting principal + workspace combination.

**Configuration:**
- Method: GET
- URL: `https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_gateway_acl`
- Query params:
  - `principal_name=eq.{{ $json.auth_username }}`
  - `workspace_id=eq.{{ $json.gw_workspace_id }}`
  - `select=acl_id,principal_name,workspace_id`
- Authentication: Supabase service role (predefined credential, typeVersion 4.2)
- Headers: `apikey`, `Authorization: Bearer {service_role_key}`
- On error: Continue (don't fail the workflow — Gatekeeper handles empty result)

**Output:** Array of matching ACL rows. Empty array = no access.

**Note:** `auth_username` is already extracted by `Normalize_Request` and available in `_gw_debug.auth_username`. The ACL_Lookup node should reference it from there, or Normalize_Request should surface it as a top-level field.

#### 2. MODIFIED: `NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly` → `NQxb_Gateway_v1__Gatekeeper`

**Changes:**
- Remove `OWNER_WORKSPACE_ID` constant
- Remove hard-coded workspace comparison
- Add ACL check: verify ACL_Lookup returned at least one row
- Rename node (drop `MVP_OwnerOnly` suffix)

**Before (current):**
```javascript
const OWNER_WORKSPACE_ID = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a";
if (gw_workspace_id !== OWNER_WORKSPACE_ID) {
  return fail("WORKSPACE_FORBIDDEN", ...);
}
```

**After:**
```javascript
// ACL check — replaces hard-coded workspace lock
const acl_result = $node["NQxb_Gateway_v1__ACL_Lookup"].json;
const acl_rows = Array.isArray(acl_result) ? acl_result : [acl_result];
const has_access = acl_rows.some(r => r && r.acl_id);

if (!has_access) {
  return fail("WORKSPACE_FORBIDDEN", "Principal is not authorized for this workspace.", {
    gw_workspace_id,
    principal: auth_username,
  });
}
```

**All other Gatekeeper logic remains unchanged:** action allowlist, type allowlist, route-specific validation.

#### 3. MODIFIED: `NQxb_Gateway_v1__Normalize_Request`

**Change:** Surface `auth_username` as a top-level field (not just inside `_gw_debug`).

**Add to output:**
```javascript
auth_username: auth_username || "unknown"
```

This ensures the ACL_Lookup node can reference `{{ $json.auth_username }}` cleanly.

### Downstream Impact

**None.** All sub-workflows (Query, List, Save, Update, Promote) already receive `gw_workspace_id` as a pass-through field. They don't validate workspace authorization — that's the Gatekeeper's job. No sub-workflow changes needed.

### Wiring Summary

```
Webhook_In
  → Normalize_Request
  → ACL_Lookup (NEW)             ← HTTP GET qxb_gateway_acl
  → Gatekeeper (MODIFIED)        ← checks ACL result instead of constant
  → Switch_Route_OK_or_Error
  → Switch_Action
  → [existing action branches — unchanged]
```

---

## Migration Plan

### Step 1: Create ACL Table

```sql
-- Run in Supabase SQL Editor
CREATE TABLE public.qxb_gateway_acl (
    acl_id          uuid DEFAULT gen_random_uuid() NOT NULL,
    principal_name  text NOT NULL,
    workspace_id    uuid NOT NULL,
    granted_at      timestamptz DEFAULT now() NOT NULL,
    granted_by      text,
    notes           text,
    CONSTRAINT qxb_gateway_acl_pkey PRIMARY KEY (acl_id),
    CONSTRAINT qxb_gateway_acl_unique UNIQUE (principal_name, workspace_id),
    CONSTRAINT qxb_gateway_acl_workspace_fk FOREIGN KEY (workspace_id)
        REFERENCES public.qxb_workspace(workspace_id)
);

COMMENT ON TABLE public.qxb_gateway_acl IS
  'Gateway authorization control list. Maps API principals to permitted workspaces. No RLS — accessed only by service role.';
```

### Step 2: Name BlaggLife Workspace

```sql
UPDATE public.qxb_workspace
SET name = 'BlaggLife'
WHERE workspace_id = 'b4e7f648-96d5-44a7-80b9-c39cac4efbd1';
```

### Step 3: Create Work Forest Workspace

```sql
INSERT INTO public.qxb_workspace (name)
VALUES ('Work - Resolve.io')
RETURNING workspace_id;
-- ⚠️ Save the returned workspace_id — needed for Step 4 and Step 5
```

### Step 4: Add Joel as Owner of New Workspaces

```sql
-- Joel's user_id: c52c7a57-74ad-433d-a07c-4dcac1778672

-- BlaggLife (check if already exists first)
INSERT INTO public.qxb_workspace_user (workspace_id, user_id, role)
VALUES ('b4e7f648-96d5-44a7-80b9-c39cac4efbd1', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'owner')
ON CONFLICT (workspace_id, user_id) DO NOTHING;

-- Work Forest (use workspace_id from Step 3)
INSERT INTO public.qxb_workspace_user (workspace_id, user_id, role)
VALUES ('<work_workspace_id>', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'owner')
ON CONFLICT (workspace_id, user_id) DO NOTHING;
```

### Step 5: Seed ACL (Steward Access to All Forests)

```sql
-- Determine the current Basic Auth username used by Gateway
-- (check n8n credential: "Qwrk Supabase – Kernel v1" → username field)
-- Placeholder: 'qwrk-steward'

INSERT INTO public.qxb_gateway_acl (principal_name, workspace_id, granted_by, notes) VALUES
  ('qwrk-steward', 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'joel', 'Qwrk Personal (default)'),
  ('qwrk-steward', 'b4e7f648-96d5-44a7-80b9-c39cac4efbd1', 'joel', 'BlaggLife'),
  ('qwrk-steward', '<work_workspace_id>',                    'joel', 'Work - Resolve.io');
```

### Step 6: Verify ACL Data

```sql
SELECT acl.principal_name, w.name AS forest, acl.granted_at
FROM qxb_gateway_acl acl
JOIN qxb_workspace w ON w.workspace_id = acl.workspace_id
ORDER BY acl.principal_name, w.name;
```

**Expected output:**
| principal_name | forest | granted_at |
|---------------|--------|------------|
| qwrk-steward | BlaggLife | ... |
| qwrk-steward | Master Joel Workspace | ... |
| qwrk-steward | Work - Resolve.io | ... |

### Step 7: Update Gateway Workflow

1. Export current Gateway (`NQxb_Gateway_v1 (43).json`) to `workflows/Archive/`
2. Add `ACL_Lookup` HTTP Request node (see Gateway Implementation Plan)
3. Modify `Gatekeeper` Code node (replace workspace constant with ACL check)
4. Modify `Normalize_Request` (surface `auth_username`)
5. Re-wire: Normalize_Request → ACL_Lookup → Gatekeeper
6. Export as `NQxb_Gateway_v1 (44).json`
7. Import to n8n, activate
8. Test (see Test Plan)

### Step 8: Create Scoped Credentials (Phase 1 — Optional)

Create additional n8n Basic Auth credentials for scoped Heads:
- `blagglife-head` / `{password}` → ACL rows for BlaggLife workspace only
- `work-head` / `{password}` → ACL rows for Work workspace only

This step can be deferred until Heads are actually deployed.

---

## Test Plan

### Unit Tests (Gatekeeper Logic)

| # | Test | Input | Expected |
|---|------|-------|----------|
| U1 | Default workspace, valid principal | ws=`be0d3a48...`, principal=`qwrk-steward` | `_gw_route: "ok"` |
| U2 | BlaggLife workspace, valid principal | ws=`b4e7f648...`, principal=`qwrk-steward` | `_gw_route: "ok"` |
| U3 | Work workspace, valid principal | ws=`<work_id>`, principal=`qwrk-steward` | `_gw_route: "ok"` |
| U4 | Unknown workspace, valid principal | ws=`00000000-0000-0000-0000-000000000000` | `WORKSPACE_FORBIDDEN` |
| U5 | Missing workspace | ws=null | Existing validation catches this first |

### Integration Tests (End-to-End via Gateway)

| # | Test | Action | Expected |
|---|------|--------|----------|
| I1 | List artifacts in default forest | `artifact.list` + ws=`be0d3a48...` | Returns artifacts (backward compatible) |
| I2 | List artifacts in BlaggLife | `artifact.list` + ws=`b4e7f648...` | Returns 2 journal artifacts |
| I3 | Save artifact to BlaggLife | `artifact.save` + ws=`b4e7f648...` | INSERT succeeds, artifact in BlaggLife |
| I4 | Query artifact from BlaggLife | `artifact.query` + artifact from I3 | Returns artifact |
| I5 | Save to Work forest | `artifact.save` + ws=`<work_id>` | INSERT succeeds |
| I6 | List Work forest (empty) | `artifact.list` + ws=`<work_id>` | Returns empty list, count=0 |
| I7 | All 8 actions on default forest | Each action type | All still work (no regression) |

### Security Tests

| # | Test | Attack Vector | Expected |
|---|------|--------------|----------|
| S1 | Workspace ID tampering | Valid principal, unauthorized workspace | `WORKSPACE_FORBIDDEN` |
| S2 | Scoped principal cross-forest | `blagglife-head` tries ws=`be0d3a48...` | `WORKSPACE_FORBIDDEN` |
| S3 | No auth header | Missing Basic Auth | n8n returns 401 (pre-Gateway) |
| S4 | Invalid principal | Valid auth, unknown username | `WORKSPACE_FORBIDDEN` (no ACL rows) |
| S5 | ACL row deleted mid-session | Remove ACL row, retry request | `WORKSPACE_FORBIDDEN` (real-time) |
| S6 | SQL injection in workspace_id | ws=`'; DROP TABLE...` | PostgREST parameterizes (safe) |

### Backward Compatibility Tests

| # | Test | Expected |
|---|------|----------|
| B1 | Existing Chrome Extension payloads (no changes) | All still work |
| B2 | Existing Telegram bot (default workspace) | All still work |
| B3 | CC Gateway query script | All still work |
| B4 | Existing artifacts unchanged | No data migration, zero artifact loss |

---

## Rollback Plan

### Rollback Scope

| Component | Rollback Action | Reversibility |
|-----------|----------------|---------------|
| Gateway workflow | Reimport `NQxb_Gateway_v1 (43).json` (archived) | Full revert, instant |
| ACL table | `DROP TABLE public.qxb_gateway_acl;` (or leave in place — harmless) | Full revert |
| Workspace name change | `UPDATE qxb_workspace SET name = '(original)' WHERE workspace_id = 'b4e7f648...'` | Reversible |
| New workspace | `DELETE FROM qxb_workspace WHERE workspace_id = '<work_id>'` (if no artifacts) | Reversible if empty |
| Workspace_user rows | `DELETE FROM qxb_workspace_user WHERE workspace_id IN (...)` | Reversible |

### Rollback Procedure

1. Import `workflows/Archive/NQxb_Gateway_v1 (43).json` to n8n
2. Activate old Gateway (deactivate v44)
3. Verify default workspace access works
4. (Optional) Drop ACL table or leave it

**Data safety:** No existing artifacts are modified. Rollback does not require restoring data.

---

## QPM Intersection Points

This design is **independent of and parallel to** Phase 2 QPM Implementation (T1).

| Concern | Intersection | Action |
|---------|-------------|--------|
| Lifecycle progression (seed → sapling → tree) | Operates within a forest, not across | None — QPM is forest-local |
| Promote validation (child counts, anatomy) | Queries use workspace_id already | None — already scoped |
| Cross-forest artifact movement | NOT a QPM operation | Out of scope for both designs |
| QPM guard rules | Same rules apply per forest | None — rules are universal |

**Key principle:** Forestry governs *where*; QPM governs *how*. They are orthogonal.

If cross-forest artifact movement is needed later, it would be a new Gateway action (`artifact.move` or `artifact.clone`) — not a QPM or Forestry concern.

---

## Explicit Non-Goals

1. **Cross-forest operations** — No artifact.move, artifact.clone, or cross-forest queries
2. **Per-action permissions** — All authorized principals get full R/W within their forest(s)
3. **Automatic execution** — No auto-promotion, auto-save, or background cross-forest sync
4. **Non-1:1 forest-workspace mapping** — Explicitly locked out per Terminology Lock
5. **forest.list Gateway action** — Phase 2 only; SQL-only discovery for Phase 1
6. **Tenant isolation changes** — RLS already enforces workspace scoping at DB layer
7. **UI/frontend changes** — Chrome Extension, Telegram, and CC continue using gw_workspace_id
8. **Multiple RLS service roles** — Single service role continues to bypass RLS; ACL is the enforcement layer
9. **World-as-schema** — The Qwrk_World sovereignty boundary (`25e02429`) exists as a conceptual invariant above the forest level. This design operates at the forest/workspace level and is compatible with World governance. The ACL model's "no access unless explicitly granted" default satisfies the World anti-footgun rule ("silence always means private"). World-as-schema is explicitly deferred — no `qxb_world` table in this design.

---

## Phase 2: Optional Enhancements

These are not required for multi-forest to work but may be valuable later:

| Enhancement | Description | Trigger |
|-------------|-------------|---------|
| `forest.list` action | Returns authorized workspaces for calling principal | When Heads need self-service discovery |
| ACL audit log | Event table tracking ACL grants/revokes | When compliance or multi-admin needed |
| Per-action permissions | Add `allowed_actions` column to ACL table | If Heads need restricted action sets |
| `qxb_workspace` metadata | Add `forest_type`, `description`, `status` columns | If workspace metadata is needed for UX |
| Cross-forest move | `artifact.move` action with audit trail | If Joel needs to move artifacts between forests |
| ACL caching | Cache ACL lookups in n8n (reduce DB calls per request) | If latency becomes a concern |

---

## DDL Discrepancy Note

The Schema Reference v1.1 shows `qxb_workspace.owner_user_id` but the LIVE DDL (`LIVE_DDL__Kernel_v1__2026-01-04.sql`) does not include this column. Per DDL-as-Truth governance, this design uses the DDL schema (no `owner_user_id`). Workspace ownership is determined by `qxb_workspace_user` role='owner'.

If `owner_user_id` was added via a migration after the DDL export, the DDL file should be refreshed.

---

## CHANGELOG

### v1.0 - 2026-02-08
**What changed:** Initial design document

**Why:** Evolve Gateway from MVP single-workspace lock to multi-forest model per Forestry Governance v2 (`3f854e00`)

**Scope of impact:**
- New table: `qxb_gateway_acl`
- Gateway workflow: 3 node changes (1 new, 2 modified)
- 3 forests: Qwrk Personal, BlaggLife, Work (Resolve)
- Backward compatible — existing clients unchanged

**How to validate:** Execute test plan (unit, integration, security, backward compatibility)
