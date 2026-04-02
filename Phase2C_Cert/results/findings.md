# Phase 2C Certification Report

| Field | Value |
|-------|-------|
| Timestamp | 2026-04-01_14-38-22 |
| Gateway URL | https://n8n.halosparkai.com/webhook/nqxb/gateway/v2 |
| Workspace | be0d3a48-c764-44f9-90c8-e846d9dbbd0a |
| Gateway Version | v58 |
| Save Version | v37 |
| Update Version | v36 |

---

## Summary

| Metric | Count |
|--------|-------|
| Total Tests | 139 |
| Passed | 130 |
| Failed | 4 |
| Skipped | 5 |

---

## Results

| # | Test | Result | Notes |
|---|------|--------|-------|
| 1 | A01 â€” Journal INSERT Valid | PASS |  |
| 2 | A02 â€” Journal QUERY by ID | PASS |  |
| 3 | A03 â€” Journal TAG Update | PASS |  |
| 4 | A04 â€” Project INSERT (seed) | PASS |  |
| 5 | A05 â€” Project TAG Add | PASS |  |
| 6 | A06 â€” Project TAG Remove | PASS |  |
| 7 | A07 â€” Project Extension Update (state_reason) | PASS |  |
| 8 | A08 â€” Project Promote BLOCKED (seed not ready) | PASS |  |
| 9 | A09 â€” Add Linked Journal to Project | PASS |  |
| 10 | A10 â€” Project Promote ALLOWED (seed to sapling) | PASS |  |
| 11 | A11 â€” Snapshot INSERT Valid | PASS |  |
| 12 | A12 â€” Snapshot Extension Update BLOCKED (immutability) | PASS |  |
| 13 | A13 â€” Restart INSERT Valid | PASS |  |
| 14 | A14 â€” Restart Extension Update BLOCKED (immutability) | PASS |  |
| 15 | B01 â€” Fuzz: Stringified Extension (belt-and-suspenders recovery) | PASS |  |
| 16 | B02 â€” Fuzz: Tags as Comma String (normalizeTags recovery) | PASS |  |
| 17 | B03 â€” Fuzz: Unknown Extension Key (journal strict allowlist) | PASS |  |
| 18 | B04 â€” Fuzz: Missing Required Extension (snapshot without payload) | PASS |  |
| 19 | B05 â€” Fuzz: Unknown Gateway Action | PASS |  |
| 20 | B06 â€” Fuzz: Invalid UUID in Query | PASS |  |
| 21 | C01 â€” Promote: Invalid Transition Name | PASS |  |
| 22 | C02 â€” Promote: Missing Transition Field | PASS |  |
| 23 | C03 â€” Promote: Missing Reason Field | PASS |  |
| 24 | C04 â€” Promote: Lifecycle Mismatch (already sapling, request seed_to_sapling) | PASS |  |
| 25 | C05 â€” Promote: Non-promotable Type (journal) | PASS |  |
| 26 | D01 â€” T51 Create Project for Extension Tests | PASS |  |
| 27 | D02 â€” T51 Update Project Summary (full-replace) | PASS |  |
| 28 | D03 â€” T51 Query Project After Summary Update (hydrate) | PASS |  |
| 29 | D04 â€” T51 Project Unknown Extension Field REJECTED | PASS |  |
| 30 | D05 â€” T51 Project lifecycle_stage via Update REJECTED (PROMOTE_ONLY) | PASS |  |
| 31 | D06 â€” T51 Create Journal for Extension Tests | PASS |  |
| 32 | D07 - T51 Journal Extension Update BLOCKED (JOURNAL_INSERT_ONLY per T87) | PASS |  |
| 33 | D08 â€” T51 Snapshot Extension Update BLOCKED (immutability) | PASS |  |
| 34 | D09 â€” T51 Project Full-Replace Set (baseline for clear test) | PASS |  |
| 35 | D10 â€” T51 Project Full-Replace Clear (send summary only, expect state_reason NULL) | PASS |  |
| 36 | D11 â€” T51 Query Project After Full-Replace (verify reset) | PASS |  |
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
| 62 | E12 â€” D12 Leaf NULL to in_progress (skip rejection) | FAIL | Expected ok=False, got ok=True; Expected error=INVALID_TRANSITION, got= |
| 63 | E13 â€” Leaf 2 NULL to not_started (D06 setup) | FAIL | Expected ok=True, got ok=False |
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
| 75 | F06 â€” T70 Create Project for Rollup Tests | PASS |  |
| 76 | F07 â€” T70 Create Branch (child of project) | PASS |  |
| 77 | F08 â€” T70 Create Leaf 1 (complete, child of branch) | PASS |  |
| 78 | F09 â€” T70 Create Leaf 2 (in_progress, child of branch) | PASS |  |
| 79 | F10 â€” T70 Create Leaf 3 (no execution_status, child of branch) | PASS |  |
| 80 | F11 â€” T70 Branch rollup (1/3 complete) | PASS |  |
| 81 | F12 â€” T70 Project rollup (0/1 branch complete) | PASS |  |
| 82 | F13 â€” T70 Update Leaf 2 to complete | PASS |  |
| 83 | F14 â€” T70 Branch rollup (2/3 complete) | PASS |  |
| 84 | F15a â€” T70 Leaf 3 NULL to not_started | PASS |  |
| 85 | F15b â€” T70 Leaf 3 not_started to in_progress | PASS |  |
| 86 | F15c â€” T70 Leaf 3 in_progress to complete | PASS |  |
| 87 | F16 â€” T70 Branch rollup (3/3 complete) | PASS |  |
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
| 124 | H17c - T87 Update deleted artifact = NOT_FOUND | FAIL | Expected ok=False, got ok=True; Expected error=NOT_FOUND, got= |
| 125 | H18a - T87 Create project for lifecycle governance tests | PASS |  |
| 126 | H18b - T87 Promote seed to sapling | PASS |  |
| 127 | H18c - T87 Create branch child for QPM sapling-to-tree gate | PASS |  |
| 128 | H19 - T87 Promote sapling to tree | PASS |  |
| 129 | H20 - T87 Tree project title update = FIELD_FROZEN | PASS |  |
| 130 | H21 - T87 Tree project summary update allowed | PASS |  |
| 131 | H22 - T87 Promote tree to archive | PASS |  |
| 132 | H23 - T87 Archive project summary update = ARCHIVE_IMMUTABLE | PASS |  |
| 133 | H24 - T87 Archive project tags update = ARCHIVE_IMMUTABLE | PASS |  |
| 134 | VERIFY Journal (A01) [4879f0cc] | PASS |  |
| 135 | VERIFY Project (A04) [0789d55d] | PASS |  |
| 136 | VERIFY Snapshot (A11) [7210bcff] | PASS |  |
| 137 | VERIFY Restart (A13) [d72b66f6] | PASS |  |
| 138 | VERIFY Fuzz Journal (B01) [0568a874] | PASS |  |
| 139 | VERIFY Fuzz Project (B02) [72bbd1c1] | PASS |  |

---

## Failures

- **E12 â€” D12 Leaf NULL to in_progress (skip rejection)**: Expected ok=False, got ok=True; Expected error=INVALID_TRANSITION, got=
- **E13 â€” Leaf 2 NULL to not_started (D06 setup)**: Expected ok=True, got ok=False
- **G07 â€” T71 LEAF_B in_progress to complete (BLOCKED â€” LEAF_A not complete)**: Expected ok=False, got ok=True; Expected error=DEPENDENCY_INCOMPLETE, got=
- **H17c - T87 Update deleted artifact = NOT_FOUND**: Expected ok=False, got ok=True; Expected error=NOT_FOUND, got=

---

## Observations

- Journal (A01): version=2
- Project (A04): version=5
- Snapshot (A11): version=1
- Restart (A13): version=1
- Fuzz Journal (B01): version=1
- Fuzz Project (B02): version=1

---

## Captured Artifact IDs

| Variable | Value |
|----------|-------|
| CHILD_JOURNAL_ID | `d4c98006-45dd-4cfd-bafd-240eaffa0e19` |
| D_DS_PROJECT_ID | `759f9794-e495-44eb-aebb-538b4c9141c8` |
| D_IPACK_ID | `401a2f4a-0cc9-4f3a-9523-821098313219` |
| D_JOURNAL_ID | `1df1ac2e-d200-4709-8b5b-3880dee2c860` |
| D_PROJECT_ID | `e8857ca0-ad3e-4139-aeef-f28955fa153e` |
| FUZZ_JOURNAL_ID | `0568a874-b685-45cf-b500-d5ba61fcf23e` |
| FUZZ_PROJECT_ID | `72bbd1c1-b037-466f-80cf-9c6edd1054fc` |
| H_JOURNAL_ID | `7da58541-bc1c-4d63-a022-7064b5f3866e` |
| H_LIFE_PROJECT_ID | `b0db9b01-c94e-42f0-9eda-8e6532e1dfc0` |
| H_PROJECT_ID | `a90d775a-008a-49d9-be9a-1cbf95b68491` |
| H_SNAPSHOT_ID | `9d88dfb6-c16e-4b66-a63d-06834f325fe3` |
| H_TEMP_PROJECT_ID | `d017afa4-7e8d-4a85-9ea5-b516be0615c9` |
| JOURNAL_ID | `4879f0cc-6ac3-4e5c-b90a-71ddd1cbb20a` |
| LEAF_ID | `bb6a0d6d-ac67-47e5-b95b-faf6fcdca2d1` |
| LIMB_ID | `e2b2c56e-d64b-4c34-b2c4-e0c78b728355` |
| PROJECT_ID | `0789d55d-a140-4f2f-b28f-f186126e6ba5` |
| RESTART_ID | `d72b66f6-1139-4106-84bc-7b5e43b97426` |
| RUN_TAG | `run:cert-2026-04-01_14-38-22` |
| SNAPSHOT_ID | `7210bcff-6a24-4ecf-a13a-b0df5612af00` |
| T64_BRANCH_ID | `ef40c690-be74-4887-a064-f560a294b501` |
| T64_LEAF_ID | `cf789572-ae5e-4567-941a-313f8df689c7` |
| T64_LEAF2_ID | `6951d79e-6522-4fa1-9147-d5a49724aa6c` |
| T64_LIMB_ID | `2b2d9f79-7402-467d-af85-8fe5a3b79745` |
| T70_BRANCH_ID | `9a1a8db0-e1ca-4cfa-ad36-66ca159d148e` |
| T70_LEAF_1_ID | `4e04e2ca-7e16-4e8b-a8bb-56ef6cd29936` |
| T70_LEAF_2_ID | `ad4d3ff8-a90f-4441-8c72-1fd4c3706d8e` |
| T70_LEAF_3_ID | `f5ecab46-480a-4ce7-a2c0-384f235905b0` |
| T70_PROJECT_ID | `c97b815b-8d7e-4e9a-be1f-da3d69e02514` |
| T71_BRANCH_ID | `032e4dec-c307-431f-98ef-ca3545054ab8` |
| T71_LEAF_A_ID | `a7c605c8-bcb3-4555-b7e4-5e643c7ff190` |
| T71_LEAF_B_ID | `cee5d3f2-029d-4c38-8c76-f315cb63845c` |
| T71_LEAF_C_ID | `65f811fd-29ca-4dd0-9224-d8ac8ec6a020` |

---

## Conclusion

**FAIL**

One or more tests failed. Review failures above for remediation.

