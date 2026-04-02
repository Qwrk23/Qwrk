# Manus Review Framework

**Purpose:** Repeatable 5-part lens for reviewing any Qwrk build plan.
**Date:** 2026-03-22
**Usage:** Apply all 5 sections to every plan review. Skip a section only if genuinely not applicable.

---

## How to Use This Framework

For each plan Manus reviews:

1. Read the plan fully before starting the framework
2. Work through each of the 5 sections in order
3. For each section, note findings with severity (HARD / SOFT / INFO)
4. Compile findings into the review output format defined in `manus_review_contract.md`

---

## 1. Structural Fit

**Question:** Does the plan fit the existing architecture and artifact model?

### What Manus Checks
- Does the plan use existing tables, types, and fields correctly?
- Does the plan respect the spine + extension pattern?
- Are parent/child relationships valid per hierarchy rules?
- Does the plan introduce new structural elements (types, tables, columns)? If so, are they properly scoped?
- Does the plan account for the class-table inheritance model (writes to both spine and extension)?
- Are workspace/tenancy boundaries respected?

### What a Strong Plan Looks Like
- References specific tables and columns by name
- Shows awareness of spine vs extension separation
- New structural elements include migration plan and constraint definitions
- Parent/child relationships follow the hierarchy rules

### What Failure Smells Like
- Vague references to "the database" without naming tables
- Assuming fields exist on the wrong table (spine vs extension confusion)
- Proposing parent/child relationships that violate hierarchy rules (e.g., leaf parenting a leaf)
- Ignoring workspace isolation
- Proposing new artifact types without specifying CHECK constraint update, extension table design, and Gateway routing

### Manus Output
For each structural concern, state:
- What element is affected
- What rule it may violate
- Severity (HARD if schema constraint would fail; SOFT if design concern)

---

## 2. Governance Compliance

**Question:** Does the plan violate known invariants, phase gates, mutability rules, or authority boundaries?

### What Manus Checks
- Does the plan respect the truth hierarchy? (Behavioral Controls > North Star > Phase Locks > KGB)
- Does the plan propose changes that conflict with locked decisions?
- Are immutability rules respected (snapshots, restarts, event log)?
- Does the plan propose updating or deleting data that should be immutable?
- Is the file versioning approach specified (Pattern A/B/C)?
- Does the plan include a file manifest?
- Does the plan respect phase boundaries (not assuming unreleased features are available)?
- Does the plan follow governance-first merge order?

### What a Strong Plan Looks Like
- Explicitly states which governance surfaces are affected
- References canonical docs when proposing changes near governance boundaries
- Includes file manifest with versioning pattern
- Notes if any locked decisions need to be reopened (with justification)
- Follows planning-before-execution discipline

### What Failure Smells Like
- Modifying locked governance without acknowledgment
- Assuming features from a future phase are available
- Missing file manifest or vague "update files as needed"
- Overwriting files without versioning
- Proposing hard deletes or updates to immutable artifacts
- Skipping parallel build approach for changes to live systems

### Manus Output
For each governance concern, state:
- Which governance rule is affected
- Whether the plan violates it or just approaches it
- Severity (HARD if invariant violation; SOFT if best-practice deviation)

---

## 3. Contract Alignment

**Question:** Do payloads, workflow assumptions, schema references, and action semantics match known contract surfaces?

### What Manus Checks
- Do Gateway action references match the 10 supported actions?
- Are request envelope fields correct (gw_action, gw_workspace_id, artifact_type)?
- Do payload shapes match expected formats?
- Are error handling expectations aligned with the Gateway error contract?
- Do field names match actual column names (not aliases or outdated names)?
- Does the plan account for Gateway normalization behavior?
- If proposing new Gateway actions: is the full stack addressed (Gatekeeper, sub-workflow, response shaper, Gateway routing)?
- Does the plan account for multi-gateway deployment (primary + beta)?

### What a Strong Plan Looks Like
- Uses exact field names from schema
- Shows example payloads that match Gateway envelope format
- Accounts for error cases and edge conditions
- Specifies which gateways are affected
- Notes sub-workflow version updates and Gateway "Execute Workflow" node updates

### What Failure Smells Like
- Using invented field names or aliases
- Assuming a Gateway action exists that is not in the supported list
- Payloads that mix spine and extension fields incorrectly
- Missing sub-workflow → Gateway deployment coupling
- Ignoring multi-gateway rollout (changing one gateway but not the other)

### Manus Output
For each contract concern, state:
- Which contract surface is affected
- What the expected behavior is
- How the plan deviates
- Severity (HARD if would cause runtime failure; SOFT if contract interpretation issue)

---

## 4. Execution Completeness

**Question:** Are dependencies, validation, rollout, documentation, and state transitions adequately accounted for?

### What Manus Checks
- Are prerequisite steps identified and ordered?
- Does the plan account for database migrations (if schema changes)?
- Is there a testing or validation strategy?
- Is documentation updated (README, schema reference, CLAUDE.md if applicable)?
- Are rollback procedures considered?
- Does the plan specify deployment order (sub-workflow first, then Gateway)?
- Are there implicit dependencies the plan doesn't mention?
- Is the Phase 2C certification harness relevant? If so, does the plan address it?
- Does the plan account for multi-workspace impact?

### What a Strong Plan Looks Like
- Numbered implementation steps in dependency order
- Migration plan with rollback
- Testing strategy (manual, script, or certification harness)
- Documentation update list
- Deployment sequence specified
- Workspace scope defined (which workspaces are affected)

### What Failure Smells Like
- Steps that depend on unfinished prior work not mentioned in the plan
- No testing strategy
- No documentation update plan
- Migration without rollback
- Deployment without specifying order
- Assuming all workspaces are identical when they may have different Gateway versions

### Manus Output
For each completeness concern, state:
- What is missing
- Why it matters (what could go wrong)
- Severity (HARD if execution would fail without it; SOFT if it's a gap that increases risk)

---

## 5. Risk & Ambiguity Scan

**Question:** What could fail due to stale assumptions, unclear ownership, hidden coupling, or missing detail?

### What Manus Checks
- Does the plan rely on assumptions about current state that might be stale?
- Are there areas where the plan is vague about *who* does *what*?
- Could changes in one component unexpectedly affect another?
- Are there single points of failure in the plan?
- Does the plan touch components that have known technical debt or open bugs?
- Is the plan's scope well-bounded, or could it expand during execution?
- Are there time-sensitive dependencies (e.g., merge freezes, parallel sessions)?

### What a Strong Plan Looks Like
- States assumptions explicitly
- Identifies risks and mitigation
- Scope is clearly bounded with explicit non-goals
- Accounts for known technical debt in the affected area
- Ownership is clear (who executes each step)

### What Failure Smells Like
- Implicit assumptions about current state ("this should still be...")
- Unbounded scope ("and then we can also...")
- No risk acknowledgment
- Touching areas with known open bugs without acknowledging them
- Missing ownership (steps that don't specify who executes)
- Coupling between plan steps and external work not in the plan

### Manus Output
For each risk/ambiguity concern, state:
- What the risk is
- What could go wrong
- What information would reduce the risk
- Severity (HARD if likely to cause failure; SOFT if risk is real but manageable; INFO if worth noting)

---

## Framework Summary

| # | Dimension | Core Question |
|---|-----------|---------------|
| 1 | Structural Fit | Does it fit the existing architecture? |
| 2 | Governance Compliance | Does it violate known rules? |
| 3 | Contract Alignment | Do references match real surfaces? |
| 4 | Execution Completeness | Is everything accounted for? |
| 5 | Risk & Ambiguity Scan | What could go wrong? |

Apply all 5. Report findings by severity. Lead with the most important issues.

---

## CHANGELOG

### v1 — 2026-03-22
Initial creation for Manus plan reviewer role.
