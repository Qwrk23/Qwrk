# Runbook — CC Workflow Build Discipline (v1) — 2026-01-02

## Purpose
Keep n8n workflow development deterministic, governable, and easy to review.

## Rules (non-negotiable)
1. **Do not guess schemas or enums.** Use the North Star + current contract docs.
2. **Normalize payloads early.** Downstream nodes should never depend on “wrapped” structures.
3. **No auto-mapping into Supabase nodes** when payloads are wrapped. Flatten first.
4. **Spine-first writes, then type writes.** If type write fails, roll back spine row.
5. **KGB before merge.** A workflow is not “done” until KGB passes.

## Required artifacts per workflow
For each workflow (Gateway router, save, query, list), CC should maintain:
- A short README block (what it does)
- Input contract (example payload)
- Output contract (example response)
- Failure modes
- KGB steps

## Review checkpoints
- After a working change: capture a small “History/Report” note and mirror it to GitHub.
- After a KGB pass: tag the workflow export as Known-Good.

## Naming conventions
- Workflows + nodes: `Qx_<WorkflowName>_<NodePurpose>`
- Tables: `qxb_*`
- GitHub docs: `Build_Tree__*`, `Runbook__*`, `KGB__*`

