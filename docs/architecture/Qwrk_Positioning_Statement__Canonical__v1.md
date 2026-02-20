# Qwrk Positioning Statement — Canonical v1

**Type:** Canonical Technical Documentation (Authoritative)
**Status:** LOCKED
**Date:** 2026-01-05
**Owner:** Master Joel
**Derivation:** This document is the single source of truth for all Qwrk positioning, messaging, and marketing materials.

---

## Core Positioning Statement

**Qwrk is:**

> **A conversationally driven, lifecycle-aware, agent-capable operating environment for human intent.**

---

## Metadata for Derivation

### Feature Name
**Qwrk V2 Operating Environment**

### Stage
**Crawl** (Kernel v1 is foundational infrastructure; user-facing features are nascent)

### Capabilities (What Qwrk IS)

**Conversationally Driven:**
- Natural language is the primary interface for all interactions
- Users express intent through conversation, not commands or forms
- System interprets, clarifies, and executes based on conversational input
- Dialogue is bidirectional: Qwrk asks questions, confirms, and explains

**Lifecycle-Aware:**
- Artifacts have lifecycle stages (seed → sapling → tree → retired for projects)
- System tracks state transitions and operational status
- Context persists across sessions via snapshots, restarts, and journals
- System "remembers" where work stands and can resume intelligently

**Agent-Capable:**
- Supports autonomous execution within governed rails (Qwrkflows/QFs)
- Agents operate with explicit approval gates for state-changing actions
- Explainability is mandatory: agents can explain what they did and why
- Designed for human-agent collaboration, not replacement

**Operating Environment for Human Intent:**
- Qwrk is infrastructure, not an app
- Users work *within* Qwrk; Qwrk adapts to their workflow
- Intent is captured, refined, executed, and logged
- System is workspace-first: all work scoped to user's operational context

---

### Non-Capabilities (What Qwrk is NOT)

**NOT a chatbot:**
- Qwrk is not a simple Q&A interface
- It is a stateful, workspace-aware operating environment

**NOT a task manager:**
- While Qwrk tracks lifecycle, it is not a simple to-do list
- It is an environment for *executing* intent, not just tracking it

**NOT a code editor:**
- Qwrk can manage code artifacts, but is not IDE-replacement
- Focus is on intent → execution, not syntax editing

**NOT fully autonomous:**
- Agents require approval for state changes
- Human oversight is built-in, not optional

**NOT production-ready (Kernel v1):**
- Crawl stage: foundational infrastructure
- User-facing features are MVP-level
- Not marketed as "complete" product

---

## User-Facing Summary (Plain Language)

Qwrk is a new kind of operating environment designed for working with AI agents.

Instead of clicking through apps or filling out forms, you talk to Qwrk in natural language. You describe what you want to accomplish, and Qwrk helps you refine, plan, and execute that intent.

Qwrk remembers where you left off. It tracks your projects, decisions, and work context across sessions. When you return, it knows what you were doing and can pick up right where you stopped.

Qwrk can run agents — autonomous workflows that execute tasks on your behalf. But agents don't operate in the dark: they ask for approval before making changes, and they can always explain what they did and why.

Think of Qwrk as an operating system for human intent: a workspace where you and AI agents collaborate to get things done, with full transparency and control.

---

## Demo Safety Classification

**Demo Status:** Demo-partial (with notes)

**Demo-Safe Elements:**
- Conversational interface (can show natural language interaction)
- Artifact lifecycle concepts (seed → sapling → tree)
- Workspace-scoped data (show user-specific context)
- Approval gates (demonstrate agent pausing for confirmation)

**Demo-Unsafe Elements:**
- n8n workflow internals (too technical, not user-facing)
- Database schema details (backend complexity, confusing)
- RLS policy mechanics (technical implementation detail)
- Gateway contract raw JSON (not user-friendly)

**Recommended Demo Flow:**
1. Show conversational interaction (user expresses intent)
2. Demonstrate lifecycle awareness (Qwrk remembers context)
3. Show agent execution with approval gate (agent pauses, asks permission)
4. Demonstrate explainability (agent explains what it did)

**Demo Script Note:**
Focus on *outcomes* (what the user accomplishes), not *mechanics* (how Qwrk does it internally).

---

## Derivation Rules

### For Marketing Materials:
- Use the core positioning statement verbatim or adapt using the user-facing summary
- Emphasize conversational, lifecycle-aware, agent-capable, operating environment
- Avoid technical jargon (don't mention Supabase, n8n, RLS, Gateway)
- Lead with user benefit, not technical architecture

### For User Guides:
- Explain conversational interface first (how to express intent)
- Introduce lifecycle concepts gradually (seed/sapling/tree as users encounter them)
- Clarify agent approval gates upfront (users need to know agents will ask permission)
- Provide explainability examples (show users how to ask "why did you do that?")

### For Sales / Positioning Copy:
- "Operating environment for human intent" is the hook
- Contrast with task managers, chatbots, and traditional apps
- Highlight transparency + control (agents ask permission, always explainable)
- Position as "future of human-AI collaboration"

### For Demo Scripts:
- Use demo-safe elements only (see above)
- Show, don't tell: demonstrate conversation → approval → execution flow
- Avoid showing backend complexity unless audience is technical
- End with "and Qwrk remembered all of this for next time" (lifecycle awareness)

---

## Conflict Resolution

If any marketing material, user guide, demo script, or positioning copy **contradicts** this canonical statement:

1. **Canonical documentation wins**
2. Derived material must be corrected or regenerated
3. Do NOT blend or "average" messaging

This document is authoritative. All downstream messaging derives from here.

---

## Version History

### v1 - 2026-01-05
- Initial canonical positioning statement locked
- Core statement: "A conversationally driven, lifecycle-aware, agent-capable operating environment for human intent."
- Metadata for derivation added (stage, capabilities, non-capabilities, demo safety)
- Derivation rules for marketing, user guides, sales, demos documented

---

**Status:** LOCKED
**Canonical Source:** This file
**Derived From:** Master Joel's foundational positioning statement (2026-01-05)

---
