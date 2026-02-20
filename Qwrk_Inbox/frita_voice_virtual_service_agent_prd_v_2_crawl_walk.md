# Frita Voice Virtual Service Agent

## Product Requirements Document (PRD)
**Version:** v2.0
**Status:** Crawl complete / Walk designed
**Last Updated:** 2026-02-07

---

## 1. Purpose & Vision

Frita Voice is a **voice-based virtual service agent** designed to handle common internal service desk requests via phone in a way that feels credible, professional, and enterprise-ready.

The system prioritizes:
- Believable behavior over deep automation
- Deterministic, testable flows over improvisation
- A clear **Crawl → Walk → Run** maturity path

Frita Voice is intentionally designed so that **spoken language remains stable** as backend capabilities evolve.

---

## 2. Guiding Principles

- **Demo-grade realism**: Never claim actions that cannot be supported later
- **Voice is constrained**: Avoid long, sensitive, or complex information via speech
- **Identity before action** (Walk+)
- **Out-of-band delivery** for details (SMS, Teams, etc.)
- **Single orchestration layer**: n8n owns logic, state, and integration

---

## 3. Scope by Phase

### Crawl (Current)
- Single-turn calls
- Deterministic intent routing (keyword-based)
- Narrative promises only (no real side effects)
- No session state
- n8n Tables as the only data store

### Walk (Designed)
- Multi-turn conversations
- Identity-first call flow
- Session state keyed by CallSid
- Employee ID fallback identity resolution
- Real async delivery (SMS / Microsoft Teams)

### Run (Future)
- IAM integration
- Ticketing system integration
- HR / Benefits platform integration
- Resolve Actions SaaS execution

---

## 4. High-Level Architecture

**Crawl Architecture:**

Twilio Voice → n8n Webhook → Intent Router → Intent Handler → TwiML Response → Twilio

**Walk Architecture (Planned):**

Twilio Voice → n8n Webhook → Session State Resolver → Identity Gate → Intent Router → Intent Handler → Side Effects → TwiML Response

---

## 5. Data Model (n8n Tables)

### 5.1 `fv_known_callers`

Authoritative identity reference used across all phases.

| Column        | Type    | Description |
|--------------|---------|-------------|
| phone_number | string  | E.164 format; primary lookup |
| employee_id  | string  | Fallback lookup in Walk |
| first_name   | string  | Spoken name |
| last_name    | string  | Spoken name |
| active       | boolean | Eligibility flag |
| notes        | string  | Demo / admin notes |

**Lookup precedence (Walk):**
1. phone_number
2. employee_id

In Crawl, lookup may occur internally but does not affect conversational branching.

---

## 6. Supported Intents

| Intent | Description |
|------|-------------|
| password_reset | Account access assistance |
| guest_wifi | Guest Wi-Fi request |
| benefits | Benefits / HR assistance |
| unknown | Fallback escalation |

---

## 7. Intent Behavior — Crawl (Locked)

### 7.1 Password Reset

**Behavior:**
- Single-turn
- No confirmation loops
- No PIN entry

**Spoken Response (recognized):**
> “I can help with that. I recognize this phone number as {{first_name}} {{last_name}}. I’ll unlock your account and text you the next steps shortly.”

**Spoken Response (default):**
> “I can help with that. I’ll open a ticket and have someone from the service desk contact you shortly.”

No real unlocks occur in Crawl.

---

### 7.2 Guest Wi-Fi

**Design Decision:**
- Do not read network details aloud
- Do not branch on identity in Crawl

**Spoken Response:**
> “I’ll text you the guest Wi-Fi information now.”

Narrative only in Crawl.

---

### 7.3 Benefits (Updated)

**Design Decision:**
- Voice is not appropriate for detailed benefits information
- Explicit handoff to asynchronous channel

**Spoken Response:**
> “I have detailed information available that is too long for voice. I’ll forward this conversation to Teams, where you can read it, ask additional questions, or submit a request to the HR service desk.”

Narrative only in Crawl.

---

### 7.4 Unknown

**Spoken Response:**
> “I’m sorry — I didn’t catch a supported request. I’ll open a ticket and have someone follow up with you.”

---

## 8. Conversation Rules (Crawl)

- One turn per call
- No follow-up questions
- No identity challenges
- No sensitive information spoken aloud
- Calm, professional service desk tone

---

## 9. Walk Phase — Identity-First Call Flow (Designed)

In Walk, **identity resolution precedes intent routing**.

### Walk Entry Flow
1. FV greets the caller and confirms identity by phone number:
   > “Hi, this is Frita. I recognize this number. Are you {{first_name}} {{last_name}}?”

2. If confirmed:
   - FV proceeds to intent collection

3. If not confirmed:
   - FV requests employee ID
   - Identity is resolved via table lookup

4. Once identity is resolved:
   - FV asks what help is needed
   - Existing intent routing applies

---

## 10. Walk Intent Behavior (Key Differences)

- Multi-turn conversations using `<Gather>`
- Session state stored per CallSid
- Real async delivery:
  - Guest Wi-Fi → SMS / Teams
  - Benefits → Microsoft Teams conversation
- Password reset expands to full verification flow

Spoken language remains consistent with Crawl.

---

## 11. Risks & Mitigations

| Risk | Mitigation |
|----|-----------|
| Over-claiming actions | Use narrative phrasing in Crawl |
| Privacy concerns | Avoid speaking sensitive info |
| Demo fragility | Single-turn Crawl design |
| Voice limitations | Teams handoff for complexity |

---

## 12. Open Items (Deferred)

- Admin workflow for managing known callers
- Ticketing system integration
- Resolve Actions SaaS integration
- Analytics and reporting

---

## 13. Summary

This PRD defines a **credible, extensible voice service agent** with:
- A stable Crawl implementation
- A fully designed Walk evolution
- Clear separation between spoken experience and backend execution

Frita Voice is positioned to evolve from demo to production without rewriting conversational behavior.

---

**End of Document**