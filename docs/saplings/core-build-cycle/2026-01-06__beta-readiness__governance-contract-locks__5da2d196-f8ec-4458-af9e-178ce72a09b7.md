---
title: Beta Readiness — Governance & Contract Locks
artifact_type: project
lifecycle_status: sapling
operational_state: paused
state_reason: Beta gating work — governance locks not yet completed.
artifact_id: 5da2d196-f8ec-4458-af9e-178ce72a09b7
workspace_id: be0d3a48-c764-44f9-90c8-e846d9dbbd0a
parent_thicket_id: 84ccd9aa-c123-4747-968d-9262fa56ec65
thicket_title: Core Build Cycle
tags:
  - beta
  - readiness
  - governance
  - contract
  - scope
created_at: 2026-01-06T23:23:53.185781Z
status: ACTIVE
owner: Master Joel
---

# Beta Readiness — Governance & Contract Locks

## Purpose

This sapling captures the pre-Beta governance work required to lock down Qwrk's foundational contracts before opening to beta users.

The goal is to establish three immutable governance anchors:

1. **Beta scope exclusions** — explicitly define what will NOT ship in V1 to prevent scope creep
2. **Artifact schema canon** — one-page immutable reference for all artifact types, fields, and constraints
3. **Qwrk Conversation Contract** — explicit user-facing contract defining what users can expect when they talk to Qwrk

These three locks ensure Beta users experience a stable, predictable system with clear boundaries.

---

## Scope (What's In)

This sapling focuses exclusively on **governance documentation** and **contract definition**, not implementation.

**Deliverables:**
- Beta scope exclusions document (what won't ship in V1)
- Artifact schema canon (single authoritative page)
- Qwrk Conversation Contract (user-facing behavioral contract)

**Boundaries:**
- No new features or functionality
- No schema changes (only documentation of existing schema)
- No code implementation (pure governance/documentation work)

---

## Out of Scope (Beta V1 Exclusions)

**Status:** TBD — to be locked during sapling → tree promotion

**Confirmed Exclusions:**

### Spring Artifact Type (Idea-Origin Artifact)
- **What:** New first-class artifact_type that sits above execution layer as a durable semantic anchor; can spawn multiple seeds/saplings without being a project itself
- **Why:** Requires schema changes (new artifact_type enum value + extension table), semantic model extension, and Gateway support; adds complexity before Beta baseline is stable
- **When:** Phase 2+ (post-Beta); design captured in restart artifact `2a8a5719-4734-4cd1-9fa1-3880a430c3a1`
- **Reference:** Seed project `5bca1db6-27eb-4272-ae34-f68b91a8685e`; design doc `docs/design/Spring_Artifact_Type__Phase_2_Concept__v1.md`

**Placeholder bullets (to be refined):**
- TBD — Real-time collaboration features (not in V1)
- TBD — Mobile apps (web-first for Beta)
- TBD — Advanced agent automation (approval-gated workflows only)
- TBD — Third-party integrations (Qwrk-native workflows first)
- TBD — Multi-workspace features (single workspace for Beta)
- TBD — Custom Qwrkflows (QF Builder not in V1)
- TBD — Video artifact advanced features (transcription only, no AI insights in V1)

**Definition Criteria:**
Each exclusion must state:
- What is excluded
- Why it's excluded (complexity, risk, or timing)
- When it might be reconsidered (post-Beta, V2, etc.)

---

## Artifact Schema Canon (One Page)

**Status:** TBD — to be derived from Kernel v1 LIVE_DDL + KGB schemas

**Placeholder bullets (to be refined):**
- TBD — Derive from `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`
- TBD — Include all artifact types: project, journal, snapshot, restart, video, grass, thorn
- TBD — Document class-table inheritance pattern (spine + extensions)
- TBD — List all core fields (artifact_id, workspace_id, owner_user_id, artifact_type, title, summary, tags, lifecycle_status, parent_artifact_id)
- TBD — Document lifecycle stages (seed → sapling → tree → retired for projects)
- TBD — Document operational states (active, paused, blocked, waiting)
- TBD — List extension table schemas (qxb_artifact_project, qxb_artifact_journal, etc.)
- TBD — Lock as immutable for Beta (no schema changes during Beta)

**Deliverable:**
Single-page reference document: `docs/reference/Artifact_Schema_Canon__Beta_V1.md`

**Definition of Done:**
- All artifact types documented
- All core and extension fields listed
- Class-table inheritance pattern explained
- Marked as IMMUTABLE for Beta V1
- Referenced in Gateway documentation

---

## Qwrk Conversation Contract

**Status:** TBD — to be derived from Behavioral Controls + Gateway Contract v1

**Placeholder bullets (to be refined):**
- TBD — Derive from `docs/architecture/Behavioral_Controls_Governing_Constitution.md`
- TBD — Include Core Behavioral Controls (precision, no-guessing, pacing, safety)
- TBD — Document Mode system (Bootstrap, Build Mode, role-gating)
- TBD — Explain Qwrkflows (QFs) approval gates and explainability
- TBD — Define Personality Layer (how/not what, user-scoped)
- TBD — List what users can expect (conversational interface, lifecycle awareness, agent approval gates)
- TBD — List what users cannot expect (no fully autonomous actions, no silent changes)
- TBD — Include Gateway action allowlist (artifact.query, artifact.save, artifact.list when ready)
- TBD — Document response formats (success/error envelopes)

**Deliverable:**
User-facing contract document: `docs/contracts/Qwrk_Conversation_Contract__Beta_V1.md`

**Definition of Done:**
- All behavioral controls translated to user-facing language
- Clear explanation of approval gates (agents ask permission)
- Explainability guarantees documented (users can ask "why")
- Gateway actions listed (with examples)
- Marked as immutable for Beta V1
- Linked from onboarding materials

---

## Checklist

### 1. Tighten the beta scope — define exactly what won't ship in V1
- [ ] (status: open)
  - **Deliverable:** Beta V1 Exclusions document listing all out-of-scope features
  - **Definition of done:**
    - Minimum 5-10 explicit exclusions documented
    - Each exclusion has: what, why, when
    - Exclusions reviewed and locked by Master Joel
    - Document saved to `docs/governance/Beta_V1_Exclusions.md`
  - **Notes:** Prevents scope creep during Beta. Aligns expectations for Beta users.

### 2. Canonize the artifact schema — one page, immutable for beta
- [ ] (status: open)
  - **Deliverable:** Artifact Schema Canon single-page reference
  - **Definition of done:**
    - All artifact types (project, journal, snapshot, restart, video, grass, thorn) documented
    - Core fields + extension schemas listed
    - Class-table inheritance pattern explained
    - Marked as IMMUTABLE for Beta V1
    - Saved to `docs/reference/Artifact_Schema_Canon__Beta_V1.md`
  - **Notes:** Derived from LIVE_DDL. No new fields or types during Beta. Single source of truth for schema.

### 3. Define the "Qwrk Conversation Contract" — what users can expect when they talk to it
- [ ] (status: open)
  - **Deliverable:** Qwrk Conversation Contract user-facing document
  - **Definition of done:**
    - Behavioral Controls translated to user-facing language
    - Approval gates explained (agents ask permission before acting)
    - Explainability guarantees documented (users can ask "why")
    - Gateway action allowlist documented (artifact.query, artifact.save, artifact.list)
    - Marked as immutable for Beta V1
    - Saved to `docs/contracts/Qwrk_Conversation_Contract__Beta_V1.md`
  - **Notes:** Derived from Behavioral Controls Constitution + Gateway Contract v1. Sets user expectations for Beta.

---

## Promotion Gate (Sapling → Tree)

**Criteria for Tree promotion:**
- All 3 checklist items marked complete
- All deliverables reviewed and locked by Master Joel
- Snapshot created capturing locked governance state
- No open questions or TBD bullets remaining

**Snapshot Requirement:**
Upon promotion to Tree, create snapshot artifact:
- Title: `Snapshot — Beta Governance Locks Complete — YYYY-MM-DD`
- Payload: References to all three deliverable documents (exclusions, schema canon, conversation contract)
- Status: LOCKED

---

## Notes / Context

**Aligned with:**
- Behavioral Controls — Governing Constitution (`docs/architecture/Behavioral_Controls_Governing_Constitution.md`)
- Qwrk V2 — North Star (foundational positioning)
- Gateway Contract v1 (flat `gw_*` envelope, action allowlist)
- Gateway Internal Normalization Plan v1 (`docs/workflows/specs/Gateway_Internal_Normalization__Implementation_Plan__v1.md`)
- LIVE_DDL Kernel v1 (`docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`)
- **Environment Separation Architecture v1** (`docs/architecture/Environment_Separation__Dev_Beta_Architecture__v1.md`) — One repo, two databases pattern for Dev/Beta isolation

**Governance Notes:**
- This is **documentation and contract work**, not feature development
- All three deliverables must be locked before Beta opens
- No schema changes allowed during Beta (immutability guarantee)
- Conversation Contract sets user expectations for the entire Beta period
- Exclusions list prevents scope creep and manages Beta user expectations
- **Environment separation dependency**: Beta launch requires creating new Supabase project (separate from Dev) per Environment Separation Architecture v1

**Operational Notes:**
- Sapling currently paused (state_reason: "Beta gating work — governance locks not yet completed")
- Unpause when ready to execute on checklist items
- Promote to Tree when all three locks are complete and reviewed

---

**Sapling Status:** ACTIVE (paused)
**Parent Thicket:** Core Build Cycle
**Lifecycle:** Sapling → Tree (pending governance locks completion)
**Owner:** Master Joel

---
