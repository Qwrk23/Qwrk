# NQxb_Gateway_v1__Phase1_BearerAuth_Dev

**Purpose:** Isolated development workflow for Phase 1 Gateway Auth Generalization
**Status:** Development / Testing
**Created:** 2026-02-03

---

## Overview

This workflow is a **cloned development copy** of the live `NQxb_Gateway_v1` Gateway. It implements bearer-token authentication alongside the existing Basic Auth path, allowing the Chrome Extension to authenticate via Supabase JWT while preserving backward compatibility with Telegram.

**The live Telegram Gateway (`NQxb_Gateway_v1`) remains completely untouched.**

---

## Endpoint Configuration

| Workflow | Endpoint | Status |
|----------|----------|--------|
| **Live (Telegram)** | `POST /nqxb/gateway/v1` | Production - DO NOT MODIFY |
| **Phase 1 Dev** | `POST /nqxb/gateway/v1-dev` | Development / Testing |

---

## Key Differences from Live Gateway

### 1. Webhook Authentication

| Aspect | Live | Phase 1 Dev |
|--------|------|-------------|
| Auth Mode | `basicAuth` (required) | `none` (handled in workflow) |
| Endpoint Path | `/nqxb/gateway/v1` | `/nqxb/gateway/v1-dev` |

### 2. New Nodes Added (Phase 1)

| Node | Purpose |
|------|---------|
| `NQxb_Gateway_v1__Auth_Resolve_User` | Detect auth method, validate Basic Auth, prepare bearer for Supabase |
| `NQxb_Gateway_v1__Switch_Auth_Path` | Route to bearer validation or basic pass-through |
| `NQxb_Gateway_v1__Supabase_Validate_Token` | Call Supabase `/auth/v1/user` to validate JWT |
| `NQxb_Gateway_v1__Process_Supabase_Response` | Extract auth.uid from Supabase response |
| `NQxb_Gateway_v1__Lookup_Qxb_User` | Map supabase_auth_id → qxb_user.user_id |
| `NQxb_Gateway_v1__Finalize_Auth` | Finalize resolved user_id or return error |
| `NQxb_Gateway_v1__Switch_Finalize_Result` | Route auth success/failure after Supabase lookup |
| `NQxb_Gateway_v1__Merge_Auth_Paths` | Combine bearer and basic auth paths |
| `NQxb_Gateway_v1__Auth_Error_Response` | Return 401 for auth failures |

### 3. Modified Nodes

| Node | Change |
|------|--------|
| `NQxb_Gateway_v1__Normalize_Request` | Added auth header extraction (`_auth_method`, `_bearer_token`, `_basic_credentials`) |
| `NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly` | Now uses `_resolved_user_id` (server-derived) instead of client-supplied `owner_user_id` |

### 4. Unchanged Nodes

All action routing and subworkflow calls remain identical:
- `NQxb_Gateway_v1__Switch_Action`
- `Call 'NQxb_Artifact_Query_v1'`
- `Call 'NQxb_Artifact_List_v1'`
- `Call 'NQxb_Artifact_Save_v1'`
- `NQxb_Gateway_v1__Respond_Query_Success`
- `merge stuff`
- `Error Response`

---

## Credentials Required

Before activating this workflow in n8n, configure:

| Credential | Type | Purpose | Node |
|------------|------|---------|------|
| Supabase Anon Key | Header Auth | For `/auth/v1/user` API call | `Supabase_Validate_Token` |
| Supabase API | Supabase | For `qxb_user` lookup | `Lookup_Qxb_User` |

**Note:** The workflow JSON contains placeholder credential IDs (`CONFIGURE_ME`). Replace with actual credential IDs after importing to n8n.

---

## Auth Flow Diagram

```
Request arrives at /nqxb/gateway/v1-dev
    │
    ▼
Normalize_Request (extract Authorization header)
    │
    ▼
Auth_Resolve_User (detect method: bearer/basic/none)
    │
    ├──[bearer]──▶ Supabase_Validate_Token
    │                    │
    │                    ▼
    │              Process_Supabase_Response
    │                    │
    │                    ▼
    │              Lookup_Qxb_User
    │                    │
    │                    ▼
    │              Finalize_Auth
    │                    │
    │              Switch_Finalize_Result
    │                    │
    │              ├──[ok]───────────────────┐
    │              └──[error]──▶ Auth_Error_Response (401)
    │                                        │
    ├──[basic, auth_ok=true]─────────────────┤
    │                                        ▼
    │                              Merge_Auth_Paths
    │                                        │
    ├──[auth_ok=false]──▶ Auth_Error_Response (401)
    │                                        │
    ▼                                        ▼
                              Gatekeeper_MVP_OwnerOnly
                                        │
                                        ▼
                              ... existing routing ...
```

---

## Testing Checklist

### Bearer Auth Path (New)

- [ ] Valid JWT, known Qwrk user → Request succeeds
- [ ] Valid JWT, unknown Qwrk user → 401 AUTH_USER_NOT_FOUND
- [ ] Expired JWT → 401 AUTH_TOKEN_INVALID
- [ ] Malformed JWT → 401 AUTH_TOKEN_INVALID
- [ ] Empty bearer token → 401 AUTH_INVALID

### Basic Auth Path (Legacy)

- [ ] Valid Basic Auth + owner_user_id → Request succeeds
- [ ] Valid Basic Auth, no owner_user_id → 401 AUTH_MISSING_USER
- [ ] Invalid Basic Auth username → 401 AUTH_INVALID

### No Auth

- [ ] No Authorization header → 401 AUTH_REQUIRED

### Regression (vs Live)

- [ ] All existing Telegram commands work on live Gateway
- [ ] Response format unchanged
- [ ] Error codes unchanged

---

## Deployment Instructions

### 1. Import to n8n

```
n8n import:workflow --input=NQxb_Gateway_v1__Phase1_BearerAuth_Dev.json
```

Or manually import via n8n UI.

### 2. Configure Credentials

Replace placeholder credential IDs in:
- `NQxb_Gateway_v1__Supabase_Validate_Token` → Supabase Anon Key
- `NQxb_Gateway_v1__Lookup_Qxb_User` → Supabase API

### 3. Activate Workflow

Set `active: true` in workflow settings (currently `false` for safety).

### 4. Test Endpoint

```
POST https://n8n.halosparkai.com/webhook/nqxb/gateway/v1-dev
```

---

## Merge to Live Gateway

**DO NOT merge without explicit approval.**

After Phase 1 validation is complete:
1. Confirm all tests pass on dev workflow
2. Confirm live Telegram Gateway has no regressions
3. Get explicit approval to merge
4. Apply changes to live `NQxb_Gateway_v1` workflow
5. Update `NQxb_Gateway_v1__README.md` with new auth documentation

---

## File Locations

| File | Purpose |
|------|---------|
| `docs/workflows/NQxb_Gateway_v1.json` | **LIVE** - Do not modify |
| `docs/workflows/NQxb_Gateway_v1__README.md` | Live workflow docs |
| `docs/workflows/NQxb_Gateway_v1__Phase1_BearerAuth_Dev.json` | Phase 1 dev workflow |
| `docs/workflows/NQxb_Gateway_v1__Phase1_BearerAuth_Dev__README.md` | This file |

---

**End of README**
