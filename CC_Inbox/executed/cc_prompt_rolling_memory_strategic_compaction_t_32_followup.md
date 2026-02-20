# CC Prompt — Rolling Memory Strategic Compaction (Targeted 8)

## Outcome
Strategically compact Tier A Rolling Memory by removing 8 low-impact Rotating Shell snapshots while preserving all governance doctrine and Protected Core entries.

**Definition of Done:**
1. Exactly 8 specified snapshots removed from Tier A display.
2. Protected Core remains untouched (count must remain 8).
3. Compacted entries moved to Section C (Archived / Compacted References) as index-only references.
4. Rolling Memory regenerated with correct counts.
5. Audit snapshot created documenting the compaction.
6. No database artifacts deleted or mutated.

---

## Context

Current Rolling Memory status:
- Total snapshots: 54
- Protected Core: 8
- Rotating Shell: 44

This compaction is **strategic**, not chronological.
We are removing historical milestone/bug confirmations that no longer shape forward behavior.

Authoritative reference:
- Qwrk_Rolling_Memory__for-q__2026-02-16.md
- Tier A Memory Compaction Protocol

---

## Snapshots to Compact (Exact IDs — No Substitutions)

1. `8d1da623` — BUG-003 Closed — Hydration Gate Validation Complete
2. `d976fb52` — BUG-026 Resolved — Gateway v48 Selector Normalization Fix
3. `e62796da` — KGB Verification — BUG-017 Universal Tag Updates Deployed
4. `a45705ec` — T15 Complete: for-q Rolling Memory MVP
5. `71dbe741` — DDL Refresh v2 — Live Schema Verified
6. `0caf807a` — Kernel v1 Security Hardening Complete
7. `8e6ab823` — Snapshot — Gateway ACL Pause (Env Access Block)
8. `471d3946` — Phase 2B Walk — Hydration Stabilization Complete (Pre-Update Surface)

---

## Execution Rules (Binding)

1. DO NOT delete any database artifacts.
2. DO NOT mutate any snapshot contents.
3. Remove only their presence from Tier A Rolling Memory.
4. Move each to Section C as index-only reference (artifact_id + title).
5. Preserve Protected Core section unchanged.
6. Recalculate and update snapshot counts.
7. Archive previous Rolling Memory file version.
8. Create an audit snapshot documenting:
   - Compaction action
   - IDs compacted
   - Before/After counts
   - Confirmation Protected Core untouched

If any invariant would be violated, STOP and report.

---

## Validation Checklist

Before marking complete:

- [ ] Protected Core count = 8 (unchanged)
- [ ] Rotating Shell reduced by exactly 8
- [ ] Total snapshot count reduced accordingly
- [ ] Section C populated with index-only references
- [ ] No duplicate IDs remain in Tier A
- [ ] Previous Rolling Memory version archived
- [ ] Audit snapshot created with `for-q` tag

---

## Required Output

Respond with:

1. Summary of compaction
2. Before / After counts (Protected Core, Rotating Shell, Total)
3. Confirmation Protected Core untouched
4. New Rolling Memory file path
5. Audit snapshot artifact_id

Do NOT propose additional compaction.
Do NOT modify doctrine.
Execute only what is specified.