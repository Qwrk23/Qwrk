# AAA_New_Qwrk — Snapshot — Gateway v1 artifact.list KGB Lock (v1.0)

---

**As-of:** 2026-01-17

**Objective:** Bring artifact.list to KGB state under Gateway v1 (post Kernel v1 lock), with deterministic pagination, stable shape, explicit hydration, and zero silent empty outputs.

---

## Kernel Status

### Locked / Frozen (do not modify without versioning)

- artifact.save
- artifact.query
- artifact.update

### Pinned Proof Artifacts (sacred)

| Field | Value |
|-------|-------|
| Snapshot Artifact ID | 0452fab4-cb93-438c-a706-856c1841769e |
| Verified Project Artifact ID | e9601873-9f71-4843-bd81-9ecaccbbf9e3 |

---

## Decisions Locked

### Canonical Response Envelope for artifact.list (base + hydrated)

- Top-level: `ok`, `gw_action`, `gw_workspace_id`, `artifact_type`, `selector`, `data:{artifacts}`, `meta`, `timestamp`
- Never return top-level `items`
- `meta.count` = page count (returned items), not total DB count

### Pagination Semantics

- Inputs: `selector.limit`, `selector.offset`
- Deterministic ordering: `created_at DESC`, tie-breaker `artifact_id DESC`
- Anchor paging: `selector.as_of` enforced as `created_at <= as_of`
- If `as_of` omitted on first page, server sets `as_of = now()` and returns it
- Client must reuse same `as_of` for subsequent pages

### Minimal Pagination Signal

- `meta.has_more` implemented (no `total_count`)
- One DB call only (no COUNT query)

### Deterministic Superset Constraint

- Supabase "Get many rows" fetch uses a constant limit (500) to avoid page-to-page "different superset" drift
- Validation prevents unsafe selector windows beyond deterministic cap

### Hydration Rules

- Hydration is explicit via `selector.hydrate=true`
- Hydrated response uses the same canonical envelope as base
- No accidental hydration

---

## Known-Good Tests (Evidence Receipts)

### Base List Returns Stable Shape

- `data.artifacts[]` populated correctly
- `meta.count/limit/offset` correct
- `meta.has_more` present and boolean

### Pagination Correctness Verified by Ledger Test

- `limit=10, offset=0` establishes ordered superset
- `limit=3, offset=3` returns IDs #4-#6 from superset (correct slicing)

### Anchor Fields Verified

- `meta.as_of` present
- Subsequent requests can reuse `selector.as_of`

---

## Workflow Edits Applied (High Level)

### NQxb_Artifact_List_v1

| Node | Change |
|------|--------|
| Supabase Get many rows (qxb_artifact) | limit set to constant 500 |
| Validate node | enforces selector bounds + resolves selector + supports as_of |
| Apply Filters/Pagination node | applies created_at <= as_of, deterministic sort, computes has_more |
| Format Base Response | includes meta.has_more and meta.as_of |
| Format Hydrated Response | canonical envelope with data.artifacts + meta.has_more/as_of |

---

## Files Referenced This Session

- NQxb_Gateway_v1 (20).json (uploaded)
- NQxb_Artifact_List_v1 (5).json (uploaded)

---

## Current Phase

Execution + verification complete. KGB lock.

---

## Open Questions (Intentionally Deferred)

- Do we want `meta.total_count` later (v1.1+)?
- Do we want `selector.sort` later (v1.1+)?
- Should deterministic fetch cap remain 500 or become a versioned config?
- Any additional edge-case tests desired (empty set, offset beyond end, hydrate paging)?

---

## Next 1-2 Actions

1. Create and save a KGB proof artifact for artifact.list (snapshot/restart type), including this snapshot text and test receipts.

2. Optional: run final edge-case battery:
   - empty artifact_type set (valid but empty)
   - offset beyond end
   - hydrate=true with paging + as_of

---

**End of Snapshot**
