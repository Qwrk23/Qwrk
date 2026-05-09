# Report Template — Qwrk Prime Weekly Accomplishment Report

> Reference structure for the weekly Markdown report. The skill renderer should follow this layout exactly unless there is a strong, documented reason to add a clearly labeled supplemental section.

The proven precedent (8-day window) lives at:
`Qwrk_Inbox/Qwrk_Prime_Last_8_Days_Report__2026-05-09.md`

The weekly variant adapts that structure for a true 7-day non-overlapping window.

---

## Front matter (top of report)

```markdown
# Qwrk Prime — Weekly Accomplishment Report

**Generated:** YYYY-MM-DD (Friday)
**Author:** {agent identifier} (read-only review)
**Workspace:** Qwrk Prime (`be0d3a48-c764-44f9-90c8-e846d9dbbd0a`)
**Window:** {window_start_local} → {window_end_local} (America/Chicago, 7 calendar days, non-overlapping)
**Window UTC:** {window_start_utc} → {window_end_utc}
**Inclusion:** `created_at` OR `updated_at` within window
**Artifacts reviewed:** {N} (created in window: {C}; spine-updated only: {U})
```

---

## Section 1 — Executive Summary

Concise overview, 200–500 words. Subsections:

- **Top accomplishments** (priority-weighted, 5–10 numbered items, each one line + ID reference)
- **Primary themes** (bullet list, 4–7 items)
- **What materially changed in Qwrk Prime** (bullet list, 3–5 items)
- **Complete vs in-progress** (compact paragraph or short table)
- **Notable risk / momentum** (bullet list, 2–4 items)

Goal: Joel can read this section alone and have the right shape of the week.

---

## Section 2 — Reporting Scope and Method

Two-column table:

| Item | Value |
|------|-------|
| Workspace reviewed | Qwrk Prime only |
| Window start | (local + UTC) |
| Window end | (local + UTC) |
| Inclusion rule | created_at OR updated_at |
| Query method | MCP / PostgREST / psycopg / fallback |
| Pagination | (e.g., "4 spine pages × 25 rows; full set retrieved") |
| Hydration | (which artifacts received extension reads) |
| Other workspaces | Excluded by workspace_id filter |
| Artifact types observed | (counts by type) |
| Friday-of-run inclusion | excluded (default) OR included (override — explain) |
| Limitations | (e.g., snapshot summary nulls, token-limit re-pagination) |
| Confidence | high / medium / low + rationale |

Plus a **Counts by type and inclusion** table:

| Type | Total | Created in window | Updated only |
|------|------:|------------------:|-------------:|
| snapshot | | | |
| twig | | | |
| project | | | |
| branch | | | |
| restart | | | |
| journal | | | |
| **Total** | | | |

---

## Section 3 — Thematic Accomplishment Summary

Group artifacts into themes derived from the data. Per theme:

```markdown
### Theme {Letter} — {Theme Name}

**Summary.** 2–4 sentences describing what happened.

**Why it mattered.** 1–2 sentences on the operational/strategic significance.

**Status.** Complete / In progress / Blocked / Unclear (one line).

**Key artifacts.**
- `{artifact_id}` — {title} ({artifact_type}, {created_at_short}, tags: `tag1`, `tag2`, parent {short_parent_id}, semantic {semantic_type}, priority {n}, **{status notes}**)

**Significance.** 2–4 sentences synthesizing what the artifacts collectively reveal. Cite payload language verbatim only when it is decision-locking or doctrine-defining.
```

Common themes (do not force):
- Beta runway / T176
- T187 / Capture Integrity
- UCC / User Context Core
- Morning Flow / Session Lifecycle
- Dex / Horizon Scout
- T146 / Rollout-Completion Communication
- TQR Flow / Process Canonicalization
- Marketing & Positioning
- Coach QA1C
- Workbench / Priority Context
- Strategic / external signals
- Personal / capture / lifestyle
- Operational continuity (bookkeeping)

---

## Section 4 — Shipped / Completed Work

Table with confidence:

| Item | Evidence | Confidence |
|------|----------|-----------|
| {accomplishment} | snapshot `{id}`, payload `status: locked` | High |

Confidence levels:
- **High** — payload status text explicit, lineage cross-validated
- **Medium** — title + tags + summary support but payload not exhaustively read
- **Low** — title only, no extension confirmation

---

## Section 5 — In-Progress Work

Table:

| Workstream | Current state | Relevant artifacts | Likely next step | Blockers / open questions |

"Likely next step" only when the artifacts directly support it. Otherwise leave blank rather than guessing.

---

## Section 6 — Decisions and Governance Captured

Table:

| Decision / Rule | Artifact | Why it matters | Status |

Status: Locked / Candidate / Under review / Adopted / Trial.

---

## Section 7 — Notable Risks, Gaps, or Ambiguities

Numbered list. Each item:
- One sentence describing the issue
- One sentence describing the evidence
- One sentence on what to consider (no over-prescription)

Common categories:
- Duplicate artifacts
- Tight dependency chains
- Visible TBD blockers in saved contracts
- Quiet `for-cc` lanes (attention concentration signal)
- Unattended sibling roles
- Theme imbalance (lots of doctrine, no implementation)
- Schema drift evidence
- Outdated deprecation markers
- Pagination/query gaps

Be precise and evidence-based. Do not overstate.

---

## Section 8 — Future Automation Notes

Brief — 1 paragraph plus a small bullet list. Cover:

- Scheduling target: Fridays at 5:00 AM Central
- Non-overlap window rule (Fri 00:00 → Thu 23:59:59 local)
- Likely runtime options: Windows Task Scheduler / n8n / cron / ChatGPT scheduled task
- Risks (machine sleep, OneDrive bridge, time-zone drift)
- Open questions for the activation session

Do not create a Qwrk twig from inside the report. Include only enough text that Q can later help Joel create a twig.

---

## Section 9 — Recommended Follow-Up Questions for Q

3–5 questions. Each should:
- Surface meaning, not just summary
- Stress-test the week's assumptions
- Probe load-bearing decisions
- Be answerable from the report's data

---

## Section 10 — Chronological Artifact Appendix

Group by date, newest first. Each artifact:

```markdown
- `{artifact_id}` — {title} ({artifact_type}, {timestamp}, tags: `tag1`, `tag2`, semantic {semantic}, priority {n}{, parent {short_parent_id}}{, lifecycle {status}}{, execution {status}}) — {one short summary}{ + 2–4 sentence significance for normal/high-signal items}
```

Convention:
- **Bold** id for high-signal artifacts analyzed in §3
- _italic_ id for routine / operational continuity artifacts
- Plain id for normal artifacts

Per-day count visible in the date heading: `### YYYY-MM-DD (N artifacts)`

---

## Data Quality / Confidence Section

Final block:

| Item | Detail |
|------|--------|
| Query method | MCP / PostgREST / psycopg / mixed |
| Total artifacts reviewed | N |
| Counts by type | snapshot X / twig Y / ... |
| Counts by inclusion | created in window: X / spine-updated only: Y |
| Pagination | (e.g., "4 spine pages × 25") |
| Hydration coverage | High-signal artifacts hydrated: K. Metadata only: M. |
| Skipped artifacts | (or "None") |
| Query limitations | (token limits, retries, etc.) |
| No write operations | Confirmed |
| Workspace scope | Strictly Qwrk Prime |
| Overall confidence | high / medium / low + brief rationale |

---

## Tone and style

- Senior technical program manager voice
- Evidence-based, no hand-waving
- Concise where possible, complete where needed
- Direct artifact references (always include the id)
- No marketing fluff
- No emoji unless Joel adds them later
- Active voice; past tense for accomplishments; present for status

---

## End of report marker

```markdown
*End of report.*
```
