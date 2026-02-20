# CC Context Prompt — Frita Voice

**Date:** 2026-02-07
**Purpose:** Resume context for any CC session working on Frita Voice

---

## Current State

Frita Voice is a **demo-grade voice virtual service agent** built on Twilio + n8n. A caller dials a phone number, speaks a request, and Frita routes by intent and responds with TwiML.

**CRAWL Phase:** COMPLETE — single-turn, deterministic, live-tested 2026-02-07.
**WALK Phase:** Identity-first multi-turn workflows BUILT, pending import and test.

**Canonical PRD:** `Qwrk_Inbox/frita_voice_virtual_service_agent_prd_v_2_crawl_walk.md`

---

## Architecture

### CRAWL (Live)
```
Caller → Google Voice → Twilio → n8n
   /webhook/twilio/voice         → Voice Entry (greeting + Gather)
   /webhook/twilio/voice/handle  → Voice Handle v4 (single-turn intent routing)
                                      └── Identity Lookup (sub-workflow, hardcoded Code node)
```

### WALK (Built, Not Yet Imported)
```
Caller → Google Voice → Twilio → n8n
   /webhook/twilio/voice/walk              → Voice Entry v2 (identity lookup + greeting)
   /webhook/twilio/voice/confirm-identity  → Voice Confirm Identity (yes/no)
   /webhook/twilio/voice/employee-id       → Voice Employee ID (fallback lookup)
   /webhook/twilio/voice/walk/handle       → Voice Handle v5 (identity-aware intent routing)
                                                └── Identity Lookup v2 (sub-workflow, used by Entry v2)
```

WALK uses URL query params (`fname`, `lname`, `idstatus`) to pass identity state between turns.

---

## Workflow Files

### CRAWL (Active in n8n)

| File | Purpose | Status |
|------|---------|--------|
| `Frita_Voice/Workflows/Frita – Voice Entry.json` | Greeting + speech capture | Active |
| `Frita_Voice/Workflows/Frita – Voice Handle v4.json` | Intent routing + identity lookup | Active |
| `Frita_Voice/Workflows/Frita – Identity Lookup.json` | Sub-workflow: phone → name (hardcoded) | Active |

### WALK (Built, Pending Import)

| File | Purpose | Status |
|------|---------|--------|
| `Frita_Voice/Workflows/Frita – Voice Entry v2.json` | Identity-first greeting | Pending import |
| `Frita_Voice/Workflows/Frita – Voice Confirm Identity.json` | Yes/no confirmation | Pending import |
| `Frita_Voice/Workflows/Frita – Voice Employee ID.json` | Employee ID fallback | Pending import |
| `Frita_Voice/Workflows/Frita – Voice Handle v5.json` | Session-aware intent handler | Pending import |
| `Frita_Voice/Workflows/Frita – Identity Lookup v2.json` | Sub-workflow: phone → name (Code placeholder) | Pending import |

### Archive
| File | Purpose |
|------|---------|
| `Frita_Voice/Workflows/Archive/` | v1, v2, v2.1, v3 of Voice Handle |

---

## Intent Map (CRAWL-locked, used by both v4 and v5)

| Intent | Keywords | Response |
|--------|----------|----------|
| password_reset | password, locked out, reset, forgot | Identity lookup → personalized or generic |
| guest_wifi | wifi, wi-fi, wireless, internet | "I'll text you the guest Wi-Fi information now." |
| benefits_contact | benefits, insurance, medical, health | "I'll text you the benefits help desk information." |
| unknown | (fallback) | Ticket escalation language |

---

## Identity Lookup

- **v1 (CRAWL):** Code node with hardcoded Joel Blagg entry. Called by Voice Handle v4 on password_reset path.
- **v2 (WALK):** Same Code node placeholder. Called by Voice Entry v2 on call arrival. Needs swap to n8n Table (`fv_known_callers`).
- **Employee ID:** Voice Employee ID workflow has its own Code node with spoken-number normalization + hardcoded lookup. Also needs n8n Table swap.

---

## WALK Import Order

1. Import `Frita – Identity Lookup v2.json` → note workflow ID
2. Edit `Frita – Voice Entry v2.json` → replace `REPLACE_WITH_IDENTITY_LOOKUP_V2_WORKFLOW_ID`
3. Import `Frita – Voice Entry v2.json`
4. Import `Frita – Voice Confirm Identity.json`
5. Import `Frita – Voice Employee ID.json`
6. Import `Frita – Voice Handle v5.json`
7. Activate all 5

---

## n8n Constraints Learned

- Execute Workflow Trigger MUST define input schema or n8n blocks publishing
- Supabase node does NOT support `executeQuery` — use HTTP Request + PostgREST
- Merge node only supports 2 inputs — use Code node sync gate for 3+
- See `memory/n8n-patterns.md` for full pattern reference

---

## Decisions Locked

1. **Voice is not a UI:** Don't read passwords, phone numbers, or sensitive info aloud
2. **n8n Tables for Frita data:** `fv_known_callers` in n8n, decoupled from Qwrk Kernel Supabase
3. **URL query params for session state:** No external session store; identity rides in Gather action URLs
4. **Parallel build (Rule 9):** WALK uses separate webhook paths; CRAWL untouched

---

## What's Next

- **Import and test WALK workflows** (see import order above)
- **Swap Code nodes for n8n Table lookups** (Identity Lookup v2 + Employee ID)
- **Benefits response text:** PRD v2 specifies Teams-forwarding language; v4/v5 still use "I'll text you..."
- **Real SMS delivery** (future WALK extension)
- **Microsoft Teams integration** (future)

---

## Changelists

- `Frita_Voice/CHANGELIST__Voice_Handle_v2__2026-02-07.md` — v1→v2 (4 intents added)
- `Frita_Voice/CHANGELIST__Voice_Handle_v3__2026-02-07.md` — v2→v3 (identity lookup added)
- `Frita_Voice/CHANGELIST__Voice_Handle_v4__2026-02-07.md` — v3→v4 (voice-is-not-a-UI responses)
- `Frita_Voice/CHANGELIST__WALK_Identity_First__2026-02-07.md` — WALK identity-first multi-turn
