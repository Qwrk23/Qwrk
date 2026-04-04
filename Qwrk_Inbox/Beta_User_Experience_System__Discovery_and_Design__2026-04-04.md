# Beta User Experience System — Discovery & Design Package

> **Date:** 2026-04-04
> **Source:** CC workspace discovery + architecture discussion with Joel
> **Purpose:** Provide Q with design for sanity check, then Manus for implementation plan review
> **Status:** Design — no artifacts created or mutated

---

## Part 1: CC Discovery & Architecture Assessment — Beta Active Master Plan Input

### Joel's Declared Architecture: "Qwrk Lite"

| Decision | Value |
|----------|-------|
| **Product name** | Qwrk Lite (initial beta) |
| **AI surface** | CustomGPT (ChatGPT) + equivalent for Claude |
| **Auth mechanism** | Through Qx (Chrome Extension) — no standalone auth system |
| **Registration flow** | Automated: signup → create user record + workspace in Supabase → configure Qx with user_id + workspace_id |
| **Workspace isolation** | Each beta user gets their own workspace, scoped via Qx |
| **Features** | Locked — stabilization and rollout only |
| **Timeline** | Pre-work before vacation (~3 weeks), beta launch post-vacation |

### Existing Workspace Assets (Confirmed via Gateway Discovery)

#### Core Workstream Artifacts

| artifact_id | title | type | lifecycle | relevance |
|---|---|---|---|---|
| `6742e12a` | Qwrk Website Strategic Planning | project | sapling | Primary public entry point. 7 branches scaffolded (brand, workspace/email, site structure, hosting, auth, onboarding funnel, product surface). All `not_started`. Nav snapshot: `360810aa`. |
| `152d9c11` | Qwrk Operator Console - MVP | project | sapling | Product surface. Phases 1-8 built in code (`qwrk-console/`). 3 branches: Core Console (code done), Topology Viz (not started), Hosting/Deployment (auth blocker). Nav snapshot: `a0e5e2d2`. Milestone: `cd4487d6`. |
| `2f26fbaa` | Qwrk Beta User Provisioning & Onboarding | project | sapling | Provisioning system. Governance snapshots exist (`3996d74a`, `00ac93ae`). **Zero execution branches.** Teaching layer snapshots: `1b46a2db`, `aa7af278`. |
| `669abf42` | Qwrk Monetization — 1:1 System Setup (ADHD + AI Users) | project | sapling | GTM direction. Snapshot `5a089e39` details: 45-60 day revenue target, ADHD adults 30-60, manual 1:1 offer. 4 branches described in snapshot but **not scaffolded as artifacts**. |
| `fb5bccd0` | Compliance-to-Enforcement Hardening | project | seed | Reliability foundation. **2 trees certified** (Gateway Strict Mode `8a937ffd`, Response & Error Integrity `20d27f2d`). 1 sapling remaining (Architectural Enforcement `459fd517` — idempotency, merge-safe, workspace consistency). |
| `68b13f94` | Salience Amplification Doctrine | project | sapling | Payload accuracy initiative. 4 branches scaffolded including **payload.build** (`03fcfc9e` — 3 leaves: spec, tests, drift guard). All `not_started`. This is the "JSON accuracy improvement" workstream. |

#### Supporting Artifacts

| artifact_id | title | type | relevance |
|---|---|---|---|
| `93cb9cbf` | Demo Mode Expansion (Journaling + QPM) | project (tree) | Tagged `beta`. Demo readiness. |
| `ed978e03` | Shareable Qwrk Exploratory GPT | project (tree) | 47/47 tests PASS. Public-facing delivery surface candidate. |
| `ac51d703` | Demo Qwrk Upgrade Requirements | project (seed) | Product positioning, interactive menu, builder path. |
| `222660f8` | **Beta Parity — Patch Save Workflow** | twig | **HARD BLOCKER.** Beta Gateway still on Save v46 (communication_style corruption bug). Must be patched to v50+ before any beta user writes. |
| `86b9b4aa` / `f0786cad` | Qwrk Update Versioning System | twigs (duplicate pair) | No project structure. Needed so beta Q heads can answer "what's new?" |
| `9330c52d` | Next-Touch Hardening Sweep | twig | 3 known fixes for Save, Update, Query workflows. Should be resolved pre-beta. |
| `1ea1b687` | Gateway Stabilization Milestone | snapshot | Evidence: Save/Update/Promote integrity achieved. |

### Architecture Assessment — Three Open Design Questions

**1. How does user identity flow into Qx?**
- Chrome Web Store cannot push user-specific config
- Qx currently uses hardcoded `profiles.js` with workspace IDs
- Needs to become dynamic: user installs generic Qx → registration returns config → user enters credentials into Qx settings page
- This is a real engineering change to the extension (profiles.js → dynamic config)

**2. How does user identity flow into the CustomGPT?**
- Today each Q head is workspace-bound via system instructions
- Options: per-user CustomGPT clone (doesn't scale) vs shared CustomGPT with runtime identity resolution (ChatGPT doesn't natively support this)
- This question affects the entire delivery surface branch

**3. What triggers provisioning?**
- Options: website signup form → n8n webhook, manual invite, invite link/code
- Provisioning creates: `qxb_user` + `qxb_workspace` + `qxb_workspace_user` (role: owner)
- Returns: user_id + workspace_id for Qx configuration
- Likely a new n8n workflow (not an existing Gateway action)

### Critical Path (Sequencing Reality)

```
Auth architecture decision
  ├── Unlocks: Website auth branch, Console hosting, Qx dynamic config
  │
Provisioning workflow (n8n)
  ├── Creates: user + workspace + membership
  ├── Returns: credentials for Qx config
  │
Qx extension refactor (hardcoded → dynamic)
  ├── Config/connect flow for new users
  ├── Workspace scoping per user
  │
Beta Gateway parity patch (v46 → v50+)
  ├── HARD BLOCKER for any beta writes
  │
Website minimum viable (hosting + signup form + landing)
  ├── Entry point for beta users
  │
CustomGPT/Claude head provisioning
  ├── Per-user or shared — depends on design question #2
  │
Beta launch sequence (post-vacation)
```

### Known Blockers

| Blocker | artifact_id | Impact |
|---------|-------------|--------|
| Beta Gateway on Save v46 (corruption risk) | `222660f8` | No beta writes until patched |
| Auth architecture undecided | — | Blocks website, console, signup, Qx |
| Hosting decision unmade | — | Nothing is deployable |
| Qx hardcoded profiles | — | Extension can't support multiple users |

### Known Gaps (No Artifact Exists)

| Gap | Impact |
|-----|--------|
| No master beta rollout plan artifact | Nothing ties workstreams together |
| No provisioning automation workflow | No mechanism to create beta users |
| No Qx dynamic config design | Extension can't onboard new users |
| No beta comms / launch sequence plan | No user communication plan |
| No beta timeline artifact capturing Joel's constraints | House move, vacation, post-vacation launch not captured |
| No update versioning system (only orphan twigs) | Beta users can't know "what's new" |
| Monetization branches not scaffolded as artifacts | GTM structure exists only in snapshot text |

### Structural Notes for Manus

- **Existing saplings should be linked into the master plan, not rebuilt.** Website (`6742e12a`), Console (`152d9c11`), Beta Provisioning (`2f26fbaa`), and Monetization (`669abf42`) all have structure.
- **Compliance-to-Enforcement and Salience Amplification should remain independent projects** that feed into beta readiness as dependencies, not become sub-branches of the beta tree.
- **Duplicate cleanup needed:** Leaf `c1e2b0e8` duplicates `d49b9124` (Console Topology). Twig `86b9b4aa` duplicates `f0786cad` (Versioning). Twig `0050d8b1` (Website Launch Tree) likely superseded by T173.
- **Security boundary is client-enforced only** for beta (Qx cross-workspace write gate). Acceptable for trusted early beta, should be documented as a known limitation.

---

## Part 2: Beta User Experience System — Design for New Sapling

### Core Concept

Every beta user interacts with a shared CustomGPT (published via OpenAI GPT Store, with a Claude equivalent). Authentication and execution happen through Qx (Chrome Extension). There is no standalone auth system. All personalization comes from runtime retrieval, not static config.

### Component 1: Onboarding Profile Capture

When a user signs up for beta:
1. A dedicated onboarding agent has a conversational intake discussion
2. Captures as much or as little as the user wants to share
3. Saves a `person` artifact (artifact_type: person) as the FIRST artifact in the user's workspace
4. Uses the existing person extension table schema (T150, DDL v2.10):
   - Core identity, professional context, communication style
   - Cognitive/behavioral patterns, interaction preferences
   - `additional_details` JSONB for anything unstructured
5. Minimal required fields for low friction, rich schema for depth

### Component 2: User Traits & Shortcuts

Stored ON the person artifact itself (not as a separate file or pack).

**Rationale:** Shared CustomGPT has a 20-file attachment limit. Since every beta user uses the same published GPT, user-specific data cannot be attached as files. All personalization must come from runtime retrieval.

Traits and shortcuts live in `additional_details` JSONB on the person record, structured as keyed objects (e.g., `traits`, `shortcuts`, `preferences`).

### Component 3: Quick Action — "Load My Context"

A Qx quick action button that:
1. Retrieves the user's person artifact (artifact.query)
2. Retrieves the user's rolling memory journal (artifact.query or list)
3. Injects the combined result as a "pre-prompt knowledge pack" into the active CustomGPT session
4. Every Qwrk session starts by hydrating: who you are + how you want to be served + what happened recently

### Component 4: End-Session Rolling Memory

An "end session" experience that captures session context:
1. User triggers end session (Qx button or chat command)
2. CustomGPT generates a structured session summary
3. Summary is saved as a `content_append` to a rolling memory journal artifact in the user's workspace
4. Each entry is a dated JSONB object: what happened, decisions made, active items, carry-forward notes
5. Next session's "load my context" retrieves the latest state

Rolling memory journal:
- **artifact_type:** journal (owner-private, supports content_append)
- Created during onboarding (empty, ready for first session end)
- Grows via append — compaction strategy deferred to post-MVP

### Component 5: Shared CustomGPT Architecture

- One published CustomGPT used by all beta users
- User identity resolved at runtime via Qx (not via GPT config)
- GPT system instructions contain Qwrk behavioral rules but NO user-specific data
- All personalization comes from the "load my context" hydration flow
- Claude equivalent follows same pattern (shared agent, runtime identity)

### Key Constraints

- Features are locked — this is the user experience layer for existing infrastructure
- Person artifact schema already exists (T150)
- Save pipeline works (Save v47+, but Beta Gateway needs parity patch)
- Gateway query/list infrastructure exists for retrieval
- Qx exists but needs: dynamic user config, quick action buttons, end-session trigger
- 20-file limit on CustomGPT means zero per-user attached files
- Security: workspace isolation is client-enforced via Qx (acceptable for trusted early beta)

### Dependencies

- Beta Gateway parity patch (Save v46 → v50+) — hard blocker
- Qx refactor from hardcoded profiles to dynamic user config
- Provisioning workflow (user + workspace + membership creation)
- CustomGPT system instruction design for shared-with-runtime-identity

### CC Technical Notes

- `content_append` adds to the `append_log` array on the spine. For a rolling memory journal growing every session, this works for early beta but the array will get large over months.
- A "compaction" action (archive old entries, write fresh summary) should be on the roadmap but is not beta-blocking.
- The person artifact's `additional_details` JSONB is unbounded — traits/shortcuts structure should be defined as a keyed-object convention to prevent drift.

---

## Part 3: Prompt to Q — Sanity Check & Enrich

```
## Context

CC performed a full workspace discovery for Beta Active readiness and Joel 
and CC had an architecture discussion that produced the following design 
for a new sapling: the Beta User Experience System.

This sapling will be folded into the master Beta Active plan but needs to 
be designed and reviewed independently first.

## Design Summary — Beta User Experience System

[See Part 2 of this document for the full design]

## What I Need From You

1. Sanity check this design against Qwrk governance and existing 
   architecture. Flag anything that conflicts with North Star, existing 
   locks, or known constraints.
2. Identify risks I may be underweighting — especially around the shared 
   CustomGPT identity resolution and the rolling memory journal growth.
3. Enrich with anything missing — are there components of the beta user 
   experience that this design doesn't account for?
4. Confirm the person artifact is the right vehicle for traits/shortcuts, 
   or flag if a different pattern is better.
5. Flag any sequencing concerns — what must happen before what.
6. Prepare your additions and refinements so we can generate a clean 
   prompt to Manus for implementation plan review.

Do NOT build the sapling or emit payloads. This is a design review pass.
```

---

## Part 4: Prompt to Manus — Implementation Plan Review

```
## Context

You are reviewing an implementation plan for a new Qwrk sapling called 
"Beta User Experience System." This sapling will be folded into the 
master Beta Active plan but is being designed independently.

Joel (operator) and CC (Claude Code) designed this. Q (Qwrk Prime) has 
reviewed and enriched it. Your job is to review the plan for structural 
soundness, identify risks, and confirm it is ready to be scaffolded as 
a sapling with branches and leaves.

## Design Summary

[Q will insert the enriched design here after sanity check]

## Your Review Scope

You are a bounded plan sanity checker. Review for:

### 1. Structural Soundness
- Does this decompose cleanly into branches and leaves?
- Are the boundaries between components clear?
- Is there unnecessary coupling between components?
- Are there circular dependencies?

### 2. Sequencing & Dependencies
- Is the critical path correctly identified?
- Are there hidden dependencies that could block progress?
- Can any branches be parallelized?
- What is the minimum viable sequence to get a single beta user 
  through the full flow?

### 3. Risk Assessment
- What are the highest-risk components?
- Where is the design making assumptions that haven't been validated?
- What fails if the shared CustomGPT identity resolution doesn't work 
  as expected?
- What is the rollback plan if rolling memory journal growth becomes 
  a problem?

### 4. Scope Discipline
- Is anything in this plan that should NOT be in this sapling?
- Is anything missing that MUST be in this sapling?
- Are there components that belong in the master beta plan instead?
- Does this sapling try to solve problems that are already solved 
  elsewhere?

### 5. QPM Compliance
- Can each branch be independently validated?
- Are success criteria definable for each leaf?
- Is the crawl/walk/run phasing appropriate?

## Constraints You Must Respect

- Features are locked — this is user experience layer, not new features
- Person artifact schema (T150) already exists — do not redesign
- Gateway and save pipeline exist — do not redesign
- This sapling will be LINKED INTO a master beta plan, not absorbed
- Joel's timeline: pre-work before vacation (~3 weeks), launch after
- CC is read-only for database writes — all mutations require Joel
- No speculative future features — only what's needed for beta launch

## Output Format

Return your review as:
1. **Verdict:** Ready to scaffold / Needs revision / Blocked
2. **Structural feedback:** Branch/leaf decomposition notes
3. **Risk register:** Top 3-5 risks with severity and mitigation
4. **Sequencing recommendation:** Suggested branch execution order
5. **Scope adjustments:** Add/remove/defer recommendations
6. **Questions for Joel:** Anything that requires operator decision 
   before scaffolding

Do NOT scaffold the sapling. Do NOT emit artifacts or payloads. 
Review only.
```

---

## CHANGELOG

### v1 — 2026-04-04
**What changed:** Initial creation. CC workspace discovery + Joel architecture decisions + design for Beta User Experience System sapling + prompts for Q and Manus review.

**Why:** Joel directed Q to prepare master beta plan with Manus. CC discovered existing workspace state, Joel defined Qwrk Lite architecture (shared CustomGPT, Qx auth, automated provisioning, person-based profile, end-session rolling memory). This document packages everything for the Q → Manus review pipeline.

**Scope of impact:** New file. No existing files modified.

**How to validate:** Read document. Confirm artifact_ids match live workspace. Confirm design aligns with Joel's stated architecture.
