Query or list artifacts via Gateway (Prime) or MCP SQL (all workspaces).

Source: CLAUDE.md §2.6 — last synced 2026-03-10

## Instructions

This skill wraps artifact lookups with input validation, workspace routing, and smart defaults.

### Step 1: Parse User Intent

| User says | Action | Type | Extra |
|-----------|--------|------|-------|
| A full UUID | `query` | infer or ask | ArtifactId |
| "list projects" | `list` | `project` | |
| "list for-q snapshots" | `list` | `snapshot` | Tags = "for-q" |
| "find artifact titled X" | `list` | all or specified | title search |

### Step 2: Validate Inputs

**Full UUID check (CRITICAL):**
- UUIDs must be 36 characters (8-4-4-4-12 format)
- If short prefix (8 chars) provided, STOP:
  > "Gateway requires full UUIDs (36 characters). Do you have the complete artifact_id?"

**Artifact type validation:**
- Allowed: `project`, `journal`, `restart`, `snapshot`, `instruction_pack`, `branch`, `limb`, `leaf`, `twig`
- NOT allowed (Gateway error): `thorn`, `grass`, `forest`, `thicket`, `flower`
- If disallowed type requested:
  > "`thorn` is not queryable via Gateway. Use `/run-sql` for direct SQL."

**Query action requires artifact_type:**
- If user gives UUID without type, infer from context or ask:
  > "What artifact type is this? (project, snapshot, journal, etc.)"

### Step 3: Determine Workspace and Route

**Default:** Prime

**Override detection:**
- "work", "Q@W", "Resolve" → Q@W
- "BlaggLife" → BlaggLife
- "Akara" → Akara
- Recent conversation context about a non-Prime workspace → use that

**Routing rule (CRITICAL):**

| Workspace | ID | Execution Path |
|-----------|-----|----------------|
| **Prime** | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` | `CC-Gateway-Query.ps1` |
| **Q@W** | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | MCP SQL via `/run-sql` |
| **BlaggLife** | `b4e7f648-96d5-44a7-80b9-c39cac4efbd1` | MCP SQL via `/run-sql` |
| **Akara** | `963973e0-a98c-4044-b421-71e7348eaeaf` | MCP SQL via `/run-sql` |

`CC-Gateway-Query.ps1` is hardcoded for Prime. For ANY non-Prime workspace, route directly to MCP SQL. This is the primary path, not a fallback.

### Step 4: Execute

**Prime (via PowerShell script):**

```powershell
# Query
powershell -File "scripts/CC-Gateway-Query.ps1" -Action query -ArtifactType <type> -ArtifactId "<uuid>" -Hydrate

# List
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType <type> -Limit <N>

# List with tags
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType <type> -Tags "<tag>" -Limit <N>

# Raw JSON for parsing
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType <type> -Raw
```

Smart defaults:
- `query`: always include `-Hydrate`
- `list`: default `-Limit 20`, no `-Hydrate` unless asked
- Use `-Raw` when CC needs to parse the response

**Non-Prime (via MCP SQL):**

```sql
-- Query single artifact:
SELECT a.*, ext.*
FROM qxb_artifact a
LEFT JOIN qxb_artifact_<type> ext ON ext.artifact_id = a.artifact_id
WHERE a.artifact_id = '<full-uuid>'
  AND a.workspace_id = '<workspace-id>';

-- List:
SELECT a.artifact_id, a.artifact_type, a.title, a.tags,
       a.lifecycle_status, a.execution_status
FROM qxb_artifact a
WHERE a.workspace_id = '<workspace-id>'
  AND a.artifact_type = '<type>'
  AND a.deleted_at IS NULL
ORDER BY a.created_at DESC
LIMIT 20;
```

Execute via `mcp__supabase__execute_sql` directly (no bash).

### Step 5: Present Results

**Query (single):** title, artifact_id, type, tags, status, extension data formatted for readability.

**List (multiple):** "Found N artifacts" + table: ID | Type | Title | Status | Tags. If > 20, mention pagination.

## Common Patterns

| Need | Command |
|------|---------|
| All for-q snapshots | `list -ArtifactType snapshot -Tags "for-q"` |
| Active projects | `list -ArtifactType project` |
| Specific by ID | `query -ArtifactType <type> -ArtifactId "<uuid>" -Hydrate` |
| Recent journals | `list -ArtifactType journal -Limit 10` |
| For-cc queue | `list -ArtifactType snapshot -Tags "for-cc"` |

## Error Handling

| Error | Response |
|-------|----------|
| `ARTIFACT_TYPE_NOT_ALLOWED` | "Type not queryable via Gateway. Use `/run-sql`." |
| `TYPE_MISMATCH` | "Artifact exists but is a different type. Stored type: X" |
| `NOT_FOUND` | "No artifact found with this ID in the specified workspace." |
| PowerShell fails | Check script path, report error |
| Gateway timeout | Retry once, then report |

## NEVER DO

- Never send short UUID prefixes (< 36 chars) to the Gateway
- Never use `CC-Gateway-Query.ps1` for non-Prime workspaces
- Never execute write operations (read-only per CLAUDE.md §2.5)
- Never guess artifact_type — infer from context or ask
