# KGB Proof: Gateway v1 artifact.update

---

## Snapshot Metadata

| Field | Value |
|-------|-------|
| Snapshot Type | KGB Proof |
| Kernel | Gateway v1 |
| Date (UTC) | 2026-01-17 |
| Snapshot Artifact ID | 0452fab4-cb93-438c-a706-856c1841769e |
| Verified Project Artifact ID | e9601873-9f71-4843-bd81-9ecaccbbf9e3 |
| Workspace ID | be0d3a48-c764-44f9-90c8-e846d9dbbd0a |
| Gateway Webhook | https://n8n.halosparkai.com/webhook/nqxb/gateway/v1 |

---

## 1. Purpose

This snapshot proves that Gateway v1 `artifact.update` has reached Known-Good Baseline (KGB) state. The update operation executes end-to-end, persists extension fields to the database, and returns a stable acknowledgment without invoking an internal query. Verification is performed via a separate hydrated `artifact.query` call. This proof authorizes locking the `artifact.update` contract for Gateway v1.

---

## 2. Scope

### Covered

- `artifact.update` action routing through Gateway v1
- Mutability Registry v1 enforcement for project artifacts
- Update of `operational_state` and `state_reason` fields in `qxb_artifact_project`
- Stable acknowledgment response without internal query invocation
- Verification of persisted fields via separate `artifact.query` with hydration

### Not Covered

- Update operations for journal, snapshot, or restart artifact types (blocked per Mutability Registry v1)
- `lifecycle_stage` mutation (PROMOTE_ONLY per Mutability Registry v1)
- `deleted_at` mutation (UNDECIDED_BLOCKED per Mutability Registry v1)
- Concurrent update behavior
- RLS policy enforcement testing

---

## 3. Preconditions

1. Gateway v1 workflow (`NQxb_Gateway_v1`) deployed and active
2. Update sub-workflow (`NQxb_Artifact_Update_v1`) deployed and active
3. Query sub-workflow (`NQxb_Artifact_Query_v1`) deployed and active
4. Supabase Kernel v1 schema present with `qxb_artifact` and `qxb_artifact_project` tables
5. Project artifacts require `extension.lifecycle_stage` on insert
6. MVP owner-only mode active (workspace locked to `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`)

---

## 4. Test Sequence (Authoritative)

### Step 1: artifact.save (Create Project Artifact)

- Action: `artifact.save`
- Artifact Type: `project`
- Workspace ID: `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- Required Fields:
  - `title`: KGB test title
  - `summary`: KGB test summary
  - `extension.lifecycle_stage`: `sapling`
- Expected Result: Spine row created in `qxb_artifact`, extension row created in `qxb_artifact_project`
- Returned Artifact ID: `e9601873-9f71-4843-bd81-9ecaccbbf9e3`

### Step 2: artifact.update (Mutate Project Extension)

- Action: `artifact.update`
- Artifact Type: `project`
- Artifact ID: `e9601873-9f71-4843-bd81-9ecaccbbf9e3`
- Workspace ID: `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- Extension Fields:
  - `operational_state`: `paused`
  - `state_reason`: `KGB verify update via query - 2026-01-17`
- Expected Result: Acknowledgment response with `ok: true` and `_kgb.status: UPDATE_CONFIRMED`
- Expected Behavior: No internal `artifact.query` invocation during update execution

### Step 3: artifact.query (Verify Persisted State)

- Action: `artifact.query`
- Artifact Type: `project`
- Artifact ID: `e9601873-9f71-4843-bd81-9ecaccbbf9e3`
- Workspace ID: `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- Selector: `hydrate: true`
- Expected Result: Full artifact with spine fields and extension fields merged
- Verification Target: Confirm `operational_state` and `state_reason` match Step 2 input

---

## 5. Expected Behavior

### Update Acknowledgment

The `artifact.update` action returns a stable acknowledgment envelope:

```json
{
  "ok": true,
  "gw_action": "artifact.update",
  "operation": "UPDATE",
  "artifact_id": "<artifact_id>",
  "artifact_type": "project",
  "gw_workspace_id": "<workspace_id>",
  "updated_fields": ["operational_state", "state_reason"],
  "_kgb": {
    "status": "UPDATE_CONFIRMED",
    "note": "Update completed. Query intentionally not invoked."
  }
}
```

### No Internal Query

The update workflow terminates at `NQxb_Artifact_Update_v1__Return_Update_Ack` without invoking `NQxb_Artifact_Query_v1`. The `Call 'NQxb_Artifact_Query_v1'` node exists in the workflow but is intentionally disconnected.

### Extension Field Persistence

Updated extension fields are persisted to `qxb_artifact_project` and returned by a subsequent `artifact.query` call with hydration enabled.

---

## 6. Verified Evidence

### Update Response Values

| Field | Verified Value |
|-------|----------------|
| `ok` | `true` |
| `gw_action` | `artifact.update` |
| `operation` | `UPDATE` |
| `artifact_id` | `e9601873-9f71-4843-bd81-9ecaccbbf9e3` |
| `artifact_type` | `project` |
| `_kgb.status` | `UPDATE_CONFIRMED` |

### Query Response Values (Post-Update Verification)

| Field | Verified Value |
|-------|----------------|
| `extension.lifecycle_stage` | `sapling` |
| `extension.operational_state` | `paused` |
| `extension.state_reason` | Prefix: `KGB verify update via query` |

### Mutability Enforcement

| Artifact Type | Update Attempted | Result |
|---------------|------------------|--------|
| `project` | `operational_state`, `state_reason` | Allowed |
| `project` | `lifecycle_stage` | Blocked (PROMOTE_ONLY) |
| `snapshot` | Any field | Blocked (IMMUTABLE) |
| `restart` | Any field | Blocked (IMMUTABLE) |
| `journal` | Any field | Blocked (UNDECIDED_BLOCKED) |

---

## 7. Kernel Assertions

The following invariants are now locked for Gateway v1:

- `artifact.update` is UPDATE-ONLY; it requires a valid `artifact_id` and rejects creation attempts
- `artifact.update` does not invoke `artifact.query` internally; verification is performed externally
- `artifact.update` returns a stable acknowledgment with `_kgb.status: UPDATE_CONFIRMED`
- For `project` artifacts, only `operational_state` and `state_reason` are UPDATE_ALLOWED
- `lifecycle_stage` is PROMOTE_ONLY and cannot be mutated via `artifact.update`
- `snapshot` and `restart` artifacts are fully immutable (CREATE_ONLY)
- `journal` artifacts are INSERT-ONLY until mutability policy is locked (UNDECIDED_BLOCKED)
- `deleted_at` is UNDECIDED_BLOCKED across all artifact types
- Mutability Registry v1 is enforced at the workflow level before any database mutation

---

## 8. Lock Declaration

Gateway Kernel v1 `artifact.update` is hereby locked as of 2026-01-17.

The following contracts are immutable:

- Request envelope: `gw_action`, `gw_workspace_id`, `artifact_type`, `artifact_id`, `extension`
- Response envelope: `ok`, `gw_action`, `operation`, `artifact_id`, `artifact_type`, `updated_fields`, `_kgb`
- Mutability Registry v1 enforcement rules

Any modification to the above contracts requires a versioned update (Gateway v2 or Mutability Registry v2) with explicit migration documentation.

---

**End of KGB Proof**
