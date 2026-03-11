# PRD: /registry-refresh — Dual-Workspace Artifact Registry CSV Generation

> **Date:** 2026-03-09
> **Parent:** `CC_Inbox/prd_cc_skills_suite_v1__pre_planning.md`
> **Source Governance:** CLAUDE.md "Artifact Registry Discipline (Operational Index)"

---

## Intent

Codify the `Registry refresh` command into a deterministic skill. Eliminates:

- **SQL lookup** — CC re-reads the canonical SQL from CLAUDE.md every time
- **Path memorization** — CC forgets the workspace-specific save paths
- **Workspace ID lookup** — CC checks MEMORY.md for UUIDs each time
- **Missing workspace** — CC refreshes Prime but forgets Q@W (or vice versa)

The registry is an operational index (NOT system-of-record). This skill generates CSV mirrors of `qxb_artifact` for quick local lookup.

---

## Non-Goals

- Does NOT auto-trigger at session start or end (explicit command only)
- Does NOT delete or overwrite previous dated CSV files
- Does NOT influence runtime behavior or governance
- Does NOT query beyond the spine + semantic_type_registry JOIN
- Does NOT generate rolling memory files (different protocol)

---

## Trigger

User says "Registry refresh" or invokes `/registry-refresh`.

**Arguments (optional):** Workspace name (`prime`, `qw`, or `all`). Default: `all` (both workspaces).

---

## Prerequisites

1. MCP tool `mcp__supabase__execute_sql` must be available
2. No other prerequisites — this is a standalone operation

---

## Step Sequence

### Step 1: Determine Scope

If the user specified a workspace, run for that workspace only. Otherwise run for both.

| Workspace | ID | CSV Path |
|-----------|-----|----------|
| **Prime** | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` | `Qwrk_RollingMem/artifact_registry__YYYY-MM-DD.csv` |
| **Q@W** | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/RollingMem/artifact_registry__qw__YYYY-MM-DD.csv` |

### Step 2: Execute Canonical SQL (Per Workspace)

Use `mcp__supabase__execute_sql` directly (MCP-first rule — no bash, no heredoc).

**Canonical SQL** (substitute `<WORKSPACE_ID>` for each workspace):

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

1. Format as CSV with header row:
   ```
   artifact_id,artifact_type,title,priority,lifecycle_status,execution_status,semantic_type_id,semantic_type,tags,parent_artifact_id,created_at,updated_at
   ```
2. One row per artifact, ordered by `created_at ASC`
3. Quote fields that contain commas (especially `title` and `tags`)
4. Preserve NULL values as empty strings

### Step 4: Save CSV Files

Write to the workspace-specific path using today's date:

- **Prime:** `Qwrk_RollingMem/artifact_registry__2026-03-09.csv`
- **Q@W:** `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/RollingMem/artifact_registry__qw__2026-03-09.csv`

**Use bash `cat >` for writing** (OneDrive EEXIST bug affects Write/Edit tools on paths with spaces).

Do NOT delete or overwrite previous dated files. Each refresh produces a new dated file.

### Step 5: Confirm Completion

Output:

```
✅ Registry refresh complete:
  Prime: artifact_registry__2026-03-09.csv (N rows)
  Q@W:   artifact_registry__qw__2026-03-09.csv (N rows)
```

---

## Decision Points

| Situation | CC Action |
|-----------|-----------|
| User says just "registry refresh" | Run for BOTH workspaces |
| User specifies "prime only" or "qw only" | Run for specified workspace only |
| MCP tool unavailable | Report error, offer SQL for manual execution |
| Query returns 0 rows | Warn user — likely indicates a problem |
| File with today's date already exists | Overwrite it (same-day refresh replaces) |

---

## Output Format

1. **During execution:** Brief status per workspace ("Querying Prime... N rows returned")
2. **On completion:** Summary with file paths and row counts

---

## Error Handling

| Error | Response |
|-------|----------|
| MCP `execute_sql` fails | Report the error. Offer the raw SQL for manual execution in Supabase SQL Editor. |
| CSV write fails (permissions/path) | Report error. Output CSV content to console for user to save manually. |
| Query returns unexpected columns | STOP — SQL may have drifted from DDL. Run `/ddl-check` before proceeding. |

---

## Acceptance Criteria

1. Running `/registry-refresh` produces two CSV files (one per workspace)
2. CSV has exactly 12 columns matching the canonical SQL SELECT list
3. Previous dated files are NOT deleted
4. Row counts are reported for each workspace
5. SQL is executed via MCP (not bash/heredoc)
6. No user interaction required beyond the initial trigger (fully autonomous)

---

## SQL Drift Guard

This SQL must not drift unless DDL schema changes require it. If any of these change, the skill file and this PRD must be updated:

- Columns on `qxb_artifact` spine
- `qxb_semantic_type_registry` table structure
- Workspace IDs

---

## CHANGELOG

| Date | Entry |
|------|-------|
| 2026-03-09 | Initial PRD created |
