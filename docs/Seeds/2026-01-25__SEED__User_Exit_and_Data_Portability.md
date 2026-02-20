# SEED — User Exit & Data Portability (2-Year User Exit)

**Date:** 2026-01-25
**Status:** Seed (Future Build)
**Scope:** Design-level — not Kernel v1 execution scope

---

## Purpose

Define a dignified exit path for long-term Qwrk users, ensuring they can export their artifacts in durable, human-readable formats that preserve meaning and history.

---

## Problem

Users may use Qwrk for years, building a rich history of projects, snapshots, restarts, and journals. When they choose to stop using Qwrk, they should not lose access to their intellectual work.

Without a clear exit path:
- Users feel locked in
- Trust erodes
- Data becomes hostage to platform continuity

---

## Non-Negotiables

1. **Users own their data** — always exportable, always readable
2. **Exports must be durable** — readable years later without Qwrk
3. **Meaning must be preserved** — not just raw data, but context
4. **No API dependency** — exports stand alone
5. **Privacy respected** — journals and private artifacts handled appropriately

---

## What "Access to Their Data" Means

Access means:
- **Complete** — all artifact types the user created
- **Intelligible** — human-readable without special tools
- **Contextual** — relationships and history preserved
- **Portable** — standard formats (Markdown, JSON)
- **Self-documenting** — README explains structure and semantics

---

## Proposed Exit Model

### Option A — Raw Data Export
**Description:** Dump all user data as JSON/CSV.

**Rejected because:**
- Raw data lacks context
- Relationships are lost
- Requires technical skill to interpret
- Not "dignified"

---

### Option B — Structured Export Package + Read-Only Wind-Down (RECOMMENDED)

**Description:**
1. Generate a structured export package with organized folders, Markdown renders, and a comprehensive README
2. Provide a 90-day read-only wind-down period
3. After wind-down, account is archived; export remains downloadable

**Benefits:**
- Human-readable immediately
- Preserves artifact relationships
- Graceful transition period
- No data loss

---

### Option C — Ongoing Read-Only Account

**Description:** Convert account to permanent read-only mode instead of full exit.

**Tradeoffs:**
- Ongoing infrastructure cost
- User remains "in system"
- May create compliance complexity
- Useful for some users who want to reference but not create

---

## Export Package Spec (v1)

### Formats
- **Markdown** — all artifacts rendered as .md files
- **JSON** — structured data for programmatic access
- **PDF** (optional) — for offline archival

### Folder Structure
```
qwrk-export-{username}-{date}/
├── README.md
├── projects/
│   ├── {project-title}/
│   │   ├── project.md
│   │   ├── project.json
│   │   ├── snapshots/
│   │   │   └── {snapshot-title}.md
│   │   └── restarts/
│   │       └── {restart-title}.md
├── journals/
│   └── {journal-entry}.md
├── metadata/
│   └── export-manifest.json
└── attachments/
    └── {any linked files}
```

### Required README Contents
- Export date and Qwrk version
- User identity (anonymized ID or email based on preference)
- Artifact counts by type
- Folder structure explanation
- Semantic definitions (what snapshots/restarts/journals mean)
- Contact for questions

### Canonical Meaning Preservation
- **Snapshots** — lifecycle-only, immutable, milestone markers
- **Restarts** — ad-hoc freeze points with forward intent
- **Journals** — private reflections, owner-only

Each artifact type must be explained in the README so meaning survives without Qwrk.

---

## Security / Privacy Notes

- Journals are owner-private; export only to the owner
- Shared/collaborative artifacts require consent model (future)
- Export should not include system internals or other users' data
- Encryption option for sensitive exports (future)

---

## Open Questions

1. What is the minimum wind-down period? (30 days? 90 days?)
2. Should exports include collaboration history or just owned artifacts?
3. How do we handle artifacts shared with the user but owned by others?
4. Should we offer scheduled/recurring exports for backup purposes?
5. What happens to artifacts after account deletion? (Soft delete? Hard delete? Anonymize?)

---

## Next Actions (Gated)

| Action | Gate |
|--------|------|
| Design export package schema | After Kernel v1 stable |
| Build export generation workflow | After schema approved |
| Design wind-down UX flow | After export workflow |
| Implement read-only mode | After wind-down UX |
| User testing | Before launch |

---

## Why This Increases Trust

Users who know they can leave freely are more likely to commit fully. Data portability is not just a feature — it's a statement of values:

> "We want you here because Qwrk is valuable, not because your data is trapped."

---

## Suggested Restart

**When to resume:** After Kernel v1 is stable and core artifact types are production-hardened.

**How to resume:** Reference this seed, validate open questions with stakeholders, and begin export package schema design.

---

*Source: CC_Inbox/CC_Prompt__SEED__User_Exit_and_Data_Portability.md*
