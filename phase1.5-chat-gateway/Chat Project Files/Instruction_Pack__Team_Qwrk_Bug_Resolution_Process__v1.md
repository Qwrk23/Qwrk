# Instruction Pack — Team Qwrk Bug Resolution Process (v1.1)

**scope:** `global`
**pack_version:** `v1.1`
**status:** Active
**created:** 2026-03-29
**origin:** Standing operating protocol for production and production-adjacent bug resolution across all Qwrk system surfaces

---

## Purpose

Define a governed, enforceable, reusable process for resolving production and production-adjacent bugs affecting Gateway workflows, sub-workflows, schema/contract behavior, validation and mapping logic, persistence behavior, and any surface capable of silent data corruption.

This is a standing operating protocol. It applies to every qualifying bug, every time.

---

## Governing Principles

1. **Planning before execution.** No system mutation occurs without a reviewed and authorized plan.
2. **Immutable historical record.** Every phase produces at least one immutable artifact. The full resolution history must be reconstructable from artifacts alone.
3. **Explicit lifecycle control.** Phase transitions require exit criteria. No phase may be skipped unless the classification explicitly permits it.
4. **No silent mutation.** Every change to production state must be traceable to an authorized resolution plan.
5. **No pre-review decision locking.** Analysis does not imply solution selection. Diagnosis does not authorize implementation.

---

## 1. Classification Layer

### 1.1 Classification Dimensions

Every bug must be classified on four dimensions before any work beyond intake begins.

#### Severity

| Level | Definition | Examples |
|-------|-----------|----------|
| **Critical** | Active data corruption, data loss, or security vulnerability | Wrong data written to DB, RLS bypass, silent field overwrite |
| **High** | Incorrect system behavior with no data loss yet occurring | Wrong response envelope, type mismatch not caught, promote returning false negative |
| **Medium** | Degraded behavior with known workaround | List pagination off-by-one, tag filter not applied, cosmetic response field missing |
| **Low** | Cosmetic or non-functional issue | Formatting, naming inconsistency, documentation-only |

#### Blast Radius

| Level | Definition |
|-------|-----------|
| **Multi-workspace** | Bug affects or could affect 2+ workspaces |
| **Single-workspace** | Bug is contained to one workspace |
| **Single-type** | Bug affects one artifact type only |
| **Isolated** | Bug affects one artifact or one operation |

#### Persistence Risk

| Level | Definition |
|-------|-----------|
| **Data corrupted** | Incorrect data has already been written to the database |
| **Data at risk** | Bug could cause incorrect writes under certain conditions, but none confirmed yet |
| **No persistence impact** | Bug affects responses, rendering, or non-persistent behavior only |

#### Contract Impact

| Level | Definition |
|-------|-----------|
| **Gateway contract violated** | External-facing Gateway contract (request/response shape, error codes, action behavior) is broken |
| **Internal contract violated** | Internal contract between sub-workflows, nodes, or components is broken |
| **No contract impact** | Behavior is incorrect but does not violate any documented contract |

### 1.2 Process Path Determination

**Full Process (Phases 0–9):**

Required when ANY of the following are true:

- Severity is Critical or High
- Blast radius is Multi-workspace
- Persistence risk is Data corrupted
- Contract impact is Gateway contract violated
- Bug requires schema or DDL changes
- Bug requires Gateway workflow modification
- Joel explicitly requests full process

**Lightweight Path (Phases 0, 1, 2, 3, 5, 6, 7, 9):**

Permitted when ALL of the following are true:

- Severity is Medium or Low
- Blast radius is Single-type or Isolated
- Persistence risk is No persistence impact
- Contract impact is Internal or None
- No schema changes required
- No Gateway workflow changes required

Lightweight path skips Phase 4 (Independent Review) and Phase 8 (Data Remediation). Authorization (Phase 5) is still mandatory but may be inline (Joel approves during session rather than via separate artifact review).

**Ambiguity Default Rule:** If ANY ambiguity exists in classification — severity level is debatable, blast radius is uncertain, persistence risk is unclear, or contract impact cannot be confirmed — the bug MUST default to the Full Process. The lightweight path is only permitted when classification is unambiguous across all four dimensions. Conservative bias is required. When in doubt, go full process.

### 1.3 Classification Artifact

Classification must be recorded before proceeding to Phase 1. For full process bugs, classification is recorded in the Bug Intake artifact. For lightweight bugs, classification may be recorded inline in a twig.

---

## 2. Phase Model

### Phase 0 — Classification

**Purpose:** Determine process path before any analysis begins.

**Permitted:** Reproduce the bug, read error output, identify affected surface, classify on four dimensions, determine process path.

**Prohibited:** Root cause analysis, solution ideation, code reading beyond reproduction.

**Exit criteria:** All four dimensions classified. Process path (full or lightweight) determined and stated.

**Actor:** CC or Q (whoever encounters the bug first).

---

### Phase 1 — Bug Intake

**Purpose:** Create the authoritative record of the bug with reproduction evidence.

**Permitted:** Document symptoms, capture reproduction steps, record error output, identify affected artifacts, note environmental context.

**Prohibited:** Root cause speculation, solution proposals, any system mutation.

**Required artifact:**

| Field | Value |
|-------|-------|
| Type | `project` (full process) or `twig` (lightweight) |
| Title | `Bug — [Short Description]` |
| Tags | `bug-resolution`, `sev-[level]`, `[surface]` (e.g., `gateway`, `save`, `promote`, `schema`) |
| Semantic type | `execution-core` |
| Content | `classification` (all 4 dimensions + process path), `symptoms`, `reproduction_steps`, `affected_surface`, `affected_artifacts` (list of artifact_ids if known), `error_output`, `environment` |

**Exit criteria:** Bug artifact created with complete reproduction evidence and classification. If full process: project artifact with `lifecycle_status: seed`. If lightweight: twig artifact.

**Actor:** CC creates artifact payload. Joel saves.

---

### Phase 2 — Diagnosis

**Purpose:** Identify root cause through analysis only. No solution selection.

**Permitted:** Read source code, read workflow definitions, trace execution paths, query database state, read logs, identify the exact point of failure, identify contributing factors.

**Prohibited:** Proposing fixes, selecting solutions, modifying any file or system state, locking any implementation decision.

**Required artifact:**

| Field | Value |
|-------|-------|
| Type | `snapshot` |
| Title | `Root Cause — [Bug Title]` |
| Tags | `bug-resolution`, `root-cause`, `sev-[level]` |
| Semantic type | `execution-core` |
| Parent | Bug project/twig artifact_id |
| Payload | `root_cause` (precise technical description), `failure_point` (exact node/function/query), `contributing_factors` (list), `affected_data` (scope of any corrupted data), `blast_radius_confirmed` (actual vs initial classification), `evidence` (query results, logs, traces) |

**Exit criteria:** Root cause identified with evidence. Failure point is precise (not "somewhere in the save flow" — must be "Normalize_Request node does not forward `transition` field"). Blast radius confirmed or reclassified.

**Phase boundary rule:** If diagnosis reveals the bug is more severe than initially classified, STOP. Reclassify. If reclassification changes the process path (lightweight → full), switch to full process before proceeding.

**Actor:** CC performs analysis. CC creates snapshot payload. Joel saves.

---

### Phase 3 — Resolution Planning

**Purpose:** Design the fix with explicit scope, rollback plan, and validation criteria. No implementation.

**Permitted:** Design the fix, identify all files/nodes/queries that must change, define validation criteria, define rollback plan, assess regression risk, identify test cases.

**Prohibited:** Implementing any part of the fix, modifying any file or system state, making changes "to test a theory."

**Required artifact:**

| Field | Value |
|-------|-------|
| Type | `snapshot` |
| Title | `Resolution Plan — [Bug Title]` |
| Tags | `bug-resolution`, `resolution-plan`, `sev-[level]` |
| Semantic type | `execution-core` |
| Parent | Bug project/twig artifact_id |
| Payload | `root_cause_snapshot_id`, `fix_description` (precise technical description), `mutation_surface` (exact list of files/nodes/queries to change), `changes` (list of specific changes per surface), `non_goals` (explicit list of what will NOT be changed — see below), `rollback_plan` (how to revert if fix fails), `validation_criteria` (how to confirm fix works), `regression_risk` (what could break), `test_cases` (specific tests to run), `data_remediation_required` (boolean + scope if true), `estimated_scope` (number of files, nodes, queries) |

**Non-goals requirement:** The `non_goals` field is mandatory. It must explicitly list what will NOT be changed as part of this resolution, including but not limited to:

- Adjacent cleanup not required for the fix
- Refactoring not required for the fix
- Unrelated improvements discovered during diagnosis
- "While we're here" changes of any kind

**Scope boundary rule:** Any change not listed in `changes` AND not excluded in `non_goals` must be treated as out-of-scope. If a change is needed that appears in neither list, the resolution plan must be updated and re-snapshotted before implementation. The combination of `changes` + `non_goals` must fully account for every modification considered during planning.

**Exit criteria:** Resolution plan is complete, specific, and reviewable. Every change is enumerated. Non-goals are explicitly stated. Rollback plan exists. Validation criteria are testable.

**Phase boundary rule:** The resolution plan must not contain any change that was not traced to the root cause. If a "nice to have" cleanup is identified, it must be listed in `non_goals` and tracked separately.

**Actor:** CC designs plan. CC creates snapshot payload. Joel saves.

---

### Phase 4 — Independent Review

**Purpose:** External validation of diagnosis and resolution plan before authorization.

**Permitted:** Review root cause snapshot, review resolution plan, challenge assumptions, identify gaps, propose amendments.

**Prohibited:** Implementing any changes, authorizing implementation.

**When mandatory:**

- Severity is Critical
- Blast radius is Multi-workspace
- Gateway contract change required
- Schema or DDL mutation required
- Joel explicitly requests review

**When optional:**

- Severity is High with Single-workspace scope
- Internal contract change only

**Not required:**

- Lightweight path bugs (Phase 4 is skipped)

**Review actors:**

| Reviewer | When |
|----------|------|
| Manus | Mandatory for Critical severity or schema/DDL changes |
| Q (Qwrk Prime) | Optional second opinion on Gateway or contract changes |
| Joel | Always reviews; may delegate to Manus or Q |

**Required artifact:**

| Field | Value |
|-------|-------|
| Type | `snapshot` |
| Title | `Review — [Bug Title]` |
| Tags | `bug-resolution`, `review`, `sev-[level]` |
| Semantic type | `governance` |
| Parent | Bug project/twig artifact_id |
| Payload | `root_cause_snapshot_id`, `resolution_plan_snapshot_id`, `reviewer` (who reviewed), `review_outcome` (`approved`, `approved-with-amendments`, `rejected`), `amendments` (list of required changes if applicable), `concerns` (any noted risks), `review_date` |

**Exit criteria:** Review outcome recorded. If `approved-with-amendments`, resolution plan must be updated and re-snapshotted before proceeding. If `rejected`, return to Phase 2 or Phase 3 as directed by reviewer.

**Actor:** Reviewer produces feedback. CC creates snapshot payload. Joel saves.

---

### Phase 5 — Authorization Gate

**Purpose:** Explicit human authorization before any production mutation occurs.

**This phase is MANDATORY. No exception. No bypass. No implicit authorization.**

**Permitted:** Joel reviews all prerequisite artifacts, grants or denies authorization.

**Prohibited:** Any system mutation before authorization is recorded. Any assumption that prior discussion constitutes authorization.

**Required artifact:**

| Field | Value |
|-------|-------|
| Type | `snapshot` |
| Title | `Authorization — [Bug Title]` |
| Tags | `bug-resolution`, `authorization`, `sev-[level]` |
| Semantic type | `governance` |
| Parent | Bug project/twig artifact_id |
| Payload | `bug_artifact_id`, `root_cause_snapshot_id`, `resolution_plan_snapshot_id`, `review_snapshot_id` (null if review not required), `classification` (copy of the 4-dimension classification), `authorized_by` (must be `joel`), `authorization_scope` (exact list of permitted mutations — must match resolution plan), `mutation_surface` (exact list of files/nodes/queries authorized for change), `rollback_plan` (copied from resolution plan), `data_remediation_authorized` (boolean), `emergency` (boolean, default false), `authorization_date` |

**Approval criteria — ALL must be true:**

1. Root cause snapshot exists and is referenced
2. Resolution plan snapshot exists and is referenced
3. Review snapshot exists (if review was mandatory) and outcome is `approved` or `approved-with-amendments` (with amendments incorporated)
4. Authorization scope exactly matches resolution plan mutation surface
5. Joel has explicitly stated approval

**Hard rule:** No production mutation may occur without a saved Authorization Snapshot. CC must not execute, generate, or propose any mutation payload until this artifact exists and is referenced. This applies to Gateway workflows, sub-workflows, database state, schema, and all production-adjacent systems.

**Lightweight path variation:** For lightweight bugs, Joel may authorize inline during the session. CC must still create the Authorization Snapshot before implementing. The snapshot may reference the twig (instead of project) and omit `review_snapshot_id`.

**Exit criteria:** Authorization Snapshot saved. Joel has explicitly approved. Authorization scope matches resolution plan.

**Actor:** Joel authorizes. CC creates snapshot payload. Joel saves.

---

### Phase 6 — Controlled Implementation

**Purpose:** Execute the authorized fix and only the authorized fix.

**Permitted:** Implement changes listed in the authorization scope. Follow the resolution plan exactly. Use parallel build pattern (CLAUDE.md Section 9) when modifying live workflows.

**Prohibited:** Any change not listed in the authorization scope. Scope creep. "While we're here" improvements. Refactoring adjacent code. Changing anything the authorization does not cover.

**Implementation rules:**

1. **Scope lock:** Only changes enumerated in `authorization_scope` may be made. Any additional change requires returning to Phase 3 (new resolution plan) and Phase 5 (new authorization).
2. **Parallel build:** When modifying live Gateway workflows or sub-workflows, clone and build in parallel per CLAUDE.md Section 9. Do not modify the live workflow directly.
3. **CC read-only:** CC generates payloads and file changes. Joel executes database mutations and workflow deployments per CLAUDE.md Section 2.5.
4. **Deployment checklist:** When updating sub-workflows, follow the Workflow Deployment Checklist in CLAUDE.md (archive → fix → update Gateway reference → export → import → activate).
5. **Version discipline:** All modified files follow CLAUDE.md Section 3 (No-Overwrite Rule). Archive current version before writing new version.
6. **Payload-level traceability:** Every mutation payload (Gateway, DDL, DML, workflow deployment, file change) generated during Phase 6 MUST include `authorization_snapshot_id` in the payload body or execution context. This ID must match the Authorization Snapshot created in Phase 5. Any mutation payload that does not reference the Authorization Snapshot is considered invalid and must not be executed by Joel. CC must include this reference automatically — omission is a process violation.

**Exit criteria:** All changes in authorization scope implemented. No unauthorized changes made. Every mutation payload references `authorization_snapshot_id`. Parallel build ready for validation (not yet merged to live if applicable).

**Actor:** CC implements. Joel executes mutations.

---

### Phase 7 — Validation

**Purpose:** Confirm the fix works and nothing else broke.

**Permitted:** Run validation tests, run regression tests, query database to confirm state, compare before/after behavior.

**Prohibited:** Additional fixes, scope expansion, "one more thing" changes.

**Required validation:**

1. **Fix verification:** Each validation criterion from the resolution plan must be tested and pass.
2. **Regression check:** Run Phase 2C Certification Harness (`Phase2C_Cert/Run-Phase2C-Cert.ps1`) if the fix touches Gateway, Save, Update, or Promote. Record pass/fail counts.
3. **Contract verification:** If the bug involved a contract violation, verify the contract is now satisfied with specific test payloads.
4. **Data integrity check:** If the fix involved persistence behavior, query the database to confirm correct state.

**Required artifact:**

| Field | Value |
|-------|-------|
| Type | `snapshot` |
| Title | `Validation — [Bug Title]` |
| Tags | `bug-resolution`, `validation`, `sev-[level]` |
| Semantic type | `execution-core` |
| Parent | Bug project/twig artifact_id |
| Payload | `authorization_snapshot_id`, `fix_verification` (list of criteria + pass/fail), `regression_results` (harness output summary if applicable), `contract_verification` (test payloads + results if applicable), `data_integrity` (query results if applicable), `validation_outcome` (`pass` or `fail`), `validation_date` |

**If validation fails:** Return to Phase 6. Do not expand scope. If the fix is fundamentally wrong, return to Phase 3 (new resolution plan) and Phase 5 (new authorization). Execute rollback plan if the failed fix was deployed to live.

**Exit criteria:** All validation criteria pass. Regression harness shows no new failures. Validation Snapshot saved with `validation_outcome: pass`.

**Actor:** CC runs tests and queries. CC creates snapshot payload. Joel saves.

---

### Phase 8 — Data Remediation

**Purpose:** Repair any corrupted data as a separate governed track from the system fix.

**This phase is only entered when `data_remediation_required` is true in the resolution plan AND `data_remediation_authorized` is true in the authorization snapshot.**

**Separation rule:** Data remediation is a separate operation from the system fix. The system fix (Phases 6-7) must be validated BEFORE data remediation begins. Rationale: fixing the system first prevents the remediation from being corrupted by the same bug.

**Permitted:** Query to identify affected records, generate remediation SQL or Gateway payloads, execute remediation after approval, verify remediation results.

**Prohibited:** Combining remediation with system fix in a single operation. Executing remediation before the system fix is validated. Bulk operations without per-record verification plan.

**Remediation process:**

1. **Scope identification:** Query to identify all affected records. Document exact artifact_ids, fields, and incorrect values.
2. **Remediation plan:** For each affected record, specify the exact correction (field, old value, new value). Generate SQL or Gateway payloads.
3. **Remediation approval:** Joel reviews and explicitly approves each remediation payload. For bulk operations (10+ records), Joel approves the pattern and spot-checks results.
4. **Execution:** Joel executes remediation payloads. CC verifies each result via read query.
5. **Verification:** Query all remediated records to confirm correct state.

**Required artifact:**

| Field | Value |
|-------|-------|
| Type | `snapshot` |
| Title | `Data Remediation — [Bug Title]` |
| Tags | `bug-resolution`, `data-remediation`, `sev-[level]` |
| Semantic type | `execution-core` |
| Parent | Bug project/twig artifact_id |
| Payload | `authorization_snapshot_id`, `affected_records` (list of artifact_ids and fields), `remediation_actions` (list of exact corrections), `remediation_method` (`sql` or `gateway`), `verification_results` (query results confirming correct state), `records_remediated` (count), `remediation_date` |

**Exit criteria:** All affected records identified, corrected, and verified. Remediation Snapshot saved.

**Actor:** CC identifies and generates payloads. Joel executes. CC verifies.

---

### Phase 9 — Closure

**Purpose:** Confirm all work is complete and create the final authoritative record.

**Required evidence for closure — ALL must be present:**

1. **Validation proof:** Validation Snapshot with `validation_outcome: pass`
2. **Regression check:** Phase 2C harness results (if applicable) showing no new failures
3. **Data integrity confirmation:** Data Remediation Snapshot (if remediation was required) showing all records corrected
4. **Artifact completeness:** All required artifacts for the process path exist and are linked to the bug artifact
5. **Scope adherence:** All implemented changes match the Authorization Snapshot `mutation_surface` exactly, with no changes outside authorized scope (verified by `scope_verification` in Closure Snapshot — see below)

**Required artifact:**

| Field | Value |
|-------|-------|
| Type | `snapshot` |
| Title | `Closure — [Bug Title]` |
| Tags | `bug-resolution`, `closure`, `sev-[level]` |
| Semantic type | `governance` |
| Parent | Bug project/twig artifact_id |
| Payload | `bug_artifact_id`, `classification` (final — may differ from initial if reclassified), `root_cause_snapshot_id`, `resolution_plan_snapshot_id`, `review_snapshot_id` (null if not required), `authorization_snapshot_id`, `validation_snapshot_id`, `data_remediation_snapshot_id` (null if not applicable), `resolution_summary` (plain language description of what was wrong and how it was fixed), `files_changed` (list), `regression_status` (harness pass/fail counts), `scope_verification` (see below), `open_thread_id` (T-number if applicable), `closure_date` |

**Scope verification requirement:** The Closure Snapshot must include a `scope_verification` object that provides verifiable proof of scope adherence:

```json
"scope_verification": {
  "authorized_changes": ["list from Authorization Snapshot mutation_surface"],
  "implemented_changes": ["list of actual changes made during Phase 6"],
  "variance": "none"
}
```

- `authorized_changes` must be copied exactly from the Authorization Snapshot's `mutation_surface`
- `implemented_changes` must list every file, node, query, or system component actually modified
- `variance` must be `"none"` if the two lists match, or a detailed explanation if they differ
- **Closure is invalid if variance exists and is not explicitly reconciled.** Reconciliation requires either: (a) an amended Authorization Snapshot covering the additional changes, or (b) rollback of the unauthorized changes before closure.

**Post-closure actions:**

1. Update OPEN_THREADS.md — close the thread with resolution note
2. If the bug revealed a governance gap, create a separate governance snapshot capturing the gap and any rule change needed
3. If the bug affects documentation (Schema Reference, Gateway contract docs, CLAUDE.md), create a follow-up thread for documentation update — do not bundle with bug closure

**Exit criteria:** Closure Snapshot saved. Open thread closed. All artifacts linked.

**Actor:** CC creates snapshot payload. Joel saves. CC updates OPEN_THREADS.

---

## 3. Enforcement Mechanism

### Hard Rule

**No production mutation may occur without a saved Authorization Snapshot.**

This rule is absolute. It applies to:

- Gateway workflow modifications
- Sub-workflow modifications
- Database schema changes (DDL)
- Database data changes (DML)
- RLS policy changes
- Function/RPC changes
- Any operation that alters production system behavior or state

**Enforcement:**

- CC must verify the Authorization Snapshot exists (by artifact_id) before generating any mutation payload or file change
- CC must reference the Authorization Snapshot artifact_id in the implementation session
- If Joel requests CC to "just fix it" without an Authorization Snapshot, CC must create the snapshot first, have Joel save it, and then proceed
- Retroactive authorization is only permitted under the Emergency Path (Section 8)

### Payload-Level Traceability

Every mutation payload generated during bug resolution MUST include `authorization_snapshot_id` as a field in the payload body or as an explicit reference in the execution context. This applies to:

- Gateway payloads (save, update, promote, delete, restore)
- SQL statements (DDL, DML)
- Workflow deployment instructions
- File modification contexts

**Validation rule:** Joel must verify that `authorization_snapshot_id` is present before executing any mutation payload. A mutation payload without this reference is invalid regardless of verbal or session-context authorization. The `authorization_snapshot_id` must match the Authorization Snapshot created in Phase 5 for the specific bug being resolved.

### Artifact Chain Integrity

Every artifact in the resolution chain must reference its parent bug artifact via `parent_artifact_id`. The full chain must be traversable:

```
Bug (project/twig)
├── Root Cause (snapshot)
├── Resolution Plan (snapshot)
├── Review (snapshot, if applicable)
├── Authorization (snapshot)
├── Validation (snapshot)
├── Data Remediation (snapshot, if applicable)
└── Closure (snapshot)
```

If any artifact in the chain is missing, closure cannot proceed.

---

## 4. Phase Boundaries

### Boundary Rules

These rules prevent phase contamination. They are not guidelines — they are hard stops.

| Boundary | Rule |
|----------|------|
| **Diagnosis → Resolution** | No solution may be proposed, discussed, or implied during Phase 2. The Root Cause Snapshot must contain only analysis, not fixes. If CC catches itself proposing a fix during diagnosis, it must stop and move the proposal to Phase 3. |
| **Resolution → Implementation** | No file, workflow, query, or system state may be modified during Phase 3. The Resolution Plan is a document, not an execution. |
| **Review → Authorization** | A positive review does not constitute authorization. Phase 4 produces a Review Snapshot. Phase 5 produces an Authorization Snapshot. These are separate artifacts with separate approval semantics. |
| **Authorization → Implementation** | Implementation must not exceed authorization scope. If CC discovers during Phase 6 that the fix requires a change not in the authorization scope, CC must STOP and return to Phase 3. |
| **Implementation → Validation** | No additional changes during validation. If validation reveals the fix is incomplete, return to Phase 6 (if within scope) or Phase 3 (if scope must change). Do not add "one more fix" during validation. |
| **Validation → Remediation** | System fix must be validated BEFORE data remediation begins. These are sequential, not parallel. |

### Scope Creep Prevention

During any phase, if work is identified that is outside the bug's scope:

1. Record the observation in the current phase's artifact
2. If it is a separate bug: create a separate Bug Intake (Phase 1) for it
3. If it is a cleanup or improvement: create a twig or add to an existing thread
4. Do NOT fold it into the current bug resolution

---

## 5. Independent Review Threshold

| Condition | Review Requirement |
|-----------|-------------------|
| Severity: Critical | **Mandatory** — Manus reviews |
| Blast radius: Multi-workspace | **Mandatory** — Manus reviews |
| Gateway contract change | **Mandatory** — Manus or Q reviews |
| Schema/DDL mutation | **Mandatory** — Manus reviews |
| Severity: High, single-workspace | **Optional** — Joel decides |
| Severity: Medium/Low (lightweight path) | **Not required** — Phase 4 skipped |
| Joel explicitly requests | **Mandatory** — reviewer as specified by Joel |

When review is mandatory, the reviewer must receive:

1. Root Cause Snapshot (full payload)
2. Resolution Plan Snapshot (full payload)
3. Bug Intake artifact (for context)

The reviewer produces feedback. CC records feedback in the Review Snapshot. If the reviewer requests amendments, the Resolution Plan must be updated and re-snapshotted before proceeding to Phase 5.

---

## 6. Data Remediation Governance

### Separation Principle

Data remediation is always a separate track from the system fix. The rationale:

1. The system fix prevents future corruption
2. Data remediation repairs past corruption
3. If remediation runs before the fix, the bug may corrupt the remediated data again
4. Separating them creates a clean audit trail

### Approval Requirements

- Joel must explicitly approve data remediation (recorded in Authorization Snapshot as `data_remediation_authorized: true`)
- For bulk operations (10+ records): Joel approves the remediation pattern and spot-checks a sample of results
- For sensitive data (journal content, person records): Joel approves each individual remediation

### Validation Requirements

- Every remediated record must be verified via read query after remediation
- Verification results must be recorded in the Data Remediation Snapshot
- If any record fails verification, STOP and investigate before continuing

---

## 7. Closure Standard

A bug is closed when ALL of the following are true:

| Criterion | Evidence |
|-----------|----------|
| Root cause identified | Root Cause Snapshot exists with precise failure point |
| Fix implemented | Changes match authorization scope exactly |
| Fix validated | Validation Snapshot with `validation_outcome: pass` |
| Regression clean | Phase 2C harness shows no new failures (if applicable) |
| Data remediated | Data Remediation Snapshot confirms all records corrected (if applicable) |
| Artifacts complete | All required artifacts exist and are parented to bug artifact |
| Scope verified | `scope_verification` in Closure Snapshot shows `variance: "none"` or variance is reconciled |
| Thread closed | OPEN_THREADS.md updated |

If any criterion is not met, the bug cannot be closed. Partial closure is not permitted.

---

## 8. Emergency Path

### When Emergency Patching Is Allowed

Emergency patching bypasses the normal phase sequence ONLY when:

1. **Active data corruption is in progress** — the bug is actively writing incorrect data to production and every minute of delay increases the damage
2. **Complete system outage** — the Gateway or a critical sub-workflow is entirely non-functional and no workaround exists

"This is urgent" or "this is high priority" does NOT qualify for emergency patching. Urgency is handled by prioritizing the full process, not by skipping it.

### Emergency Procedure

1. **Immediate action:** Implement the minimum fix required to stop active corruption or restore function. No scope expansion.
2. **Retroactive Phase 1:** Create Bug Intake artifact within the same session
3. **Retroactive Phase 2:** Create Root Cause Snapshot within the same session
4. **Retroactive Phase 5:** Create Authorization Snapshot with `emergency: true` within the same session. Joel must explicitly confirm retroactive authorization.
5. **Resume normal process:** Complete Phases 3, 7, 8, 9 normally. The Resolution Plan is created retroactively to document what was done (not what should be done).
6. **Timeline:** All retroactive artifacts must be created within 24 hours of the emergency fix.

### Emergency Artifact

The Authorization Snapshot for emergency fixes must include:

- `emergency: true`
- `emergency_justification` (why normal process could not be followed)
- `emergency_action_taken` (exactly what was changed)
- `retroactive: true`

---

## 9. Artifact Classification Rules

### When to Use Project

Use a **project** artifact as the bug container when:

- Full process is required (Critical/High severity, multi-workspace, data corruption, contract violation)
- The fix will span multiple sessions
- Execution anatomy (branches, leaves) will be needed
- The bug requires coordinated work across multiple surfaces

Project settings:

- `lifecycle_status: seed` at creation
- Promote to `sapling` when resolution plan is authorized
- Promote to `tree` when fix is validated
- Promote to `archive` at closure

### When to Use Twig

Use a **twig** artifact as the bug container when:

- Lightweight path is sufficient (Medium/Low severity, isolated, no persistence impact)
- The fix will complete in a single session
- No execution anatomy needed
- Single-surface fix

### Escalation Rule

If a bug initially classified as lightweight (twig) is reclassified to full process during Phase 2:

1. Create a new project artifact with the updated classification
2. Reference the original twig in the project's content as `origin_twig_id`
3. All subsequent artifacts parent to the project, not the twig
4. The twig remains as historical record — do not delete

---

## 10. Tagging Convention

### Required Tags (All Bug Artifacts)

| Tag | Applied To | Purpose |
|-----|-----------|---------|
| `bug-resolution` | All artifacts in the chain | Identifies artifact as part of bug resolution process |
| `sev-critical` / `sev-high` / `sev-medium` / `sev-low` | All artifacts in the chain | Severity classification |

### Phase-Specific Tags

| Tag | Applied To | Purpose |
|-----|-----------|---------|
| `root-cause` | Root Cause Snapshot | Phase 2 output |
| `resolution-plan` | Resolution Plan Snapshot | Phase 3 output |
| `review` | Review Snapshot | Phase 4 output |
| `authorization` | Authorization Snapshot | Phase 5 output |
| `validation` | Validation Snapshot | Phase 7 output |
| `data-remediation` | Data Remediation Snapshot | Phase 8 output |
| `closure` | Closure Snapshot | Phase 9 output |

### Surface Tags (Applied to Bug Intake)

| Tag | When |
|-----|------|
| `gateway` | Bug affects Gateway workflow |
| `save` | Bug affects Save sub-workflow |
| `update` | Bug affects Update sub-workflow |
| `promote` | Bug affects Promote sub-workflow |
| `query` | Bug affects Query sub-workflow |
| `list` | Bug affects List sub-workflow |
| `schema` | Bug affects database schema |
| `rls` | Bug affects RLS policies |
| `contract` | Bug involves contract violation |

### Process Path Tags

| Tag | When |
|-----|------|
| `full-process` | Full process path |
| `lightweight` | Lightweight process path |
| `emergency` | Emergency path was invoked |

---

## Quick Reference — Phase Flow

### Full Process

```
Phase 0: Classification
    ↓
Phase 1: Bug Intake → project artifact
    ↓
Phase 2: Diagnosis → Root Cause Snapshot
    ↓
Phase 3: Resolution Planning → Resolution Plan Snapshot
    ↓
Phase 4: Independent Review → Review Snapshot
    ↓
Phase 5: Authorization Gate → Authorization Snapshot ← HARD GATE
    ↓
Phase 6: Controlled Implementation
    ↓
Phase 7: Validation → Validation Snapshot
    ↓
Phase 8: Data Remediation → Data Remediation Snapshot (if applicable)
    ↓
Phase 9: Closure → Closure Snapshot
```

### Lightweight Process

```
Phase 0: Classification
    ↓
Phase 1: Bug Intake → twig artifact
    ↓
Phase 2: Diagnosis → Root Cause Snapshot
    ↓
Phase 3: Resolution Planning → Resolution Plan Snapshot
    ↓
Phase 5: Authorization Gate → Authorization Snapshot ← HARD GATE
    ↓
Phase 6: Controlled Implementation
    ↓
Phase 7: Validation → Validation Snapshot
    ↓
Phase 9: Closure → Closure Snapshot
```

### Emergency Process

```
EMERGENCY ACTION (stop the bleeding)
    ↓
Phase 1: Bug Intake (retroactive, same session)
    ↓
Phase 2: Root Cause (retroactive, same session)
    ↓
Phase 5: Authorization (retroactive, emergency: true, same session)
    ↓
Phase 3: Resolution Plan (retroactive — documenting what was done)
    ↓
Phase 7: Validation
    ↓
Phase 8: Data Remediation (if applicable)
    ↓
Phase 9: Closure
```

---

## CHANGELOG

### v1.1 — 2026-03-29

Governance hardening — four targeted upgrades:

1. **Authorization Enforcement Upgrade (Payload-Level Traceability):** Every mutation payload must now include `authorization_snapshot_id`. Added to Phase 6 implementation rules (rule 6) and Enforcement Mechanism (new Payload-Level Traceability subsection). Mutation payloads without this reference are invalid.
2. **Resolution Plan Non-Goals Field:** Phase 3 now requires `non_goals` in the Resolution Plan payload — an explicit list of what will NOT be changed. Scope boundary rule added: any change not in `changes` and not excluded in `non_goals` is out-of-scope.
3. **Lightweight Path Guardrail:** Section 1.2 now includes an Ambiguity Default Rule — if ANY classification dimension is ambiguous, the bug defaults to Full Process. Conservative bias required.
4. **Closure Verification Hardening:** Phase 9 self-attestation replaced with verifiable `scope_verification` object in Closure Snapshot. Requires `authorized_changes`, `implemented_changes`, and `variance` fields. Closure is invalid if variance exists and is not reconciled. Closure Standard (Section 7) updated accordingly.

### v1 — 2026-03-29

Initial creation. Standing operating protocol for production and production-adjacent bug resolution. 10-phase model with classification layer, hard authorization gate, explicit phase boundaries, data remediation governance, emergency path, and artifact chain integrity requirements.
