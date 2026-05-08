Generate artifact registry CSV indexes for all active workspaces.

> **DEPRECATED — 2026-04-24.** The local CSV artifact registry is retired. Discovery is now via Gateway `artifact.list` / `artifact.query` and the Artifact Discovery Playbook (snapshot `16b19a1c`). Source decision: snapshot `0cb18b07` (Rolling Memory Migration Correction).
>
> **Replacement:**
> - Discovery: `artifact.list` with tag/type/lifecycle filters
> - Hydration: `artifact.query` (full UUID required)
> - Reference: Artifact Discovery Playbook (`16b19a1c`)
> - CC helper: `scripts/CC-Gateway-Query.ps1` (CLAUDE.md §2.6)
>
> This skill is retained for historical/audit reference only. Do NOT invoke in normal operation. CLAUDE.md v32 (2026-05-05) marks the registry deprecated; CSV refresh is no longer governance-supported.

Source: CLAUDE.md "Artifact Registry Discipline" — last synced 2026-03-10 (section replaced by "Artifact Registry (Deprecated)" in v32)

## Instructions

This skill generates CSV mirrors of `qxb_artifact` for quick local lookup. The registry is an operational index, NOT a system-of-record.

### Step 1: Determine Scope

If the user specified a workspace (`prime`, `qw`, or `all`), use that. Default: `all` (both workspaces).

| Workspace | ID | CSV Path |
|-----------|-----|----------|
| **Prime** | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` | `Qwrk_RollingMem/artifact_registry__YYYY-MM-DD.csv` |
| **Q@W** | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/Q@W Rolling Mem/artifact_registry__qw__YYYY-MM-DD.csv` |

### Step 2: Execute Canonical SQL via MCP

Use `mcp__supabase__execute_sql` directly (MCP-first — no bash, no heredoc).

**Canonical SQL** (substitute workspace_id for each):

```sql
SELECT
    a.artifact_id::text,
    a.artifact_type,
    a.title,
    a.priority,
    a.lifecycle_status,
    a.execution_status,
    a.semantic_type_id::text,
    st.key AS semantic_type,
    COALESCE(a.tags::text, '[]') AS tags,
    a.parent_artifact_id::text,
    a.created_at,
    a.updated_at
FROM public.qxb_artifact a
LEFT JOIN public.qxb_semantic_type_registry st
  ON st.semantic_type_id = a.semantic_type_id
WHERE a.workspace_id = '<WORKSPACE_ID>'
  AND a.deleted_at IS NULL
ORDER BY a.created_at ASC;
```

Run both queries in parallel if both workspaces are in scope.

### Step 3: Generate CSV

For each workspace's query results:

1. Header row:
   ```
   artifact_id,artifact_type,title,priority,lifecycle_status,execution_status,semantic_type_id,semantic_type,tags,parent_artifact_id,created_at,updated_at
   ```
2. One row per artifact, ordered by `created_at ASC`
3. Quote fields containing commas (especially `title` and `tags`)
4. Preserve NULL values as empty strings

### Step 4: Archive Previous CSV Files

Before writing new CSV files, move any existing CSV files (from previous dates) into an `Archive/` subfolder:

- **Prime:** Move `Qwrk_RollingMem/artifact_registry__*.csv` (excluding today's date) → `Qwrk_RollingMem/Archive/`
- **Q@W:** Move `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/Q@W Rolling Mem/artifact_registry__qw__*.csv` (excluding today's date) → `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/Q@W Rolling Mem/Archive/`

Create `Archive/` subfolder if it doesn't exist. Do NOT delete archived files.

### Step 5: Save CSV Files

Write using today's date. Use the Write tool (not bash heredoc — avoids shell escaping issues with special characters in titles/tags).

- **Prime:** `Qwrk_RollingMem/artifact_registry__YYYY-MM-DD.csv`
- **Q@W:** `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/Q@W Rolling Mem/artifact_registry__qw__YYYY-MM-DD.csv`

Same-day refresh overwrites the current date's file only.

### Step 6: Confirm Completion

Output:
```
Registry refresh complete:
  Prime: artifact_registry__YYYY-MM-DD.csv (N rows)
  Q@W:   artifact_registry__qw__YYYY-MM-DD.csv (N rows)
  Archived: [list any files moved to Archive/]
```

## Error Handling

| Error | Response |
|-------|----------|
| MCP `execute_sql` fails | Report error. Offer raw SQL for manual execution in Supabase SQL Editor. |
| CSV write fails | Report error. Output CSV content to console for user to save manually. |
| Query returns 0 rows | Warn user — likely indicates a problem. |
| Unexpected columns | STOP — SQL may have drifted from DDL. Run `/ddl-check`. |

## NEVER DO

- Never auto-trigger at session start or end (explicit command only)
- Never delete archived CSV files
- Never execute SQL through bash/heredoc — use MCP directly
- Never write CSV via bash heredoc — use the Write tool (shell escaping breaks on special characters in titles/tags)
- Never leave previous dated CSV files in the main folder — archive them first
