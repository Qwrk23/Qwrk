# Manus Reference — Governance Summary

**Purpose:** Distilled governance rules relevant to plan review. Not a canonical governance source.
**Date:** 2026-03-22
**Canonical sources:** `CLAUDE.md`, `docs/architecture/Behavioral_Controls_Governing_Constitution.md`, `docs/architecture/North_Star_v0.4.md`

---

## Truth Hierarchy

When conflicts arise in Qwrk, resolution follows this order (highest authority first):

1. **Behavioral Controls — Governing Constitution**
2. **North Star** (v1.0 / v0.4 locked for current phase)
3. **Kernel v1 Snapshots** (Pre/Post KGB)
4. **Phase 1–3 Locks** (Kernel semantics, type schemas, Gateway contract)
5. **Known-Good n8n Workflow Snapshots / KGB results**

**No lower layer may override a higher layer.**

Plans that conflict with a higher-authority document must either:
- Propose a versioned update to that document (explicit, approved), or
- Correct the implementation to match the higher truth

Silent blending or ignoring conflicts is forbidden.

---

## DDL-as-Truth

The Live DDL file is the **only** authoritative schema reference.

- Plans referencing schema must align with `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`
- Do not rely on memory, older docs, or information_schema exports
- If a plan references a column, table, or constraint: it must exist in the Live DDL

---

## No-Guessing Rule

Qwrk does not invent schemas, enums, tables, endpoints, Gateway actions, lifecycle rules, or payload shapes. If truth is missing, the correct action is to stop and ask for the authoritative source.

**Review implication:** If a plan introduces a new enum value, table, or Gateway action that does not exist in canonical docs, flag it. It may be intentional (the plan is proposing it) or accidental (the plan assumed it exists).

---

## No-Overwrite / Immutability

### File Versioning
Existing files are never overwritten in place. All changes use one of three patterns:
- **Pattern C (preferred):** Archive current file to `Archive/` subfolder, write new file with original canonical name
- **Pattern A:** Versioned clone (side-by-side)
- **Pattern B:** Rename old file with version suffix, write new with canonical name

### Data Immutability
- **Snapshot** and **Restart** artifacts are immutable (no update or delete)
- **Event log** (`qxb_artifact_event`) is append-only (triggers block UPDATE/DELETE)
- **Soft delete only** — `deleted_at` timestamp, never hard delete

**Review implication:** Plans that propose updating snapshot or restart data, or hard-deleting records, violate immutability rules.

---

## Phase Boundaries

Qwrk uses phased development. Not all types and features are active in every phase.

- **Kernel v1 core types:** project, journal, snapshot, restart, instruction_pack
- **Walk types (active):** grass, thorn, branch, leaf, limb, person, twig
- **Reserved types (CHECK constraint only):** forest, thicket, flower

**Review implication:** Plans that assume reserved types have extension tables or Gateway support are incorrect unless the plan is explicitly proposing to activate them.

---

## Planning Before Execution

Complex work (3+ files, 2+ structural surfaces) requires a formal planning gate:

1. **Gather** — read files, query state, identify surfaces and dependencies (no mutations)
2. **Propose plan** — present scope, surfaces, files, dependencies, risk, steps
3. **Wait for approval** — do not execute without explicit human approval

**Review implication:** Plans should show evidence of gathering current state before proposing changes. Plans that skip gathering and assume stale information are risky.

---

## Parallel Build Safety

When adding functionality to a system component already in active use:

- Default to a **parallel, isolated build** rather than modifying the live implementation
- Validate new functionality in the parallel version first
- Merge back only after validation succeeds, with explicit approval
- Existing functionality must remain operational throughout

**Review implication:** Plans that propose direct modification of live workflows or production paths should justify why parallel build is not appropriate.

---

## Governance-First Merge Order

When multiple workstreams converge:

1. Governance documentation merges first
2. Workflow/code changes merge second
3. Deployment or activation occurs last

This order must not be reversed.

---

## Pre-Write Confirmation

Before writing or renaming any file, the exact list of files to touch must be declared and approved. This applies to plan execution, not to plan review.

**Review implication:** Plans should include a clear file manifest. Plans that vaguely say "update relevant files" without listing them are incomplete.

---

## CHANGELOG

### v1 — 2026-03-22
Initial creation for Manus plan reviewer role.
