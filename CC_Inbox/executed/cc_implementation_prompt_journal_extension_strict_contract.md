# Claude Code Implementation Prompt

## Objective

Permanently enforce a strict journal extension schema across Qwrk Prime (Multi-User architecture) so that journal content cannot be saved under non-canonical keys.

We are adopting **STRICT mode (Option A)**:

- Journal artifacts MUST use `extension.entry_text` (string, required, non-empty)
- `extension.entry` is INVALID
- Any unknown extension keys for journal artifacts must be rejected
- System must fail fast before persistence

This change must apply across:
- Gateway Save sub-workflow
- All ChatGPT system instruction templates
- Instruction pack template
- Deployment guide
- Runbook
- Any journal payload examples

No silent mapping. No backward compatibility shim.

---

# 1️⃣ Gateway Layer — Save Validation

## Target

n8n Sub-Workflow:

- `NQxb_Artifact_Save_v1`

## Required Change

Inside the Save workflow, before persistence logic executes, add a **Journal Extension Validator step**.

### Validation Rules

If:

```
artifact_type === "journal"
```

Then enforce:

1. `extension` must exist and be an object
2. `extension.entry_text` must exist
3. `typeof extension.entry_text === "string"`
4. `extension.entry_text.trim().length > 0`
5. No other keys are allowed in `extension`

If any rule fails, return:

```
{
  "ok": false,
  "error": "VALIDATION_ERROR",
  "code": "JOURNAL_EXTENSION_INVALID",
  "message": "Journal artifacts require extension.entry_text (non-empty string). No other extension fields are permitted."
}
```

Do NOT call Supabase insert if validation fails.

Place this validation BEFORE any database interaction.

---

# 2️⃣ ChatGPT Project Template Update

## File

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Multi-User Qwrk\03_ChatGPT_Projects\SYSTEM_INSTRUCTIONS_TEMPLATE.md

## Required Additions

Under “Save Payload Requirements”, add a new section:

### Journal Artifact Schema (Strict)

```
For artifact_type "journal":

extension must contain exactly:
{
  "entry_text": "string (required, non-empty)"
}

Do NOT use:
- extension.entry
- extension.content
- extension.body
- extension.payload

If incorrect field is used, Gateway will reject the request.
```

Add a canonical journal save example:

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{workspace_uuid}}",
  "artifact_type": "journal",
  "title": "Example Journal",
  "priority": 3,
  "tags": ["example"],
  "extension": {
    "entry_text": "Journal body text here."
  }
}
```

---

# 3️⃣ Instruction Pack Template Update

## File

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Multi-User Qwrk\04_Instruction_Packs\INSTRUCTION_PACK_TEMPLATE.md

## Required Addition

Add a new section:

## Artifact Extension Contracts

### Journal

Strict contract:

```
extension:
  entry_text: string (required, non-empty)
```

No additional fields permitted.

Failure to comply results in `JOURNAL_EXTENSION_INVALID`.

---

# 4️⃣ Qwrk@Work Project System Instructions Update

## File

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Multi-User Qwrk\03_ChatGPT_Projects\Qwrk@Wrk\qwrk_work_system_instructions_v_1.md

Add identical Journal Schema section as described above.

---

# 5️⃣ Deployment Guide Update

## File

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Multi-User Qwrk\NEW_WORKSPACE_DEPLOYMENT_GUIDE.md

Add new section after "Save Payload Requirements":

## Journal Schema Invariant

All journal artifacts across all workspaces must use:

```
extension.entry_text
```

Gateway enforces strict validation. Incorrect keys will fail.

This invariant must not be modified per workspace.

---

# 6️⃣ Multi-User Runbook Update

## File

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Multi-UserQwrk\RUNBOOK__Multi_User_Cloned_Gateways__v1.md

Add under Governance Rules:

### Journal Extension Invariant

Journal artifacts are append-only and must use `extension.entry_text` exclusively.

This is a cross-clone invariant and must not be altered in any clone.

---

# 7️⃣ Tests (Required)

Add integration tests (location: testing folder if exists, otherwise create):

## Test 1 — Valid Journal Roundtrip

1. Save journal with entry_text
2. Query journal
3. Assert hydrated extension.entry_text matches input

## Test 2 — Invalid Field Rejection

Attempt save with:

```
extension: { entry: "text" }
```

Expect:
- ok: false
- code: JOURNAL_EXTENSION_INVALID

## Test 3 — Empty entry_text Rejection

Attempt save with empty string.
Expect validation error.

## Test 4 — Non-Journal Artifacts Unaffected

Ensure snapshot save still succeeds.

---

# 8️⃣ Verification Checklist

After implementation:

- [ ] Save valid journal → hydrate → correct content
- [ ] Save journal with extension.entry → rejected
- [ ] Save journal with empty entry_text → rejected
- [ ] Snapshot save unaffected
- [ ] No regression in project or snapshot artifacts

---

# Non-Negotiable Constraints

- No silent remapping
- No backward compatibility shim
- No mutation of existing journal rows
- Validation must occur before persistence

---

# Deliverables

1. Updated n8n Save sub-workflow
2. Updated templates and documentation files
3. Added test scripts
4. Confirmation of all checklist items passing

Execute precisely. No scope expansion beyond described changes.

