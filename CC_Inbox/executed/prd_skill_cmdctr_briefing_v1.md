# PRD: /cmdctr-briefing — CmdCtr Operator Briefing Generation

> **Date:** 2026-03-09
> **Parent:** `CC_Inbox/prd_cc_skills_suite_v1__pre_planning.md`
> **Source Governance:** MEMORY.md "Session Management" section (CmdCtr briefing at session start)

---

## Intent

Generate the CmdCtr operator briefing for both workspaces via MCP in a single deterministic flow. Eliminates:

- **Function name lookup** — CC forgets `cmdctr_operator_briefing()` and searches MEMORY.md
- **Workspace ID memorization** — CC looks up the Q@W workspace ID every time
- **Missed workspace** — CC runs for Prime but forgets Q@W
- **Shell quoting** — Uses MCP-first pattern (no bash SQL escaping)

---

## Non-Goals

- Does NOT modify the briefing function or its output
- Does NOT store briefing output to files (it's for Joel to paste into Q)
- Does NOT replace session start protocol (this is one step within it)
- Does NOT generate Forest Map updates (separate concern)

---

## Trigger

User invokes `/cmdctr-briefing` or CC is performing session start protocol.

**Arguments (optional):** Workspace name (`prime`, `qw`, or `all`). Default: `all`.

---

## Prerequisites

1. MCP tool `mcp__supabase__execute_sql` must be available
2. `cmdctr_operator_briefing()` function must exist in Supabase (deployed via migration)

---

## Step Sequence

### Step 1: Determine Scope

Default: both workspaces. User can limit to one.

### Step 2: Execute Briefing Queries via MCP

Use `mcp__supabase__execute_sql` directly (MCP-first — no bash, no heredoc).

**Prime (Qwrk Personal):**
```sql
SELECT cmdctr_operator_briefing();
```
No arguments — function defaults to Prime workspace context.

**Q@W (Work / Resolve):**
```sql
SELECT cmdctr_operator_briefing('635bb8d7-7b93-4bea-8ca6-ee2c924c9557');
```
Parameterized with Q@W workspace_id.

Run both queries in parallel if both workspaces are in scope.

### Step 3: Present Output

For each workspace, present the markdown output under a clear header:

```
## CmdCtr Briefing — Prime (Qwrk Personal)
[markdown output from function]

## CmdCtr Briefing — Q@W (Work / Resolve)
[markdown output from function]
```

The output is markdown that Joel pastes into Q for context. CC does not process or transform it beyond presentation.

### Step 4: Forest Topology Note (Optional)

If the briefing includes a Forest Topology section referencing a Forest Map project:
- Note the Forest Map artifact_id (Prime: `08396b6b...`)
- Remind Joel that Q hydrates on-demand — full tree is NOT embedded in briefing

---

## Decision Points

| Situation | CC Action |
|-----------|-----------|
| User says just "briefing" | Run for BOTH workspaces |
| User specifies workspace | Run for that workspace only |
| MCP unavailable | Report error — briefing requires MCP |
| Function returns error | Report SQL error — function may not be deployed |
| Empty result | Warn — may indicate no artifacts in workspace |

---

## Output Format

Clean markdown blocks per workspace, ready for Joel to copy-paste into Q. No additional formatting or wrapping needed.

---

## Error Handling

| Error | Response |
|-------|----------|
| MCP `execute_sql` fails | Report error. Offer the raw SQL for manual execution. |
| Function not found | "cmdctr_operator_briefing() may not be deployed. Check migrations." |
| Timeout | Retry once, then report. Briefing function should complete in < 5s. |

---

## Acceptance Criteria

1. `/cmdctr-briefing` produces markdown output for both workspaces
2. SQL is executed via MCP (not bash/heredoc)
3. Output is presented in copy-paste-ready format
4. No user interaction required beyond the initial trigger
5. Works standalone or as part of session start protocol

---

## CHANGELOG

| Date | Entry |
|------|-------|
| 2026-03-09 | Initial PRD created |
