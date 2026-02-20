# Open Threads

> **Single source of truth for unresolved work across sessions.**
>
> Updated at session end. Read at session start.

## Active Threads

| ID | Thread | Opened | Origin Session | Priority | Notes |
|----|--------|--------|----------------|----------|-------|
| T22 | Frita Voice — WALK Identity-First | 2026-02-07 | `2026-02-07__002` | Medium | **2 BUGS FOUND + FIXED, PENDING IMPORT.** Review found: (1) Identity Lookup v2 had duplicate code block causing SyntaxError; (2) Voice Entry v2 "Recognized?" IF node always routed true (boolean coercion on string). Fixed files: `Identity Lookup v2 (2).json`, `Voice Entry v2 (3).json`. Other 3 workflows clean. Import order: Identity Lookup first (sub-workflow), then Voice Entry. PRD: `Qwrk_Inbox/frita_voice_virtual_service_agent_prd_v_2_crawl_walk.md` |
| T24 | Multi-Forest Gateway Enablement | 2026-02-08 | `2026-02-08__006` | Medium | **CLONE 1 (Qwrk@Work_Joel) FULLY OPERATIONAL.** Dedicated clone gateway `/v1/work` active, ACL principal `qwrk-gw-work`, workspace `635bb8d7`. Chrome Extension v1.2 deployed (multi-workspace profiles: Personal + Work). 3 instruction_packs saved to Work workspace (`80c81342` Gateway Ops, `48194ff1` Execution Patterns, `60088999` Cognitive Protocol). Q@W system instructions refined (Conversational Discipline section added). Deployment milestone snapshot: `4552fd28`. **Remaining:** 3 clones pending (Akara_Blagg, BlaggLife, Krista_Blagg). ACL enforcement still paused (`$env` blocked). Debug logging still in popup.js (cleanup pending). Registry: `Multi-User Qwrk/01_Supabase/WORKSPACE_REGISTRY_TRACKING.md`. |
| T30 | Design Sandbox Access Model (Akara Collaboration) | 2026-02-15 | `2026-02-15__003` | Medium | **SAPLING — ANATOMY COMPLETE (4/4 BRANCHES).** Design seed: `f761db4f`. Execution sapling: `a1600411-3495-4a83-8f1b-753b05d5ae0d` (promoted 2026-02-15, companion journal `cdf746da`). Milestone snapshot: `2180b740`. Design memo: `docs/design/Design_Sandbox_Access_Model__Akara__v1.md`. **Foundation Green pre-flight PASSED.** 4 branches saved: (1) Identity Spine `4e9b0198`, (2) Forest ACL Enforcement `f77829e7`, (3) Role Model Enforcement `4673f231`, (4) Adversarial Validation `0c953250`. All seed-stage with parent_artifact_id → sapling. **Next:** Q defines leaf work items per branch. |
| T46 | Journal Append — Governance Decision Required (Mutability v3) | 2026-02-19 | `2026-02-19__003` | Medium | **GOVERNANCE DECISION REQUIRED — NO IMPLEMENTATION.** Current policy: UNDECIDED_BLOCKED (Doctrine_Journal_InsertOnly_Temporary). Requires: (1) Mutability Registry v3 with journal moved from UNDECIDED_BLOCKED to UPDATE_ALLOWED, (2) schema decision for content_history vs concatenation vs structured append, (3) workflow changes to Update sub-workflow. Out of Phase 2 scope. Locked per Phase 2 Governance Lock C3 (Journal Mutability — append-only, no deletion). No code changes until decision is locked. |
| T48 | Qwrk Prime — Restart Instruction Pack + System Instructions Update | 2026-02-20 | current | Medium | **NOT STARTED.** T47 delivered restart semantics for Q@Work only. Prime needs: (1) Restart instruction pack adapted for Prime context (re-anchor is Prime-only), (2) Prime system instructions updated with restart command routing + restart artifact schema. Reference: T47 implementation, `Multi-User Qwrk/04_Instruction_Packs/Restart_Semantics_v1.md`. |

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
| T3 | BUG-011 Telegram Tags | 2026-02-05 | **CLOSED** — Tags work on save via Telegram. "Can't add tags after creation" is BUG-017 (separate). BUG-008 also closed as moot (CustomGPT abandoned). |
| T17 | Active X Context + Rolling Memory Expansion | 2026-02-05 | **COMPLETE** — CLAUDE.md v14 with A2 spec, rolling memory Section A2 populated, Red October Active Book Context saved (`a52f402e-...`). Q instructions updated: `Qwrk_SYSTEM_INSTRUCTIONS_2_5_26.md` + `Active_Context_Instructions.md`. |
| T16 | Tier A Memory Compaction Design | 2026-02-05 | **COMPLETE** — Full protocol in CLAUDE.md v12. Rolling memory updated with Protected Core / Rotating Shell markers. Governance snapshot: `6b0b1bf4-76e4-4baf-b2eb-5af044fb4b01` |
| T15 | for-q Rolling Memory MVP | 2026-02-05 | **COMPLETE** — 9/9 snapshot artifacts seeded with for_q_* fields. Rolling file regenerated: `Qwrk_RollingMem/Qwrk_Rolling_Memory__for-q__2026-02-05.md`. 1 project artifact excluded (no payload). |
| T11 | CC Session Management Upgrade | 2026-02-04 | **COMPLETE** — CLAUDE.md v9 adds Restart Protocol Format. Sessions now use Thread Inventory, Decisions Locked, Constraints, Files Touched, Resume Instructions |
| T10 | Execution Surface Awareness (Mobile vs Desktop) | 2026-02-04 | **COMPLETE** — JSON-first default, Telegram NL opt-in. Session-level surface declaration. Snapshot: `ea06c68f-d859-4015-8328-f9d02ab2cfff` |
| T7 | Chrome Extension + Gateway Auth | 2026-02-04 | **COMPLETE** — Owner-Only MVP with Basic Auth. JSON Command Console v1.2 operational. Vertical slice validated: Chrome → Gateway → Artifact. Milestone snapshot: `57a84097-10c0-4398-954f-2654b72ed8eb` |
| T9 | BUG-020 instruction_pack artifact_id null | 2026-02-03 | **PARTIAL** — Workflow v25 fixed. Hallucination regression detected |
| T8 | BUG-019 Hardblock Regression | 2026-02-03 | **SUPERSEDED** — Chrome Extension MVP bypasses Telegram hallucination issues |
| T18 | BUG: FROM_STATE_MISSING in Promote | 2026-02-08 | **RESOLVED** — Root cause: QPM chain (Merge_Child_Counts sync gate) stripped $json payload. Fix v6: 3 nodes changed to `$node["Enforce_Verified_State"]` refs. Validated end-to-end via n8n + Chrome Extension. |
| T21 | BUG: Promote Response Plumbing | 2026-02-08 | **RESOLVED** — v6 deployed. Full promote pipeline works: DB_Update_Lifecycle + DB_Insert_Event + Shape_Response. Lifecycle test: save seed → promote sapling via Chrome Extension. QPM guards confirmed working (BLOCKED_SEED_NOT_READY, BLOCKED_NO_ANATOMY). File: `n8n_workflows/staged/BUG_PROMOTE_FROM_STATE_MISSING__gateway_promote_vNext.json` |
| T19 | BUG: artifact.list Tag Filter Ignored | 2026-02-08 | **RESOLVED** — Gateway + List workflow fixes imported. CC script had additional PowerShell bug: single-tag `-split` unwrapped array to scalar string. Fixed with `@()` wrapper. Validated: tag filter, offset, combined tag+offset all working. |
| T20 | BUG: artifact.list Offset/Pagination Broken | 2026-02-08 | **RESOLVED** — Same deployment as T19. Offset/pagination confirmed working (limit 3, offset 3 returns correct page with `has_more: true`). |
| T4 | BUG-016 Promote Transition | 2026-02-17 | **FULLY RESOLVED** — Was Telegram-only (NL AI hallucination). T14 JSON pipe now deployed; Telegram sends canonical JSON identical to QX. Promote transitions work correctly via both surfaces. |
| T6 | BUG-018 Update Creates Duplicate | 2026-02-08 | **RESOLVED** — Root cause: Gateway wiring bug. Update normalizer was connected to Promote executor (no Update Execute Workflow node existed). Fix: Gateway v43 adds `Call 'NQxb_Artifact_Update_v1'` node (workflow ID `ZMiwnwHm2AL96HhK`). Verified via Chrome Extension: `operational_state` updated in-place, no duplicate created. |
| T23 | Partial Write Cleanup | 2026-02-08 | **CLOSED** — All 3 artifacts verified as valid. `df3d7711` is seed (correct), `b1d88ee2` and `d181c90b` are saplings (accepted as-is by user). No cleanup needed. |
| T5 | BUG-017 Tags Update | 2026-02-08 | **RESOLVED** — Update v11 + Gateway v47. Universal spine-level tag updates (add/remove semantics) on ALL types including immutable. Mutability Registry v2 locked. 7/7 verification tests passed. |
| T26 | BUG: List Pagination Ignores Limit/Offset | 2026-02-11 | **RESOLVED** — Root cause: Gateway `Normalize_Request` stripped `selector` from webhook payload. Client-provided `selector.limit` and `selector.offset` never reached List sub-workflow. Fix (v48): added `selector: raw.selector ?? {}` to normalizer output. Deployed and verified: limit, offset, tag filter, combined tag+offset all working. |
| T1 | Phase 2 QPM Implementation | 2026-02-16 | **CLOSED — PHASE 2 STRUCTURAL MIGRATION COMPLETE.** Blocks A-C executed (2026-02-16). DDL v2.3: artifact_type CHECK v6 (13 types, limb added), execution_status CHECK enforced, priority NOT NULL DEFAULT 3, qxb_artifact_limb live (RLS, 3 policies, trigger). Migration: `migrations/2026-02-16__phase_2_completion__structural_migration__v1.sql`. Phase 2 Completion Snapshot: `f73f140d`. Block D (Gateway alignment for limb) deferred. |
| T29 | Phase 2B Foundation Migration Reconciliation Plan | 2026-02-16 | **CLOSED — STRUCTURAL MIGRATION COMPLETE.** Reconciliation plan executed: lifecycle_status conditional CHECK (project-only: seed/sapling/tree/archive), no oak. Containment tree: sapling `d8ebceb1` + 8 branches. Phase 1 sealed snapshot: `a5dcf3bb`. All Blocks A-C delivered. Block D completed via T32 (branch/limb/leaf routing in Save/Query/List/Update). |
| T32 | Phase 2B Gateway Type Registry Expansion (Walk) | 2026-02-17 | **COMPLETE — ALL 5 STEPS DELIVERED.** Gateway v56, Save v29, Query v18, List v29, Update v11. Step 5 (2026-02-17): branch/limb/leaf routing added to Update Switch_Type_For_Update. Runtime validated via Chrome Extension. Completion snapshot: `b82a4c93`. Known gap: grass/thorn/instruction_pack lack update routing (pre-existing). |
| T14 | Telegram Gateway Pipe | 2026-02-17 | **COMPLETE — JSON PIPE DEPLOYED.** `NQxb_Telegram_Gateway_Pipe_v1` active in n8n. Old NL workflow (`NQxb_Gateway_Telegram_v1`) deactivated. Credential IDs: telegramApi `VTIn4SmsgbApQNj2`, httpBasicAuth `jTp4W3tGrw2s036g`. Auth pattern: `genericCredentialType` (not `predefinedCredentialType`). All 3 validation tests passed (list/error/save). |
| T34 | Drift Reconciliation — Structured Signal vs OPEN_THREADS | 2026-02-17 | **COMPLETE.** Reconciliation report delivered. 3 housekeeping edits applied to OPEN_THREADS (T1/T29 close dates corrected, T32 notes updated). No implicitly closed threads missed. Phase 2/2B drift documented in report. |
| T35 | Telegram Surface Deprecation — Replace NL with JSON Gateway Mirror | 2026-02-17 | **COMPLETE — EXECUTED VIA T14/T38.** NL AI Agent workflow deactivated. JSON pipe workflow active. Decision executed: Telegram and QX now send identical canonical JSON envelopes to Gateway. |
| T38 | Surface Unification & Prompt Output Hardening | 2026-02-18 | **COMPLETE.** Phase 1: Telegram JSON pipe deployed. Phase 2: Execution Rendering Invariants [LOCKED] in Q instructions (v2_5_29). Invariant A (Gateway payload fencing), B (CC prompt canvas isolation), C (validation gate). Q instructions compacted 9,601→7,181 chars. v2_5_29 loaded into Q. Source: project `293a9649`. Documentation cleanup completed 2026-02-18. Telegram NL execution removed. JSON-only doctrine enforced. 6 files archived, 5 updated. Verification searches clean. Residual cleanup (2026-02-18__003): Journal_Mode_Instructions.md (Telegram plain text ref), CONVERSATION_RESTART_PROTOCOL.md (Desktop/Mobile template), work/temp_qp1_instructions.md (deleted). CC Inbox prompt fully executed. Q instructions renamed to v2_5_31 (lifecycle_stage retired→archive fix). All 6 updated files uploaded to Q. |
| T33 | Rolling Memory Compaction Execution | 2026-02-17 | **COMPLETE — FIRST STRATEGIC COMPACTION EXECUTED.** Full sync (57 DB entries) + strategic compaction of 8 historical milestone/bug entries. Post-compaction: PC=8, RS=41, Tier A=49, Section C=8. Audit snapshot: `dea4d0bb`. File: `Qwrk_Rolling_Memory__for-q__2026-02-17.md`. Priority bug noted: Gateway Save requires explicit `priority: 3` (DB default not applied). |
| T2 | Idempotency Implementation | 2026-02-19 | **CLOSED — STALE.** Plan (`~/.claude/plans/idempotent-seeking-hinton.md`) written against Save v24/Telegram surface — now obsolete (Save v31, Telegram deprecated). Core concept (60s title dedup) remains valid but plan needs full rewrite if revisited. Governance snapshot `f6b75a78` preserved. No active duplicate problem. Reopened as new thread if needed. |
| T12 | Plan Mode Concept | 2026-02-19 | **CLOSED — PARKED.** Concept captured as seed. Structured planning surface not on critical path. Reopen if demand surfaces. |
| T13 | Qwrk Open Threads Tracking | 2026-02-19 | **CLOSED — IMPLEMENTED.** `sessions/OPEN_THREADS.md` is the active solution. Phase 3 Vector DB tracking deferred indefinitely. |
| T36 | Define for-cc Tag Protocol | 2026-02-19 | **COMPLETE.** CLAUDE.md v17 formalizes 7-step sweep protocol. Q instructions have Loose-Thread Safety Rail. Governance snapshot: `12cf0577`. Protocol operational and in daily use. Source project `f2bbd268`. |
| T39 | Parallel Workstream Governance Protocol | 2026-02-19 | **COMPLETE.** Codified in CLAUDE.md v19 Section 10 (Parallel Mutation Guardrail). Human-enforced serialized mutation rule. Source project `6cd0fb6e`. |
| T44 | Phase Classification (Image Storage + RAG) | 2026-02-19 | **CLOSED — DECISION LOCKED.** Hybrid Image Storage = Phase 2C, RAG = Phase 3. Decision snapshot `5de9baf2`. No build work — classification only. |
| T41 | BUG: Gateway Tag Update Blocked on Journals + Snapshots | 2026-02-20 | **COMPLETE.** Update v12 deployed: tags-only bypass path (Switch_Update_Mode + Compute_Tag_Merge + spine PATCH). Tests passed (snapshot/journal/project tag add, journal extension rejection, version increment, updated_at trigger). Closure snapshot: `02ce2a6c`. |
| T47 | Multi-User Restart Architecture | 2026-02-19 | **COMPLETE.** Restart Artifact + Conversation Restart Command bifurcation. Instruction pack: `Multi-User Qwrk/04_Instruction_Packs/Restart_Semantics_v1.md`. QW system instructions + clone template updated. No DDL/workflow changes. Re-anchor scoped Prime-only. Implementation snapshot: `13243170`. |
| T27 | DDL Hygiene Pass | 2026-02-19 | **CLOSED — SUFFICIENT.** DDL v2.3 stable. RLS fully verified. Remaining items (triggers, indexes, type_registry/audit policies) are verification-only — no runtime failures observed. Audit report preserved: `audit/Systems_Integrity_Audit__Gateway_vs_DDL__2026-02-09.md`. Reopen if runtime issues surface. |
| T25 | CC Persistent Memory Architecture | 2026-02-19 | **COMPLETE.** 5-section MEMORY.md live and operational (92/200 lines). Topic files: `n8n-patterns.md`, `workflow-ids.md`. Update discipline integrated into session protocol (CLAUDE.md v15 CC Memory Harvest). PRD archived: `Qwrk_Inbox/Archive/`. Validated by 11+ days of daily use. |

---

## Maintenance Rules

1. **At session end:** Update this file before writing `LATEST_END_SESSION.md`
2. **Adding threads:** Assign next ID (T28, T29...), set Opened date and Origin Session
3. **Closing threads:** Move to Closed Threads table with resolution note
4. **Priority levels:** High / Medium / Low
5. **Blocked threads:** Note blocker in Notes column (e.g., "Blocked by T1")
