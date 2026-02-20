# Seed: MemMachine Learnings for Qwrk Phase 2+

**Date:** 2026-01-09
**Lifecycle Stage:** Seed
**Operational State:** Active
**Owner:** Master Joel
**Parent Thicket:** Core Build Cycle

---

## Seed Summary

This seed captures valuable conceptual patterns from the MemMachine n8n-nodes-memmachine project that could inform Qwrk's Phase 2+ feature design, particularly around automatic context retrieval, external agent APIs, and observability.

**Source:** GitHub repository review of `https://github.com/MemMachine/n8n-nodes-memmachine`

---

## Core Idea

While MemMachine solves a different problem than Qwrk (session-based conversational memory vs. artifact-based lifecycle persistence), several architectural patterns are worth considering for future Qwrk phases.

---

## Key Learnings / Concepts to Explore

### 1. Automatic Context Retrieval / Enrichment (High Priority)

**MemMachine Pattern:**
When an AI agent responds, MemMachine automatically retrieves relevant historical context from past conversations and injects it into the agent's prompt.

**Qwrk Translation:**
- Automatically query workspace for semantically related artifacts when user asks questions
- Surface relevant context without explicit artifact_id references
- Enrich conversations with "you mentioned this in Project X" or "this relates to Snapshot Y"

**Value Proposition:**
- Reduces cognitive load (user doesn't need to remember artifact IDs)
- Makes Qwrk feel more "aware" of workspace context
- Supports "prefrontal cortex" metaphor (connecting past to present automatically)

**Phase 2+ Requirements:**
- Semantic search capability (vector embeddings on artifact content)
- New Gateway action: `context.retrieve` or enhanced `artifact.query` with semantic matching
- Behavioral Controls update: Balance automatic retrieval vs user control

---

### 2. Memory API for External Agents (Extension of Gateway)

**MemMachine Pattern:**
External agents/systems call MemMachine API to store/retrieve conversational context.

**Qwrk Current Status:**
Gateway already provides this via `artifact.query`, `artifact.list`, `artifact.create`.

**Phase 2+ Enhancement:**
- Expose Gateway actions to third-party tools (not just CustomGPT)
- Allow external automation tools to query Qwrk workspace for context
- Example: Zapier integration queries Qwrk for "active projects" before creating tasks
- Example: n8n workflows outside Qwrk query artifact system for business logic decisions

**Value Proposition:**
- Positions Qwrk as "system of record" for intent across automation stack
- Reinforces "prefrontal cortex" role (other tools query Qwrk for decision context)

**Governance Considerations:**
- Needs auth model for external API access (beyond workspace RLS)
- Requires API rate limiting, versioning, contract stability

---

### 3. Session-Level Artifact Type (Speculative - Phase 3+)

**MemMachine Pattern:**
Sessions are first-class entities that capture conversation continuity.

**Qwrk Gap:**
Restarts are manual; no automatic session tracking.

**Potential Concept:**
- New artifact type: **Session** (automatic, system-generated)
- Captures conversation flow between user and Qwrk
- Links to intentional artifacts created during that session
- Queryable: "What did we discuss in my last 3 sessions?"

**Value Proposition:**
- Provides audit trail of conversational activity
- Helps user recall "where we left off" without manual Restart creation
- Complements active journaling (automatic session log + intentional artifact capture)

**Design Question:**
Does this conflict with "nothing saved automatically" philosophy? Could be exception if:
- Sessions are metadata-only (no content unless explicitly saved)
- User can query sessions but they're ephemeral/purgeable
- Only links to artifacts, doesn't duplicate content

---

### 4. Observability / Tracing (Post-Beta)

**MemMachine Pattern:**
OpenTelemetry + Jaeger for distributed workflow tracing.

**Qwrk Use Case:**
- Debug complex Gateway workflows in production
- Visualize artifact lifecycle operations end-to-end
- Monitor performance bottlenecks (CustomGPT → n8n → Supabase)

**When Needed:**
- After Beta launch when debugging production issues
- Not before (adds complexity with low immediate ROI)

---

## What NOT to Take from MemMachine

**Paradigm Mismatch:**
- MemMachine: Session-based conversational memory (message streams)
- Qwrk: Artifact-based lifecycle persistence (intentional capture)

**Integration Pattern Mismatch:**
- MemMachine plugs into n8n's built-in AI agent nodes (memory port)
- Qwrk uses CustomGPT → n8n webhooks → Supabase (no AI agent nodes)

**Conclusion:**
No direct integration or code reuse. Conceptual patterns only.

---

## Phase Recommendations

| Concept | Recommended Phase | Rationale |
|---------|------------------|-----------|
| **Automatic context retrieval** | Phase 2+ | High value; requires semantic search infrastructure |
| **External agent API access** | Phase 2+ | Extends existing Gateway; positions Qwrk as system of record |
| **Session artifact type** | Phase 3+ (speculative) | Philosophical question; needs governance alignment |
| **Observability tracing** | Post-Beta | Production debugging tool; not architectural necessity |

---

## Next Steps (When Sapling-Ready)

**To promote to Sapling:**
1. Design semantic search architecture (vector embeddings strategy)
2. Define `context.retrieve` Gateway action spec
3. Update Behavioral Controls for automatic context surfacing
4. Prototype external API auth model
5. Create implementation plan for Phase 2+

**Blockers:**
- None currently (seed is exploratory only)
- Awaiting Beta V1 completion before Phase 2 planning

---

## References

**Source Material:**
- GitHub: `https://github.com/MemMachine/n8n-nodes-memmachine`
- Package: `@memmachine/n8n-nodes-memmachine` (v2.0.3)
- Review Date: 2026-01-09

**Related Qwrk Documents:**
- Beta Readiness Sapling: `docs/saplings/core-build-cycle/2026-01-06__beta-readiness__governance-contract-locks__5da2d196-f8ec-4458-af9e-178ce72a09b7.md`
- Spring Artifact Type Design: `docs/design/Spring_Artifact_Type__Phase_2_Concept__v1.md`
- Brand Narrative (Prefrontal Cortex Metaphor): `docs/snapshots/AAA_New_Qwrk__Snapshot__Brand_Narrative_v1__2026-01-05.md`

---

**Status:** Seed (Exploratory)
**Owner:** Master Joel
**Lifecycle Stage:** Seed
**Parent Thicket:** Core Build Cycle

---
