# PRD: /rolling-mem-sync — For-Q Rolling Memory Delta Sync

> **Date:** 2026-03-09
> **Parent:** `CC_Inbox/prd_cc_skills_suite_v1__pre_planning.md`
> **Source Governance:** CLAUDE.md "Rolling Memory Sync Protocol", Session Start Step 4

---

## Intent

Codify the Rolling Memory Sync Protocol into a deterministic skill that checks both workspaces for new `for-q` artifacts and reports deltas. Eliminates:

- **Protocol re-reading** — CC re-reads 30+ lines of CLAUDE.md sync protocol every session start
- **Wrong file paths** — CC confuses Prime vs Q@W rolling memory file locations
- **Missed workspace** — CC syncs Prime but skips Q@W
- **Missed deltas** — CC extracts artifact_ids incorrectly or compares against wrong file
- **Shell quoting on SQL** — Uses MCP-first pattern

---

## Non-Goals

- Does NOT auto-regenerate rolling memory files (offers to, waits for approval)
- Does NOT perform compaction (separate protocol, separate trigger)
- Does NOT process for-cc artifacts (separate sweep, CLAUDE.md step 5)
- Does NOT run CC Memory Harvest (separate step 6, depends on delta from this skill)
- Does NOT modify any artifacts in Supabase

---

## Trigger

- **Automatic:** CC runs this as part of session start protocol (step 4)
- **Manual:** User invokes `/rolling-mem-sync` or says "regenerate for-q rolling file"

**Arguments (optional):** Workspace name (`prime`, `qw`, or `all`). Default: `all`.

---

## Prerequisites

1. MCP tool `mcp__supabase__execute_sql` must be available
2. Rolling memory files must exist in their expected locations (or skill reports they're missing)

---

## Step Sequence

### Step 1: Locate Latest Rolling Memory Files

For each workspace, find the most recent rolling memory file by date in the filename:

**Prime:**
```
Glob pattern: Qwrk_RollingMem/Qwrk_Rolling_Memory__for-q__*.md
Example match: Qwrk_Rolling_Memory__for-q__2026-03-09.md
```

**Q@W:**
```
Glob pattern: Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/RollingMem/Qwrk_Rolling_Memory__for-q-work__*.md
Example match: Qwrk_Rolling_Memory__for-q-work__2026-03-09.md
```

Select the file with the most recent date suffix. If no file exists for a workspace, report:
> "No rolling memory file found for [workspace]. Skipping delta check."

### Step 2: Extract Artifact IDs from Rolling Files

Read each rolling memory file and extract all `artifact_id` values from **Section B** entries.

**Extraction pattern:** Look for UUID patterns (8-4-4-4-12 format) in Section B artifact entries. These are the artifacts already known to the rolling memory.

Collect into a set: `known_artifact_ids` (per workspace).

### Step 3: Query Supabase for Current For-Q Artifacts

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

Run both queries in parallel if both workspaces are in scope.

Collect results into: `live_artifact_ids` (per workspace).

### Step 4: Compute Delta

For each workspace:
```
delta = live_artifact_ids - known_artifact_ids
```

These are artifacts tagged `for-q` in Supabase that are NOT yet in the rolling memory file.

### Step 5: Report Results

**If delta exists (new artifacts found):**

```
📊 Rolling Memory Sync — [Workspace Name]

Rolling file: [filename] ([date])
Known artifacts: N
Live for-q artifacts: M
New artifacts found: K

New artifact IDs:
  - <artifact_id_1>
  - <artifact_id_2>
  ...

Would you like me to regenerate the rolling memory file?
```

Then WAIT for user confirmation before regenerating.

**If no delta (successfully checked, nothing new):**
- During session start: proceed silently (no output)
- During manual invocation: report "Rolling memory is current. No new for-q artifacts."

**If check could not complete (MUST NOT be silent):**
- Rolling file missing: `"⚠️ No rolling memory file found for [workspace]. Cannot verify delta."`
- Rolling file unparsable (0 artifact_ids extracted): `"⚠️ Could not parse rolling file for [workspace]. File may be malformed."`
- MCP query failed: `"⚠️ Could not query for-q artifacts for [workspace]. MCP returned error."`
- In all three cases: offer to regenerate from scratch or skip

**Key distinction:** "No delta" means the check succeeded and found nothing new. Silence is only appropriate when the check succeeded. Any failure to check MUST produce a visible warning — even at session start — so persistent problems are not masked as "no news."

**If rolling file missing:**
- Report which workspace has no file
- Offer to generate one from scratch

### Step 6: Regeneration (If Approved)

If the user approves regeneration:

1. Query all for-q artifacts with full hydration (title, tags, extension data)
2. Generate new rolling memory file following the existing format:
   - Section A: Protected Core entries
   - Section A2: Active Operational Contexts (if any)
   - Section B: All for-q artifacts (sorted by created_at)
   - Section C: Compacted/archived references (if any)
3. Save with today's date suffix:
   - **Prime:** `Qwrk_RollingMem/Qwrk_Rolling_Memory__for-q__YYYY-MM-DD.md`
   - **Q@W:** `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/RollingMem/Qwrk_Rolling_Memory__for-q-work__YYYY-MM-DD.md`
4. Previous dated files are retained (do NOT delete)
5. Confirm: "Rolling memory regenerated: [filename] (N entries)"

---

## Decision Points

| Situation | CC Action |
|-----------|-----------|
| No rolling file found | Report, offer to generate from scratch |
| Delta = 0 (check succeeded, nothing new) | Silent at session start; explicit "current" on manual invoke |
| Delta > 0 (new artifacts found) | Report delta, offer regeneration, WAIT for approval |
| User approves regeneration | Generate new file with today's date |
| MCP unavailable | Log warning, continue session (non-blocking) |
| User specifies single workspace | Run for that workspace only |
| Section B parsing fails | Warn (NEVER silent), offer full regeneration as alternative |
| Check could not complete (any reason) | Emit warning (NEVER silent) — distinguish from "no delta" |

---

## Output Format

**At session start (automatic):**
- Silent if no delta
- Brief delta report if new artifacts found
- No regeneration without user approval

**On manual invocation:**
- Always report status (even if current)
- Delta details if any
- Regeneration offer if delta exists

---

## Error Handling

| Error | Response |
|-------|----------|
| MCP `execute_sql` fails | Log warning, continue session. Rolling mem sync is non-blocking. |
| Rolling file path not found | Report which workspace — may indicate directory structure change |
| Section B parsing returns 0 IDs | Warn — file may be malformed. Offer full regeneration. |
| Supabase returns 0 for-q artifacts | Unusual but valid. Report "0 for-q artifacts in [workspace]." |
| File write fails (OneDrive bug) | Use bash `cat >` with quoted paths as fallback |

---

## Acceptance Criteria

1. `/rolling-mem-sync` checks both workspaces and reports deltas
2. Correct rolling file is identified per workspace (latest by date)
3. Delta computation is accurate (new = live minus known)
4. No regeneration happens without explicit user approval
5. Session start runs non-blocking (MCP failure doesn't halt session)
6. SQL is executed via MCP (not bash/heredoc)
7. Previous rolling memory files are never deleted

---

## Integration with Session Start Protocol

This skill implements **Step 4** of the session start protocol (CLAUDE.md "Required Behavior on Session Trigger"):

```
Step 1: Read OPEN_THREADS.md
Step 2: Read LATEST_END_SESSION.md
Step 3: Present handoff summary, ask for session intent
Step 4: → /rolling-mem-sync (this skill)
Step 5: → for-cc work queue sweep
Step 6: → CC Memory Harvest (depends on delta from step 4)
```

The delta from this skill feeds into Step 6 (CC Memory Harvest). If no delta, Step 6 is skipped silently.

---

## CHANGELOG

| Date | Entry |
|------|-------|
| 2026-03-09 | Initial PRD created |
| 2026-03-10 | Manus review: distinguish "checked, no delta" (silent OK) from "couldn't check" (must warn). Prevents persistent failures from masking as silence. |
