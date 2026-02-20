# RESTART — Seed Capture Discipline: Suggested Restart Required

**Date:** 2026-01-25
**Type:** Governance / Behavioral Rule
**Status:** Active
**Scope:** All seed-stage artifacts

---

## Why This Restart Exists

Seeds without forward intent decay into archaeology. When a seed is captured without a suggested restart prompt, future work requires reconstructing context, intent, and next steps from incomplete signals.

This restart canonizes a governance rule: **all seed artifacts must include a suggested restart**.

Suggested restarts encode:
- **Intent** — what the seed is meant to become
- **Resumption path** — when and how to pick it up
- **Learning trajectory** — what must be understood first

This supports Qwrk's goals of historical clarity and self-descriptiveness.

---

## Rule Declaration (Canonical)

> **All seed artifacts MUST include a `suggested_restart` section.**

A suggested restart defines:
- **When** — the trigger or readiness condition for resuming
- **Why** — the purpose of resuming this seed
- **How** — the approach or first steps for continuation

**Absence of a suggested restart indicates incomplete capture.**

---

## Scope

**Applies to:**
- All seed-stage projects (all domains)
- All artifact types that begin at seed lifecycle

**Does NOT:**
- Change snapshot semantics
- Require immediate enforcement at schema level
- Apply retroactively to existing seeds (unless intentionally updated)

---

## Non-Goals

- No Kernel changes
- No new artifact types
- No schema modifications
- No hard validation enforcement (yet)

---

## Enforcement Posture

| Phase | Enforcement Level | Mechanism |
|-------|-------------------|-----------|
| **Phase 1** | Social + Assist | CC + Qwrk reminders when creating seeds |
| **Phase 2** | Template Defaults | Seed templates include suggested_restart section |
| **Phase 3** | Optional Hard Enforcement | Gated, requires explicit approval |

---

## Relationship to Larger Vision

This rule supports:
- **Seeds as instructional objects** — self-contained enough to teach
- **Foundation for self-descriptive Qwrk** — artifacts explain themselves
- **Future auto-docs, demos, and onboarding** — suggested restarts become entry points

---

## Implementation Tree

### A. Governance Layer
| Item | Actor | Timing |
|------|-------|--------|
| Record this restart | CC | **NOW** |
| Update Behavioral Controls in Governing Constitution | Human | Later |
| Cross-reference restart artifact ID | Human | Later |

### B. Assist / Behavior Layer
| Item | Actor | Timing |
|------|-------|--------|
| Update CC prompts to require suggested_restart when creating seeds | Human + CC | Later |
| Add reminder behavior when suggested_restart is missing | CC | Later |
| Create "suggested restart" templates | CC | Later |

### C. Product / UX Layer (Future)
| Item | Actor | Timing |
|------|-------|--------|
| Seed creation UI defaults | Product | Gated |
| Visual indicators for incomplete seeds | Product | Gated |
| Restart surfacing affordances | Product | Gated |

### D. Documentation Layer
| Item | Actor | Timing |
|------|-------|--------|
| Seed rendering templates | CC | Later |
| Auto-generated feature docs inputs | CC | Later |
| Demo and onboarding hooks | Product | Gated |

### E. Enforcement Evolution (Explicitly Deferred)
| Item | Actor | Timing |
|------|-------|--------|
| Soft warnings | System | Gated |
| Hard blocks | System | Gated (requires explicit approval) |

---

## Suggested Restart (Meta)

**When to resume:** When updating CC system prompts or seed creation flows.

**How to resume:** Reference this restart and implement Phase 1 enforcement (social + assist reminders).

---

*Source: CC_Inbox/Run this first.txt*
