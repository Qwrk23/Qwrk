# Beta User Provisioning Checklist v1

**Purpose:** Repeatable, step-by-step process for provisioning a new Qwrk Beta user.
**Operator:** Joel (or delegated admin)
**Source:** Leaf `bf5400e2-026a-465e-9fd8-2229114c1b12`

---

## Pre-Provisioning Requirements

Before starting, confirm:
- [ ] Beta Gateway v2 is operational (`/webhook/nqxb/gateway/v2/beta`)
- [ ] QSB beta sidebar extension template is ready (`qwrk-sidebar-beta/`)
- [ ] Qwrk Beta Custom GPT is configured and working
- [ ] Beta system instructions v1 + instruction packs uploaded to GPT

---

## Provisioning Steps

### Step 1: Create Workspace

Create a new workspace for the beta user in Supabase.

```sql
-- 1a. Create qxb_user (if new identity)
INSERT INTO public.qxb_user (display_name, email)
VALUES ('<User Name>', '<user_email>')
RETURNING user_id;

-- 1b. Create workspace
INSERT INTO public.qxb_workspace (name, description)
VALUES ('Qwrk Beta — <User Name>', 'Beta user workspace')
RETURNING workspace_id;

-- 1c. Create workspace membership
INSERT INTO public.qxb_workspace_user (workspace_id, user_id, role)
VALUES ('<workspace_id>', '<user_id>', 'owner');
```

**Record:** workspace_id = `________________`

---

### Step 2: Generate Gateway Credentials

Create Basic Auth credentials for the beta user's QSB profile.

- **Username:** `qwrk-beta-<shortname>` (e.g., `qwrk-beta-sarah`)
- **Password:** Generate a secure random password
- **Base64 credential:** Encode `username:password` as Base64

```bash
echo -n "qwrk-beta-<shortname>:<password>" | base64
```

**Record:** credential = `________________`

---

### Step 3: Add ACL Entry

Register the new principal in the Gateway ACL table.

```sql
INSERT INTO public.qxb_gateway_acl (principal_name, workspace_id, role)
VALUES ('qwrk-beta-<shortname>', '<workspace_id>', 'owner');
```

---

### Step 4: Add to Beta Gateway Token Map

Update the Beta Gateway workflow's `TOKEN_WORKSPACE_MAP` in n8n:

1. Open `NQxb_Gateway_v2_Beta` workflow in n8n
2. Find the token resolution node
3. Add entry: `"<bearer_token>": "<workspace_id>"`
4. Save and activate

---

### Step 5: Configure QSB Extension

Clone the `qwrk-sidebar-beta/` folder for this user.

Edit `profiles.js` with the user's credential:

```javascript
QSB.profiles = [
  {
    id: "qwrk-beta",
    label: "Qwrk Beta",
    endpoint: "https://n8n.halosparkai.com/webhook/nqxb/gateway/v2",
    credential: "<BASE64_CREDENTIAL>",
    auth_mode: "basic"
  }
];
```

Package the folder for delivery (zip or shared folder).

---

### Step 6: Clone Custom GPT

1. Open the Qwrk Beta Custom GPT in ChatGPT
2. Duplicate it (Create a copy)
3. Rename to: `Qwrk Beta — <User Name>`
4. Share with the user's ChatGPT account

---

### Step 7: Send Welcome Package

Send the user:

- [ ] Link to their Qwrk Beta Custom GPT
- [ ] QSB extension folder (zip)
- [ ] QSB Onboarding Guide (`Beta_QSB_Onboarding__v1.md`)
- [ ] Brief welcome message:

> Welcome to Qwrk Beta! Here's everything you need to get started:
>
> 1. Install the QSB Chrome Extension (see the setup guide)
> 2. Open your Qwrk Beta GPT in ChatGPT
> 3. Type anything — Q will help you save your first note
>
> The setup guide walks you through a quick test to make sure everything works.
> If anything doesn't work, just let me know.

---

### Step 8: Verify First Success

After the user reports they've completed setup:

- [ ] Confirm they saved their first journal
- [ ] Confirm they retrieved it successfully
- [ ] Mark "First Success Completed" in the Beta User Record

---

## Post-Provisioning

- Update the Beta User Record with all details
- Monitor for any issues in the first 24 hours
- If the user reports problems, reference the Failure Recovery Pattern (SI error handling)

---

## CHANGELOG

### v1 — 2026-03-21
- Initial provisioning checklist
- 8-step process: workspace → credentials → ACL → token map → QSB → GPT clone → welcome → verify
- SQL templates for workspace/ACL creation
- Welcome message template
