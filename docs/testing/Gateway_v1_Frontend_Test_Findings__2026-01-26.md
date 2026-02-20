# Gateway v1 Front-End Test Findings

**Date:** 2026-01-26
**System:** Qwrk Alpha (Gateway v1 — Full Access)
**Test Suite:** Prompt__ANQ_Gateway_Frontend_Test_Suite__2026-01-26.md
**Status:** Partial execution (blocked by critical findings)

---

## Summary

| ID | Test | Classification | Severity |
|----|------|----------------|----------|
| F001 | R2 | Gateway contract reality | Warning |
| F002 | W1 | Tooling / transport (schema) | **Critical** |
| F003 | W1 Retry | Tooling / transport (schema) | **Critical** |
| F004 | Pagination | Gateway contract reality | **Critical** |
| F005 | W12 | Gateway contract reality | **Critical** |

**Critical findings:** 4
**Warnings:** 1

---

## F001 — List response size not driven solely by hydrate flag

| Field | Value |
|-------|-------|
| **Test ID** | R2 |
| **Observed** | Even with `hydrate:false`, list responses can include large `content` objects. "hydrate" is not the only driver of payload size. |
| **Expected** | `hydrate:false` would significantly reduce payload size |
| **Classification** | Gateway contract reality |
| **Severity** | Warning |
| **Note** | Supports suspicion that "ResponseTooLargeError at limit 100" needs receipts to be verified |

---

## F002 — WRITE blocked by request-model kwargs rejection

| Field | Value |
|-------|-------|
| **Test ID** | W1 |
| **Observed** | Request-model rejected top-level fields: `tags`, `content`, `lifecycle_status`. Error: `UnrecognizedKwargsError: ('tags', 'content', 'lifecycle_status')`. Failure occurred BEFORE Gateway workflow (no `ok:false` envelope). |
| **Expected** | Payload accepted by Action schema, processed by Gateway |
| **Classification** | Tooling / transport limitation (Action schema mismatch) |
| **Severity** | **Critical** (blocks WRITE suite) |
| **Root Cause** | Schema/model mismatch at boundary — calling schema does not accept fields front-end is sending |
| **Impact** | CREATE payload shape not aligned with Action schema. WRITE suite blocked. |

---

## F003 — WRITE blocked by caller schema type validation (parent_artifact_id null)

| Field | Value |
|-------|-------|
| **Test ID** | W1 (Retry) |
| **Observed** | Payload included `parent_artifact_id: null`. Caller/tool schema rejected as non-string. Error: `ApiTypeError: Expected parent_artifact_id to be a str`. No Gateway envelope returned. |
| **Expected** | `null` accepted or field omission allowed |
| **Classification** | Tooling / transport limitation (Action schema type constraint) |
| **Severity** | **Critical** (blocks WRITE suite) |
| **Root Cause** | Caller schema defines `parent_artifact_id` as `string` (not nullable). Must omit entirely or provide valid UUID. |
| **Impact** | CREATE payloads cannot include `null` values for optional parent fields. |

---

## F004 — Pagination offset ignored (repeat page across offsets) + ResponseTooLarge at limit=50

| Field | Value |
|-------|-------|
| **Test ID** | Pagination (implicit R-series / W-series verification) |
| **Observed** | 1) `limit=50, offset=0, hydrate=false` → `ResponseTooLargeError` (no payload). 2) Retried with `limit=10` at offsets 0/10/20 — all three returned **identical results** (same first `artifact_id: 58b8d15a-70c1-44ea-9e3c-3000e81d2607`, same artifact set). Offset appears ignored/overwritten. |
| **Expected** | Different result sets for different offset values; pagination advances through dataset |
| **Classification** | **Gateway contract reality** (fundamental pagination violation) |
| **Severity** | **Critical** |
| **Impact** | Cannot page through artifacts. Cannot locate newly created TEST Project. `meta.has_more` + pagination behavior untrustworthy. Blocks WRITE-phase verification. |

---

## F005 — Invalid promote yields internal resolver error + leaks artifact fields

| Field | Value |
|-------|-------|
| **Test ID** | W12 (invalid promote negative test) |
| **Observed** | Transition `tree_to_tree` (invalid) returned `ok:false` with `error.code: FROM_STATE_MISSING`, `error.message: "from_state missing after Resolve_Transition."`, `error.details.from_state: null`. Additionally, artifact fields leaked at top level of error response (workspace_id, owner_user_id, title, summary, lifecycle_status, etc.). |
| **Expected** | Deterministic validation error like `LIFECYCLE_TRANSITION_NOT_ALLOWED` with clean error envelope |
| **Classification** | **Gateway contract reality** (error semantics bug + potential data leakage) |
| **Severity** | **Critical** |
| **Impact** | Error codes not stable/semantic for invalid promotions. Client-side error handling unreliable. Unintended data exposure in error responses. |
| **Security Note** | Error envelope leaks artifact fields on `_gw_route: "error"` responses. |

---

## Next Steps

1. **F002/F003 (Schema):** Review and update `Qwrk_Gateway_v1_Actions_Schema.yaml` to align with actual Gateway expectations
2. **F004 (Pagination):** Investigate `NQxb_Artifact_List_v1` workflow — offset not being applied to Supabase query
3. **F005 (Promote):** Fix `Resolve_Transition` to return proper validation error for unknown transitions; sanitize error envelope

---

*Findings captured during Qwrk Alpha validation — 2026-01-26*
