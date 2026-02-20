# AAA_New_Qwrk__Snapshot__Dev_Beta_Environment_Separation__2026-01-07

**Date:** 2026-01-07
**Owner:** Master Joel
**Status:** LOCKED
**Type:** Architectural Decision
**Artifact Type:** snapshot

---

## Decision

**Qwrk will use a single codebase (`new-qwrk-kernel`) with two separate Supabase database projects for Dev and Beta environments.**

---

## Core Architecture

### One Repository
**GitHub:** `new-qwrk-kernel`
- Shared code, schema DDL, RLS policies, n8n workflows, governance docs
- All deployments pull from this single source of truth

### Two Supabase Projects

**Dev Supabase** (existing: `npymhacpmxdnkdgzxll`)
- Master Joel's personal Qwrk instance
- Contains journals, design artifacts, build notes
- Development and testing environment

**Beta Supabase** (to be created pre-launch)
- Clean user-facing environment
- No dev data
- Beta tester workspaces only

---

## Rationale

**Why this pattern:**
1. **Single codebase** - No duplicate maintenance, no code drift
2. **Data isolation** - Dev data never touches Beta users
3. **Simple deployment** - Commit once, deploy to both
4. **CC access** - Can query both environments (read-only)
5. **Cost effective** - Only two Supabase projects needed
6. **Easy rollback** - Beta trails Dev by design

---

## What Gets Separated vs Shared

### SHARED (One Repo)
- Schema DDL files
- RLS policies
- n8n workflow JSON
- Gateway contracts
- Behavioral Controls
- Governance documents (CLAUDE.md, etc.)

### SEPARATED (Two Databases)
- **Dev:** Master Joel's journals, design artifacts, test data
- **Beta:** User workspaces, user artifacts, clean state

---

## Component Mapping

| Component | Dev | Beta | Shared? |
|-----------|-----|------|---------|
| GitHub Repo | `new-qwrk-kernel` | `new-qwrk-kernel` | ✅ |
| Supabase Project | existing | new | ❌ |
| Database Data | dev artifacts | user artifacts | ❌ |
| Schema/RLS | from repo | from repo | ✅ |
| n8n Workflows | dev instance | beta instance | ❌ (separate) |
| n8n JSON | from repo | from repo | ✅ |
| CustomGPT | "Qwrk Dev" | "Qwrk Beta" | ❌ |
| CC Access | dev connection | beta connection | ✅ (same tool) |

---

## CC Access Pattern

Claude Code can query either environment by switching connection strings:

**Dev Connection:**
```
QWRK_DEV_DB_HOST=db.npymhacpmxdnkdgzxll.supabase.co
QWRK_DEV_DB_USER=cc_readonly
```

**Beta Connection:**
```
QWRK_BETA_DB_HOST=db.[beta-project-ref].supabase.co
QWRK_BETA_DB_USER=cc_readonly
```

Master Joel specifies: "CC, query Dev" or "CC, query Beta"

---

## Deployment Flow

### Initial Beta Setup (Pre-Launch)
1. Create Beta Supabase project
2. Deploy schema from repo (LIVE_DDL + RLS)
3. Setup Beta n8n with Beta Supabase credentials
4. Create Beta CustomGPT pointing to Beta n8n
5. Grant CC read-only access to Beta
6. Validate schema parity (Dev vs Beta)

### Ongoing Updates
1. Develop and test in Dev
2. Commit changes to repo
3. Deploy to Beta (schema migrations + workflow updates)
4. Validate with CC queries
5. Rollback if needed (revert commit + redeploy)

---

## Benefits

✅ Single codebase (no duplicate maintenance)
✅ Clean data separation (Dev isolated from Beta)
✅ CC can validate both environments
✅ Simple deployment (commit once, deploy twice)
✅ Easy rollback (Beta trails Dev)
✅ Cost effective (two Supabase projects only)
✅ Governance aligned (same rules everywhere)

---

## Risks & Mitigations

**Schema Drift:**
- Risk: Dev and Beta schemas diverge
- Mitigation: CC validates parity, all changes via repo

**Breaking Changes:**
- Risk: Deploy breaks Beta users
- Mitigation: Test in Dev first, snapshot before deploy, rollback plan

**Data Leak:**
- Risk: Dev data exposed to Beta
- Mitigation: Separate Supabase projects (physical isolation), no migration scripts

**Connection Confusion:**
- Risk: CC queries wrong environment
- Mitigation: Explicit environment names, different passwords

---

## Alternative Rejected

**Two separate repos** (new-qwrk-kernel-dev + qwrk-beta):
- Rejected: Duplicate maintenance, code drift, governance complexity
- Only valid if dev experiments would break Beta (not the case)

---

## Pre-Beta Checklist Reference

Before creating Beta Supabase project, these must be complete:
- Gateway v1.1 stable
- CustomGPT working
- Schema locked (Kernel v1.1)
- Beta Readiness Sapling → Tree
- Beta scope exclusions locked
- Artifact schema canon documented
- Qwrk Conversation Contract finalized

---

## References

**Architecture Document:**
`docs/architecture/Environment_Separation__Dev_Beta_Architecture__v1.md`

**Beta Readiness:**
`docs/saplings/core-build-cycle/2026-01-06__beta-readiness__governance-contract-locks__5da2d196-f8ec-4458-af9e-178ce72a09b7.md`

**CC Access Walkthrough:**
`docs/governance/QP1_Walkthrough__Grant_CC_ReadOnly_Supabase_Access.md`

---

**Status:** LOCKED
**Decision Date:** 2026-01-07
**Owner:** Master Joel

---
