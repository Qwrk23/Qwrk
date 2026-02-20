# Multi-User Qwrk — Test Checklist

**Created:** 2026-02-17
**Purpose:** Deterministic verification checklist for all 4 gateway clones.

---

## Pre-Test Requirements

- [ ] All 4 gateway workflows imported and activated in n8n
- [ ] All 4 ACL rows seeded in `qxb_gateway_acl`
- [ ] All 4 Basic Auth credentials created in n8n
- [ ] `POWERSHELL_TEST_TEMPLATE.ps1` updated with real values for each gateway
- [ ] Sub-workflows confirmed active (5/5)

---

## Isolated Tests (Per Gateway)

### Qwrk@Work_Joel

| # | Test | Expected | Result | Notes |
|---|------|----------|--------|-------|
| 1 | Allowed workspace `artifact.list` | HTTP 200, `ok: true` | [ ] PASS / [ ] FAIL | |
| 2 | Wrong workspace `artifact.list` | HTTP 403, `ACL_FORBIDDEN` or `WORKSPACE_FORBIDDEN` | [ ] PASS / [ ] FAIL | |
| 3 | Missing `gw_action` | `VALIDATION_ERROR` | [ ] PASS / [ ] FAIL | |

### Akara_Blagg

| # | Test | Expected | Result | Notes |
|---|------|----------|--------|-------|
| 1 | Allowed workspace `artifact.list` | HTTP 200, `ok: true` | [ ] PASS / [ ] FAIL | |
| 2 | Wrong workspace `artifact.list` | HTTP 403 | [ ] PASS / [ ] FAIL | |
| 3 | Missing `gw_action` | `VALIDATION_ERROR` | [ ] PASS / [ ] FAIL | |

### BlaggLife

| # | Test | Expected | Result | Notes |
|---|------|----------|--------|-------|
| 1 | Allowed workspace `artifact.list` | HTTP 200, `ok: true` | [ ] PASS / [ ] FAIL | |
| 2 | Wrong workspace `artifact.list` | HTTP 403 | [ ] PASS / [ ] FAIL | |
| 3 | Missing `gw_action` | `VALIDATION_ERROR` | [ ] PASS / [ ] FAIL | |

### Krista_Blagg

| # | Test | Expected | Result | Notes |
|---|------|----------|--------|-------|
| 1 | Allowed workspace `artifact.list` | HTTP 200, `ok: true` | [ ] PASS / [ ] FAIL | |
| 2 | Wrong workspace `artifact.list` | HTTP 403 | [ ] PASS / [ ] FAIL | |
| 3 | Missing `gw_action` | `VALIDATION_ERROR` | [ ] PASS / [ ] FAIL | |

---

## End-to-End Tests (At Least 1 Gateway)

Pick one gateway for full-cycle validation:

**Gateway:** ___________________

| # | Step | Action | Expected | Result |
|---|------|--------|----------|--------|
| 1 | Save | `artifact.save` test snapshot | HTTP 200, `artifact_id` returned | [ ] PASS / [ ] FAIL |
| 2 | List | `artifact.list` snapshots | Test artifact appears in list | [ ] PASS / [ ] FAIL |
| 3 | Query | `artifact.query` by returned ID | Content matches saved data | [ ] PASS / [ ] FAIL |

---

## Cross-Gateway Isolation Test

Verify that clones cannot access each other's workspaces:

| From Gateway | To Workspace | Expected | Result |
|-------------|-------------|----------|--------|
| Work_Joel | Akara's workspace | 403 | [ ] PASS / [ ] FAIL |
| Akara | Work's workspace | 403 | [ ] PASS / [ ] FAIL |
| BlaggLife | Krista's workspace | 403 | [ ] PASS / [ ] FAIL |
| Krista | BlaggLife workspace | 403 | [ ] PASS / [ ] FAIL |

---

## Production Regression Check

- [ ] Production gateway (`NQxb_Gateway_v1`) still active
- [ ] Production `artifact.list` returns expected results (Joel's personal workspace)
- [ ] No sub-workflow errors in n8n execution log

---

## Sign-Off

| Check | Status | Date |
|-------|--------|------|
| All 4 gateways pass isolated tests (12/12) | [ ] | |
| At least 1 gateway passes E2E test (3/3) | [ ] | |
| Cross-gateway isolation verified (4/4) | [ ] | |
| Production regression check passed (3/3) | [ ] | |
| **OVERALL: Ready for ChatGPT Project setup** | [ ] | |
