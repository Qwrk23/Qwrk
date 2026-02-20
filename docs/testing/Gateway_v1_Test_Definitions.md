# Gateway v1 — Comprehensive Test Definitions

**Purpose:** This document defines all tests required to validate the 6 Gateway workflows before front-end development begins. Each test definition includes the action, inputs, expected behavior, and success criteria.

**Date:** 2026-01-18
**Target:** ANQ to generate PowerShell scripts for each test

---

## ANQ Prompt Instructions

You are generating PowerShell test scripts for the Qwrk V2 Gateway. Each test should:

1. Call the Gateway webhook endpoint with the specified payload
2. Validate the response matches expected behavior
3. Output PASS/FAIL with details
4. Be executable one at a time until it passes

**Gateway Endpoint:** `{{GATEWAY_WEBHOOK_URL}}`
**Method:** POST
**Content-Type:** application/json

---

## Test Suite 1: artifact.save (CREATE ONLY)

### Test 1.1: Save Project — Happy Path
**Action:** `artifact.save`
**Description:** Create a new project artifact with all required fields

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "title": "Test Project - Gateway Validation",
  "summary": "Created by automated test suite",
  "priority": 3,
  "extension": {
    "lifecycle_status": "seed",
    "operational_state": "active"
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifact_id` (UUID)
- Response contains `artifact_type: "project"`
- Response contains `lifecycle_status: "seed"`

**Success Criteria:** Artifact ID returned, all fields echo correctly

---

### Test 1.2: Save Journal — Happy Path
**Action:** `artifact.save`
**Description:** Create a new journal artifact

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "journal",
  "title": "Test Journal Entry",
  "summary": "Gateway validation journal",
  "priority": 4,
  "extension": {
    "body": "This is a test journal entry for Gateway validation."
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifact_id` (UUID)
- Response contains `artifact_type: "journal"`

**Success Criteria:** Journal artifact created successfully

---

### Test 1.3: Save Snapshot — Happy Path
**Action:** `artifact.save`
**Description:** Create a snapshot artifact with parent_artifact_id referencing a project

**Prerequisite:** Use artifact_id from Test 1.1 as parent

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "snapshot",
  "title": "Snapshot of Test Project",
  "summary": "Lifecycle transition snapshot",
  "parent_artifact_id": "{{PROJECT_ARTIFACT_ID_FROM_TEST_1.1}}",
  "extension": {
    "lifecycle_from": "seed",
    "lifecycle_to": "sapling",
    "frozen_payload": {}
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifact_id` (UUID)
- Response contains `artifact_type: "snapshot"`
- Response contains `parent_artifact_id` matching input

**Success Criteria:** Snapshot created with correct parent lineage

---

### Test 1.4: Save Restart — Happy Path
**Action:** `artifact.save`
**Description:** Create a restart artifact

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "restart",
  "title": "Daily Restart - Test",
  "summary": "Pausing work for the day",
  "parent_artifact_id": "{{PROJECT_ARTIFACT_ID_FROM_TEST_1.1}}",
  "extension": {
    "restart_reason": "End of day pause",
    "next_step": "Continue with validation tests"
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifact_id` (UUID)
- Response contains `artifact_type: "restart"`

**Success Criteria:** Restart artifact created successfully

---

### Test 1.5: Save — Missing Required Field (gw_workspace_id)
**Action:** `artifact.save`
**Description:** Attempt to save without gw_workspace_id — should fail validation

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "artifact_type": "project",
  "title": "Missing Workspace Test"
}
```

**Expected Behavior:**
- Error response with code: `VALIDATION_ERROR` or `MISSING_REQUIRED_FIELD`
- Error message indicates gw_workspace_id is required

**Success Criteria:** Request rejected with appropriate error

---

### Test 1.6: Save — Missing Required Field (artifact_type)
**Action:** `artifact.save`
**Description:** Attempt to save without artifact_type — should fail validation

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "title": "Missing Type Test"
}
```

**Expected Behavior:**
- Error response with code: `VALIDATION_ERROR` or `MISSING_REQUIRED_FIELD`
- Error message indicates artifact_type is required

**Success Criteria:** Request rejected with appropriate error

---

### Test 1.7: Save — Invalid Artifact Type
**Action:** `artifact.save`
**Description:** Attempt to save with invalid artifact_type — should fail validation

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "invalid_type",
  "title": "Invalid Type Test"
}
```

**Expected Behavior:**
- Error response with code: `INVALID_ARTIFACT_TYPE` or `VALIDATION_ERROR`
- Error message indicates artifact_type not in allow-list

**Success Criteria:** Request rejected with appropriate error

---

## Test Suite 2: artifact.query (Single Artifact Fetch)

### Test 2.1: Query Project — Happy Path
**Action:** `artifact.query`
**Description:** Fetch a project by artifact_id

**Prerequisite:** Use artifact_id from Test 1.1

**Input Payload:**
```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{PROJECT_ARTIFACT_ID_FROM_TEST_1.1}}"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains full artifact with hydrated fields
- Response contains `artifact_id` matching input
- Response contains `artifact_type: "project"`
- Response contains extension table fields (operational_state, etc.)

**Success Criteria:** Artifact returned with all hydrated fields

---

### Test 2.2: Query Journal — Happy Path with Hydration
**Action:** `artifact.query`
**Description:** Fetch a journal and verify hydration merges extension table data

**Prerequisite:** Use artifact_id from Test 1.2

**Input Payload:**
```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "journal",
  "artifact_id": "{{JOURNAL_ARTIFACT_ID_FROM_TEST_1.2}}"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains hydrated artifact
- Extension table fields merged into response

**Success Criteria:** Hydration works correctly for journal type

---

### Test 2.3: Query — NOT_FOUND Error
**Action:** `artifact.query`
**Description:** Query with non-existent artifact_id — should return NOT_FOUND

**Input Payload:**
```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "00000000-0000-0000-0000-000000000000"
}
```

**Expected Behavior:**
- Error response with code: `NOT_FOUND`
- Error message indicates artifact does not exist

**Success Criteria:** NOT_FOUND error returned correctly

---

### Test 2.4: Query — TYPE_MISMATCH Error
**Action:** `artifact.query`
**Description:** Query a project artifact_id but specify artifact_type as journal — should return TYPE_MISMATCH

**Prerequisite:** Use artifact_id from Test 1.1 (a project)

**Input Payload:**
```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "journal",
  "artifact_id": "{{PROJECT_ARTIFACT_ID_FROM_TEST_1.1}}"
}
```

**Expected Behavior:**
- Error response with code: `TYPE_MISMATCH`
- Error message indicates artifact_type does not match

**Success Criteria:** TYPE_MISMATCH error returned correctly

---

### Test 2.5: Query — Missing artifact_id
**Action:** `artifact.query`
**Description:** Query without artifact_id — should fail validation

**Input Payload:**
```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project"
}
```

**Expected Behavior:**
- Error response with code: `VALIDATION_ERROR` or `MISSING_REQUIRED_FIELD`
- Error message indicates artifact_id is required for query

**Success Criteria:** Request rejected with appropriate error

---

## Test Suite 3: artifact.list (Paginated List)

### Test 3.1: List Projects — Happy Path (Default Pagination)
**Action:** `artifact.list`
**Description:** List all projects in workspace with default pagination

**Input Payload:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifacts` array
- Each artifact in array is hydrated (extension fields merged)
- `lifecycle_stage` is NOT present (stripped per governance)
- `lifecycle_status` IS present

**Success Criteria:** List returned with hydrated artifacts and correct pagination

---

### Test 3.2: List Projects — Custom Limit
**Action:** `artifact.list`
**Description:** List projects with custom limit of 5

**Input Payload:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "selector": {
    "limit": 5
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains at most 5 artifacts

**Success Criteria:** Limit respected correctly

---

### Test 3.3: List Projects — Offset Pagination
**Action:** `artifact.list`
**Description:** List projects with offset to test pagination

**Input Payload:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "selector": {
    "limit": 5,
    "offset": 5
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains artifacts starting from position 6

**Success Criteria:** Offset pagination works correctly

---

### Test 3.4: List Projects — Limit Exceeds Maximum (200)
**Action:** `artifact.list`
**Description:** Request limit of 500 — should be capped at 200

**Input Payload:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "selector": {
    "limit": 500
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Returned artifacts capped at 200
- No error thrown

**Success Criteria:** Limit correctly capped at 200

---

### Test 3.5: List Journals — Empty Results
**Action:** `artifact.list`
**Description:** List journals in a workspace that has none (or use filter that returns empty)

**Input Payload:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "journal",
  "selector": {
    "offset": 99999
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains empty `artifacts` array: `[]`
- No error thrown for empty results

**Success Criteria:** Empty results handled gracefully

---

### Test 3.6: List — Verify lifecycle_stage Stripping
**Action:** `artifact.list`
**Description:** Verify that lifecycle_stage is stripped from list responses per governance

**Input Payload:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "selector": {
    "limit": 10
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Each artifact in response does NOT contain `lifecycle_stage` field
- Each artifact DOES contain `lifecycle_status` field

**Success Criteria:** lifecycle_stage correctly stripped, lifecycle_status present

---

### Test 3.7: List — Missing gw_workspace_id
**Action:** `artifact.list`
**Description:** List without gw_workspace_id — should fail validation

**Input Payload:**
```json
{
  "gw_action": "artifact.list",
  "artifact_type": "project"
}
```

**Expected Behavior:**
- Error response with code: `VALIDATION_ERROR` or `MISSING_REQUIRED_FIELD`
- Error message indicates gw_workspace_id is required

**Success Criteria:** Request rejected with appropriate error

---

## Test Suite 4: artifact.update (Mutability Enforcement)

### Test 4.1: Update Project operational_state — Happy Path
**Action:** `artifact.update`
**Description:** Update a project's operational_state from active to paused (allowed per Mutability Registry)

**Prerequisite:** Use artifact_id from Test 1.1

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{PROJECT_ARTIFACT_ID_FROM_TEST_1.1}}",
  "extension": {
    "operational_state": "paused",
    "state_reason": "Testing pause functionality"
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains acknowledgment: `UPDATE_CONFIRMED` or similar

**Success Criteria:** operational_state update accepted

---

### Test 4.2: Update Project state_reason — Happy Path
**Action:** `artifact.update`
**Description:** Update only state_reason (allowed field)

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{PROJECT_ARTIFACT_ID_FROM_TEST_1.1}}",
  "extension": {
    "state_reason": "Updated reason for testing"
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `UPDATE_CONFIRMED`

**Success Criteria:** state_reason update accepted

---

### Test 4.3: Update Project lifecycle_status — BLOCKED (Promote Only)
**Action:** `artifact.update`
**Description:** Attempt to update lifecycle_status directly — should be blocked (use artifact.promote instead)

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{PROJECT_ARTIFACT_ID_FROM_TEST_1.1}}",
  "extension": {
    "lifecycle_status": "tree"
  }
}
```

**Expected Behavior:**
- Error response with code: `MUTABILITY_ERROR` or `PROMOTE_ONLY`
- Error message indicates lifecycle_status can only be changed via artifact.promote

**Success Criteria:** lifecycle_status update correctly blocked

---

### Test 4.4: Update Project title — BLOCKED (Not in Allowed Fields)
**Action:** `artifact.update`
**Description:** Attempt to update title on a project — should be blocked per Mutability Registry v1

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{PROJECT_ARTIFACT_ID_FROM_TEST_1.1}}",
  "extension": {
    "title": "Attempted Title Change"
  }
}
```

**Expected Behavior:**
- Error response with code: `MUTABILITY_ERROR`
- Error message indicates title is not in allowed update fields for project

**Success Criteria:** Title update correctly blocked

---

### Test 4.5: Update Snapshot — IMMUTABLE Error
**Action:** `artifact.update`
**Description:** Attempt any update on a snapshot — should return IMMUTABILITY_ERROR

**Prerequisite:** Use artifact_id from Test 1.3

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "snapshot",
  "artifact_id": "{{SNAPSHOT_ARTIFACT_ID_FROM_TEST_1.3}}",
  "extension": {
    "title": "Attempted Snapshot Update"
  }
}
```

**Expected Behavior:**
- Error response with code: `IMMUTABILITY_ERROR`
- Error message indicates snapshots are fully immutable

**Success Criteria:** Snapshot update correctly blocked

---

### Test 4.6: Update Restart — IMMUTABLE Error
**Action:** `artifact.update`
**Description:** Attempt any update on a restart — should return IMMUTABILITY_ERROR

**Prerequisite:** Use artifact_id from Test 1.4

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "restart",
  "artifact_id": "{{RESTART_ARTIFACT_ID_FROM_TEST_1.4}}",
  "extension": {
    "title": "Attempted Restart Update"
  }
}
```

**Expected Behavior:**
- Error response with code: `IMMUTABILITY_ERROR`
- Error message indicates restarts are fully immutable

**Success Criteria:** Restart update correctly blocked

---

### Test 4.7: Update Journal — UNDECIDED_BLOCKED
**Action:** `artifact.update`
**Description:** Attempt update on journal — should return UNDECIDED_BLOCKED (policy not yet defined)

**Prerequisite:** Use artifact_id from Test 1.2

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "journal",
  "artifact_id": "{{JOURNAL_ARTIFACT_ID_FROM_TEST_1.2}}",
  "extension": {
    "title": "Attempted Journal Update"
  }
}
```

**Expected Behavior:**
- Error response with code: `UNDECIDED_BLOCKED` or `MUTABILITY_ERROR`
- Error message indicates journal mutability policy is undecided

**Success Criteria:** Journal update correctly blocked

---

### Test 4.8: Update — Non-existent Artifact
**Action:** `artifact.update`
**Description:** Attempt update on non-existent artifact_id

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "00000000-0000-0000-0000-000000000000",
  "extension": {
    "operational_state": "paused"
  }
}
```

**Expected Behavior:**
- Error response with code: `NOT_FOUND`
- Error message indicates artifact does not exist

**Success Criteria:** NOT_FOUND error returned

---

## Test Suite 5: artifact.promote (Lifecycle Transitions)

### Test 5.1: Promote seed_to_sapling — Happy Path
**Action:** `artifact.promote`
**Description:** Promote a project from seed to sapling

**Prerequisite:** Create a new project with lifecycle_status: "seed"

**Setup Payload (create test project):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "title": "Promote Test - Seed to Sapling",
  "extension": {
    "lifecycle_status": "seed"
  }
}
```

**Promote Payload:**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{NEW_PROJECT_ARTIFACT_ID}}",
  "transition": "seed_to_sapling"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response confirms new lifecycle_status: "sapling"
- Event inserted into qxb_artifact_event table

**Success Criteria:** Lifecycle transitioned to sapling

---

### Test 5.2: Promote sapling_to_tree — Happy Path
**Action:** `artifact.promote`
**Description:** Promote a project from sapling to tree

**Prerequisite:** Use artifact from Test 5.1 (now in sapling state)

**Input Payload:**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{SAPLING_PROJECT_ARTIFACT_ID}}",
  "transition": "sapling_to_tree"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response confirms new lifecycle_status: "tree"
- Event inserted into qxb_artifact_event

**Success Criteria:** Lifecycle transitioned to tree

---

### Test 5.3: Promote tree_to_retired — Happy Path
**Action:** `artifact.promote`
**Description:** Retire a tree project

**Prerequisite:** Use artifact from Test 5.2 (now in tree state)

**Input Payload:**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{TREE_PROJECT_ARTIFACT_ID}}",
  "transition": "tree_to_retired"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response confirms new lifecycle_status: "retired"
- Event inserted into qxb_artifact_event

**Success Criteria:** Lifecycle transitioned to retired

---

### Test 5.4: Promote retired_to_tree — Reactivation
**Action:** `artifact.promote`
**Description:** Reactivate a retired project back to tree

**Prerequisite:** Use artifact from Test 5.3 (now in retired state)

**Input Payload:**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{RETIRED_PROJECT_ARTIFACT_ID}}",
  "transition": "retired_to_tree"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response confirms new lifecycle_status: "tree"
- Event inserted into qxb_artifact_event

**Success Criteria:** Lifecycle transitioned back to tree

---

### Test 5.5: Promote — LIFECYCLE_STATE_MISMATCH Error
**Action:** `artifact.promote`
**Description:** Attempt seed_to_sapling on a project that is already a tree — should fail

**Prerequisite:** Use a project currently in "tree" state

**Input Payload:**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{TREE_PROJECT_ARTIFACT_ID}}",
  "transition": "seed_to_sapling"
}
```

**Expected Behavior:**
- Error response with code: `LIFECYCLE_STATE_MISMATCH`
- Error message indicates current state (tree) does not match expected from_state (seed)

**Success Criteria:** State mismatch correctly detected and rejected

---

### Test 5.6: Promote — Invalid Transition Key
**Action:** `artifact.promote`
**Description:** Attempt promotion with invalid transition key

**Input Payload:**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{ANY_PROJECT_ARTIFACT_ID}}",
  "transition": "invalid_transition"
}
```

**Expected Behavior:**
- Error response with code: `INVALID_TRANSITION` or `VALIDATION_ERROR`
- Error message indicates transition key not in allowed map

**Success Criteria:** Invalid transition rejected

---

### Test 5.7: Promote — Non-existent Artifact
**Action:** `artifact.promote`
**Description:** Attempt promotion on non-existent artifact_id

**Input Payload:**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "00000000-0000-0000-0000-000000000000",
  "transition": "seed_to_sapling"
}
```

**Expected Behavior:**
- Error response with code: `NOT_FOUND`
- Error message indicates artifact does not exist

**Success Criteria:** NOT_FOUND error returned

---

### Test 5.8: Promote — Repeat Guard (Same Transition Twice)
**Action:** `artifact.promote`
**Description:** Attempt the same transition twice in a row — second should fail

**Prerequisite:** Create new seed project, promote to sapling successfully, then try again

**Input Payload (second attempt after successful promotion):**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{SAPLING_PROJECT_ARTIFACT_ID}}",
  "transition": "seed_to_sapling"
}
```

**Expected Behavior:**
- Error response with code: `LIFECYCLE_STATE_MISMATCH`
- Current state is now "sapling", expected from_state is "seed"

**Success Criteria:** Repeat transition correctly blocked

---

## Test Suite 6: Gateway Routing and Error Handling

### Test 6.1: Invalid gw_action
**Action:** Invalid action
**Description:** Send request with invalid gw_action value

**Input Payload:**
```json
{
  "gw_action": "artifact.invalid_action",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project"
}
```

**Expected Behavior:**
- Error response with code: `INVALID_ACTION` or `UNKNOWN_ACTION`
- Error message indicates action not recognized

**Success Criteria:** Invalid action rejected with appropriate error

---

### Test 6.2: Missing gw_action
**Action:** None
**Description:** Send request without gw_action field

**Input Payload:**
```json
{
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project"
}
```

**Expected Behavior:**
- Error response with code: `VALIDATION_ERROR` or `MISSING_REQUIRED_FIELD`
- Error message indicates gw_action is required

**Success Criteria:** Missing action rejected

---

### Test 6.3: Malformed JSON
**Action:** N/A
**Description:** Send request with malformed JSON body

**Input Payload (raw string):**
```
{ "gw_action": "artifact.query", "artifact_id": missing_quotes }
```

**Expected Behavior:**
- Error response with code: `PARSE_ERROR` or `MALFORMED_REQUEST`
- HTTP status may be 400 Bad Request

**Success Criteria:** Malformed JSON handled gracefully

---

## Test Suite 7: artifact.save / artifact.list / artifact.query — instruction_pack

### Test 7.1: Save Instruction Pack — Happy Path (Global Scope)
**Action:** `artifact.save`
**Description:** Create a new instruction_pack artifact with scope=global

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "instruction_pack",
  "title": "Global Instruction Pack - Test",
  "summary": "GPT front-end global instructions",
  "tags": ["scope:global"],
  "content": {
    "pack_version": "1.0.0",
    "scope": "global",
    "invariants": ["Never surface lifecycle_stage"],
    "rules": ["Default hydrate = true"],
    "templates": {},
    "examples": []
  },
  "extension": {
    "scope": "global",
    "pack_version": "1.0.0",
    "active": true
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifact_id` (UUID)
- Response contains `artifact_type: "instruction_pack"`
- DB trigger creates extension row with matching scope

**Success Criteria:** Instruction pack created with scope enforcement

---

### Test 7.2: Save Instruction Pack — View:List Scope
**Action:** `artifact.save`
**Description:** Create an instruction_pack with scope=view:list

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "instruction_pack",
  "title": "List View Instructions - Test",
  "summary": "Formatting rules for list views",
  "tags": ["scope:view:list"],
  "content": {
    "pack_version": "1.0.0",
    "scope": "view:list",
    "invariants": [],
    "rules": ["Show numbered rows"],
    "templates": {"list_header": "Projects (N shown)"},
    "examples": []
  },
  "extension": {
    "scope": "view:list",
    "pack_version": "1.0.0",
    "active": true
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifact_id` (UUID)
- Extension row created with scope=view:list

**Success Criteria:** Instruction pack created with view:list scope

---

### Test 7.3: List Instruction Packs — Happy Path
**Action:** `artifact.list`
**Description:** List all instruction_pack artifacts in workspace

**Prerequisite:** Tests 7.1 and 7.2 completed successfully

**Input Payload:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "instruction_pack"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifacts` array with at least 2 items
- Each artifact contains scope in content or extension

**Success Criteria:** Instruction packs listed successfully

---

### Test 7.4: Query Instruction Pack — Happy Path
**Action:** `artifact.query`
**Description:** Query a specific instruction_pack by artifact_id

**Prerequisite:** Use artifact_id from Test 7.1

**Input Payload:**
```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "instruction_pack",
  "artifact_id": "{{INSTRUCTION_PACK_ARTIFACT_ID_FROM_TEST_7.1}}"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains full hydrated artifact
- Response contains content.scope matching extension.scope

**Success Criteria:** Instruction pack queried with hydration

---

### Test 7.5: Save Instruction Pack — Duplicate Scope (Should Fail or Replace)
**Action:** `artifact.save`
**Description:** Attempt to create a second active instruction_pack with same scope — behavior depends on DB constraint

**Prerequisite:** Test 7.1 completed (global scope pack exists)

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "instruction_pack",
  "title": "Duplicate Global Pack - Test",
  "summary": "Should fail due to unique constraint",
  "tags": ["scope:global"],
  "content": {
    "pack_version": "2.0.0",
    "scope": "global",
    "invariants": [],
    "rules": [],
    "templates": {},
    "examples": []
  },
  "extension": {
    "scope": "global",
    "pack_version": "2.0.0",
    "active": true
  }
}
```

**Expected Behavior:**
- Either: Error response with code indicating duplicate scope violation
- Or: Success if DB performs upsert/replace behavior

**Success Criteria:** One-active-per-scope constraint enforced (verify DB behavior)

---

### Test 7.6: Update Instruction Pack — Happy Path
**Action:** `artifact.update`
**Description:** Update an existing instruction_pack's content

**Prerequisite:** Use artifact_id from Test 7.1

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "instruction_pack",
  "artifact_id": "{{INSTRUCTION_PACK_ARTIFACT_ID_FROM_TEST_7.1}}",
  "extension": {
    "pack_version": "1.1.0"
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `UPDATE_CONFIRMED`
- Instruction pack is mutable (unlike snapshot/restart)

**Success Criteria:** Instruction pack update accepted

---

## Test Execution Order

For sequential dependencies, execute tests in this order:

1. **Test 1.1** (Save Project) — creates PROJECT_ARTIFACT_ID
2. **Test 1.2** (Save Journal) — creates JOURNAL_ARTIFACT_ID
3. **Test 1.3** (Save Snapshot) — uses PROJECT_ARTIFACT_ID
4. **Test 1.4** (Save Restart) — uses PROJECT_ARTIFACT_ID
5. Tests 1.5–1.7 (Save validation errors) — independent
6. **Test 2.1–2.5** (Query tests) — use saved artifact IDs
7. **Test 3.1–3.7** (List tests) — mostly independent
8. **Test 4.1–4.8** (Update tests) — use saved artifact IDs
9. **Test 5.1–5.8** (Promote tests) — sequential lifecycle progression
10. **Test 6.1–6.3** (Gateway routing) — independent
11. **Test 7.1** (Save Instruction Pack - Global) — creates INSTRUCTION_PACK_ARTIFACT_ID
12. **Test 7.2** (Save Instruction Pack - View:List) — independent
13. **Test 7.3** (List Instruction Packs) — depends on 7.1, 7.2
14. **Test 7.4** (Query Instruction Pack) — uses INSTRUCTION_PACK_ARTIFACT_ID from 7.1
15. **Test 7.5** (Duplicate Scope) — depends on 7.1 (tests constraint)
16. **Test 7.6** (Update Instruction Pack) — uses INSTRUCTION_PACK_ARTIFACT_ID from 7.1

---

## Variables to Configure Before Running

| Variable | Description |
|----------|-------------|
| `{{GATEWAY_WEBHOOK_URL}}` | Full URL to Gateway webhook endpoint |
| `{{TEST_WORKSPACE_ID}}` | UUID of test workspace in Qxb_Workspace |

---

## Success Criteria Summary

- All 50 tests pass (44 core + 6 instruction_pack)
- Error codes match expected values
- Hydration works correctly for all artifact types
- Mutability Registry v1 enforced correctly
- Lifecycle transitions follow allowed map
- Pagination behaves within bounds (limit: 1-200, window cap: 500)
- lifecycle_stage stripped from all list responses
- instruction_pack scope constraint enforced (one active per workspace+scope)

---

**End of Test Definitions**
