Execute SQL against Supabase safely, avoiding shell quoting issues.

Source: CLAUDE.md §2.5, §2.6 — last synced 2026-03-10

## The Problem This Solves

SQL contains single quotes (e.g., `'be0d3a48-...'`). When passed through bash heredoc or inline shell, quotes break. This skill ensures CC always uses the correct execution path.

## Instructions

### Step 1: Determine the SQL

If the user provided SQL, use it directly. If not, compose it — but first run the `/ddl-check` skill if touching `qxb_*` tables.

### Step 2: Choose the execution path

**ALWAYS prefer MCP tool (Option A).** Only fall back to Option B if MCP is unavailable.

#### Option A: MCP Tool (PREFERRED — zero quoting issues)

Use `mcp__supabase__execute_sql` directly. This is a tool call with a string parameter — no shell involved, no escaping needed. Single quotes in SQL work perfectly.

```
Tool: mcp__supabase__execute_sql
Parameter "sql": SELECT * FROM qxb_artifact WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a' LIMIT 5;
```

**Rules for MCP execution:**
- Pass the SQL as-is in the `sql` parameter — no escaping, no wrapping
- One statement per call (no semicolon-separated batches unless the SQL is a single logical statement)
- Read-only queries only (per CLAUDE.md Section 2.5). For writes, present the SQL to the user instead.

#### Option B: Temp File (FALLBACK — when MCP unavailable)

If MCP is not available and bash is the only option:

1. Write SQL to a temp file using the Write tool:
   ```
   Write tool -> /tmp/cc_sql_temp.sql
   ```

2. Execute via psql or PowerShell reading from file:
   ```bash
   # Never inline the SQL — always read from file
   powershell -Command "Get-Content /tmp/cc_sql_temp.sql | ..."
   ```

3. Clean up the temp file after execution.

### Step 3: Present results

- For SELECT queries: show results in a readable table format
- For DDL/DML (user-executed): present the SQL in a clean code block for copy-paste
- If the query returns no rows, say so explicitly

## NEVER DO THIS

These patterns WILL break and must never be used:

```bash
# BROKEN: heredoc with single quotes in SQL
bash -c "echo 'SELECT ... WHERE id = 'breaks-here''"

# BROKEN: PowerShell inline through bash with SQL quotes  
powershell -Command "Invoke-RestMethod ... 'sql': 'SELECT ... WHERE id = ''uuid'''"
```

## Quick Reference

| Scenario | Method |
|----------|--------|
| Read query (SELECT) | MCP `execute_sql` directly |
| Write SQL (INSERT/UPDATE/DELETE) | Generate SQL, present to user (CLAUDE.md 2.5) |
| MCP unavailable | Write to `/tmp/cc_sql_temp.sql`, execute from file |
| PowerShell Gateway query | Use `scripts/CC-Gateway-Query.ps1` (already handles escaping) |
