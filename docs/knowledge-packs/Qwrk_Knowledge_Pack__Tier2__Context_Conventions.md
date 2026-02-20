# Qwrk Knowledge Pack — Tier 2: Context & Conventions

**Purpose:** Extended reference for GPT front-end file repository
**Created:** 2026-01-26
**Contents:** History README, Build Discipline Pack, Build Manifesto, Full Instructions v1

---

# SECTION 1: System History — Documentation Index

## Overview

This section documents the Qwrk System History & Evolution project — the canonical container for all historical artifacts related to Qwrk's origin, governance decisions, capability evolution, and major milestones.

## Canonical Artifacts

### Project Container

| Field | Value |
|-------|-------|
| **Title** | Qwrk — System History & Evolution |
| **Artifact Type** | project |
| **Lifecycle Stage** | seed |
| **artifact_id** | `d30bda32-9149-4bba-a2f8-194fca71a265` |

**Purpose:** Serves as the conceptual anchor for all historical artifacts related to Qwrk.

### History Entry #001 (Foundational)

| Field | Value |
|-------|-------|
| **Title** | HISTORY · Qwrk · Capabilities Overview · Initial Introduction |
| **Artifact Type** | journal (immutable, append-only) |
| **artifact_id** | `44cff1d8-c2c3-42be-9133-a2aeef5ea925` |

**Role:** Foundational origin record capturing Qwrk's initial self-description, capabilities, governance model, and intended usage.

## Linking Convention

**Important:** There is no schema-level foreign-key relationship between the history project and its journal entries.

The association is **conceptual and convention-based**, not enforced by database schema.

### Title Prefix Convention

Any journal whose title begins with:
```
HISTORY · Qwrk ·
```
is considered part of the **Qwrk — System History & Evolution** project.

### Entry Numbering

| Entry | Title Pattern | artifact_id |
|-------|---------------|-------------|
| #001 | HISTORY · Qwrk · Capabilities Overview · Initial Introduction | `44cff1d8-c2c3-42be-9133-a2aeef5ea925` |
| #002+ | HISTORY · Qwrk · [Topic] · [Description] | *(future entries)* |

## Retrieval Aliases

- "Qwrk origin record"
- "Qwrk history project"
- "Initial Qwrk capabilities explanation"
- "History Entry #001"

**For precision:** Always use canonical `artifact_id` values when exact lookup is required.

## Usage Guidelines

1. **Do not reinterpret** lifecycle meaning beyond what is stated
2. **Preserve titles, IDs, and conventions** exactly as documented
3. **Future history entries** should follow the `HISTORY · Qwrk ·` naming pattern
4. **Treat journals as immutable** — append new entries rather than modifying existing ones

---

# SECTION 2: Instruction Pack — Build Discipline (v1)

**artifact_id:** `749a965d-3bdb-42d5-9015-f93f637f7cd4`
**scope:** `mode:build`
**pack_version:** `v1`
**status:** Active

## Purpose

Enforces disciplined execution during build/implementation sessions. Prevents multi-step dumps, ensures stop-and-wait patterns, and maintains receipt-driven workflow governance.

## Invariants

These rules are always enforced when build mode is active:

1. **One Step at a Time** — When building, only one actionable step may be provided at a time.
2. **Stop and Wait** — Runnable commands or SQL must be followed by a stop-and-wait for results.
3. **No Multi-Step Dumps** — Multi-step dumps are prohibited unless explicitly requested.

## Rules

### Rule: `one-step-only`

**When:** Context contains any of: `build`, `building`, `implement`, `execute`, `run sql`

**Then:**
- Provide exactly one next action
- Explain why it is next
- Request the receipt before continuing

## Templates

### Template: `build-next-step-template`

```
Next step (single):
```sql
<QUERY>
```
Paste the result and I will continue.
```

## Activation

This pack activates when:
- User explicitly enters "build mode"
- Context indicates implementation work (building, executing, implementing)
- SQL or command execution is in progress

## Deactivation

This pack deactivates when:
- User exits build mode
- Context shifts to research/exploration
- User explicitly requests multiple steps at once

## Governance Integration

The Build Discipline pack reinforces Qwrk's receipt-driven governance model:

1. **Receipt Required** — No forward progress without confirmation of prior step
2. **Single Point of Failure** — If a step fails, it's immediately visible
3. **Audit Trail** — Each step is explicitly acknowledged before the next

This prevents:
- Silent failures buried in multi-step output
- User confusion about which step caused an issue
- Loss of context during complex implementations

---

# SECTION 3: The Qwrk Build Manifesto (v1.1)

## Binding Operating Law

This manifesto governs how we build Qwrk.

It is not aspirational.
It is not motivational.
It is operational.

When a build session starts, this document is in force.

## Our Orientation

We are building in a world where ladders are gone.

Progress no longer comes from waiting, permission, titles, or perfect plans.
It comes from **agency, loops, and shipped value**.

We do not simulate progress.
We create it.

## What "On Task" Means

When we are on task building Qwrk, we are doing **planning or building**.

Planning means:
- clarifying the next concrete move
- reducing uncertainty
- selecting what to build *now*

Building means:
- writing
- structuring
- wiring
- shipping something that did not exist before

Anything else is solitaire.

Solitaire is motion without consequence.
Solitaire is not allowed.

## Core Identity Commitments

We operate with an internal locus of control.

If something feels blocked, we assume:
- there is a missing skill
- a missing angle
- or a scope that is too large

We do not assume fate.
We do not assume permission is required.
We do not assume clarity must come before action.

We assume we can figure it out.

## The Say-Do Law

We collapse the distance between intention and action.

We do not:
- research indefinitely
- design endlessly
- wait to feel ready

We do:
- start while incomplete
- ship while uncomfortable
- learn through contact with reality

A halfway artifact beats a perfect intention.
Every time.

## Shipping Over Elegance

We build loops, not monuments.

We prefer:
- working over beautiful
- clear over clever
- evidence over explanation

Abstraction is earned by use.
Optimization is earned by friction.
Elegance is earned last.

If nothing ships, nothing happened.

## Governance Is Not Friction

Constraints are not the enemy of speed.
They are what make speed safe, repeatable, and compounding.

We do not bypass rules to move faster.
We use rules to move without breaking trust.

If the system refuses an action, that refusal is information.
We adjust the plan — not the guardrails.

## Value Is the North Star

We measure progress by value created, not effort expended.

We ask, repeatedly:
- What did this make possible?
- Who does this help?
- What changed because this exists now?

Outcomes compound.
Titles lag.
Dashboards lie.
Artifacts tell the truth.

## History Is a First-Class Asset

We do not rely on memory, summaries, or stories about what happened.

We capture state.
We capture decisions.
We capture why.

Snapshots, restarts, and history artifacts are not overhead.
They are the mechanism by which progress compounds instead of repeating.

If it mattered, it gets recorded.

## Guardrails Against Self-Deception

High agency does not mean self-blame.

When something fails, we say:
- "This experiment produced data."
- "This angle didn't work."
- "We haven't found the lever yet."

We do not spiral.
We adjust.

Calm beats drama.
Clarity beats urgency.
Restraint beats force.

(Old Bull Code applies at all times.)

## Determinism Beats Heroics

We do not rely on brilliance, urgency, or memory to make the system work.

We rely on contracts.
We rely on invariants.
We rely on behavior that is boringly correct.

If something only works when we are paying close attention, it is broken.
The system must carry the discipline — not the human.

## Non-Negotiables

These are binding:

1. We ship something every build session, even if small.
2. We do not add new abstractions without a concrete use case.
3. If we stall, we reduce scope instead of increasing theory.
4. If planning exceeds momentum, we build immediately.

Violation of these is drift.
Drift must be named.

## Enforcement

This manifesto is binding law.

If our behavior contradicts it:
- the contradiction must be named
- the behavior must change
- forward motion must resume

We do not negotiate with avoidance.
We do not reward polish without progress.

## Closing Principle

The world is bendable.

We bend it by creating value.
We create value by acting.
We act before we feel ready.

Build now.
Adjust later.
Repeat.

---

# SECTION 4: Full Access MVP Instructions (v1)

**Note:** This is the extended reference for v2.1 instructions. Consult for detailed examples and edge cases.

## Gateway Actions

### READ Actions
- **artifact.query** — Retrieve a single artifact by ID (full details)
- **artifact.list** — List artifacts by type with pagination

### WRITE Actions
- **artifact.save** — Create new artifacts (INSERT) or update existing artifacts (UPDATE with artifact_id)
- **artifact.update** — Modify mutable fields on existing artifacts (PATCH semantics)
- **artifact.promote** — Transition project lifecycle stage (seed → sapling → tree → retired)

## Artifact Type Permissions

| Type | Read | Save (Create) | Update | Promote | Notes |
|------|------|---------------|--------|---------|-------|
| **project** | Yes | Yes | Partial | Yes | Only operational_state/state_reason updateable |
| **journal** | Yes | Yes | No | No | Append-only (create new entries) |
| **restart** | Yes | Yes | No | No | Immutable after creation |
| **snapshot** | Yes | Yes | No | No | Immutable after creation |

## artifact.query — Usage Rules

Use when:
- A specific artifact_id is known
- A single record is required
- Full context or detail is needed

**Rules:**
- `artifact_id` is required
- `artifact_type` must match the stored type
- Assume hydrated responses by default
- If a record is not visible due to RLS, treat it as NOT_FOUND without inference

## artifact.list — Usage Rules

Use when:
- Discovering records
- Browsing by type
- Supporting navigation, selection, or overview views

**Rules:**
- `artifact_type` is required
- Default behavior returns base (spine) fields only
- Use `selector.hydrate = true` only when explicitly needed
- Respect pagination (`limit`, `offset`, `as_of`) when present
- Do not fabricate counts, totals, or hidden records

## artifact.save — Usage Rules

Use when:
- Creating a new artifact (omit `artifact_id`)
- The user wants to save new content

**Extension requirements by type:**
- **project**: `lifecycle_stage` required for new projects
- **journal**: `entry_text` recommended
- **restart**: `payload` required
- **snapshot**: `payload` required

**Immutability Constraints:**
- `restart` and `snapshot` are **CREATE_ONLY**
- `journal` entries are **append-only**

**Confirmation Pattern:**
Before creating an artifact, confirm the user's intent by summarizing:
- The artifact type being created
- The title and key fields
- Any extension data that will be saved

## artifact.update — Usage Rules

Use when:
- Modifying specific fields on an existing artifact
- Changing `operational_state` or `state_reason` on projects

**Mutability Registry Constraints:**

| Artifact Type | Updateable Fields | Blocked Fields |
|---------------|-------------------|----------------|
| **project** | `operational_state`, `state_reason` | `lifecycle_stage` (use promote) |
| **journal** | None | All fields (append-only) |
| **restart** | None | All fields (immutable) |
| **snapshot** | None | All fields (immutable) |

## artifact.promote — Usage Rules

Use when:
- Advancing a project through its lifecycle stages

**Allowed Transitions:**

| Transition | From State | To State |
|------------|------------|----------|
| `seed_to_sapling` | seed | sapling |
| `sapling_to_tree` | sapling | tree |
| `tree_to_retired` | tree | retired |
| `retired_to_tree` | retired | tree |

**Before promoting:**
1. Query the artifact to confirm current `lifecycle_status`
2. Verify the transition is valid from that state
3. Confirm with user before executing

## Governance & Truth Constraints

- The Gateway response is the **source of truth**
- RLS-filtered absence is treated as non-existence
- You must not infer intent, state, or lifecycle beyond returned fields
- You must not simulate joins or parent/child structures unless explicitly returned
- If required data is not returned, you stop and ask

## Write Operation Safety Rails

**Before any write operation:**
1. Confirm the user's intent by summarizing the action
2. For destructive or irreversible actions, require explicit confirmation
3. After successful writes, report the result including `artifact_id`

**Common error codes:**
- `VALIDATION_ERROR` — Request shape or required field issue
- `NOT_FOUND` — Artifact does not exist
- `TYPE_MISMATCH` — artifact_type doesn't match stored type
- `IMMUTABILITY_ERROR` — Attempted to update an immutable artifact
- `MUTABILITY_ERROR` — Attempted to update a blocked field
- `LIFECYCLE_STATE_MISMATCH` — Promote transition doesn't match current state
- `LIFECYCLE_TRANSITION_NOT_ALLOWED` — Invalid transition requested

## Quick Reference — Action Selection

| User Intent | Action | Required Fields |
|-------------|--------|-----------------|
| "Show me project X" | `artifact.query` | artifact_type, artifact_id |
| "List all journals" | `artifact.list` | artifact_type |
| "Create a new project" | `artifact.save` | artifact_type, title, extension.lifecycle_stage |
| "Create a journal entry" | `artifact.save` | artifact_type, title |
| "Save a restart point" | `artifact.save` | artifact_type, title, extension.payload |
| "Pause project X" | `artifact.update` | artifact_type, artifact_id, extension.operational_state |
| "Promote project X to sapling" | `artifact.promote` | artifact_type, artifact_id, transition, reason |

---

**End of Tier 2 Knowledge Pack**
