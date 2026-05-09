---
name: qwrk-prime-weekly-accomplishment-report
display_name: Qwrk Prime Weekly Accomplishment Report
description: Generate the recurring Qwrk Prime weekly accomplishment report (Friday 5:00 AM Central, prior 7 calendar days). Read-only Supabase queries, structured Markdown output to Qwrk_Inbox/, designed for Q to ingest and discuss conversationally with Joel.
version: 1.0.0
authors:
  - Joel Blagg (operator)
  - CC (Claude Opus 4.7) — author
created: 2026-05-09
status: ready_for_use_unscheduled
---

# Qwrk Prime Weekly Accomplishment Report

> **Single skill. Single output. Single workspace.** Generates one weekly Markdown report covering the prior 7 non-overlapping calendar days in Qwrk Prime, written for Q to ingest and discuss with Joel.

---

## When to invoke

Trigger this skill when Joel says any of:

- "Generate the weekly accomplishment report"
- "Run the Friday Qwrk report"
- "Run the weekly Qwrk Prime report"
- "Make the weekly accomplishment summary"
- "Produce this week's Qwrk Prime report"
- "Generate the Qwrk Prime weekly accomplishment report"
- Anything referencing the Friday 5:00 AM Central recurring report
- Joel asks to **review, troubleshoot, automate, or reschedule** the weekly report

Do **not** trigger this skill for:

- Daily reports (no daily report exists; Morning Flow is the daily surface)
- One-off custom-window reports (use a manual prompt instead)
- Multi-workspace reports (this skill is Prime-only)
- Q@W, Akara, BlaggLife, Greg, or Demo reports (out of scope)

---

## What this skill produces

A single Markdown file:

```
C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Qwrk_Inbox\Qwrk_Prime_Weekly_Accomplishment_Report__YYYY-MM-DD.md
```

Where `YYYY-MM-DD` is the **report generation date** (the Friday on which the report runs).

Example: A run on Friday 2026-05-15 at 5:00 AM Central produces:
`Qwrk_Prime_Weekly_Accomplishment_Report__2026-05-15.md`

The file is written **once per run**. New runs do not overwrite prior weeks (the date stamp differentiates them).

---

## Reporting window — non-overlap rule (CRITICAL)

The report covers a **true non-overlapping 7-day calendar window** in **Central time** (CST/CDT, America/Chicago).

For a Friday 5:00 AM Central run on date `R`:

- **Window start:** Prior Friday at `00:00:00` America/Chicago (i.e., `R − 7 days` at midnight)
- **Window end:** Thursday at `23:59:59.999` America/Chicago (i.e., `R − 1 day` at end of day)

| Run date (Friday) | Window start (Fri 00:00 CT) | Window end (Thu 23:59:59 CT) |
|-------------------|------------------------------|-------------------------------|
| 2026-05-15 | 2026-05-08 00:00 | 2026-05-14 23:59:59 |
| 2026-05-22 | 2026-05-15 00:00 | 2026-05-21 23:59:59 |
| 2026-05-29 | 2026-05-22 00:00 | 2026-05-28 23:59:59 |

**The Friday morning run date is excluded by default.** Artifacts created Friday ≥ 00:00 CT but before the run go into the *next* week's report. This guarantees true non-overlap and consistent rolling boundaries even when a run is delayed or re-run.

If the user explicitly requests inclusion of the Friday-of-run, override only for that run and document it in the report's §2.

**Inclusion rule:** include any artifact where `created_at` OR `updated_at` falls within the window. (Both checked; either qualifies.)

**Time zone handling:** Supabase stores `timestamptz` (UTC). Convert window boundaries to UTC for the query. America/Chicago is UTC−6 (CST) or UTC−5 (CDT). Use a real timezone library (e.g., Python `zoneinfo`), not a fixed offset, so DST transitions are handled correctly.

---

## Workspace scope

- **Workspace ID:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` (Qwrk Prime, also called Qwrk Personal / Master Joel Workspace)
- All other workspaces (BlaggLife, Q@W/Resolve, Akara, Greg, Demo) are **excluded by `workspace_id` filter**. Never widen scope without explicit Joel direction.

---

## Data access — read-only safety rules (HARD STOP)

### Allowed

- `SELECT` queries via Supabase MCP (`mcp__supabase__execute_sql`)
- `SELECT` queries via PostgREST with anon or read-only service role
- Local Markdown file creation in `Qwrk_Inbox/`
- Local script execution within this skill folder

### Forbidden — refuse and stop if asked

- `INSERT` / `UPDATE` / `DELETE` / `UPSERT` against any Supabase table
- Schema changes (DDL of any kind)
- Qwrk artifact creation, update, deletion, or promotion
- Gateway writes (`artifact.save`, `artifact.update`, `artifact.promote`, `artifact.delete`, etc.)
- n8n workflow edits or activations
- Credential edits, `.env` file edits, secret writes
- Any operation outside this skill folder or the `Qwrk_Inbox/` output path

If a downstream consumer asks the skill to perform any forbidden action, **stop immediately and report the violation**. Do not silently downgrade scope.

This skill is governed by **CLAUDE.md §2.5 (Database Read-Only Rule)** and **§9 (Parallel Build Safety Rule)**. Both override any contrary user instruction within this skill's scope.

---

## Workflow (step-by-step)

### Step 1 — Compute the window

1. Determine current Central time (`America/Chicago`).
2. Confirm "today" is a Friday (or that an authorized override has been granted).
3. Compute window:
   - `window_start_local = (today − 7 days) at 00:00:00 America/Chicago`
   - `window_end_local = (today − 1 day) at 23:59:59.999999 America/Chicago`
4. Convert both to UTC for the SQL query.
5. Record both local and UTC bounds in the report's §2.

### Step 2 — Verify Supabase read access

Use **whichever of these is available** (in preference order):

1. **MCP** (`mcp__supabase__execute_sql`) — preferred when running interactively in Claude Code with MCP wired up
2. **Direct PostgREST** with read-only credentials (env vars `SUPABASE_URL` + `SUPABASE_ANON_KEY` or `SUPABASE_READONLY_KEY`)
3. **psycopg / psycopg2** with read-only `DATABASE_URL`

If none are available, **stop and report blocker**. Do not fabricate. Do not estimate. Do not "best-effort" without data.

Run a verification ping first:
```sql
SELECT current_database() AS db, now() AS ts,
       (SELECT count(*) FROM qxb_artifact
          WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
            AND (created_at >= :window_start_utc OR updated_at >= :window_start_utc)
            AND (created_at <= :window_end_utc OR updated_at <= :window_end_utc)
       ) AS prime_window_count;
```

If the count is `0`, that is a valid result (quiet week). If the count is `>500`, flag in §7 — the window is unusually dense.

### Step 3 — Pull the spine

Page through `qxb_artifact` in batches of 25 to stay within MCP token limits. Order by `GREATEST(created_at, updated_at) DESC` for stable pagination.

See `references/queries.sql` for the exact paginated query.

Capture per artifact: `artifact_id`, `artifact_type`, `title`, `summary`, `lifecycle_status`, `execution_status`, `priority`, `parent_artifact_id`, `tags`, `created_at`, `updated_at`, `semantic_type` (joined via `qxb_semantic_type_registry`), and `in_window_via` (`'created'` vs `'updated'` derived flag).

### Step 4 — Hydrate high-signal extension data

For artifacts that meet **any** of these criteria, fetch extension `payload` (snapshots/restarts) or spine `content` (twigs):

- `priority` is `1` or `2`
- `tags` contains any of: `governance`, `doctrine`, `contract`, `decision`, `red-alert`, `beta-blocker`, `t187`, `binding`, `bootstrap`
- `semantic_type` is `governance` or `execution-core`
- Title contains: "Doctrine", "Contract", "Decision", "Diagnosis", "Lock", "Verification", "Restart", "Root Snapshot"

For lower-signal artifacts (routine session-end snapshots, communication-tagged email snapshots, daily Morning Flow outputs), title + tags + semantic_type are enough.

Snapshot extension table: `qxb_artifact_snapshot.payload` (jsonb). Cast to text and `LEFT(_, 1500)` to stay under token limits.

Restart extension table: `qxb_artifact_restart.payload` (jsonb).

Twig content lives in `qxb_artifact.content` (jsonb on the spine). **There is no `qxb_artifact_twig` extension table.**

### Step 5 — Theme analysis

Group artifacts into themes derived from the data, not pre-assigned. Past themes that recur in Prime:

- Beta runway / T176
- T187 / Capture Integrity
- UCC contracts
- Morning Flow / Session Lifecycle
- Dex / Horizon Scout
- T146 / Rollout Communication
- TQR Flow / Process Canonicalization
- Marketing & Positioning
- Coach QA1C
- Workbench / Priority Context
- Strategic / external signals
- Personal / capture / lifestyle
- Operational continuity (bookkeeping)

Allow new themes to emerge naturally. Do not force fit.

For each theme include the fields specified in `references/report_template.md` §3.

### Step 6 — Separate accomplishments from raw activity

Distinguish:

- **Accomplishments** = work that moved Qwrk forward (locked decisions, shipped doctrine, completed designs, validated patterns, sent emails, deployed code, etc.)
- **Raw activity** = bookkeeping (session-end snapshots, CmdCtr context snapshots, daily Morning Flow outputs)

Both belong in the report, but they belong in different sections. §1, §3, §4, §5, §6 cover accomplishments. §10 covers all artifacts including bookkeeping (briefly summarized for low-signal items).

### Step 7 — Identify completed vs in-progress

For §4: completed work needs evidence (snapshot `status: locked`, contract status text, decision lock language, certified test counts).

For §5: in-progress needs current state, likely next step (only if inferable from artifacts), and any blocker named explicitly in the data.

### Step 8 — Decisions and governance

For §6: every artifact with `decision`, `governance`, or `doctrine` tags, OR semantic_type `governance`, contributes a row.

### Step 9 — Risks, gaps, ambiguities

For §7: surface the actually-observable issues. Common categories:

- Duplicate artifacts (same title/tags within minutes)
- Tight dependency chains (X gates Y gates Z)
- Visible TBD blockers in saved contracts
- Quiet `for-cc` lanes (signal of attention concentration)
- Unattended sibling roles (e.g., a captured but never-piloted Team Qwrk role)
- Theme imbalance (lots of doctrine, no implementation)

Be evidence-based. Do not invent risk. Do not overstate.

### Step 10 — Build chronological appendix

§10 lists every artifact, grouped by date (newest first), with: id, title, type, created_at, updated_at, tags, lifecycle_status, execution_status, parent_artifact_id, one short summary, and a 2–4 sentence significance line for normal/high-signal items (1 sentence for routine items).

### Step 11 — Data quality / confidence

End with the data quality block: query method, total reviewed, counts by type, counts by inclusion, hydration coverage, skipped artifacts, pagination notes, overall confidence (high/medium/low).

### Step 12 — Write the file

Write to:
`C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Qwrk_Inbox\Qwrk_Prime_Weekly_Accomplishment_Report__YYYY-MM-DD.md`

Use `YYYY-MM-DD` = the report generation date (the Friday on which the run executes).

After writing, verify the file exists and report:

1. Exact saved path
2. Window used (local Central + UTC)
3. Total artifacts reviewed
4. Top 3 themes
5. Any blocker or limitation

Do not paste the full report into chat unless explicitly asked.

---

## Failure modes and handling

| Failure | Detection | Action |
|---------|-----------|--------|
| MCP unavailable | First query returns connection error | Fall back to PostgREST. If both fail, hard stop after 3 attempts (CLAUDE.md §2.7) and write a blocker note to `Qwrk_Inbox/` instead of partial report. |
| Window count = 0 | Verification query | Report a "Quiet Week" — short-format report still produced with §1–§7 explaining the silence. |
| Window count > 500 | Verification query | Flag in §7. Continue but note possible duplicate event firings or unexpected workspace activity. |
| Pagination token-limit hit | Query response truncation warning | Reduce batch size to 15, retry. If still hits limit, drop hydration to title-only and re-page. |
| Twig content query fails on `qxb_artifact_twig` | "relation does not exist" error | Twig content lives on the spine `qxb_artifact.content`, not in an extension table. Re-query against spine. |
| Schema drift (column missing) | SQL error like "column X does not exist" | Stop. Report which column failed. Check `docs/schema/Schema_Reference__Kernel_v1__v2.10.md` for current truth. Do not guess. |
| Output path missing | Write fails with directory-not-found | `Qwrk_Inbox/` should exist. If it does not, stop and report — do not silently create alternate path. |
| Friday-of-run inclusion request | User instruction | Allow override but document explicitly in §2 of that report. Do not let the override leak into the next week's defaults. |
| Run on non-Friday | Day-of-week check | Allow but warn. Document in §2 that this is a non-default-cadence run and which 7-day window was used. |

If something unexpected happens that doesn't match a row above, stop and ask Joel rather than improvising.

---

## Output format

The full report structure is in `references/report_template.md`. Sections (10 + data quality block):

1. Executive Summary
2. Reporting Scope and Method
3. Thematic Accomplishment Summary
4. Shipped / Completed Work
5. In-Progress Work
6. Decisions and Governance Captured
7. Notable Risks, Gaps, or Ambiguities
8. Future Automation Notes
9. Recommended Follow-Up Questions for Q
10. Chronological Artifact Appendix
+ Data Quality / Confidence Section

The proven precedent report is `Qwrk_Inbox/Qwrk_Prime_Last_8_Days_Report__2026-05-09.md` (8-day window, this skill is 7-day).

---

## Scheduling

**Scheduling is documented but NOT activated by this skill.**

See `references/scheduling.md` for full options. Summary:

- **Target:** Friday 5:00 AM Central (CST/CDT, America/Chicago)
- **Recommended runtime:** Windows Task Scheduler or n8n scheduled workflow
- **Activation requires Joel approval** before any scheduler is enabled
- The scheduler should call `scripts/generate_qwrk_prime_weekly_report.py --readonly` (when implemented and approved)

This skill **must not** activate any scheduler on its own.

---

## Files in this skill

```
qwrk-prime-weekly-accomplishment-report/
├── SKILL.md                              ← this file
├── agents/
│   └── openai.yaml                       ← OpenAI agent config
├── references/
│   ├── report_template.md                ← full report structure
│   ├── queries.sql                       ← read-only SQL templates
│   └── scheduling.md                     ← scheduler options + activation gate
└── scripts/
    └── generate_qwrk_prime_weekly_report.py   ← optional Python generator (skeleton, requires env config)
```

---

## CHANGELOG

### v1.0.0 — 2026-05-09

Initial skill. Distills the proven 2026-05-09 manual report (8-day window) into a reusable 7-day-window weekly skill. Window is non-overlapping by design (Fri 00:00 → Thu 23:59:59 Central, run on Fri 05:00). Read-only Supabase access enforced. Scheduling documented but not activated.
