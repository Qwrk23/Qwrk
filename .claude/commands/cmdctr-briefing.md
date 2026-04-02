Generate CmdCtr operator briefing for Qwrk Prime and Q@W via MCP, then produce QSB-ready snapshot save payloads.

Source: CLAUDE.md "CmdCtr Snapshot Contract (Locked)" — last synced 2026-03-24

## Instructions

This skill runs `cmdctr_operator_briefing()` for each workspace, presents the markdown briefing, then generates a QSB-ready snapshot save payload per workspace for Joel to execute manually.

### Step 1: Determine Scope

Default: both workspaces. User can limit with `prime` or `qw`.

Workspaces in scope:
- **Prime** (Qwrk Personal): `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **Q@W** (Work / Resolve): `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`

### Step 2: Execute Briefing Queries via MCP

Use `mcp__supabase__execute_sql` directly (MCP-first — no bash, no heredoc).

**Prime:**
```sql
SELECT cmdctr_operator_briefing();
```

**Q@W:**
```sql
SELECT cmdctr_operator_briefing('635bb8d7-7b93-4bea-8ca6-ee2c924c9557');
```

Run both queries in parallel if both workspaces are in scope.

**Fallback (MCP unavailable):** Present the raw SQL for Joel to run in Supabase SQL Editor. Also present the structured context query:
```sql
SELECT cmdctr_build_session_context();
SELECT cmdctr_build_session_context('635bb8d7-7b93-4bea-8ca6-ee2c924c9557');
```

### Step 3: Execute Structured Context Queries

In addition to the markdown briefing, fetch the structured JSONB for the snapshot payload:

**Prime:**
```sql
SELECT cmdctr_build_session_context();
```

**Q@W:**
```sql
SELECT cmdctr_build_session_context('635bb8d7-7b93-4bea-8ca6-ee2c924c9557');
```

This structured context becomes the `extension.payload` in the snapshot.

### Step 4: Present Briefing Output

For each workspace, present the markdown output under a clear header:

```
## CmdCtr Briefing — Prime (Qwrk Personal)

[markdown output from function]

## CmdCtr Briefing — Q@W (Work / Resolve)

[markdown output from function]
```

Output is markdown that Joel can paste into Q. CC does not transform it.

### Step 5: Generate QSB-Ready Snapshot Payloads

For each workspace in scope, generate one QSB-ready save payload.

**Payload contract (locked — do not deviate):**

For **Prime**, output:

```
prime-exec
```
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "title": "CmdCtr Session Context — <YYYY-MM-DD>",
  "semantic_type_id": "40a5060b-1a80-4e8b-b7b7-1e102026efc0",
  "tags": ["cmdctr", "session-context", "for-q"],
  "priority": 3,
  "extension": {
    "payload": <STRUCTURED_CONTEXT_JSON_FROM_STEP_3>
  }
}
```

For **Q@W**, output:

```
qw-exec
```
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "snapshot",
  "title": "CmdCtr Session Context — <YYYY-MM-DD>",
  "semantic_type_id": "40a5060b-1a80-4e8b-b7b7-1e102026efc0",
  "tags": ["cmdctr", "session-context", "for-q"],
  "priority": 3,
  "extension": {
    "payload": <STRUCTURED_CONTEXT_JSON_FROM_STEP_3>
  }
}
```

**Rules:**
- `<YYYY-MM-DD>` = today's date
- `extension.payload` = the full JSONB result from `cmdctr_build_session_context()` for that workspace
- NEVER include `artifact_id` (server generates)
- NEVER modify the tag bundle
- NEVER change the semantic_type_id
- Joel executes these via QSB (CC does NOT execute saves per CLAUDE.md Section 2.5)

### Step 6: Forest Topology Note

If briefing includes Forest Topology referencing a Forest Map project:
- Prime Forest Map: `08396b6b`
- Remind Joel that Q hydrates on-demand — full tree is NOT embedded in briefing

## Error Handling

| Error | Response |
|-------|----------|
| MCP `execute_sql` fails | Report error. Offer raw SQL for manual execution in Supabase SQL Editor. Skip snapshot payload (no structured context available). |
| Function not found | "`cmdctr_operator_briefing()` may not be deployed. Check migrations." |
| Timeout | Retry once, then report. Function should complete in < 5s. |
| Empty result | Warn — may indicate no artifacts in workspace. |
| Structured context unavailable | Present briefing markdown only. Note that snapshot payload cannot be generated without structured context. |

## NEVER DO

- Never execute briefing SQL through bash/heredoc — use MCP directly
- Never transform or summarize the briefing output — present it verbatim
- Never execute the snapshot save payload — Joel executes via QSB
- Never omit the snapshot payload step — it is required for delta continuity
- Never modify the locked tag bundle or semantic_type_id
