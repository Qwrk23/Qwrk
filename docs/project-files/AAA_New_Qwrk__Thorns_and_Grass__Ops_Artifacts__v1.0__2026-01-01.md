# Thorns and Grass: Operational Artifacts for Qwrk V2

**Version**: 1.0
**Date**: 2026-01-01
**Status**: Design Specification (Not Yet Implemented)
**Audience**: Master Joel + Future Build Assistants (Claude Code included)

---

## CHANGELOG

### v1.0 - 2026-01-01 (Initial Specification)

**What changed**: Initial design document created

**Why**: Define two new artifact types (THORN and GRASS) to handle operational incidents and review items separately from Flowers (to-dos)

**Scope of impact**:
- Database schema (2 new extension tables)
- n8n workflow integration (detection, creation, diagnostic attachment)
- Claude Code operational loop (diagnosis, patch proposal, verification)
- Gateway contract (new artifact types for save/query/list operations)

**How to validate**:
- Review design against existing artifact architecture
- Confirm alignment with spine + extension pattern
- Verify governance rules match existing RLS model
- Ensure no conflicts with truth hierarchy (Kernel v1, KGB, Phase 1-3 locks)

**Previous version**: None (initial document)

---

## 1. Why Thorns and Grass Exist (Problem Statement)

### Current State

The Qwrk V2 system currently has **Flowers** as the primary artifact type for to-do items and execution tasks. Flowers represent intentional, planned work items that users create to track goals, tasks, and deliverables.

### Gap Identified

**Two distinct operational needs are not well-served by Flowers:**

1. **Urgent Break/Fix Items (Thorns)**: When n8n workflows fail, data integrity issues arise, or system errors occur, these require immediate attention and triage. These are **not** planned to-dos—they are incidents that demand operational response.

2. **Non-Urgent Review Items (Grass)**: When workflows detect anomalies, warnings, or informational messages that should be reviewed but don't require immediate action, these need a holding queue. These are **not** actionable tasks (yet)—they are notifications awaiting human judgment.

### The Problem with Conflating Types

If we force Thorns and Grass into the Flower model:
- ❌ Operational incidents pollute to-do lists
- ❌ Urgency signals (severity) get lost in task priority
- ❌ Triage workflows (acknowledge → diagnose → resolve) don't map to task completion
- ❌ Review queues (unreviewed → reviewed/promoted/dismissed) have no clear state model
- ❌ Users lose clarity on what requires immediate attention vs. planned execution

### Solution: First-Class Artifact Types

**Thorns** and **Grass** become distinct artifact types with their own:
- Extension tables (type-specific fields for ops handling)
- Status lifecycles (incident resolution vs. review disposition)
- Query/list semantics (severity-based triage vs. review queues)
- Operational loops (CC diagnosis + auto-fix vs. promotion to Flowers)

**Flowers remain unchanged** as the artifact type for planned to-dos and execution items.

---

## 2. Definitions (Binding Semantics)

### Thorn (artifact_type: "thorn")

**Definition**: An **urgent operational incident** requiring immediate attention, triage, and resolution.

**Characteristics**:
- Created automatically by n8n workflows when errors, failures, or critical anomalies are detected
- Has **severity** (1-5 scale, with 5 being most urgent)
- Follows **incident lifecycle**: open → acknowledged → resolved → ignored
- Requires **diagnostic context** (source system, workflow, execution ID, error details)
- May trigger **CC auto-diagnosis** and patch proposals
- Workspace-scoped and owner-scoped (via existing artifact governance)

**Examples**:
- n8n workflow execution failure (e.g., Supabase connection timeout)
- Data integrity violation detected (e.g., orphaned extension row)
- RLS policy denial preventing expected operation
- KGB regression test failure after schema change

**Lifecycle States**:
- `open`: Newly created, awaiting acknowledgment
- `acknowledged`: Human or CC has seen it, diagnosis in progress
- `resolved`: Root cause fixed, resolution logged
- `ignored`: Determined to be false positive or low priority, dismissed

### Grass (artifact_type: "grass")

**Definition**: A **non-urgent informational item** or notification awaiting review and disposition.

**Characteristics**:
- Created automatically by n8n workflows when warnings, informational events, or low-priority anomalies are detected
- Has **review_status** (unreviewed → reviewed → dismissed)
- Has **disposition** (none → promoted_to_flower → dismissed)
- Does **not** require immediate action
- May be **promoted to a Flower** if review determines it's actionable
- Workspace-scoped and owner-scoped (via existing artifact governance)

**Examples**:
- Performance degradation warning (e.g., query took 3+ seconds)
- Data quality notice (e.g., missing optional field on 10% of records)
- Usage pattern alert (e.g., user created 50+ artifacts in 1 hour)
- Workflow execution note (e.g., "fallback logic used due to X")

**Review States**:
- `unreviewed`: Newly created, awaiting human review
- `reviewed`: Human has evaluated the item
- `dismissed`: Determined to be noise or acceptable, no action needed

**Disposition States**:
- `none`: No action taken yet
- `promoted_to_flower`: Converted into a to-do/task for planned execution
- `dismissed`: Reviewed and dismissed as noise or acceptable

### Flower (artifact_type: "flower") - Unchanged

**Definition**: A **planned to-do or execution item** representing intentional work.

**Characteristics**:
- Created manually by users or promoted from Grass
- Has **priority** and **lifecycle_status** (planning → execution → completion)
- Represents deliberate, planned action (not reactive incidents)

**No changes to Flower semantics** are proposed in this document.

---

## 3. Artifact Model (How It Fits qxb_artifact Spine)

### Spine + Extension Architecture

Both **Thorn** and **Grass** follow the existing Qwrk V2 class-table inheritance pattern:

**Spine Table**: `qxb_artifact`
- Contains common fields: `artifact_id`, `workspace_id`, `owner_user_id`, `artifact_type`, `title`, `summary`, `created_at`, `updated_at`, etc.
- `artifact_type` will accept new values: `'thorn'` and `'grass'`

**Extension Tables**: Type-specific fields via PK=FK relationship
- `qxb_artifact_thorn` (artifact_id PK, FK → qxb_artifact.artifact_id)
- `qxb_artifact_grass` (artifact_id PK, FK → qxb_artifact.artifact_id)

### Workspace & Owner Scoping

**Governance Model** (unchanged from existing artifacts):
- Both Thorns and Grass are **workspace-scoped** (require valid `workspace_id`)
- Both are **owner-scoped** (created by a specific `owner_user_id`)
- RLS policies apply (workspace members can read, owner/admin can update)
- **Exception**: Thorns may have special RLS for ops team access (deferred to implementation)

### Relationship to Other Artifacts

- Thorns and Grass may reference **parent_artifact_id** (e.g., a Thorn about a failed operation on a Project)
- Grass may be **promoted to a Flower** (creates new Flower artifact, updates Grass disposition)
- Thorns **remain distinct** from Flowers (no promotion path—incidents are resolved, not completed)

### Integration with Existing Gateway

**Gateway Actions Required**:
- `artifact.save` must support `artifact_type: "thorn"` and `artifact_type: "grass"`
- `artifact.query` must support querying Thorns and Grass by `artifact_id`
- `artifact.list` must support filtering by `artifact_type` (e.g., list all open Thorns)

**No Breaking Changes**: Existing artifact types (project, journal, restart, snapshot) remain unchanged.

---

## 4. Operational Loop (n8n + Claude Code)

### Thorn Operational Loop (Incident Response)

**Phase 1: Detection & Creation (n8n workflows)**

1. **Detect**: n8n workflow encounters error, failure, or critical anomaly
2. **Create Thorn**: Workflow calls `NQxb_Artifact_Save_v1` with:
   - `artifact_type: "thorn"`
   - `title`: Short incident description (e.g., "Workflow execution failed: DB timeout")
   - `summary`: Human-readable summary
   - `extension`:
     - `source_system`: "n8n" or other origin
     - `source_workflow`: Workflow name (e.g., "NQxb_Artifact_Save_v1")
     - `source_execution_id`: n8n execution ID
     - `detected_at`: Timestamp of detection
     - `severity`: 1-5 (auto-assigned based on error type)
     - `status`: "open"
     - `details_json`: Full error context, stack trace, input data
3. **Attach Diagnostic Bundle**: Workflow may attach logs, execution history, affected artifact IDs

**Phase 2: Diagnosis (Claude Code)**

4. **CC Triggered**: Thorn creation triggers CC notification (manual or automated)
5. **CC Analyzes**:
   - Reads Thorn details_json
   - Queries related artifacts (parent, affected records)
   - Reviews n8n execution logs
   - Compares against KGB baseline
6. **CC Proposes**:
   - Root cause analysis
   - Patch proposal (code change, schema fix, workflow update)
   - Risk assessment

**Phase 3: Approval & Fix (Human + CC)**

7. **Approval Gate**:
   - **Autonomy Tier 1 (Suggest-only)**: CC proposes, human reviews and approves
   - **Autonomy Tier 2 (Safe auto-fix)**: CC auto-applies if patch is on allow-list (e.g., restart workflow, clear cache)
   - **Autonomy Tier 3 (Broader auto-fix)**: Future—CC can apply broader fixes with post-hoc notification
8. **Apply Fix**: CC or human applies approved patch
9. **Update Thorn**:
   - `status: "acknowledged"` → `"resolved"`
   - `resolution_notes`: Summary of fix applied
   - `resolved_at`: Timestamp

**Phase 4: Verification**

10. **Verify**: Run KGB regression or targeted test to confirm fix
11. **Log Outcome**: Update Thorn with verification results
12. **Close**: Thorn remains `status: "resolved"` for historical record

### Grass Operational Loop (Review & Triage)

**Phase 1: Detection & Creation (n8n workflows)**

1. **Detect**: n8n workflow encounters warning, informational event, or low-priority anomaly
2. **Create Grass**: Workflow calls `NQxb_Artifact_Save_v1` with:
   - `artifact_type: "grass"`
   - `title`: Short description (e.g., "Performance warning: Query took 4.2s")
   - `summary`: Human-readable summary
   - `extension`:
     - `source_system`: "n8n" or other origin
     - `source_workflow`: Workflow name
     - `source_execution_id`: n8n execution ID
     - `detected_at`: Timestamp
     - `review_status`: "unreviewed"
     - `details_json`: Full context
3. **Queue for Review**: Grass added to unreviewed queue

**Phase 2: Human Review**

4. **Human Reviews**: User reads Grass summary and details
5. **Disposition Decision**:
   - **Dismiss**: Mark `review_status: "reviewed"`, `disposition: "dismissed"`, `reviewed_at: now()`
   - **Promote to Flower**:
     - Create new Flower artifact with Grass details
     - Mark Grass `disposition: "promoted_to_flower"`, `review_status: "reviewed"`
     - Link Flower to Grass via `parent_artifact_id`
   - **Ignore**: Leave as `unreviewed` (may be batch-dismissed later)

**Phase 3: Cleanup**

6. **Archive**: Reviewed/dismissed Grass may be archived or deleted after retention period (future)

### Claude Code Role (Mechanic, Not Architect)

**CC operates as a mechanic:**
- ✅ Reads Thorn/Grass artifacts via Gateway
- ✅ Analyzes diagnostic bundles
- ✅ Proposes patches based on known patterns
- ✅ Applies approved fixes using versioned file operations
- ✅ Runs regression tests (KGB or targeted)
- ✅ Updates Thorn status and resolution notes

**CC does NOT:**
- ❌ Decide autonomously which incidents to create (that's n8n's detection logic)
- ❌ Guess schemas, enums, or status values not defined in truth hierarchy
- ❌ Overwrite files without versioning
- ❌ Apply fixes without approval (unless on safe auto-fix allow-list)

---

## 5. Minimal Schema (As Implemented in SQL)

### qxb_artifact_thorn

**Purpose**: Extension table for Thorn artifacts (urgent operational incidents)

```sql
CREATE TABLE qxb_artifact_thorn (
  artifact_id UUID PRIMARY KEY REFERENCES qxb_artifact(artifact_id) ON DELETE CASCADE,

  -- Source context
  source_system TEXT NOT NULL,              -- e.g., 'n8n', 'supabase', 'manual'
  source_workflow TEXT,                     -- Workflow name if from n8n
  source_execution_id TEXT,                 -- n8n execution ID or other trace ID
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Severity & lifecycle
  severity INTEGER NOT NULL CHECK (severity BETWEEN 1 AND 5),  -- 1=low, 5=critical
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'acknowledged', 'resolved', 'ignored')),

  -- Incident details
  summary TEXT,                             -- Short summary (also in spine)
  details_json JSONB,                       -- Full diagnostic context (errors, logs, affected IDs)

  -- Resolution tracking
  resolution_notes TEXT,                    -- Summary of fix applied
  resolved_at TIMESTAMPTZ,                  -- When incident was resolved

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for operational queries
CREATE INDEX idx_thorn_status_detected ON qxb_artifact_thorn(status, detected_at DESC);
CREATE INDEX idx_thorn_severity_detected ON qxb_artifact_thorn(severity DESC, detected_at DESC);
CREATE INDEX idx_thorn_source_workflow ON qxb_artifact_thorn(source_workflow, detected_at DESC);

-- Trigger for updated_at
CREATE TRIGGER thorn_updated_at
  BEFORE UPDATE ON qxb_artifact_thorn
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### qxb_artifact_grass

**Purpose**: Extension table for Grass artifacts (non-urgent review items)

```sql
CREATE TABLE qxb_artifact_grass (
  artifact_id UUID PRIMARY KEY REFERENCES qxb_artifact(artifact_id) ON DELETE CASCADE,

  -- Source context
  source_system TEXT NOT NULL,              -- e.g., 'n8n', 'supabase', 'manual'
  source_workflow TEXT,                     -- Workflow name if from n8n
  source_execution_id TEXT,                 -- n8n execution ID or other trace ID
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Review lifecycle
  review_status TEXT NOT NULL DEFAULT 'unreviewed' CHECK (review_status IN ('unreviewed', 'reviewed', 'dismissed')),

  -- Incident details
  summary TEXT,                             -- Short summary (also in spine)
  details_json JSONB,                       -- Full context (warnings, data, affected IDs)

  -- Disposition tracking
  disposition TEXT NOT NULL DEFAULT 'none' CHECK (disposition IN ('none', 'promoted_to_flower', 'dismissed')),
  reviewed_at TIMESTAMPTZ,                  -- When review occurred

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for review queue queries
CREATE INDEX idx_grass_review_status_detected ON qxb_artifact_grass(review_status, detected_at DESC);
CREATE INDEX idx_grass_source_workflow ON qxb_artifact_grass(source_workflow, detected_at DESC);

-- Trigger for updated_at
CREATE TRIGGER grass_updated_at
  BEFORE UPDATE ON qxb_artifact_grass
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### RLS Policies (Deferred to Implementation)

**Requirements**:
- Thorns and Grass must respect workspace membership (existing RLS helper: `qxb_current_user_id()`)
- Read access: workspace members can read
- Write access: owner can update, admins can update
- Special consideration: May need ops team role for Thorn triage (deferred)

**Implementation**: RLS policies will follow existing artifact pattern (see `AAA_New_Qwrk__RLS_Patch__Kernel_v1__v1.2__2025-12-30.sql`)

---

## 6. Governance & Safety Rules

### Separation of Concerns

**Hard Rule 1: Thorns/Grass are NOT Flowers**

- ❌ Do NOT co-mingle Thorn/Grass lists with Flower lists by default
- ❌ Do NOT use Flower priority/lifecycle fields for incident severity/status
- ✅ Provide separate list views: "Thorns (Open)", "Grass (Unreviewed)", "Flowers (Active)"
- ✅ Allow cross-type queries only when explicitly requested (e.g., "All artifacts for workspace X")

**Hard Rule 2: No Silent Type Changes**

- ❌ Do NOT convert Thorns to Flowers automatically
- ❌ Do NOT convert Flowers to Grass/Thorns
- ✅ Grass may be **promoted** to Flower via explicit user action (creates new Flower, updates Grass disposition)
- ✅ All type changes must be logged and versioned

### Auto-Fix Safety

**Autonomy Tier 1 (Current - Suggest-only)**

- CC diagnoses Thorns and **proposes** patches
- **Human approval required** for all fixes
- CC updates Thorn with proposal, waits for approval
- After approval, CC applies fix and updates Thorn status

**Autonomy Tier 2 (Future - Safe Auto-Fix)**

**Allow-list for safe auto-fixes** (examples, not exhaustive):
- ✅ Restart failed workflow execution
- ✅ Clear cache/temporary data
- ✅ Retry idempotent operation (e.g., GET request)
- ✅ Update workflow pinned data to match schema change (if KGB passes)

**Deny-list for unsafe auto-fixes**:
- ❌ Schema changes (ALTER TABLE, DROP, etc.)
- ❌ Data deletion (DELETE, TRUNCATE)
- ❌ RLS policy changes
- ❌ Workflow logic changes (node addition/removal)

**Requirements for safe auto-fix**:
1. Patch must be on explicit allow-list
2. Regression checks must pass (KGB or targeted tests)
3. All changes must be versioned and documented
4. Rollback plan must exist
5. Post-fix notification to human required

**Autonomy Tier 3 (Deferred - Broader Auto-Fix)**

- CC can apply broader fixes with post-hoc notification
- Requires confidence scoring, risk assessment, expanded allow-list
- Out of scope for v1.0

### Versioning Discipline

**All fixes must be versioned:**
- ✅ Schema changes: Use versioned SQL files (e.g., `AAA_New_Qwrk__Schema_Patch__Thorns_Grass__v1.0__2026-01-02.sql`)
- ✅ Workflow changes: Export updated workflow with version in filename
- ✅ Code changes: Follow Pattern A or B (versioned clone or canonical preservation)
- ✅ Documentation: Update relevant docs with version increments

**All fixes must be documented:**
- ✅ CHANGELOG section in updated files
- ✅ Resolution notes in Thorn artifact
- ✅ Commit messages or change log entries

**All fixes must be rollbackable:**
- ✅ Keep previous versions archived
- ✅ Document rollback steps
- ✅ Test rollback plan before applying fix to production

### KGB Discipline

**Thorns/Grass integration with Known-Good Baseline:**

- ✅ Any schema change adding Thorn/Grass tables must include updated KGB test pack
- ✅ KGB tests must create sample Thorn and Grass artifacts
- ✅ KGB tests must verify Thorn/Grass can be queried, updated, and resolved/reviewed
- ✅ No Thorn/Grass feature ships without passing KGB regression

**KGB Test IDs** (to be created):
- `thorn_sample_id`: UUID for test Thorn artifact
- `grass_sample_id`: UUID for test Grass artifact

---

## 7. Recommended List Views (Non-Binding UI Guidance)

### Thorn List Views

**View 1: Open Thorns by Severity**
```
Title: "Thorns: Open Incidents"
Filter: artifact_type = 'thorn' AND status = 'open'
Sort: severity DESC, detected_at DESC
Display Columns: title, severity, source_workflow, detected_at, summary
```

**View 2: All Thorns by Recency**
```
Title: "Thorns: All Incidents"
Filter: artifact_type = 'thorn'
Sort: detected_at DESC
Display Columns: title, severity, status, source_workflow, detected_at, resolved_at
```

**View 3: Acknowledged Thorns (In Progress)**
```
Title: "Thorns: In Progress"
Filter: artifact_type = 'thorn' AND status = 'acknowledged'
Sort: severity DESC, detected_at DESC
Display Columns: title, severity, source_workflow, detected_at, summary
```

### Grass List Views

**View 1: Unreviewed Grass**
```
Title: "Grass: Awaiting Review"
Filter: artifact_type = 'grass' AND review_status = 'unreviewed'
Sort: detected_at DESC
Display Columns: title, source_workflow, detected_at, summary
```

**View 2: All Grass by Recency**
```
Title: "Grass: All Review Items"
Filter: artifact_type = 'grass'
Sort: detected_at DESC
Display Columns: title, review_status, disposition, source_workflow, detected_at, reviewed_at
```

**View 3: Promoted Grass (Became Flowers)**
```
Title: "Grass: Promoted to Flowers"
Filter: artifact_type = 'grass' AND disposition = 'promoted_to_flower'
Sort: reviewed_at DESC
Display Columns: title, source_workflow, detected_at, reviewed_at
```

### Gateway List Contract

**Required filter parameters for `artifact.list`:**
- `artifact_type`: Support filtering by `'thorn'` or `'grass'`
- `status` (for Thorns): Support filtering by `'open'`, `'acknowledged'`, `'resolved'`, `'ignored'`
- `review_status` (for Grass): Support filtering by `'unreviewed'`, `'reviewed'`, `'dismissed'`
- `severity` (for Thorns): Support filtering by severity range (e.g., `severity >= 4`)

**Required sort parameters:**
- `detected_at DESC` (default for Thorns/Grass)
- `severity DESC` (for Thorns)

**Example `artifact.list` request for open Thorns:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "thorn",
  "filters": {
    "status": "open"
  },
  "sort": {
    "field": "severity",
    "direction": "desc"
  }
}
```

---

## 8. Future Upgrades (Explicitly Deferred)

### Phase 2: Dedicated Incident Artifact Type

**Consideration**: If Thorn incident handling becomes more complex, consider promoting to full `artifact_type: "incident"` with:
- Incident lifecycle (open → triaging → investigating → resolving → resolved → closed)
- Assigned owner (who's working on it)
- Related artifacts (affected projects, linked Thorns)
- SLA tracking (time to acknowledge, time to resolve)

**Decision**: Deferred until Thorn usage patterns are observed in production.

### Phase 3: Automated KGB Regression Harness

**Vision**: CC automatically runs KGB test pack after applying fixes:
1. CC applies patch to Thorn
2. CC triggers KGB test workflow
3. CC waits for results
4. If KGB passes → mark Thorn resolved
5. If KGB fails → mark Thorn acknowledged, add failure details, notify human

**Decision**: Requires KGB test automation infrastructure (not yet implemented).

### Phase 4: Formal Severity Taxonomy

**Vision**: Define formal severity levels with auto-assignment rules:
- **Severity 5 (Critical)**: Data corruption, RLS bypass, total system failure
- **Severity 4 (High)**: Workflow execution failure, missing data integrity
- **Severity 3 (Medium)**: Performance degradation, partial functionality loss
- **Severity 2 (Low)**: Warnings, non-critical errors
- **Severity 1 (Informational)**: Notices, usage patterns

**Decision**: Start with numeric 1-5 scale, refine taxonomy based on operational experience.

### Phase 5: Auto-Promotion Rules (Grass → Flower)

**Vision**: Define rules for automatic Grass promotion:
- If Grass of type X appears N times in Y hours → auto-promote to Flower
- If Grass severity (if added) exceeds threshold → auto-promote
- If Grass contains keywords (e.g., "urgent", "required") → flag for review

**Hard Requirement**: All auto-promotions must have **explicit user approval** before creating Flower.

**Decision**: Requires pattern detection infrastructure and approval workflow (deferred).

### Phase 6: Thorn/Grass Analytics

**Vision**: Dashboard showing:
- Thorn trends (open count over time, by severity)
- Mean time to acknowledge (MTTA), mean time to resolve (MTTR)
- Top sources of Thorns (which workflows generate most incidents)
- Grass review rate (how many reviewed per day, promotion rate)

**Decision**: Build after sufficient operational data collected (6+ months).

### Phase 7: Thorn Assignment & Escalation

**Vision**: Assign Thorns to specific users or teams:
- Thorn extension adds `assigned_to_user_id` field
- Assignment based on source_workflow or severity
- Escalation if not acknowledged within SLA

**Decision**: Requires team/role model in qxb_workspace_user (deferred).

---

## Implementation Checklist (For Master Joel + Build Assistants)

Before implementing Thorns and Grass, complete these steps:

### 1. Database Schema
- [ ] Create `qxb_artifact_thorn` extension table (SQL from Section 5)
- [ ] Create `qxb_artifact_grass` extension table (SQL from Section 5)
- [ ] Add indexes for operational queries
- [ ] Create RLS policies for Thorn/Grass (following existing artifact pattern)
- [ ] Update KGB test pack to include Thorn and Grass sample artifacts
- [ ] Run KGB regression to verify no breakage

### 2. Gateway Integration
- [ ] Update `NQxb_Artifact_Save_v1` to support `artifact_type: "thorn"` and `"grass"`
- [ ] Update `NQxb_Artifact_Query_v1` to support Thorn/Grass queries (spine + extension join)
- [ ] Update `NQxb_Artifact_List_v1` to support Thorn/Grass filtering (status, review_status, severity)
- [ ] Test save/query/list for Thorns and Grass using KGB test IDs

### 3. n8n Detection Workflows
- [ ] Create `NQxb_Create_Thorn` helper workflow (accepts error context, creates Thorn artifact)
- [ ] Create `NQxb_Create_Grass` helper workflow (accepts notice context, creates Grass artifact)
- [ ] Update existing workflows to call Create_Thorn on critical errors
- [ ] Update existing workflows to call Create_Grass on warnings/notices

### 4. Claude Code Integration
- [ ] Document Thorn diagnosis protocol in CLAUDE.md
- [ ] Define safe auto-fix allow-list in governance doc
- [ ] Implement Thorn query/update via Gateway
- [ ] Test CC diagnosis and patch proposal flow

### 5. Documentation
- [ ] Update CLAUDE.md with Thorn/Grass handling rules
- [ ] Update schema execution order doc to include Thorn/Grass tables
- [ ] Create user guide for reviewing Grass and triaging Thorns
- [ ] Document Grass → Flower promotion workflow

### 6. Testing & Validation
- [ ] Create manual test scenarios for Thorn creation, acknowledgment, resolution
- [ ] Create manual test scenarios for Grass creation, review, promotion, dismissal
- [ ] Run full KGB regression after all changes
- [ ] Document rollback plan for Thorn/Grass schema

---

## Compatibility with Qwrk V2 Truth Hierarchy

### Alignment with Binding Truth

**1. Behavioral Controls (Governing Constitution)**
- ✅ CC treated as mechanic, not architect
- ✅ No silent overwrites (all changes versioned)
- ✅ Approval gates for fixes
- ✅ Versioning discipline enforced

**2. Qwrk V2 North Star (v0.1)**
- ✅ Workspace-first, artifact-centric model preserved
- ✅ Spine + extension pattern followed
- ✅ No changes to existing artifact types

**3. Kernel v1 Snapshots (Pre/Post KGB)**
- ✅ New tables follow existing schema patterns
- ✅ RLS policies use existing helper functions
- ✅ KGB regression required before merge

**4. Phase 1-3 Locks**
- ✅ No changes to locked semantics (project, journal, restart, snapshot)
- ✅ Gateway contract extended, not broken
- ✅ Type schemas follow existing patterns

**5. Known-Good n8n Workflow Snapshots**
- ✅ Existing workflows unchanged
- ✅ New detection workflows additive only
- ✅ KGB baseline updated to include Thorn/Grass

### No Schema Guessing

**This document does NOT guess:**
- ❌ Exact RLS policy SQL (deferred to implementation following existing patterns)
- ❌ n8n workflow node implementations (high-level operational loop only)
- ❌ CC diagnostic algorithms (CC determines based on observed patterns)
- ❌ Thorn/Grass UI components (non-binding list view guidance only)

**This document DOES define:**
- ✅ Extension table schemas (Section 5)
- ✅ Status/review_status enums (Section 2)
- ✅ Operational loop phases (Section 4)
- ✅ Governance rules (Section 6)

---

## Questions for Master Joel (Requiring Decisions)

Before implementing, resolve these design questions:

1. **Severity Auto-Assignment**: Should n8n workflows auto-assign severity based on error type, or should all Thorns start at a default severity (e.g., 3) and be manually adjusted?

2. **Ops Team Access**: Should Thorns have special RLS policies allowing an "ops team" role to read/update all workspace Thorns, or follow standard owner/admin model?

3. **Grass Promotion UX**: Should Grass → Flower promotion create a new Flower with a link back to the Grass (via parent_artifact_id), or should it copy Grass details into Flower and mark Grass as promoted?

4. **Auto-Fix Allow-List**: Which specific fix types should be on the Tier 2 safe auto-fix allow-list? (Examples provided in Section 6, but need explicit approval)

5. **Retention Policy**: Should resolved Thorns and dismissed Grass be auto-archived or deleted after N days, or kept indefinitely for historical analysis?

6. **Thorn Notification**: Should Thorn creation trigger immediate notifications (email, Slack, etc.), or only surface in list views?

---

## Conclusion

Thorns and Grass introduce **operational artifact types** to Qwrk V2, enabling systematic incident response and review triage separate from planned to-dos (Flowers).

**Key Design Principles:**
- First-class artifact types with dedicated extension tables
- Incident lifecycle (Thorns) vs. review disposition (Grass)
- n8n detection → CC diagnosis → human approval → fix application
- Versioning discipline and KGB regression required
- CC operates as mechanic with explicit approval gates

**Implementation Status**: Design specification complete. Awaiting Master Joel decisions on open questions before schema implementation.

**Next Steps**:
1. Resolve design questions (Section: Questions for Master Joel)
2. Implement database schema (Section 5)
3. Update Gateway workflows (Section 3)
4. Create n8n detection workflows (Section 4)
5. Update CLAUDE.md with Thorn/Grass handling rules
6. Run KGB regression and create snapshot

---

**End of Document**
