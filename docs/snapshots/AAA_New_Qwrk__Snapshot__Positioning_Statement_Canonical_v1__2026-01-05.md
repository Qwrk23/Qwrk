# AAA_New_Qwrk__Snapshot__Positioning_Statement_Canonical_v1__2026-01-05

**Date:** 2026-01-05
**Owner:** Master Joel
**Status:** LOCKED
**Type:** Canonical Positioning
**Artifact Type:** snapshot

---

## Core Positioning Statement

**Qwrk is:**

> **A conversationally driven, lifecycle-aware, agent-capable operating environment for human intent.**

---

## Purpose

This snapshot captures the canonical positioning statement for Qwrk V2 as the single source of truth for all messaging, marketing, user guides, sales materials, and demo scripts.

**Derivation Contract:**
All downstream materials (marketing, user guides, demos) derive from this canonical statement per Rule 7.5: Documentation & Derivation Contract.

---

## Metadata

**Version:** v1
**Stage:** Crawl (Kernel v1 foundational infrastructure)
**Demo Safety:** Demo-partial (conversational interface, lifecycle, approval gates are demo-safe; backend internals are not)

---

## Capabilities Breakdown

### Conversationally Driven
Natural language is the primary interface for all interactions. Users express intent through conversation, not commands or forms. System interprets, clarifies, and executes based on conversational input.

### Lifecycle-Aware
Artifacts have lifecycle stages (seed → sapling → tree → retired). System tracks state transitions and operational status. Context persists across sessions via snapshots, restarts, and journals.

### Agent-Capable
Supports autonomous execution within governed rails (Qwrkflows/QFs). Agents operate with explicit approval gates for state-changing actions. Explainability is mandatory: agents can explain what they did and why.

### Operating Environment for Human Intent
Qwrk is infrastructure, not an app. Users work *within* Qwrk; Qwrk adapts to their workflow. Intent is captured, refined, executed, and logged. System is workspace-first: all work scoped to user's operational context.

---

## Non-Capabilities

**NOT a chatbot** - Qwrk is a stateful, workspace-aware operating environment, not a simple Q&A interface.

**NOT a task manager** - While Qwrk tracks lifecycle, it is an environment for *executing* intent, not just tracking it.

**NOT a code editor** - Qwrk can manage code artifacts, but is not IDE-replacement.

**NOT fully autonomous** - Agents require approval for state changes. Human oversight is built-in, not optional.

**NOT production-ready (Kernel v1)** - Crawl stage: foundational infrastructure. User-facing features are MVP-level.

---

## User-Facing Summary

Qwrk is a new kind of operating environment designed for working with AI agents.

Instead of clicking through apps or filling out forms, you talk to Qwrk in natural language. You describe what you want to accomplish, and Qwrk helps you refine, plan, and execute that intent.

Qwrk remembers where you left off. It tracks your projects, decisions, and work context across sessions. When you return, it knows what you were doing and can pick up right where you stopped.

Qwrk can run agents — autonomous workflows that execute tasks on your behalf. But agents don't operate in the dark: they ask for approval before making changes, and they can always explain what they did and why.

Think of Qwrk as an operating system for human intent: a workspace where you and AI agents collaborate to get things done, with full transparency and control.

---

## Derivation Rules

### For Marketing Materials
- Use core positioning statement verbatim or adapt using user-facing summary
- Emphasize: conversational, lifecycle-aware, agent-capable, operating environment
- Avoid technical jargon (no Supabase, n8n, RLS, Gateway mentions)
- Lead with user benefit, not technical architecture

### For User Guides
- Explain conversational interface first (how to express intent)
- Introduce lifecycle concepts gradually (seed/sapling/tree as users encounter them)
- Clarify agent approval gates upfront (users need to know agents will ask permission)
- Provide explainability examples (show users how to ask "why did you do that?")

### For Sales / Positioning Copy
- "Operating environment for human intent" is the hook
- Contrast with task managers, chatbots, and traditional apps
- Highlight transparency + control (agents ask permission, always explainable)
- Position as "future of human-AI collaboration"

### For Demo Scripts
- Use demo-safe elements only: conversational interface, lifecycle awareness, approval gates, explainability
- Show, don't tell: demonstrate conversation → approval → execution flow
- Avoid backend complexity unless audience is technical
- End with "and Qwrk remembered all of this for next time" (lifecycle awareness)

---

## Demo Safety Classification

**Demo-Safe Elements:**
- Conversational interface (show natural language interaction)
- Artifact lifecycle concepts (seed → sapling → tree)
- Workspace-scoped data (show user-specific context)
- Approval gates (demonstrate agent pausing for confirmation)

**Demo-Unsafe Elements:**
- n8n workflow internals (too technical, not user-facing)
- Database schema details (backend complexity, confusing)
- RLS policy mechanics (technical implementation detail)
- Gateway contract raw JSON (not user-friendly)

---

## Conflict Resolution

If any marketing material, user guide, demo script, or positioning copy **contradicts** this canonical statement:

1. Canonical documentation wins
2. Derived material must be regenerated
3. Do NOT blend or "average" messaging

---

## References

**Canonical Document:** `docs/architecture/Qwrk_Positioning_Statement__Canonical__v1.md`
**Governance:** Rule 7.5 - Documentation & Derivation Contract (GLOBAL)

---

**Status:** LOCKED
**Derived From:** Master Joel's foundational positioning statement (2026-01-05)

---
