# T41 — Tags Update Contract Tests

**Workflow:** NQxb_Artifact_Update_v1 (v12)
**Created:** 2026-02-19
**Purpose:** Validate tags-only update path per Mutability Registry v2

---

## Test Artifacts (use existing KGB IDs)

| Type | artifact_id | Workspace |
|------|------------|-----------|
| snapshot | `610e16d1-c5bb-468c-bd35-57eadf9f2e38` | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |
| journal | `db428a32-1afa-4e6b-a649-347b0bffd46c` | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |
| project | `668bd18f-4424-41e6-b2f9-393ecd2ec534` | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |

---

## Test A — Snapshot Tag Add (MUST SUCCEED)

```json
{
  "action": "artifact.update",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "artifact_id": "610e16d1-c5bb-468c-bd35-57eadf9f2e38",
  "tags": {
    "add": ["t41-test"]
  }
}
```

**Expected:** `{ ok: true, operation: "TAG_UPDATE", tags: [..., "t41-test"] }`

---

## Test B — Journal Tag Add (MUST SUCCEED)

```json
{
  "action": "artifact.update",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "artifact_id": "db428a32-1afa-4e6b-a649-347b0bffd46c",
  "tags": {
    "add": ["t41-test"]
  }
}
```

**Expected:** `{ ok: true, operation: "TAG_UPDATE", tags: [..., "t41-test"] }`

---

## Test C — Journal Tag Remove (MUST SUCCEED)

```json
{
  "action": "artifact.update",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "artifact_id": "db428a32-1afa-4e6b-a649-347b0bffd46c",
  "tags": {
    "remove": ["t41-test"]
  }
}
```

**Expected:** `{ ok: true, operation: "TAG_UPDATE" }` — tag removed from array

---

## Test D — Journal Tag + Extension (MUST FAIL)

```json
{
  "action": "artifact.update",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "artifact_id": "db428a32-1afa-4e6b-a649-347b0bffd46c",
  "tags": {
    "add": ["should-not-apply"]
  },
  "extension": {
    "entry_text": "this should be blocked"
  }
}
```

**Expected:** `{ ok: false, error.code: "JOURNAL_MUTABILITY_UNDECIDED" }`
Tags NOT applied (extension presence triggers type-specific block).

---

## Test E — Project Tag Add (MUST SUCCEED)

```json
{
  "action": "artifact.update",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "668bd18f-4424-41e6-b2f9-393ecd2ec534",
  "tags": {
    "add": ["t41-test"]
  }
}
```

**Expected:** `{ ok: true, operation: "TAG_UPDATE", tags: [..., "t41-test"] }`

---

## Test F — Version Increments

Run Test A or Test B, then query the artifact. Verify:
- `version` is previous value + 1

```json
{
  "action": "artifact.query",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "artifact_id": "610e16d1-c5bb-468c-bd35-57eadf9f2e38"
}
```

**Expected:** `version` incremented from pre-test value.

---

## Test G — updated_at Changes

Run any tag update, then query the artifact. Verify:
- `updated_at` is more recent than `created_at`
- `updated_at` is more recent than pre-test value

**Expected:** Trigger `qxb_artifact_set_updated_at` fires on PATCH, updating timestamp.

---

## Test H — No Extension Mutation on Tags-Only

After running Test A (snapshot tag add), query the snapshot with hydration:

```json
{
  "action": "artifact.query",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "artifact_id": "610e16d1-c5bb-468c-bd35-57eadf9f2e38",
  "selector": { "hydrate": true }
}
```

**Expected:** Extension payload is IDENTICAL to pre-test state. Only `tags`, `version`, `updated_at` changed on spine.

---

## Cleanup

After all tests pass, remove `t41-test` tag from all test artifacts:

```json
{
  "action": "artifact.update",
  "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "artifact_id": "610e16d1-c5bb-468c-bd35-57eadf9f2e38",
  "tags": { "remove": ["t41-test"] }
}
```

(Repeat for journal and project test artifacts.)

---

## Dead-End Routing Verification

Before activation, visually confirm in n8n editor:

1. `Switch_Update_Mode` output 0 (tags_only) → `Compute_Tag_Merge` (connected)
2. `Switch_Update_Mode` fallback → `Switch_Type_For_Update` (connected)
3. `Switch_Mutability_Result` output 0 (error) → `Return_Error_Passthrough` (connected)
4. `Switch_Mutability_Result` output 2 (fallback) → `Return_Error_Passthrough` (connected)
5. `Switch_Type_Registry` output 0 (error) → `Return_Error_Passthrough` (connected)
6. All terminal nodes (`Return_Tags_Ack`, `Return_Update_Ack`, `Return_Error_Passthrough`) have no unconnected outputs downstream

**No orphaned branches. No dead ends.**
