# RUNBOOK — Multi-User Qwrk (Prime) via Cloned Gateways — v1

**Created:** 2026-02-17
**Author:** CC (Claude Code) — Planning Phase Only
**Mode:** 3M Build — Non-Mutating Planning Pass
**Source Baseline:** `workflows/NQxb_Gateway_v1 (57).json` (Gateway v59 era, T69 compliant)
**Status:** Work_Joel deployed (v2, 2026-03-04). Other clones pending.

---

## Clarifying Defaults (Assumptions)

These defaults are assumed unless Joel overrides during execution:

| # | Question | Default |
|---|----------|---------|
| 1 | Include Team_Qwrk shared workspace? | **No** — not in this batch |
| 2 | Each clone gets its own Basic Auth principal? | **Yes** — one principal per gateway clone |
| 3 | BlaggLife — add Daisy as user? | **No** — Joel-only for MVP |

---

## Target Gateway Registry

| # | Gateway Name | Email | Workspace Status | Notes |
|---|-------------|-------|------------------|-------|
| 1 | Qwrk@Work_Joel | espressivedemojoel@gmail.com | **Verify existing** — may reuse Work (Resolve) `635bb8d7-...` or create new | Work-related activities |
| 2 | Akara_Blagg | akarablagg@gmail.com | **Create new** | Personal + Team Qwrk use |
| 3 | BlaggLife | j_blagg@hotmail.com | **Reuse existing** — `b4e7f648-96d5-44a7-80b9-c39cac4efbd1` | Family life (Joel + Daisy) |
| 4 | Krista_Blagg | kristablagg@gmail.com | **Create new** | Personal use |

---

## Architecture Summary

```
[ChatGPT Project per user]
        │
        ▼ (webhook URL + Basic Auth)
[Cloned Gateway per workspace]
  ├── Webhook (unique path)
  ├── ACL_Lookup (principal → workspace)
  ├── ACL_Guard (fail-closed)
  ├── Gatekeeper (OWNER_WORKSPACE_ID lock)
  └── Action Switch → Shared Sub-Workflows
                        ├── Save v42 (T69 + Contract B)
                        ├── Query v21 (T70 VIEW-based)
                        ├── List v29
                        ├── Update T69 (v38)
                        └── Promote v23
```

**Key design:** Each clone has its own webhook + Gatekeeper workspace lock + ACL principal. All clones share the same 5 sub-workflows.

---

## Phase 0 — Baseline Verification

### 0.1 Confirm Golden JSON

- [ ] File exists: `workflows/NQxb_Gateway_v1 (57).json`
- [ ] Workflow name in JSON: `NQxb_Gateway_v1 (57)`
- [ ] Webhook path: `/nqxb/gateway/v1/acl-test`
- [ ] ACL wiring present: `ACL_Lookup` → `ACL_Guard__HasRow` → `ACL_Guard__Route`
- [ ] ACL fail-closed snapshot verified: `ee8d3c9f`

### 0.2 Confirm Sub-Workflow IDs (v56)

| Action | Workflow ID (in ACL_Test JSON) | Cached Name | Status |
|--------|-------------------------------|-------------|--------|
| Query | `27efKlNfdyu89YGD` | NQxb_Artifact_Query_v1 | [ ] Verify active in n8n |
| Save | `cEmJcbfQE2C92MNV` | NQxb_Artifact_Save_v1 | [ ] Verify active in n8n |
| List | `RKDyfV4mdHCBDkmK` | NQxb_Artifact_List_v1 | [ ] Verify active in n8n |
| Promote | `DhcvKMsThjxbBReT` | NQxb_Artifact_Promote_v1 | [ ] Verify active in n8n |
| Update | `0FwKlCRJ1wV5qDhV` | NQxb_Artifact_Update_v1__T69 | [ ] Verify active in n8n |

### 0.3 Update workflow-ids.md

- [ ] Update `workflow-ids.md` from v55 IDs to v56 IDs (using table above)
- [ ] Move old v55 IDs to Deprecated section

### Phase 0 Verification Checklist

- [ ] All 5 sub-workflows confirmed active in n8n
- [ ] Golden JSON file readable and intact
- [ ] workflow-ids.md updated to v56

---

## Phase 1 — Supabase Preparation

### 1.1 Create Auth Users

For each target email, create a Supabase auth user. Use the Supabase Dashboard (Authentication → Users → Add User) or the Admin API.

| # | Email | Method | auth_user_id (capture) |
|---|-------|--------|----------------------|
| 1 | espressivedemojoel@gmail.com | Dashboard → Add User (set password) | `{{auth_user_id_work}}` |
| 2 | akarablagg@gmail.com | Dashboard → Add User (send invite) | `{{auth_user_id_akara}}` |
| 3 | j_blagg@hotmail.com | Dashboard → Add User (send invite) | `{{auth_user_id_blagglife}}` |
| 4 | kristablagg@gmail.com | Dashboard → Add User (send invite) | `{{auth_user_id_krista}}` |

**Note:** Joel (espressivedemojoel) gets password-set directly. Others receive email invites and must confirm before proceeding.

**Decision point:** If Joel already has a Supabase auth user for `espressivedemojoel@gmail.com`, capture the existing UUID instead of creating a new one.

### 1.2 Create qxb_user Rows

Use SQL template: `Multi-User Qwrk/01_Supabase/SUPABASE_USER_CREATION_TEMPLATE.sql`

```sql
-- Run AFTER auth users are confirmed
-- Replace {{placeholders}} with actual UUIDs from Step 1.1

INSERT INTO qxb_user (auth_user_id, display_name, email)
VALUES
  ('{{auth_user_id_work}}', 'Joel (Work)', 'espressivedemojoel@gmail.com'),
  ('{{auth_user_id_akara}}', 'Akara Blagg', 'akarablagg@gmail.com'),
  ('{{auth_user_id_blagglife}}', 'Joel (BlaggLife)', 'j_blagg@hotmail.com'),
  ('{{auth_user_id_krista}}', 'Krista Blagg', 'kristablagg@gmail.com')
RETURNING user_id, auth_user_id, display_name, email;
```

**Capture the returned `user_id` values into the tracking table (Step 1.5).**

### 1.3 Verify / Create Workspaces

| # | Workspace | Existing? | Action |
|---|-----------|-----------|--------|
| 1 | Qwrk@Work (Joel) | **Maybe** — Work (Resolve) `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | **DECISION:** Reuse existing OR create new? |
| 2 | Akara_Blagg | **No** | Create new |
| 3 | BlaggLife | **Yes** — `b4e7f648-96d5-44a7-80b9-c39cac4efbd1` | Reuse existing |
| 4 | Krista_Blagg | **No** | Create new |

```sql
-- Only for NEW workspaces (skip existing)
INSERT INTO qxb_workspace (name)
VALUES
  -- ('Qwrk@Work'),  -- ONLY if not reusing Work (Resolve)
  ('Akara_Blagg'),
  ('Krista_Blagg')
RETURNING workspace_id, name;
```

**Capture the returned `workspace_id` values.**

### 1.4 Create workspace_user Memberships

```sql
-- Each user → their workspace with role 'owner'
INSERT INTO qxb_workspace_user (workspace_id, user_id, role)
VALUES
  ('{{workspace_uuid_work}}', '{{user_id_work}}', 'owner'),
  ('{{workspace_uuid_akara}}', '{{user_id_akara}}', 'owner'),
  ('{{workspace_uuid_blagglife}}', '{{user_id_blagglife}}', 'owner'),
  ('{{workspace_uuid_krista}}', '{{user_id_krista}}', 'owner')
RETURNING workspace_user_id, workspace_id, user_id, role;
```

**Note for BlaggLife:** If Joel's existing qxb_user (`c52c7a57-...`) already has a `workspace_user` row for BlaggLife, skip that row. Only add if the new `j_blagg@hotmail.com` user needs separate membership.

### 1.5 Seed ACL Rows

One row per principal × workspace in `qxb_gateway_acl`:

```sql
INSERT INTO qxb_gateway_acl (principal_name, workspace_id)
VALUES
  ('qwrk-gw-work', '{{workspace_uuid_work}}'),
  ('qwrk-gw-akara', '{{workspace_uuid_akara}}'),
  ('qwrk-gw-blagglife', '{{workspace_uuid_blagglife}}'),
  ('qwrk-gw-krista', '{{workspace_uuid_krista}}')
RETURNING acl_id, principal_name, workspace_id, role;
```

**Principal naming convention:** `qwrk-gw-<short_name>`

### 1.6 Master Tracking Table

Record all captured values in `Multi-User Qwrk/01_Supabase/WORKSPACE_REGISTRY_TRACKING.md`:

| Gateway | Email | auth_user_id | user_id | workspace_id | workspace_name | principal_name | webhook_path |
|---------|-------|-------------|---------|-------------|----------------|----------------|-------------|
| Qwrk@Work_Joel | espressivedemojoel@gmail.com | `{{TBD}}` | `{{TBD}}` | `{{TBD}}` | Qwrk@Work | qwrk-gw-work | /nqxb/gateway/v1/work |
| Akara_Blagg | akarablagg@gmail.com | `{{TBD}}` | `{{TBD}}` | `{{TBD}}` | Akara_Blagg | qwrk-gw-akara | /nqxb/gateway/v1/akara |
| BlaggLife | j_blagg@hotmail.com | `{{TBD}}` | `{{TBD}}` | `b4e7f648-...` | BlaggLife | qwrk-gw-blagglife | /nqxb/gateway/v1/blagglife |
| Krista_Blagg | kristablagg@gmail.com | `{{TBD}}` | `{{TBD}}` | `{{TBD}}` | Krista_Blagg | qwrk-gw-krista | /nqxb/gateway/v1/krista |

### Phase 1 Verification Checklist

- [ ] All 4 auth users exist in Supabase Auth (email confirmed)
- [ ] All 4 `qxb_user` rows created with correct `auth_user_id` mapping
- [ ] All workspaces exist (2 new + 1 reused + 1 decision resolved)
- [ ] All 4 `workspace_user` rows created with role `owner`
- [ ] All 4 ACL rows seeded with correct principal × workspace
- [ ] Tracking table fully populated with captured UUIDs

---

## Phase 2 — n8n Clone Procedure (Manual)

### 2.1 Pre-Clone Setup: Create Basic Auth Credentials

In n8n, create 4 new Basic Auth credentials:

| Credential Name | Username (principal) | Password |
|----------------|---------------------|----------|
| Qwrk Gateway — Work (Joel) | `qwrk-gw-work` | `{{generate secure password}}` |
| Qwrk Gateway — Akara | `qwrk-gw-akara` | `{{generate secure password}}` |
| Qwrk Gateway — BlaggLife | `qwrk-gw-blagglife` | `{{generate secure password}}` |
| Qwrk Gateway — Krista | `qwrk-gw-krista` | `{{generate secure password}}` |

**Store credential IDs after creation** — needed for JSON import.

**Password generation:** Use `openssl rand -base64 24` or equivalent. Record securely.

### 2.2 Clone Procedure (Repeat for Each Gateway)

For each of the 4 gateways, follow the checklist in `Multi-User Qwrk/02_n8n_Workflows/CLONE_GATEWAY_CHECKLIST.md`.

**Summary per clone:**

1. **Copy** `NQxb_Gateway_v1 (57).json` to working file
2. **Rename** workflow: `NQxb_Gateway_v1__<GatewayName>`
3. **Update Webhook path:** `/nqxb/gateway/v1/<short_name>`
4. **Update Webhook credential:** Bind to clone's Basic Auth credential
5. **Update Gatekeeper OWNER_WORKSPACE_ID:** Replace `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` with clone's workspace UUID
6. **Update ACL_Lookup URL:** Replace `principal_name=eq.qwrk-gateway` with `principal_name=eq.<clone_principal>`
7. **Import** to n8n
8. **Activate** workflow
9. **Capture** webhook URL from n8n

### 2.3 Specific Changes Per Node

#### Node: `NQxb_Gateway_v1__Webhook_In`
- **Change:** `path` field → `/nqxb/gateway/v1/{{short_name}}`
- **Change:** `credentials.httpBasicAuth` → clone's credential ID and name

#### Node: `NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly`
- **Change:** Line in jsCode: `const OWNER_WORKSPACE_ID = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a";`
- **Replace with:** `const OWNER_WORKSPACE_ID = "{{workspace_uuid}}";`

#### Node: `NQxb_Gateway_v1__ACL_Lookup`
- **Change:** URL contains `principal_name=eq.qwrk-gateway`
- **Replace with:** `principal_name=eq.{{principal_name}}`
- **Keep:** `supabaseApi` credential unchanged (`n4R4JdOIV9zrCGIT` — shared service_role)

#### All Other Nodes
- **No changes required.** Sub-workflow IDs, action routing, response shaping all remain identical.

### 2.4 Naming Convention

| Gateway | Workflow Name | Webhook Path | Short Name |
|---------|-------------|-------------|------------|
| Qwrk@Work_Joel | `NQxb_Gateway_v1__Work_Joel` | `/nqxb/gateway/v1/work` | `work` |
| Akara_Blagg | `NQxb_Gateway_v1__Akara` | `/nqxb/gateway/v1/akara` | `akara` |
| BlaggLife | `NQxb_Gateway_v1__BlaggLife` | `/nqxb/gateway/v1/blagglife` | `blagglife` |
| Krista_Blagg | `NQxb_Gateway_v1__Krista` | `/nqxb/gateway/v1/krista` | `krista` |

### 2.5 Sub-Workflow Activation Check

All 5 shared sub-workflows must be active before clones can execute:

| Sub-Workflow | ID | Required State |
|-------------|-----|---------------|
| NQxb_Artifact_Query_v1 | `27efKlNfdyu89YGD` | [ ] Active |
| NQxb_Artifact_Save_v1 | `cEmJcbfQE2C92MNV` | [ ] Active |
| NQxb_Artifact_List_v1 | `RKDyfV4mdHCBDkmK` | [ ] Active |
| NQxb_Artifact_Promote_v1 | `DhcvKMsThjxbBReT` | [ ] Active |
| NQxb_Artifact_Update_v1__T69 | `0FwKlCRJ1wV5qDhV` | [ ] Active |

### Phase 2 Verification Checklist

- [ ] 4 Basic Auth credentials created in n8n (IDs recorded)
- [ ] 4 workflow JSON files prepared with correct modifications
- [ ] All 4 workflows imported and activated in n8n
- [ ] All 4 webhook URLs captured and recorded in tracking table
- [ ] Sub-workflows confirmed active (5/5)
- [ ] No production gateway (`NQxb_Gateway_v1`) modified

---

## Phase 3 — ChatGPT Project Setup

### 3.1 Create ChatGPT Projects

For each user, create a ChatGPT Project in ChatGPT (Settings → Projects → New Project):

| # | Project Name | User |
|---|-------------|------|
| 1 | Qwrk@Work | Joel (espressivedemojoel@gmail.com) |
| 2 | Qwrk (Akara) | Akara (akarablagg@gmail.com) |
| 3 | Qwrk (BlaggLife) | Joel (j_blagg@hotmail.com) |
| 4 | Qwrk (Krista) | Krista (kristablagg@gmail.com) |

### 3.2 System Instructions

Use template: `Multi-User Qwrk/03_ChatGPT_Projects/SYSTEM_INSTRUCTIONS_TEMPLATE.md`

Each project's system instructions must enforce:

1. **Webhook URL** — hardcoded, no user override
2. **Workspace UUID** — hardcoded, no user override
3. **Payload format** — JSON in markdown code block
4. **Stop-after-command** — Q outputs one command at a time, waits for user confirmation
5. **No cross-workspace operations** — workspace_id is always the user's assigned workspace

### 3.3 Instruction Packs

Use template: `Multi-User Qwrk/04_Instruction_Packs/INSTRUCTION_PACK_TEMPLATE.md`

Each user gets an instruction pack containing:
- Gateway action reference (save, query, list, update, promote)
- Allowed artifact types
- Payload examples
- Error code reference

### 3.4 Per-User Configuration Table

| User | Webhook URL | Workspace UUID | Principal |
|------|------------|---------------|-----------|
| Joel (Work) | `https://<n8n-host>/webhook/nqxb/gateway/v1/work` | `{{workspace_uuid_work}}` | qwrk-gw-work |
| Akara | `https://<n8n-host>/webhook/nqxb/gateway/v1/akara` | `{{workspace_uuid_akara}}` | qwrk-gw-akara |
| BlaggLife | `https://<n8n-host>/webhook/nqxb/gateway/v1/blagglife` | `b4e7f648-96d5-44a7-80b9-c39cac4efbd1` | qwrk-gw-blagglife |
| Krista | `https://<n8n-host>/webhook/nqxb/gateway/v1/krista` | `{{workspace_uuid_krista}}` | qwrk-gw-krista |

### Phase 3 Verification Checklist

- [ ] 4 ChatGPT Projects created
- [ ] System instructions pasted into each project (with real values from tracking table)
- [ ] Instruction packs uploaded to each project
- [ ] Each project's Q can generate a valid `artifact.list` payload (smoke test)

---

## Phase 4 — Deterministic Testing

### 4.1 Test Script

Use template: `Multi-User Qwrk/05_Testing/POWERSHELL_TEST_TEMPLATE.ps1`

For each gateway clone, run 3 tests:

#### Test 1: Allowed Workspace (Expect 200)

```powershell
# Send artifact.list to the clone's webhook with the clone's correct workspace_id
# Expected: HTTP 200, valid JSON response with ok: true
```

#### Test 2: Wrong Workspace (Expect 403)

```powershell
# Send artifact.list to the clone's webhook with a DIFFERENT workspace_id
# Expected: HTTP 403, ACL_FORBIDDEN or WORKSPACE_FORBIDDEN
```

#### Test 3: Malformed Request (Expect Error)

```powershell
# Send request with missing gw_action
# Expected: VALIDATION_ERROR response
```

### 4.2 Test Execution Matrix

| Gateway | Test 1 (200) | Test 2 (403) | Test 3 (Error) | All Pass? |
|---------|-------------|-------------|---------------|-----------|
| Qwrk@Work_Joel | [ ] | [ ] | [ ] | [ ] |
| Akara_Blagg | [ ] | [ ] | [ ] | [ ] |
| BlaggLife | [ ] | [ ] | [ ] | [ ] |
| Krista_Blagg | [ ] | [ ] | [ ] | [ ] |

### 4.3 End-to-End Validation

After all 4 gateways pass isolated tests, perform one full-cycle test per gateway:

1. **Save** a test snapshot artifact
2. **List** snapshot artifacts (confirm test artifact appears)
3. **Query** the test artifact by ID (confirm content matches)

### Phase 4 Verification Checklist

- [ ] All 4 gateways pass Test 1 (allowed workspace → 200)
- [ ] All 4 gateways pass Test 2 (wrong workspace → 403)
- [ ] All 4 gateways pass Test 3 (malformed request → error)
- [ ] At least 1 gateway completes full save/list/query cycle
- [ ] No regressions on production gateway

---

## Phase 5 — Governance Rules

### 5.1 Builder Authority

- **Joel is the sole builder.** Only Joel may:
  - Modify workflow JSON
  - Create/delete workspaces
  - Manage ACL rows
  - Update system instructions
  - Manage n8n credentials

### 5.2 Delegated Users (Execution-Only)

Akara, Krista, and Daisy (future) are execution-only:
- Can use their ChatGPT Project to generate and execute Qwrk commands
- Cannot access n8n, Supabase Dashboard, or workflow internals
- Cannot modify their own system instructions or ACL permissions

### 5.3 Clone Version Propagation Policy

When the production Gateway or sub-workflows are updated:

1. **Sub-workflow updates** propagate automatically (all clones share the same sub-workflow IDs)
2. **Gateway-level changes** (Gatekeeper logic, normalizer, new actions) must be manually propagated to each clone:
   - Update golden template first
   - Re-clone to all 4 gateways
   - Follow Phase 2 procedure for each
3. **Version registry** tracks which clone is at which version: `Multi-User Qwrk/05_Testing/WORKFLOW_VERSION_REGISTRY.md`

### 5.4 Journal Extension Invariant

Journal artifacts are append-only and must use `extension.entry_text` exclusively.

- `entry_text` must be a non-empty string
- No other extension keys are permitted (`entry`, `body`, `content`, `payload` are all rejected)
- Gateway enforces this with error code `JOURNAL_EXTENSION_INVALID`

This is a cross-clone invariant and must not be altered in any clone.

### 5.5 Credential Rotation Policy

- Rotate passwords quarterly (minimum)
- Update n8n credential → update ChatGPT Project system instructions
- Never share credentials across gateways
- Record rotation dates in version registry

### 5.6 Team_Qwrk (Future)

Team_Qwrk shared workspace is not included in this batch. When added:
- Requires its own gateway clone
- Multiple users would have `workspace_user` rows for the shared workspace
- ACL row maps Team_Qwrk principal to shared workspace
- Each user's ChatGPT Project would need a "switch workspace" instruction or separate project

### Phase 5 Verification Checklist

- [ ] Governance rules documented and acknowledged by Joel
- [ ] Version registry initialized with all 4 clones at v1
- [ ] Credential storage plan confirmed (password manager, etc.)

---

## Appendix A — Directory Structure

```
Multi-User Qwrk/
├── 00_Runbook/
│   └── (this runbook is in Qwrk_Inbox, linked here)
├── 01_Supabase/
│   ├── SUPABASE_USER_CREATION_TEMPLATE.sql
│   └── WORKSPACE_REGISTRY_TRACKING.md
├── 02_n8n_Workflows/
│   └── CLONE_GATEWAY_CHECKLIST.md
├── 03_ChatGPT_Projects/
│   └── SYSTEM_INSTRUCTIONS_TEMPLATE.md
├── 04_Instruction_Packs/
│   └── INSTRUCTION_PACK_TEMPLATE.md
├── 05_Testing/
│   ├── POWERSHELL_TEST_TEMPLATE.ps1
│   ├── TEST_CHECKLIST.md
│   └── WORKFLOW_VERSION_REGISTRY.md
└── Archive/
```

## Appendix B — Critical Node Locations in ACL_Test JSON

| Node Name | What Changes Per Clone | JSON Location |
|-----------|----------------------|---------------|
| `NQxb_Gateway_v1__Webhook_In` | `path`, `credentials.httpBasicAuth` | nodes[0] |
| `NQxb_Gateway_v1__Normalize_Request` | Nothing | nodes[1] |
| `NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly` | `OWNER_WORKSPACE_ID` in jsCode | nodes[2] |
| `NQxb_Gateway_v1__ACL_Lookup` | `principal_name=eq.` in URL | Last HTTP Request node |
| All Execute Workflow nodes | Nothing (shared sub-workflows) | — |
| All other nodes | Nothing | — |

## Appendix C — Rollback

If any clone causes issues:

1. **Deactivate** the clone workflow in n8n (does not affect other clones or production)
2. **Delete** the ACL row for that principal (prevents access)
3. **Disable** the Supabase auth user (Dashboard → Users → Disable)
4. No shared infrastructure is affected — clones are fully isolated

---

## CHANGELOG

### v2 — 2026-03-04
- Updated golden template from ACL_Test to Gateway v59 era export
- Updated all sub-workflow IDs and versions (Save v42, Query v21, Update T69, Promote v23)
- Added T69 compliance requirement (semantic_type_id forwarding)
- Previous version: `Archive/RUNBOOK__Multi_User_Cloned_Gateways__v1__2026-03-04.md`

### v1 — 2026-02-17
- Initial planning runbook (non-mutating)
- 5 phases with verification checklists
- 8 template files specified
- Architecture: one gateway clone per workspace, shared sub-workflows
