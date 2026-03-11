# Multi-User Qwrk — Test Checklist

**Created:** 2026-02-17
**Updated:** 2026-03-04 (T69 semantic type enforcement tests added)
**Purpose:** Deterministic verification checklist for all gateway clones.

---

## Pre-Test Requirements

- [ ] Gateway workflow imported and activated in n8n
- [ ] ACL row seeded in `qxb_gateway_acl` for this clone
- [ ] Basic Auth credential created in n8n
- [ ] `POWERSHELL_TEST_TEMPLATE.ps1` updated with real values
- [ ] Sub-workflows confirmed active (5/5)
- [ ] Gateway version: v59 era (T69 compliant)

---

## Isolated Tests (Per Gateway)

### {{Gateway_Name}} (e.g., Qwrk@Work_Joel)

| # | Test | Expected | Result | Notes |
|---|------|----------|--------|-------|
| 1 | Allowed workspace `artifact.list` | HTTP 200, `ok: true` | [ ] PASS / [ ] FAIL | |
| 2 | Wrong workspace `artifact.list` | HTTP 403, `WORKSPACE_FORBIDDEN` | [ ] PASS / [ ] FAIL | |
| 3 | Missing `gw_action` | `VALIDATION_ERROR` | [ ] PASS / [ ] FAIL | |

---

## Semantic Type Enforcement Tests (Per Gateway)

Run `TEST_Semantic_Type_Enforcement.ps1` with gateway-specific parameters.

### {{Gateway_Name}}

| # | Test | Expected | Result | Notes |
|---|------|----------|--------|-------|
| ST1 | Save project with `semantic_type_id` key | 200, `ok: true`, `artifact_id` returned | [ ] PASS / [ ] FAIL | Key resolved to UUID |
| ST2 | Save project with UUID passthrough | 200, `ok: true`, `artifact_id` returned | [ ] PASS / [ ] FAIL | |
| ST3 | Save project WITHOUT `semantic_type_id` | `VALIDATION_ERROR` or `SEMANTIC_TYPE_RESOLUTION_FAILED` | [ ] PASS / [ ] FAIL | |
| ST4 | Save branch WITH `semantic_type_id` | `VALIDATION_ERROR` | [ ] PASS / [ ] FAIL | Non-top-level type |
| ST5 | Save snapshot with invalid `semantic_type_id` | `INVALID_SEMANTIC_TYPE` or `SEMANTIC_TYPE_RESOLUTION_FAILED` | [ ] PASS / [ ] FAIL | |
| ST6 | Update `semantic_type_id` (dedicated path) | 200, `ok: true` | [ ] PASS / [ ] FAIL | Requires ST1 artifact |
| ST7 | Update `semantic_type_id` + tags combined | `MIXED_UPDATE_NOT_ALLOWED` | [ ] PASS / [ ] FAIL | Requires ST2 artifact |

---

## End-to-End Tests (At Least 1 Gateway)

Pick one gateway for full-cycle validation:

**Gateway:** ___________________

| # | Step | Action | Expected | Result |
|---|------|--------|----------|--------|
| 1 | Save | `artifact.save` test snapshot with `semantic_type_id` | HTTP 200, `artifact_id` returned | [ ] PASS / [ ] FAIL |
| 2 | List | `artifact.list` snapshots | Test artifact appears in list | [ ] PASS / [ ] FAIL |
| 3 | Query | `artifact.query` by returned ID | Content matches saved data, `semantic_type_id` present | [ ] PASS / [ ] FAIL |
| 4 | Tag Update | `artifact.update` tags on test artifact | Tags updated, version incremented | [ ] PASS / [ ] FAIL |

---

## Cross-Gateway Isolation Test

Verify that clones cannot access each other's workspaces:

| From Gateway | To Workspace | Expected | Result |
|-------------|-------------|----------|--------|
| Work_Joel | Personal (be0d3a48) | 403 | [ ] PASS / [ ] FAIL |
| Personal (Prime) | Work (635bb8d7) | 403 | [ ] PASS / [ ] FAIL |

---

## Production Regression Check

- [ ] Production gateway (`NQxb_Gateway_v1`) still active
- [ ] Production `artifact.list` returns expected results (Joel's personal workspace)
- [ ] No sub-workflow errors in n8n execution log

---

## Sign-Off

| Check | Status | Date |
|-------|--------|------|
| Gateway passes isolated tests (3/3) | [ ] | |
| Semantic type enforcement tests pass (7/7) | [ ] | |
| End-to-end test passes (4/4) | [ ] | |
| Cross-gateway isolation verified (2/2) | [ ] | |
| Production regression check passed (3/3) | [ ] | |
| **OVERALL: Ready for ChatGPT Project setup** | [ ] | |
