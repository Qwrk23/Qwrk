Generate CmdCtr operator briefing for both workspaces via MCP.

Source: MEMORY.md "Session Management" — last synced 2026-03-10

## Instructions

This skill runs the `cmdctr_operator_briefing()` function for both workspaces and presents copy-paste-ready markdown for Joel to hand to Q.

### Step 1: Determine Scope

Default: both workspaces. User can limit with `prime` or `qw`.

### Step 2: Execute Briefing Queries via MCP

Use `mcp__supabase__execute_sql` directly (MCP-first — no bash, no heredoc).

**Prime (Qwrk Personal):**
```sql
SELECT cmdctr_operator_briefing();
```

**Q@W (Work / Resolve):**
```sql
SELECT cmdctr_operator_briefing('635bb8d7-7b93-4bea-8ca6-ee2c924c9557');
```

Run both queries in parallel if both workspaces are in scope.

### Step 3: Present Output

For each workspace, present the markdown output under a clear header:

```
## CmdCtr Briefing — Prime (Qwrk Personal)

[markdown output from function]

## CmdCtr Briefing — Q@W (Work / Resolve)

[markdown output from function]
```

Output is markdown that Joel pastes into Q. CC does not process or transform it.

### Step 4: Forest Topology Note

If briefing includes Forest Topology referencing a Forest Map project:
- Prime Forest Map: `08396b6b`
- Remind Joel that Q hydrates on-demand — full tree is NOT embedded in briefing

## Error Handling

| Error | Response |
|-------|----------|
| MCP `execute_sql` fails | Report error. Offer raw SQL for manual execution. |
| Function not found | "`cmdctr_operator_briefing()` may not be deployed. Check migrations." |
| Timeout | Retry once, then report. Function should complete in < 5s. |
| Empty result | Warn — may indicate no artifacts in workspace. |

## NEVER DO

- Never execute briefing SQL through bash/heredoc — use MCP directly
- Never transform or summarize the briefing output — present it verbatim
- Never store briefing to files (it's for Joel to paste into Q)
