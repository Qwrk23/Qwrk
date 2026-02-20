# Instruction Pack — Phase 2 Governance Hardening Amendments (v1)

**artifact_id:** *(generated on insert)*
**scope:** `architecture:workflow`
**pack_version:** `v1`
**status:** Active
**created:** 2026-02-15
**origin:** Save v27 hardening audit — deterministic error routing validation

---

## Purpose

Encodes governance rules validated during Phase 2 (Crawl — Lifecycle Governance) troubleshooting. These rules formalize architectural invariants discovered during Save v26 → v27 error routing hardening and full orchestration audit.

This is a governance clarification update. No schema changes. No lifecycle redesign. No behavioral expansion.

---

## Phase 2 Governance Hardening Amendments

### Amendment 1: Production Workflow Purity Rule

**ID:** `gov-prod-purity`

**Invariant:** Production workflows MUST NOT contain debug-only nodes.

**Rules:**

1. No Code node may return early for instrumentation purposes.
2. No temporary "testing" or "debug" nodes may exist in activated workflows.
3. Any instrumentation must be removed before activation.
4. Any early `return` in a `Normalize_*` node is prohibited.
5. Debug artifacts are allowed only in isolated development branches, never in activated workflows.

**Rationale:** During Save v26 audit, instrumentation remnants and debug patterns were identified as vectors for silent data loss. Production workflows must contain only nodes that serve the canonical request-response pipeline.

**Enforcement:** Manual review before workflow activation. Transformation scripts must include purity verification.

---

### Amendment 2: Normalize Node Contract

**ID:** `gov-normalize-contract`

**Invariant:** All `Normalize_*` nodes must produce a single canonical output shape without discarding valid upstream fields.

**Contract:**

1. Exactly one return statement per Normalize node.
2. That return must output the canonical object shape for the pipeline stage.
3. No conditional early exits.
4. No mutation of `_gw_route`, `ok`, or `gw_action` fields.
5. No stripping of canonical fields previously established by Gateway.
6. Normalize nodes may read dual-shape input (raw webhook vs pre-normalized) but must output a single canonical shape.
7. All fields required by downstream nodes must be forwarded explicitly.

**Doctrine:**

> Canonicalization is idempotent and monotonic. It may enrich shape but must never discard valid canonical fields.

**Rationale:** BUG-015 (transition/reason dropped) and T26 (selector.limit/offset ignored) were both caused by `Normalize_Request` failing to forward canonical fields. This contract prevents the entire bug class.

**Enforcement:** Normalize node output must be verified against downstream field dependencies before activation.

---

### Amendment 3: Deterministic Error Routing Rule

**ID:** `gov-deterministic-error-routing`

**Invariant:** Every `{ ok: false }` envelope must reach a response node. No error may be silently swallowed.

**Rules:**

1. Every workflow must guarantee that any `{ ok: false }` envelope reaches a response-shaping node.
2. No Switch node may have an unconnected output branch (empty connection array `[]`).
3. No error-producing node may flow into a dead end.
4. Sub-workflows must not swallow validation errors or registry errors.
5. Error envelopes must remain structurally intact throughout the pipeline — no field stripping, no shape mutation.
6. Guard nodes (IF: `ok === false`) must be placed immediately after any node that can produce error envelopes, before the item flows through irrelevant downstream nodes.

**Doctrine:**

> Error envelopes are first-class citizens and must travel deterministically to response shaping.

**Rationale:** Save v26 had two dead-end Switch branches where validation errors and type registry errors were silently dropped (items routed to `[]` connections). This was the root cause of the "missing error response" class of bugs. Save v27 hardened all three error paths with explicit routing to `Return_Response`.

**Enforcement:** Transformation scripts must include integrity verification that checks all Switch outputs for non-empty connections. Dead-end detection is a blocking check — scripts must `process.exit(1)` on failure.

---

### Amendment 4: Phase Boundary Enforcement Rule

**ID:** `gov-phase-boundary`

**Invariant:** Phase scope is enforced by registry, not by convention.

**Rules:**

1. Phase 2 (Crawl) includes lifecycle governance only: `project`, `journal`, `snapshot`, `restart`, `grass`, `thorn`, `instruction_pack`.
2. Execution types (`leaf`, `branch`, `limb`) belong to Phase 2B (Walk).
3. Execution types must not be registered or tested during Crawl.
4. The Gateway Type Registry is the enforcement boundary for phase scope — if a type is not registered, the Gateway rejects it.
5. Phase expansion requires explicit governance approval before registry updates.

**Doctrine:**

> Phase boundaries are enforced by registry, not by convention.

**Rationale:** During troubleshooting, type branching logic (Switch_Type_For_Insert, Switch_Type_For_Update) was found to handle only 5 of 12 CHECK constraint types. This is correct for Phase 2 Crawl — the remaining types belong to future phases and are blocked at the registry level.

**Enforcement:** Type Registry entries determine which types flow through the pipeline. Adding a type to the registry is a phase-scoped governance decision, not a code change.

---

### Amendment 5: Gateway Canonical Authority Rule

**ID:** `gov-gateway-authority`

**Invariant:** Gateway defines shape. Sub-workflows implement behavior.

**Rules:**

1. Gateway `Normalize_Request` is the authoritative source of canonical envelope shape.
2. Sub-workflows must treat the inbound canonical envelope as source of truth for all gateway-level fields.
3. Sub-workflows must not reconstruct canonical envelope fields independently (no re-deriving `gw_workspace_id`, `gw_action`, `artifact_type` from raw input).
4. No sub-workflow may override canonical fields established by Gateway.
5. Sub-workflows may add new fields to the envelope (enrichment) but must never remove or mutate Gateway-established fields.

**Doctrine:**

> Gateway defines shape. Sub-workflows implement behavior.

**Rationale:** The full orchestration audit confirmed that Gateway routing is architecturally sound — it correctly routes normalized envelopes to sub-workflows via Execute Workflow nodes. Errors were internal to sub-workflows (Save v26), not caused by Gateway shape corruption. This rule formalizes the trust boundary.

**Enforcement:** Sub-workflow Code nodes must reference upstream fields via `$json` or `$node[]` from the canonical envelope, not from raw webhook data or independent derivation.

---

## Cross-Reference: Bugs Sealed by These Amendments

| Amendment | Bug / Issue | How Sealed |
|-----------|-------------|------------|
| Amendment 1 | Debug node contamination risk | Purity rule prevents debug artifacts in production |
| Amendment 2 | BUG-015 (transition/reason dropped), T26 (selector stripped) | Monotonic canonicalization prevents field loss |
| Amendment 3 | Save v26 dead-end Switch branches | Deterministic routing eliminates silent error swallowing |
| Amendment 4 | Out-of-phase type testing confusion | Registry enforcement prevents premature type activation |
| Amendment 5 | Sub-workflow envelope reconstruction risk | Authority rule prevents independent shape derivation |

---

## Scope and Non-Goals

This pack encodes governance validated during Phase 2 Crawl troubleshooting.

**In scope:**
- Workflow purity requirements
- Normalize node behavioral contract
- Error routing determinism
- Phase boundary enforcement
- Gateway authority model

**Explicitly NOT in scope:**
- Phase 2B (Walk) execution type behavior
- Schema changes or DDL modifications
- Lifecycle stage additions or modifications
- New artifact type registration
- Runtime behavioral changes to existing workflows

---

## CHANGELOG

### v1 — 2026-02-15
**What changed:** Initial creation. Five governance amendments formalized from Phase 2 Crawl troubleshooting.

**Why:** Save v27 error routing hardening and full orchestration audit revealed governance gaps that were being enforced by convention rather than doctrine. These amendments make the rules explicit.

**Scope of impact:** Governance documentation only. No runtime behavior altered. No workflows modified. No schema changes.

**How to validate:**
- Review each amendment against the corresponding bug/issue in the cross-reference table
- Confirm that Save v27, Gateway v50+, and the orchestration audit findings align with these rules
- Verify no Phase 2B behavior is introduced

---

*Registered in qxb_artifact_instruction_pack with scope: architecture:workflow*
