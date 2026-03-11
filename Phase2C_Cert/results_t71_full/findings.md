# Phase 2C Certification Report

| Field | Value |
|-------|-------|
| Timestamp | 2026-03-02_16-48-00 |
| Gateway URL | https://n8n.halosparkai.com/webhook/nqxb/gateway/v1 |
| Workspace | be0d3a48-c764-44f9-90c8-e846d9dbbd0a |
| Gateway Version | v58 |
| Save Version | v37 |
| Update Version | v36 |

---

## Summary

| Metric | Count |
|--------|-------|
| Total Tests | 101 |
| Passed | 95 |
| Failed | 1 |
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
| 32 | D07 â€” T51 Journal Extension Update BLOCKED | PASS |  |
| 33 | D08 â€” T51 Snapshot Extension Update BLOCKED (immutability) | PASS |  |
| 34 | D09 â€” T51 Project Full-Replace Set (baseline for clear test) | PASS |  |
| 35 | D10 â€” T51 Project Full-Replace Clear (send summary only, expect state_reason NULL) | PASS |  |
| 36 | D11 â€” T51 Query Project After Full-Replace (verify reset) | PASS |  |
| 37 | D12 â€” T51 Create Instruction Pack for Immutability Test | PASS |  |
| 38 | D13 â€” T51 Instruction Pack Extension Update BLOCKED (immutability) | PASS |  |
| 39 | E01 â€” Limb INSERT (Phase 2 Walk Type) | PASS |  |
| 40 | E01 â€” T64 Create Branch for Spine-Field Tests | PASS |  |
| 41 | E02 â€” Leaf INSERT (Phase 2 Walk Type, Spine-Only) | PASS |  |
| 42 | E02 â€” T64 Create Limb for Spine-Field Tests | PASS |  |
| 43 | E03 â€” T64 Create Leaf for Spine-Field Tests | PASS |  |
| 44 | E04 â€” T64 Create Leaf 2 for Skip/Backward Tests | PASS |  |
| 45 | E05 â€” D01 Branch NULL to not_started | PASS |  |
| 46 | E06 â€” Limb NULL to not_started (D02 setup) | PASS |  |
| 47 | E07 â€” D02 Limb not_started to in_progress | PASS |  |
| 48 | E08 â€” Leaf NULL to not_started (D03 setup) | PASS |  |
| 49 | E09 â€” Leaf not_started to in_progress (D03 setup) | PASS |  |
| 50 | E10 â€” D03 Leaf in_progress to complete (no parent check) | PASS |  |
| 51 | E11 â€” D09 Limb in_progress to in_progress (NOOP) | PASS |  |
| 52 | E12 â€” D12 Leaf NULL to in_progress (skip rejection) | PASS |  |
| 53 | E13 â€” Leaf 2 NULL to not_started (D06 setup) | PASS |  |
| 54 | E14 â€” Leaf 2 not_started to in_progress (D06 setup) | PASS |  |
| 55 | E15 â€” D06 Leaf in_progress to not_started (backward rejection) | PASS |  |
| 56 | E16 â€” D07 Leaf complete to in_progress (terminal rejection) | PASS |  |
| 57 | E17 â€” Branch not_started to in_progress (D08 setup) | PASS |  |
| 58 | E18 â€” Branch in_progress to blocked (D08 setup) | PASS |  |
| 59 | E19 â€” D08 Branch blocked to complete (skip rejection) | PASS |  |
| 60 | F01 â€” Project QUERY without rollup flag (backward compat) | SKIP | Unresolved: KGB_PROJECT_ID |
| 61 | F02 â€” Project rollup with zero leaves | SKIP | Unresolved: KGB_PROJECT_ID |
| 62 | F03 â€” Project rollup with branches and leaves | PASS |  |
| 63 | F04 â€” Rollup flag on non-project type (ignored) | SKIP | Unresolved: KGB_SNAPSHOT_ID |
| 64 | F05 â€” Rollup with hydrate=false combination | SKIP | Unresolved: KGB_PROJECT_ID |
| 65 | F06 â€” T70 Create Project for Rollup Tests | PASS |  |
| 66 | F07 â€” T70 Create Branch (child of project) | PASS |  |
| 67 | F08 â€” T70 Create Leaf 1 (complete, child of branch) | PASS |  |
| 68 | F09 â€” T70 Create Leaf 2 (in_progress, child of branch) | PASS |  |
| 69 | F10 â€” T70 Create Leaf 3 (no execution_status, child of branch) | PASS |  |
| 70 | F11 â€” T70 Branch rollup (1/3 complete) | PASS |  |
| 71 | F12 â€” T70 Project rollup (0/1 branch complete) | PASS |  |
| 72 | F13 â€” T70 Update Leaf 2 to complete | PASS |  |
| 73 | F14 â€” T70 Branch rollup (2/3 complete) | PASS |  |
| 74 | F15a â€” T70 Leaf 3 NULL to not_started | PASS |  |
| 75 | F15b â€” T70 Leaf 3 not_started to in_progress | PASS |  |
| 76 | F15c â€” T70 Leaf 3 in_progress to complete | PASS |  |
| 77 | F16 â€” T70 Branch rollup (3/3 complete) | PASS |  |
| 78 | G01 â€” T71 Create Branch (non-leaf baseline) | PASS |  |
| 79 | G02 â€” T71 Create LEAF_A (dependency target) | PASS |  |
| 80 | G03 â€” T71 Create LEAF_B (depends on LEAF_A) | PASS |  |
| 81 | G04 â€” T71 MANUAL STEP: Insert dependency B depends on A | SKIP | Unresolved: T71_DEPENDENCY_INSERTED |
| 82 | G05 â€” T71 LEAF_B null to not_started | PASS |  |
| 83 | G06 â€” T71 LEAF_B not_started to in_progress | PASS |  |
| 84 | G07 â€” T71 LEAF_B in_progress to complete (BLOCKED â€” LEAF_A not complete) | FAIL | Expected ok=False, got ok=True; Expected error=DEPENDENCY_INCOMPLETE, got= |
| 85 | G08 â€” T71 LEAF_A null to not_started | PASS |  |
| 86 | G09 â€” T71 LEAF_A not_started to in_progress | PASS |  |
| 87 | G10 â€” T71 LEAF_A in_progress to complete (no dependency on A) | PASS |  |
| 88 | G11 â€” T71 LEAF_B in_progress to complete (UNBLOCKED â€” LEAF_A now complete) | PASS |  |
| 89 | G12 â€” T71 Create LEAF_C (no dependencies) | PASS |  |
| 90 | G13 â€” T71 LEAF_C null to not_started | PASS |  |
| 91 | G14 â€” T71 LEAF_C not_started to in_progress | PASS |  |
| 92 | G15 â€” T71 LEAF_C in_progress to complete (no dependencies â€” bypass) | PASS |  |
| 93 | G16 â€” T71 Branch null to not_started (non-leaf setup) | PASS |  |
| 94 | G17 â€” T71 Branch not_started to in_progress (non-leaf setup) | PASS |  |
| 95 | G18 â€” T71 Branch in_progress to complete (non-leaf â€” no dependency check) | PASS |  |
| 96 | VERIFY Journal (A01) [a2fb1646] | PASS |  |
| 97 | VERIFY Project (A04) [476ba506] | PASS |  |
| 98 | VERIFY Snapshot (A11) [80e12613] | PASS |  |
| 99 | VERIFY Restart (A13) [eee924cd] | PASS |  |
| 100 | VERIFY Fuzz Journal (B01) [1b4f2032] | PASS |  |
| 101 | VERIFY Fuzz Project (B02) [ee86e999] | PASS |  |

---

## Failures

- **G07 â€” T71 LEAF_B in_progress to complete (BLOCKED â€” LEAF_A not complete)**: Expected ok=False, got ok=True; Expected error=DEPENDENCY_INCOMPLETE, got=

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
| CHILD_JOURNAL_ID | `845e43c4-37d6-4256-8a7f-7cd0f4d07ed2` |
| D_IPACK_ID | `fbd7eb9c-2bbe-4439-a4e1-e8382640e952` |
| D_JOURNAL_ID | `ae6a95fe-3a55-488a-bd52-18456b5a0e89` |
| D_PROJECT_ID | `6813829e-80d3-4565-abef-cf4e6e1c6ede` |
| FUZZ_JOURNAL_ID | `1b4f2032-d656-44ae-84d3-a86c4ff625f0` |
| FUZZ_PROJECT_ID | `ee86e999-6719-46d5-8b1a-b516b8cf3beb` |
| JOURNAL_ID | `a2fb1646-e5e5-42df-a275-39220732480c` |
| LEAF_ID | `eddd1abc-569b-40c2-878f-cc9871325383` |
| LIMB_ID | `f4de2da7-9908-46b7-b022-a69c7f6ebec5` |
| PROJECT_ID | `476ba506-f0c7-49de-a29b-90f997831a79` |
| RESTART_ID | `eee924cd-ffaa-4a65-a0b2-79570bee41eb` |
| SNAPSHOT_ID | `80e12613-4f56-4463-bcc1-b8f335bf6894` |
| T64_BRANCH_ID | `a65cb4bf-cbb9-4245-bf51-105f22dae0ba` |
| T64_LEAF_ID | `7fa80f31-eeb6-4d49-9018-02968da43d5c` |
| T64_LEAF2_ID | `1f8b8a80-3585-428a-909f-31c541b60a33` |
| T64_LIMB_ID | `2536567b-f551-442f-aa8f-3c3470a64f5d` |
| T70_BRANCH_ID | `4a1d0d29-d43e-43e1-b3fb-72a1b1a17ad5` |
| T70_LEAF_1_ID | `0a701f07-acc6-46ac-b11e-1bc25a3147ec` |
| T70_LEAF_2_ID | `7ec305f2-2077-426e-9d8a-3114c8b4e615` |
| T70_LEAF_3_ID | `c02243c3-e3cf-4dd7-b9f0-6dbbc150cd26` |
| T70_PROJECT_ID | `f944e067-12a5-47ee-a9b2-7541a45d8b0e` |
| T71_BRANCH_ID | `685bb4ac-86a2-4c15-a840-b969fdb2d3f7` |
| T71_LEAF_A_ID | `bed2dbf0-58ff-4ee9-86bf-e3de7b95e061` |
| T71_LEAF_B_ID | `a783c6de-12ff-4fe0-b29c-b0db2f9180e9` |
| T71_LEAF_C_ID | `f197e857-a4fe-4b67-b8af-bb81097ef743` |

---

## Conclusion

**FAIL**

One or more tests failed. Review failures above for remediation.

