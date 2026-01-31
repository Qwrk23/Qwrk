# Gateway Telegram Test Pack v1

**Version:** 1.0
**Date:** 2026-02-01
**Status:** Active
**Scope:** Gateway v1 via Telegram Interface — Full Regression Suite

---

## 1. Purpose

This document defines a repeatable test suite for validating Gateway v1 operations through the Telegram interface. It adapts the PowerShell-based Gateway_Test_Pack_v1 for natural language testing.

**Use this pack:**
- After deploying Telegram workflow changes
- To validate AI Agent correctly interprets user intent
- To verify end-to-end data persistence
- To diagnose Telegram-specific payload issues

---

## 2. Prerequisites

| Requirement | Details |
|-------------|---------|
| Telegram Bot | Qwrk Telegram bot configured and active |
| n8n Workflow | `NQxb_Gateway_Telegram_v1` deployed |
| CC Read Access | Query script for verification: `phase1.5-chat-gateway/scripts/Query-Supabase.ps1` |
| Workspace | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` (Master Joel Workspace) |

---

## 3. Test Execution Pattern

For each test:
1. **Send** the natural language prompt to Telegram
2. **Record** the Telegram response (artifact_id if save/promote)
3. **Verify** via database query that data persisted correctly
4. **Mark** pass/fail based on both response AND database state

---

## 4. Test Matrix — artifact.save

### S1: Save Project with Summary
**Prompt:**
```
Save project titled "TG-TEST-S1 Project Save": This project tests that summary content persists correctly via Telegram.
```

**Expected Telegram Response:** Confirmation with artifact_id

**Verification Query:**
```powershell
Query-Supabase -Table qxb_artifact -Filter "title=ilike.*TG-TEST-S1*" -Select "artifact_id,title,summary,lifecycle_status"
```

**Pass Criteria:**
- [ ] Telegram returns artifact_id
- [ ] `summary` field contains the content after the colon
- [ ] `lifecycle_status` = "seed"

---

### S2: Save Journal with Content
**Prompt:**
```
Save journal titled "TG-TEST-S2 Journal Save": This journal tests that entry_text persists correctly via Telegram.
```

**Expected Telegram Response:** Confirmation with artifact_id

**Verification Query:**
```powershell
Query-Supabase -Table qxb_artifact_journal -Filter "artifact_id=eq.[UUID]" -Select "artifact_id,entry_text"
```

**Pass Criteria:**
- [ ] Telegram returns artifact_id
- [ ] `entry_text` field contains the content after the colon

---

### S3: Save Journal with Parent Link
**Prompt:**
```
Save journal titled "TG-TEST-S3 Linked Journal": This journal should link to its parent. Link to parent [S1_ARTIFACT_ID]
```

**Expected Telegram Response:** Confirmation with artifact_id

**Verification Query:**
```powershell
Query-Supabase -Table qxb_artifact -Filter "title=ilike.*TG-TEST-S3*" -Select "artifact_id,title,parent_artifact_id"
```

**Pass Criteria:**
- [ ] Telegram returns artifact_id
- [ ] `parent_artifact_id` = S1's artifact_id

---

### S4: Save Snapshot
**Prompt:**
```
Save snapshot titled "TG-TEST-S4 Snapshot Save": This snapshot tests payload persistence via Telegram.
```

**Expected Telegram Response:** Confirmation with artifact_id

**Verification Query:**
```powershell
Query-Supabase -Table qxb_artifact_snapshot -Filter "artifact_id=eq.[UUID]" -Select "artifact_id,payload"
```

**Pass Criteria:**
- [ ] Telegram returns artifact_id
- [ ] `payload.body` contains the content

---

### S5: Save Restart
**Prompt:**
```
Save restart titled "TG-TEST-S5 Restart Save": This restart tests context persistence via Telegram.
```

**Expected Telegram Response:** Error OR Success (BUG-013 status)

**Pass Criteria:**
- [ ] Document current behavior (may fail per BUG-013)

---

### S6: Save Instruction Pack
**Prompt:**
```
Save instruction pack titled "TG-TEST-S6 Instruction Pack": These are test instructions for the pack.
```

**Expected Telegram Response:** Confirmation with artifact_id

**Pass Criteria:**
- [ ] Telegram returns artifact_id
- [ ] Extension fields populated correctly

---

## 5. Test Matrix — artifact.list

### L1: List Projects
**Prompt:**
```
List projects
```

**Pass Criteria:**
- [ ] Returns numbered list of projects
- [ ] No duplicate save operations triggered

---

### L2: List Journals
**Prompt:**
```
List journals
```

**Pass Criteria:**
- [ ] Returns numbered list of journals
- [ ] Owner-only filtering respected

---

### L3: List with Limit
**Prompt:**
```
List the last 5 projects
```

**Pass Criteria:**
- [ ] Returns at most 5 projects
- [ ] Ordered by created_at desc

---

### L4: List Snapshots
**Prompt:**
```
List snapshots
```

**Pass Criteria:**
- [ ] Returns snapshot list

---

### L5: List Instruction Packs
**Prompt:**
```
List instruction packs
```

**Pass Criteria:**
- [ ] Returns instruction pack list

---

## 6. Test Matrix — artifact.query (Retrieve)

### Q1: Retrieve by Number
**Prompt (after L1):**
```
Retrieve 1
```

**Pass Criteria:**
- [ ] Returns full details of first item from previous list
- [ ] No duplicate save triggered

---

### Q2: Retrieve by Title
**Prompt:**
```
Retrieve the project "TG-TEST-S1 Project Save"
```

**Pass Criteria:**
- [ ] Returns matching artifact details
- [ ] Hydrated fields included

---

### Q3: Retrieve by UUID
**Prompt:**
```
Get artifact [KNOWN_UUID]
```

**Pass Criteria:**
- [ ] Returns artifact details
- [ ] Type correctly identified

---

## 7. Test Matrix — artifact.promote

### P1: Promote Seed to Sapling
**Prompt:**
```
Promote [S1_ARTIFACT_ID] to sapling
```

**Verification Query:**
```powershell
Query-Supabase -Table qxb_artifact -Filter "artifact_id=eq.[UUID]" -Select "artifact_id,lifecycle_status"
```

**Pass Criteria:**
- [ ] Telegram confirms promotion
- [ ] `lifecycle_status` = "sapling" in database

---

### P2: Promote Sapling to Tree
**Prompt:**
```
Promote [S1_ARTIFACT_ID] to tree
```

**Pass Criteria:**
- [ ] Telegram confirms promotion
- [ ] `lifecycle_status` = "tree" in database

---

### P3: Invalid Promotion (Skip Stage)
**Prompt:**
```
Promote [SEED_UUID] to tree
```

**Pass Criteria:**
- [ ] Telegram returns error about invalid transition
- [ ] Database unchanged

---

## 8. Test Matrix — artifact.update

### U1: Update Project State
**Prompt:**
```
Update project [UUID] to paused state
```

**Pass Criteria:**
- [ ] Document current behavior (Tool_Update may not exist)

---

## 9. Negative Tests

### N1: Save with Invalid Type
**Prompt:**
```
Save foo titled "Invalid Type Test": This should fail.
```

**Pass Criteria:**
- [ ] Error returned about invalid artifact type

---

### N2: Retrieve Non-Existent
**Prompt:**
```
Retrieve 00000000-0000-0000-0000-000000000000
```

**Pass Criteria:**
- [ ] Error returned about not found

---

### N3: Duplicate Detection
**Prompt (send twice):**
```
Save project titled "TG-TEST-N3 Duplicate Check": Testing duplicate detection.
```

**Verification:**
```powershell
Query-Supabase -Table qxb_artifact -Filter "title=ilike.*TG-TEST-N3*" -Select "artifact_id,title,created_at"
```

**Pass Criteria:**
- [ ] Count how many records created
- [ ] Document if duplicates occur

---

## 10. Regression Checklist (Minimum)

Run these before/after any Telegram workflow change:

**Critical Path:**
- [ ] S1: Save project with summary
- [ ] S2: Save journal with content
- [ ] S3: Save journal with parent link
- [ ] L1: List projects
- [ ] Q1: Retrieve by number
- [ ] P1: Promote seed to sapling

**Bug Verification:**
- [ ] BUG-012: Project summary persists
- [ ] BUG-014: Parent artifact link persists

---

## 11. Test Cleanup

After testing, soft-delete test artifacts:

```sql
UPDATE qxb_artifact
SET deleted_at = NOW()
WHERE title LIKE 'TG-TEST-%'
AND deleted_at IS NULL;
```

---

## 12. Pass/Fail Criteria

### Test PASSES when:
- Telegram returns expected response
- Database query confirms correct data persistence
- No duplicates created
- No unexpected errors

### Test FAILS when:
- Telegram returns error for happy-path test
- Database shows missing/incorrect data
- Duplicates created on single operation
- Wrong action triggered

---

## 13. Known Limitations

| Area | Limitation | Bug |
|------|------------|-----|
| Restart save | May fail with schema mismatch | BUG-013 |
| Update | No Tool_Update in Telegram | Feature gap |
| Promotion validation | No content requirements enforced | BUG-015 |

---

## 14. Changelog

### v1.0 — 2026-02-01
- Initial version adapted from Gateway_Test_Pack_v1
- Added Telegram-specific prompts
- Added database verification steps
- Added BUG-012, BUG-014 regression checks

---

**End of Gateway Telegram Test Pack v1**
