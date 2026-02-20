# RESTART — Instruction Pack Seeding Blocked at Gateway Save

**Date:** 2026-01-19
**Status:** Build phase paused at integration boundary (DB ready → Gateway write path unresolved)

---

## Mode / Governance

You are AAA_New_Qwrk (GPT-5.2 Thinking) operating under the Qwrk V2 Constitution.

- Design first, build later
- One step at a time (no batching)
- No runnable code without explicit approval (kg)
- Receipts mandatory ("no receipt, no action")
- No placeholders in executable artifacts
- Stop immediately after producing runnable commands and wait for results

---

## Current State (Authoritative)

### Database (CONFIRMED WORKING)

The following changes are successfully applied and verified:

- New extension table created: `qxb_artifact_instruction_pack`
- Partial unique index enforcing: one active instruction_pack per (workspace_id, scope)
- Trigger installed on qxb_artifact:
  - Enforces content.scope for artifact_type = instruction_pack
  - Automatically upserts PK=FK extension row
  - Syncs workspace_id, scope, and timestamps
- No rows exist yet (expected)

**Receipt:** User confirmed: success. no rows

### Gateway v1 (BLOCKER IDENTIFIED)

- artifact.save works for existing artifact types (historically KGB-locked)
- Attempts to artifact.save with:
  - artifact_type = instruction_pack
  - valid payload
  - valid Basic Auth
  - valid actor_user_id

❌ **FAIL** with:
```
_owner_source: "missing_auth_username"
code: "VALIDATION_ERROR"
message: "Validation failed for artifact.save operation (INSERT)"
```

**Important constraints (locked by user):**

- ❌ Do NOT modify Gateway v1
- ❌ Do NOT add new Gateway behavior
- ❌ Do NOT change auth extraction logic
- ✅ Only PowerShell / client-side invocation is allowed

---

## Objective (Resume Here)

Create the first instruction_pack artifact with:

- scope = global
- Minimal valid content:
  - pack_version
  - scope
  - invariants
  - rules
  - templates
  - examples
- Tags including: scope:global

This insert should:

- Be accepted end-to-end by Gateway v1
- Trigger DB logic to create the extension row
- Establish the first active instruction pack

---

## Open Questions (Unresolved — Do Not Assume)

1. Does Gateway v1 currently allow artifact_type = instruction_pack on artifact.save?
   (May be blocked by an internal allow-list.)

2. Is _owner_source strictly derived from n8n auth context only (not headers / payload)?

3. Is there an existing artifact type (e.g., snapshot) we should temporarily use to seed instruction packs, then migrate?

No assumptions are permitted until tested.

---

## Next Step (One Step Only)

Design and execute a single diagnostic path to disambiguate:

- **Case A:** Gateway does not allow new artifact types on save
- **Case B:** Gateway requires a specific auth invocation pattern for INSERT
- **Case C:** Both

⚠️ **Do NOT:**

- Change Gateway
- Change DB
- Add new schema
- Add new actions

---

## Known-Good Context

| Item | Value |
|------|-------|
| Workspace ID | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` |
| Auth username | `qwrk-gateway` |
| User ID (dev) | `7097c16c-ed88-4e49-983f-1de80e5cfcea` |
| DB trigger + constraints | Correct and active |

---

## Phase

Build phase paused at integration boundary
(DB ready → Gateway write path unresolved)

---

## Resume Instruction

When restarting, do NOT re-explain history.
Immediately propose one diagnostic test to determine whether Gateway supports saving instruction_pack at all, without editing Gateway.

---

**End of Restart**
