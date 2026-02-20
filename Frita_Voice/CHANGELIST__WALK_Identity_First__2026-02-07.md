# Changelist: WALK Phase — Identity-First Multi-Turn Flow

**Date:** 2026-02-07
**PRD Version:** v2.0 (`frita_voice_virtual_service_agent_prd_v_2_crawl_walk.md`)
**Phase:** WALK (identity-first scope only)
**Parallel Build:** Yes — all WALK workflows use separate webhook paths; CRAWL untouched

---

## Summary

Implements the PRD v2 Section 9 "Walk Entry Flow": identity resolution before intent routing via multi-turn TwiML conversation.

**CRAWL (live, unchanged):**
- `/webhook/twilio/voice` → Voice Entry (greeting + Gather → /voice/handle)
- `/webhook/twilio/voice/handle` → Voice Handle v4 (single-turn intent routing)

**WALK (new, parallel):**
- `/webhook/twilio/voice/walk` → Voice Entry v2 (identity lookup + Gather → confirm or employee-id)
- `/webhook/twilio/voice/confirm-identity` → Voice Confirm Identity (yes/no → Gather → /walk/handle)
- `/webhook/twilio/voice/employee-id` → Voice Employee ID (lookup → Gather → /walk/handle)
- `/webhook/twilio/voice/walk/handle` → Voice Handle v5 (reads identity from URL params, same intent routing)

---

## Call Flow (WALK)

```
Turn 1: Caller dials → Voice Entry v2
         ├── Phone recognized → "Are you Joel Blagg?" + Gather
         └── Phone unknown → "Employee ID?" + Gather

Turn 2a: Caller says "yes" → Voice Confirm Identity
         └── "How can I help?" + Gather → /walk/handle?fname=Joel&lname=Blagg&idstatus=confirmed

Turn 2b: Caller says "no" → Voice Confirm Identity
         └── "Employee ID?" + Gather → /employee-id

Turn 2c: Caller speaks employee ID → Voice Employee ID
         ├── Found → "Thanks, Joel. How can I help?" + Gather → /walk/handle?...&idstatus=confirmed
         └── Not found → "I can still help..." + Gather → /walk/handle?idstatus=unverified

Turn 3: Caller speaks intent → Voice Handle v5
         └── Same keyword routing as v4, but reads identity from URL query params
```

---

## State Management

Identity state passes between turns via **URL query parameters** in `<Gather action="...">` URLs:

| Param | Values | Description |
|-------|--------|-------------|
| `fname` | string | Caller's first name (if resolved) |
| `lname` | string | Caller's last name (if resolved) |
| `idstatus` | `confirmed` / `unverified` | Identity resolution result |

This is standard Twilio multi-turn practice. No external session store required.

---

## New Workflows (5)

| # | File | Webhook Path | Purpose |
|---|------|-------------|---------|
| 1 | `Frita – Identity Lookup v2.json` | (sub-workflow) | Lookup by phone_number. Code node placeholder — swap for n8n Table node. |
| 2 | `Frita – Voice Entry v2.json` | `/twilio/voice/walk` | Identity-first greeting. Calls Identity Lookup v2 sub-workflow. |
| 3 | `Frita – Voice Confirm Identity.json` | `/twilio/voice/confirm-identity` | Yes/no identity confirmation. Switch with 5 "yes" patterns + fallback. |
| 4 | `Frita – Voice Employee ID.json` | `/twilio/voice/employee-id` | Employee ID fallback. Code node with spoken-number normalization. |
| 5 | `Frita – Voice Handle v5.json` | `/twilio/voice/walk/handle` | Intent handler. Reads identity from query params. No sub-workflow call for password_reset. |

---

## Key Changes from v4 → v5 (Voice Handle)

| Aspect | v4 (CRAWL) | v5 (WALK) |
|--------|-----------|-----------|
| Identity resolution | Password_reset path calls Identity Lookup sub-workflow | Identity already resolved from earlier turns; read from URL query params |
| Entry node | Edit Fields (normalized_text, raw_speech) | Extract State (normalized_text, raw_speech, identity_status, caller names) |
| Password_reset branch | Prepare Lookup → Identity Lookup → IF Recognized? | IF Identity Confirmed? (reads $json.identity_status) |
| Other intents | Unchanged | Unchanged |
| Response texts | CRAWL-locked | CRAWL-locked (identical) |
| Pinned test data | CRAWL payload | WALK payload with query params |

---

## Import Order

1. **Import `Frita – Identity Lookup v2.json`** → note its workflow ID
2. **Edit `Frita – Voice Entry v2.json`** → replace `REPLACE_WITH_IDENTITY_LOOKUP_V2_WORKFLOW_ID` with the real ID
3. **Import `Frita – Voice Entry v2.json`**
4. **Import `Frita – Voice Confirm Identity.json`**
5. **Import `Frita – Voice Employee ID.json`**
6. **Import `Frita – Voice Handle v5.json`**
7. **Activate all 5 workflows**

---

## Post-Import: Swap Code Nodes for n8n Table

Two Code nodes use hardcoded caller data (demo-grade). Replace with n8n Table lookups:

**Identity Lookup v2 — "Lookup Caller" node:**
- Table: `fv_known_callers`
- Filter: `phone_number = $json.phone_number` AND `active = true`
- Output: `{ recognized: true, first_name, last_name }` or `{ recognized: false }`

**Voice Employee ID — "Lookup by Employee ID" node:**
- Table: `fv_known_callers`
- Filter: `employee_id = normalized_input` AND `active = true`
- Output: `{ found: true, first_name, last_name, employee_id }` or `{ found: false, employee_id }`

---

## Testing

**Per-turn (n8n test mode):**
1. Voice Entry v2: POST `{ body: { From: "+18177156827" } }` → expect "Are you Joel Blagg?"
2. Confirm Identity: POST `{ query: { fname: "Joel", lname: "Blagg" }, body: { SpeechResult: "yes" } }` → expect "How can I help?"
3. Employee ID: POST `{ body: { SpeechResult: "one zero zero four two" } }` → expect "Thanks, Joel"
4. Voice Handle v5: POST `{ query: { fname: "Joel", lname: "Blagg", idstatus: "confirmed" }, body: { SpeechResult: "I'm locked out" } }` → expect personalized password_reset

**End-to-end:** Update Twilio webhook from `/voice` to `/voice/walk`, call the number.

**Regression:** CRAWL workflows at `/voice` and `/voice/handle` remain active and unchanged.

---

## Plan Deviation: No Session Table

The original plan specified a `fv_call_sessions` n8n Table. This was replaced with URL query parameters — simpler, no external state store, standard Twilio practice. Session table can be added later if needed for audit or analytics.

---

## Follow-up Items

- [ ] Benefits response text: PRD v2 specifies Teams-forwarding language; current v4/v5 still uses "I'll text you..." text
- [ ] Real SMS delivery (Twilio SMS nodes) for guest_wifi, password_reset
- [ ] Microsoft Teams integration for benefits
- [ ] Session cleanup / audit logging (if session table added later)
