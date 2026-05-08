# Multi-Workspace Session Lifecycle Migration Playbook v1

**Effective:** 2026-05-06
**Status:** Active reference for multi-workspace session lifecycle migration
**Audience:** CC (primary executor), Joel (operator), Q@W/Akara/BlaggLife/Greg/Demo workspace SI authors
**Authority:** Session Lifecycle Protocol v1 (snapshot `3248263c`), CLAUDE.md v32 governance, Q@W migration template (snapshot `fe9798ef`).

---

## Purpose

This playbook is the reusable runbook for migrating a Qwrk workspace from file-based or undefined memory to DB-backed Rolling Memory + Session Lifecycle Protocol v1. It is provenance-tagged with two completed migrations: QP (2026-04-24) and Q@W (2026-05-05). After each subsequent migration, it MUST be refined with deviations and lessons (Phase H).

The goal is **architectural consistency across all workspaces** with one memory model (DB-backed Rolling Memory + atomic End Session snapshots) and one retrieval pattern (`/wake` followed by Crawl-phase minimal End Session save). Each migrated workspace operates under workspace-local Rolling Memory; system-wide governance reaches the workspace via its SI/IP set, not via cross-workspace Rolling Memory pointers.

---

## Provenance

- **QP migration (2026-04-24):** First DB-backed Rolling Memory snapshot — `6576de56-7fd6-4c23-a3c2-637368f9b1d3`. Source decisions: `0cb18b07` (Registry deprecated), `3248263c` (SLP v1 lock), `f93f8ec6` (review protocol).
- **Q@W migration (2026-05-05):** Bootstrap snapshot — `fe9798ef-f84c-4ba6-b2c1-41314806941a`. First Q@W session-end — `4d16480e-4d58-4566-9523-fe76d1c68738` (closed first-wake T185 window).
- **CLAUDE.md v32 (2026-05-05):** File-based Rolling Memory + Registry protocols formally deprecated system-wide.
- **Workspace Bootstrap Bookmark Doctrine (2026-05-06):** Adopted as preferred mitigation for first-wake T185; introduced in this playbook v1.

---

## Hard-Won Lessons (from QP and Q@W migrations)

1. **SI head lives in ChatGPT Project Instructions field, NOT Files/Knowledge.** The disk file is a working source that the operator pastes into the Instructions field manually. Failure mode: assuming a disk file means deployed state. ChatGPT's Files/Knowledge area is for instruction packs and reference docs, NOT the SI head.

2. **IPs are project Files/Knowledge attachments.** Different upload mechanism from SI head. Each IP is uploaded as a file. The IP Index governs which packs are active.

3. **Local disk file does NOT prove deployed state.** Always verify by asking the operator to read the actual ChatGPT Project Instructions field text. Disk drift can persist for weeks. Q@W had a `v_2_10` draft sitting on disk that was never deployed; without operator verification this would have become the false baseline for the v2.11 bump.

4. **Never-deployed SI drafts must be archived with `__draft_never_deployed__<DATE>` suffix.** Otherwise they accumulate alongside deployed versions and confuse future migrations.

5. **First-wake T185 risk applies to every newly migrated workspace until that workspace's first session-end snapshot is saved.** The Gateway zero-result-empty-body defect causes QSB to throw `"Unexpected end of JSON input"` when no `session-end` snapshot exists yet. **Preferred mitigation: Workspace Bootstrap Bookmark Doctrine (see below) — eliminates the first-wake window at provisioning.** Fallback: per-workspace Session Lifecycle IP first-wake handler (Q@W IP v2 pattern).

6. **Bootstrap content recall (Migration Claim A) is the strongest pre-end-session validation step.** Have the operator open a fresh tab, run `/wake`, and verify the workspace correctly hydrates active threads, topology, aliases, and Tier A artifacts from the bootstrap snapshot. This validates the migration's core path before full session-end continuity exists.

---

## CmdCtr Separation (Invariant)

**Workspace migrations do NOT alter CmdCtr session-context behavior.** This is invariant across all workspaces and migrations. CmdCtr session-context snapshots remain:

- System-generated (saved by `cmdctr_operator_briefing()` at session start).
- Tagged `cmdctr,session-context,for-q`.
- Saved to the Operational Intelligence branch (workspace-specific UUID).
- **NOT part of Rolling Memory.** Not loaded by `/wake`. Not part of the End Session save schema.

CmdCtr does not override governance, does not replace `/wake` retrieval, and does not serve as sole source of truth. The Rolling Memory snapshot is the canonical workspace-local state at `/wake`; CmdCtr is real-time operational observability available on demand.

If any future migration wants to bind CmdCtr more tightly to Rolling Memory, that is a separate doctrine change and MUST be raised as its own thread, not folded into a workspace migration.

---

## Workspace Bootstrap Bookmark Doctrine

**Invariant:** Every provisioned workspace MUST have at least one valid End Session snapshot before first user interaction.

**Purpose:** Eliminates the T185 first-wake parse-error window by ensuring `/wake`'s End Session retrieval always returns a valid JSON envelope, even on a workspace's first user session. Turns T185 from a recurring migration hazard into a one-time setup requirement.

**Pattern:** During workspace provisioning, after the workspace is created and after Rolling Memory bootstrap is saved, save a Bootstrap End Session snapshot. The snapshot is visibly marked as bootstrap (not phantom prior session) and provides the bookmark that `/wake` retrieves on first user interaction.

**Save payload shape (workspace-specific tag set):**

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "<workspace_id>",
  "artifact_type": "snapshot",
  "semantic_type_id": "governance",
  "title": "End Session — Bootstrap — <Workspace Name>",
  "tags": ["<workspace's active session-end retrieval tag>", "for-q", "bootstrap"],
  "priority": 3,
  "extension": {
    "payload": {
      "schema_version": "v1",
      "session_scope": "bootstrap",
      "session_id": "bootstrap-<provisioning ISO timestamp>",
      "session_date": "<provisioning local date YYYY-MM-DD>",
      "prior_end_session_snapshot_id": null,
      "corrects_end_session_snapshot_id": null,
      "session_summary": "Bootstrap End Session snapshot created during workspace provisioning so first /wake has a valid bookmark. No prior user session exists.",
      "session_start_ts": "<provisioning ISO timestamp>",
      "session_end_ts": "<provisioning ISO timestamp>",
      "startup_skipped": false,
      "open_threads": [],
      "decisions_locked": [],
      "artifacts_created": [],
      "artifacts_referenced": [],
      "next_session_start": "Begin first user onboarding session. Load Rolling Memory, confirm workspace identity, and guide first save/retrieve cycle.",
      "workspace_id": "<workspace_id>",
      "workspace_name": "<workspace_name>"
    }
  }
}
```

**Bootstrap schema exception:** For Bootstrap End Session snapshots only, `session_scope: "bootstrap"` is a permitted `extension.payload` field. Standard (non-bootstrap) End Session snapshots MUST NOT include `session_scope: "bootstrap"` and MUST follow the workspace's normal End Session schema (Crawl-phase minimal today; SLP v1 §5.2 19-field after T186 unifies). The `bootstrap` tag and `session_scope: "bootstrap"` together form the marker pair that distinguishes a Bootstrap snapshot from a real session-end.

**Timestamp rule:** `session_start_ts` and `session_end_ts` MUST both be set to the provisioning ISO timestamp (the moment the workspace was created and the Bootstrap snapshot was saved). Do NOT use `null` for either. The bootstrap "session" is a synthetic zero-duration window at provisioning time; both timestamps reflect that moment.

**Identity field rules for Bootstrap payload:**

- `session_id`: literal prefix `bootstrap-` followed by the provisioning ISO timestamp.
- `session_date`: provisioning local date (YYYY-MM-DD).
- `prior_end_session_snapshot_id`: always `null` (there is no prior session).
- `corrects_end_session_snapshot_id`: always `null` (bootstrap is not a correction artifact).

**Schema divergence note:** The Bootstrap payload carries identity fields (`session_id`, `session_date`, `prior_end_session_snapshot_id`, `corrects_end_session_snapshot_id`) that are NOT in the current Crawl-phase minimal End Session schema. This divergence is intentional: bootstrap is a one-time provisioning artifact and benefits from explicit identification. T186 will likely unify both schemas; until then, treat the Bootstrap schema as the more-explicit superset.

**Tag invariant (per workspace, not universal):** The Bootstrap End Session snapshot MUST use the same session-end retrieval tag used by that workspace's active Session Lifecycle IP. For Q@W, that is `session-end`. Cross-workspace tag standardization is a separate governance issue NOT addressed by this doctrine. Do not retroactively normalize tag conventions across workspaces as a side effect of adopting this pattern.

**Guardrails:**

- `session_scope: "bootstrap"` and tag `bootstrap` are both required. They mark the snapshot as a provisioning artifact, not real prior work.
- Bootstrap save is a one-time provisioning step. Subsequent End Session saves use the workspace's normal End Session schema (no `bootstrap` tag, no `session_scope: "bootstrap"`).
- For workspaces provisioned BEFORE this doctrine was adopted, the Session Lifecycle IP first-wake mitigation handler serves as fallback. Retroactive Bootstrap save is optional, not required.
- Future Q queries that legitimately match zero rows on `tags_any` will still trip T185 root defect (Gateway empty body). This doctrine does NOT fix the root cause; it prevents the *first-wake* manifestation only.

---

## Phases

### Phase A — Discovery (read-only)

A1. Confirm workspace UUID, primary alias, and all human-facing labels (e.g., Q@W: "Q@W", "Qwrk Resolve", "Work (Resolve)").
A2. Inventory current memory surface: file-based MD? CSV registry? embedded in SI? none?
A3. Identify workspace-local Tier A artifacts (forest map snapshot, milestone snapshots, founding decisions).
A4. Filter OPEN_THREADS for threads tied to this workspace.
A5. Identify any workspace-specific governance NOT covered by QP Rolling Memory.
A6. Inventory all instruction packs that reference the file-based memory path; flag for Phase C update.
A7. **Verify deployed SI version with operator** — do NOT assume local disk file equals deployed state. Ask operator to paste actual ChatGPT Project Instructions field text. Confirm version match (or surface drift) before proceeding.

### Phase B — Bootstrap Strategy (review-only draft)

B1. Decide what is preserved (Tier A workspace-local, navigation pointers, topology, active threads).
B2. Decide what is dropped (CmdCtr session-context noise, system-wide governance already in QP, low-signal narrative).
B3. Draft the Rolling Memory bootstrap snapshot JSON following the Q@W template (see Q@W bootstrap `fe9798ef-...` for shape).
B4. **Mandatory:** include a `governance_inheritance_note` field explicitly stating workspace-local-only and that the snapshot does NOT cross-load QP Rolling Memory at startup.
B5. Validate JSON: full UUIDs everywhere (no shortened refs in canonical Rolling Memory; canonical fields use 36-char form), schema correct, all tag arrays exact.
B6. Draft the Bootstrap End Session snapshot JSON per the Workspace Bootstrap Bookmark Doctrine (above). Confirm tag set matches workspace's Session Lifecycle IP retrieval tag.

### Phase C — SI Update

C1. Use the `/update-si` skill (never freehand — per CC feedback rule).
C2. Add Workspace Identity & Aliases section.
C3. Add Session Start Protocol — `/wake` retrieval (latest session-end + latest rolling-memory, workspace-scoped). Mirror QP's `/wake` pattern exactly.
C4. Add Session End Protocol per SLP v1 (Crawl-phase minimal schema; T186 unifies system-wide later).
C5. Add CmdCtr Snapshot Separation note (operational, separate from Rolling Memory).
C6. Add file-based deprecation banner with date.
C7. Subsession mode: skip unless explicitly required by operator (Q@W default).
C8. **8k char ceiling check:** if no headroom, extract operational detail to a new IP and have the SI head carry only the routing pointer.
C9. The Session Lifecycle IP (per workspace) MUST include the first-wake T185 fallback handler as defined in Q@W IP v2.

### Phase D — Bootstrap Saves (Rolling Memory + End Session Bookmark)

**D-1: Rolling Memory Bootstrap Save**

D1.1. CC produces the Rolling Memory save payload (read-only).
D1.2. **CWG approval** if CC's home workspace differs from migration target.
D1.3. Joel executes via QSB.
D1.4. Verify retrievability via Gateway query (read; no CWG).
D1.5. Verify content shape: full UUIDs, tags `["rolling-memory","for-q"]`, semantic_type `governance`, `governance_inheritance_note` present.

**D-2: Bootstrap End Session Snapshot Save (Workspace Bootstrap Bookmark)**

Per the Workspace Bootstrap Bookmark Doctrine, every provisioned workspace MUST have at least one valid End Session snapshot before first user interaction. This save closes the first-wake T185 window before the user ever runs `/wake`.

D2.1. CC produces the Bootstrap End Session save payload using the workspace's active Session Lifecycle IP retrieval tag set (e.g., for Q@W: `["session-end", "for-q", "bootstrap"]`). Payload includes `session_scope: "bootstrap"` and clearly marks itself as a provisioning artifact (not phantom prior work). Both `session_start_ts` and `session_end_ts` use the provisioning ISO timestamp.
D2.2. **CWG approval** if cross-workspace.
D2.3. Joel executes via QSB.
D2.4. Verify retrievability — Bootstrap snapshot returns as latest `tags_any: ["<workspace session-end tag>"]` query result.
D2.5. Verify content shape; confirm `session_scope: "bootstrap"` is set; confirm both timestamps populated; confirm identity fields (`session_id`, `session_date`, `prior_end_session_snapshot_id`, `corrects_end_session_snapshot_id`) present.

**Retroactive case:** Workspaces provisioned before this doctrine was adopted (e.g., Q@W on 2026-05-05) may either receive a retroactive Bootstrap save OR rely on the Session Lifecycle IP's first-wake fallback handler. Decision is per workspace and not required for already-bookmarked workspaces.

### Phase E — Live Test (Bootstrap-Aware)

E1. Joel uploads SI head into ChatGPT Project Instructions field; uploads new IP and updated IP Index to project Files/Knowledge.
E2. Joel opens a fresh ChatGPT tab in the workspace.
E3. Joel runs `/wake`.

**E4. Expected when Bootstrap Bookmark exists:** first `/wake` retrieves the Bootstrap End Session snapshot as a valid JSON envelope; no parse error. Q absorbs the bootstrap context, recognizes `session_scope: "bootstrap"` as a provisioning marker (no real prior work), and proceeds to Rolling Memory retrieval.

**E5. Expected when bootstrap save was skipped, failed, or predates the Bootstrap Bookmark pattern (fallback path):** Q applies the workspace's Session Lifecycle IP first-wake mitigation handler — recognizes the QSB parse error as "no prior session-end," surfaces the decision to Joel, proceeds to Rolling Memory retrieval after Joel confirms.

E6. Q proceeds to Rolling Memory retrieval (step 4 of /wake) — succeeds (the Rolling Memory bootstrap snapshot exists). Q hydrates workspace-local context.
E7. **Migration Claim A — Bootstrap content recall:** Verify Q correctly references active threads, topology, aliases, Tier A artifacts from the loaded Rolling Memory snapshot. If Q reasons from the loaded payload, Migration Claim A passes.
E8. Joel ends the session. Q produces the End Session save payload (real session, not bootstrap). Joel executes via QSB.
E9. Joel opens another fresh tab; runs `/wake` again. Both retrievals succeed end-to-end. Migration is functionally complete.

### Phase F — Multi-Tab + Schema Validation (optional, deferred)

F1. Operator runs two parallel ChatGPT sessions in the workspace; ends both. Verify no collision; latest-by-`created_at` resolves cleanly.
F2. Note: End Session schema is currently Crawl-phase minimal (matches QP). T186 unifies to SLP v1 §5.2 19-field schema later, system-wide. Migration does not change schema.

### Phase G — Cutover

G1. After ~1 month of validated use, move file-based MD/CSV references in `<Workspace>/Rolling Mem/` to `Archive/`. Files are retained, not deleted, per CLAUDE.md Destructive Operations Discipline.
G2. Update OPEN_THREADS: mark migration thread COMPLETE; archive cutover scheduled.
G3. Update CC's MEMORY.md if any workspace-specific notes change.

### Phase H — Hygiene + Playbook Refinement

H1. Capture deviations and lessons from this migration.
H2. Verify file-based memory references in other workspace IPs are updated/deprecated as appropriate.
H3. Bump this playbook to vN+1 if any phase materially changed; otherwise add a short post-migration entry to the changelog noting the migration completed cleanly without playbook changes.

---

## Per-Workspace Effort Estimates

Based on Q@W actuals and QP retrospective:

| Workspace | Surface size | Estimated effort |
|---|---|---|
| **QP (DONE 2026-04-24)** | Large (8 Protected Core, 6 Anchors, 5 Tier A-Prime, 32+ active threads) | First-of-kind; effort not directly comparable |
| **Q@W (DONE 2026-05-05)** | Small (2 Tier A workspace-local, 8 Section B, 6 active threads) | ~3h CC + 1.5h Joel actual |
| BlaggLife | TBD — discovery first | TBD |
| Akara | Larger (Mother Tree + IP set + Gardenomicon + Seed Pod) | 3–4h CC + 1.5–2h Joel |
| Greg | Smaller (newer workspace) | 2–3h CC + 1h Joel |
| Demo | Smallest (read-only / exploratory) | 1–2h CC + 30min Joel |

---

## Hard Constraints (System-Wide)

- **Pattern C archive-first** for SI bumps and IP/Index version bumps. Existing version moves to Archive; new version takes the canonical filename.
- **No Gateway / DB schema / n8n workflow / runtime changes** during a workspace migration. Migration is documentation + data only.
- **No workspace identity collapse.** Aliases are documented; UUIDs remain authoritative.
- **CWG required** for cross-workspace bootstrap saves.
- **8k character ceiling on SI heads** — strict.
- **No destructive operations.** Files retained, not deleted, throughout migration.
- **First-wake T185 mitigation MUST be present** in the workspace's Session Lifecycle IP before live test (Phase E). Pattern as defined in Q@W IP v2.
- **Bootstrap End Session save (Phase D-2) is REQUIRED** for new workspace provisioning. For migrations of existing pre-doctrine workspaces, retroactive Bootstrap save is optional; fallback path (IP first-wake handler) is acceptable.

---

## Escalation — When First-Wake Mitigation Becomes a Gateway Bug

If `"Unexpected end of JSON input"` recurs in any migrated workspace **after** that workspace has saved at least one session-end snapshot (either user-generated or Bootstrap Bookmark), the first-wake mitigation no longer applies. The Gateway-side defect is then live and active, not a benign first-wake artifact.

**Reclassify immediately as a Gateway/QSB bug.** Follow the Team Qwrk Bug Resolution Process. Capture as a snapshot (or twig, severity-dependent) tagged `bug-resolution`, `t185`, `qsb`, `gateway`. No numeric threshold; one occurrence post-session-end is sufficient to escalate.

---

## Propagation Track (Out of Scope for This Playbook)

The Workspace Bootstrap Bookmark Doctrine MUST be folded into the following surfaces. Propagation is tracked separately and is NOT part of this playbook's authority:

- **T176 Branch B (Operator Provisioning System):** Make Bootstrap End Session save a deterministic provisioning step alongside workspace creation, ACL setup, and Rolling Memory bootstrap.
- **T145 (Beta User Provisioning & Onboarding):** Add Bootstrap save as a required onboarding sub-step.
- **Future workspace migrations:** Phase D-2 of this playbook is the canonical reference (above).

A separate twig tracks this propagation work and links to the implementation thread in T176 / T145.

---

## Changelog

**v1 (2026-05-06):** Initial. Produced from QP and Q@W migrations. Includes hard-won lessons, CmdCtr Separation invariant, Workspace Bootstrap Bookmark Doctrine, Phases A–H (D split into D-1 + D-2 for bootstrap saves), per-workspace effort estimates, hard constraints, escalation rule, propagation track. QP review amendments applied (2 rounds): trigger condition language + recognition example + escalation artifact pattern (round 1); Bootstrap schema exception + identity field rules + timestamp rule + payload structure (round 2).
