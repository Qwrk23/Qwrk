# SNAPSHOT — Gateway Type Registry Guard (KGB-LOCK Candidate)

**Date:** 2026-01-24 (CST)
**Scope:** Gateway v1 — WRITE workflows only
**Status:** KGB-LOCKED (Governance Close-Out)

---

## Purpose

Lock the verified behavior of the Gateway Type Registry Guard so future workflow changes cannot silently loosen enforcement.

This snapshot is based on direct review of the actual n8n workflow JSON files (not summaries).

---

## What Was Reviewed (Ground Truth)

Files reviewed:

- `NQxb_Artifact_Save_v1.json`
- `NQxb_Artifact_Update_v1.json`
- `NQxb_Artifact_Promote_v1.json`

---

## Decisions Locked

### 1) Guard Coverage is WRITE-Only

Guard applies ONLY to:

- `artifact.save`
- `artifact.update`
- `artifact.promote`

Guard does NOT apply to:

- `artifact.query`
- `artifact.list`

### 2) Guard Placement is Correct (All Three Workflows)

Placement is identical across save/update/promote:

- After normalize / validation
- Before any DB write or promote logic

### 3) Fail-Closed Semantics (Verified)

Requests are rejected in all of these cases:

- Missing `artifact_type`
- `artifact_type` not registered in the Type Registry
  - `error.details.reason = "not_registered"`
- `artifact_type` registered but disabled
  - `error.details.reason = "disabled"`

### 4) Canonical Error Envelope (Verified)

All rejections use the same envelope:

- HTTP: **403**
- error.code: **ARTIFACT_TYPE_NOT_ALLOWED**
- error.details.reason: one of:
  - `missing_type`
  - `not_registered`
  - `disabled`

### 5) Regression Check (Verified)

No regressions were detected in existing KGB behavior.

---

## Explicit Non-Goals (Locked)

- No changes to `artifact.query`
- No changes to `artifact.list`
- No expansion of allowed artifact types (registry enforcement only)

---

## Implication

Any future change to this guard behavior requires a versioned override (no silent blending).

— End —
