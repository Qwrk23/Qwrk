# Instruction Pack Index

> Master index of all instruction packs and reference documents available to Qwrk.
>
> **Payload Lookup Mandate:** Before selecting an artifact type or emitting any Gateway payload, find the governing pack in this index by matching the Trigger column, open it, and verify the required shape.

## Core

| File | Purpose | Trigger |
|------|---------|---------|
| `north_star_january_joel_alignment_charter.md` | Alignment Prime — always-on reference | Session start, prioritization decisions |
| `Journal_Mode_Instructions.md` | Journal Mode behavioral rules | Entering/exiting Journal Mode |
| `Active_Context_Instructions.md` | Section A2 active context protocol | Session start (A2 check) |
| `CC_Prompt_Guidelines.md` | CC prompt generation rules | Generating CC prompts |
| `Instruction_Pack__Global_Behavior__v1.md` | Cross-cutting authored-output behavior: authorship classification, attribution posture, rendering boundaries | Producing authored output (emails, seed pods, written artifacts, communications with byline) |

## Execution

| File | Purpose | Trigger |
|------|---------|---------|
| `Qwrk_Gateway_Payload_Canonical_v5.md` | Full Gateway payload specification | Any `artifact.save` payload |
| `QUICK_REFERENCE.md` | Save/update/promote/list/query examples + workflow patterns | Any Gateway payload (quick lookup) |
| `Instruction_Pack__QSB_Payload_Format__v3.md` | QSB rendering contract + validation gate | Every execution-bound output (QSB format) |
| `Instruction_Pack__Artifact_Discovery_Playbook__v1.md` | Search mode classification + query strategies + intent recognition + candidate scoring + ghost-like demotion + presentation/disambiguation + test corpus reference | `artifact.query`, `artifact.list`, fuzzy artifact discovery requests |
| `Instruction_Pack__Payload_Discipline__v4.md` | Single operational authority for payload construction: extension field rules, semantic type governance, artifact selection, gateway error posture, and fast-capture carveout | Every Gateway payload (preflight check), artifact type selection |
| `Instruction_Pack__Messaging__ACTIVE.md` | send_email + calendar_event contracts | `messaging.send_email`, `messaging.create_calendar_event` |
| `Instruction_Pack__Debt_Freedom_Plan_Operating_Protocol__v1.md` | Debt Freedom Plan operating protocol — snapshot taxonomy, monthly cycle, cross-workspace routing, derived metrics | Debt payment, debt snapshot, monthly debt update, debt payoff progress, statement upload |
| `Instruction_Pack__Feedback_Snapshot__v1.md` | Structured feedback capture contract for beta users | User expresses feedback, feature request, bug report, usability friction, praise |
| `Instruction_Pack__Person_Artifact_Save_Capability_Boundary__v1.md` | Person artifact save contract boundary — implemented vs blocked capabilities, extension schema, mapping rules, operational posture | `artifact.save` with `artifact_type: "person"`, person profile capture |

## Governance

| File | Purpose | Trigger |
|------|---------|---------|
| `LIFECYCLE_GUIDE.md` | Lifecycle stage transitions | `artifact.promote`, lifecycle decisions |
| `CONVERSATION_RESTART_PROTOCOL.md` | Restart prompt format | Conversation restart |
| `weekly_qwrk_stewardship_loop.md` | Weekly stewardship cadence | Weekly review |
| `Instruction_Pack__Phase2_Governance_Hardening__v1.md` | Phase 2 governance rules | Governance questions |
| `Instruction_Pack__Session_Lifecycle__v2.3.md` | Session Lifecycle Protocol v2.3 (Crawl Phase) — primary vs subsession startup modes, deterministic startup retrieval per mode, post-startup Morning Flow integration (primary only), End Session Protocol, snapshot schema, failure handling, crawl constraints. Incorporates CmdCtr Session Context briefing as §3 (supersedes CmdCtr IP v1). v2.1 adds T185 instruction-layer fallback handlers (§1.5 Primary, §1.3 Step 7 Subsession; §1.7 guardrail). v2.2 adds Workbench (Working Set) doctrine (§9), workbench tag exclusion for session-close snapshots (§5.1a), documents the `active_workbench[]` payload field (§5.2/§5.3), and canonicalizes the session-close spine tag to `session-end` (§5.1). v2.3 restores retrieval-side alignment with §5.1 by introducing two-query client-side union retrieval as substeps in §1.2 (2a–2d) and §1.3 (4a–4b); §1.2 Step 4 merge-and-absorb algorithm (union by `artifact_id`, sort `created_at` DESC, tiebreaker `artifact_id` ASC, schema-valid scan per §5.2/§5.3, invalid-latest handling, K=10 bounded retry); §1.2 Step 8 and §1.3 Step 8 verbatim slot `[ (transitional tag)]`; new §1.8 transitional retrieval window with named narrowing trigger (N=5 save-side emission across Prime + Q@W + ≥30 days + Q@W parity). Save-side §5.1 frozen at `["session-end", "for-q"]`; §4.4 unchanged; no DB/Gateway/payload-shape change; no historical retag. | Session start, startup, wake, /wake, new session, /new sub, new sub, nsub, sub, end session, workbench, CmdCtr briefing present, Morning Flow daily check |
| `Instruction_Pack__QPM_Build_Process__v1.md` | QPM 7-phase launch + twig fast-capture | QPM project launch, twig quick capture |
| `Instruction_Pack__Team_Qwrk_Bug_Resolution_Process__v1.md` | 10-phase bug resolution with authorization gate | Bug identified, bug fix planning, production mutation |

## Safety

| File | Purpose | Trigger |
|------|---------|---------|
| `Instruction_Pack__Cross_Workspace_Write_Gate__v1.md` | Cross-workspace write consent boundary for non-home workspace mutations | Before emitting any cross-workspace write payload |

## Infrastructure

| File | Purpose | Trigger |
|------|---------|---------|
| `Instruction_Pack__Mother_Tree_Structural_Map__v1.md` | Mother Tree branch UUIDs + routing | Setting `parent_artifact_id` |
| `Instruction_Pack__CC_Handoff_Lane__v1.md` | Q ↔ CC structured handoff protocol — artifact roles, tags, Template A, retrieval doctrine | Sending structured work to CC, receiving CC results |

## Overlay

| File | Purpose | Trigger |
|------|---------|---------|
| `Demo_Mode_IP_v2.md` | Demo Mode behavioral overlay (session-bound) | Entering Demo Mode |
| `Instruction_Pack__Voice_Mode__v1.md` | Voice Mode behavioral overlay (session-bound) — Prime adopts Voice posture on demand; inherits full Prime context; capture/shape only; exit does not emit payloads | Entering/exiting Voice Mode ("voice on", "go voice", "voice off", "exit voice") |

## Onboarding

| File | Purpose | Trigger |
|------|---------|---------|
| `Instruction_Pack__Beta_User_Onboarding__v1.md` | Beta user provisioning (operator) + onboarding (user) — two-mode protocol | Joel declares new beta user OR user's first interaction in new workspace |

---

**Governance Rule:** Instruction Pack Index must be updated in the same change set as any pack version bump. ACTIVE alias files must be updated atomically with version changes.

*Updated: v20 — Session Lifecycle v2.2 → v2.3. Restores retrieval-side alignment with v2.2 §5.1 save-side canonical `session-end` tag by introducing two-query client-side union retrieval, expressed as substeps (§1.2 Steps 2a–2d; §1.3 Steps 4a–4b) so existing step numbering and §2 cross-references remain valid. §1.2 Step 4 body updates to merge-and-absorb algorithm: union by `artifact_id` (dedupe single-record for both-tag artifacts), sort by `created_at` DESC (recency authority — not `updated_at` or `version`), tiebreaker `artifact_id` ASC, schema-valid scan per §5.2/§5.3, invalid-latest handling, tag-source classification (canonical / transitional / both / canonical-plus-transitional), K=10 bounded retry per query (up to 20 pre-dedupe candidates), §6 Failure Handling escalation on persistent schema-invalidity, genuine-absence handling. §1.3 Step 5 body mirrors §1.2 Step 4 with spine-only schema validation. §1.2 Step 8 and §1.3 Step 8 verbatim reports gain conditional slot `[ (transitional tag)]` triggered only when selected bookmark carries only `end-session`. New §1.8 documents transitional posture, K semantics, recency authority, transitional observation telemetry (not failure framing; no historical re-tag authorization), invalid-latest handling, §4.4 consumption note (explicitly confirms §4.4 has no retrieval payload), and narrowing trigger (N=5 consecutive new End Session saves across Prime + Q@W carry `session-end` and zero carry `end-session` — save-side emission, not retrieval-side selection — AND ≥30 days since landing AND Q@W parity). §2 Startup Context Absorption gains one clarifying sentence on tag-source classification; step-number references preserved. §4.4 body unchanged. Save-side §5.1 frozen at `["session-end", "for-q"]`. No DB schema change, no `schema_version` bump, no Gateway action change, no payload-shape change at save-side, no historical retag. Workbench (§9), §5.1a, §5.2/§5.3 `active_workbench[]`, T185 fallback handlers (§1.5, §1.3 Step 7, §1.7), §3 CmdCtr, §6 Failure Handling base, §7 Crawl Phase Constraints, §8 Surface Rendering, Morning Flow v2 doctrine references all unchanged. T212 gate: Manus TQR Amend (A1–A10 applied); Q approve with one wording polish in §1.8 (future-collapse evaluation) and parallel §1.8 sister-thread coordination wording polish (both applied); Joel approval (applied). Authorizing lane: project `46142606-ac00-416c-95a0-2e81e997b9e4` (Session Lifecycle / End Session Schema — Governance Lane). Driven by G coordination flag from Rolling Memory v16 cleanup 2026-06-10; sister twig `b14f8027-5ab9-4010-a4f0-ab9461f79599` (Gateway v2 `tags_any` returns intersection not union); related downstream branch `dd702a7f-9113-43ee-ab9f-cea1fdedacc0` (End Session Search Enrichment). Pack count unchanged at 27. Previous: `Archive/Instruction_Pack_Index__v19__2026-06-10.md`. v19 — Session Lifecycle v2.1 → v2.2. Adds Workbench (Working Set) doctrine (§9), workbench tag exclusion for session-close snapshots (§5.1a), `active_workbench[]` payload documentation (§5.2/§5.3), and bounded canonicalization of the session-close spine tag `end-session` → `session-end` (§5.1, CD-1). Additive doctrine + prohibition + payload documentation + tag-string alignment; no DB schema change, no schema-version bump, no Gateway change, no startup behavior change, no historical retag. T212 gate: Manus TQR approve-with-amendments + final shape approval; Q approved with CD-1. Source: sapling `c75c4dbe-987d-43ed-a126-65f3222179d2`; TQR Synthesis `d89c9395-ea35-41ed-b161-dd18c770ab0a`; Correction `a067ec42-b4e0-4931-acde-ab075c636200`. Pack count unchanged at 27. Previous: `Archive/Instruction_Pack_Index__v18__2026-06-07.md`. v18 — Artifact Discovery Playbook v1.2 → v1.3. T209 Crawl-1 landing. Added sections H (Intent Recognition), I (Candidate Scoring v1), J (Ghost-like Demotion), K (Candidate Presentation and Disambiguation), L (Test Corpus Reference). Front-matter `pack_version` corrected from drifted `v1` to `v1.3`. Trigger column expanded to surface fuzzy artifact discovery requests. Manus TQR `Ready with amendments` applied (ghost-like "flag" → "indicator/caveat" softening; "recommend hydrate" → "offer for Joel's confirmation before hydration"; Section L fixture authority sentence). Source: Artifact Discovery Layer seed `542cf4c1-c6df-4504-8a1e-9ca799a9c38c`, Crawl-0 Audit Snapshot `b532f87c-5b25-4c92-bb41-1a3cfd06022e`. Pack count unchanged at 27. Previous: `Archive/Instruction_Pack_Index__v17__2026-05-12.md`. v17 — Session Lifecycle v2 → v2.1. Adds T185 instruction-layer fallback handlers to two daily-orientation lookup contexts: §1.5 (Primary, Post-startup Morning Flow integration) and §1.3 Step 7 (Subsession lightweight startup). Both handlers strictly scoped to the exact daily-orientation lookup payload; do NOT generalize to other Gateway calls. Mode-differentiated outcomes preserved: Primary prompts Morning Flow v2; Subsession records none-today and continues. New §1.7 documents shared scope guardrail. T185 remains an active Gateway defect — handlers are instruction-layer mitigation only, not a Gateway closure. No new triggers. Pack count unchanged at 27. v16 — Session Lifecycle v1 → v2. New v2 adds Primary vs Subsession startup mode distinction (`/new sub`, `new sub`, `nsub`, `sub` triggers run lightweight retrieval; existing primary triggers run full 8-step + post-startup Morning Flow integration). Trigger column updated to surface new subsession triggers and Morning Flow daily check. Pack count unchanged at 27. v15 — Replaced `Instruction_Pack__CmdCtr_Session_Context__v1.md` with `Instruction_Pack__Session_Lifecycle__v1.md` under Governance. New pack incorporates prior CmdCtr content verbatim as §3 plus Session Lifecycle Protocol v1 (Crawl Phase). Pack count unchanged at 27. v14 — Added Voice Mode v1 under Overlay. Pack count 26→27. v13 — Added Global Behavior v1 under Core. Pack count 25→26. v12 — Messaging pack ACTIVE alias. v11 — Added CC Handoff Lane under Infrastructure. v10 — Added Feedback Snapshot under Execution. v8 — Added Person Artifact Save Capability Boundary. v6 — Payload Discipline v3→v4. v5 — architecture refactor.*
