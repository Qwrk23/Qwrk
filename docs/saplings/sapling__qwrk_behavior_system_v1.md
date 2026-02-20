# Sapling — Qwrk Behavior System (Shortcuts, Tone, Modes)

**Type:** Sapling (future work)
**Created:** 2026-01-11
**Status:** Captured, not active
**Purpose:** Preserve intent for user-configurable behavior layer

---

## Problem Statement

After Gateway and frontend stability is achieved, users will need ways to:
- Teach Qwrk their personal language and shorthand
- Control how Qwrk communicates (tone, style)
- Configure behavior based on context (modes, time, workspace)
- Override behavior temporarily without permanent changes

The problem: Qwrk currently has no mechanism for personalization, mode-awareness, or user-defined behavior policies. This sapling captures the direction for solving that problem when the time is right.

---

## Core Concepts (High-Level Only)

### User-Configurable Behavior
Allow users to define and persist preferences that shape how Qwrk interprets requests and generates responses, without breaking contracts or compromising security.

### Shortcuts (Macros)
User-defined language mappings that expand before reasoning.
- Example: `WSY` → "what say you?"
- Case-insensitive, punctuation-tolerant
- Standalone token matching only (no partial matches)
- Single expansion (no recursion)
- Deterministic conflict resolution

### Tone Policies
Scheduled style preferences that control how Qwrk communicates.
- Scheduled (e.g., specific days/times)
- Scoped (global, workspace, mode)
- Suppressed for high-stakes contexts (warnings, errors, medical/legal/financial topics)
- Style only - never affects facts, contracts, or enforcement

### Modes
Real state that determines default behavior packs.
- Examples: Normal, Journal, Build
- Affects response pacing, tone exclusions, UI presentation
- Not just "vibes" - actual tracked state

### Session Overrides
Temporary, higher-priority behavior changes.
- Example: "For today, keep answers short"
- Expires at session end unless persisted
- Cannot override hard rails

### Minimal Hard Rails
Only three non-configurable constraints:
1. Contract integrity (no breaking Gateway/system contracts)
2. Security & privacy baseline (no auto-execution, secret leakage, unsafe actions)
3. Truthfulness (never claim persistence without actual persistence)

Everything else is configurable.

### Risk-Aware Tone Suppression
Tone automatically suppressed when:
- Response is a warning, apology, or error
- Topic is high-stakes (medical, legal, financial, safety)
- UI or classifier flags high risk

Risk determined by both UI tags and content-based classification.

---

## Precedence Layers

Behavior resolved in layers (highest wins):
- **L0** Hard rails (non-negotiable)
- **L3** Session overrides (temporary, highest priority)
- **L1** Mode defaults
- **L2** Persistent user policies (shortcuts, tone)

---

## Non-Goals

This sapling does **not**:
- Commit to any specific implementation approach
- Define schemas, tables, or artifact structures
- Specify Gateway changes or new actions
- Require UI changes or new frontend surfaces
- Provide a timeline or roadmap
- Answer "how" - only captures "what" and "why"

---

## Future Entry Conditions

This sapling should only be activated when:
- Frontend is stable with save/query/list/update/promote at high reliability
- Error tracking and telemetry are in place
- Gateway contracts are locked and trusted
- Clear user need for personalization has been validated
- Team capacity exists for non-critical enhancement work

---

## Open Questions (Intentionally Unanswered)

1. **Persistence strategy**: Tables vs artifacts vs configuration files vs external service?
2. **Mode taxonomy**: What modes exist? Who defines them? Are they extensible?
3. **Scope hierarchy**: How are global/workspace/mode scopes represented structurally?
4. **Session definition**: What constitutes a "session" for override expiration?
5. **Risk classifier**: Build new vs integrate existing vs LLM-based vs pattern matching?
6. **Telemetry sink**: Where do behavior traces go?
7. **User timezone**: Where is it stored and sourced?
8. **Command surface**: CLI vs UI vs conversational vs API?
9. **Long-term governance**: How much user-defined behavior is safe? What limits?
10. **Integration point**: Gateway middleware vs standalone service vs client-side?

These questions remain open until activation.

---

## Acceptance Criteria (When Activated)

When this sapling becomes active work, it must demonstrate:
- Shortcuts expand deterministically with correct conflict resolution
- Tone policies apply correctly with proper suppression
- Session overrides work without breaking hard rails
- Risk classification prevents inappropriate tone
- Telemetry captures applied behavior for debugging
- All behavior is testable and deterministic

---

**This sapling is complete. No further work until explicitly activated.**
