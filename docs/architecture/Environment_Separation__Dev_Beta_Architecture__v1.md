# Environment Separation — Dev/Beta Architecture (v1)

**Date:** 2026-01-07
**Status:** LOCKED (Architectural Decision)
**Owner:** Master Joel
**Decision:** One repository, two Supabase database projects

---

## Core Decision

**Qwrk uses a single codebase with environment-specific database instances.**

- **One GitHub repository:** `new-qwrk-kernel`
- **Two Supabase projects:** Dev (existing) + Beta (to be created)
- **Shared code/schema, isolated data**

---

## Rationale

### Why One Repo, Two Databases?

**Simplicity:**
- Single codebase to maintain
- Schema changes apply to both environments
- No duplicate governance docs, workflow logic, or design artifacts

**Data Isolation:**
- Dev contains Master Joel's journals, design notes, build artifacts
- Beta is clean for beta testers (no dev data)
- No risk of dev data leaking to users

**CC Access:**
- Claude Code can query both environments
- Swap connection strings to switch contexts
- Validate schema parity across environments

**Cost Effective:**
- Only pay for two Supabase projects (not separate infrastructure)
- No duplicate repos to sync

**Simple Deployment:**
- Commit changes to repo once
- Deploy to Dev, test, then deploy to Beta
- Rollback is easy (revert in repo, redeploy)

---

## What Gets Separated vs Shared

### SHARED (One Repository)

**Code & Schema:**
- ✅ `docs/schema/LIVE_DDL__Kernel_v1__*.sql` (CREATE TABLE statements)
- ✅ `docs/schema/RLS_*.sql` (Row Level Security policies)
- ✅ n8n workflow JSON files (`workflows/*.json`)
- ✅ Gateway contract definitions
- ✅ Behavioral Controls constitution
- ✅ Governance documents (CLAUDE.md, etc.)

**Design & Documentation:**
- ✅ Architecture docs
- ✅ Design documents
- ✅ Workflow specifications
- ✅ Known-Good Baseline (KGB) validation scripts

**Why shared:**
Code and governance are identical. You're testing the same system with different data.

---

### SEPARATED (Two Supabase Projects)

**Dev Supabase Project** (existing: `npymhacpmxdnkdgzxll`)
- **Purpose:** Master Joel's personal Qwrk instance
- **Contains:**
  - Journals (personal reflections, health tracking)
  - Design artifacts (snapshots, restarts capturing build decisions)
  - Experimental projects (Spring, Beta Readiness, etc.)
  - Test data for workflow validation
- **Workspace:** "Master Joel Workspace" (`be0d3a48-c764-44f9-90c8-e846d9dbbd0a`)
- **Status:** Active development environment

**Beta Supabase Project** (to be created)
- **Purpose:** User-facing beta environment
- **Contains:**
  - Clean database (no dev data)
  - Beta user workspaces
  - Production-ready RLS policies
  - Real user artifacts (created through CustomGPT)
- **Workspace:** Multiple beta user workspaces
- **Status:** Beta testing environment

---

## Component Mapping

| Component | Dev Environment | Beta Environment | Shared? |
|-----------|----------------|------------------|---------|
| **GitHub Repo** | `new-qwrk-kernel` | `new-qwrk-kernel` | ✅ Yes |
| **Supabase Project** | `npymhacpmxdnkdgzxll` | `[beta-project-ref]` (new) | ❌ No |
| **Database Data** | Dev data (journals, design) | Beta data (user artifacts) | ❌ No |
| **Schema (DDL)** | From repo | From repo | ✅ Yes |
| **RLS Policies** | From repo | From repo | ✅ Yes |
| **n8n Instance** | Dev workflows | Beta workflows | ❌ No* |
| **n8n JSON Files** | From repo | From repo | ✅ Yes |
| **CustomGPT** | "Qwrk Dev" | "Qwrk Beta" | ❌ No |
| **CC Read Access** | Via Dev connection | Via Beta connection | ✅ Same code |

**n8n note:** Same workflow JSON, different connection variables (Supabase credentials)

---

## CC Access to Both Environments

Claude Code (CC) can query either environment by switching connection strings.

### Dev Connection (existing)
```
QWRK_DEV_DB_HOST=db.npymhacpmxdnkdgzxll.supabase.co
QWRK_DEV_DB_NAME=postgres
QWRK_DEV_DB_PORT=5432
QWRK_DEV_DB_USER=cc_readonly
QWRK_DEV_DB_PASSWORD=[dev_password]
```

### Beta Connection (to be created)
```
QWRK_BETA_DB_HOST=db.[beta-project-ref].supabase.co
QWRK_BETA_DB_NAME=postgres
QWRK_BETA_DB_PORT=5432
QWRK_BETA_DB_USER=cc_readonly
QWRK_BETA_DB_PASSWORD=[beta_password]
```

### How to Switch
Master Joel tells CC which environment to query:
- "CC, query Dev for..." → uses Dev connection
- "CC, query Beta for..." → uses Beta connection
- "CC, validate schema parity" → queries both, compares

---

## Deployment Flow

### Initial Beta Setup (One-Time)

**Prerequisites:**
- Gateway v1.1 stable in Dev
- CustomGPT tested and working in Dev
- Schema locked (Kernel v1.1 immutable)
- Beta Readiness Sapling promoted to Tree

**Steps:**
1. **Create Beta Supabase Project**
   - Name: "Qwrk Beta"
   - Region: Same as Dev (for latency consistency)
   - Save project ref: `[beta-project-ref]`

2. **Deploy Schema to Beta**
   - Run `LIVE_DDL__Kernel_v1__*.sql` on Beta Supabase
   - Run `RLS_*.sql` policies on Beta Supabase
   - Validate: CC queries both Dev and Beta, confirms table structure matches

3. **Setup n8n for Beta**
   - Create new n8n instance (or use separate workspace in same n8n)
   - Import workflow JSON from repo
   - Update Supabase connection credentials to Beta project
   - Test webhook endpoints

4. **Create Beta CustomGPT**
   - Clone "Qwrk Dev" CustomGPT structure
   - Update webhook URLs to Beta n8n endpoints
   - Update system prompt if needed (same contract)
   - Test artifact.save and artifact.query

5. **Grant CC Read-Only Access to Beta**
   - Follow `docs/governance/QP1_Walkthrough__Grant_CC_ReadOnly_Supabase_Access.md`
   - Create `cc_readonly` role on Beta Supabase
   - Grant SELECT only (no INSERT/UPDATE/DELETE)
   - Validate permissions with test query

6. **Validate Environment Parity**
   - CC runs schema comparison query (Dev vs Beta)
   - Confirm all tables, columns, constraints match
   - Confirm RLS policies match
   - Confirm no data in Beta (clean state)

---

### Ongoing Updates (Dev → Beta)

**Workflow:**
1. **Develop in Dev**
   - Make schema changes, update workflows, test features
   - CC validates in Dev environment
   - Commit changes to `new-qwrk-kernel` repo

2. **Test in Dev**
   - Run KGB validation scripts
   - Create snapshot of changes
   - Get Master Joel approval

3. **Deploy to Beta**
   - Run schema migrations on Beta Supabase (if schema changed)
   - Import updated n8n workflows to Beta n8n
   - Update Beta CustomGPT if API contract changed
   - Notify beta users of updates (if breaking changes)

4. **Validate Beta**
   - CC queries Beta to verify deployment
   - Run smoke tests (artifact.save, artifact.query)
   - Monitor for errors in first 24 hours

5. **Rollback if Needed**
   - Revert commit in repo
   - Redeploy previous version to Beta
   - Investigate issue in Dev

---

## Repository Structure

Current structure already supports this pattern:

```
new-qwrk-kernel/
├── docs/
│   ├── schema/              # Shared (deploy to both)
│   │   ├── LIVE_DDL__Kernel_v1__*.sql
│   │   └── RLS_*.sql
│   ├── governance/          # Shared (same rules)
│   ├── workflows/           # Shared (same logic)
│   ├── architecture/        # Shared (this doc)
│   ├── snapshots/           # Dev-only (Master Joel's build notes)
│   └── saplings/            # Dev-only (project tracking)
├── workflows/               # n8n JSON (deploy to both)
└── .env.example             # Template for connection vars
```

**Add (gitignored):**
```
.env.dev     # Dev Supabase connection string
.env.beta    # Beta Supabase connection string
```

---

## Benefits

✅ **Single codebase** - No duplicate maintenance
✅ **Clean separation** - Dev data never touches Beta
✅ **CC can access both** - Read-only to both environments
✅ **Easy rollback** - Beta trails Dev by design
✅ **Cost effective** - Only two Supabase projects needed
✅ **Simple deploy** - Schema/workflow changes apply to both
✅ **Governance aligned** - Same rules in both environments

---

## Risks & Mitigations

### Risk: Schema Drift
**Problem:** Dev and Beta schemas diverge over time
**Mitigation:**
- CC validates schema parity regularly
- All schema changes committed to repo
- Beta deployments use exact same DDL from repo

### Risk: Breaking Changes in Beta
**Problem:** Deploy breaks Beta users' workflows
**Mitigation:**
- Test thoroughly in Dev first
- Snapshot before deploying to Beta
- Rollback plan (revert + redeploy)
- Notify beta users of breaking changes

### Risk: Data Leak (Dev → Beta)
**Problem:** Dev data accidentally exposed to Beta users
**Mitigation:**
- Separate Supabase projects (physically isolated)
- No data migration scripts (Beta starts clean)
- RLS policies enforce workspace isolation

### Risk: Connection String Confusion
**Problem:** CC queries wrong environment
**Mitigation:**
- Explicit environment names in commands
- CC confirms environment before queries
- Different passwords for Dev vs Beta

---

## Alternative Considered (Rejected)

**Two Separate Repositories:**
- `new-qwrk-kernel` (Dev)
- `qwrk-beta` (Beta production)

**Why rejected:**
- Duplicate maintenance (fix bugs twice)
- Code drift over time (hard to sync)
- CC needs to track two codebases
- More complex governance (which repo is truth?)

**Only valid if:**
- Dev experiments are so radical they'd break Beta
- Need to hide dev work entirely from Beta codebase

This is not the use case for Qwrk Beta.

---

## Pre-Beta Checklist

Before creating Beta Supabase project:

- [ ] Gateway v1.1 stable in Dev
- [ ] CustomGPT tested and working in Dev
- [ ] Schema locked (Kernel v1.1 immutable)
- [ ] RLS policies validated in Dev
- [ ] KGB baseline complete
- [ ] Beta Readiness Sapling promoted to Tree
- [ ] Beta scope exclusions locked
- [ ] Artifact schema canon documented
- [ ] Qwrk Conversation Contract finalized

---

## References

**Governance:**
- Beta Readiness Sapling: `docs/saplings/core-build-cycle/2026-01-06__beta-readiness__governance-contract-locks__5da2d196-f8ec-4458-af9e-178ce72a09b7.md`
- CC Read-Only Access Walkthrough: `docs/governance/QP1_Walkthrough__Grant_CC_ReadOnly_Supabase_Access.md`

**Schema:**
- LIVE_DDL: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`

**Workflow:**
- Gateway v1: `docs/workflows/NQxb_Gateway_v1__README.md`

---

**Status:** LOCKED (Architectural Decision)
**Version:** v1
**Date:** 2026-01-07
**Owner:** Master Joel

---
