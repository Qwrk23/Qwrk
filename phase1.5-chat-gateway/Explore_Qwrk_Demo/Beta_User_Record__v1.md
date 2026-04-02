# Beta User Record v1

**Purpose:** Centralized tracking of all beta users, provisioning state, and onboarding progress.
**Source:** Leaf `370506e8-c411-4b99-886d-9fbd8b7ab6ab`

---

## Active Beta Users

| User Name | Email | Workspace ID | Username | Provisioning | Onboarding | First Success | Notes |
|-----------|-------|-------------|----------|-------------|------------|---------------|-------|
| | | | | | | | |

---

## Field Definitions

| Field | Values | Description |
|-------|--------|-------------|
| **User Name** | Free text | Display name |
| **Email** | Email address | Contact / ChatGPT account |
| **Workspace ID** | UUID | `qxb_workspace.workspace_id` |
| **Username** | `qwrk-beta-<shortname>` | Gateway Basic Auth principal |
| **Provisioning** | `not_started` / `in_progress` / `complete` | Steps 1-6 of provisioning checklist |
| **Onboarding** | `not_started` / `welcome_sent` / `setup_complete` / `active` | User-side progress |
| **First Success** | `Y` / `N` | User completed save + retrieve loop |
| **Notes** | Free text | Issues, feedback, special circumstances |

---

## Status Definitions

### Provisioning Status

| Status | Meaning |
|--------|---------|
| `not_started` | User identified but no infra created |
| `in_progress` | Workspace/credentials created, not fully delivered |
| `complete` | All 8 provisioning steps done, welcome sent |

### Onboarding Status

| Status | Meaning |
|--------|---------|
| `not_started` | Welcome not yet sent |
| `welcome_sent` | Package delivered, awaiting user action |
| `setup_complete` | QSB installed and configured |
| `active` | User is using Qwrk Beta regularly |

---

## Monitoring Checklist

For each user in the first week:

- [ ] First Success completed within 24 hours of welcome?
- [ ] Any error reports or confusion?
- [ ] Second voluntary interaction observed?
- [ ] Feedback captured?

---

## Future Internalization

This record is currently maintained as a markdown file. Future options:
- Google Sheet (for multi-editor access)
- Qwrk project artifact (internalize tracking into Qwrk itself)
- Database table (if beta scales beyond ~10 users)

---

## CHANGELOG

### v1 — 2026-03-21
- Initial beta user record template
- 8 tracking fields with definitions
- Status progression models for provisioning and onboarding
- Monitoring checklist for first week
