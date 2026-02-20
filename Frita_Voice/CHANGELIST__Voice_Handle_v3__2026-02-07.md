# Changelist: Frita – Voice Handle v3 + Identity Lookup

**Date:** 2026-02-07
**Base:** `Workflows/Frita – Voice Handle v2.json`
**New files:**
- `Workflows/Frita – Voice Handle v3.json`
- `Workflows/Frita – Identity Lookup.json` (sub-workflow)

**Phase:** Phase 2 CRAWL — Single-turn identity lookup for password_reset

---

## What Was Added

### New Sub-Workflow: Frita – Identity Lookup

| Node | Type | Purpose |
|------|------|---------|
| When Called By Another Workflow | Execute Workflow Trigger | Receives `{ phone_number }` from parent |
| Lookup Caller | Code | Matches phone_number against known callers, returns `{ recognized, first_name?, last_name? }` |

- Uses inline Code node with hardcoded caller data (demo-grade)
- **To connect to your n8n table:** replace the Code node with your n8n Table lookup on `fv_known_callers`, filtering by `phone_number` + `active = true`
- Pre-seeded with: `+18177156827` → Joel Blagg

### Modified: Voice Handle password_reset path

**Before (v2):** Switch → Set password_reset → Respond to Webhook

**After (v3):**
```
Switch [outputs 0-3]
  → Prepare Lookup (extracts From via $node['Webhook'].json.body.From)
    → Identity Lookup (Execute Workflow — calls sub-workflow)
      → Caller Recognized? (IF node)
        → true:  Set Recognized → Respond to Webhook
        → false: Set Not Recognized → Respond to Webhook
```

| New Node | Type | Purpose |
|----------|------|---------|
| Prepare Lookup | Set | Extracts caller phone_number from Webhook body.From |
| Identity Lookup | Execute Workflow | Calls the Identity Lookup sub-workflow |
| Caller Recognized? | IF | Branches on `recognized === true` |
| Set Recognized | Set | Personalized response: "I recognize this phone number as {name}..." |
| Set Not Recognized | Set | Unknown caller response: "I don't recognize this number..." |

### Removed

| Node | Reason |
|------|--------|
| Set password_reset | Replaced by Prepare Lookup → Identity Lookup → IF → Set Recognized / Set Not Recognized |

### Unchanged

- Webhook, Edit Fields (normalization), Switch (all 12 rules + fallback)
- guest_wifi, benefits_contact, unknown intent paths
- Respond to Webhook (same dynamic TwiML, repositioned)
- pinData (locked-out test utterance preserved)

---

## Import Steps

1. Import **Identity Lookup** sub-workflow first → note its workflow ID
2. Open **Voice Handle v3** JSON → find `"workflowId": "REPLACE_WITH_IDENTITY_LOOKUP_WORKFLOW_ID"` → replace with actual ID
3. Import Voice Handle v3
4. Deactivate v2 → Activate v3 and Identity Lookup
5. **(Optional)** Replace the Code node in Identity Lookup with your n8n Table node

---

## Intentionally Deferred (WALK Phase)

Password reset is intentionally single-turn in CRAWL. The following are planned for WALK phase:

- Multi-turn identity confirmation ("Are you Joel Blagg?" → yes/no)
- PIN entry and verification
- Session state tracking (CallSid-based)
- `<Gather>` for multi-turn TwiML
- `fv_call_session` and `fv_ticket` table integration
