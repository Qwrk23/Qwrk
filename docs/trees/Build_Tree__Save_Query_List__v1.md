# Build Tree — Save / Query / List (v1) — 2026-01-02

## Purpose
Deliver the **minimum end-to-end user experience** for Qwrk’s CustomGPT front end:
- **Save** an artifact
- **Query** an artifact
- **List** artifacts by type
…using the same contract and governance posture we will keep long-term.

This Tree is designed to be executed **today** using:
- n8n workflows built by CC
- Supabase as canonical truth
…and later executed from the front end without changing the semantics.

---

## Governing invariants (do not violate)
1. **Qxb_Artifact is the spine.** Typed tables extend it; never bypass the spine.
2. **Snapshots are lifecycle-only and immutable.** They are not “daily state reports.”
3. **Restarts are ad-hoc freeze records** (used to restart a thread/build without changing lifecycle).
4. **History/Report is separate** (for daily/weekly “state-of-the-moment” digests + GitHub mirroring).
5. **KGB gates everything.** No new surface area ships without KGB passing.

---

## Tree (execution graph)
> Reading tip: each node has Inputs → Outputs → Invariants → Failure modes → Tests.

### ROOT: Deliver Save / Query / List to CustomGPT via Gateway
- **Outcome:** a user can Save/Query/List from the CustomGPT front end, and the system remains governed.

#### Branch A — Contracts & Governance
A1. **Lock “Writes enabled” decision (Gateway v1.1)**
- Output: `contracts/Gateway_v1_1__Writes_Enablement__Decision_Record.md`
- Gate: owner-only, allow-listed artifact types, explicit error model.

A2. **Define Action set**
- `artifact.save`
- `artifact.query`
- `artifact.list`
- (Later) `artifact.promote`, `artifact.patch`, `artifact.history_report.create`

A3. **Define “History/Report” mirror rules**
- GitHub is a mirror, not truth.
- One folder per History/Report artifact (named by artifact_id and date).
- Include: links to KGB baselines, linked lifecycle snapshot, deltas, next steps.

#### Branch B — n8n Workflows (CC-owned)
B1. **Gateway Router**
- Routes by `gw_action` (not by guessing payload shapes).
- Normalizes request so downstream nodes see stable top-level fields.

B2. **artifact.query (Known-good)**
- Must already be KGB (baseline).
- Output shape is stable and action-scoped.

B3. **artifact.list**
- Type-scoped list with sane defaults.
- Supports pagination and ordering (later), but v1 can be minimal.

B4. **artifact.save**
- Spine-first insert; typed extension insert second.
- Writes event log entry.
- Returns the created artifact (or at least artifact_id + echo fields).

#### Branch C — Database Discipline
C1. **RLS and owner-only posture**
- MVP mode: only super admin / owner identity can write.
- Beta mode later: workspace membership + role weighting.

C2. **Schema alignment**
- qxb_artifact base columns are locked.
- typed tables follow Kernel semantics.

#### Branch D — Front End (CustomGPT Actions)
D1. **Create 3 GPT Actions**
- Save / Query / List, all pointed to the Gateway endpoint.

D2. **End-to-end acceptance**
- Run KGB: Save a Project → Query it → List Projects and see it.

---

## “As it will work eventually” — mapping to the UX
The front end (CustomGPT today; dashboard later) will:
1. **Decide intent** (save, query, list)
2. **Call Gateway** with a stable envelope
3. **Gateway validates + routes**
4. **n8n writes/reads Supabase**
5. **Response returns to the UI**
6. **History/Report captures milestone + mirror to GitHub**

This Tree ensures we can execute the same shape now and later.

---

## Milestone triggers (auto-history/report)
When any of these happen, create a History/Report artifact and mirror to GitHub:
- KGB passed (Save/Query/List)
- Phase transition (planning → definition → execution)
- Contract version bump
- Schema migration / RLS change

Template: `templates/Artifact__History_Report__Template__v1.md`
Runbook: `runbooks/Runbook__Snapshot_and_GitHub_Mirror.md`
