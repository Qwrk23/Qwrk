# Restart Prompt — EXECUTION (CC-Only)
## Step 1 — Fix artifact.save INSERT Response Shaping

**Audience:** Claude Code (CC)
**Mode:** Execution
**Authorized Scope:** ONE STEP ONLY
**Derived From:** LOCKED Me-First Governance Restart
**Status:** READY FOR CC

---

## Purpose (Single-Step)

Fix the `artifact.save` Gateway workflow so that a successful INSERT returns a correct, deterministic response envelope, with no loss of request context.

This step addresses a **known correctness bug**, not a feature addition.

---

## Authorized Scope (Strict)

### You are authorized to modify ONLY:
- The `artifact.save` workflow
- Response shaping logic after a successful INSERT

### You are NOT authorized to:
- Modify Kernel v1 semantics
- Modify Supabase schemas
- Modify RLS policies
- Modify lifecycle rules
- Modify `artifact.query` behavior
- Implement `artifact.list`
- Implement `artifact.update`
- Touch CustomGPT schemas or actions
- Introduce new artifact types, actions, or fields

**If a change appears to require any of the above, STOP and report.**

---

## Problem Statement (Observed)

`artifact.save` INSERT succeeds, but the final Gateway response incorrectly returns:
- `artifact_type = null`
- `workspace_id = null`
- `extension.payload = {}` (for restart/snapshot)

The database write is correct; **the response is wrong**.

---

## Required Fix Pattern (Binding)

**Freeze request context early, before any DB nodes:**
- `req_artifact_type`
- `req_workspace_id`
- `req_owner_user_id` (if used)
- `req_extension_payload` (restart / snapshot)

**Do NOT rely on downstream nodes to re-derive these values.**

**Build the final response ONLY from:**
- Frozen `req_*` fields
- Inserted `artifact_id`
- Gateway operation metadata (action, timestamp)

**No other data sources are permitted for response shaping.**

---

## Required Success Response (Minimum Fields)

On success, the response must include:
- `ok: true`
- `gw_action`
- `artifact_id`
- `artifact_type` (from frozen request)
- `workspace_id` (from frozen request)
- `operation`
- `timestamp`

**Additionally:**
- For `restart` and `snapshot`, the response must echo the saved payload correctly.

---

## Regression Checklist (MANDATORY)

After the fix, confirm:

1. **artifact.query KGB tests still pass for:**
   - project
   - journal
   - snapshot
   - restart

2. **One artifact.save test for restart:**
   - All required fields are non-null
   - Payload is preserved

3. **No change in:**
   - Schema
   - RLS
   - Query behavior

**If any regression appears, revert and report.**

---

## Hard Stop Instruction (Non-Negotiable)

After completing this step only:
- **STOP.**
- Do NOT implement additional steps.
- Do NOT refactor adjacent logic.
- Do NOT proceed to `artifact.list`, `artifact.update`, or CustomGPT work.
- **Report completion and wait for the next restart.**

---

## Definition of Done (Binary)

This step is complete **only if:**
- The response fields listed above are correct and non-null
- Restart/snapshot payloads are preserved
- All KGB query tests still pass
- No scope boundaries were crossed

---

**END OF RESTART — EXECUTE STEP 1 ONLY**
