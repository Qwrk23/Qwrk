# Open Threads

> **Single source of truth for unresolved work across sessions.**
>
> Updated at session end. Read at session start.

## Active Threads

| ID | Thread | Opened | Origin Session | Priority | Notes |
|----|--------|--------|----------------|----------|-------|
| T22 | Frita Voice — WALK Identity-First | 2026-02-07 | `2026-02-07__002` | Medium | **TREE — ACTIVE ENHANCEMENT.** All 5 workflows operational, tree promoted (`df65ba2f`). Session 080: Added employee ID gather step to password reset path — voice asks for employee ID (any input passes), then proceeds with reset + SMS. Handle v5 updated (Step Check? IF node + TwiML Ask Employee ID node). Tested and confirmed working. 10DLC pending (leaf `8a42f845`). |
| T24 | Multi-Forest Gateway Enablement | 2026-02-08 | `2026-02-08__006` | Medium | **Q@W + BLAGGLIFE + AKARA ACTIVATED.** Q@W: v59 T69-compliant (session 047/049). BlaggLife: Full deployment (session 056) — Supabase identity (auth user `afa5845c`, qxb_user `81609ab7`, workspace_user `daa9e5be`, ACL `a841ad59`), Gateway clone (`NQxb_Gateway_v1_BlaggLife`, principal `qwrk-gw-blagglife`), 7 ChatGPT project files (SI v1.1 + 6 instruction packs), Chrome Extension profile, first artifact saved (`fe82369b`). Coach Qwrk — Family Manager MVP. **Remaining:** 1 clone pending (Krista_Blagg). Greg clone COMPLETE (session 081) -- see T119. ACL enforcement still paused. |
| T48 | Qwrk Prime — Restart Instruction Pack + System Instructions Update | 2026-02-20 | current | Medium | **NOT STARTED.** T47 delivered restart semantics for Q@Work only. Prime needs: (1) Restart instruction pack adapted for Prime context (re-anchor is Prime-only), (2) Prime system instructions updated with restart command routing + restart artifact schema. Reference: T47 implementation, `Multi-User Qwrk/04_Instruction_Packs/Restart_Semantics_v1.md`. |
| T49 | Version Invariant — Semantic Definition and Centralization Strategy | 2026-02-20 | `2026-02-20__007` | Medium | **OPTION B IMPLEMENTED — DEPLOYED AND VERIFIED.** Version increment added to Promote (DB_Update_Lifecycle +1 field) and Update extension/project path (2 new nodes: Prepare_Spine_Version_Increment → DB_Increment_Spine_Version). All 3 modified workflows imported to n8n and tested. Promote verified live: version 3→4 on sapling→tree, QPM guard fires first, no double-writes. Branch/limb/leaf blocked by T51 (no DB write exists). **Additional finding:** Gateway↔SubWorkflow contract seam — no formal spec of what Gateway outputs vs what sub-workflows expect. Same bug class as T26/BUG-015. To be addressed when T49 centralization work continues. Coverage: Save (DB DEFAULT 1), tags (pre-existing), extension/project (+1 NEW), Promote (+1 NEW), branch/limb/leaf (BLOCKED by T51). Restart snapshot `09e8312b` (for-cc) reviewed 2026-02-21 — no new action items, all next_actions map to T49/T51/T52. |
| T52 | Payload Contract Drift Guardrails (Planning Only) | 2026-02-21 | `2026-02-21__010` | Medium | **PLANNING COMPLETE — GOVERNANCE LOCKED.** Design document delivered: `docs/design/Design__Payload_Contract_Drift_Guardrails__v1.md` (v1.1). 23 authority surfaces inventoried, 15 drift vectors mapped, 5 guardrails designed (A: Version Bump Protocol, B: Contract Regression Checklist, C: Pre-Activation Ritual, D: Drift Detection, E: Pointer Discipline). All 4 open questions resolved 2026-02-21. CLAUDE.md step 7 approved for separate governance edit. **Implementation deferred** — unlock: Hardening Sprint complete + re-audit PASS + T51 resolved. |
| T53 | Phase Boundary Doctrine Realignment (Planning Only) | 2026-02-21 | current | Medium | **PLANNING ONLY — PLAN APPROVED.** Reconcile Amendment 4 (Crawl-only type scope) with actual system state (Walk types active since `2a8911ef` on 2026-02-16). Deliverables: (1) Phase status declaration — "Crawl-to-Walk Transition (Phase 2/2B Hybrid)", (2) Amendment 4 v2 draft — three-layer enforcement model (DDL/Registry/Gateway), grass/thorn reclassified "Unphased", forest/thicket/flower "Reserved", (3) Registry enforcement diagram, (4) Risk analysis (3 HIGH risks from misalignment), (5) Future type activation policy (8-step prerequisites), (6) Governance snapshot spec (extends `2a8911ef`). Plan file: `~/.claude/plans/enchanted-juggling-gray.md`. **Unlock condition:** T51 resolved + Deterministic Hardening Sprint complete + no competing structural mutations. |
| T58 | **FROM Q (for-cc).** Deterministic Restart Contract v2 | 2026-02-22 | `2026-02-22__020` | Medium | **NOT STARTED.** Restart contract redesign. Broader scope than T48 (Prime restart IP only). Recommended as priority 3 in forward roadmap (after Phase 2 close + Walk gaps). May subsume T48 depending on scope decision. Source: `388b023e`. |
| T59 | **FROM Q (for-cc).** Gateway Resolve + Enhanced Search Capability | 2026-02-22 | `2026-02-22__020` | Medium | **NOT STARTED — SAPLING. DOWNGRADED.** CmdCtr + MCP covers CC-side search. Remaining value: Q-facing Gateway action for ChatGPT direct search without CC intermediation. Source: `8ffbda90`. |
| T60 | **FROM Q (for-cc).** Multi-Forest Architecture via LLM Project Isolation | 2026-02-22 | `2026-02-22__020` | Medium | **NOT STARTED.** Architecture for multi-forest isolation via LLM project boundaries (e.g., Claude Code projects per forest). Different angle from T24 (Gateway clones) — this is about CC/LLM-level isolation. Recently updated (v2). Source: `0664d7ad`. |
| T61 | **FROM Q (for-cc).** 2025 Tax Prep & CPA Submission | 2026-02-22 | `2026-02-22__020` | Medium | **NOT STARTED.** Personal operations project, priority 2. Not Qwrk build work — personal task management tracked through Qwrk. Source: `679fc921`. |
| T62 | **FROM Q (for-cc).** Thorn: extension.payload Documentation Audit | 2026-02-22 | `2026-02-22__020` | Medium | **NOT STARTED.** Snapshot save failed due to missing `extension.payload` — validation correctly rejected but indicates documentation gap or Q behavior drift. CC review prompt: audit all docs in `phase1.5-chat-gateway/Chat Project Files/` for `extension.payload` mandatory-on-INSERT documentation. Provide file references and corrections. Source: `344f292f`. |
| T63 | **FROM Q (for-cc).** Promote Rolling Registry to Tree | 2026-02-22 | `2026-02-22__023` | Low | **IN USE — PROMOTE TO TREE.** Rolling Registry feature is fully operational (CLAUDE.md v20, `Registry refresh` command). Project artifact `c84c2aeb` is seed — needs promote seed→sapling→tree to reflect implemented state. Source: `c84c2aeb`. |
| T66 | **FROM Q (for-cc).** Phase 3 Type Registry Implementation Doctrine | 2026-02-24 | `2026-02-23__025` | Medium | **NOT STARTED.** Seed-stage architecture for Phase 3 type registry implementation. Source: `802b5eb1`. Sub-item: App Build Process Contract Template (`a6ae6d8d`) — Q drafting seed skeleton with 7 sections, 2 open refinement questions (commercial Economic Model Snapshot, enterprise RLS validation artifact). Folded from deferred for-cc item (session 041). |
| T67 | **FROM Q (for-cc).** Thorn: TG Silent Error Response Investigation | 2026-02-24 | `2026-02-23__025` | Medium | **NOT STARTED.** TG (Telegram) returning silent errors — needs investigation of error handling path. Source: `9e600927`. |
| T68 | **FROM Q (for-cc).** Phase 2C Behavioral Type System + Category Layer | 2026-02-24 | `2026-02-23__025` | Medium | **NOT STARTED.** Schema design for behavioral type system and category layer. Phase 2C scope. Source: `58667e8e`. |
| T73 | **FROM Q (for-cc).** Refactor Q@W Domain Architecture (Forest vs Separate Workspace) | 2026-02-28 | `2026-02-28__032` | Medium | **OPTION — NOT YET AGREED UPON.** Seed-stage architecture question: should Q@Work be a domain within the main forest or a separate workspace? Related to T24 (Multi-Forest Gateway Enablement) and T60 (LLM Project Isolation) but distinct — this is about the Q@W domain model itself. No content/payload yet. Approach is an option under consideration, not a committed direction. Source: `c1cce3d1`. |
| T78 | **FROM Q (for-cc).** Classification Architecture Design + Post-T70 Execution | 2026-03-01 | `2026-03-01__038` | Medium | **NOT STARTED — DESIGN ONLY. T70 BLOCKER RESOLVED.** Define category/subcategory model for artifacts. Key decisions: spine vs extension, nullable, controlled vocabulary, type-scoped vs global, relationship to tags. Constraints: no schema/workflow changes until design locked. Related to T68 (Behavioral Type System), T69 (Behavioral Role Layer). Design seed: `0325aa2c`. Execution seed: `a21c0b63` (merged — implementation stub for post-design). Q restart prompt provides full scope. |
| T79 | **FROM Q (for-cc).** Build Mode Protocol v1 (Post-T70 Governance) | 2026-03-01 | `2026-03-01__038` | Medium | **NOT STARTED. T70 NOW CERTIFIED — READY TO DRAFT.** Formalize build governance for Walk phase. Draft `BUILD_MODE_PROTOCOL_v1` after T70 certification. T64 deployed, T70 certified, T71 certified. Project seed: `262d805c`. Restart: `441ebf52`. |
| T81 | **FROM Q (for-cc).** Strategic Direction — Open Brain Substrate Under Qwrk | 2026-03-05 | `2026-03-05__051` | Medium | **NOT STARTED — STRATEGIC CAPTURE.** Decision: layer Open Brain (embeddings/RAG/MCP) beneath Qwrk governance spine. 4-phase roadmap: pgvector → semantic retrieval → MCP read → MCP write. Read-first, approval-gated writes. Captured for future, not active build. Source: `73b7851f`. |
| T82 | **FROM Q (for-cc).** Execution Ordering Model (Branch + Leaf Sequence) | 2026-03-05 | `2026-03-05__051` | Low | **NOT STARTED — PHASE 5.** Seed for branch/leaf execution sequencing within QPM. Source: `30944fcb`. |
| T83 | **FROM Q (for-cc).** Artifact Operational State Column | 2026-03-05 | `2026-03-05__051` | Medium | **NOT STARTED.** Seed — new spine column for operational state tracking. Phase 3 scope. Source: `bdd57e37`. |
| T84 | **FROM Q (for-cc).** Artifact Query Indexing Strategy | 2026-03-05 | `2026-03-05__051` | Medium | **NOT STARTED.** Seed — query performance and indexing design. Phase 3-late scope. Source: `5ca2bbe1`. |
| T85 | **FROM Q (for-cc).** Artifact Durability Model (Ephemeral vs Durable) | 2026-03-05 | `2026-03-05__051` | Low | **NOT STARTED — PHASE 5.** Seed for artifact durability classification. Source: `cb446713`. |
| T86 | **FROM Q (for-cc).** Lifecycle Force Archive Path | 2026-03-05 | `2026-03-05__051` | Low | **NOT STARTED — PHASE 5.** Seed for forced archive lifecycle transition. Source: `d1933171`. |
| T88 | Preserve Spine Fields During Extension-Only Updates | 2026-03-06 | `2026-03-06__052` | Medium | **NOT STARTED — TECHNICAL DEBT.** Extension-only updates on project artifacts clear spine `summary` field. Pre-existing behavior, discovered during T87 Task 4 certification. Source: T87 certification snapshot `20389ab0`. |
| T89 | **FROM Q (for-cc).** Single-Query Tree Render Capability | 2026-03-06 | `2026-03-06__054` | Medium | **NOT STARTED — SEED. DOWNGRADED from P1.** CmdCtr read-model tables cover CC-side. Remaining value: Gateway-level action for Q/multi-user access. Source: `b5b374c3`. |
| T90 | **FROM Q (for-cc).** Command Center Execution Readiness Engine | 2026-03-06 | `2026-03-06__054` | Medium | **NOT STARTED — SEED.** Source: `edb1a406`. |
| T91 | **FROM Q (for-cc).** Command Center Project Health Monitor | 2026-03-06 | `2026-03-06__054` | Medium | **NOT STARTED — SEED.** Source: `315014e6`. |
| T92 | **FROM Q (for-cc).** Command Center Design Integrity Scanner | 2026-03-06 | `2026-03-06__054` | Medium | **NOT STARTED — SAPLING.** Source: `542c2d25`. |
| T103 | **FROM Q (for-cc).** Command Center Limb -- Structural Artifact | 2026-03-06 | `2026-03-06__059` | Medium | **IN PROGRESS.** CmdCtr limb `b00fc252` re-parented from Product to Platform branch (session 060). Blocked by Branch Closure Protocol: 6 child twigs must complete execution lifecycle before limb can close. Session 076: Forest Topology section added to CmdCtr briefing (leaf `454de01d` under Strategic Operator Briefing twig `6b59a677`). Governance snapshot: `34f74800`. Source: `b00fc252`. |
| T106 | **FROM Q (for-cc).** Thin-Core Prompt + Instruction Director Boot Model | 2026-03-07 | `2026-03-07__060` | Medium | **NOT STARTED.** Platform prompt architecture — instruction system design. Source: `f00020b6`. |
| T109 | **FROM Q (for-cc).** CmdCtr Chief of Staff Evolution | 2026-03-07 | `2026-03-07__066` | Medium | **NOT STARTED.** Phase 3: evolve CmdCtr beyond observability into operational intelligence. Source: `45721910`. |
| T111 | Gateway execution_status Update Path | 2026-03-09 | `2026-03-09__074` | Medium | **NOT STARTED.** Gateway has no action to update `execution_status` on leaves/branches/limbs. Column exists (CHECK enforced: not_started, in_progress, blocked, complete) but no Gateway route handles it. Discovered during first QPM leaf execution. Workaround: direct SQL. Needed for QPM canon Phase 6 (CC marks leaves in_progress/complete via Gateway). |
| T113 | Audit Gateway Response Shapers for Error-Swallowing Bug | 2026-03-09 | `2026-03-09__076` | Medium | **NOT STARTED.** Shape_List_Response was swallowing sub-workflow errors (fixed in session 074). Same bug pattern likely exists in Shape_Save_Response, Shape_Update_Response, Shape_Promote_Response. Audit all 4 gateway response shapers across all 4 gateways (QP, Q@W, BlaggLife, Akara). |
| T114 | Mobile Gateway Silent Failures | 2026-03-09 | `2026-03-09__076` | Medium | **NOT STARTED.** Mobile console returns silent failures (no error displayed to user). Related to T113 (response shaper error-swallowing) and T67 (TG silent errors). Needs investigation of error visibility on mobile execution surface. |
| T116 | **FROM Q (for-cc).** Twig Incubation and Mother Tree Feature Topology Doctrine | 2026-03-10 | `2026-03-10__080` | Medium | **NOT STARTED.** Doctrine clarification on twig incubation rules and Mother Tree feature topology. Source: `ec801b27`. |
| T117 | **FROM Q (for-cc).** Menu Mode Journal Tag Update Failure | 2026-03-10 | `2026-03-10__080` | Medium | **NOT STARTED.** Menu mode journal tag update failing — needs investigation. Carry-forward from 5 sessions. Source: `7e1aec02`. |
| T118 | parent_artifact_id Update Path -- Fix + Multi-Gateway Rollout | 2026-03-10 | `2026-03-10__081` | High | **IN PROGRESS -- BLOCKED ON DEBUG.** Enable `parent_artifact_id` as mutable spine field in `artifact.update`. Three-layer fix: (1) Gateway Gatekeeper -- DONE on Prime only (v67, `spineFieldCandidates` + `spine_fields` builder patched), (2) Update Normalize_Request + Compute_Mixed -- DONE in exported JSON (v9), (3) Check_Mutability_Rules -- code correct (section 2b returns early for spine_only before journal guard). **BUG:** Both journal and project tests fail with `hasSpineFields=false`. Journal: `JOURNAL_INSERT_ONLY`. Project: `VALIDATION_ERROR: No updateable fields in extension`. **ROOT CAUSE:** n8n import of Update v9 likely did not apply Normalize_Request code change. **RESUME:** Joel must verify in n8n UI: open Update sub-workflow > Normalize_Request node > search for `parent_artifact_id` in JS code. If absent, re-import v9. If present, need deeper data pipeline debug. **GATEWAY DIVERGENCE:** Prime=v67 (patched). Q@W/BlaggLife/Akara/Greg=prior version (unpatched). Once Prime works, patch all 4. **Files:** `workflows/NQxb_Gateway_v1 (67).json`, `workflows/NQxb_Artifact_Update_v1__T69 (9).json`. **Test payloads:** Journal: `artifact_id=9570cf84, parent=8ffbda90`. Project: `artifact_id=8ffbda90, parent=dec0597b`. Workspace: `be0d3a48`. |
| T119 | Greg Onboarding -- Sunday 2026-03-15 | 2026-03-10 | `2026-03-10__081` | High | **READY FOR ONBOARDING.** All infra complete: Supabase identity (workspace `970d0df8`, auth `1bad96c8`, qxb_user `07c097ad`, ws_user `5fe84de0`, ACL `c878f29a`, principal `qwrk-gw-greg`). Gateway clone deployed. Chrome extensions built (QX+QSB). 7 ChatGPT instruction files. Greg profile added to Joel QX+QSB for testing. Test saves confirmed (journal `aa71c995`, project `0c76208c`). Target: Sunday 2026-03-15. |
| T120 | SI Update — Extension Persistence Rule + Seed Planting Protocol | 2026-03-10 | `2026-03-10__082` | High | **APPROVED — READY TO EXECUTE.** Two additions to all 5 workspace SIs, shipping together. **(1) Extension Persistence Rule:** "Only listed fields are persisted per type — unknown keys are silently dropped. To link artifacts, use `parent_artifact_id` (top-level)." Discovered via Greg onboarding (session 081): `journal_source_id` passed in project extension was silently dropped. DDL confirmed: `qxb_artifact_project` has strict column schema (lifecycle_stage, operational_state, state_reason, design_spine). **(2) Seed Planting Protocol:** Journal-first genesis pattern. Save companion journal FIRST → retrieve artifact_id → save seed project with `parent_artifact_id` = journal_id. Anti-pattern: creating unlinked seed then attempting post-hoc topology repair (Gateway does not support retroactive `parent_artifact_id` assignment via update — **blocked by T118**). **DEPENDENCY:** T118 (parent_artifact_id Update Path) blocked on n8n debug. Extension persistence rule can ship independently. **5 FILES:** (1) Prime: `Qwrk_SYSTEM_INSTRUCTIONS_2_5_41.md` after line 72, (2) Greg: `qwrk_greg_system_instructions_v1.md` after line 81, (3) Akara: `qwrk_akara_system_instructions_v_1.md` after line 80, (4) BlaggLife: `qwrk_blagglife_system_instructions_v_1.md` after line 82, (5) Q@W: `qwrk_work_system_instructions_v_2.md` after line 46. **Related twig:** `ea25d6a0` (Gateway Enhancement — Unknown Extension Field Warning, priority 4). |


## On Hold

> Threads with valid work but intentionally paused. Not eligible for execution until explicitly unlocked.

| ID | Thread | Priority | Hold Reason |
|----|--------|----------|-------------|
| T28 | Rolling Memory Retention Redesign + for-q Enforcement | Medium | Already functional. Compaction deferred to 3M mode with Q. |
| T31 | 3M Governance Doctrine + Structural Trigger Registry | Medium | Abstraction risk. Zero shipping value right now. |
| T37 | Audit & Reattach — Mother Tree Topology Alignment | Medium | Audit task. Not urgent. |
| T40 | Q Personal Tag Instruction Update | Medium | Nice-to-have, not system critical. |
| T42 | Modes vs Lenses Distinction Architecture | Medium | Pure agent-architecture thinking. No shipping impact. |
| T43 | Role Micro-Switch Lens Architecture | Medium | Pure agent-architecture thinking. No shipping impact. |
| T45 | Qwrk Public Beta — Restart-Only MVP | High | Explicitly deferred. Respect the lock. |

## Closed Threads

| ID | Thread | Closed | Resolution |
|----|--------|--------|------------|
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
2. **Adding threads:** Assign next ID (T28, T29...), set Opened date and Origin Session
3. **Closing threads:** Move to Closed Threads table with resolution note
4. **Priority levels:** High / Medium / Low
5. **Blocked threads:** Note blocker in Notes column (e.g., "Blocked by T1")
