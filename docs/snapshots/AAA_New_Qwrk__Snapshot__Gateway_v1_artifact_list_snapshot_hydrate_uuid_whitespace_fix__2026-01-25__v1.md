# SNAPSHOT — Gateway v1 artifact.list snapshot hydrate UUID whitespace fix (KGB)

## Snapshot Metadata
- **Artifact Type:** snapshot
- **Artifact ID:** `2a95b6fd-ab75-4dd2-b8a6-0e3e99c0e0ba`
- **Title:** SNAPSHOT — Gateway v1 artifact.list snapshot hydrate UUID whitespace fix (KGB)
- **Created At (UTC):** 2026-01-25T23:33:33Z
- **Status:** LOCKED (KGB pass)

> **Already Saved:** This snapshot is already persisted in Qwrk (Supabase) under artifact_id `2a95b6fd-ab75-4dd2-b8a6-0e3e99c0e0ba`. This markdown file is the human-readable companion record.

---

## 1. Context

- **System:** Qwrk Gateway v1 + n8n
- **Action:** `artifact.list`
- **Type:** `snapshot`
- **Selector:** `hydrate=true`
- **Failing Node:** `NQxb_Artifact_List_v1__DB_Get_Snapshot_Extension`

---

## 2. Symptom (As Observed)

- HTTP 200 with empty body (raw length 0)
- Supabase node error: `invalid input syntax for type uuid`
- Input showed UUID with trailing whitespace (space/newline/control)

---

## 3. Root Cause

`artifact_id` value reached UUID filter with trailing whitespace; Postgres UUID cast rejected it.

The n8n expression `{{ $json.artifact_id }}` passed through a value with trailing whitespace, which PostgREST sent to PostgreSQL. PostgreSQL's strict UUID type casting rejected the malformed value.

---

## 4. Fix (Single Change, No Batching)

- **Node:** `NQxb_Artifact_List_v1__DB_Get_Snapshot_Extension`
- **Change:** Trim artifact_id before UUID filter
- **Expression (verbatim):**
  ```
  {{ ($json.artifact_id || '').trim() }}
  ```

---

## 5. Receipts (Explicit Numeric Facts)

### Fix Validation Call
- **Status:** 200
- **Raw Length:** 877
- **Body:** `ok: true` with snapshot returned

### Regression Test 1: snapshot list hydrate=false
- **Status:** 200
- **Raw Length:** 7142

### Regression Test 2: project list hydrate=true
- **Status:** 200
- **Raw Length:** 3686

---

## 6. Governance Notes

- One-step change → immediate retest → regression tests run
- Step 2 fallback (HTTP PostgREST replacement) was pre-approved but NOT required
- Fix was minimal and deterministic — trim is idempotent and safe for clean UUIDs

---

## 7. Follow-On (Non-Binding)

Recommend standardizing all UUID filters in n8n to trim-safe expression where user-provided/runtime values may carry whitespace. Candidates: project, journal, restart extension fetch nodes.

---

## Suggested Restart Prompt

**RESTART — Gateway v1 List Hardening (Post-Snapshot-Hydrate Fix):** The snapshot hydrate UUID whitespace issue is now LOCKED. Resume from "next hardening options" for artifact.list. Candidates include: (1) applying the same trim() pattern to other extension fetch nodes (project, journal, restart) for defensive consistency, (2) evaluating whether page-wide hydration for other artifact types has similar single-item collapse issues, (3) running full Gateway regression suite to confirm no regressions. Do NOT reopen the snapshot UUID fix — it is KGB-locked.

---

*Snapshot created by Claude Code — 2026-01-25*
