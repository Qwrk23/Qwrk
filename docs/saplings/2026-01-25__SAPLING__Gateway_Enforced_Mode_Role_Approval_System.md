# Sapling — Gateway-Enforced Mode + Role + Approval System (Owner Instance MVP)

**Date:** 2026-01-25
**Lifecycle:** sapling
**Scope:** Owner-only instance (not beta production)
**Enforcement posture:** Gateway-first (hard enforcement), chat-layer assists only

---

## Purpose

Implement explicit Mode + Role + Approval gating so governed actions cannot occur by accident. The Gateway must reject state-changing actions unless the correct mode/role/approval receipt exists.

---

## What is Locked

- Enforcement point is the Gateway boundary (not "LLM best effort").
- Mode shifts are explicit; no silent drift.
- State-changing actions require approval and receipts.
- Owner-only instance first; beta production later.

---

## Minimal Policy Registry (v1)

Define a deterministic allow-list mapping:
- gw_action → requires_mode
- gw_action → requires_role
- gw_action → requires_approval

Initial defaults:

| gw_action | requires_mode | requires_role | requires_approval |
|-----------|---------------|---------------|-------------------|
| artifact.save | Build | Builder or CEO | Yes |
| artifact.update | Build | Builder or CEO | Yes |
| artifact.promote | Build | Builder or CEO | Yes |
| artifact.query | Normal | Any | No |
| artifact.list | Normal | Any | No |

---

## Approval Receipt (v1)

Define a minimal receipt object:

| Field | Description |
|-------|-------------|
| receipt_id | Unique identifier for this approval |
| gw_request_id | Correlation to the gateway request |
| approved_by_role | CEO or Builder |
| approved_at | Timestamp |
| intended_action | gw_action + artifact_type + target artifact_id (if any) |
| status | approved / executed |

Receipts must be queryable and auditable.

---

## Gateway Enforcement Rules (v1)

Gateway must reject with stable machine codes when:

| Error Code | Condition |
|------------|-----------|
| MODE_REQUIRED | Action requires Build mode and current_mode != Build |
| ROLE_REQUIRED | Action requires Builder/CEO role and role mismatch |
| APPROVAL_REQUIRED | Action requires approval and none exists |

Rules:
- If action requires approval and none exists → reject
- If action requires Build mode and current_mode != Build → reject
- If action requires Builder/CEO role and role mismatch → reject

---

## Owner-Only Scope

This policy pack applies only to Master Joel's owner instance. Beta production will load a different policy pack later.

---

## KGB Tests (Required)

### Denial Proofs

| Test | Expected Result |
|------|-----------------|
| Attempt save/update/promote without Build mode | MODE_REQUIRED |
| Attempt save/update/promote without approval | APPROVAL_REQUIRED |
| Attempt with wrong role | ROLE_REQUIRED |

### Success Proofs

| Test | Expected Result |
|------|-----------------|
| Build mode + correct role + approval receipt | Request succeeds |

---

## Suggested Restart — Sapling → Tree

**When to resume:** After Gateway enforcement rules are implemented and KGB tests pass.

**How to resume:**
1. Verify all denial proofs work
2. Verify success proofs work
3. Document receipt storage mechanism
4. Promote to tree with governance snapshot

---

*Source: CC_Inbox/CC prompt for CEO mode.md*
