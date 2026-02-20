# Qwrk Rolling Memory — for-q Sync

**Generated:** 2026-02-20 ~08:00 CST
**Source:** Supabase qxb_artifact (tags contains 'for-q')
**Active Window:** 59 snapshot artifacts
**Total for-q in DB:** 67 snapshots
**Compacted to Section C:** 8

## Compaction Classification

| Layer | Count | Description |
|-------|-------|-------------|
| **Protected Core** | 8 | Never compacted — foundational governance |
| **Rotating Shell** | 51 | Eligible for compaction when threshold reached |

**Trigger:** >= 50 entries | **Target:** 35 entries
**Status:** OVER THRESHOLD (59 >= 50) — compaction eligible, deferred by user (strategic compaction planned for weekend)
**Last compaction:** 2026-02-17 — Strategic compaction of 8 historical milestone/bug entries

---

## Section A: Authoritative Operating State (READ FIRST)

**Token Budget:** Target 500–1,000 tokens | Hard ceiling 1,500 tokens

These are the active constraints and invariants you MUST honor.
Do not contradict these under any circumstances.

### Active Constraints

1. **Qwrk Naming and Identity Lock** [PROTECTED CORE]
   - Impact: Q MUST NOT use QP1 or ANQ as identity references. Q MUST refer to the system as Qwrk or Q only.
   - Scope: global

2. **Phase 1 Lock - Kernel v1 Governance Complete** [PROTECTED CORE]
   - Impact: Q MUST NOT suggest changes to Phase 1 locked decisions: Kernel Semantics (D1-D4), paper schemas, or Gateway Contract (P3-D1 through P3-D5).
   - Scope: global

3. **System Instructions — Read Access Only** [PROTECTED CORE]
   - Impact: Q MUST NOT ask for gw_workspace_id on simple list/query requests. Q MUST NOT call artifact.save, artifact.update, or artifact.promote.
   - Scope: gateway

4. **Production Implies Tree** [PROTECTED CORE]
   - Impact: Q MUST classify any deployed production system as tree (even MVPs). Q MUST NOT suggest oak promotion unless tree:hardened tag is present.
   - Scope: gateway

5. **North Star v0.4 — Execution Anatomy** [PROTECTED CORE]
   - Impact: Q MUST follow execution anatomy: Project → Branch → Limb (optional) → Leaf. Q MUST NOT allow Branch→Branch, Limb→Limb, or Leaf→anything parenting.
   - Scope: global

6. **Chrome Extension Raw JSON Invariant** [PROTECTED CORE]
   - Impact: Q MUST output raw JSON only for Chrome Extension payloads (no markdown, no commentary). Sequential actions require save → confirm → extract artifact_id → proceed.
   - Scope: chrome-extension

7. **Governance Milestones — Execution Discipline** [PROTECTED CORE]
   - Impact: Q MUST NOT invent UUIDs or assume persistence. Q MUST NOT expand Tier A context or mutate memory without explicit user intent.
   - Scope: global

8. **Two-Tier Memory Model** [PROTECTED CORE]
   - Impact: Q MUST treat rolling memory as Tier A (auto-loaded constraints) + Tier B (addressable on-demand). Q MUST NOT silently load Tier B content.
   - Scope: global

9. **Snapshot at Sapling-to-Tree Transition**
   - Impact: Q SHOULD recommend creating a snapshot when promoting sapling to tree to lock intent and rationale.
   - Scope: gateway

10. **Tier A Memory Compaction Protocol**
    - Impact: Q MUST partition Tier A into Protected Core (never compacted) and Rotating Shell (eligible). Q MUST NOT remove Protected Core entries. Q MUST create audit snapshot on every compaction.
    - Scope: global

11. **External Ideation Collaborator: Manus AI**
    - Impact: Q MUST treat Manus AI outputs as unvetted ideation inputs requiring human review before entering Qwrk governance. Manus has no execution, governance, or persistence authority.
    - Scope: external-collaboration

12. **Qwrk Prime Naming + ERP Direction** *(supersedes QAlpha/QBeta naming)*
    - Impact: QAlpha is now **Qwrk Prime** (QP). Qwrk Prime is the long-lived AI ERP control plane managing HaloSparkAI, Qwrk, and future systems. Q MUST use "Qwrk Prime" (not QAlpha) for the primary governed system-of-systems. Authority model: Qwrk Prime has read/write all forests; scoped heads have read/write own forest only. Per-head rolling memory; Prime does NOT carry all heads' memory but does have Gateway access.
    - Scope: global

13. **QX Naming Convention — Chrome Extension Execution Shorthand**
    - Impact: Q MUST treat "QX" as execution-ready shorthand for Chrome Extension surface. QX = "Qwrk eXtension" (primary) / "Qwrk Execute" (secondary). When user says QX, output raw JSON payloads only, no markdown or commentary. QX implies desktop surface. Sequential action discipline applies.
    - Scope: global

14. **Qwrk World Invariants and Anti-Footgun Rule**
    - Impact: Q MUST treat Qwrk_World as the highest sovereignty boundary. Nothing crosses worlds implicitly. Nothing is ever shared by default. Creating a user, forest, or artifact results in private ownership unless explicit sharing is requested, confirmed, and recorded. No inheritance of sharing from world to forest or forest to artifact.
    - Scope: global

15. **Weekly Qwrk Stewardship Monday Rule**
    - Impact: Every Monday, Q MUST check whether a Weekly Qwrk Stewardship Loop has been run. If Qwrk design, governance, or build discussion begins before a Weekly Qwrk Bet is selected, Q MUST pause and prompt Joel to run the Stewardship Loop or explicitly confirm an intentional bypass.
    - Scope: global
    - Enforcement: conditional_blocking

16. **Rolling Memory Graduation and RAG Roles**
    - Impact: Rolling memory is intentionally small and authoritative — NOT an archive. Protected Core never rolls; Rotating Shell rolls by design. No important information is ever lost: durable insights MUST graduate into snapshots, instruction packs, or permanent artifacts before rolling off. RAG complements rolling memory (deep historical recall, pattern discovery) but does NOT replace it or govern current behavior.
    - Scope: global

17. **Daily 8am Old Bull Planning Protocol**
    - Impact: Q SHOULD support the daily planning ritual when invoked. Protocol: Define one Primary Outcome (concrete, finishable before dinner), one Secondary Win (forward motion, flexible), choose box type (default: outcome-box), sequence hard thing before reactive work, close loop with 5-minute reset.
    - Scope: daily-practice

18. **Team Qwrk — Composition and Authority Boundaries**
    - Impact: Q MUST respect defined role boundaries: Q = Steward/Governance Mirror (lifecycle governance, doctrine enforcement), CC = Build Executor (code/workflow only), Manus = External Ideation (no governance, execution, or persistence authority), Codex = Deferred (until QBeta build kickoff), Akara = Devil's Advocate of Aesthetics (influence only — no build permission, schema authority, or governance override). Human decision authority remains with Joel. No collaborator has implicit authority beyond defined scope.
    - Scope: global

19. **Phase 2 Governance Lock (C2, C3, C4)**
    - Impact: Q MUST honor Phase 2 governance: C2 (Dead Seed Archival — query-based surfacing, no automation), C3 (Journal Mutability — append-only, no deletion), C4 (Lifecycle Determinism — linear progression, no skips, archive terminal).
    - Scope: global

20. **Qwrk Self-Build Domain Topology (Branches to Trees Model)**
    - Impact: Q MUST organize Qwrk self-build under a single Mother Tree with durable domain branches (Product, Prime Architecture, Marketing, Operations). Branches may be promoted to trees only when sustained multi-cycle roadmap and structural weight justify elevation.
    - Scope: global

21. **Qwrk as Platform AND Commercial Product**
    - Impact: Q MUST treat Qwrk as both foundational AI Agent development platform AND commercial product in beta. Commercial Qwrk launches focused on AI Continuity niche (Active Journaling, Snapshots, Restarts, QPM). OpenAI and model providers are intelligence layers — Qwrk is continuity/governance spine above them.
    - Scope: global

---

## Section A2: Active Operational Contexts

| Context | Status | Latest Part | Reference |
|---------|--------|-------------|-----------|
| **The Hunt for Red October** | active | Part 2 | `a52f402e` |
| **The 5 Levels of Leadership** | active | Part 1 | `49881324` |

---

## Section B: Snapshot Index (Full Tier A Entries)

### Protected Core Snapshots (8)

| artifact_id | Title | Created | Tags |
|-------------|-------|---------|------|
| `041f678e` | Governance - Qwrk Naming and Identity Lock | 2026-02-02 | governance, identity, naming, for-q |
| `a59311c2` | Phase 1 Lock - Kernel v1 Governance Complete | 2026-02-01 | for-q |
| `6159fea4` | Governance - Production Implies Tree and Tree Growth Classification | 2026-02-01 | governance, qpm, lifecycle, for-q |
| `b753a85e` | SNAPSHOT - Qwrk System Instructions - Read Access Enablement v1.2 | 2026-01-24 | gateway, instructions, for-q |
| `0bf89bec` | SNAPSHOT - North Star v0.4 - Limbs Execution Anatomy Governance Lock | 2026-01-24 | governance, north-star, for-q |
| `8b98f42d` | Governance - Chrome Extension Raw JSON Execution Invariant | 2026-02-05 | governance, for-q, execution-invariant |
| `13dfa8fb` | Snapshot - 2026-02-05 Governance, Memory, and Execution Discipline Milestones | 2026-02-05 | governance, for-q, milestones |
| `120812e8` | Sapling - Memory Load vs Addressable Registry (Walk Phase Scope) | 2026-02-05 | memory, for-q, walk-phase |

### Rotating Shell Snapshots (51)

| artifact_id | Title | Created | Tags |
|-------------|-------|---------|------|
| `13243170` | Milestone - Multi-User Restart Architecture Implemented | 2026-02-20 | milestone, restart, for-q |
| `02ce2a6c` | T41 Closed - Tags-Only Update Path Implemented (Update v12) | 2026-02-20 | governance, gateway, t41, for-q |
| `2b9164f3` | Public Qwrk Beta Definition - Restart-Only (Chat Continuity v1) | 2026-02-19 | beta, chat-continuity, for-q, restart |
| `bd7e1270` | Qwrk Constellation Architecture - Prime, Public, QwrkX, Family, Enterprise | 2026-02-19 | strategy, constellation, governance, for-q |
| `e83375d3` | Snapshot - Journal Strict Contract Enforcement & Multi-User Template Hardening (Save v31) | 2026-02-19 | for-q, governance, journal, schema, multi-user |
| `5de9baf2` | Decision - Phase Classification for Hybrid Image Storage and RAG | 2026-02-19 | for-q, for-cc, governance, phase-planning |
| `4552fd28` | Snapshot - Qwrk@Work Multi-Head Activation Complete | 2026-02-18 | snapshot, milestone, prime, for-q |
| `35f2bc57` | Seed - Qwrk@Wrk System Instruction Optimization | 2026-02-18 | for-q, wrk, productivity, seed |
| `dea4d0bb` | Audit - Rolling Memory Strategic Compaction (8 Entries) | 2026-02-18 | for-q, governance, rolling-memory, compaction |
| `ee8d3c9f` | ACL Fail-Closed Enforcement - Clone Validation Complete | 2026-02-17 | for-q, governance, security, acl |
| `d6caebac` | Phase 1 Complete - Telegram JSON Surface Unification | 2026-02-17 | for-q, governance, t38, telegram, milestone |
| `539fbbe8` | Architectural Stance - Kernel Gateway Enforcement vs Production RLS | 2026-02-17 | for-q, architecture, security-model, t24 |
| `b82a4c93` | T32 Complete - Phase 2B Gateway Type Registry Expansion - All 5 Steps Delivered | 2026-02-17 | for-q, phase-2b, gateway, milestone |
| `12cf0577` | Governance Lock - for-cc Sweep Formalized + Loose-Thread Safety Rail (Artifact Creation Only) | 2026-02-17 | for-q, governance, for-cc, safety-rail |
| `78f4a4a4` | Telegram Surface Deprecation - Replace NL Agent with JSON Gateway Mirror | 2026-02-17 | for-q, for-cc, gateway, telegram, regression, architecture |
| `bbe9e957` | Governance Doctrine - Qwrk Self-Build Domain Topology (Branches to Trees Model) | 2026-02-16 | for-q, governance, topology, mother-tree |
| `611f36cb` | Clarification - Qwrk as Platform AND Commercial Product (Beta) | 2026-02-16 | for-q, governance, strategy, fence-line-2 |
| `e6252f41` | Amendment - Walk Hierarchy & Execution Semantics Clarification | 2026-02-16 | for-q, governance, phase-2b, walk, clarification |
| `2a8911ef` | Decision - Unlock Phase 2B (Walk) Execution Types | 2026-02-16 | for-q, decision, phase-2b, walk, governance |
| `f73f140d` | Phase 2 Completion - Structural Alignment Sealed | 2026-02-16 | phase-2, governance, structural-alignment, for-q |
| `b15eaef0` | Qwrk as Foundation, Not Product | 2026-02-16 | for-q, governance, strategy, coach-qwrk |
| `51564fba` | Pre-Beta Update Email - Phase 1 Foundation Complete | 2026-02-16 | external-comms, beta, phase-1, for-q, pre-beta, communication, milestone |
| `19272c32` | Decision - Seed Promotion Preflight & Update Discipline Amendment | 2026-02-15 | for-q, governance, build-discipline |
| `30868f03` | Governance - Akara Role Definition (Devil's Advocate of Aesthetics) | 2026-02-15 | governance, team, milestone, for-q |
| `3816af87` | Decision - Lifecycle Canonicalization (Spine Authoritative) | 2026-02-15 | for-q, governance, lifecycle, hygiene |
| `8db7b1b1` | Governance - Team Qwrk Composition and Roles | 2026-02-15 | governance, team, for-q |
| `2180b740` | Milestone - Akara Joins Team Qwrk as Devil's Advocate of Aesthetics | 2026-02-15 | for-q, governance, team, milestone |
| `765dcdfc` | Decision - Phase 2B Governance Gate Locked | 2026-02-15 | for-q, governance, phase-2b, walk-boundary |
| `2478953e` | Decision - Phase 2 Governance Lock (Entropy, Narrative, Lifecycle) | 2026-02-15 | governance, phase-2, decision, for-q |
| `73584f66` | Core Governance Hardening - Canonical Authority & Deterministic Routing | 2026-02-15 | for-q, governance, core-doctrine, phase-boundary |
| `26efd3eb` | Decision - Rolling Memory Tier Model Staging Protocol | 2026-02-13 | for-q, governance, memory, tier-model |
| `91953c38` | Rolling Memory Architecture Requires Redesign | 2026-02-13 | for-q, rolling-memory, governance, architecture |
| `0f83b3d2` | Decision: Defer Codex Until QBeta Build Phase | 2026-02-13 | team, codex, decision, qbeta, for-q |
| `b78f43f3` | Phase 2 - QPM Lifecycle, Execution, and Structure Baseline | 2026-02-13 | qpm, phase-2, snapshot, governance, for-q |
| `137669a9` | Decision - Daily 8am Old Bull Planning Protocol | 2026-02-12 | for-q, daily-practice |
| `47784c6e` | Snapshot - Personal Alignment & Operating State (January Joel Bridge) | 2026-02-11 | for-q, personal-alignment, january-joel, life-snapshot |
| `d6e806f6` | Weekly Qwrk Bet - 2026-02-09 | 2026-02-09 | for-q, weekly-bet, execution |
| `e6d939f0` | Reference - Weekly Qwrk Stewardship Loop Doctrine | 2026-02-09 | for-q, governance, doctrine-pointer, weekly-stewardship |
| `cbf7624e` | Governance - Weekly Qwrk Stewardship Monday Rule | 2026-02-09 | for-q, governance, weekly-trigger, rolling-rule |
| `2bca3fa6` | Decision - Rolling Memory, Graduation, and RAG Roles | 2026-02-09 | for-q, governance, memory-architecture |
| `25e02429` | Governance - Qwrk World Invariants and Anti-Footgun Rule | 2026-02-08 | governance, for-q, world, safety |
| `3f854e00` | Snapshot - Forestry Governance v2: Multi-Forest Authority & Scoped Heads | 2026-02-08 | forestry, governance, multi-forest, for-q |
| `54f24c00` | Governance Model - Qwrk Forestry (Growth Without Premature Commitment) | 2026-02-08 | for-q, governance, forestry, growth-model |
| `5ad0db26` | Governance - QX Naming Convention Locked | 2026-02-08 | for-q, governance, naming, qx, execution |
| `49881324` | Active Book Context - The 5 Levels of Leadership | 2026-02-08 | for-q, active-context, active-book, book-maxwell, book-leadership |
| `48cee713` | Governance - Qwrk Prime Naming + ERP Direction | 2026-02-08 | for-q, governance, qwrk-prime, erp |
| `4b53b34f` | Governance - Official System Names QAlpha and QBeta | 2026-02-07 | governance, naming, for-q |
| `a52f402e` | Active Book Context - The Hunt for Red October | 2026-02-05 | for-q, active-context, active-book, book:red-october |
| `687c4439` | Governance - External Ideation Collaborator: Manus AI | 2026-02-05 | governance, collaboration, ideation, external, for-q |
| `6b0b1bf4` | Governance Lock - Tier A Memory Compaction Protocol v1 | 2026-02-05 | governance, memory-management, for-q, tier-a, compaction |
| `271046d8` | Governance Rule - Snapshots at Sapling to Tree Transition (Non-Exclusive) | 2026-02-05 | governance, lifecycle, snapshots, for-q |

---

## Section C: Archived / Compacted References

*Compacted 2026-02-17 — Strategic compaction of 8 historical milestone/bug confirmation snapshots.*

| artifact_id | Title | Compacted |
|-------------|-------|-----------|
| `8d1da623` | BUG-003 Closed - Hydration Gate Validation Complete | 2026-02-17 |
| `d976fb52` | BUG-026 Resolved - Gateway v48 Selector Normalization Fix | 2026-02-17 |
| `e62796da` | KGB Verification - BUG-017 Universal Tag Updates Deployed and Verified | 2026-02-17 |
| `a45705ec` | Snapshot - T15 Complete: for-q Rolling Memory MVP (9/9 Artifacts Seeded) | 2026-02-17 |
| `71dbe741` | DDL Refresh v2 - Live Schema Verified and Audit Findings Resolved | 2026-02-17 |
| `0caf807a` | Kernel v1 Security Hardening Complete - RLS + search_path | 2026-02-17 |
| `8e6ab823` | Snapshot - Gateway ACL Pause (Env Access Block) | 2026-02-17 |
| `471d3946` | Phase 2B Walk - Hydration Stabilization Complete (Pre-Update Surface) | 2026-02-17 |

---

## Regeneration Notes

- **Previous state:** 2026-02-19 sync (55 Tier A, 63 DB)
- **Operation:** Sync only — 4 new entries added, no compaction
- **New entries:** `13243170` (Multi-User Restart Architecture milestone), `02ce2a6c` (T41 closure — Update v12), `2b9164f3` (Public Beta Definition — Restart-Only), `bd7e1270` (Constellation Architecture — 6-layer model)
- **All 4 classified as Rotating Shell** — no new Section A constraints
- **Total Protected Core:** 8 (unchanged)
- **Total Rotating Shell:** 51 (was 47, +4 sync)
- **Total Tier A:** 59
- **Total in DB:** 67
- **Compaction status:** OVER THRESHOLD (59 >= 50) — deferred by user (strategic compaction planned for weekend, 7th consecutive deferral)
