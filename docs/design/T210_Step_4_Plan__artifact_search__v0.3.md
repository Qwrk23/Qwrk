# T210 Step 4 Plan — `artifact.search` — v0.3

> **Mode: PLANNING-ONLY.**
>
> This document plans the *future* implementation of `artifact.search`. It does not authorize implementation, cert authoring with expected-values, dev-clone creation, sub-workflow creation, cert-harness edits, ACL/credential changes, live regression baseline runs, or merge-back. Each of those is a separate governed step.
>
> **Manus amendments A1–A7 incorporated** (see CHANGELOG §v0.3).
>
> **Q2 (Score formula) remains OPEN and CRITICAL.** Per Manus A6: any implementation-ready successor, cert-authoring plan with expected-values, or dev-clone authorization packet MUST close Q2 first. Planning-only v0.3 may carry Q2 open.

---

## CHANGELOG

### v0.3 — 2026-05-15

**What changed (v0.2 → v0.3):** Incorporated Manus TQR amendments A1–A7 on Step 4 Plan v0.2 (approve-with-amendments).
- **A1 — TQR posture wording corrected.** Document header now distinguishes prior recovery-integrity Manus TQR (proceed with amendments) from current Step 4 Plan v0.2 TQR (approve with amendments). v0.3 itself is unratified pending fresh TQR.
- **A2 — Q4 tightened.** Live regression baseline reframed as a future operational action requiring separate Joel approval through the governed path. Any wording suggesting this review authorizes a live cert run removed.
- **A3 — P8/P9/P10 mapping-gap register added.** New §5.4.2 documents three P-families with no current direct cert mapping, each with explicit pre-cert review requirements. P10 carries heaviest review obligation (depends on Q2).
- **A4 — Q7 persistence clarified.** Inline review acceptable; ratified planning state that becomes basis for v0.4 / execution planning must be persisted with provenance before reliance.
- **A5 — Action language reworded.** Objective and downstream language changed from "Implement artifact.search" to "Plan the future implementation of artifact.search" (planning-only framing throughout).
- **A6 — v0.3 mode distinction added.** Planning-only v0.3 may carry Q2 open as critical blocker. Any implementation-ready / cert-authoring-with-expected-values / dev-clone-authorization successor must close Q2 first.
- **A7 — Provenance limitation note added.** "Snapshot existence was asserted by CC/plan. Manus reviewed the plan text and cited boundary; Manus did not independently verify Prime state." Applied across snapshot references throughout.
- New risk R6 (live baseline non-authorization) added to §4.3.
- §7 non-goals extended with two additional v0.3 non-goals.
- Lineage section explicit about v0.1 / v0.2 supersession.

**Why:** Manus TQR returned APPROVE WITH AMENDMENTS on v0.2. Amendments tighten posture wording, action framing, blocker severity model, provenance limitations, and persistence semantics. All amendments preserve original boundaries.

**Scope of impact:**
- Document this file only — no code, no DDL, no Gateway, no n8n, no cert harness, no ACL, no credentials.
- Plan content and structure preserved verbatim from v0.2 where not amended.
- v0.3 supersedes v0.1 (inline, session 145 first draft) and v0.2 (inline, this session after Q1 closure).

**How to validate:**
- Search this file for "planning-only" — present in header, §1, §5.1, §5.6, §5.7, §10, and CHANGELOG.
- Search for "A1", "A2", … "A7" — each amendment annotated at its application site.
- Search for "subject to A7" — provenance limitation applied at every snapshot reference.
- Confirm §5.4.2 P8/P9/P10 mapping-gap register present.
- Confirm §8.2 Q2 row carries CRITICAL severity with A6 statement.
- Confirm §8.2 Q4 row carries A2 reframing (future operational action, separate Joel approval).
- Confirm §8.2 Q7 row carries A4 reframing (inline review acceptable; persistence required before reliance).
- Confirm §7 carries 12 base non-goals + 2 additional v0.3 non-goals (Q4 + A6).

### v0.2 — 2026-05-15 (inline-only, superseded)

**What changed (v0.1 → v0.2):** Integrated recovered P1–P10 matrix from Path B DDL Plan v0.3 §6.2 (Q1 resolution) into §5.4 P-family table as probe/substrate support material. Preserved source distinction (Walk Memo §3.3 = determinism contract; Path B DDL Plan §6.2 = P1–P10 query/probe matrix).

**Why:** Q1 (P1–P10 matrix not recovered) was the headline blocker on v0.1. Recovery cycle returned FOUND_FULL for §1.2 / §7 / §8.2, FOUND_PARTIAL for §3.3 (correct — §3.3 is determinism contract, not P1–P10), and FOUND_FULL for Path B DDL Plan §6.2 P1–P10. Integration unblocked v0.2.

**Scope of impact:** Inline drafting only. No repo file existed. No mutations.

**How to validate:** Superseded — historical only.

### v0.1 — 2026-05-15 (inline-only, superseded)

**What changed:** First Step 4 plan draft after T210 substrate acceptance (snapshot `efa3861f`, 2026-05-13).

**Why:** Substrate built and accepted; next step is to plan dev-parallel build of `artifact.search` against it.

**Scope of impact:** Inline drafting only. No repo file existed. No mutations.

**How to validate:** Superseded — historical only.

---

# Step 4 Plan v0.3 — Plan the Future Implementation of `artifact.search`

**Document type:** Planning artifact (§11 Planning Gate output for the Walk-phase planning of `artifact.search`).
**Mode (per Manus A6):** **Planning-only.** This plan does not constitute, authorize, or substitute for an implementation-ready plan, a cert-authoring plan with expected-values, or a dev-clone authorization packet. Any such successor document MUST close Q2 first.
**Scope discipline:** This plan documents WHAT WOULD BE PLANNED FURTHER. It does NOT authorize implementation, cert authoring with expected-values, dev clone creation, live regression baseline runs, or any operational action against live surfaces.
**Recovery anchor:** Snapshot `354dd79d-9632-4d11-9f6e-54701ea0545f` (Walk-Design Preflight Memo v0.3 §§1.2, 3.3, 7, 8.2 + Path B DDL Plan v0.3 §6.2 + recovery ledger + blocker register + recovery-integrity Manus TQR boundary).

**TQR posture (per Manus A1):**
- Prior recovery-integrity Manus TQR: proceed with amendments.
- Current Step 4 Plan v0.2 TQR: completed; result approve with amendments.
- This document (v0.3) carries the v0.2 amendments and is itself unratified pending fresh TQR.

**Provenance limitation note (per Manus A7):** Snapshot existence was asserted by CC/plan. Manus reviewed the plan text and cited boundary; Manus did not independently verify Prime state.

**Status:** Drafting; Q1 RESOLVED; Q2 OPEN (CRITICAL, blocking for implementation-ready successors per A6); Q3–Q7 OPEN.

---

## §1 — Objective

**Plan the future implementation** of `artifact.search` as a new Gateway action against the Path B substrate already built (milestone `efa3861f`), to be executed (in a future authorized step) behind a cloned dev gateway, validated by the cert harness extension (C1–C33) specified in recovered Walk Memo v0.3 §7, with **no regression** in the live Gateway and **no DDL** required beyond the indexes already accepted in Phase 1 of `efa3861f`.

This plan does not authorize execution, cert authoring with expected-values, or dev-clone creation. Authorization for those is a sequence of separate Joel decisions, each gated on the corresponding blocker closures in §8.

---

## §2 — Mutation Surface (Clone-Only)

| Surface | Mutation status in this plan |
|---|---|
| Live Gateway `NQxb_Gateway_v2` | **NOT mutated** |
| Sub-workflows (Save, Query, List, Update, Promote) | **NOT mutated** |
| DDL / `qxb_*` tables | **NOT mutated** (substrate already exists from `efa3861f`) |
| Cert harness `Phase2C_Cert/Run-Phase2C-Cert.ps1` | **NOT mutated**; extension spec exists in recovered §7; harness edits are downstream of recovered §8.2 Step 5 |
| Live `qxb_gateway_acl` rows | **NOT mutated** |
| Live cert run (Phase 2C baseline against live) | **NOT executed** — see §4.3 R6 and §8.2 Q4 |
| `_dev` gateway clone | **WOULD BE CREATED** in a future authorized step — out of scope for this plan |
| `NQxb_Artifact_Search_v1` sub-workflow | **WOULD BE CREATED** under dev clone in a future authorized step — out of scope for this plan |

§9 Parallel Build Safety is satisfied by construction at the plan level: this plan is planning-only and authorizes no parallel build action. Future Step 4 execution will inherit §9 constraints.

---

## §3 — §9 Parallel Build Compliance (forward-looking statement)

Per CLAUDE.md §9, parallel-isolated build is the default. v0.3 commits future Step 4 execution to:

1. **Live protection (§9.1):** No edits to `NQxb_Gateway_v2` or its sub-workflows until §6 cert PASS + §5 no-regression check + §8 blockers all closed.
2. **Parallel workflow (§9.2):** A cloned `NQxb_Gateway_v2_dev` would be the contract-identical container. Differences: new credential binding, new ACL identity, addition of `artifact.search` route.
3. **No-regression guarantee (§9.3):** Existing artifact.* and messaging.* actions must run on the dev clone with identical behavior, validated by running the existing Phase 2C cert against the dev clone before any merge-back. (Live baseline capture is a separately governed action — §8.2 Q4 / §4.3 R6.)
4. **Controlled merge-back (§9.4):** Merge from `_dev` → live is a separate Joel approval gate (recovered §8.2 Step 6). Not authorized by this plan and explicitly out of scope.
5. **Scope discipline (§9.5):** Feature addition only. No cleanup, no refactor, no architectural improvements to live Gateway code paths. Anything beyond `artifact.search` introduction is out of scope.

---

## §4 — §11 Planning Gate Output

### §4.1 — Surfaces touched (real plan-level)
- Documentation surface: this plan v0.3 (this file; companion snapshot is a separate Joel-executed save per §2.5 read-only rule).
- Operational surfaces (future, not authorized): n8n (clone + new sub-workflow), `qxb_gateway_acl` (new dev row), Phase 2C cert harness (extension cases C1–C33), live baseline run.

### §4.2 — Dependencies (deps a–h)
- **(a)** Recovery-integrity snapshot `354dd79d` — ✓ ASSERTED PRESENT (subject to A7 provenance limitation)
- **(b)** Milestone substrate snapshot `efa3861f` — ✓ asserted present (2026-05-13; subject to A7)
- **(c)** Walk Memo v0.3 §1.2 (payload contract) — ✓ RECOVERED via `354dd79d`
- **(d)** Walk Memo v0.3 §3.3 (determinism contract) — ✓ RECOVERED via `354dd79d`
- **(e)** Walk Memo v0.3 §7 (cert C1–C33 spec) — ✓ RECOVERED via `354dd79d`
- **(f)** Walk Memo v0.3 §8.2 (gated 7-step sequence) — ✓ RECOVERED via `354dd79d`
- **(g)** Path B DDL Plan v0.3 §6.2 (P1–P10 matrix) — ✓ RECOVERED via `354dd79d` (probe/substrate support material — see §5.4 boundary)
- **(h)** Q2–Q7 blocker closure — ⚠ OPEN (see §8); Q2 closure required before any implementation-ready successor (per A6)

### §4.3 — Risk register (R1–R6)
| ID | Risk | Mitigation |
|---|---|---|
| R1 | Dev clone drifts from live (binding, ACL, env) and cert PASS on dev fails to predict live behavior | Pre-clone diff manifest; existing Phase 2C cert run against dev as no-regression check (recovered §8.2 Step 4). Note: live baseline capture is separately governed — see R6. |
| R2 | Q2 score formula remains unresolved → rank logic + cert C15 expected-values not implementable | Block any implementation-ready successor (per A6) until Q2 closed. **Q2 carries dual blocking weight per A6.** |
| R3 | P9 (semantic_type recency) measured at 28.8ms but planner bypassed `idx_qxb_artifact_semantic_type` — composite `(workspace_id, semantic_type_id, created_at DESC)` may be required sooner than expected | Probe outcomes captured in `efa3861f` (subject to A7); trigger condition (>~5% traffic) remains the deferral criterion |
| R4 | Cert harness extension (§7 spec) lands during live freeze or merges before contract lock → contract-vs-test divergence | Cert harness edits prohibited until Step 5 (recovered §8.2). This plan explicitly excludes them. |
| R5 | Persistence-gap-fix (Q7) — drafted v0.1/v0.2 lived inline only; this v0.3 file write is the persistence step. Per A4, any ratified planning state that becomes basis for v0.4 / execution planning must be persisted with provenance before reliance. | This file write satisfies repo provenance. Companion snapshot (Joel-executed via QSB) satisfies cross-system provenance. |
| R6 | **Live regression baseline run (Q4) is a future operational action** requiring separate Joel approval through the governed path. This plan does not authorize a live cert run; mistaking review of v0.3 for such authorization would violate §2.5 read-only posture and §9 live protection. | A2 amendment text incorporated. Live baseline capture remains explicitly unauthorized. |

### §4.4 – §4.9 — Substeps (numbered, no actions taken)
- **§4.4** Plan v0.3 file landed (this turn) — IN PROGRESS at write-time
- **§4.5** Q2 score-formula recovery cycle (separate from v0.3; gated by Joel). **Required before any implementation-ready successor (A6).**
- **§4.6** Q3–Q7 recovery cycle OR deferral decisions (Joel)
- **§4.7** Plan v0.3 → v0.4 amendment incorporating Q2–Q7 outcomes
- **§4.8** TQR ratification of v0.4 (Q + Manus)
- **§4.9** Joel ratification + §4 Pre-Write Gate for persistence (file + companion snapshot) — required per A4 before v0.4 / execution planning can rely on the ratified state

No substep authorizes implementation, cert authoring with expected-values, dev-clone creation, or live baseline runs. Each is downstream of its own gate.

---

## §5 — Implementation Scope (planning-only)

### §5.1 — Future in-scope artifacts (planned, not authorized for creation)
- Cloned gateway `NQxb_Gateway_v2_dev` (n8n workflow)
- New sub-workflow `NQxb_Artifact_Search_v1` (n8n)
- New ACL row in `qxb_gateway_acl` for dev principal
- New basic-auth credential in n8n for dev principal
- Cert harness extension cases C1–C33 (Phase 2C extension; recovered §7)

None of the above are authorized for creation by this plan.

### §5.2 — Out-of-scope (hard exclusions)
- Live Gateway mutation; Existing sub-workflow edits; DDL changes; Schema migrations; Live ACL row changes; Live regression baseline run; pgvector / unaccent / I6 summary trigram / composite `(workspace_id, semantic_type_id, created_at DESC)` (all deferred per `efa3861f`, subject to A7); Q-side resolve behavior; Operator Console consumer; Performance probe pass/fail (separate gate per recovered §7.1).

### §5.3 — Payload contract (referenced, not redefined)
Reference only — full field rules + validation order (M1–M10) live in recovered §1.2 in snapshot `354dd79d` (subject to A7). Plan v0.3 references that block as the normative contract; does NOT redefine it. Q5 (response envelope normative spec) remains OPEN — if Q5 closes against an extended §1.2, that update flows into plan v0.4.

### §5.4 — P-family table (probe / substrate support material)

**Boundary (carried from v0.2 + A3):** §5.4 is **probe/substrate support**. It is **NOT** the Gateway contract surface (that is recovered §1.2) and **NOT** the cert matrix (that is recovered §7 C1–C33). §5.4 documents which physical substrate elements the future implementation would plan against and what their probe outcomes were.

Source: Path B DDL Plan v0.3 §6.2 (verbatim P1–P10 predicates in snapshot `354dd79d`; subject to A7).
Probe outcomes: DDL Execution Packet v0.1 Phase 3, captured in milestone `efa3861f` (subject to A7).

| P | Pattern | Expected substrate | Probe outcome |
|---|---------|---------------------|----------------|
| P1 | `tags ?\| ARRAY[...]` | I3 GIN tags + I1 narrowing | 2.2ms |
| P2 | `tags ?& ARRAY[...]` | I3 GIN tags | 0.15ms |
| P3 | combined ?\| + ?& | I3 (planner combined bitmap) | 0.12ms |
| P4 | ws + soft-delete + ORDER BY created_at | I1 (range scan, no sort) | 0.18ms |
| P5 | + artifact_type = X | I2 (range scan, no sort) | 0.22ms |
| P6 | + artifact_type IN (...) | planner bypassed I2; used I1 + post-filter | 0.18ms |
| P7 | created_at half-open [T1, T2) | I1 (range scan) | 0.19ms |
| P8 | parent_artifact_id = X | I5 | 3.1ms |
| P9 | semantic_type_id = X + ORDER BY recency + LIMIT | existing idx_qxb_artifact_semantic_type bypassed → heap filter | 28.8ms |
| P10 | title %  q + ORDER BY similarity DESC | I4 GIN trgm + I1 narrow; 76:1 recheck ratio | 50.5ms |

All P-families append `ORDER BY ..., created_at DESC, artifact_id ASC` (consistent with §5.5 determinism contract, sourced from Walk Memo §3.3).

### §5.4.1 — Marker namespaces

| Namespace | Origin | Cardinality | Examples |
|---|---|---|---|
| **M1–M10** | Walk Memo v0.3 §1.2 / §3.3 / §7 validation-order markers | 10 fixed | M1 (top-level artifact_type forbidden), M5 (deterministic tie-floor), M8 (8-step validation order), M9 (score evidence bounds), M10 (matched_fields correctness) |
| **M-S<n>** | Path B DDL Plan v0.3 §6 substrate markers (probe-derived) | open-ended | M-S7 (I2 + multi-type sort behavior — P6), M-S10 (summary fuzzy not indexed — P10 note) |

**Boundary:** M1–M10 are normative for Gateway contract + cert. M-S<n> are advisory for implementation choice + future substrate evolution decisions. Do NOT conflate.

### §5.4.2 — P8/P9/P10 Mapping-Gap Register (per Manus A3)

Three P-families lack direct cert mapping at this draft. Each carries an explicit pre-cert review requirement. None may be relied on for cert authoring or implementation-ready claims until reviewed.

| P-family | Pattern | Mapping-gap statement | Review required against |
|---|---|---|---|
| **P8** | parent_artifact_id lookup | No direct cert mapping currently identified | Must be reviewed before cert authoring |
| **P9** | semantic_type_id filter + recency order | No direct cert mapping currently identified | Must be reviewed before cert authoring |
| **P10** | title fuzzy (pg_trgm) | No direct cert mapping currently identified | Must be reviewed against C1–C33 cert matrix, Q2 score formula, Q5 response envelope, `matched_fields` semantics, and `score_components` semantics before cert authoring or implementation-ready rank claims |

P10 carries the heaviest review obligation because fuzzy ranking is the most rank-formula-dependent of the three. P10 review depends on Q2 closure.

### §5.5 — Determinism (sourced from Walk Memo §3.3)

> **Source-distinction reminder:** Walk Memo §3.3 is the determinism contract. It is NOT the P1–P10 matrix. P1–P10 lives in Path B DDL Plan §6.2 (probe support, §5.4 above).

Tiebreaker chain: `score DESC → created_at DESC → artifact_id ASC` (artifact_id unique → deterministic floor exists). Cert C27 (M5) verifies the floor is exercised when score and created_at collide.

§5.5 ties into Q2 (score formula): until Q2 closes, the rank function backing `score DESC` is undefined, which means C15 expected-values, C27 fixture construction, and any production rank logic are all blocked. **Q2 is the highest-leverage blocker.** Planning-only v0.3 carries Q2 open per A6; any successor positioned for implementation, cert expected-values, or dev-clone authorization must close Q2 first.

### §5.6 — Sub-workflow shape (advisory, not specification, planning-only)
Future shape sketch only. A single sub-workflow `NQxb_Artifact_Search_v1` would be called from Gatekeeper `call_search` (Execute Workflow node, typeVersion 1.3, `onError: continueRegularOutput`, `alwaysOutputData: true` per Session 123 hardening pattern). Internal node sketch deferred — depends on Q2 (rank) and Q5 (response envelope). Nothing in §5.6 authorizes construction.

### §5.7 — Workspace + soft-delete invariants (sourced from Walk Memo §1.2 + §1.4, planning-only)
Every future `artifact.search` execution path would apply two mandatory predicates: `workspace_id = <envelope>` AND `deleted_at IS NULL`. These are not user-controllable filters; they are unconditional. Cert C2/C3/C5/C6 validate this in future cert authoring.

### §5.8 — Substrate↔Contract↔Cert bridge

| Source | What it provides | Lives in |
|---|---|---|
| Path B DDL Plan §6.2 (P1–P10) | Physical predicate/index pairings + observed performance | Probe support (§5.4) |
| Walk Memo §1.2 (M1–M10) | Payload field rules + validation order | Gateway contract (§5.3) |
| Walk Memo §3.3 | Order determinism contract | §5.5 |
| Walk Memo §7 (C1–C33) | Cert assertions | §6 |

Cross-references:
- P1 ↔ C13 (tags_any OR semantics)
- P2 ↔ C14 (tags_all AND semantics)
- P3 ↔ C26 (combined AND/OR semantics)
- P4–P7 ↔ C7 / C19 / C21 / C28 (pagination / type filters / has_more / date interval)
- **P8, P9, P10 ↔ mapping-gap register §5.4.2** — pre-cert review required before any cert authoring or implementation-ready rank claim

---

## §6 — Cert C1–C33 (referenced, not redefined)

Plan v0.3 cites recovered Walk Memo v0.3 §7 verbatim as the cert specification surface. Plan does NOT author cert cases. Plan does NOT author cert harness code. Plan binds (forward-looking):

- **C1, C7, C27** depend on Q2 (rank/score formula closure) for fixture construction.
- **C15 (M9)** explicitly depends on Q2 — score values must be numeric, bounded `[0,1]`, with `score_components` present and `weights` absent from response envelope. Cannot author expected-values without Q2.
- **C2–C6, C8–C14, C16–C26, C28–C33** are independent of Q2; would be authorable after the §5.4.2 mapping-gap review and the §8.2 Q3/Q5 closures.
- **Path-conditional cases (Q3 OPEN):** TBD which cert cases are skipped under specific gateway/build configurations.
- **P8/P9/P10 mapping-gap (§5.4.2):** future cert authoring against any of these P-families requires the §5.4.2 pre-cert review.

Cert authoring is downstream of recovered §8.2 Step 5. Plan v0.3 does not author cert and does not authorize cert authoring.

---

## §7 — Non-Goals

1. No live Gateway mutation.
2. No DDL execution (substrate already accepted in `efa3861f`, subject to A7).
3. No dev clone creation in this turn or by this plan.
4. No sub-workflow creation in this turn or by this plan.
5. No cert harness edits in this turn or by this plan.
6. No merge-back planning in this turn or by this plan (Step 6 is downstream).
7. No pgvector / semantic search introduction (Run-phase, T81 lineage).
8. No I6 summary trigram or composite `(ws, semantic_type, created_at DESC)` index addition (deferred per `efa3861f` decisions).
9. No unaccent extension (deferred per `efa3861f`).
10. No Q-side resolve behavior change.
11. No Operator Console consumer wiring.
12. No performance pass/fail assertion in cert (separate measurement gate per recovered §7.1).

**Additional v0.3 non-goal (per A2):** No live regression baseline run; no authorization of such a run by this review.

**Additional v0.3 non-goal (per A6):** No implementation-readiness, no cert expected-values authoring, no dev-clone authorization. Each is a separate successor document.

---

## §8 — Blockers

### §8.1 — Q1 (RESOLVED previously, carried in v0.3)
P1–P10 query/probe matrix — RECOVERED via `354dd79d` → integrated as probe/substrate support material in §5.4. Source-distinction preserved (Walk Memo §3.3 ≠ Path B DDL Plan §6.2). Subject to A7 provenance limitation.

### §8.2 — Q2–Q7 (OPEN)

| ID | Blocker | Severity | Blocks |
|---|---------|----------|--------|
| **Q2** | **Score formula** — rank logic backing the `score DESC` tiebreaker primary; cert C1, C15 (M9), C27 expected-values; P10 rank claims (§5.4.2) | **CRITICAL — blocks any implementation-ready v0.4, cert expected-values, dev-clone authorization (per A6)** | §5.5 determinism (rank function), §5.6 sub-workflow shape, §6 cert C1/C15/C27 fixture construction, §5.4.2 P10 pre-cert review |
| Q3 | Path-conditional cert exclusions — which C-cases are skipped under which gateway/build configurations | Medium | §6 cert authoring; cert harness extension (recovered §8.2 Step 5) |
| Q4 | **Live regression baseline** — explicit "what passes today on live" capture. **Per A2: this is a future operational action requiring separate Joel approval through the governed path. This review does NOT authorize a live cert run.** | Medium | Future dev-clone authorization packet; §3 no-regression guarantee instrumentation. |
| Q5 | Response envelope normative spec — what `data.candidates[]`, `meta`, `score`, `score_components`, `matched_fields` look like field-by-field | Medium | §5.3 contract; §6 cert response-shape assertions; §5.4.2 P10 review |
| Q6 | Explicit Path B lock — written governance record locking Path B vs alternatives (substrate already built, but the path-choice lock per recovered §8.2 Step 2 not yet papered) | Low (functional substrate exists; governance papering open) | Persistence of v0.4 (Q7-linked); Manus future-state authority |
| Q7 | **Persistence-gap-fix recommendation** — plan v0.1 / v0.2 lived inline only; v0.3 is the persistence step. **Per A4: inline review is acceptable, but any ratified planning state that becomes the basis for v0.4 or execution planning must be persisted with provenance before reliance.** | Medium (procedural; becomes blocking the moment v0.4 ratification is sought) | All future ratified plan revisions; pre-implementation freeze |

### §8.3 — Resolution paths
- **Q2 first:** Recovery cycle against Walk Memo v0.3 §§ outside the already-recovered set (likely §4 / §5 / §6) and/or against Path B DDL Plan v0.3 outside §6.2; alternatively defer to dev-build work product. **Defer is structurally allowed for planning-only v0.3 (per A6) but is NOT allowed for any implementation-ready successor, cert-authoring plan with expected-values, or dev-clone authorization packet.**
- **Q3, Q5:** Recovery cycle likely succeeds; both are spec-shaped.
- **Q4:** Future operational action requiring separate Joel approval through the governed path (per A2). Not authorized here.
- **Q6:** Authoring — write a governance lock snapshot referencing `efa3861f` + this plan once v0.4 ratifies.
- **Q7:** This v0.3 file write + companion snapshot (Joel-executed via QSB) satisfies Q7 for v0.3 ratification reliance.

---

## §9 — Plan Lineage & Provenance

| Predecessor | Role |
|---|---|
| Snapshot `efa3861f` | Substrate milestone — Path B accepted, 5 indexes + pg_trgm live, 10/10 probe families <100ms (subject to A7) |
| Snapshot `542cf4c1` (T209 seed) | Discovery layer ancestor |
| Snapshot `959a060d` (T209 root) | Discovery layer root |
| Snapshot `354dd79d` | Recovery integrity — this plan's source-of-truth anchor for §1.2/§3.3/§6.2/§7/§8.2/ledger/blocker register/recovery-integrity Manus TQR boundary (subject to A7) |
| Plan v0.1 (inline, session 145) | Predecessor draft; superseded |
| Plan v0.2 (inline, this session) | Predecessor draft; TQR approve-with-amendments returned; superseded by this v0.3 |

This plan v0.3 supersedes v0.1 and v0.2.

**Provenance limitation (per A7):** Snapshot existence (`354dd79d`, `efa3861f`, `542cf4c1`, `959a060d`) was asserted by CC/plan. Manus reviewed plan text and cited boundary; Manus did not independently verify Prime state. Any future ratification that relies on snapshot state should include independent verification before relying on the snapshot contents as authoritative.

---

## §10 — Closure Conditions for v0.3

v0.3 is closed (and ready for TQR → ratification → optional persistence per A4) when:

1. Manus + Q complete TQR pass on v0.3 (this turn produces the input).
2. Joel ratifies v0.3 OR directs v0.3 → v0.4 amendment.
3. **If v0.3 (or any successor) is to be relied upon as the basis for v0.4 or execution planning, persistence with provenance is required first (per A4).** This v0.3 file write + companion snapshot satisfy that requirement for v0.3 itself.

If v0.4 is positioned as **implementation-ready**, **cert-authoring with expected-values**, or **dev-clone authorization**, Q2 must close before v0.4 ratification (per A6).

This plan v0.3 is **TQR-READY** in planning-only mode.

---

**Status:** Persisted. No operational mutations. Q1 resolved; Q2 open and CRITICAL (blocks any implementation-ready successor per A6); Q3–Q7 carried as open. Source distinction preserved throughout. A1–A7 amendments incorporated.
