# Surface Unification & Prompt Output Hardening

## Outcome
Unify Telegram Gateway and QX (Chrome Extension) to a single canonical JSON payload contract, then enforce deterministic rendering invariants for all execution-facing outputs.

**Done means:**
1. Telegram Gateway accepts the exact same JSON envelope as QX.
2. No dual-shape normalization paths remain.
3. All Gateway-bound payloads render in a single markdown code block (no surrounding prose).
4. All Claude Code prompts render in canvas only.
5. A validation gate prevents formatting drift before delivery.
6. No regression to existing Gateway behavior.

---

# Phase 1 — Payload Surface Unification

## Goal
Eliminate divergence between Telegram NL formatting and QX JSON execution format.

## Requirements
- Telegram must accept the identical JSON envelope used by QX.
- Remove NL parsing dependencies that fabricate or transform save requests.
- Ensure Normalize_Request supports a single canonical input shape.
- Preserve existing validation, registry enforcement, and error routing invariants.

## Non-Goals
- No lifecycle changes.
- No schema changes.
- No artifact type expansion.
- No Phase 2B execution semantics work.

## Deliverable
Before implementation, provide a minimal change plan including:
- Exact workflows affected
- Nodes to modify or remove
- Regression risks
- Rollback path

Do not implement until plan is approved.

---

# Phase 2 — Rendering Invariants

After Phase 1 is complete and verified, implement the following invariants:

## Invariant A — Gateway Payload Rendering
All Gateway-bound payloads must:
- Render in a single markdown code block
- Contain raw JSON only
- Include no surrounding prose
- Include exactly one payload per execution

## Invariant B — Claude Code Prompt Rendering
All prompts intended for Claude Code must:
- Render in canvas only
- Contain no surrounding analysis or commentary
- Be fully execution-ready
- Follow CC Prompt Formulation Guidelines

## Invariant C — Validation Gate
Introduce a rendering validation check prior to delivery:
- If a Gateway payload is generated without markdown fencing, regenerate.
- If a CC prompt is generated outside canvas, regenerate.
- Validation must occur before final response emission.

Implementation may occur either:
- As a deterministic formatting layer, or
- As a pre-return guard in the orchestration layer.

Propose the lowest-risk enforcement mechanism.

---

# Risk Awareness
This work is motivated by:
- T14: Telegram hallucinated save confirmations
- T35: Telegram save pipeline failure

Primary risk: modifying Telegram workflows could disturb deterministic error routing or Normalize contracts.

Mitigation: Preserve existing error envelope propagation and routing integrity.

---

# Required Response Structure

Respond in this structure:

1. Summary of Understanding
2. Minimal Change Plan (Step-by-step)
3. Identified Risks
4. Proposed Validation Mechanism
5. Explicit Confirmation Before Implementation

Do not implement changes until explicit approval is given.

