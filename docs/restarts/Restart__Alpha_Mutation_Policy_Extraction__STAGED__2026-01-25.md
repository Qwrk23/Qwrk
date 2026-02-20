# RESTART — Alpha Mutation Policy (Post-Activation Capture)

**Date:** 2026-01-25
**System:** Qwrk Alpha (Gateway v1 — Full Access ENABLED)
**Trigger:** Observed live Alpha behavior with mutation enabled
**Mode / Governance:** AAA_New_Qwrk under Qwrk V2 Constitution
**Status:** STAGED — DO NOT EXECUTE UNTIL AFTER LIVE VALIDATION

---

## Authoritative Context (LOCKED)

- Qwrk Alpha Full Access has been successfully enabled
- Gateway v1 supports:
  - artifact.query
  - artifact.list
  - artifact.save
  - artifact.update
  - artifact.promote
- ChatGPT is now a live mutation actor, not read-only
- v2 system instructions are active and governing behavior
- No standalone Alpha mutation policy document exists yet

---

## Purpose of This Restart

Capture the actual, observed mutation rules that Qwrk followed in Alpha into a standalone governance artifact **without changing behavior**.

This is a documentation and authority extraction step, not a redesign.

---

## Inputs Required on Resume

On restart, the user will provide:

1. **Observed behaviors**, including:
   - When ChatGPT asked for confirmation
   - When it refused or paused
   - Any surprising or ambiguous mutation behavior

2. **Examples** (verbatim prompts + outcomes), if available

3. **Confirmation** of whether any behavior felt:
   - Unsafe
   - Too permissive
   - Too restrictive
   - Confusing to a human

---

## Required Actions on Resume

1. **Extract** (not invent) mutation rules from:
   - v2 system instructions
   - Observed Alpha behavior

2. **Create** a standalone document:
   - `docs/governance/Alpha_Mutation_Policy_v0.1.md`

3. **Ensure** the document:
   - Matches existing behavior exactly
   - Introduces no new constraints
   - Clearly distinguishes:
     - Query vs mutation
     - Safe vs gated actions
     - Confirmation requirements

4. **Explicitly note** any:
   - Ambiguities
   - Known limitations
   - Intentional gray areas

---

## Explicit Non-Goals

- Do NOT modify Gateway workflows
- Do NOT change system instructions
- Do NOT "improve" behavior
- Do NOT add new rules
- Do NOT re-litigate prior decisions

**This is a truth capture, not a policy debate.**

---

## Output Artifacts

- One Markdown file: `Alpha_Mutation_Policy_v0.1.md`
- Optional appendix: "Observed Alpha Behaviors (Examples)"
- No code changes
- No schema changes
- No redeploy required

---

## Success Criteria

This restart is complete when:

1. A human can read the policy and say:
   > "Yes — that's exactly how Qwrk behaved."

2. Future builders can understand:
   - What ChatGPT is allowed to do
   - When it must ask
   - When it must refuse

3. No behavior changes occurred as part of this work

---

## Suggested Follow-On (Not Part of This Restart)

Decide whether to:
- Keep policy as documentation only, or
- Later re-embed it into instruction packs or registries

That decision is out of scope for this restart.

---

*Staged by ANQ — 2026-01-25*
*Execute after live Alpha validation is complete*
