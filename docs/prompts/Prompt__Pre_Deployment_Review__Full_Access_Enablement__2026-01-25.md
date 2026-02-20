# PRE-DEPLOYMENT REVIEW — Qwrk Full Access Enablement

**Mode:** Agent / Deep Analysis
**Goal:** Identify all issues BEFORE deploying Qwrk Full Access to prevent deployment failures

---

## Context

I am about to enable Full Access (read + write) for Qwrk, a GPT-based artifact management system. The Gateway v1 backend is tested and passing (36/37 tests). Before I deploy new instructions and schema to the ChatGPT Custom GPT, I need you to review everything and identify potential issues.

**Critical constraint:** ChatGPT Custom GPT instructions have an **8,000 character limit**. If the instruction file exceeds this, we need a behavior management strategy.

---

## Uploaded Files

I have uploaded the following files for your review:

### Core Documents
1. `Restart__Full_Access_Enablement__2026-01-25.md` — Deployment checklist and requirements
2. `Qwrk_Gateway_v1_Actions_Schema.yaml` — OpenAPI schema for Gateway actions
3. `Qwrk_Full_Access_MVP_Instructions_v1.md` — System instructions for the GPT

### Gateway Workflows (n8n JSON)
4. `NQxb_Gateway_v1 (*.json)` — Main dispatcher
5. `NQxb_Artifact_Query_v1 (*.json)` — Query single artifact
6. `NQxb_Artifact_List_v1 (*.json)` — List artifacts with pagination
7. `NQxb_Artifact_Save_v1 (*.json)` — Create new artifacts
8. `NQxb_Artifact_Update_v1 (*.json)` — Update existing artifacts
9. `NQxb_Artifact_Promote_v1 (*.json)` — Lifecycle transitions

### Reference (Optional)
10. `AAA_New_Qwrk__North_Star__v0.4__2026-01-24.md` — Vision and architecture

---

## Your Tasks

### Task 1: Instruction File Size Check

1. Count the exact character count of `Qwrk_Full_Access_MVP_Instructions_v1.md`
2. Report: Is it under 8,000 characters?
3. If OVER limit: Propose a trimming strategy that preserves essential behavior

### Task 2: Schema ↔ Workflow Alignment

For each action in the schema (`artifact.query`, `artifact.list`, `artifact.save`, `artifact.update`, `artifact.promote`):

1. Verify the schema request/response shapes match what the workflow actually accepts/returns
2. Flag any mismatches (field names, required vs optional, enum values)
3. Check that all `artifact_type` values in schema are supported by workflows

### Task 3: Instructions ↔ Schema Alignment

1. Verify instructions accurately describe the schema capabilities
2. Check that error codes mentioned in instructions match what workflows return
3. Verify mutability rules in instructions match workflow behavior:
   - `project`: updateable (operational_state, state_reason)
   - `journal`, `restart`, `snapshot`: immutable (update should fail)

### Task 4: Workflow Internal Consistency

Review each workflow JSON for:

1. **Dead ends:** Any paths that don't reach a terminal response node?
2. **Error handling:** All error paths return proper `ok: false` responses?
3. **Type coverage:** All 4 artifact types (project, journal, restart, snapshot) handled?
4. **Field mapping:** Extension fields correctly mapped for each type?

### Task 5: Identify Deployment Risks

List any issues that could cause:

1. **Runtime failures** — Requests that will crash or return empty responses
2. **Contract violations** — Responses that don't match schema
3. **User confusion** — Instructions that promise something workflows can't deliver
4. **Silent failures** — Operations that appear to succeed but don't persist

### Task 6: Behavior Management Strategy (If Needed)

If instructions exceed 8k limit, propose:

1. **Core instructions** (must fit in 8k) — Essential behavior, error handling, safety
2. **Extended behavior** — What can be moved to:
   - Conversation starters
   - Knowledge files
   - In-context examples
3. **Compression techniques** — How to reduce character count without losing meaning

---

## Output Format

Provide your analysis as:

```
## Summary
- Instruction file size: X characters (UNDER/OVER limit)
- Schema-workflow alignment: X issues found
- Instructions-schema alignment: X issues found
- Workflow consistency: X issues found
- Deployment risks: X identified

## Critical Issues (Must Fix Before Deploy)
1. [Issue description + fix]
2. ...

## Warnings (Should Fix)
1. [Issue description + recommendation]
2. ...

## Recommendations
1. [Suggestion for smoother deployment]
2. ...

## Behavior Management Plan (If Over 8k)
[Strategy for fitting within limit]
```

---

## Success Criteria

After your review, I should have:

1. Confidence that deployment will work first try
2. A list of any fixes needed before deployment
3. A behavior management strategy if instructions are too long
4. Clear understanding of any limitations or edge cases

---

**Begin your analysis. Be thorough — I want zero surprises at deployment time.**
