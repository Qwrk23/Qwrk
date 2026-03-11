# CC Execution Prompt — Clean Execution Hygiene (E3 + C2)

You are executing a workflow hygiene + DDL hardening pass. This is a cleanup and structural integrity task. No feature expansion.

## Objective
1) Remove dead/debug nodes from production workflows (E3)
2) Embed search_path hardening directly into DDL function definitions (C2)

Do not alter business logic.

---

# PART 1 — Workflow Purity & Dead Node Removal (E3)

## Target Workflows
- NQxb_Artifact_Query_v1 (v18)
- NQxb_Artifact_Save_v1 (v31)
- NQxb_Artifact_Update_v1 (v12)
- NQxb_Artifact_Promote_v2_HTTP

## Required Actions

1. Remove Query debug Code node that injects debug_compare_* fields.
2. Remove Save "testing" node with no output connections.
3. Remove dead Query-after-Update nodes in Update v12 (Build_Query_Request + Prepare_Query_Call if unused).
4. Remove dead Query call in Promote if output unconnected.

## Governance Invariant
Must comply with Amendment 1 — Production Workflow Purity Rule.
No debug-only nodes in activated workflows.

## Safety Checks
- Ensure no Switch node has empty output branches.
- Ensure every error envelope still routes deterministically.
- Validate no canonical fields are stripped.

---

# PART 2 — DDL search_path Hardening (C2)

## Input
LIVE_DDL__Kernel_v1__2026-01-04.sql (current v2.3)

## Required Actions

1. Locate all CREATE FUNCTION definitions.
2. Modify each to include:

   SET search_path = public;

   directly within the CREATE FUNCTION block.

3. Remove reliance on post-creation ALTER FUNCTION hardening migration.
4. Increment DDL version to v2.4.
5. Add CHANGELOG entry documenting inline hardening.

## Constraints
- Do not alter function logic.
- Do not change signatures.
- Do not modify RLS policies.

---

# Validation Requirements

Before completion:
- All workflows export clean (no dead nodes).
- No debug fields appear in response payloads.
- DDL functions contain inline search_path hardening.
- Version header updated to v2.4.

---

# Deliverables

1) Updated workflow JSON exports (cleaned)
2) Updated LIVE_DDL__Kernel_v1__v2.4.sql
3) Commit message:

"Execution hygiene: remove dead/debug nodes + inline search_path hardening (DDL v2.4)"

Stop after commit.

