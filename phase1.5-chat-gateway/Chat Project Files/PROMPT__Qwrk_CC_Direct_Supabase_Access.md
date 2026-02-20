# Prompt for Qwrk: Enable CC Direct Supabase Read Access

Copy everything below the line and paste to Qwrk:

---

## Context

I need to upgrade Claude Code's (CC) Supabase access from "proxy queries" (I run SQL manually) to **direct read access** via the Supabase REST API.

**Current State (from 2026-01-05):**
- `cc_readonly` PostgreSQL role exists with SELECT-only permissions
- CC provides SQL, I execute in Supabase SQL Editor manually
- This is slow and creates friction

**Target State (per Seed cb506bc8):**
- CC can query Supabase directly using REST API
- Uses **anon key only** (no service_role, no privileged credentials)
- RLS enforces workspace scoping (Team Qwrk workspace only)
- Read-only — all writes still go through Gateway

## Why REST API (not direct PostgreSQL)

1. **Anon key is safe** — it's public by design, RLS enforces security
2. **No blast radius** — credentials can be in synced folders without risk
3. **No psql needed** — CC uses PowerShell/curl to make HTTP requests
4. **Aligns with Supabase architecture** — PostgREST is the intended access pattern

## What I Need

Walk me through these steps:

### Step 1: Get Supabase API Credentials

I need to retrieve from Supabase dashboard:
- Project URL (e.g., `https://[ref].supabase.co`)
- Anon key (public key, NOT service_role)

**Location:** Project Settings → API → Project URL and anon/public key

### Step 2: Create Configuration File

Create a config file CC can read. Suggested location:
```
C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\.env.supabase
```

Contents:
```
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_ANON_KEY=[anon-key-here]
```

**Note:** This file should NOT contain service_role key.

### Step 3: Create PowerShell Query Script

Create a reusable script CC can invoke to query Supabase.

**Location:** `phase1.5-chat-gateway/scripts/Query-Supabase.ps1`

The script should:
1. Read credentials from `.env.supabase`
2. Accept a table name and optional filter parameters
3. Make GET request to Supabase REST API
4. Return JSON results

**Example usage CC would run:**
```powershell
.\Query-Supabase.ps1 -Table "qxb_artifact" -Select "artifact_id,title,artifact_type" -Filter "artifact_type=eq.journal" -Limit 10
```

### Step 4: Test Queries

After setup, help me verify with these test queries:

**Test 1: Count artifacts by type**
```
GET /rest/v1/qxb_artifact?select=artifact_type&limit=1000
```
Then aggregate in PowerShell.

**Test 2: List journals (should return only Team Qwrk workspace)**
```
GET /rest/v1/qxb_artifact?select=artifact_id,title,created_at&artifact_type=eq.journal&limit=10&order=created_at.desc
```

**Test 3: Verify RLS (query with fake workspace should return empty)**
```
GET /rest/v1/qxb_artifact?workspace_id=eq.00000000-0000-0000-0000-000000000000
```
Should return empty array `[]` due to RLS.

### Step 5: Document in CC Active Seeds

Once working, I'll update:
- `docs/governance/CC_Active_Seeds.md` — mark implementation complete
- Create snapshot documenting the upgrade

## Technical Details

**Supabase REST API Pattern:**
```
GET https://[project-ref].supabase.co/rest/v1/[table]?[query-params]

Headers:
  apikey: [anon-key]
  Authorization: Bearer [anon-key]
```

**Query Parameters (PostgREST syntax):**
- `select=col1,col2` — columns to return
- `column=eq.value` — equals filter
- `column=like.*pattern*` — like filter
- `order=column.desc` — ordering
- `limit=N` — row limit
- `offset=N` — pagination offset

**RLS Behavior:**
- Anon key requests are subject to RLS policies
- `qxb_artifact` RLS requires workspace membership
- CC will only see Team Qwrk workspace data (where I'm a member)

## Security Constraints (Non-Negotiable)

From Seed cb506bc8:
- ✅ Use anon key (public, RLS-enforced)
- ❌ NO service_role key
- ❌ NO credentials that bypass RLS
- ❌ NO write access (read-only)

## My Environment

- Supabase project: Qwrk Kernel v1 (ref: `npymhacpmxdnkdgzxll`)
- CC runs on Windows with PowerShell 5.1
- Files sync via OneDrive
- CC already has `cc_readonly` PostgreSQL role (but we're using REST API instead)

## Expected Outcome

After this walkthrough:
1. CC can run `Query-Supabase.ps1` to fetch data directly
2. RLS enforces workspace scoping automatically
3. No manual proxy queries needed
4. Credentials are safe (anon key only)

## Please Guide Me

Start with Step 1 (getting credentials from Supabase dashboard) and walk me through each step. Wait for my confirmation before moving to the next step.

---

End of prompt.
