# Design — Payload Contract Drift Guardrails

> **Status:** PLANNING COMPLETE — GOVERNANCE LOCKED — IMPLEMENTATION DEFERRED
>
> **Thread:** T52
> **Created:** 2026-02-21
> **Decisions Locked:** 2026-02-21
> **Author:** CC (Claude Code)
> **Unlock Condition:** Deterministic Hardening Sprint complete + re-audit PASS (no HIGH findings)

---

## CHANGELOG

| Version | Date | Changes |
|---------|------|---------|
| v1 | 2026-02-21 | Initial design. Drift risk map, guardrail architecture, enforcement surfaces, governance snapshot strategy, implementation order. |
| v1.1 | 2026-02-21 | Governance lock. All 4 open questions resolved. Audit cadence finalized (event-triggered + per-sprint). Clone IPs added to Guardrail E scope. Checklist format locked as inline. CLAUDE.md step 7 approved for governance edit (separate session). Coupling rejection rule added to Guardrail A. |

---

## 1. Purpose & Scope

### Problem Statement

The 2026-02-20 Payload Contract Alignment Audit revealed **31 drift findings** (13 Critical, 12 Major, 6 Minor) between the canonical payload contract, system instructions, Gateway workflows, and supporting documentation. The root cause was structural: no durable mechanism existed to detect or prevent contract drift across authority surfaces.

### Root Cause Taxonomy

Historical drift occurred through five distinct failure modes:

| Mode | Description | Example Findings |
|------|-------------|-----------------|
| **Empty Authority** | Canonical doc claimed authority but contained empty stub sections | C-01: Sections 3-7 were stubs referencing non-existent "prior canonical reference" |
| **Pointer Misalignment** | Documents referenced wrong or non-existent files | C-03: TYPE_ALLOWLIST vs DDL CHECK divergence |
| **Undocumented Behavior** | Workflows implemented features never captured in any doc | C-02: 3 live Gateway actions (delete/restore/list_deleted) with zero documentation |
| **Semantic Mismatch** | Field names implied different behavior than implementation | C-12: `tags_any` field uses AND semantics (set containment) |
| **Silent Degradation** | Workflow routing exists but performs no actual work | M-10: branch/limb/leaf extension update returns fake success |

### Scope

This design covers mechanisms to prevent future drift between:

1. **Canonical payload contract** (Qwrk_Gateway_Payload_Canonical_v2.md)
2. **System instructions** (Q's payload generation rules)
3. **Gateway workflows** (runtime validation and routing logic)
4. **Schema enforcement** (DDL constraints, CHECK values, RLS)
5. **Supporting documentation** (QUICK_REFERENCE, LIFECYCLE_GUIDE, WORKFLOW_PATTERNS, CC_Prompt_Guidelines)
6. **Governance documents** (CLAUDE.md, Mutability Registry, Phase Locks)

### Explicit Non-Goals

- No workflow edits, schema changes, or registry modifications
- No automation or scripting (human-enforced guardrails only, until unlock)
- No changes to the existing authority chain
- No retroactive remediation of existing drift (that's the Hardening Sprint's job)

---

## 2. Authority Surface Inventory

### 2.1 Complete Surface Map

Every file that defines, references, or enforces payload shapes:

| Tier | Surface | Current Version | File | Role |
|------|---------|----------------|------|------|
| **T1: Source Truth** | Database Schema | DDL v2.4 | `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` | Column names, types, constraints, CHECK values |
| **T1: Source Truth** | Payload Contract | v2 | `Chat Project Files/Qwrk_Gateway_Payload_Canonical_v2.md` | Field requirements, extension rules, error codes, mutation invariants |
| **T2: Enforcement** | Gateway Router | v56 | `workflows/NQxb_Gateway_v1 (56).json` | Action routing, type validation, normalize request |
| **T2: Enforcement** | Save Sub-workflow | v31 | `workflows/NQxb_Artifact_Save_v1 (31).json` | Extension validation, field allow-lists, spine INSERT |
| **T2: Enforcement** | Query Sub-workflow | v18 | `workflows/NQxb_Artifact_Query_v1 (18).json` | Type-specific hydration, response shaping |
| **T2: Enforcement** | List Sub-workflow | v29 | `workflows/NQxb_Artifact_List_v1 (29).json` | Filtering, pagination, hydrate defaults |
| **T2: Enforcement** | Update Sub-workflow | v12 | `workflows/NQxb_Artifact_Update_v1 (12).json` | Tags-only bypass, mutability enforcement, type routing |
| **T2: Enforcement** | Promote Sub-workflow | v2_HTTP | `workflows/NQxb_Artifact_Promote_v2_HTTP.json` | QPM guards, lifecycle transitions, reason validation |
| **T2: Enforcement** | Schema Reference | v2.3 | `docs/schema/Schema_Reference__Kernel_v1__v2.3.md` | Human-readable DDL interpretation |
| **T3: Behavioral** | Q System Instructions | v2.5.35 | `Chat Project Files/Qwrk_SYSTEM_INSTRUCTIONS_2_5_35.md` | How Q generates payloads |
| **T3: Behavioral** | Quick Reference | current | `Chat Project Files/QUICK_REFERENCE.md` | Payload examples for Q |
| **T3: Behavioral** | Workflow Patterns | current | `Chat Project Files/WORKFLOW_PATTERNS.md` | n8n patterns for payload handling |
| **T3: Behavioral** | CC Prompt Guidelines | current | `Chat Project Files/CC_Prompt_Guidelines.md` | CC interaction with payloads |
| **T3: Behavioral** | Lifecycle Guide | current | `Chat Project Files/LIFECYCLE_GUIDE.md` | Promote payload examples |
| **T3: Behavioral** | Demo Mode IP | v2 | `Chat Project Files/Demo_Mode_IP_v2.md` | Demo payload constraints |
| **T3: Behavioral** | Work Gateway Ops IP | v2.1 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/instruction_pack_*` | Clone workspace payload rules |
| **T4: Governance** | CLAUDE.md | v19 | `CLAUDE.md` | CC governance, DDL-as-Truth, deployment checklist |
| **T4: Governance** | Mutability Registry | v2 | `docs/governance/Mutability_Registry_v2.md` | What can be updated vs read-only |
| **T4: Governance** | Phase 1-3 Lock | locked | `docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md` | Artifact semantics binding |
| **T4: Governance** | North Star | v0.4 | `docs/architecture/North_Star_v0.4.md` | Execution anatomy (branch/leaf/limb) |
| **T5: Validation** | KGB Locks | 2026-01-17 | `docs/governance/Gateway_v1_KGB_Lock_Status__2026-01-17.md` | Known-good baseline proofs |
| **T5: Validation** | Test Plans | current | `workflows/Test Plans/T41__Tags_Update__Contract_Tests.md` | Contract-level test specs |
| **T5: Validation** | Drift Report | 2026-02-20 | `Chat Project Files/Payload_Contract_Drift_Report__2026-02-20.md` | Audit findings reference |

**Total surfaces: 23 files across 5 tiers.**

### 2.2 Authority Chain (Single Source of Truth)

```
DDL v2.4 (database truth)
    ↓ constrains
Canonical v2 (payload truth)
    ↓ informs
Gateway v56 + Sub-workflows (enforcement)
    ↓ referenced by
Q System Instructions + Reference Docs (behavior)
    ↓ governed by
CLAUDE.md + Phase Locks + Mutability Registry (governance)
    ↓ validated by
KGB Snapshots + Test Plans + Drift Reports (validation)
```

**Resolution rule:** On conflict, higher tier wins. Lower tier must be corrected to match higher tier. Never the reverse.

---

## 3. Drift Risk Map

### 3.1 Drift Vectors (Where Drift Can Occur)

Each vector represents a pair of surfaces that can fall out of alignment:

| Vector ID | Surface A | Surface B | Drift Risk | Historical Evidence |
|-----------|-----------|-----------|------------|-------------------|
| **V-01** | DDL CHECK constraints | Canonical v2 type list | **HIGH** | C-03: TYPE_ALLOWLIST excludes 5 DDL types |
| **V-02** | Canonical v2 field specs | Save v31 validation logic | **HIGH** | C-07, C-08, C-09, C-10: Extension requirements undocumented |
| **V-03** | Canonical v2 action list | Gateway v56 action routing | **HIGH** | C-02: 3 undocumented live actions |
| **V-04** | Canonical v2 update rules | Update v12 routing logic | **HIGH** | M-10: Fake success on branch/limb/leaf |
| **V-05** | Canonical v2 promote rules | Promote v2_HTTP QPM guards | **MEDIUM** | C-06: `reason` requirement undocumented |
| **V-06** | Q System Instructions | Canonical v2 extension rules | **MEDIUM** | C-04: System instructions said "extension required for save" — not always true |
| **V-07** | QUICK_REFERENCE examples | Canonical v2 field specs | **MEDIUM** | m-02: Missing spine fields in examples |
| **V-08** | LIFECYCLE_GUIDE promote examples | Canonical v2 promote rules | **LOW** | m-03: Missing endpoint/auth info |
| **V-09** | CLAUDE.md action list | Canonical v2 / Gateway reality | **MEDIUM** | CLAUDE.md says "5 actions" — actually 8 |
| **V-10** | Schema Reference v2.3 | DDL v2.4 | **LOW** | Drift Prevention Rule already exists (co-commit) |
| **V-11** | Gateway pinned sub-workflow IDs | Actual deployed sub-workflow versions | **HIGH** | CLAUDE.md Deployment Checklist addresses this, but no verification mechanism |
| **V-12** | Mutability Registry v2 | Update v12 enforcement logic | **MEDIUM** | M-06: Registry says UNDECIDED_BLOCKED but tags-only bypasses it |
| **V-13** | CC_Prompt_Guidelines | Canonical v2 | **LOW** | No historical drift found |
| **V-14** | Work clone instruction packs | Canonical v2 | **MEDIUM** | Clone IPs must track prime changes |
| **V-15** | Demo Mode IP v2 | Canonical v2 | **LOW** | Demo overlay — narrow surface |

### 3.2 Drift Risk Classification

| Risk Level | Count | Vectors | Characteristic |
|------------|-------|---------|---------------|
| **HIGH** | 5 | V-01, V-02, V-03, V-04, V-11 | Would cause runtime failure or silent data loss |
| **MEDIUM** | 5 | V-05, V-06, V-09, V-12, V-14 | Would cause user confusion or governance inconsistency |
| **LOW** | 5 | V-07, V-08, V-10, V-13, V-15 | Clarity/completeness issues, unlikely to cause failures |

### 3.3 Drift Triggers (When Drift Happens)

| Trigger | Affected Vectors | Frequency |
|---------|-----------------|-----------|
| **Sub-workflow version bump** | V-02, V-03, V-04, V-05, V-11 | Every workflow edit |
| **DDL migration** | V-01, V-10 | Rare (schema changes) |
| **New artifact type added** | V-01, V-02, V-03, V-04, V-06, V-07 | Rare (type system expansion) |
| **System instructions update** | V-06 | Moderate (Q behavioral changes) |
| **CLAUDE.md update** | V-09 | Moderate (governance evolution) |
| **New clone workspace** | V-14 | Rare (multi-user expansion) |
| **Mutability decision change** | V-12 | Rare (governance decision) |

---

## 4. Guardrail Architecture

### 4.1 Guardrail A — Version Bump Protocol

**Problem:** Workflow version changes are the most frequent drift trigger, and the most dangerous (HIGH risk vectors V-02, V-03, V-04, V-11).

**Design:**

When ANY sub-workflow version is bumped (Save, Query, List, Update, Promote):

| Step | Action | Owner | Verification |
|------|--------|-------|-------------|
| 1 | Identify fields/validation/routing changed | CC/Joel | Diff old vs new workflow JSON |
| 2 | Check: Does Canonical v2 describe this behavior? | CC | Read relevant Canonical v2 section |
| 3 | If Canonical v2 is accurate: no doc change needed | — | Proceed to step 5 |
| 4 | If Canonical v2 is stale/wrong: update Canonical v2 | CC (write), Joel (approve) | Archive old version per Pattern C |
| 5 | Update Gateway pinned sub-workflow ID | Joel | CLAUDE.md Deployment Checklist (existing) |
| 6 | Record version change in MEMORY.md Deployed State | CC | Session protocol (existing) |

**Coupling rule:** Canonical v2 update and workflow deployment must occur in the same session. Deferral is not permitted for behavioral changes.

**Rejection rule:** If a workflow behavioral change cannot be accompanied by a Canonical v2 update in the same session, the workflow change must be rejected. The change may not be activated until the canonical update is ready to ship alongside it.

**Exclusion:** Cosmetic workflow changes (node repositioning, comment edits) that don't alter validation, routing, or response shape are exempt.

### 4.2 Guardrail B — Contract Regression Checklist

**Problem:** No systematic verification exists to confirm a workflow change doesn't break contract alignment.

**Design:**

Before activating any modified workflow, verify:

```
CONTRACT REGRESSION CHECKLIST
==============================

Workflow: _____________ (version)
Change summary: _________________________

PAYLOAD SHAPE
[ ] All required fields still required? (Canonical v2 §2-7)
[ ] No new required fields added without Canonical v2 update?
[ ] Extension requirements per type unchanged? (or updated in Canonical v2)
[ ] Response envelope shape unchanged? (or updated in Canonical v2)

VALIDATION LOGIC
[ ] TYPE_ALLOWLIST matches Canonical v2 §2.2?
[ ] Error codes match Canonical v2 §9?
[ ] Mutability enforcement matches Mutability Registry v2?

ROUTING
[ ] All type branches produce output? (no silent dead-ends)
[ ] All type branches perform DB write? (no fake success)
[ ] Gateway pinned workflow IDs updated?

VERSION BEHAVIOR
[ ] Save INSERT: version defaults to 1?
[ ] Update paths: version increments by 1?
[ ] Promote: version increments by 1?

DOCUMENTATION
[ ] Canonical v2 current for this action?
[ ] QUICK_REFERENCE examples still valid?
[ ] LIFECYCLE_GUIDE transitions still valid? (promote changes only)
```

**Format (LOCKED):** Inline checklist in session notes or commit message. Not a separate tracked artifact — overhead must be near-zero. This is a final decision; the checklist remains lightweight session discipline.

### 4.3 Guardrail C — Pre-Activation Validation Ritual

**Problem:** The existing CLAUDE.md Deployment Checklist (Section "Workflow Deployment Checklist") covers workflow import mechanics but not contract alignment.

**Design:**

Extend the existing 6-step deployment checklist with a 7th step:

| Step | Current Checklist | Addition |
|------|------------------|----------|
| 1 | Archive current version | (unchanged) |
| 2 | Apply fix, increment version | (unchanged) |
| 3 | Update Gateway Execute Workflow node | (unchanged) |
| 4 | Export updated Gateway | (unchanged) |
| 5 | Import both to n8n | (unchanged) |
| 6 | Activate both | (unchanged) |
| **7** | — | **Contract regression check (Guardrail B)** |

**Enforcement:** Human discipline. CC reminds at step 7; Joel confirms checklist passes.

### 4.4 Guardrail D — Drift Detection Mechanism

**Problem:** Drift accumulates silently between audits. Need periodic or event-triggered detection.

**Design — Two-Layer Detection:**

#### Layer 1: Event-Triggered (Per Change)

On each workflow version bump, CC runs Guardrails A + B inline. This catches drift at the point of introduction.

#### Layer 2: Periodic Audit (LOCKED Policy)

**Final cadence:** Event-triggered + per-sprint. No calendar-based audit required at this stage.

**Mandatory full contract audit triggers:**

| Trigger | Scope | Owner | Deliverable |
|---------|-------|-------|------------|
| Sub-workflow version bump | Affected action's contract surface | CC | Guardrails A + B inline |
| DDL migration | Full 15-vector audit | CC | Drift report |
| New artifact type added | Full 15-vector audit | CC | Drift report |
| Runtime anomaly traceable to contract misalignment | Full 15-vector audit | CC | Drift report + thorn |
| Per hardening sprint | Full 15-vector audit | CC | Drift report (same format as 2026-02-20 audit) |
| Per phase gate | Structural alignment check | CC + Joel | Phase gate snapshot |

**Audit procedure (repeatable):**

1. Extract runtime behavior from all 6 workflow JSONs (behavioral truth)
2. Compare against Canonical v2 (documented truth)
3. Compare Canonical v2 against DDL (schema truth)
4. Compare Q System Instructions against Canonical v2 (behavioral authority)
5. Classify findings: Critical / Major / Minor
6. Produce drift report

### 4.5 Guardrail E — Pointer Discipline

**Problem:** Historical drift (C-01) occurred because the canonical doc itself referenced a non-existent "prior canonical reference." System instructions referenced wrong filenames.

**Design:**

**Rule: Every document that references the canonical payload contract must use the exact filename.**

Canonical filename: `Qwrk_Gateway_Payload_Canonical_v2.md`

Documents that MUST reference this filename:

| Document | Reference Type | Current Status |
|----------|---------------|---------------|
| Q System Instructions | `§Generating Qwrk Commands` | Updated in v2.5.35 |
| QUICK_REFERENCE.md | Header or "Full spec" pointer | Needs verification |
| WORKFLOW_PATTERNS.md | Reference section | Needs verification |
| CC_Prompt_Guidelines.md | Reference section | Needs verification |
| LIFECYCLE_GUIDE.md | Reference section | Needs verification |
| CLAUDE.md | No direct filename ref needed (refers to Gateway contract generically) | OK |
| Work clone IPs (Q@Work + future clones) | Gateway operations IP | Needs verification |

**Clone IP scope (LOCKED):** Clone workspace instruction packs (Q@Work and all future clones) are derivative authority surfaces and MUST follow Pointer Discipline. They must reference Canonical v2 by exact filename and must not redefine payload contract semantics. They do NOT require full Version Bump Protocol (Guardrail A) enforcement — pointer alignment is sufficient.

**On Canonical version bump:** All pointer documents (including clone IPs) must be updated in the same session. This is the same coupling rule as Guardrail A, applied to pointers specifically.

---

## 5. Enforcement Surfaces

### 5.1 Where Each Guardrail Applies

| Guardrail | Trigger | Enforcement Point | Enforcer |
|-----------|---------|-------------------|----------|
| **A: Version Bump Protocol** | Sub-workflow version change | Session (before activation) | CC (proposes), Joel (approves) |
| **B: Contract Regression Checklist** | Any workflow modification | Session (before activation) | CC (runs checklist), Joel (confirms) |
| **C: Pre-Activation Ritual** | Workflow deployment | CLAUDE.md Deployment Checklist step 7 | CC (reminds), Joel (executes) |
| **D: Drift Detection** | Per sprint / per phase gate / on failure | Scheduled or event-triggered | CC (audits), Joel (reviews findings) |
| **E: Pointer Discipline** | Canonical version bump or doc update | Session (same-session coupling) | CC (identifies pointers), Joel (approves updates) |

### 5.2 Human vs. Automated

| Category | Current Design | Future Possibility (Post-Unlock) |
|----------|---------------|--------------------------------|
| Checklist execution | Manual (CC inline) | Scripted diffing of workflow JSON vs Canonical v2 |
| Pointer verification | Manual (CC grep) | Pre-commit hook checking canonical filename references |
| Periodic audit | Manual (CC multi-agent extraction) | Automated workflow JSON parser + Canonical v2 comparator |
| Version coupling | Manual (session discipline) | CI/CD gate blocking activation without doc update |

**Current design is entirely human-enforced.** Automation is a post-unlock optimization, not a prerequisite.

---

## 6. Governance Snapshot Strategy

### 6.1 When to Snapshot Contract State

| Event | Snapshot Required | Content |
|-------|-------------------|---------|
| **Canonical v2 version bump** | YES | Full Canonical vN archived per Pattern C |
| **Post-hardening sprint** | YES | Audit report + pass/fail determination |
| **Phase gate crossing** | YES | Contract alignment confirmation |
| **Runtime failure from contract drift** | YES | Thorn artifact + root cause analysis |
| **Routine workflow version bump** | NO | Covered by version bump protocol inline |

### 6.2 Snapshot Content Requirements

Each contract governance snapshot (Supabase artifact) must include:

| Field | Content |
|-------|---------|
| `artifact_type` | `snapshot` |
| `tags` | `for-q`, `governance`, `contract-alignment` |
| `extension.payload.canonical_version` | Current Canonical version (e.g., "v2") |
| `extension.payload.gateway_version` | Current Gateway version (e.g., "v56") |
| `extension.payload.sub_workflow_versions` | Object: `{ save: "v31", query: "v18", list: "v29", update: "v12", promote: "v2_HTTP" }` |
| `extension.payload.ddl_version` | Current DDL version (e.g., "v2.4") |
| `extension.payload.audit_result` | `PASS` or `FAIL` with finding count |
| `extension.payload.drift_vectors_checked` | Count of vectors audited |

### 6.3 Snapshot Lineage

Contract governance snapshots form a chain:

```
[Canonical v2 Lock] → [Hardening Sprint Audit] → [Phase Gate N] → ...
```

Each snapshot references the previous via `parent_artifact_id` or `extension.payload.prior_snapshot_id`.

---

## 7. Implementation Order (Post-Hardening Sprint)

### Prerequisites (Unlock Conditions)

- [ ] Deterministic Hardening Sprint complete
- [ ] Re-audit returns PASS (no HIGH findings)
- [ ] T51 resolved (branch/limb/leaf extension write)
- [ ] All 9 manual action plan steps from audit review executed

### Recommended Implementation Sequence

| Phase | Guardrail | Effort | Dependencies |
|-------|-----------|--------|-------------|
| **1** | **E: Pointer Discipline** | Low | Verify all pointer documents reference Canonical v2 by exact filename. One-time sweep. |
| **2** | **C: Pre-Activation Ritual** | Low | Add step 7 to CLAUDE.md Deployment Checklist. Single edit. **APPROVED FOR GOVERNANCE EDIT** — may be applied in a separate controlled governance session without waiting for full unlock. |
| **3** | **A: Version Bump Protocol** | Low | Document coupling rule in CLAUDE.md. Behavioral — CC already does most of this. |
| **4** | **B: Contract Regression Checklist** | Medium | Finalize checklist template. Test on next workflow edit. Iterate based on friction. |
| **5** | **D: Drift Detection (event-triggered)** | Low | Embed in Guardrails A+B. No separate mechanism needed. |
| **6** | **D: Drift Detection (periodic)** | Medium | Define sprint cadence. Create reusable audit prompt (like the one that produced the 2026-02-20 audit). |
| **7** | **Governance Snapshot** | Low | Create first contract alignment snapshot post-hardening. |

### Phase 1-3 are quick wins (governance edits only, no workflow changes).
### Phase 4-6 require testing against real workflow changes to validate.
### Phase 7 is a single snapshot creation.

---

## 8. Risk Assessment

### Risks of NOT Implementing

| Risk | Likelihood | Impact | Mitigation Without Guardrails |
|------|-----------|--------|------------------------------|
| Canonical v2 becomes stale (repeat of v1 failure) | HIGH | Critical | None — same failure mode will recur |
| System instructions diverge from Canonical v2 | MEDIUM | Major | Q/Joel notice payloads failing |
| New type added without full contract update | MEDIUM | Critical | Manual vigilance only |
| Sub-workflow updated without Gateway ID update | HIGH | Critical | CLAUDE.md checklist (partial coverage) |

### Risks of THIS Design

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Checklist fatigue (too many steps, gets skipped) | MEDIUM | Major | Keep checklists short; embed in existing flow |
| Over-engineering (guardrails more complex than the system they protect) | LOW | Medium | Design is human-enforced, no automation overhead |
| False security (checklist passes but drift exists) | LOW | Medium | Periodic full audit catches accumulated drift |

---

## 9. Decisions Locked — 2026-02-21

All open questions resolved. These are final policies.

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | **Audit cadence** | Event-triggered + per-sprint. No calendar-based audit. | Sub-workflow bumps, DDL migrations, new types, and runtime anomalies trigger full audit. Per-sprint remains mandatory. Calendar cadence adds overhead without proportional value at current scale. |
| 2 | **Clone IP pointer scope** | Clone IPs included in Guardrail E (Pointer Discipline). | They are derivative authority surfaces. Must reference Canonical v2 by exact filename. Must not redefine payload contract semantics. Do NOT require full Version Bump Protocol enforcement. |
| 3 | **Checklist format** | Inline session discipline. Not a tracked artifact. | Low overhead by design. Executed within deployment session notes. No separate file. |
| 4 | **CLAUDE.md step 7** | Approved for governance edit (separate controlled session). | Adding step 7 (Contract Regression Check) to CLAUDE.md Deployment Checklist is a governance-only edit. Does not require full unlock. Will be applied in a dedicated governance session — not in this thread. |

---

## 10. Relationship to Other Threads

| Thread | Relationship |
|--------|-------------|
| **T51** | Prerequisite. branch/limb/leaf extension write must be implemented before re-audit can pass. |
| **T49** | Related. Version invariant coverage is a checklist item (Guardrail B). |
| **T46** | Independent. Journal append governance is a mutability decision, not a contract drift issue. |
| **T41** | Predecessor. Tags update contract tests (T41) are a model for what Guardrail B checks look like. |
| **Audit 2026-02-20** | Foundation. All drift vectors and findings derived from this audit. |

---

## 11. Thread Status

| Field | Value |
|-------|-------|
| Thread | T52 |
| Status | **Planning Complete** |
| Decisions | All 4 locked (2026-02-21) |
| Implementation | **Deferred** — awaiting Hardening Sprint unlock |
| Unlock Conditions | (1) Deterministic Hardening Sprint complete, (2) Re-audit PASS (no HIGH findings), (3) T51 resolved, (4) Audit review 9-step action plan executed |
| Early Release | CLAUDE.md step 7 governance edit approved for separate session (does not require full unlock) |

**No implementation of any guardrail is authorized until unlock conditions are met.**

---

*This document is a planning deliverable. Version v1.1 — governance locked 2026-02-21.*
