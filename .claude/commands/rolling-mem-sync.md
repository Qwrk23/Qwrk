Check both workspaces for new for-q artifacts and report deltas against rolling memory files.

Source: CLAUDE.md "Rolling Memory Sync Protocol" — last synced 2026-03-10

## Instructions

This skill implements session start step 4. It compares live for-q artifacts in Supabase against the local rolling memory files and reports what's new. Non-blocking — failures warn but never halt the session.

### Step 1: Locate Latest Rolling Memory Files

Find the most recent file by date suffix for each workspace:

**Prime:**
```
Glob: Qwrk_RollingMem/Qwrk_Rolling_Memory__for-q__*.md
```

**Q@W:**
```
Glob: Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/RollingMem/Qwrk_Rolling_Memory__for-q-work__*.md
```

Select the file with the most recent date. If no file exists, emit warning (see Step 5).

### Step 2: Extract Known Artifact IDs

Read each rolling memory file and extract all UUID-format artifact_ids from **Section B** entries.

Collect into: `known_artifact_ids` (per workspace).

If 0 IDs extracted, this is a parse failure — do NOT treat as "no known artifacts." See Step 5 warning rules.

### Step 3: Query Supabase for Live For-Q Artifacts

Use `mcp__supabase__execute_sql` directly (MCP-first — no bash).

**Prime:**
```sql
SELECT artifact_id
FROM qxb_artifact
WHERE tags ? 'for-q'
  AND workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL;
```

**Q@W:**
```sql
SELECT artifact_id
FROM qxb_artifact
WHERE tags ? 'for-q'
  AND workspace_id = '635bb8d7-7b93-4bea-8ca6-ee2c924c9557'
  AND deleted_at IS NULL;
```

Run both in parallel if both workspaces are in scope.

### Step 4: Compute Delta

```
delta = live_artifact_ids - known_artifact_ids
```

New artifacts = those in Supabase but NOT in the rolling memory file.

### Step 5: Report Results

**Delta exists (new artifacts found):**
```
Rolling Memory Sync — [Workspace]

Rolling file: [filename] ([date])
Known: N | Live: M | New: K

New artifact IDs:
  - <id_1>
  - <id_2>

Would you like me to regenerate the rolling memory file?
```
WAIT for user confirmation before regenerating.

**No delta (check succeeded, nothing new):**
- Session start: proceed silently (no output)
- Manual invocation: "Rolling memory is current. No new for-q artifacts."

**Check could not complete (MUST NOT be silent):**
- File missing: "Could not find rolling memory file for [workspace]. Cannot verify delta."
- File unparsable (0 IDs extracted): "Could not parse rolling file for [workspace]. File may be malformed."
- MCP query failed: "Could not query for-q artifacts for [workspace]. MCP returned error."
- In all three cases: offer to regenerate from scratch or skip.

**Key rule:** Silence ONLY means "checked and found nothing new." Any failure to check MUST produce a visible warning, even at session start, so persistent problems are never masked.

### Step 6: Regeneration (If Approved)

1. Query all for-q artifacts with full hydration
2. Generate rolling memory file following existing format:
   - Section A: Protected Core
   - Section A2: Active Operational Contexts
   - Section B: All for-q artifacts (by created_at)
   - Section C: Compacted/archived references
3. Save with today's date:
   - **Prime:** `Qwrk_RollingMem/Qwrk_Rolling_Memory__for-q__YYYY-MM-DD.md`
   - **Q@W:** `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/RollingMem/Qwrk_Rolling_Memory__for-q-work__YYYY-MM-DD.md`
4. Retain previous files (do NOT delete)
5. Confirm: "Rolling memory regenerated: [filename] (N entries)"

## Decision Points

| Situation | Action |
|-----------|--------|
| No rolling file found | Warn (NEVER silent), offer generation from scratch |
| Delta = 0 (check succeeded) | Silent at session start; explicit on manual invoke |
| Delta > 0 | Report, offer regeneration, WAIT for approval |
| MCP unavailable | Warn, continue session (non-blocking) |
| Section B parse returns 0 IDs | Warn (NEVER silent), offer full regeneration |
| User specifies single workspace | Run for that workspace only |

## Integration

Session start step 4. Delta feeds into step 6 (CC Memory Harvest). No delta = step 6 skipped.

## NEVER DO

- Never be silent when a check fails — silence means "checked, nothing new"
- Never auto-regenerate without user approval
- Never execute SQL through bash/heredoc — use MCP directly
- Never delete previous rolling memory files
