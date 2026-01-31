# Test Pack Quick Reference

## Gateway Telegram Test Pack v1
- **Artifact UUID:** `6e09ed13-cc95-4578-b8c7-d2239b23db0b`
- **Local File:** `docs/testing/Gateway_Telegram_Test_Pack_v1.md`
- **Created:** 2026-02-01
- **Retrieve via Telegram:** `Retrieve 6e09ed13-cc95-4578-b8c7-d2239b23db0b`

---

## Test Execution Log

### 2026-02-01 — Initial Run
| Test | Status | Notes |
|------|--------|-------|
| S1 | PASS | Project summary persists (BUG-012 verified) |
| S2 | PASS | Journal save works after empty UUID fix |
| S3 | PASS | Linked journal with parent_artifact_id (BUG-014 verified) |
| S4 | PASS | Snapshot save works |
| S5 | PASS | Restart save works after BUG-013 fix |
| S6 | FAIL | Instruction pack unique constraint (existing data) |
| L1 | PASS | List projects |
| L2 | PASS | List journals |
| L3 | FAIL | List ordering bug (limit query not sorting correctly) |
| L4 | PASS | List snapshots |
| L5 | PASS | List instruction packs |
| Q1 | FAIL | Retrieve context binds to wrong list type |
| Q2 | PASS | Retrieve by title |
| Q3 | PASS | Retrieve by UUID |
| P1 | PASS | Promote seed → sapling |
| P2 | PASS | Promote sapling → tree |
| P3 | PASS | Invalid promotion rejected |
| N1 | PASS | Invalid type rejected |
| N2 | PASS | Zero UUID rejected |
| N3 | PASS | Duplicate project rejected |

**Bugs Fixed This Session:**
- BUG-012: CLOSED (project summary)
- BUG-013: CLOSED (restart save)
- BUG-014: CLOSED (parent_artifact_id)
- S2 fix: Empty UUID → null normalization

**Remaining Issues:**
- L3: List ordering with limit
- Q1: Retrieve context binding
- S6: Instruction pack constraint (test data issue)
