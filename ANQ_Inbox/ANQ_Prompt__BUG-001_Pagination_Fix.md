# ANQ Prompt — BUG-001: Pagination Fix (OFFSET + ORDER BY)

**Date:** 2026-01-27
**Workflow:** NQxb_Artifact_List_v1
**Current Version:** v24
**Target Version:** v25

---

## The Bug (Confirmed)

When `artifact.list` is called with different `offset` values, **the same artifact is returned every time**.

**Test Results:**
```
offset=0, limit=1 → artifact_id: 83b07ebb-19ab-4ec1-b202-cf3f0b3f7d53
offset=1, limit=1 → artifact_id: 83b07ebb-19ab-4ec1-b202-cf3f0b3f7d53
offset=2, limit=1 → artifact_id: 83b07ebb-19ab-4ec1-b202-cf3f0b3f7d53
```

All three return the same artifact. **Pagination is broken.**

**Root Cause:** The n8n Supabase "Get many rows" node does not support:
- ORDER BY (results come back in arbitrary order)
- OFFSET (only limit is passed to DB)

---

## The Fix

Replace the Supabase "Get many rows" node with an **HTTP Request to PostgREST**, which supports full ORDER BY + OFFSET + LIMIT.

**CC has already generated the fixed v25 workflow JSON.**

---

## Step-by-Step Instructions

**IMPORTANT:** Take Joel through these steps ONE AT A TIME. Wait for confirmation after each step before proceeding.

### Step 1 — Import the Fixed Workflow

1. In n8n, go to the workflow list
2. Click "Import from File"
3. Select: `workflows/NQxb_Artifact_List_v1 (25).json`
4. n8n will create a new workflow with the fixes already applied

### Step 2 — Review the New Nodes

The v25 workflow replaces the broken Supabase node with two new nodes:

| Old Node | New Nodes |
|----------|-----------|
| `Get many rows` (Supabase) | `Build_PostgREST_Request` (Code) + `HTTP_Request_List` (HTTP Request) |

**Build_PostgREST_Request** constructs a PostgREST query with:
- `order=created_at.desc,artifact_id.desc` — deterministic ordering
- `offset={{offset}}` — actual offset passed to database
- `limit={{limit+1}}` — for has_more detection
- `created_at=lte.{{as_of}}` — paging anchor filter

**HTTP_Request_List** executes the query using Supabase credentials.

### Step 3 — Verify HTTP Request Node Configuration

1. Open the `HTTP_Request_List` node
2. Check the URL field — it should reference `$credentials.supabaseApi.host`
3. Check Authentication — should be "Predefined Credential Type" → "Supabase API"
4. Credential should be: `Qwrk Supabase – Kernel v1`

**If the URL doesn't resolve correctly:**
- The URL pattern should be: `https://YOUR_PROJECT.supabase.co{{ $json._postgrest.path }}`
- You may need to manually set the base URL if `$credentials.supabaseApi.host` doesn't work

### Step 4 — Test with Pinned Data (Basic)

1. Use the existing pinned test data (project, limit=10, hydrate=true)
2. Execute workflow
3. Verify: Response returns multiple projects (confirms BUG-005 fix still works)

### Step 5 — Test Pagination (Critical)

Run these three requests through the workflow (update pinned data for each):

**Test A:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "artifact_type": "project",
    "limit": 1,
    "offset": 0,
    "hydrate": false
  }
}
```

**Test B:** Same but `offset: 1`

**Test C:** Same but `offset: 2`

**Expected Result:** Each test returns a DIFFERENT artifact_id.

If all three return the same artifact_id → fix didn't work, troubleshoot HTTP Request node.

### Step 6 — Test via Qwrk Front-End

1. Run: `artifact.list` with `artifact_type=project`, `limit=1`, `offset=0`
2. Note the artifact_id
3. Run: `artifact.list` with `artifact_type=project`, `limit=1`, `offset=1`
4. Note the artifact_id
5. **Verify:** The two artifact_ids are DIFFERENT

### Step 7 — Activate and Deactivate Old Version

1. If tests pass, activate the new v25 workflow
2. Deactivate the old v24 workflow (do not delete yet)

---

## Success Criteria

- [ ] Different offsets return different artifacts
- [ ] Results are ordered by created_at DESC (newest first)
- [ ] Hydration still works (BUG-005 regression check)
- [ ] meta.has_more is accurate
- [ ] meta.offset reflects the requested offset

---

## Troubleshooting

**If HTTP Request fails with 401/403:**
- Check that the Supabase credential is selected
- Verify the credential has the correct API key

**If HTTP Request fails with 404:**
- The URL base may be wrong
- Check that the path starts with `/rest/v1/qxb_artifact`

**If results are still duplicated:**
- Check the `Build_PostgREST_Request` node output
- Verify the `order` and `offset` params are in the URL

---

## File Location

Fixed workflow JSON: `workflows/NQxb_Artifact_List_v1 (25).json`

---

**End of prompt.**
