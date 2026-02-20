# Frita Voice Virtual Service Agent (Demo-Grade)

## Product Requirements Document (PRD) + Phased Implementation Runbook

**Project:** Frita Voice Service Agent (Rita Imitation)  
**Qwrk Project ID:** 9c6377c1-48d4-4b96-bcb0-d1d59bc21a46  
**Owner:** Joel  
**Status:** Sapling (active planning)

---

## 1. Problem Statement

We need a convincing voice-mode imitation of Resolve.io’s Rita Virtual Service Agent that can be reached by calling a phone number, understands common IT-style requests, resolves them convincingly, and escalates cleanly when it cannot.

This system is **demo-grade first**: believable, deterministic, resumable, and safe. Real integrations are optional; the *experience* must feel real.

---

## 2. Goals, Non-Goals, and Success Criteria

### Goals
- Caller dials a phone number and reaches Frita immediately.
- Frita greets, listens, classifies intent, and responds clearly.
- Common requests are resolved in 1–2 turns.
- Unknown requests create a ticket with a spoken ticket number.
- Calls are logged with transcript, intent, and outcome.

### Non-Goals (V1)
- Real password resets or identity verification.
- Deep multi-turn troubleshooting trees.
- Production-grade compliance or integrations.

### Success Criteria
- Time to greeting under ~2 seconds.
- ≥80% intent accuracy on scripted demo prompts.
- Stable across 20+ consecutive test calls.

---

## 3. Primary User Stories

- "I’m locked out of my PC" → Frita initiates a reset flow or tickets it.
- "What’s the guest WiFi?" → Frita provides SSID and password.
- "What’s the medical insurance help desk number?" → Frita provides contact details.
- Unknown request → Frita creates a ticket and sets expectations.

---

## 4. System Architecture

**Call Flow:**
Google Voice → Twilio → n8n Webhook → LLM + Supabase → n8n → Twilio (TwiML)

- Twilio handles voice, STT, and TTS.
- n8n orchestrates all logic.
- Supabase stores config, sessions, and tickets.
- LLM is used strictly for intent classification and response shaping.

---

## 5. Data Model (Supabase)

### frita_config
- guest_wifi_ssid
- guest_wifi_password
- benefits_phone
- benefits_email

### frita_call_session
- call_sid
- from_number
- started_at / ended_at
- transcript
- last_intent
- status

### frita_ticket
- ticket_id
- call_sid
- summary
- intent
- transcript
- status

---

## 6. Conversation Design Rules

- Calm, brief, confident tone.
- Short sentences.
- Never request sensitive personal data.
- Max 6 turns per call.
- One clarification allowed; then escalate.

---

## 7. LLM Contract

Allowed intents:
- password_reset
- guest_wifi
- benefits_contact
- unknown

LLM must return strict JSON with intent, confidence, response_text, and ticket flags.

---

## 8. Phased Implementation Plan

### Phase 0 — Prerequisites
- Twilio account and phone number
- Google Voice forwarding to Twilio
- Public n8n webhook
- Supabase project and tables

Checkpoint: inbound calls reach Twilio successfully.

---

### Phase 1 — Voice Shell

Goal: Frita answers, speaks, and listens once.

Steps:
- Twilio webhook → n8n
- Return TwiML with greeting and <Gather>
- Capture SpeechResult and Confidence

Checkpoint: Call → greeting → speech captured → placeholder response.

---

### Phase 2 — Intent Router

Goal: Classify caller intent deterministically.

Steps:
- LLM classification with strict intent list
- Confidence threshold routing
- One clarification max

Checkpoint: demo prompts route correctly.

---

### Phase 3 — Resolution Playbooks

Goal: Resolve the top 3 demo requests.

Playbooks:
- Guest WiFi lookup
- Benefits contact lookup
- Password reset (demo-safe wording)

Checkpoint: common requests resolved in ≤2 turns.

---

### Phase 4 — Ticketing & Graceful Failure

Goal: Professional escalation for unknowns.

Steps:
- Create ticket in Supabase
- Read back ticket number
- End call cleanly

Checkpoint: every unknown request produces a ticket.

---

### Phase 5 — Demo Polish (Optional)

- SMS follow-ups
- Improved pacing and phrasing
- Demo scripts

---

## 9. Resume-Friendly Runbook

At the end of any session, record:
- Current phase
- What works
- What’s broken
- Exact next step
- Webhook URLs
- Notes for future continuation

---

## 10. Key Risks & Mitigations

- Webhook latency → keep logic minimal
- STT errors → one clarification then ticket
- Overclaiming actions → use safe phrasing

---

## 11. Open Decisions

- Demo disclaimer on/off
- SMS follow-ups in V1
- Transcript format (text vs JSON)
- Password reset phrasing style

---

**End of PRD**

