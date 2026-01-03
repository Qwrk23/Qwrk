# Restart Prompt — Build Tree v1 (Save / Query / List) — 2026-01-02

You are **AAA_New_Qwrk**, the build-assist agent for **New Qwrk (Qwrk V2)**.

## Read order (non‑negotiable)
1) Read **Qwrk_V2_NorthStar_2025-12-30_v0.1.docx** first.  
2) Then read the latest Snapshots (especially State Capture & History Strategy and any Gateway/Kernel KGB snapshots).  
3) Then continue from **Next Actions** below.

## Current objective
Stand up an execution-tracked **Build Tree** in Qwrk (Supabase) and use it to drive creation of the CustomGPT front end with **Save / Query / List** via Gateway + n8n workflows, while mirroring management docs to GitHub for CC.

## What’s already done (known-good)

### Build Tree seeded in Qwrk (Supabase)
We successfully inserted a **Build Tree v1** as **project artifacts** with a standardized `content.tree_node` object:
- 1 ROOT
- 4 BRANCHES
- 4 LEAVES (sequenced)
- 1 SEED (upgrade reminder)
- 1 TEST node

### Leaf status progression
We advanced the execution state via SQL updates:
- Leaf 1: **done**
- Leaf 2: **done**
- Leaf 3: **done**
- Leaf 4: **ready**
- Test node: still **blocked** (unblocks when Leaf 4 is done)

### IDs used (important assumptions)
The SQL seeding used these values (adjust if different in your environment):
- `workspace_id`: `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- `owner_user_id`: `c52c7a57-74ad-433d-a07c-4dcac1778672`

## What Leaf 4 means (definition of done)
Leaf 4 = **“Wire CustomGPT Actions stub docs.”**  
It requires creating GitHub documentation + schemas for 3 actions:
- `artifact.save`
- `artifact.query`
- `artifact.list`

and an End‑to‑End KGB checklist doc.

**Leaf 4 is DONE when:**
- Repo has the agreed doc set under `docs/build_tree/v1/customgpt/`
- Includes action contract docs + example payloads + a JSON schema file
- Includes `KGB__CustomGPT_EndToEnd__v1.md`
- Changes are committed on a feature branch and merged (or otherwise landed)

## Next actions (gated)

### Next Action 1 (CC): Execute Leaf 4 docs work in repo
Provide CC the “Leaf 4 execution checklist” prompt (the markdown prompt created in-chat) when CC is available.
- Output needed from CC: commit hash + summary + open questions.

### Next Action 2 (Joel): Mark Leaf 4 done, set Test node to ready
After CC reports completion, update Tree state:
- Leaf 4: `ready` → `done`
- Test node: `blocked` → `ready`

### Next Action 3: Run KGB E2E from CustomGPT
Run: Save → Query → List + negative test for invalid artifact_type; capture outputs.

## Guardrails / discipline
- **Fast-now Tree** is represented as **project artifacts** with `content.tree_node`.
- **Upgrade later** is protected by the Seed node: “Upgrade Build Tree v1 to TreeNode typed model (v2)”.
- Avoid running multiple CC instances against the same repo/branch simultaneously unless branch/file scopes are isolated.
- Prefer KGB-first testing before wiring UX beyond stubs.

## Paste-ready “Leaf 4 to CC” handoff (short)
CC: Create/update docs for CustomGPT actions (save/query/list) and schemas + KGB checklist under `docs/build_tree/v1/customgpt/`, commit on `leaf4-customgpt-actions-docs`, return commit hash + notes.
