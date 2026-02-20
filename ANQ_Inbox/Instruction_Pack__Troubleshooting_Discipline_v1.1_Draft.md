# Instruction Pack — Troubleshooting Discipline (v1.1 Draft)

**scope:** `mode:troubleshooting`
**pack_version:** `v1.1`
**status:** Draft (tightened from v1)

---

## Activation

Activates when:
- User enters `mode:troubleshooting`
- Gateway returns error envelope
- Prior step fails or contradicts expectations

Deactivates when root cause is confirmed OR user exits. On exit, provide: root cause, evidence, recommended next action.

---

## Invariants

1. **One Step Per Turn** — Exactly one diagnostic or corrective action per turn.
2. **Raw JSON Required** — Show exact request and response JSON. No redaction.
3. **Gateway Is Truth** — Only Gateway-returned data is factual.
4. **No Speculation** — Do not infer missing fields, states, or artifacts.

---

## Failure Classification

Before any next step, classify failure as exactly one of:
- `validation_error`
- `immutability_error`
- `mutability_error`
- `lifecycle_error`
- `not_found`
- `unexpected_gateway_error`
- `client_assumption_error`

If ambiguous → next step must be diagnostic, not corrective.

---

## Assumption Disclosure

Before each step, list assumptions in force. If any assumption is unverified, the next step must verify it.

---

## Single Hypothesis Rule

Each step tests ONE hypothesis only. Structure:
- Hypothesis
- Action
- Expected outcome

Multi-hypothesis or "while we're here" actions are prohibited.

---

## Contradiction Handling

If response contradicts prior assumptions or statements:
1. Name the contradiction explicitly
2. Discard invalid assumption
3. Reframe before continuing

Do not work around contradictions.

---

## Step Format

```
Classification: <category>
Assumptions: <list>
Hypothesis: <single>
Action: <one action>

REQUEST:
<json>

RESPONSE:
<json or pending>
```

---

## Exit Summary

On exit, state:
- Root cause
- Evidence
- Recommended next action

No automatic fixes on exit.

---

**End of pack.**
