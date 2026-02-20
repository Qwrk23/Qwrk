# RESTART — Gateway v1 `artifact.list` Missing Restart (Post-DB Proof)

**Date:** 2026-01-25
**Status:** DESIGN / TROUBLESHOOTING HANDOFF (NO EXECUTION)
**Parent Project (Tree):**
KGB Promote Proof – Fresh Seed (Init lifecycle_status)
`project_id = 7a0492cb-7fc5-4bca-b29c-17040803ddd7`

---

## Why This Restart Exists

This restart freezes the system state **after proving that a Restart artifact exists in the database but does not surface via Gateway `artifact.list`.**

Direct SQL verification confirms the Restart exists and is correctly parented. Therefore, the failure is isolated to **Gateway list behavior**, not data integrity or SQL execution.

This document exists to:
- Prevent re-deriving known facts
- Anchor troubleshooting at the correct layer
- Define a deterministic diagnostic plan
- Prepare an execution roadmap without making changes yet

---

## Authoritative Facts (LOCKED)

### Restart Artifact (DB-Proven)

- **artifact_id:** `7922040b-402e-4927-82d2-d71795890ad4`
- **artifact_type:** `restart`
- **parent_artifact_id:** `7a0492cb-7fc5-4bca-b29c-17040803ddd7`
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **deleted_at:** `null`
- **payload:** present and valid

Verified via direct queries against:
- `public.qxb_artifact`
- `public.qxb_artifact_restart`

**Conclusion:**
Any absence of this Restart in Gateway responses is a **Gateway `artifact.list` issue**.

---

## Problem Statement

Gateway `artifact.list` fails to return a Restart artifact that:
- exists in the database
- is not soft-deleted
- is correctly parented
- is owned by the querying user
- is in the correct workspace

The failure must be in one (or more) of the following layers:

1. Artifact type allow-list / registry guard
2. `artifact.list` workflow filtering or wiring
3. Selector logic (`as_of`, offset, hydrate)
4. Workspace or auth resolution
5. Hard-coded constraints in the list workflow

No assumptions are allowed. Only proofs.

---

## Objective

Design and execute a **deterministic troubleshooting sequence** to identify exactly **why Gateway `artifact.list` does not surface restart artifacts**, and produce:

- Root cause (proven)
- Minimal fix plan
- Gated execution checklist

---

## Required Inputs (User Will Provide)

Do **not proceed** until these are supplied:

1. **PowerShell Evidence**
   - Raw request + response for:
     - `artifact.query` (restart by ID)
     - `artifact.list` (artifact_type = restart)
   - Include payloads, headers, and responses verbatim

2. **Gateway Workflow (KGB Baseline)**
   - `NQxb_Artifact_List_v1.json`
   - Must be treated as authoritative ground truth

3. **Any Registry / Guard Config**
   - If Gateway uses a type registry or allow-list for list/query

---

## Diagnostic Plan (Design Only)

### Step 1 — Verify artifact.query works for restart
- Call `artifact.query` with the known restart artifact_id
- Expected: Returns the restart artifact
- If fails: Problem is broader than list

### Step 2 — Verify artifact.list with restart type
- Call `artifact.list` with `artifact_type: restart`
- Expected: Returns list including the known artifact
- If fails: Proceed to Step 3

### Step 3 — Check Type Registry
- Query `qxb_artifact_type_registry` for restart type
- Expected: `enabled = true`
- If missing or disabled: Root cause found

### Step 4 — Review List Workflow
- Examine `NQxb_Artifact_List_v1.json`
- Look for type filtering or hard-coded exclusions
- Expected: No restart-specific exclusion
- If found: Root cause identified

### Step 5 — Check RLS policies
- Review `qxb_artifact` and `qxb_artifact_restart` RLS
- Expected: Restart artifacts visible to owner
- If restrictive: Root cause may be RLS

---

## Explicit Non-Goals

- No SQL writes
- No workflow edits
- No registry changes
- No fixes or patches
- No assumptions about cause

This restart exists to **explain reality before changing it**.

---

## Definition of Done

This restart is complete when:
- The failing layer is identified
- The cause is proven with receipts
- A minimal, governed fix plan exists
- A follow-up build step is clearly defined (but not executed)

---

## Suggested Restart

**When to resume:** When ready to troubleshoot Gateway `artifact.list` missing restart behavior.

**How to resume:** Gather the required inputs (PowerShell evidence, workflow JSON, registry config) and execute the diagnostic plan step by step.

---

*Source: External Restart Document (to be saved into Qwrk when writes are enabled).*
