Generate artifact registry CSV indexes for all active workspaces.

Source: CLAUDE.md "Artifact Registry Discipline" — last synced 2026-03-10

## Instructions

This skill generates CSV mirrors of `qxb_artifact` for quick local lookup. The registry is an operational index, NOT a system-of-record.

### Step 1: Determine Scope

If the user specified a workspace (`prime`, `qw`, or `all`), use that. Default: `all` (both workspaces).

| Workspace | ID | CSV Path |
|-----------|-----|----------|
| **Prime** | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` | `Qwrk_RollingMem/artifact_registry__YYYY-MM-DD.csv` |
| **Q@W** | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/RollingMem/artifact_registry__qw__YYYY-MM-DD.csv` |

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

### Step 4: Save CSV Files

Write using today's date. Use bash `cat >` with quoted paths (OneDrive EEXIST workaround).

- **Prime:** `Qwrk_RollingMem/artifact_registry__YYYY-MM-DD.csv`
- **Q@W:** `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/RollingMem/artifact_registry__qw__YYYY-MM-DD.csv`

Do NOT delete or overwrite previous dated files. Each refresh produces a new dated file.
Same-day refresh overwrites the current date's file only.

### Step 5: Confirm Completion

Output:
```
Registry refresh complete:
  Prime: artifact_registry__YYYY-MM-DD.csv (N rows)
  Q@W:   artifact_registry__qw__YYYY-MM-DD.csv (N rows)
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
- Never delete previous dated CSV files
- Never execute SQL through bash/heredoc — use MCP directly
