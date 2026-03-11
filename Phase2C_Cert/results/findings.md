# Phase 2C Certification Report

| Field | Value |
|-------|-------|
| Timestamp | 2026-03-06_06-18-52 |
| Gateway URL | https://n8n.halosparkai.com/webhook/nqxb/gateway/v1 |
| Workspace | be0d3a48-c764-44f9-90c8-e846d9dbbd0a |
| Gateway Version | v58 |
| Save Version | v37 |
| Update Version | v36 |

---

## Summary

| Metric | Count |
|--------|-------|
| Total Tests | 133 |
| Passed | 82 |
| Failed | 10 |
| Skipped | 41 |

---

## Results

| # | Test | Result | Notes |
|---|------|--------|-------|
| 1 | A01 â€” Journal INSERT Valid | FAIL | Expected ok=True, got ok=False |
| 2 | A02 â€” Journal QUERY by ID | SKIP | Unresolved: JOURNAL_ID |
| 3 | A03 â€” Journal TAG Update | SKIP | Unresolved: JOURNAL_ID |
| 4 | A04 â€” Project INSERT (seed) | FAIL | Expected ok=True, got ok=False |
| 5 | A05 â€” Project TAG Add | SKIP | Unresolved: PROJECT_ID |
| 6 | A06 â€” Project TAG Remove | SKIP | Unresolved: PROJECT_ID |
| 7 | A07 â€” Project Extension Update (state_reason) | SKIP | Unresolved: PROJECT_ID |
| 8 | A08 â€” Project Promote BLOCKED (seed not ready) | SKIP | Unresolved: PROJECT_ID |
| 9 | A09 â€” Add Linked Journal to Project | SKIP | Unresolved: PROJECT_ID |
| 10 | A10 â€” Project Promote ALLOWED (seed to sapling) | SKIP | Unresolved: PROJECT_ID |
| 11 | A11 â€” Snapshot INSERT Valid | FAIL | Expected ok=True, got ok=False |
| 12 | A12 â€” Snapshot Extension Update BLOCKED (immutability) | SKIP | Unresolved: SNAPSHOT_ID |
| 13 | A13 â€” Restart INSERT Valid | FAIL | Expected ok=True, got ok=False |
| 14 | A14 â€” Restart Extension Update BLOCKED (immutability) | SKIP | Unresolved: RESTART_ID |
| 15 | B01 â€” Fuzz: Stringified Extension (belt-and-suspenders recovery) | FAIL | Expected ok=True, got ok=False |
| 16 | B02 â€” Fuzz: Tags as Comma String (normalizeTags recovery) | FAIL | Expected ok=True, got ok=False |
| 17 | B03 â€” Fuzz: Unknown Extension Key (journal strict allowlist) | PASS |  |
| 18 | B04 â€” Fuzz: Missing Required Extension (snapshot without payload) | PASS |  |
| 19 | B05 â€” Fuzz: Unknown Gateway Action | PASS |  |
| 20 | B06 â€” Fuzz: Invalid UUID in Query | PASS |  |
| 21 | C01 â€” Promote: Invalid Transition Name | SKIP | Unresolved: PROJECT_ID |
| 22 | C02 â€” Promote: Missing Transition Field | SKIP | Unresolved: PROJECT_ID |
| 23 | C03 â€” Promote: Missing Reason Field | SKIP | Unresolved: PROJECT_ID |
| 24 | C04 â€” Promote: Lifecycle Mismatch (already sapling, request seed_to_sapling) | SKIP | Unresolved: PROJECT_ID |
| 25 | C05 â€” Promote: Non-promotable Type (journal) | SKIP | Unresolved: JOURNAL_ID |
| 26 | D01 â€” T51 Create Project for Extension Tests | FAIL | Expected ok=True, got ok=False |
| 27 | D02 â€” T51 Update Project Summary (full-replace) | SKIP | Unresolved: D_PROJECT_ID |
| 28 | D03 â€” T51 Query Project After Summary Update (hydrate) | SKIP | Unresolved: D_PROJECT_ID |
| 29 | D04 â€” T51 Project Unknown Extension Field REJECTED | SKIP | Unresolved: D_PROJECT_ID |
| 30 | D05 â€” T51 Project lifecycle_stage via Update REJECTED (PROMOTE_ONLY) | SKIP | Unresolved: D_PROJECT_ID |
| 31 | D06 â€” T51 Create Journal for Extension Tests | FAIL | Expected ok=True, got ok=False |
| 32 | D07 - T51 Journal Extension Update BLOCKED (JOURNAL_INSERT_ONLY per T87) | SKIP | Unresolved: D_JOURNAL_ID |
| 33 | D08 â€” T51 Snapshot Extension Update BLOCKED (immutability) | SKIP | Unresolved: SNAPSHOT_ID |
| 34 | D09 â€” T51 Project Full-Replace Set (baseline for clear test) | SKIP | Unresolved: D_PROJECT_ID |
| 35 | D10 â€” T51 Project Full-Replace Clear (send summary only, expect state_reason NULL) | SKIP | Unresolved: D_PROJECT_ID |
| 36 | D11 â€” T51 Query Project After Full-Replace (verify reset) | SKIP | Unresolved: D_PROJECT_ID |
| 37 | D12 â€” T51 Create Instruction Pack for Immutability Test | PASS |  |
| 38 | D13 â€” T51 Instruction Pack Extension Update BLOCKED (immutability) | PASS |  |
| 39 | D20a - T87 Create project for design_spine tests | PASS |  |
| 40 | D20 - T87 Update design_spine.problem on seed project | PASS |  |
| 41 | D20c - T87 Restore summary via spine update (QPM setup) | PASS |  |
| 42 | D20d - T87 Promote seed to sapling (design_spine setup) | PASS |  |
| 43 | D21 - T87 Update design_spine.hypothesis on sapling project | PASS |  |
| 44 | D21b - T87 Create branch child for QPM gate (design_spine) | PASS |  |
| 45 | D21c - T87 Promote sapling to tree (design_spine setup) | PASS |  |
| 46 | D22 - T87 Update design_spine.constraints on tree project | PASS |  |
| 47 | D22b - T87 Promote tree to archive (design_spine setup) | PASS |  |
| 48 | D23 - T87 Update design_spine on archive project = ARCHIVE_IMMUTABLE | PASS |  |
| 49 | E01 â€” Limb INSERT (Phase 2 Walk Type) | PASS |  |
| 50 | E01 â€” T64 Create Branch for Spine-Field Tests | PASS |  |
| 51 | E02 â€” Leaf INSERT (Phase 2 Walk Type, Spine-Only) | PASS |  |
| 52 | E02 â€” T64 Create Limb for Spine-Field Tests | PASS |  |
| 53 | E03 â€” T64 Create Leaf for Spine-Field Tests | PASS |  |
| 54 | E04 â€” T64 Create Leaf 2 for Skip/Backward Tests | PASS |  |
| 55 | E05 â€” D01 Branch NULL to not_started | PASS |  |
| 56 | E06 â€” Limb NULL to not_started (D02 setup) | PASS |  |
| 57 | E07 â€” D02 Limb not_started to in_progress | PASS |  |
| 58 | E08 â€” Leaf NULL to not_started (D03 setup) | PASS |  |
| 59 | E09 â€” Leaf not_started to in_progress (D03 setup) | PASS |  |
| 60 | E10 â€” D03 Leaf in_progress to complete (no parent check) | PASS |  |
| 61 | E11 â€” D09 Limb in_progress to in_progress (NOOP) | PASS |  |
| 62 | E12 â€” D12 Leaf NULL to in_progress (skip rejection) | PASS |  |
| 63 | E13 â€” Leaf 2 NULL to not_started (D06 setup) | PASS |  |
| 64 | E14 â€” Leaf 2 not_started to in_progress (D06 setup) | PASS |  |
| 65 | E15 â€” D06 Leaf in_progress to not_started (backward rejection) | PASS |  |
| 66 | E16 â€” D07 Leaf complete to in_progress (terminal rejection) | PASS |  |
| 67 | E17 â€” Branch not_started to in_progress (D08 setup) | PASS |  |
| 68 | E18 â€” Branch in_progress to blocked (D08 setup) | PASS |  |
| 69 | E19 â€” D08 Branch blocked to complete (skip rejection) | PASS |  |
| 70 | F01 â€” Project QUERY without rollup flag (backward compat) | SKIP | Unresolved: KGB_PROJECT_ID |
| 71 | F02 â€” Project rollup with zero leaves | SKIP | Unresolved: KGB_PROJECT_ID |
| 72 | F03 â€” Project rollup with branches and leaves | PASS |  |
| 73 | F04 â€” Rollup flag on non-project type (ignored) | SKIP | Unresolved: KGB_SNAPSHOT_ID |
| 74 | F05 â€” Rollup with hydrate=false combination | SKIP | Unresolved: KGB_PROJECT_ID |
| 75 | F06 â€” T70 Create Project for Rollup Tests | FAIL | Expected ok=True, got ok=False |
| 76 | F07 â€” T70 Create Branch (child of project) | SKIP | Unresolved: T70_PROJECT_ID |
| 77 | F08 â€” T70 Create Leaf 1 (complete, child of branch) | SKIP | Unresolved: T70_BRANCH_ID |
| 78 | F09 â€” T70 Create Leaf 2 (in_progress, child of branch) | SKIP | Unresolved: T70_BRANCH_ID |
| 79 | F10 â€” T70 Create Leaf 3 (no execution_status, child of branch) | SKIP | Unresolved: T70_BRANCH_ID |
| 80 | F11 â€” T70 Branch rollup (1/3 complete) | SKIP | Unresolved: T70_BRANCH_ID |
| 81 | F12 â€” T70 Project rollup (0/1 branch complete) | SKIP | Unresolved: T70_PROJECT_ID |
| 82 | F13 â€” T70 Update Leaf 2 to complete | SKIP | Unresolved: T70_LEAF_2_ID |
| 83 | F14 â€” T70 Branch rollup (2/3 complete) | SKIP | Unresolved: T70_BRANCH_ID |
| 84 | F15a â€” T70 Leaf 3 NULL to not_started | SKIP | Unresolved: T70_LEAF_3_ID |
| 85 | F15b â€” T70 Leaf 3 not_started to in_progress | SKIP | Unresolved: T70_LEAF_3_ID |
| 86 | F15c â€” T70 Leaf 3 in_progress to complete | SKIP | Unresolved: T70_LEAF_3_ID |
| 87 | F16 â€” T70 Branch rollup (3/3 complete) | SKIP | Unresolved: T70_BRANCH_ID |
| 88 | G01 â€” T71 Create Branch (non-leaf baseline) | PASS |  |
| 89 | G02 â€” T71 Create LEAF_A (dependency target) | PASS |  |
| 90 | G03 â€” T71 Create LEAF_B (depends on LEAF_A) | PASS |  |
| 91 | G04 â€” T71 MANUAL STEP: Insert dependency B depends on A | SKIP | Unresolved: T71_DEPENDENCY_INSERTED |
| 92 | G05 â€” T71 LEAF_B null to not_started | PASS |  |
| 93 | G06 â€” T71 LEAF_B not_started to in_progress | PASS |  |
| 94 | G07 â€” T71 LEAF_B in_progress to complete (BLOCKED â€” LEAF_A not complete) | FAIL | Expected ok=False, got ok=True; Expected error=DEPENDENCY_INCOMPLETE, got= |
| 95 | G08 â€” T71 LEAF_A null to not_started | PASS |  |
| 96 | G09 â€” T71 LEAF_A not_started to in_progress | PASS |  |
| 97 | G10 â€” T71 LEAF_A in_progress to complete (no dependency on A) | PASS |  |
| 98 | G11 â€” T71 LEAF_B in_progress to complete (UNBLOCKED â€” LEAF_A now complete) | PASS |  |
| 99 | G12 â€” T71 Create LEAF_C (no dependencies) | PASS |  |
| 100 | G13 â€” T71 LEAF_C null to not_started | PASS |  |
| 101 | G14 â€” T71 LEAF_C not_started to in_progress | PASS |  |
| 102 | G15 â€” T71 LEAF_C in_progress to complete (no dependencies â€” bypass) | PASS |  |
| 103 | G16 â€” T71 Branch null to not_started (non-leaf setup) | PASS |  |
| 104 | G17 â€” T71 Branch not_started to in_progress (non-leaf setup) | PASS |  |
| 105 | G18 â€” T71 Branch in_progress to complete (non-leaf â€” no dependency check) | PASS |  |
| 106 | H01 - T87 Create Project for spine testing | PASS |  |
| 107 | H02 - T87 Spine-only update (summary) | PASS |  |
| 108 | H03 - T87 Spine-only update (title) | PASS |  |
| 109 | H04 - T87 Spine-only update (priority) | PASS |  |
| 110 | H05 - T87 Mixed update (summary + tags) | PASS |  |
| 111 | H06 - T87 Mixed update (title + priority + tags) | PASS |  |
| 112 | H07 - T87 Extension + spine = MIXED_UPDATE_NOT_ALLOWED | PASS |  |
| 113 | H08 - T87 Extension + tags = MIXED_UPDATE_NOT_ALLOWED | PASS |  |
| 114 | H09 - T87 Create Journal for immutability test | PASS |  |
| 115 | H10 - T87 Journal extension update = JOURNAL_INSERT_ONLY | PASS |  |
| 116 | H11 - T87 Create Snapshot for immutability test | PASS |  |
| 117 | H12 - T87 Snapshot extension update = IMMUTABILITY_ERROR | PASS |  |
| 118 | H13 - T87 Query project to verify spine updates persisted | PASS |  |
| 119 | H14 - T87 Tags-only update (regression) | PASS |  |
| 120 | H15 - T87 Extension-only update (regression) | PASS |  |
| 121 | H16 - T87 Empty update rejected (no spine/tags/extension) | PASS |  |
| 122 | H17a - T87 Create temp project for delete test | PASS |  |
| 123 | H17b - T87 Soft-delete temp project | PASS |  |
| 124 | H17c - T87 Update deleted artifact = NOT_FOUND | PASS |  |
| 125 | H18a - T87 Create project for lifecycle governance tests | PASS |  |
| 126 | H18b - T87 Promote seed to sapling | PASS |  |
| 127 | H18c - T87 Create branch child for QPM sapling-to-tree gate | PASS |  |
| 128 | H19 - T87 Promote sapling to tree | PASS |  |
| 129 | H20 - T87 Tree project title update = FIELD_FROZEN | PASS |  |
| 130 | H21 - T87 Tree project summary update allowed | PASS |  |
| 131 | H22 - T87 Promote tree to archive | PASS |  |
| 132 | H23 - T87 Archive project summary update = ARCHIVE_IMMUTABLE | PASS |  |
| 133 | H24 - T87 Archive project tags update = ARCHIVE_IMMUTABLE | PASS |  |

---

## Failures

- **A01 â€” Journal INSERT Valid**: Expected ok=True, got ok=False
- **A04 â€” Project INSERT (seed)**: Expected ok=True, got ok=False
- **A11 â€” Snapshot INSERT Valid**: Expected ok=True, got ok=False
- **A13 â€” Restart INSERT Valid**: Expected ok=True, got ok=False
- **B01 â€” Fuzz: Stringified Extension (belt-and-suspenders recovery)**: Expected ok=True, got ok=False
- **B02 â€” Fuzz: Tags as Comma String (normalizeTags recovery)**: Expected ok=True, got ok=False
- **D01 â€” T51 Create Project for Extension Tests**: Expected ok=True, got ok=False
- **D06 â€” T51 Create Journal for Extension Tests**: Expected ok=True, got ok=False
- **F06 â€” T70 Create Project for Rollup Tests**: Expected ok=True, got ok=False
- **G07 â€” T71 LEAF_B in_progress to complete (BLOCKED â€” LEAF_A not complete)**: Expected ok=False, got ok=True; Expected error=DEPENDENCY_INCOMPLETE, got=

---

## Observations

None.

---

## Captured Artifact IDs

| Variable | Value |
|----------|-------|
| D_DS_PROJECT_ID | `6b682c50-3e8c-4259-9eb7-c2f28468df2f` |
| D_IPACK_ID | `fb410902-7394-497c-bb0a-8bac3f039d8d` |
| H_JOURNAL_ID | `2c05c94e-3219-4026-9357-fa14c4ee809b` |
| H_LIFE_PROJECT_ID | `e21e5f01-b980-4bff-b929-d0b266e87fc7` |
| H_PROJECT_ID | `f187efc8-f58c-4980-9d51-387ae7b00253` |
| H_SNAPSHOT_ID | `0f1d3534-19e0-48d7-9999-1820ff0d0c58` |
| H_TEMP_PROJECT_ID | `7e8d6a67-3c70-40ba-b9c8-db9d795f9faa` |
| LEAF_ID | `f9443837-9b76-4e1d-b5e2-9cfacba97f54` |
| LIMB_ID | `c3326dd7-020c-43fa-b186-c2588e3956de` |
| T64_BRANCH_ID | `35712bd8-4ce2-46f7-9374-9c1650d8c57e` |
| T64_LEAF_ID | `b458b5d5-fbe2-4d57-a328-e542e582fcef` |
| T64_LEAF2_ID | `d9b46737-342a-4fb5-b893-006f233aa0aa` |
| T64_LIMB_ID | `8f785f12-78aa-4511-988b-692c9d7ad8da` |
| T71_BRANCH_ID | `c39410c8-ac83-4136-937b-9afdfe0ff5f8` |
| T71_LEAF_A_ID | `7634d9d5-51a2-438c-835f-9c303e870b30` |
| T71_LEAF_B_ID | `f71c65b9-0a9d-4131-9b0c-9f10ac52650f` |
| T71_LEAF_C_ID | `f9041b2c-871e-4e7a-a0ee-e207cac972f0` |

---

## Conclusion

**FAIL**

One or more tests failed. Review failures above for remediation.

