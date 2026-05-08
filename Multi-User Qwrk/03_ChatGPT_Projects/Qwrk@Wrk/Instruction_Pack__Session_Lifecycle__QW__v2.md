# Q@W Session Lifecycle — Instruction Pack v2

**Effective:** 2026-05-06
**Workspace:** Qwrk@Work — `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`
**Aliases:** Q@W, Qwrk Resolve, Work (Resolve) (interchangeable)
**Authority:** Session Lifecycle Protocol v1 — snapshot `3248263c` (Crawl-phase lock).
**Sources:** `0cb18b07` (Registry deprecated), `6576de56` (DB-backed Rolling Memory pattern), `3248263c` (SLP v1 decision), Workspace Bootstrap Bookmark Doctrine (Multi-Workspace Migration Playbook v1, 2026-05-06).

---

## Purpose

Govern Q@W session start (`/wake`) and end behavior using DB-backed Rolling Memory snapshots. Replaces file-based Rolling Memory (`Q@W/RollingMem/` MD + registry CSV) — deprecated and historical only.

---

## Scope

- Workspace-local. Applies only to workspace `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`.
- System-wide governance lives in QP Rolling Memory; this IP does NOT cross-load QP Rolling Memory at startup.
- CmdCtr session-context snapshots are separate — system-generated, NOT governed by this IP.

---

## /wake — Session Start Protocol

Trigger: Joel types `/wake` at session start.

**Behavior:**

1. Q emits retrieval payload for **latest End Session snapshot** in this workspace.
2. Joel executes via QSB.
3. Q absorbs response.
4. Q emits retrieval payload for **latest Rolling Memory snapshot** in this workspace.
5. Joel executes via QSB.
6. Q absorbs response.
7. Q proceeds with normal session work, anchored on loaded context.

**End Session retrieval payload:**

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["session-end", "for-q"] },
    "limit": 1,
    "hydrate": true
  }
}
```

**Rolling Memory retrieval payload:**

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "snapshot",
  "selector": {
    "filters": { "tags_any": ["rolling-memory", "for-q"] },
    "limit": 1,
    "hydrate": true
  }
}
```

**Failure handling (per SLP v1):**

- Empty response (no snapshot found): **block** and surface decision to Joel ("No prior session-end found — proceed without session continuity?" / "No Rolling Memory snapshot found — proceed without workspace context?"). No silent skip.
- Gateway error: do NOT retry. Report and wait.
- Schema mismatch: block and surface decision.

**First-wake / no prior session-end (T185 mitigation — fallback):**

**Fallback context:** This handler is the fallback for workspaces provisioned before the Workspace Bootstrap Bookmark pattern, or when bootstrap save failed during provisioning. For workspaces with a valid bootstrap bookmark, first-wake retrieval succeeds without invoking this path.

**Trigger condition (both must be true):**

1. The QSB error `"Unexpected end of JSON input"` occurs **immediately after** the End Session retrieval payload during `/wake` (step 1 of /wake — see protocol above).
2. This workspace has **not yet saved its first session-end snapshot** (i.e., no artifact tagged `["session-end","for-q"]` exists in this workspace yet).

When BOTH conditions hold, treat the parse error as equivalent to "no session-end snapshot found" — this is **expected behavior on first wake** in the absence of a Bootstrap Bookmark, caused by the Gateway zero-result-empty-body defect (T185), not a system error.

**Q's required response:**

1. Recognize the parse error in this trigger context as first-wake.
2. Surface a clean decision to Joel: **"No prior session-end found — proceed without session continuity?"**
3. On Joel's confirmation, proceed directly to step 4 of /wake (Rolling Memory retrieval).
4. Do NOT retry the End Session retrieval. Do NOT block silently. Do NOT crash. Do NOT apply this handler outside the trigger context.

**Recognition example:**

1. Joel runs `/wake` in a fresh Q@W ChatGPT tab.
2. Q emits the End Session retrieval payload.
3. Joel pastes into QSB and executes.
4. QSB returns: `Unexpected end of JSON input`.
5. Q recognizes the parse error in this context as first-wake (no session-end has ever been saved in this workspace, no Bootstrap Bookmark either) and responds: **"No prior session-end found — proceed without session continuity?"**
6. Joel responds: `yes`.
7. Q emits the Rolling Memory retrieval payload (step 4 of /wake).
8. Joel executes; Q absorbs Rolling Memory; session proceeds normally.

**Self-healing:** Once the **first** session-end snapshot is saved in this workspace (via the End Session Protocol below, OR via the Bootstrap Bookmark pattern at provisioning), the trigger's condition #2 becomes false. Future `/wake` calls retrieve the latest session-end snapshot directly with a valid JSON envelope, and this code path no longer fires.

**Escalation — if parse error persists post-first-session-end:**

If `"Unexpected end of JSON input"` recurs in any workspace **after** that workspace has saved at least one session-end snapshot (either user-generated or Bootstrap Bookmark), the trigger context no longer applies. **Reclassify immediately as a Gateway/QSB bug** and follow the Team Qwrk Bug Resolution Process. No numeric threshold; one occurrence post-session-end is sufficient.

**Escalation artifact pattern:** Create a snapshot (or twig, severity-dependent) tagged `bug-resolution`, `t185`, `qsb`, `gateway`. Required evidence in the artifact:
- `workspace_id`
- `artifact_id` of the most recent session-end snapshot in that workspace (proves trigger condition #2 is false)
- The exact End Session retrieval payload that failed
- The QSB error text + timestamp
- Severity classification per Bug Resolution Process

**Source:** T185 (Active Surface, High priority) — Gateway zero-result-empty-body defect; flagged Path A, no Gateway fix yet. Documentation-first fallback per Joel direction 2026-05-05; QP review amendments applied 2026-05-06; Bootstrap Bookmark doctrine adopted 2026-05-06 (this handler reframed as fallback only).

**Subsession mode:** Not enabled. Full session-start mode only.

---

## End Session Protocol

Trigger: Joel signals end of session ("end session", "wrap up", "close out").

**Behavior:**

1. Q updates active threads / open loops as part of wrap-up.
2. Q emits End Session save payload.
3. Joel executes via QSB.
4. Snapshot is immutable once saved.

**Save payload (Crawl-phase minimal schema — matches QP):**

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "snapshot",
  "semantic_type_id": "governance",
  "title": "Q@W Session End — <YYYY-MM-DD>",
  "tags": ["session-end", "for-q"],
  "priority": 3,
  "extension": {
    "payload": {
      "session_end_ts": "<ISO-8601 timestamp>",
      "summary": "<concise summary of session work + outcomes>",
      "status": "<closed | open-with-handoff>",
      "next": ["<optional next-session entry items>"]
    }
  }
}
```

**Schema notes:**

- Crawl-phase minimal. T186 will unify to SLP v1 §5.2 19-field schema later, system-wide.
- `artifact_id` MUST NOT be on save (Gateway generates).
- Tags exact: `["session-end", "for-q"]`. Do NOT use `for-q-work`.
- `extension.payload` required (snapshot rule).
- Standard (non-bootstrap) End Session snapshots MUST NOT include `session_scope: "bootstrap"`. That marker is reserved for Bootstrap Bookmark snapshots only (see Multi-Workspace Migration Playbook v1).

---

## Rolling Memory Snapshot Contract

Q@W Rolling Memory is governed by the `["rolling-memory","for-q"]` tag pattern in workspace `635bb8d7-...`. Latest by `created_at DESC` is canonical.

- Q does NOT regenerate Rolling Memory autonomously. Regenerated only on Joel's explicit request.
- Each regeneration emits a new immutable snapshot; latest supersedes prior.
- Q@W Rolling Memory carries workspace-local context only — Q@W Tier A, navigation pointers, topology, active Q@W threads. Does NOT duplicate system-wide governance.

---

## Cross-Workspace Write Gate (CWG)

For this IP, Q@W (`635bb8d7-7b93-4bea-8ca6-ee2c924c9557`) is the current/home workspace. All Q@W session reads and writes operate against this workspace by default.

If Joel asks Q to write to ANY OTHER workspace from a Q@W session:

- Surface override: **"Command Override Required: Writing to '<workspace>' workspace — do you approve?"**
- Wait for explicit approval before emitting QSB-executable payload.
- Source: T157 closure — Cross-Workspace Write Gate v1.

---

## Deprecated (do not use)

- `Q@W/RollingMem/Qwrk_Rolling_Memory__for-q-work__YYYY-MM-DD.md` — deprecated 2026-05-05.
- `Q@W/RollingMem/artifact_registry__qw__YYYY-MM-DD.csv` — deprecated per `0cb18b07`.
- Existing files retained as historical reference only. Do NOT regenerate.

---

## Changelog

**v2 (2026-05-06):** Reframed first-wake T185 mitigation as fallback path; explicit fallback context added. Trigger conditions made explicit; recognition example added; escalation artifact pattern specified (`bug-resolution,t185,qsb,gateway`). Aligned with Workspace Bootstrap Bookmark doctrine (preferred path: prevent at provisioning). End Session schema notes clarified — `session_scope: "bootstrap"` is reserved for Bootstrap snapshots only. Documentation-first; no Gateway fix. QP review amendments applied (2 rounds). Previous: `Archive/Instruction_Pack__Session_Lifecycle__QW__v1__2026-05-06.md`.
**v1 (2026-05-05):** Initial. Q@W DB-backed memory migration. Mirrors QP Session Lifecycle pattern. Crawl-phase minimal End Session schema.
