# RESTART — Full Access Enablement (Qwrk Alpha)

**Date:** 2026-01-25
**System:** Qwrk Gateway v1 + n8n + Supabase
**Mode / Governance:** AAA_New_Qwrk under Qwrk V2 Constitution
**Status:** READY FOR EXECUTION

---

## Prerequisites (All Met)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Gateway v1 KGB-locked | ✅ | 5 actions: query, list, save, update, promote |
| Query tests | ✅ | 7/7 |
| List tests | ✅ | 10/10 |
| Save tests | ✅ | 7/8 (S5 expected) |
| Update tests | ✅ | 7/7 |
| Promote tests | ✅ | 5/5 |
| **Total** | ✅ | **36/37** |
| S6 decision locked | ✅ | Option A - nil UUIDs ignored |

---

## What "Full Access" Means

Qwrk Alpha Full Access enables:

1. **Complete CRUD operations** via Gateway v1
   - Query single artifacts
   - List artifacts by type with pagination
   - Save new artifacts (INSERT)
   - Update existing artifacts
   - Promote lifecycle transitions

2. **All registered artifact types**
   - project
   - journal
   - snapshot
   - restart
   - (instruction_pack pending registration)

3. **Hydrated responses** for list operations
   - Spine + extension data merged
   - Full artifact payloads returned

---

## Execution Steps

### Step 1: Verify Current Gateway State

Confirm all workflows are active in n8n:
- `NQxb_Gateway_Dispatcher_v1` — active
- `NQxb_Artifact_Query_v1` — active
- `NQxb_Artifact_List_v1` — active
- `NQxb_Artifact_Save_v1` — active
- `NQxb_Artifact_Update_v1` — active
- `NQxb_Artifact_Promote_v1` — active

### Step 2: Update Qwrk System Instructions

If system instructions need updating, they should reflect:

1. **Gateway endpoint:** `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1`

2. **Available actions:**
   - `artifact.query` — retrieve single artifact by ID
   - `artifact.list` — paginated list with optional hydration
   - `artifact.save` — create or update artifacts
   - `artifact.update` — modify existing artifact fields
   - `artifact.promote` — lifecycle state transitions

3. **Registered artifact types:**
   - `project` — work items with lifecycle (seed → sapling → tree)
   - `journal` — author notes and entries
   - `snapshot` — immutable point-in-time captures
   - `restart` — context restoration prompts

4. **Lifecycle model:**
   - Statuses: seed, sapling, tree, retired
   - Transitions via `artifact.promote` with reason required

### Step 3: Document Gateway Contract

The Gateway v1 contract includes:

**Request format:**
```json
{
  "gw_action": "artifact.<action>",
  "gw_workspace_id": "<uuid>",
  "artifact_type": "<type>",
  "artifact_id": "<uuid>",  // required for query/update/promote
  // action-specific fields...
}
```

**Response format (success):**
```json
{
  "ok": true,
  "gw_action": "artifact.<action>",
  "workspace_id": "<uuid>",
  "artifact_type": "<type>",
  // action-specific data...
}
```

**Response format (error):**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "<ERROR_CODE>",
    "message": "<human readable>",
    "details": { ... }
  }
}
```

### Step 4: Enable Front-End Access (If Applicable)

If a front-end client will access the Gateway:

1. Configure authentication (Basic Auth with `qwrk-gateway` user)
2. Set workspace ID in client config
3. Implement error handling for Gateway error codes
4. Test with known artifact IDs before creating new artifacts

---

## Governance Notes

- **No workflow changes** required for Full Access Enablement
- Gateway v1 is now feature-complete for Alpha
- Future enhancements (instruction_pack, new types) follow same governance
- All changes require KGB receipt before LOCK

---

## Step 5: Deploy Schema to ChatGPT Custom GPT

Once all verification passes:

1. Open ChatGPT Custom GPT configuration
2. Go to Actions section
3. Replace schema with contents of:
   - `docs/qwrk-instructions/Qwrk_Gateway_v1_Actions_Schema.yaml` (v2.0.0-dev)
4. Update system instructions with contents of:
   - `docs/qwrk-instructions/Qwrk_Full_Access_MVP_Instructions_v1.md`
5. Save and test

---

## Step 6: End-to-End Validation in ChatGPT

Perform manual validation in ChatGPT:

| Test | Expected Result |
|------|-----------------|
| "List projects" | Returns project list |
| "List journals" | Returns journal list |
| "List restarts" | Returns restart list |
| "List snapshots" | Returns snapshot list |
| "Create a new project called Test" | Creates project, returns artifact_id |
| "Create a journal entry" | Creates journal, returns artifact_id |
| "Save a restart point" | Creates restart, returns artifact_id |
| "Pause project [ID]" | Updates operational_state to paused |
| "Promote project [ID] to sapling" | Transitions lifecycle_status |
| "Update the journal entry" | Returns IMMUTABILITY_ERROR |

---

## Reference Files

| Purpose | Path |
|---------|------|
| Schema (v2.0.0-dev) | `docs/qwrk-instructions/Qwrk_Gateway_v1_Actions_Schema.yaml` |
| Instructions (v1) | `docs/qwrk-instructions/Qwrk_Full_Access_MVP_Instructions_v1.md` |
| Test Harness | `docs/testing/Qwrk.Gateway.TestHarness.ps1` |

---

## Scope Note: instruction_pack

`instruction_pack` is **intentionally deferred** to Phase 2:
- S5 test fails because type is not registered (expected)
- This is a scope decision, not a bug
- Full Access Alpha ships with 4 types: project, journal, restart, snapshot

---

## Post-Enablement Checklist

- [ ] System instructions updated
- [ ] Schema deployed to ChatGPT
- [ ] Gateway contract documented
- [ ] End-to-end validation passes in ChatGPT
- [ ] Smoke test: query known artifact
- [ ] Smoke test: list projects with hydrate=true
- [ ] Smoke test: save new journal entry
- [ ] Create first "official" seed artifact via Gateway

---

## Success Criteria

Full Access is **ENABLED** when:

1. All prerequisite tests pass (36/37) ✅
2. System instructions reflect Gateway v1 capabilities
3. At least one artifact created via Gateway post-enablement
4. No regressions in subsequent test runs

---

## Suggested First Action Post-Enablement

Create a journal entry via Gateway to mark Alpha milestone:

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "title": "Qwrk Alpha Milestone — Full Access Enabled",
  "summary": "Gateway v1 is now fully operational with 36/37 tests passing.",
  "priority": 1,
  "extension": {
    "entry_text": "Full Access Enablement completed on 2026-01-25. Gateway v1 supports query, list, save, update, and promote operations across all registered artifact types.",
    "payload": {
      "milestone": "alpha",
      "test_score": "36/37",
      "date": "2026-01-25"
    }
  }
}
```

---

*Generated by Claude Code — 2026-01-25*
