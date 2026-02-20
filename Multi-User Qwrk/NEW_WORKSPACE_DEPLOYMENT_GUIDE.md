# New Workspace Deployment Guide — Qwrk Prime

**Purpose:** Repeatable step-by-step process to add a new workspace (user) to Qwrk Prime. Follow this guide every time a new workspace is onboarded.

**Estimated time:** 30-45 minutes (manual steps)

**Prerequisites:**
- Supabase Dashboard access (project `npymhacpmxdnkqdzgxll`)
- n8n admin access (`https://n8n.halosparkai.com`)
- Golden template: `workflows/NQxb_Gateway_v1__ACL_Test.json`
- Chrome Extension source: `qwrk-chrome-mvp/`
- Telegram BotFather access (optional — for Telegram surface)

---

## Naming Conventions

Before starting, define these values for the new workspace:

| Field | Convention | Example |
|-------|-----------|---------|
| `short_name` | Lowercase, no spaces, URL-safe | `work`, `akara`, `blagglife` |
| `principal_name` | `qwrk-gw-<short_name>` | `qwrk-gw-work` |
| `webhook_path` | `/nqxb/gateway/v1/<short_name>` | `/nqxb/gateway/v1/work` |
| `workflow_name` | `NQxb_Gateway_v1__<DisplayName>` | `NQxb_Gateway_v1__Work_Joel` |
| `workspace_name` | Human-readable | `Qwrk@Work` |
| `profile_id` | `qwrk-<short_name>` | `qwrk-work` |

---

## Step 1 — Supabase: Identity & Workspace

### 1.1 Create Auth User

**Where:** Supabase Dashboard > Authentication > Users > Add User

| Field | Value |
|-------|-------|
| Email | `<user_email>` |
| Method | Send invite (external users) or Set password (Joel accounts) |

**Capture:** `auth_user_id` (UUID shown in Users table after creation)

> **If user already exists in Supabase Auth:** Skip creation, capture existing `auth_user_id`.

### 1.2 Create qxb_user Row

**Where:** Supabase SQL Editor

```sql
INSERT INTO qxb_user (auth_user_id, display_name, email)
VALUES (
  '<auth_user_id>',
  '<Display Name>',
  '<user_email>'
)
RETURNING user_id, auth_user_id, display_name, email;
```

**Capture:** `user_id` (UUID returned)

### 1.3 Create or Reuse Workspace

**If new workspace:**

```sql
INSERT INTO qxb_workspace (name)
VALUES ('<workspace_name>')
RETURNING workspace_id, name;
```

**Capture:** `workspace_id`

**If reusing existing workspace:** Look up `workspace_id` in the Workspace Registry Tracking file or query:

```sql
SELECT workspace_id, name FROM qxb_workspace WHERE name ILIKE '%<partial_name>%';
```

### 1.4 Create workspace_user Membership

```sql
INSERT INTO qxb_workspace_user (workspace_id, user_id, role)
VALUES (
  '<workspace_id>',
  '<user_id>',
  'owner'
)
RETURNING workspace_user_id, workspace_id, user_id, role;
```

> **Role:** Always `owner` for the workspace's primary user.

### 1.5 Seed ACL Row

```sql
INSERT INTO qxb_gateway_acl (principal_name, workspace_id, role)
VALUES (
  '<principal_name>',
  '<workspace_id>',
  'owner'
)
RETURNING acl_id, principal_name, workspace_id, role;
```

### Step 1 Checkpoint

| Item | Value | Captured? |
|------|-------|-----------|
| auth_user_id | `________________` | [ ] |
| user_id | `________________` | [ ] |
| workspace_id | `________________` | [ ] |
| workspace_user_id | `________________` | [ ] |
| acl_id | `________________` | [ ] |

---

## Step 2 — n8n: Clone Gateway Workflow

### 2.1 Create Basic Auth Credential

**Where:** n8n > Credentials > New > HTTP Basic Auth

| Field | Value |
|-------|-------|
| Name | `Qwrk Gateway — <DisplayName>` |
| Username | `<principal_name>` |
| Password | Generate with `openssl rand -base64 24` |

**Capture:** Credential ID (shown in n8n URL after save), password (store securely)

**Generate base64 for Chrome Extension:**

```javascript
// In browser console:
btoa("<principal_name>:<password>")
```

**Capture:** base64 credential string

### 2.2 Prepare Clone JSON

1. Copy `workflows/NQxb_Gateway_v1__ACL_Test.json` to a working file
2. Make exactly 4 edits:

#### Edit 1: Webhook Node — Path

Find node `NQxb_Gateway_v1__Webhook_In`:
```json
"path": "/nqxb/gateway/v1/acl-test"
```
Change to:
```json
"path": "/nqxb/gateway/v1/<short_name>"
```

#### Edit 2: Webhook Node — Credential

In the same webhook node, find `credentials.httpBasicAuth`:
```json
"httpBasicAuth": {
  "id": "<old_credential_id>",
  "name": "<old_name>"
}
```
Replace with:
```json
"httpBasicAuth": {
  "id": "<new_credential_id>",
  "name": "Qwrk Gateway — <DisplayName>"
}
```

#### Edit 3: Gatekeeper Node — OWNER_WORKSPACE_ID

Find node `NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly`, locate in `jsCode`:
```javascript
const OWNER_WORKSPACE_ID = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a";
```
Replace with:
```javascript
const OWNER_WORKSPACE_ID = "<workspace_id>";
```

> **NOTE:** This constant-based gatekeeper model assumes one workspace per gateway clone (Option A isolation model).
> In future production consolidation (Option B), workspace routing will replace this constant.
> Do not treat this pattern as permanent architecture.

#### Edit 4: ACL_Lookup Node — Principal Name

Find node `NQxb_Gateway_v1__ACL_Lookup`, locate in URL:
```
principal_name=eq.qwrk-gateway
```
Replace with:
```
principal_name=eq.<principal_name>
```

> **Do NOT change:** Sub-workflow IDs, Supabase credentials, action routing, response shaping. These are shared across all clones.

### **Sub-Workflow Immutability Guard**

> **Sub-workflows are shared infrastructure.**
> They must NEVER be cloned, edited, or modified per workspace.
> All workspace isolation occurs exclusively through:
> - Webhook path
> - HTTP Basic Auth credential
> - OWNER_WORKSPACE_ID constant
> - ACL principal_name
>
> Modifying shared sub-workflows breaks isolation and affects ALL workspaces.

### 2.3 Import and Activate

1. **Import** the modified JSON to n8n (Workflows > Import from File)
2. **Rename** workflow to `NQxb_Gateway_v1__<DisplayName>` if not already set in JSON
3. **Activate** the workflow
4. **Verify** webhook URL is live: `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/<short_name>`

### 2.4 Verify Sub-Workflows Active

All 5 shared sub-workflows must be active (they already should be — just confirm):

| Sub-Workflow | ID |
|-------------|-----|
| NQxb_Artifact_Save_v1 | `mlUCDPRRdWp286ja` |
| NQxb_Artifact_Query_v1 | `LGYSXI586inagTPk` |
| NQxb_Artifact_List_v1 | `RKDyfV4mdHCBDkmK` |
| NQxb_Artifact_Update_v1 | `1L2HKncP2Dh0K3DI` |
| NQxb_Artifact_Promote_v1 | `SaKD4o4FKrXfSYt6` |

### Step 2 Checkpoint

| Item | Value | Captured? |
|------|-------|-----------|
| n8n Credential ID | `________________` | [ ] |
| Password | `________________` | [ ] |
| base64 credential | `________________` | [ ] |
| Webhook URL | `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/<short_name>` | [ ] |
| Workflow activated | | [ ] |

---

## Step 3 — Chrome Extension: Add Profile

### 3.1 Edit WORKSPACE_PROFILES

**Where:** `qwrk-chrome-mvp/popup.js`

Add a new entry to the `WORKSPACE_PROFILES` array:

```javascript
{
  id: "qwrk-<short_name>",
  label: "<Display Name>",
  endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/<short_name>",
  credential: "<base64_credential_from_step_2.1>"
}
```

### 3.2 Reload Extension

1. Go to `chrome://extensions/`
2. Find "Qwrk Command Console"
3. Click the reload button
4. Open popup — verify new workspace appears in dropdown

### Step 3 Checkpoint

- [ ] New profile appears in dropdown
- [ ] Selection persists across popup close/open

---

## Step 4 — Telegram Bot (Optional)

Skip this step if the workspace does not need a Telegram surface.

### 4.1 Create Bot via BotFather

1. Open Telegram, message `@BotFather`
2. Send `/newbot`
3. Name: `Qwrk <DisplayName>` (e.g., "Qwrk Work")
4. Username: `qwrk_<short_name>_<environment>_bot` (e.g., `qwrk_work_dev_bot`)

> **Telegram usernames are global.**
> Include environment suffix (e.g., `dev`, `beta`, `prod`) to prevent collisions and future namespace conflicts.

**Capture:** Bot token (format: `123456789:ABCdef...`)

### 4.2 Create n8n Telegram Credential

**Where:** n8n > Credentials > New > Telegram API

| Field | Value |
|-------|-------|
| Name | `Telegram — Qwrk <DisplayName>` |
| Access Token | `<bot_token_from_4.1>` |

**Capture:** Telegram credential ID

### 4.3 Clone Telegram Pipe Workflow

1. Export `NQxb_Telegram_Gateway_Pipe_v1` from n8n (or copy JSON from `workflows/`)
2. Make these edits:

#### Edit 1: Workflow Name
```
NQxb_Telegram_Gateway_Pipe_v1__<DisplayName>
```

#### Edit 2: Telegram Trigger Node — Credential

Find `credentials.telegramApi`:
```json
"telegramApi": {
  "id": "<new_telegram_credential_id>",
  "name": "Telegram — Qwrk <DisplayName>"
}
```

#### Edit 3: Telegram Trigger Node — Webhook ID

Find `webhookId`:
```json
"webhookId": "qwrk-telegram-gateway-pipe"
```
Change to:
```json
"webhookId": "qwrk-telegram-pipe-<short_name>"
```

#### Edit 4: POST to Gateway Node — URL

Find `url`:
```
https://n8n.halosparkai.com/webhook/nqxb/gateway/v1
```
Change to:
```
https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/<short_name>
```

#### Edit 5: POST to Gateway Node — Credential

Find `credentials.httpBasicAuth`:
```json
"httpBasicAuth": {
  "id": "<gateway_credential_id_from_step_2.1>",
  "name": "Qwrk Gateway — <DisplayName>"
}
```

#### Edit 6: Send Response Node — Credential

Find `credentials.telegramApi` in the Send Response node:
```json
"telegramApi": {
  "id": "<new_telegram_credential_id>",
  "name": "Telegram — Qwrk <DisplayName>"
}
```

#### Edit 7: Shape Error Node — Example workspace_id (optional)

The error message shows an example payload. Update the example `gw_workspace_id` to match this workspace:
```javascript
"gw_workspace_id": "<workspace_id>"
```

### 4.4 Import and Activate

1. Import modified JSON to n8n
2. Activate — n8n automatically registers the Telegram webhook
3. Send a test message to the bot in Telegram

### Telegram Node Summary

| Node | What Changes |
|------|-------------|
| Telegram Trigger | Credential (telegramApi), webhookId |
| Parse JSON | Nothing |
| Valid JSON? | Nothing |
| POST to Gateway | URL (endpoint), credential (httpBasicAuth) |
| Shape Response | Nothing |
| Shape Error | Example workspace_id (optional) |
| Send Response | Credential (telegramApi) |

### Step 4 Checkpoint

| Item | Value | Captured? |
|------|-------|-----------|
| Bot username | `@qwrk_<short_name>_<env>_bot` | [ ] |
| Bot token | `________________` | [ ] |
| Telegram credential ID | `________________` | [ ] |
| Pipe workflow activated | | [ ] |
| Test message sent and response received | | [ ] |

---

## Security & Secret Handling Protocol

- Bot tokens must be stored in approved password manager only.
- Gateway Basic Auth passwords must be stored in the same secure location.
- No tokens may be committed to any Git repository.
- No tokens may appear in markdown documentation files.
- No tokens may be hardcoded in Chrome Extension source files beyond the `WORKSPACE_PROFILES` base64 credential (which is required for runtime operation and must be treated as a secret).
- Base64 credentials are considered secrets and must be handled as such.

---

## Step 5 — ChatGPT Project (Optional)

Skip this step if the workspace user does not use ChatGPT as their primary surface.

### 5.1 Create Project

**Where:** ChatGPT > Settings > Projects > New Project

| Field | Value |
|-------|-------|
| Name | `Qwrk (<DisplayName>)` or custom |

### 5.2 System Instructions

Paste system instructions into the project. Must include:

| Required Field | Value |
|----------------|-------|
| Workspace UUID | `<workspace_id>` |
| Webhook URL | `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/<short_name>` |
| Domain boundary | Workspace lock (never operate on another workspace) |
| Execution surface rules | JSON in fenced code block, one payload per response, stop-and-wait |

**Template:** See `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/qwrk_work_system_instructions_v_1.md` as reference. Adapt identity, tone, and behavioral sections per user.

### 5.3 Instruction Packs (Optional)

Save instruction packs to the workspace via Chrome Extension. Recommended starter packs:

1. **Gateway Operations** — Action reference, payload templates, extension schemas
2. **Execution Patterns** — Lifecycle discipline, artifact type guidance
3. **Cognitive Protocol** — User-specific behavioral rules (ADHD support, drift guard, etc.)

**instruction_pack extension fields (required):**
```json
{
  "scope": "Description of what this pack covers",
  "active": true,
  "priority": 1,
  "pack_format": "v1",
  "payload": { ... }
}
```

> **These 4 fields must be top-level in `extension`**, not nested inside `extension.payload`. The Save sub-workflow validates them on INSERT.

### 5.4 Journal Schema Invariant

All journal artifacts across all workspaces must use:

```
extension.entry_text
```

Gateway enforces strict validation. Incorrect keys (e.g., `extension.entry`, `extension.body`, `extension.payload`) will be rejected with `JOURNAL_EXTENSION_INVALID`.

This invariant must not be modified per workspace.

### Step 5 Checkpoint

- [ ] ChatGPT project created
- [ ] System instructions pasted with correct workspace_id and webhook URL
- [ ] Q can generate a valid `artifact.list` payload (smoke test)
- [ ] Instruction packs saved (if applicable)
- [ ] Journal schema invariant included in system instructions

---

## Step 6 — Validation

### 6.1 Three-Test Suite

Run these 3 tests via Chrome Extension (select the new workspace profile) or PowerShell:

#### Test 1: Allowed Workspace (Expect 200 + ok: true)

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "<workspace_id>",
  "artifact_type": "snapshot",
  "selector": { "limit": 3 }
}
```

**Pass criteria:** `ok: true`, valid `data.artifacts` array

#### Test 2: Wrong Workspace (Expect WORKSPACE_FORBIDDEN)

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "selector": { "limit": 3 }
}
```

**Pass criteria:** Error response with `WORKSPACE_FORBIDDEN`

#### Test 3: Malformed Request (Expect VALIDATION_ERROR)

```json
{
  "gw_workspace_id": "<workspace_id>"
}
```

**Pass criteria:** Error response (missing `gw_action`)

### 6.2 Full Cycle Test

1. **Save** a smoke test snapshot:

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "<workspace_id>",
  "artifact_type": "snapshot",
  "title": "Smoke Test - <DisplayName> Workspace Deployment",
  "priority": 3,
  "tags": ["smoke-test", "deployment"],
  "extension": {
    "payload": {
      "test": true,
      "deployed_by": "Joel",
      "timestamp": "<current_datetime>"
    }
  }
}
```

2. **List** snapshots — confirm smoke test appears
3. **Query** the smoke test artifact by ID — confirm content matches

### 6.3 Cross-Surface Validation (if applicable)

- [ ] Chrome Extension sends and receives correctly
- [ ] Telegram bot sends and receives correctly (if Step 4 done)
- [ ] ChatGPT Q generates correct payloads (if Step 5 done)

### Step 6 Checkpoint

| Test | Result |
|------|--------|
| Test 1 (200) | [ ] Pass |
| Test 2 (403) | [ ] Pass |
| Test 3 (Error) | [ ] Pass |
| Full cycle (Save/List/Query) | [ ] Pass |
| Telegram (if applicable) | [ ] Pass |
| ChatGPT Q (if applicable) | [ ] Pass |

---

## Step 7 — Registry Update

After all tests pass, update the tracking file:

**File:** `Multi-User Qwrk/01_Supabase/WORKSPACE_REGISTRY_TRACKING.md`

Record all captured values:
- User Registry row (email, auth_user_id, user_id)
- Workspace Registry row (workspace_name, workspace_id)
- Gateway Configuration row (principal_name, webhook_path, credential_id, full URL)
- ACL Registry row (principal_name, workspace_id, acl_id)
- Test Results row (all 3 tests + full cycle + date)

---

## Quick Reference — All Edits Per Clone

### Gateway Workflow (4 edits)

| # | Node | Field | Change To |
|---|------|-------|-----------|
| 1 | Webhook_In | `path` | `/nqxb/gateway/v1/<short_name>` |
| 2 | Webhook_In | `credentials.httpBasicAuth` | Clone's credential ID + name |
| 3 | Gatekeeper | `OWNER_WORKSPACE_ID` | Clone's `workspace_id` |
| 4 | ACL_Lookup | `principal_name=eq.` | Clone's `principal_name` |

### Telegram Pipe (7 edits)

| # | Node | Field | Change To |
|---|------|-------|-----------|
| 1 | Telegram Trigger | `credentials.telegramApi` | New bot's credential |
| 2 | Telegram Trigger | `webhookId` | `qwrk-telegram-pipe-<short_name>` |
| 3 | POST to Gateway | `url` | Clone's gateway URL |
| 4 | POST to Gateway | `credentials.httpBasicAuth` | Clone's gateway credential |
| 5 | Send Response | `credentials.telegramApi` | New bot's credential |
| 6 | Shape Error | Example `gw_workspace_id` | Clone's workspace_id |
| 7 | Workflow | Name | `NQxb_Telegram_Gateway_Pipe_v1__<DisplayName>` |

### Chrome Extension (1 edit)

Add entry to `WORKSPACE_PROFILES` array in `popup.js` with `id`, `label`, `endpoint`, `credential`.

---

## Rollback

If a deployed workspace needs to be removed:

1. **Deactivate** the gateway clone workflow in n8n
2. **Deactivate** the Telegram pipe clone workflow (if exists)
3. **Delete** the ACL row: `DELETE FROM qxb_gateway_acl WHERE principal_name = '<principal_name>';`
4. **Remove** the Chrome Extension profile from `WORKSPACE_PROFILES` and reload
5. **Disable** the Supabase auth user (Dashboard > Users > Disable)

No shared infrastructure is affected — clones are fully isolated.

---

## Automation Threshold

This guide assumes manual provisioning for a small number of workspaces (6 or fewer).

If active workspace count exceeds 6:
- Manual cloning must be reevaluated.
- Consider scripted provisioning for Supabase, n8n cloning, and Chrome profile generation.
- Isolation invariants must remain intact regardless of provisioning method.

Do not implement automation here — only define the threshold trigger.

---

## CHANGELOG

### v1.1 — 2026-02-18
- Added sub-workflow immutability guard
- Clarified OWNER_WORKSPACE_ID temporary architecture
- Made ACL role explicit in SQL
- Hardened Telegram bot naming convention (environment suffix)
- Formalized secret handling protocol
- Added automation threshold trigger

### v1 — 2026-02-18
- Initial replicable deployment guide
- 7 steps: Supabase, n8n Gateway, Chrome Extension, Telegram, ChatGPT, Validation, Registry
- Covers all 3 execution surfaces (Chrome, Telegram, ChatGPT)
- Based on Clone 1 (Qwrk@Work_Joel) deployment experience
- Includes instruction_pack extension field requirements (learned from validation error)
