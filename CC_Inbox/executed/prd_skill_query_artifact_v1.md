# PRD: /query-artifact — Smart Gateway Query Wrapper

> **Date:** 2026-03-09
> **Parent:** `CC_Inbox/prd_cc_skills_suite_v1__pre_planning.md`
> **Source Governance:** CLAUDE.md §2.6 (CC Gateway Query Script), `scripts/CC-Gateway-Query.ps1`

---

## Intent

Wrap the `CC-Gateway-Query.ps1` script with smart defaults, input validation, and multi-workspace support. Eliminates:

- **Re-reading §2.6** — CC looks up parameter names and allowed types every time
- **Short UUID mistakes** — CC passes 8-char prefixes that return empty results
- **Wrong artifact types** — CC queries `thorn` or `grass` which return ARTIFACT_TYPE_NOT_ALLOWED
- **Missing workspace context** — CC defaults to Prime even when user is working in Q@W
- **Parameter amnesia** — CC forgets `-Hydrate`, `-Raw`, or `-ArtifactType` requirements

---

## Non-Goals

- Does NOT bypass the Gateway (still uses `CC-Gateway-Query.ps1`)
- Does NOT perform write operations (read-only per CLAUDE.md §2.5)
- Does NOT replace MCP SQL queries (different tool for different purpose)
- Does NOT cache results between invocations

---

## Trigger

User invokes `/query-artifact` or CC needs to look up artifact data via Gateway.

**Arguments (flexible parsing):**
- `/query-artifact <uuid>` — query a specific artifact
- `/query-artifact list projects` — list all projects
- `/query-artifact for-q snapshots` — list snapshots tagged for-q

---

## Prerequisites

1. PowerShell must be available (`powershell -File ...`)
2. `scripts/CC-Gateway-Query.ps1` must exist
3. Gateway must be reachable

---

## Step Sequence

### Step 1: Parse User Intent

Determine the action from the user's request:

| User says | Action | Type | Extra |
|-----------|--------|------|-------|
| "query artifact abc-123..." | `query` | (detect from response) | ArtifactId = full UUID |
| "list projects" | `list` | `project` | |
| "list for-q snapshots" | `list` | `snapshot` | Tags = "for-q" |
| "find artifact titled X" | `list` | (all or specified) | Search by title |
| Just a UUID | `query` | (detect from response) | |

### Step 2: Validate Inputs

**Full UUID check (CRITICAL):**
- UUIDs must be 36 characters (8-4-4-4-12 format)
- If user provides a short prefix (8 chars), STOP and ask:
  > "Gateway requires full UUIDs (36 characters). Do you have the complete artifact_id?"

**Artifact type validation:**
- Allowed types for Gateway query: `project`, `journal`, `restart`, `snapshot`, `instruction_pack`, `branch`, `limb`, `leaf`, `twig`
- NOT allowed (will return error): `thorn`, `grass`, `forest`, `thicket`, `flower`
- If user requests a disallowed type, warn before sending:
  > "`thorn` is not queryable via Gateway. Use MCP SQL query instead (`/run-sql`)."

**Query action requires `-ArtifactType`:**
- If the user provides only a UUID without specifying type, CC must either:
  - Infer from context (if they just mentioned the type)
  - Ask: "What artifact type is this? (project, snapshot, journal, etc.)"

### Step 3: Determine Workspace

**Default:** Prime (`be0d3a48-c764-44f9-90c8-e846d9dbbd0a`)

**Override detection:**
- If user mentions "work", "Q@W", "Resolve" → use Q@W workspace
- If user mentions "BlaggLife" → use BlaggLife workspace
- If user mentions "Akara" → use Akara workspace
- If recent conversation context is clearly about a non-Prime workspace, use that

| Workspace | ID | Execution Path |
|-----------|-----|----------------|
| Prime | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` | `CC-Gateway-Query.ps1` (default) |
| Q@W | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | MCP SQL via `/run-sql` |
| BlaggLife | `b4e7f648-96d5-44a7-80b9-c39cac4efbd1` | MCP SQL via `/run-sql` |
| Akara | `963973e0-a98c-4044-b421-71e7348eaeaf` | MCP SQL via `/run-sql` |

**Routing rule (CRITICAL):** `CC-Gateway-Query.ps1` is hardcoded for Prime (workspace ID + principal). For ANY non-Prime workspace, do NOT attempt to use the script — route directly to MCP SQL using the `/run-sql` pattern. This is not a fallback; it is the primary path for non-Prime queries.

**MCP SQL template for non-Prime queries:**
```sql
-- For query (single artifact):
SELECT a.*, ext.*
FROM qxb_artifact a
LEFT JOIN qxb_artifact_<type> ext ON ext.artifact_id = a.artifact_id
WHERE a.artifact_id = '<full-uuid>'
  AND a.workspace_id = '<workspace-id>';

-- For list:
SELECT a.artifact_id, a.artifact_type, a.title, a.tags, a.lifecycle_status, a.execution_status
FROM qxb_artifact a
WHERE a.workspace_id = '<workspace-id>'
  AND a.artifact_type = '<type>'
  AND a.deleted_at IS NULL
ORDER BY a.created_at DESC
LIMIT 20;
```

### Step 4: Build and Execute Command

Construct the PowerShell command:

```powershell
# Query specific artifact
powershell -File "scripts/CC-Gateway-Query.ps1" -Action query -ArtifactType <type> -ArtifactId "<full-uuid>" -Hydrate

# List with type filter
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType <type> -Limit <N>

# List with tag filter
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType <type> -Tags "<tag1>,<tag2>" -Limit <N>

# Raw JSON for parsing
powershell -File "scripts/CC-Gateway-Query.ps1" -Action list -ArtifactType <type> -Raw
```

**Smart defaults:**
- `query` action: always include `-Hydrate` (extension data is almost always needed)
- `list` action: default `-Limit 20`, no `-Hydrate` unless user asks
- Always use `-Raw` when CC needs to parse the response programmatically

### Step 5: Present Results

**For query (single artifact):**
- Show title, artifact_id, artifact_type, tags, lifecycle/execution status
- Show extension data (payload, entry_text, etc.) formatted for readability
- If payload is large JSON, summarize key fields

**For list (multiple artifacts):**
- Show count: "Found N artifacts"
- Table format: ID | Type | Title | Status | Tags
- If > 20 results, mention pagination: "Showing first 20. Use offset for more."

---

## Common Query Patterns (Quick Reference)

| Need | Command |
|------|---------|
| All for-q snapshots | `-Action list -ArtifactType snapshot -Tags "for-q"` |
| All active projects | `-Action list -ArtifactType project` |
| Specific artifact by ID | `-Action query -ArtifactType <type> -ArtifactId "<uuid>" -Hydrate` |
| Recent journals | `-Action list -ArtifactType journal -Limit 10` |
| For-cc work queue items | `-Action list -ArtifactType snapshot -Tags "for-cc"` (+ other types) |
| Instruction packs | `-Action list -ArtifactType instruction_pack` |
| Twigs for a project | `-Action list -ArtifactType twig -Tags "<project-tag>"` |

---

## Decision Points

| Situation | CC Action |
|-----------|-----------|
| Short UUID provided | STOP — ask for full UUID |
| Disallowed type requested | Warn — offer MCP SQL alternative |
| No artifact type for query | Ask user |
| Non-Prime workspace | Route to MCP SQL directly (not a fallback — primary path) |
| Empty results returned | Report "0 results" — suggest checking UUID/type/workspace |
| Gateway returns error | Show error code + message, suggest troubleshooting |

---

## Error Handling

| Error | Response |
|-------|----------|
| `ARTIFACT_TYPE_NOT_ALLOWED` | "This type isn't queryable via Gateway. Use `/run-sql` for direct SQL." |
| `TYPE_MISMATCH` | "The artifact exists but is a different type than requested. Stored type: X" |
| `NOT_FOUND` | "No artifact found with this ID in the specified workspace." |
| PowerShell execution fails | Check script path, report error, suggest manual execution |
| Gateway timeout | Retry once, then report connectivity issue |

---

## Acceptance Criteria

1. `/query-artifact <uuid>` returns hydrated artifact data (no manual `-Hydrate` needed)
2. Short UUIDs (< 36 chars) are rejected before sending to Gateway
3. Disallowed types (`thorn`, `grass`) produce a warning, not a Gateway error
4. List queries default to 20 results with clean table output
5. Non-Prime workspace requests are handled (even if via MCP fallback)
6. Error responses include the Gateway error code and actionable guidance

---

## Future Enhancements (Out of Scope for v1)

- Add workspace parameter to `CC-Gateway-Query.ps1` (supports all 4 workspaces natively)
- Artifact search by title substring
- Cache recent query results for follow-up questions

---

## CHANGELOG

| Date | Entry |
|------|-------|
| 2026-03-09 | Initial PRD created |
| 2026-03-10 | Manus review: replaced ambiguous non-Prime fallback with explicit MCP routing rule + SQL templates |
