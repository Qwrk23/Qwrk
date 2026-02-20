# Multi-User Qwrk — Workspace Registry Tracking

**Created:** 2026-02-17
**Purpose:** Single source of truth for all captured UUIDs, credentials, and URLs during Multi-User Qwrk deployment.

---

## User Registry

| Gateway | Email | auth_user_id | user_id | Status |
|---------|-------|-------------|---------|--------|
| Qwrk@Work_Joel | espressivedemojoel@gmail.com | `9daa1708-c329-4e7c-90cb-30ea5c243d1e` | `1c67004d-3c5a-42ad-8a38-1b36a3284aa2` | [x] Created |
| Akara_Blagg | akarablagg@gmail.com | `{{TBD}}` | `{{TBD}}` | [ ] Created |
| BlaggLife | j_blagg@hotmail.com | `{{TBD}}` | `{{TBD}}` | [ ] Created |
| Krista_Blagg | kristablagg@gmail.com | `{{TBD}}` | `{{TBD}}` | [ ] Created |

---

## Workspace Registry

| Gateway | Workspace Name | workspace_id | Source | Status |
|---------|---------------|-------------|--------|--------|
| Qwrk@Work_Joel | Qwrk@Work | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | Reused existing (Resolve) | [x] Resolved |
| Akara_Blagg | Akara_Blagg | `{{TBD}}` | Create new | [ ] Created |
| BlaggLife | BlaggLife | `b4e7f648-96d5-44a7-80b9-c39cac4efbd1` | Existing | [x] Confirmed |
| Krista_Blagg | Krista_Blagg | `{{TBD}}` | Create new | [ ] Created |

---

## Gateway Configuration

| Gateway | Principal Name | Webhook Path | n8n Credential ID | Webhook URL (full) | Status |
|---------|---------------|-------------|-------------------|-------------------|--------|
| Qwrk@Work_Joel | qwrk-gw-work | /nqxb/gateway/v1/work | `{{n8n}}` | `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1/work` | [x] Deployed |
| Akara_Blagg | qwrk-gw-akara | /nqxb/gateway/v1/akara | `{{TBD}}` | `{{TBD}}` | [ ] Deployed |
| BlaggLife | qwrk-gw-blagglife | /nqxb/gateway/v1/blagglife | `{{TBD}}` | `{{TBD}}` | [ ] Deployed |
| Krista_Blagg | qwrk-gw-krista | /nqxb/gateway/v1/krista | `{{TBD}}` | `{{TBD}}` | [ ] Deployed |

---

## ACL Registry

| Principal Name | workspace_id | acl_id | Role | Status |
|---------------|-------------|--------|------|--------|
| qwrk-gw-work | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | `8ef9b0f6-3b54-4464-86a6-32c32383ce24` | owner | [x] Seeded |
| qwrk-gw-akara | `{{TBD}}` | `{{TBD}}` | owner | [ ] Seeded |
| qwrk-gw-blagglife | `{{TBD}}` | `{{TBD}}` | owner | [ ] Seeded |
| qwrk-gw-krista | `{{TBD}}` | `{{TBD}}` | owner | [ ] Seeded |

---

## Test Results

| Gateway | Test 1 (200) | Test 2 (403) | Test 3 (Error) | Full Cycle | Date |
|---------|-------------|-------------|---------------|------------|------|
| Qwrk@Work_Joel | [x] | [x] | [x] | [x] | 2026-02-18 |
| Akara_Blagg | [ ] | [ ] | [ ] | [ ] | |
| BlaggLife | [ ] | [ ] | [ ] | [ ] | |
| Krista_Blagg | [ ] | [ ] | [ ] | [ ] | |

---

## Notes

- Fill in `{{TBD}}` values as each step completes
- All changes are manual (Joel executes)
- This file is the single tracking surface — do not duplicate values elsewhere
