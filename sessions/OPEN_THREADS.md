# Open Threads

> **Single source of truth for unresolved work across sessions.**
>
> Updated at session end. Read at session start.
>
> **Structure:** Active Surface (session-start default) → Cold Archive (on-demand) → On Hold → Closed
>
> **Last restructured:** 2026-03-24 (v27 cognitive load reduction). Pre-restructure snapshot: `sessions/Archive/OPEN_THREADS__pre-restructure__2026-03-24.md`

## Active Surface

> Threads with momentum, active bugs, or clear next actions. This is the default session-start view.
>
> **`Last Touch`** = session number where thread was last worked or discussed. Prevents zombie drift.

| ID | Thread | Priority | Last Touch | Status | Notes |
|----|--------|----------|------------|--------|-------|
| T140 | ~~Gateway Content Field Update Path~~ | Low | 124 | **COMPLETE** | Moved to Closed. |
| T160 | ~~Canonical v5 — T140 Content Update Section~~ | Low | 124 | **COMPLETE** | Moved to Closed. |
| T159 | Non-Prime Pack Propagation Sprint | Medium | 115 | PARTIAL | **AKARA AT PARITY (session 115).** SI v1.3→v1.4 (T140 pointer, fast-capture, person type). IP Index v2→v3 (Person pack added, WORKFLOW_PATTERNS removed). Person Save Capability Boundary IP v1 created. Joel also added Feedback Snapshot section + pack count bump. Remaining: BlaggLife SI alignment, Q@W SI alignment, Greg SI alignment, Messaging v2.2 resolution, QPM v1.2 propagation. Restart: `79b1a02a`. |
| T167 | Compliance-to-Enforcement Hardening Initiative | High | 121 | 2 TREES, 1 SAPLING | **Tree A: Response & Error Integrity** (`20d27f2d`, certified `e35be5af`). Save v49, Update T140 v2, Gateway v4. Gateway passthrough enforced, dual-shaping eliminated. **Tree B: Gateway Strict Mode** (`8a937ffd`, certified `3f8e5052`). Save v50. Extension allowlists, empty object rejection, for-q auto-injection, execution_status default, parent requirement, twig completeness. **Sapling C: Architectural Enforcement** (`459fd517`) — design-first, not yet implemented. Seed: `fb5bccd0`. Subsumes T113/T114. |
| T118 | parent_artifact_id Update Path | High | 081 | BLOCKED | **BLOCKED ON DEBUG.** n8n import of Update v9 may not have applied Normalize_Request code change. Joel must verify in n8n UI. Prime=v67 (patched), 4 other gateways unpatched. |
| T145 | Qwrk Beta User Provisioning & Onboarding | High | 106 | IN PROGRESS | **SAPLING — TEACHING LAYER LOCKED.** Joel needs to: (1) fill credential placeholder in Akazanar Qx/QSB, (2) upload beta IPs to ChatGPT. Tree criteria defined. |
| T152 | Fix Akara Gateway Access | High | 107 | PARTIAL | **REGULAR QX FIXED — BETA QX STILL BLOCKED.** Beta Qx needs KNOWN_WORKSPACES update for Akara workspace. |
| T164 | Seed Pod — Portable Idea Primitive (Move 1) | High | 114 | WSY GATE ACTIVE | **WSY Review Gate (first use).** Source: `4c536ef7`. WSY Gate: `09df42bf`. Decision: `3b1bdb03`. Restart: `4b37da12` (supersedes `4f1117ac`). Waiting for WSY-complete snapshot from Q+Manus. |
| T165 | Qwrk Update Versioning System | High | 114c | NOT STARTED | **Design discussion with Q pending.** Twigs: `f0786cad`, `09254a0d`. Restart: pending save. No version scheme exists — Q heads cannot answer "what's new?" after deployments. Triggered by live Akara update today. |
| T150 | Person Artifact Type — Implementation | Medium | 114 | IN PROGRESS | **BRANCHES 1-3 COMPLETE.** DDL v2.10, Save v47 deployed (v46→v47: communication_style bug fix). Person Save Capability Boundary IP v1 created. NEXT: Branch 4 (Retrieval & Behavior) → 5 → 6. Source: `f3505fdf`. |
| T103 | Command Center Limb | Medium | 076 | IN PROGRESS | CmdCtr limb `b00fc252`. Blocked by Branch Closure Protocol: 6 child twigs must complete. |
| T127 | Qwrk Exploratory GPT | Medium | 091 | IN PROGRESS | Demo proxy operational, 47/47 tests PASS, auth added. Source: `f83ca27c`. |
| T22 | Frita Voice — WALK Identity-First | Medium | 080 | TREE | Active enhancement. 10DLC pending (leaf `8a42f845`). |
| T121 | Upload Instruction Packs to ChatGPT | Medium | 105 | PARTIAL | Akara files ready, Greg deferred. QPM Build Process IP still needed for Q@W, BlaggLife, Greg. |
| T123 | Messaging Subsystem — QPM Execution | Low | 124 | MVP COMPLETE | **Session 123:** Calendar Event v2 deployed (recurrence RRULE, attendee fix, sendUpdates, timezone). Google Meet leaf `1465d007` created. Recurrence leaf `659817a9` complete. 1 future leaf open (file attachments `3a7ad2ba`). Multi-forest rollout: BlaggLife + Q@W + Akara done. Greg remaining. |
| T126 | Akara/Greg Capability Parity | Medium | 105 | PARTIAL | Akara complete. Greg deferred until after onboarding. |
| T88 | ~~Preserve Spine Fields During Extension-Only Updates~~ | Medium | 123 | **COMPLETE** | Moved to Closed. |
| T171 | ~~Destructive Operation Safety — 3-Layer Defense Model~~ | High | 124 | **COMPLETE** | Moved to Closed. |
| T111 | Gateway execution_status Update Path | Medium | 074 | NOT STARTED | No Gateway route for `execution_status` updates. Needed for QPM Phase 6. Workaround: direct SQL. |
| T113 | ~~Audit Gateway Response Shapers~~ | Medium | 123 | **COMPLETE** | Moved to Closed. |
| T114 | Mobile Gateway Silent Failures | Medium | 076 | NOT STARTED | Mobile console returns silent failures. Related to T113. |
| T117 | Menu Mode Journal Tag Update Failure | Medium | 080 | NOT STARTED | Bug — 5-session carry-forward. Source: `7e1aec02`. |
| T133 | ~~Gateway UPDATE Failure — Save Crashes During Merge~~ | Medium | 124 | **CLOSED** | Moved to Closed. |
| T141 | Reset the Board — Re-Entry & Loose Thread Sweep | Medium | — | NOT STARTED | Brain dump all loose threads, categorize, pick 3 re-entry targets. Source: `9aac2d90`. |
| T144 | Lifecycle Alignment Guardrail | Medium | 099 | SEED | Spine/extension lifecycle alignment enforcement. Seed: `eae05a4a`. |
| T166 | ~~Navigation Snapshot Required for Sapling Hydration~~ | Medium | 124 | **COMPLETE** | Moved to Closed. |
| T167 | Artifact-Based Handoff Lane (Q ↔ CC) | Medium | 117 | MVP PILOT READY | Protocol doc: `docs/design/Design__Artifact_Handoff_Protocol__v1.md`. CLAUDE.md pointer added. Q-side IP: `Instruction_Pack__CC_Handoff_Lane__v1.md` (IP Index v11, 25 packs). Pilot #0 completed. Pattern: `3758dab9`. Handoffs: `aa3569fb`, `c44bdb00`. **NEXT:** Upload IP to ChatGPT, pick real thread for Pilot #1. |
| T168 | ~~Gateway Read Path Alignment (Query/List Response Consistency)~~ | Medium | 124 | **CLOSED** | Moved to Closed. |
| T169 | execution_status Update → HTTP 400 Investigation | Medium | 123 | PARTIAL — TRANSPORT FIXED | **Session 123: Transport fix applied.** `onError: continueRegularOutput` + `alwaysOutputData: true` added to both Update and Promote Execute Workflow nodes in Gateway v2. Data path gap remains: `execution_status` still not in Update Normalizer allowlist (T111). |
| T170 | ~~Cert Harness Governance Boundary — Protect Non-Test Artifacts~~ | Medium | 123 | **COMPLETE** | Moved to Closed. |
| T172 | Qwrk Operator Console — Web Product Surface | High | 125 | SAPLING — 3 BRANCHES | **Sapling:** `152d9c11`. Promoted seed→sapling 2026-04-01. CC built Phases 1–8 (scaffold→pattern standardization). 3 branches: **Core Console** (`d5781fab`, read/hydration, Phases 1–8 complete), **Topology Visualization** (`298a32bd`, 5 leaves scaffolded, not started), **Hosting & Deployment** (`af189c7d`, deployment plan leaf saved, auth blocker identified). Nav snapshot: `pending save`. Milestone v2: `cd4487d6`. NEXT: Joel decides Vercel vs self-hosted, auth approach. Duplicate leaf to clean up: `c1e2b0e8` (same as `d49b9124`). |
| T173 | Qwrk Website Strategic Planning | High | 125 | SAPLING — 7 BRANCHES | **FROM Q (for-cc).** Strategic planning for Qwrk.com — branding, architecture, onboarding, product surface. 7 branches scaffolded (all `not_started`). Promoted seed→sapling 2026-04-03. Overlaps T172 on hosting/auth. Source: `6742e12a`. Needs: design_spine, branch prioritization. |
| T175 | Salience Amplification Doctrine — Instruction Layer Transition | High | 125 | PLAN COMPLETE — READY FOR PHASE A | **Sapling:** `68b13f94`. 4 branches + 3 leaves. payload.build v1.1 CERTIFIED (9/9 tests, Gateway v2 deployed). **Full transition plan produced.** 4 phases: A (additive guidance, zero risk), B (prefer builder), C (deprecate manual), D (enforce intent-based). 12 affected artifacts mapped (Payload Discipline v4, QSB Format v3, Canonical v5.2, 5 SIs, CC write-payload, IP Index, Quick Ref, Person IP). ~70% of current instruction text is mechanical assembly — replaceable by builder. **Phase A is ready to execute immediately** (1 paragraph added to each SI). Nav snapshot v2: `pending save`. Branch 4: `4dd7b0f3` (Instruction Layer Transition). Leaf 2.1 spec: `eaf3c349` (implemented). Leaf 2.2 test suite: `73eceef3` (9/9 PASS). Leaf 2.3 drift guard: `6d0e996c`. |
| T174 | Guided PoV Experience (Chrome Side Panel) | High | 125 | BUILD IN PROGRESS | **Target: April 7 (Tuesday).** Sapling `112327f7` with 5 branches + 7 leaves. Schema v1 locked. **CC built:** Chrome extension scaffold (5 files, `guided-pov-extension/`), n8n workflow JSON (`PoV_Orchestrator_v1.json`, 19 nodes), scenario JSON v1 (6 steps). **NOT YET DONE:** n8n import, workflow activation, extension load, end-to-end test, scenario content refinement with Q. Q building refined scenario from screen recording. All files in `Multi-User Qwrk/.../Qwrk@Wrk/RitaPoV Experience/`. Workspace: Q@W. |

## Cold Archive

> Seeds, Phase 3+ items, deferred designs, and strategic captures. NOT scanned at session start.
>
> **28 threads.** Say "show cold archive" or reference a T-number to access.
>
> To promote a thread back to Active Surface, tell CC during any session.

| ID | Thread | Priority | Category | Notes |
|----|--------|----------|----------|-------|
| T24 | Multi-Forest Gateway Enablement | Medium | Stalled | 1 clone pending (Krista_Blagg), ACL enforcement paused. |
| T52 | Payload Contract Drift Guardrails | Medium | Planning locked | Implementation deferred. Unlock: Hardening Sprint + re-audit + T51. |
| T53 | Phase Boundary Doctrine Realignment | Medium | Planning locked | Unlock: T51 + Hardening Sprint + no competing mutations. |
| T58 | Deterministic Restart Contract v2 | Medium | Deferred | Priority 3 in roadmap. Source: `388b023e`. |
| T60 | Multi-Forest Architecture via LLM Project Isolation | Medium | Architecture | CC/LLM-level isolation design. Source: `0664d7ad`. |
| ~~T61~~ | ~~2025 Tax Prep & CPA Submission~~ | — | Closed | **Moved to Closed table.** |
| T66 | Phase 3 Type Registry Implementation Doctrine | Medium | Phase 3 seed | Source: `802b5eb1`. |
| T68 | Phase 2C Category/Subcategory Universal Classification | **High** | **SAPLING — ACTIVE** | 6 branches scaffolded, all `not_started`. Canonical plan: `32d88e45`. Nav snapshot: `c3819c41`. Ready for leaf creation (Branch 1 first). Source: `58667e8e`. |
| T78 | Classification Architecture Design | Medium | Design only | Category/subcategory model. Related: T68, T69. Source: `0325aa2c`. |
| T81 | Open Brain Substrate Under Qwrk | Medium | Strategic capture | Future: pgvector → semantic retrieval → MCP. Source: `73b7851f`. |
| T82 | Execution Ordering Model | Low | Phase 5 seed | Branch/leaf sequencing. Source: `30944fcb`. |
| T83 | Artifact Operational State Column | Medium | Phase 3 seed | New spine column. Source: `bdd57e37`. |
| T84 | Artifact Query Indexing Strategy | Medium | Phase 3-late seed | Source: `5ca2bbe1`. |
| T85 | Artifact Durability Model | Low | Phase 5 seed | Source: `cb446713`. |
| T86 | Lifecycle Force Archive Path | Low | Phase 5 seed | Source: `d1933171`. |
| T90 | CmdCtr Execution Readiness Engine | Medium | Seed | Source: `edb1a406`. |
| T91 | CmdCtr Project Health Monitor | Medium | Seed | Source: `315014e6`. |
| T92 | CmdCtr Design Integrity Scanner | Medium | Sapling (no activity) | Source: `542c2d25`. |
| T106 | Thin-Core Prompt + Instruction Director | Medium | Platform design | Source: `f00020b6`. |
| T109 | CmdCtr Chief of Staff Evolution | Medium | Phase 3 | Source: `45721910`. |
| T116 | Twig Incubation & Mother Tree Doctrine | Medium | Doctrine | Source: `ec801b27`. |
| ~~T124~~ | ~~Recurring Calendar Events~~ | — | Closed | **Moved to Closed table.** |
| T128 | Default Seed Content Lives on the Seed | Medium | Governance seed | Source: `b8cd7538`. |
| T129 | Qwrk Release Contract & Forest Seasoning | Medium | Seed | Source: `589b9f42`. |
| T130 | Qwrk v3 Autonomous System Concept | Medium | Seed | Source: `1733c477`. |
| T131 | Qwrk v2 Release Definition | Medium | Seed | Source: `70664f0c`. |
| T132 | Multi-User Feedback Capture via Snapshot | Medium | Decision | Source: `1f663eb1`. |
| T134 | Versioned Design Spine Architecture | Medium | Architecture seed | Source: `363164a5`. |
| T135 | QPM Active Execution Registry | Medium | Seed | Source: `55d061ef`. |
| T136 | QPM Active Execution Registry — Standard Pattern | Medium | Seed | Source: `3c38011a`. |
| T137 | Demo Qwrk Upgrade Requirements | Medium | Seed | Source: `ac51d703`. |
| T138 | QPM as AI-Driven Software Dev Framework | Medium | Seed | Source: `c61c6177`. |
| T139 | Multi-User Gateway & Workspace Resolution | Medium | Seed | Related to T122. Source: `e8bfcb89`. |
| T142 | Forest Map Doctrine — CmdCtr Topology | Medium | Governance seed | Source: `961c37b3`. |
| ~~T143~~ | ~~Decision — Twig Fast-Capture Pattern~~ | — | Closed | **Moved to Closed table.** |
| T146 | Snapshot-Triggered Upgrade Notifications | Medium | Seed | Source: `679f9f5d`. |
| T147 | Read-Only Gateway Layer | Medium | Late sapling | 5 actions scoped. Source: `199be114`. |
| T161 | Qwrk Monetization Sapling | Medium | Seed | **FROM Q (for-cc).** Initial structure + go-to-market direction. Source: `5a089e39`. |
| ~~T162~~ | ~~DIY Tax Preparation System~~ | — | Closed | **Moved to Closed table.** |
| T163 | Cognitive Exoskeleton Initiative | Medium | Paused | **FROM Q (for-cc).** Paused at sapling scaffold. Source: `f21579f3`. |


## On Hold

> Threads with valid work but intentionally paused. Not eligible for execution until explicitly unlocked.

| ID | Thread | Priority | Hold Reason |
|----|--------|----------|-------------|
| T28 | Rolling Memory Retention Redesign + for-q Enforcement | Medium | Already functional. Compaction deferred to 3M mode with Q. |
| T31 | 3M Governance Doctrine + Structural Trigger Registry | Medium | Abstraction risk. Zero shipping value right now. |
| T37 | Audit & Reattach — Mother Tree Topology Alignment | Medium | Audit task. Not urgent. |
| T40 | Q Personal Tag Instruction Update | Medium | Nice-to-have, not system critical. |
| T42 | Modes vs Lenses Distinction Architecture | Medium | Pure agent-architecture thinking. No shipping impact. |
| T73 | Refactor Q@W Domain Architecture (Forest vs Separate Workspace) | Medium | Option not agreed upon. No content/payload. Source: `c1cce3d1`. |
| T43 | Role Micro-Switch Lens Architecture | Medium | Pure agent-architecture thinking. No shipping impact. |
| T45 | Qwrk Public Beta — Restart-Only MVP | High | Explicitly deferred. Respect the lock. |

## Closed Threads

| ID | Thread | Closed | Resolution |
|----|--------|--------|------------|
| T165 | BUG: Person communication_style Corruption (Save Pipeline) | 2026-03-29 |
| T61 | 2025 Tax Prep & CPA Submission | 2026-03-29 | **COMPLETE.** Personal + TPS (Daisy's business) taxes filed for 2025. Seed `679fc921` never scaffolded — work driven by Q + Manus outside QPM. |
| T162 | DIY Tax Preparation System | 2026-03-29 | **CLOSED — SUBSUMED BY T61.** Tax filing complete. Source `1b754cd1` (soft-deleted). | **COMPLETE.** Malformed n8n expression in Save v46 DB_Insert_Person_Extension (field 21). Save v47 deployed, 6/6 TC PASS. 10 corrupted records remediated (8 test + 2 production NULLed). Production re-acquisition pending (Fran, Christian). Beta Gateway parity deferred. Bug intake: `c7bd3a1b`. Authorization: `7c81ad8d`. Closure: `4b7dcd76`. |
| T158 | Instruction Architecture Refactor — Root Compression + Payload Discipline Authority | 2026-03-25 | **COMPLETE.** SI v48→v49 (7,910→7,108 chars, 892 headroom). Payload Discipline v2→v3 (single payload construction authority). Quick Ref v5→v6 (absorbed Workflow Patterns). Pack count 21→20. Snapshot: `0ce5488b`. |
| T157 | Cross-Workspace Write Gate — Three-Layer Defense | 2026-03-25 | **COMPLETE.** SI v48 §CW Gate [LOCKED — INVIOLABLE], Instruction Pack v1, QSB executor.js runtime gate, profiles.js home_workspace_id + workspaceNames. Prime-first scope. |
| T156 | Cognitive Load Reduction — CLAUDE.md v27 + OPEN_THREADS Restructure | 2026-03-24 | **COMPLETE.** CLAUDE.md 1723→1156 lines (33% reduction). OPEN_THREADS split into Active Surface (21) + Cold Archive (37). Last Touch column added. |
| T155 | CmdCtr Daily Operating Loop — Session Start Integration | 2026-03-24 | **COMPLETE.** CmdCtr integrated into session start protocol. First snapshot saved. |
| T154 | Branch 4 Duplicate Leaf Cleanup — Soft-Delete Superseded Batch | 2026-03-24 | **COMPLETE.** 16 superseded Batch 1 leaves soft-deleted from Branch 4 (`f483df62`). Two passes (11 + 5). Tagged `superseded` + `duplicate-cleanup`. 16 canonical Batch 2 leaves verified. |
| T153 | Manus Project Files — Plan Reviewer Upgrade | 2026-03-24 | **COMPLETE.** 8-file package delivered. Manus upgraded to bounded plan sanity checker. |
| T151 | Decision — Progress Rollup Implementation Strategy | 2026-03-24 | **DECISION LOCKED.** Option B selected — use existing read patterns, defer dedicated endpoint. |
| T149 | Promote Atomicity Fix — Extension lifecycle_stage Sync | 2026-03-21 | **COMPLETE.** Promote v28 deployed to both gateways (Qwrk + Qwrk Beta). Atomic promote via `promote_artifact_lifecycle()` RPC function. Post-promote re-validation fixed. Build scripts: v26-v28a. Migration: `2026-03-21__promote_lifecycle_atomic__v1.sql`. |
| T148 | Beta SI Semantic Type Registry Drift | 2026-03-21 | **COMPLETE.** Corrected 6 invalid `semantic_type_id` values in Beta SI and Payload Discipline. |
| T125 | Instruction Pack Lookup Discipline Implementation | 2026-03-12 | **COMPLETE.** 6 twigs executed under sapling `c5707a3f`. Payload Lookup Mandate [LOCKED] in all 5 SIs, IP Index v2 (Trigger column), Payload Discipline v2 (preflight checklist). |
| T120 | SI Update — Extension Persistence Rule + Seed Planting Protocol | 2026-03-12 | **COMPLETE.** Extension Persistence Rule + Seed Planting Protocol shipped to all 5 workspace SIs. Related twig `ea25d6a0` (Unknown Extension Field Warning) remains open. |
| T79 | Build Mode Protocol v1 | 2026-03-12 | **COMPLETE — DELIVERED AS QPM BUILD PROCESS IP.** `Instruction_Pack__QPM_Build_Process__v1.md` shipped to Prime, Q@W, BlaggLife. Distilled from 8 governance snapshots (first QPM tree build). Covers 7-phase launch procedure, navigation snapshots, branch closure protocol, build governance rules, and extension guidance. Source seed: `262d805c`. |
| T115 | CC Skills Suite — 5 New Skills Built + PRDs | 2026-03-10 | **COMPLETE.** 5 skills deployed: /archive-file, /registry-refresh, /query-artifact, /cmdctr-briefing, /rolling-mem-sync. Plus /run-sql. 6 PRDs written, Manus-reviewed, executed, archived. |
| T110 | Q@W Feature Parity Sprint | 2026-03-09 | **COMPLETE.** 6-block parity sprint + workspace cleanup. 21 clean artifacts, Mother Tree intact, all governance operational. |
| T51 | Extension Update Surface Determinism | 2026-03-05 | **COMPLETE — CERTIFIED AND DEPLOYED.** |
| T74 | T51 Status — Extension Update Surface Not Implemented | 2026-03-05 | **CLOSED — ANSWERED BY T51 CLOSURE.** |
| T64 | Spine-Field Update Path for Non-Project Types | 2026-03-05 | **COMPLETE — DEPLOYED AND CERTIFIED.** |
| T77 | Q@W Gateway Broken State — QSB Route Debug | 2026-03-05 | **COMPLETE — Q@W OPERATIONAL.** |
| T30 | Design Sandbox Access Model (Akara Collaboration) | 2026-03-05 | **SUPERSEDED BY T24.** |
| T69 | Behavioral Role Layer — Revised Sapling Execution | 2026-03-04 | **COMPLETE — ALL PHASES DELIVERED.** |
| T70 | Walk Gap — Rollup Query Implementation | 2026-03-01 | **CERTIFIED.** |
| T71 | Walk Gap — Dependency Enforcement (Leaf-to-Leaf) | 2026-03-02 | **CERTIFIED.** |
| T76 | Surgical Stabilization Pass — B01 + C01 + B06 Fixes | 2026-03-01 | **COMPLETE.** |
| T75 | Save Response Envelope Integrity | 2026-03-01 | **COMPLETE.** |
| T72 | Save Workflow Deterministic Audit | 2026-02-28 | **COMPLETE — CREATE-ONLY ENFORCEMENT DEPLOYED.** |
| T80 | Supabase Security Advisor Warnings | 2026-03-07 | **COMPLETE.** |
| T95 | workflow-ids.md Stale | 2026-03-07 | **COMPLETE.** |
| T96 | BUG: QSB Execute Button Stays Active | 2026-03-06 | **COMPLETE.** |
| T97 | write-payload Skill Bug | 2026-03-07 | **COMPLETE.** |
| T98 | Supabase MCP Server Activation | 2026-03-06 | **COMPLETE.** |
| T100 | CmdCtr Forest Scan Capability Build | 2026-03-07 | **COMPLETE.** |
| T101 | Address Supabase Security Issues First | 2026-03-07 | **CLOSED — SUBSUMED BY T80.** |
| T102 | Move Mother Tree Snapshot to Snapshots Branch | 2026-03-07 | **COMPLETE.** |
| T104 | Command Center Project -- Tree Status | 2026-03-07 | **CLOSED — ORPHAN DELETED.** |
| T105 | QSB Auto-Dismiss + Accomplishment Report | 2026-03-07 | **COMPLETE.** |
| T107 | Mobile Gateway Access — Phone Execution Surface | 2026-03-08 | **COMPLETE.** |
| T108 | Pre-Feb-1 Artifact Cleanup — Soft Delete Sweep | 2026-03-07 | **COMPLETE.** |
| T48 | Qwrk Prime — Restart IP + SI Update | 2026-03-11 | **CLOSED — SUBSUMED BY T58.** T58 (Deterministic Restart Contract v2) is broader scope and explicitly subsumes T48. Source: `388b023e`. |
| T49 | Version Invariant — Semantic Definition | 2026-03-11 | **CLOSED — OPTION B DEPLOYED.** Save/Promote/Update all increment version. Branch/limb/leaf version increment gap remains (minor, ad-hoc if needed). Contract seam finding covered by T52. |
| T59 | Gateway Resolve + Enhanced Search | 2026-03-11 | **CLOSED — SUPERSEDED.** CmdCtr + MCP covers CC-side. Discovery Playbook covers Q-side. Remaining value (Gateway search action) speculative. |
| T62 | Thorn: extension.payload Doc Audit | 2026-03-11 | **CLOSED — RESOLVED BY T69/T87.** Documentation sweeps fixed all extension examples across QR, SI, and Canonical docs. |
| T63 | Promote Rolling Registry to Tree | 2026-03-11 | **CLOSED — SOURCE ARTIFACT DELETED.** Original `c84c2aeb` soft-deleted 2026-03-08. Replacement `2ca3b6be` tagged deprecated. Feature operational via CLAUDE.md v20 `Registry refresh` command — no project artifact needed. |
| T67 | Thorn: TG Silent Error Response | 2026-03-11 | **CLOSED — MERGED INTO T114.** Same bug class as Mobile Gateway Silent Failures. Source `9e600927` referenced in T114. |
| T89 | Single-Query Tree Render | 2026-03-11 | **CLOSED — SUPERSEDED.** CmdCtr read-model covers CC-side. Remaining value (Gateway action) speculative, downgraded twice. |
| T122 | Unified Gateway Identity & Workspace Resolution | 2026-03-25 | **COMPLETE.** Tree promoted. v1 clones (Q@W, email_cal) decommissioned and archived. |
| T119 | Greg Onboarding | 2026-03-20 | **COMPLETE.** All infra deployed, walkthrough completed. |
| T87 | Qwrk Governance Ergonomics Correction | 2026-03-06 | **COMPLETE — ALL 8 DOCUMENTS DEPLOYED.** |
| T93 | Test Artifact Cleanup — Surgical Delete | 2026-03-06 | **COMPLETE.** |
| T46 | Journal Append — Governance Decision | 2026-03-06 | **CLOSED — DECISION LOCKED BY T87.** |
| T99 | QSB Auto-Paste Gateway Response Feature | 2026-03-06 | **COMPLETE.** |
| T3 | BUG-011 Telegram Tags | 2026-02-05 | **CLOSED.** |
| T17 | Active X Context + Rolling Memory Expansion | 2026-02-05 | **COMPLETE.** |
| T16 | Tier A Memory Compaction Design | 2026-02-05 | **COMPLETE.** |
| T15 | for-q Rolling Memory MVP | 2026-02-05 | **COMPLETE.** |
| T11 | CC Session Management Upgrade | 2026-02-04 | **COMPLETE.** |
| T10 | Execution Surface Awareness | 2026-02-04 | **COMPLETE.** |
| T7 | Chrome Extension + Gateway Auth | 2026-02-04 | **COMPLETE.** |
| T9 | BUG-020 instruction_pack artifact_id null | 2026-02-03 | **PARTIAL.** |
| T8 | BUG-019 Hardblock Regression | 2026-02-03 | **SUPERSEDED.** |
| T18 | BUG: FROM_STATE_MISSING in Promote | 2026-02-08 | **RESOLVED.** |
| T21 | BUG: Promote Response Plumbing | 2026-02-08 | **RESOLVED.** |
| T19 | BUG: artifact.list Tag Filter Ignored | 2026-02-08 | **RESOLVED.** |
| T20 | BUG: artifact.list Offset/Pagination Broken | 2026-02-08 | **RESOLVED.** |
| T4 | BUG-016 Promote Transition | 2026-02-17 | **FULLY RESOLVED.** |
| T6 | BUG-018 Update Creates Duplicate | 2026-02-08 | **RESOLVED.** |
| T23 | Partial Write Cleanup | 2026-02-08 | **CLOSED.** |
| T5 | BUG-017 Tags Update | 2026-02-08 | **RESOLVED.** |
| T26 | BUG: List Pagination Ignores Limit/Offset | 2026-02-11 | **RESOLVED.** |
| T1 | Phase 2 QPM Implementation | 2026-02-16 | **CLOSED.** |
| T29 | Phase 2B Foundation Migration Reconciliation Plan | 2026-02-16 | **CLOSED.** |
| T32 | Phase 2B Gateway Type Registry Expansion (Walk) | 2026-02-17 | **COMPLETE.** |
| T14 | Telegram Gateway Pipe | 2026-02-17 | **COMPLETE.** |
| T34 | Drift Reconciliation | 2026-02-17 | **COMPLETE.** |
| T35 | Telegram Surface Deprecation | 2026-02-17 | **COMPLETE.** |
| T38 | Surface Unification & Prompt Output Hardening | 2026-02-18 | **COMPLETE.** |
| T33 | Rolling Memory Compaction Execution | 2026-02-17 | **COMPLETE.** |
| T2 | Idempotency Implementation | 2026-02-19 | **CLOSED — STALE.** |
| T12 | Plan Mode Concept | 2026-02-19 | **CLOSED — PARKED.** |
| T13 | Qwrk Open Threads Tracking | 2026-02-19 | **CLOSED — IMPLEMENTED.** |
| T36 | Define for-cc Tag Protocol | 2026-02-19 | **COMPLETE.** |
| T39 | Parallel Workstream Governance Protocol | 2026-02-19 | **COMPLETE.** |
| T44 | Phase Classification (Image Storage + RAG) | 2026-02-19 | **CLOSED — DECISION LOCKED.** |
| T41 | BUG: Gateway Tag Update Blocked | 2026-02-20 | **COMPLETE.** |
| T47 | Multi-User Restart Architecture | 2026-02-19 | **COMPLETE.** |
| T57 | Phase 2C Kernel Certification Session | 2026-02-22 | **COMPLETE.** |
| T56 | Gateway v58 + Save v37 Deployment | 2026-02-22 | **RESOLVED.** |
| T54 | Deploy Deterministic Hardening Sprint | 2026-02-22 | **CLOSED.** |
| T55 | Coordinated Deployment | 2026-02-22 | **CLOSED — SUBSUMED BY T54.** |
| T50 | Save Priority Default Restoration | 2026-02-20 | **CLOSED.** |
| T65 | QSB Prime Sidebar | 2026-02-24 | **COMPLETE.** |
| T27 | DDL Hygiene Pass | 2026-02-19 | **CLOSED.** |
| T25 | CC Persistent Memory Architecture | 2026-02-19 | **COMPLETE.** |

---

## Maintenance Rules

1. **At session end:** Update this file before writing `LATEST_END_SESSION.md`
2. **Adding threads:** Assign next ID, add to Active Surface with `Last Touch` = current session number
3. **Closing threads:** Move to Closed Threads table with resolution note
4. **Priority levels:** High / Medium / Low
5. **Blocked threads:** Note blocker in Status/Notes column
6. **Last Touch:** Update session number when a thread is worked or meaningfully discussed
7. **Cold Archive promotion:** Joel says "pick up T-number" → move from Cold Archive to Active Surface
8. **Active Surface demotion:** At session end, threads untouched for 10+ sessions with no momentum may be proposed for Cold Archive (Joel confirms)
9. **New for-cc items:** Always enter Active Surface first. Demote to Cold Archive only at session end if seed/Phase 3+
