# Manus Reference — Current State Snapshot

**Purpose:** Deployed state orientation for plan review.
**Date:** 2026-05-06
**Snapshot only. Not timeless doctrine.**
**Anchored to:** CLAUDE.md v32 (2026-05-05); OPEN_THREADS Active Surface (session 135); DDL v2.10; Schema Reference v2.10.

---

> **WARNING**
>
> This document is a convenience snapshot for review orientation only.
> It is not authoritative over canonical governance, schema, workflow, or contract references.
> If this file conflicts with a plan's direct evidence or a canonical reference, the canonical reference wins.
> This file may become stale. Verify against canonical sources when precision matters.

---

## Deployed Versions

| Component | Version | Notes |
|-----------|---------|-------|
| Gateway workflow | v2 (build 4) | Sole production gateway. v1 fully decommissioned 2026-03-26 (T122). |
| Gateway endpoint | `/webhook/nqxb/gateway/v2` | Routes via `CREDENTIAL_WORKSPACE_MAP` in Gatekeeper (Demo's operational category to be confirmed by Joel; Beta provisioning surface state to be confirmed — see Multi-Forest below). |
| DDL (database schema) | v2.10 | 20 tables + 1 view, 5 functions. Includes `qxb_artifact_person` (T150), `design_spine` on project extension (T87), `semantic_type_id` on spine (T69). |
| Artifact type CHECK | v8 | 15 types (12 active + 3 reserved). |
| Schema Reference | v2.10 | Human-readable, co-committed with DDL. |
| CLAUDE.md | v32 | Current governance (2026-05-05). DB-backed Rolling Memory; LATEST_END_SESSION.md deprecated; subsession protocol; §2.7 Retry Cap; §11 Planning Gate. |
| North Star | v0.4 (locked) | Execution anatomy (branch/limb/leaf). |
| Phase 2C certification | Operational; current pass count not asserted in this file — verify with Joel before relying on a specific number. | 26-test black-box harness covering Gateway + Save + Update + Promote. Mandatory gating deferred until QBeta Dev/Prod stand-up. |

---

## What Is Shipped and Operational

### Core CRUD
- `artifact.save` — all CHECK-allowed types
- `artifact.query` — TYPE_ALLOWLIST = 9 types (project, journal, restart, snapshot, instruction_pack, branch, limb, leaf, twig); `thorn` and `grass` return `ARTIFACT_TYPE_NOT_ALLOWED` on read
- `artifact.list` — filtering by type, tags, pagination
- `artifact.update` — mutable fields on spine and extensions; T140 content/content_append update path live (Update T140 v2)
- `artifact.promote` — project lifecycle transitions (atomic via `promote_artifact_lifecycle()` RPC; T113 DB_Read filter fix in Promote v24)
- `artifact.delete` / `artifact.restore` / `artifact.list_deleted` — soft-delete lifecycle

### Messaging
- `messaging.send_email` — Gmail integration
- `messaging.create_calendar_event` — Google Calendar (recurrence, attendees, sendUpdates, timezone — T123/T124)

### Additional Gateway capability (action signature pending Joel verification)
- `payload.build` — payload assembler/validator deployed under T175 Salience Amplification (v1.1 certified). Used by Q heads as the canonical assembly route. Confirm exact `gw_action` value, validate-only vs. execute-mode contract, and whether it counts as the 11th canonical action or a sub-route before relying on it in plan review.

### Execution Anatomy
- Branch/Limb/Leaf hierarchy operational
- `execution_status` tracked on spine (not_started → in_progress → blocked → complete)
- Leaf-to-leaf dependency enforcement via `qxb_artifact_dependency`
- Progress rollup view (`qxb_artifact_rollup_view`)

### Multi-Forest

- **Confirmed active workspaces** (production-tier per OPEN_THREADS / MEMORY operational state): Prime (Qwrk Personal), Q@W (Work / Qwrk Resolve), BlaggLife, Akara, Greg.
- **Surfaces with operational category to be confirmed by Joel:**
  - **Demo** (Explore Qwrk Demo, T127). Demo proxy is operational and tested, but its operational category relative to the production workspaces above is not separately asserted in this file. Confirm with Joel before relying on Demo as production-equivalent in any review.
  - **Beta provisioning surface** (T145 / T176 onboarding). Beta gateway state and endpoint pattern are NOT asserted in this file. Treat as a separate provisioning surface, not a regular workspace, until Joel confirms.
- Routing: Gateway v2 with credential→workspace resolution. Per-workspace Basic Auth principal.
- **Workspace memory model:** Prime and Q@W on DB-backed Rolling Memory snapshots (Q@W migrated 2026-05-05, T195 complete). BlaggLife / Akara / Greg / Demo still on file-based Rolling Memory; migration path defined in Multi-Workspace Session Lifecycle Migration Playbook v1, scheduling pending.

### Execution Surfaces
- Chrome Extension (Qx) — raw JSON payload submission
- Sidebar (QSB) — structured UI for common operations
- Mobile — Gateway access via phone browser
- ChatGPT Projects — Q (governance), Q@W (work), Q@Akara, Q@BlaggLife, Q@Greg
- Claude Code — implementation and execution

### Certification
- Phase 2C harness operational — 26-test black-box regression harness covering Gateway + Save + Update + Promote
- Current pass count not asserted in this file. Verify with Joel before relying on a specific number.
- Harness is advisory; mandatory deployment gating deferred until QBeta Dev/Prod stand-up

---

## What Is In Progress

> Selected from OPEN_THREADS Active Surface. Manus reviews of plans touching these surfaces should expect the linked thread to be referenced. Not exhaustive.

| Thread | Status | Summary |
|--------|--------|---------|
| **T176** Beta Active Launch Program (Critical) | Authority framing **locked** (snapshot `5d80ee44`); binding model and follow-on contracts **in flight** | Master program for Beta launch. **Locked invariants** (do treat as authoritative for review): workspace-first, Gateway enforcement, deterministic control plane, no AI in provisioning / binding / initialization. **In-flight, NOT locked** (do NOT treat as decided in any plan review): binding mechanism (Option A — Activation Code — memo produced, decision pending), Activation Code Lifecycle Contract, Master Record concept, Bootstrap contract. Flag any plan that assumes a specific binding mechanism, Master Record schema, or bootstrap contract as decided. |
| **T185** Gateway zero-result empty-body defect (High) | Docs complete; doctrine adopted | Workspace Bootstrap Bookmark Doctrine adopted 2026-05-06 as preferred mitigation; per-workspace IP first-wake fallback handler covers pre-doctrine workspaces. |
| **T195** Q@W DB-backed memory migration (Medium) | Complete; cutover ~2026-06-05 | Q@W on DB-backed Rolling Memory + SLP v1; bootstrap snapshot `fe9798ef`; first session-end `4d16480e`. |
| **T197** Bootstrap Bookmark propagation (Medium) | Not started | Propagate Bootstrap save into T176 Branch B (Operator Provisioning) and T145 (Beta User Provisioning). |
| **T172** Qwrk Operator Console (High) | Sapling; 3 branches | Next.js console for artifact browsing/hydration; Phases 1–8 scaffolded. Hosting/auth approach pending Joel decision. |
| **T175** Salience Amplification Doctrine (High) | Phase A in progress | Instruction-layer transition plan (4 phases A→D). Payload Builder IP v1 promoted to Q heads via T177. payload.build v1.1 certified. |
| **T177** Payload Builder IP — Test & Promote (High) | IP uploaded; Q deep-tested | Builder = assembler-only. Lifecycle validated for journal, project, twig, snapshot. Known: semantic_type_id silent drop bug; payload.build execute-mode via Qx under investigation. |
| **T179** QPA — Q@W Workday Personal Assistant (High) | Deployed to Q@W | QPA v2 + Cognitive Protocol v2 live in Q@W. Akara/Prime adaptations queued. |
| **T174** Guided PoV Experience (High) | Build in progress | Chrome side panel + n8n orchestrator. Workspace: Q@W. Originally targeted 2026-04-07. |
| **T173** Qwrk Website Strategic Planning (High) | Sapling; 7 branches | Branding, architecture, onboarding, product surface. Overlaps T172 on hosting/auth. |
| **T150** Person artifact type — Implementation (Medium) | Branches 1–3 complete | DDL v2.10 deployed; Save v47 (communication_style bug fixed under closed T165); 10 corrupted records remediated. Branch 4 (Retrieval & Behavior) → 5 → 6 still pending. |
| **T167** Compliance-to-Enforcement Hardening (High) | 2 trees + 1 sapling | Tree A (Response & Error Integrity, certified `e35be5af`) and Tree B (Gateway Strict Mode, certified `3f8e5052`) deployed in Save v50, Update T140 v2, Gateway v2 build 4. Sapling C (Architectural Enforcement) design-first, not yet implemented. |
| T145 Beta user provisioning & onboarding | Sapling | Teaching layer locked. Akazanar Qx/QSB credential placeholder + ChatGPT IP upload pending. |
| T152 Akara Gateway access | Partial | Regular Qx fixed; Beta Qx still blocked on KNOWN_WORKSPACES update. |
| T118 parent_artifact_id update path | Blocked | n8n import verification pending in UI. |
| T127 Qwrk Exploratory GPT (Demo) | In progress | Demo proxy operational, 47/47 PASS, auth added. |
| T144 Lifecycle alignment guardrail | Seed | Spine/extension lifecycle alignment enforcement. |

---

## What Is NOT Yet Built

These items are in the thread backlog but not active:

- **Gateway `execution_status` update action** (T111) — no Gateway route to update execution_status on the Update normalizer allowlist; workaround is direct SQL.
- **Read-Only Gateway Layer** (T147) — 5 read-only actions scoped but not implemented.
- **Classification architecture** (T78) — category/subcategory model not designed.
- **Type registry implementation** (T66) — Phase 3 scope.
- **Retry/restart contract v2** (T58) — restart system redesign, not started.
- **Gateway dependency management routes** (T180) — `qxb_artifact_dependency` add/remove/query routes; currently SQL-only despite table existing under T71 and being read by CmdCtr.
- **Architectural Enforcement** (T167 Sapling C) — design-first; not yet implemented.

---

## Known Technical Debt

- n8n JSON import double-escapes regex in Normalize_Request (manual fix required after import).
- Mobile console returns silent failures (T114, related to closed T113 audit).
- Menu Mode journal tag update failure (T117) — 5+ session carry-forward bug.
- payload.build `execute` mode via Qx returned validation-only response under T177 — investigation pending.
- T185 Gateway zero-result empty-body defect — root cause not patched; mitigated via Bootstrap Bookmark Doctrine + IP first-wake handler. If `"Unexpected end of JSON input"` recurs in any workspace **after** that workspace has saved a session-end snapshot, escalate immediately as Gateway/QSB bug per Bug Resolution Process.

> Closed since 2026-03-22 (no longer technical debt): T88 spine preservation (Update T140 v2), T113 response-shaper audit, T140 content field update path, T122 v1 Gateway decommission, T149 Promote atomicity, T158 instruction architecture refactor, T165 Person communication_style corruption.

---

## Key System Boundaries

| Boundary | Rule |
|----------|------|
| Database writes | Gateway only (service_role); CC is read-only |
| Workspace isolation | Artifacts cannot cross workspace boundaries |
| Immutability | Snapshots and restarts: no UPDATE, no DELETE |
| Audit log | Append-only, triggers block modification |
| Lifecycle transitions | Directional only (seed→sapling→tree→archive), no backward |
| Soft delete | All deletes set `deleted_at`; no hard deletes |

---

## CHANGELOG

### Proposed v2 — 2026-05-06 (pending Q/Joel confirmation on versioning convention)

**Version number is a proposal, not an assumption.** If Joel prefers a different versioning style, the bump label changes accordingly; the body of the change set does not.

**What changed (proposed):** Refreshed Deployed Versions table (Gateway v68 → Gateway v2 build 4; CLAUDE.md v25 → v32; Phase 2C count made non-assertive). Added "Additional Gateway capability" sub-section for `payload.build` under verification. Multi-Forest sub-section restructured to distinguish confirmed active workspaces from surfaces with operational category to be confirmed (Demo, Beta provisioning surface). Replaced "What Is In Progress" with current OPEN_THREADS Active Surface highlights (T176 row separates locked authority framing from in-flight follow-on decisions). Replaced "What Is NOT Yet Built" (removed completed items: T140, v1 Gateway clone decommission). Replaced "Known Technical Debt" (removed completed items: T88, T113). Preserved: WARNING block, Execution Anatomy, Execution Surfaces, Key System Boundaries.

**Why:** Prior v1 asserted facts that became false post-2026-03-22 (Gateway v68, v1 still extant, T140 not built, T88/T113 open). Refresh aligns Manus's current-state reference with CLAUDE.md v32 and OPEN_THREADS without importing UCC, full Session Lifecycle, or full Beta packets (those remain deferred).

**Previous version:** `Archive/manus_current_state__v1__2026-03-22.md`

### v1 — 2026-03-22
Initial creation for Manus plan reviewer role.
