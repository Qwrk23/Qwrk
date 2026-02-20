# KGB Proof — Gateway `artifact.list` (Base + Hydrated) — 2026-01-11

**As-of:** 2026-01-11 (America/Chicago)
**Workspace:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
**Gateway endpoint:** `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1`
**Status:** KGB-PROVEN (lock candidate)

---

## Contract Surface (Locked Semantics)

### Request (required)
- `gw_action = "artifact.list"`
- `gw_workspace_id` (uuid) **required**
- `artifact_type` **required** (if omitted → deterministic `VALIDATION_ERROR`)
- `selector.hydrate` (boolean)
- `selector.limit` (int)
- `selector.offset` (int)
- `selector.include_fields` (string[])

### Response (success)
- `ok: true`
- `gw_action: "artifact.list"`
- `gw_workspace_id`
- `artifact_type`
- `selector`
- `data.artifacts: []`
- `meta: { count, limit, offset }`
  - `meta.count` represents **items returned in this page** (not total)

### Response (error)
- `ok: false`
- `error.code = "VALIDATION_ERROR"` (e.g., missing `artifact_type`)

---

## KGB Test Suite (Minimum Lock-Worthy)

### Test 1 — restart, hydrate=false, limit=5, offset=0
**Result:** ok=true, meta.count=5
**Timestamp:** 2026-01-11T12:11:50.180Z

### Test 2 — restart, hydrate=true, limit=5, offset=5
**Result:** ok=true, meta.count=3 (partial page is correct)
**Timestamp:** 2026-01-11T12:12:15.950Z

### Test 3 — artifact_type omitted, hydrate=false
**Result:** deterministic validation error
**HTTP:** 403
**Body:** ok=false, error.code="VALIDATION_ERROR"

### Test 4 — project, hydrate=true, limit=5, offset=0
**Result:** ok=true, meta.count=1
**Timestamp:** 2026-01-11T12:14:48.806Z

### Test 5 — snapshot, hydrate=true, limit=5, offset=0
**Result:** ok=true, meta.count=1
**Timestamp:** 2026-01-11T12:15:17.928Z

### Test 6 — journal, hydrate=true, limit=5, offset=0
**Result:** ok=true, meta.count=1
**Timestamp:** 2026-01-11T12:15:46.664Z

---

## Fixes Applied (Root Cause + Resolution)

1) **List workflow request normalization**
- `artifact_type` was becoming null because Normalize only read `selector.artifact_type`.
- Fixed by supporting top-level `artifact_type` as well.

2) **Gateway list response shaping**
- Child list workflow returned `items` shapes (sometimes nested).
- Gateway shaper updated to unwrap child output and return canonical `data.artifacts`.

3) **Hydrate path cardinality bug**
- `NQxb_Artifact_List_v1__Merge_Restart` (Code node, run once for all items) collapsed 5→1.
- Fixed to iterate `$input.all()` and return one output per input item.
- Verified by successful hydrated restart list with `meta.count=5` on 2026-01-11T12:08:40.012Z.

---

## Lock Recommendation

✅ Safe to lock `artifact.list` contract semantics for Kernel v1 / Gateway v1.
Remaining optional hardening (non-blocking):
- Add `meta.total` (count query) if needed
- Sort guarantees
- Parent filters
- RLS enforcement regression suite
