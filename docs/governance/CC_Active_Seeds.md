# CC Active Seeds

Seeds that provide directional context for Claude Code (CC) when working on Qwrk.

---

## Seed — Qwrk Infrastructure Capacity & Scaling Assumptions

**UUID:** `441ed127-113f-48e3-aedd-8874ae9ae19a`
**Status:** Active
**Date Added:** 2026-01-29

### Summary

Documents current assumptions about Qwrk's infrastructure capacity during beta and early production.

### Key Assumptions

- Expected user counts and usage patterns (beta scale)
- Likely bottlenecks: Supabase Free tier, n8n throughput, concurrency
- Non-binding infrastructure upgrade ladder
- Philosophy: scale based on observed pain signals, not preemptive optimization

### CC Guidance

When making suggestions, plans, or changes related to infrastructure, scaling, performance, or capacity:

1. **Align** recommendations with the assumptions and upgrade posture captured in this seed
2. **Surface conflicts** or risks explicitly if identified
3. **Prefer** incremental, observable scaling steps over premature architectural changes
4. **Avoid** preemptive optimization or over-engineering for hypothetical scale

---

---

## Seed — CC Read Access via RLS (No Service Role)

**UUID:** `cb506bc8-497a-4eca-8a2a-68a77c07e8cd`
**Status:** ✅ Implemented (2026-01-30)
**Date Added:** 2026-01-29

### Summary

Establishes that CC will be granted direct read access to Qwrk's Supabase database, scoped to the Team Qwrk workspace only, respecting Row Level Security.

### Implementation (2026-01-30)

- RLS policies added for `anon` role on Master Joel Workspace (`be0d3a48-c764-44f9-90c8-e846d9dbbd0a`)
- Policies applied to: `qxb_artifact`, `qxb_workspace`, `qxb_artifact_project`, `qxb_artifact_journal`, `qxb_artifact_snapshot`, `qxb_artifact_restart`
- Access method: Supabase REST API via `Query-Supabase.ps1` script
- Credentials: `.env.supabase` with anon key only (no service_role)

### Agreed Approach (Binding)

- CC granted **broad READ access** scoped to Team Qwrk workspace only
- Access MUST respect Supabase Row Level Security (RLS)
- CC MUST NOT be given:
  - service_role keys
  - credentials that bypass RLS
  - unrestricted write/delete access
- Initial posture is **read-only**
- All writes remain governed through Qwrk Gateway / n8n workflows

### Rationale

- CC's runtime environment is local but synced (OneDrive + Google Drive)
- Privileged credentials represent unacceptable blast radius
- Qwrk artifacts in Supabase are the single source of truth
- Governance at the boundary is non-negotiable

### CC Guidance

1. **Treat Supabase as the authoritative "Qwrk Brain"**
2. **Prefer querying existing artifacts** (projects, seeds, journals, snapshots) over recreating parallel files unless explicitly asked
3. **Assume future evolution** toward RAG-based retrieval once Qwrk's native web chat becomes primary
4. **Do not assume write access** unless explicitly granted via Gateway contracts
5. **Surface conflicts** or risks explicitly if detected
6. **Use `Query-Supabase.ps1`** for direct database queries when needed

---

## Seed — Introduce RAG Capabilities in Qwrk

**UUID:** `c02b26b5-2a5f-48e6-9928-dd5aea1c6be2`
**Companion Journal:** `104a4334-710e-4152-84c7-998cfdef32a6`
**Status:** Active (Seed stage)
**Date Added:** 2026-01-30

### Summary

Plans a governed, staged rollout of Retrieval-Augmented Generation (RAG) for Qwrk to enable scalable long-term memory and context retrieval, starting with low-risk read-only retrieval and evolving into a full production capability.

### Key Context

- RAG will be needed when n8n AI agent becomes primary conversational planner (buffer-window memory won't scale)
- Supabase remains canonical source of truth; RAG is retrieval aid, not the truth
- Planning posture: baby steps, read-only retrieval first, defer write/auto-mutation until governance proven
- Lifecycle: Seed → Sapling → Tree over multiple sessions

### CC Guidance

1. **Respect RAG's role** — RAG is a retrieval aid, not a replacement for Supabase as source of truth
2. **Workspace scoping is non-negotiable** — No cross-tenant leakage in any RAG implementation
3. **Selective retrieval** — Do not flood the LLM with raw history; retrieve only relevant context
4. **Read-only first** — Any RAG suggestions should prefer read-only retrieval until governance is proven
5. **Surface evaluation signals** — When discussing RAG, consider accuracy, latency, cost, and user trust

---

## How to Use This File

When new seeds are planted that provide CC-relevant context, add them here with:
- UUID
- Summary
- Key guidance for CC behavior
