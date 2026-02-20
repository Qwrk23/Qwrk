# Qwrk Snapshot — Gateway Query Contract + KG Proof Locked

**Timestamp:** 2026-01-04 (CST)  
**Snapshot Type:** Governance / Kernel Proof  
**Status:** Locked (post-execution)

---

## 1. Objective Completed
Lock the canonical **Gateway query semantics** and preserve a **KG proof** demonstrating `artifact.query` works end-to-end with real IDs and correct merging behavior.

---

## 2. What Changed (Canonical)
### A) KG Proof Added (artifact.query)
**File:** `docs/kg/KG_Proofs__Kernel_v1.md` (modified)  
**Section added:** `KG Proof — Gateway v1 artifact.query (KGB type)`  

**Proof includes:**
- Request payload using KGB workspace/user IDs
- Response payload showing merged **spine + extension** fields
- `artifact_id`: `668bd18f-4424-41e6-b2f9-393ecd2ec534` (KGB project)
- Timestamp: 2026-01-04
- Verified checklist:
  - Spine-first pattern
  - Type validation
  - Response merging
  - RLS enforcement

### B) Query Contract Created (separate from Write Contract)
**File:** `docs/contracts/Gateway_Query_Contract__v1.0__MVP.md` (new)

**Key content:**
- Request envelope: `gw_action`, `gw_workspace_id`, `gw_user_id`, `artifact_id`, `artifact_type`
- Allow-list types: `project`, `journal`, `snapshot`, `restart`
- Example request/response for project query
- Example `TYPE_MISMATCH` error response
- Spine-first architecture notes
- RLS enforcement notes
- KGB artifact IDs documented

### C) Write Contract Scope Clarified (no semantic change)
**File:** `docs/contracts/AAA_New_Qwrk__Gateway_Contract__v1.0__2026-01-03.md` (updated)

**Scope note added (2026-01-04):**
- This contract governs **artifact.save** (write semantics only).
- Query semantics are defined in `Gateway_Query_Contract__v1.0__MVP.md`.
- **No semantics changed**; clarification only.

---

## 3. Decisions Locked
1. **Contract split is canonical:**
   - Write semantics live in: `AAA_New_Qwrk__Gateway_Contract__v1.0__2026-01-03.md`
   - Query semantics live in: `Gateway_Query_Contract__v1.0__MVP.md`

2. **`artifact.query` is proven** via KG proof with real KGB IDs and merged spine+extension response.

3. **Allow-list for query types** (MVP):
   - `project`, `journal`, `snapshot`, `restart`

4. **RLS enforcement remains mandatory** for all query paths.

---

## 4. Files Created/Modified (Summary)
- Modified:
  - `docs/kg/KG_Proofs__Kernel_v1.md`
  - `docs/contracts/AAA_New_Qwrk__Gateway_Contract__v1.0__2026-01-03.md`
- Created:
  - `docs/contracts/Gateway_Query_Contract__v1.0__MVP.md`

---

## 5. Next Actions (Gated)
1. Push commits to origin (if not already pushed).
2. Use `Gateway_Query_Contract__v1.0__MVP.md` as the **authoritative source** for CustomGPT Actions schema for query.
3. When ready, add the next KG proof for `artifact.save` write path (if not already fully proven under the same standard).

---
