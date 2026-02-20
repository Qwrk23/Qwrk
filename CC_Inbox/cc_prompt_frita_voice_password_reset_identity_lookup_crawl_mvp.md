## Role
Act as a senior n8n workflow engineer. Build deterministic, minimal-scope workflows suitable for a live demo. Favor clarity over cleverness.

---

## Objective
Extend **Frita Voice** with a **crawl/MVP identity lookup + multi-turn password reset sub-workflow**, using a table-backed lookup for caller identity.

This work is **additive**. Do not refactor unrelated logic.

---

## Source Context (Read First)

### 1) Existing Voice Handle Workflow (Base)
Use the current v2 workflow as the starting point:

```
Frita – Voice Handle v2.json
```

This workflow already supports:
- Deterministic intent routing (password_reset, guest_wifi, benefits_contact, unknown)
- Valid TwiML responses via a single Respond to Webhook node

### 2) Product Intent (Authoritative)
Password reset is being extended to a **multi-turn, demo-realistic flow**. No real IAM actions are performed.

---

## New Data Model (Required)

### Table: `fv_known_callers`
Assume this table exists (or create it if needed).

**Columns:**
- `phone_number` (string, E.164 format, primary lookup key)
- `first_name` (string)
- `last_name` (string)
- `active` (boolean)
- `notes` (string, optional)

Only records with `active = true` are valid.

---

## What You Need to Build

### A) Sub-Workflow — Identity Lookup

Create a reusable **sub-workflow** that:

**Input:**
```json
{
  "phone_number": "+18177156827"
}
```

**Behavior:**
- Query `fv_known_callers` where:
  - `phone_number` matches input
  - `active === true`

**Output (one of the following):**

**Recognized:**
```json
{
  "recognized": true,
  "first_name": "Joel",
  "last_name": "Blagg"
}
```

**Not recognized:**
```json
{
  "recognized": false
}
```

No fuzzy matching. Exact match only.

---

### B) Extend Password Reset Flow in Voice Handle

Modify **only** the `password_reset` path.

#### Step 1 — Call Identity Lookup
- Extract caller phone number from Twilio payload (`From`)
- Invoke the identity lookup sub-workflow

#### Step 2 — Branch on Result

**If `recognized === true`:**

Frita Voice says:
> "I recognize this phone number. Are you {{first_name}} {{last_name}}?"

- If caller affirms (yes): continue
- If caller denies or says anything else: open ticket + close

**If `recognized === false`:**

Frita Voice says:
> "I’m sorry — I don’t recognize this number. I’ll open a ticket and have someone from the service desk reach out to you."

Then close.

---

### C) Crawl/MVP Password Reset Conversation (Simulated)

For recognized + confirmed callers only:

1. **PIN Prompt (simulated):**
   > "I’ve sent a verification pin to the phone number on file. Please enter it now."

2. **PIN Verification (always succeeds):**
   > "Thanks. That pin has been verified."

3. **Resolution:**
   > "Your account should now be unlocked. I’ve sent a temporary password to you, and you’ll be prompted to change it the next time you log in."

4. **Outcome Check:**
   > "Let me know if that worked."

5. **Caller Response Branch:**
   - Success (yes / worked / ok):
     > "Perfect. I’m glad that worked. I’m here any time you need help."
   - Failure (no / didn’t work):
     > "I’m sorry about that. I’ll open a ticket for you now, and someone from the service desk will contact you shortly."

End the call cleanly in all cases.

---

## Architectural Constraints (Do Not Violate)

- ❌ No LLM usage
- ❌ No real SMS or IAM calls
- ❌ No additional Respond to Webhook nodes
- ❌ Do not change Voice Entry workflow

- ✅ Use deterministic branching only
- ✅ Preserve existing intent routing for non-password paths
- ✅ All voice output must be valid TwiML

---

## Output Required

1. Updated **Voice Handle workflow JSON** (new version)
2. New **Identity Lookup sub-workflow JSON**
3. Brief changelist describing:
   - New nodes added
   - Where the sub-workflow is invoked

Do not include explanations beyond this.

---

## Final Instruction

Proceed with implementation exactly as specified. If any assumption is unclear, ask before changing behavior.

