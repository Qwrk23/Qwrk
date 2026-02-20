# ANQ Prompt — BUG-006: Hydration Spine Data Fix

**Date:** 2026-01-27
**Workflow:** NQxb_Artifact_List_v1
**Current Version:** v25
**Target Version:** v26

---

## The Bug (Confirmed)

When `artifact.list` is called with `hydrate=true`, **spine data is lost** and only extension fields are returned.

**Test Results (v25):**
```json
{
  "data": {
    "artifacts": [
      {
        "artifact_id": "4c439489-6921-49e8-94d5-9c76753bfb7e",
        "lifecycle_stage": "seed",
        "operational_state": "active",
        "state_reason": null,
        "created_at": "2026-01-26T23:25:30.309807+00:00",
        "updated_at": "2026-01-26T23:25:30.309807+00:00"
      }
    ]
  },
  "meta": {
    "count": 1,  // Should be 2!
    "limit": 2,
    "offset": 0,
    "has_more": false
  }
}
```

**Missing fields:** `title`, `summary`, `artifact_type`, `workspace_id`, `owner_user_id`, `tags`, `content`, `parent_artifact_id`

**Root Cause:**
In the Merge nodes (Merge_Project, Merge_Journal, Merge_Restart, Merge_Snapshot), the code assumed `$input.item.json` was the spine data. But actually:
1. Split Out produces spine items
2. DB_Get fetches extension rows
3. DB_Get's OUTPUT replaces the input — so Merge only sees extension data
4. `$input.item.json` in Merge is the extension, not the spine

---

## The Fix (v26)

All Merge nodes now use `$items()` to reference back to the Split Out node and retrieve spine data by matching `artifact_id`.

**New Merge Pattern:**
```javascript
// Get extension from current input (from DB_Get)
const extRaw = $input.item.json ?? {};
const artifact_id = extRaw.artifact_id;

// Get all spine items from Split Out node
const allSpineItems = $items("NQxb_Artifact_List_v1__Explode_Project_Page");

// Find matching spine
const spineItem = allSpineItems.find(item => item.json?.artifact_id === artifact_id);
const spine = spineItem?.json ?? {};

// Merge: spine first, then extension overlays
const merged = { ...spine, ...extFields };
```

---

## Step-by-Step Instructions

**IMPORTANT:** Take Joel through these steps ONE AT A TIME. Wait for confirmation after each step before proceeding.

### Step 1 — Import the Fixed Workflow

1. In n8n, go to the workflow list
2. Click "Import from File"
3. Select: `workflows/NQxb_Artifact_List_v1 (26).json`
4. n8n will create a new workflow with the fixes already applied

### Step 2 — Review the Key Changes

The v26 workflow updates these Merge nodes:

| Node | Change |
|------|--------|
| `Merge_Project` | Uses `$items("Explode_Project_Page")` to get spine |
| `Merge_Journal` | Uses `$items("Explode_Journal_Page")` to get spine |
| `Merge_Restart` | Uses `$items("Explode_Restart_Page")` to get spine |
| `Merge_Snapshot` | Uses `$items("Explode_Snapshot_Page")` to get spine |
| `Merge_Instruction_Pack` | Simplified to use same `$items()` pattern |

### Step 3 — Test with Pinned Data (Basic)

1. Use the pinned test data: `{ hydrate: true, limit: 2, artifact_type: "project" }`
2. Execute workflow
3. Verify: Response includes BOTH spine AND extension fields

**Expected output should include:**
- `artifact_id` ✓
- `title` ✓ (spine field)
- `summary` ✓ (spine field)
- `artifact_type` ✓ (spine field)
- `workspace_id` ✓ (spine field)
- `lifecycle_stage` ✓ (extension field)
- `operational_state` ✓ (extension field)

### Step 4 — Test Count Accuracy

Run with `limit: 2, hydrate: true`:
1. Execute workflow
2. Check `meta.count` — should be 2 (not 1)
3. Check `data.artifacts` array — should contain 2 items

### Step 5 — Regression Test: Pagination (BUG-001)

Run these three requests:

**Test A:** `offset: 0, limit: 1, hydrate: false`
**Test B:** `offset: 1, limit: 1, hydrate: false`
**Test C:** `offset: 2, limit: 1, hydrate: false`

**Expected:** Each returns a DIFFERENT artifact_id (confirms BUG-001 fix still works)

### Step 6 — Test via Qwrk Front-End

1. Run: `artifact.list` with `artifact_type=project`, `limit=2`, `hydrate=true`
2. Verify response includes:
   - 2 artifacts (not 1)
   - Both spine fields (title, summary) AND extension fields (lifecycle_stage)

### Step 7 — Activate and Deactivate Old Version

1. If tests pass, activate the new v26 workflow
2. Deactivate the old v25 workflow (do not delete yet)

---

## Success Criteria

- [ ] Hydrated response includes spine fields (title, summary, artifact_type, etc.)
- [ ] Hydrated response includes extension fields (lifecycle_stage, operational_state)
- [ ] meta.count matches actual artifact count
- [ ] Pagination still works (BUG-001 regression check)
- [ ] Multiple items returned when limit > 1

---

## Troubleshooting

**If spine fields are still missing:**
- Check the Merge node output — look for `_merge_error` field
- If present, the `$items()` call may not be finding the Split Out node
- Verify node names match exactly

**If only 1 artifact returned when limit > 1:**
- Check the Split Out node output — it should produce N items
- Check DB_Get output — it should produce N items
- Check Merge output — it should produce N items

**If `_merge_error: "No matching spine found"`:**
- The artifact_id from DB_Get doesn't match any spine item
- This suggests a data integrity issue or node wiring problem

---

## File Location

Fixed workflow JSON: `workflows/NQxb_Artifact_List_v1 (26).json`

---

**End of prompt.**
