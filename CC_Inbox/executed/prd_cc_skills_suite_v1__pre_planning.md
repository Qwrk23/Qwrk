# CC Skills Suite — Pre-Planning Document

> **Purpose:** Index and rationale for 5 new CC skills. Each skill codifies an existing CLAUDE.md protocol into a deterministic, error-proof slash command.
>
> **Date:** 2026-03-09
> **Predecessor:** `/run-sql` skill (built and deployed same session — proved the pattern)

---

## Why Skills?

CC repeatedly hits the same friction points:

1. **Re-reading governance** — Multi-step protocols in CLAUDE.md require CC to re-read 20-50 lines of governance before executing. This wastes context window and introduces drift risk when CC paraphrases instead of following exactly.
2. **Shell escaping** — SQL, PowerShell, and JSON payloads break when passed through bash. `/run-sql` proved that codifying "use MCP directly" eliminates the entire error class.
3. **Multi-workspace complexity** — Prime and Q@W have different workspace IDs, file paths, and Gateway principals. CC looks these up from MEMORY.md every time. Skills embed the lookup table.
4. **Step amnesia** — Pattern C archiving has 4+ steps. CC forgets one (usually the changelog or the version suffix). A skill makes the sequence deterministic.

**Design principle:** Skills codify existing governance. They do NOT introduce new rules. If a skill contradicts CLAUDE.md, the skill is wrong.

---

## Skills Index

| # | Skill | Error Class Eliminated | Source Governance | PRD File | Status |
|---|-------|----------------------|-------------------|----------|--------|
| 1 | `/archive-file` | Forgotten archive steps, wrong naming, missing changelogs | CLAUDE.md §3, §4, §5 | `prd_skill_archive_file_v1.md` | ✅ WRITTEN |
| 2 | `/registry-refresh` | SQL lookup, path memorization, workspace ID lookup | CLAUDE.md "Artifact Registry Discipline" | `prd_skill_registry_refresh_v1.md` | ✅ WRITTEN |
| 3 | `/query-artifact` | Wrong parameters, short UUIDs, re-reading §2.6 | CLAUDE.md §2.6, CC-Gateway-Query.ps1 | `prd_skill_query_artifact_v1.md` | ✅ WRITTEN |
| 4 | `/cmdctr-briefing` | Function name lookup, workspace ID memorization | MEMORY.md session management | `prd_skill_cmdctr_briefing_v1.md` | ✅ WRITTEN |
| 5 | `/rolling-mem-sync` | Protocol re-reading, wrong file paths, missed deltas | CLAUDE.md "Rolling Memory Sync Protocol" | `prd_skill_rolling_mem_sync_v1.md` | ✅ WRITTEN |

---

## Build Order & Dependencies

```
1. /archive-file        — standalone, no dependencies
2. /registry-refresh    — depends on /run-sql pattern (MCP-first)
3. /query-artifact      — depends on Gateway query script knowledge
4. /cmdctr-briefing     — depends on /run-sql pattern (MCP-first)
5. /rolling-mem-sync    — depends on /run-sql + /query-artifact patterns
```

Rationale: archive-file is the most complex and highest-frequency. registry-refresh and query-artifact are clean specifications. cmdctr-briefing is smallest. rolling-mem-sync benefits from all prior patterns.

---

## Shared Conventions (All 5 Skills)

### Skill File Structure
- First line: one-sentence description of what the skill does
- Plain markdown, no YAML/frontmatter
- Numbered step sequences (deterministic execution order)
- Decision points clearly marked (ask user vs. proceed)
- "NEVER DO" section for known failure patterns
- Quick reference table for scanning

### Multi-Workspace Constants
| Workspace | ID | Gateway Principal | Rolling Mem Path |
|-----------|-----|-------------------|------------------|
| **Prime** | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` | `qwrk-gateway` | `Qwrk_RollingMem/` |
| **Q@W** | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | `qwrk-gw-work` | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/RollingMem/` |

### MCP-First Rule (from /run-sql)
All skills that touch Supabase MUST use `mcp__supabase__execute_sql` directly. No bash-wrapped SQL. No heredoc. No inline PowerShell with SQL strings.
### Governance Sync Rule (from Manus review)

Each skill file MUST include a sync annotation on the first line after the description:

`Source: CLAUDE.md §N — last synced YYYY-MM-DD`

When updating a CLAUDE.md governance section that has a corresponding skill, the skill MUST be updated in the same session. CLAUDE.md remains the source of truth. If a skill and its source section diverge, CLAUDE.md wins and the skill gets corrected.

---

## Non-Goals

- These PRDs do NOT build the skill files (`.claude/commands/*.md`)
- These PRDs do NOT modify CLAUDE.md governance
- These PRDs do NOT introduce new protocols — they codify existing ones
- No automation or hooks — skills are manually invoked via `/skill-name`

---

## CHANGELOG

| Date | Entry |
|------|-------|
| 2026-03-09 | Initial pre-planning document created. All 5 PRDs pending. |
| 2026-03-09 | PRD #1 (/archive-file) WRITTEN. |
| 2026-03-09 | PRD #2 (/registry-refresh) WRITTEN. |
| 2026-03-09 | PRD #3 (/query-artifact) WRITTEN. |
| 2026-03-09 | PRD #4 (/cmdctr-briefing) WRITTEN. |
| 2026-03-09 | PRD #5 (/rolling-mem-sync) WRITTEN. All 5 PRDs complete. |
| 2026-03-10 | Manus review incorporated: +Governance Sync Rule (parent), +explicit MCP routing (PRD #3), +silent-failure distinction (PRD #5). |
