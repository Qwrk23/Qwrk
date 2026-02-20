# Surface Unification — Phase 1 Execution Authorization (Revised)

## Context
We are proceeding with Phase 1 of T38: Payload Surface Unification.

Clarification: We will NOT modify the existing NL workflow in-place.
We will:
- Reuse the existing Telegram bot token.
- Deactivate the old NL workflow (NQxb_Gateway_Telegram_v1).
- Activate the already-built JSON-only pipe (NQxb_Telegram_Gateway_Pipe_v1).

No new bot will be created.

---

# Objectives

1. Eliminate NL parsing and AI interpretation from the Telegram surface.
2. Ensure Telegram and QX both send identical canonical JSON envelopes to Gateway.
3. Preserve deterministic error routing and Normalize contract integrity.
4. Maintain instant rollback capability.

---

# Required Response Structure

Respond in this exact structure:

1. Confirmation of Architectural Approach
2. Updated Minimal Change Plan (reflecting deactivate + activate strategy)
3. Explicit Node-Level Verification Checklist
4. Rollback Confirmation Steps
5. Explicit Go/No-Go Recommendation

Do not implement changes. Joel will execute the n8n actions.

---

# Architectural Constraints (Binding)

- Do NOT modify Gateway v56.
- Do NOT modify Normalize_Request.
- Do NOT alter Save, Query, List, Update, or Promote workflows.
- Do NOT modify schema or registry.
- Only workflow activation state and credential wiring are allowed.

---

# Phase 1 Execution Plan (Revised Strategy)

## Step 1 — Credential Preparation

Confirm required credentials for NQxb_Telegram_Gateway_Pipe_v1:

- telegramApi → must reuse the existing bot credential (same token currently used by NL workflow).
- httpBasicAuth → must use the Qwrk Ingest Basic Auth credential.

Provide exact credential IDs Joel should verify before activation.

---

## Step 2 — Safe Cutover Sequence (Critical Ordering)

1. Deactivate NQxb_Gateway_Telegram_v1.
2. Confirm only one workflow is listening to the Telegram bot trigger.
3. Activate NQxb_Telegram_Gateway_Pipe_v1.
4. Confirm activation success.

Explicitly confirm there is zero scenario where both workflows could fire simultaneously.

---

## Step 3 — Validation Tests

Provide exact test payloads and expected responses for:

A) Happy Path (list)
```
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":3}}
```

B) Error Path (invalid JSON)
Send plain text: hello
Expected: structured error response with example JSON.

C) Write Path (save)
Provide a minimal safe journal save payload for testing.

---

## Step 4 — Post-Cutover Verification

Define:
- How to confirm Normalize_Request is receiving canonical JSON only.
- How to confirm no NL interpretation nodes remain active.
- How to confirm deterministic error routing remains intact.

---

## Rollback Plan (Must Be Immediate)

If any validation fails:
1. Deactivate pipe workflow.
2. Reactivate NL workflow.
3. Confirm Telegram functionality restored.

No other system changes required.

---

# Additional Tightening Requirement

Add one improvement to original plan:

Before activation, perform a visual node audit on the NL workflow to ensure:
- It is fully deactivated.
- No other workflow shares the same Telegram trigger credential.

Explicitly confirm no ghost listeners exist.

---

# Important

This is Phase 1 only.
Phase 2 (Rendering Invariants) will be drafted after Phase 1 is verified stable.

Do not implement anything. Provide plan and verification steps only.

---

# Phase 2 — Rendering Invariants Drafting (Execution-Bound Only)

We are now proceeding to Phase 2 of T38.

Scope clarification: Rendering invariants apply ONLY to execution-bound outputs (Gateway payloads and CC prompts). Discussion examples and exploratory JSON are excluded.

## Objective
Draft minimal additions to Q system instructions that introduce a binding "Execution Rendering Invariant" without bloating the instruction file.

## Requirements

Draft language that:

1. Applies ONLY when output is intended for execution (Gateway or CC).
2. Does NOT constrain discussion-mode examples.
3. Is compact and governance-grade (no narrative explanation).
4. Introduces a validation gate requirement before final emission.

---

## Invariant A — Gateway Payload Rendering

Execution-bound Gateway payloads must:
- Be emitted inside a single markdown code block
- Use language hint: json
- Contain raw JSON only
- Contain exactly one payload
- Contain no surrounding prose

---

## Invariant B — CC Prompt Rendering

Execution-bound CC prompts must:
- Be emitted in canvas only
- Contain no analysis outside the canvas
- Be execution-ready
- Follow CC_Prompt_Guidelines

---

## Invariant C — Validation Gate

Before emitting an execution-bound output:
- If Gateway payload → verify markdown fencing and isolation.
- If CC prompt → verify canvas usage and isolation.
- If invariant violated → regenerate silently before final response.

No visible correction message may be emitted.

---

## Deliverable Format

Respond with:

1. Exact instruction text to insert (ready to paste).
2. Recommended insertion location within Qwrk_SYSTEM_INSTRUCTIONS.
3. Character count impact estimate.

Do not modify files. Draft only.

