# Frita Voice — Demo Workflow Runbook (Living Document)

**Audience:** Resolve Sales Engineers (SEs)

**Purpose:** This document enables any Resolve SE to confidently deliver the Frita Voice demo by following a clear, repeatable workflow. It explains *what the demo is*, *how it works*, *what resources are involved*, and *how to run it live* without improvisation.

**Status:** Living document — expected to evolve during Crawl → Walk maturation.

---

## 1. Demo Overview

Frita Voice is a **voice-based virtual service agent** designed to handle common internal service desk requests over the phone in a way that feels credible, professional, and enterprise-safe.

This demo intentionally prioritizes:
- Believable service desk behavior
- Deterministic, testable flows
- Clear separation between *what is spoken* and *what is actually automated*

The current demo operates in **Crawl phase**.

**Key framing for customers:**
> “What you’re hearing today is production-safe voice behavior. The backend capabilities mature underneath it over time — the spoken experience stays stable.”

---

## 2. Demo Scope (Crawl Phase)

**What the demo DOES:**
- Accepts a live phone call
- Routes a single spoken request to a known intent
- Responds with a professional, service-desk-appropriate voice
- Narrates follow-up actions (without executing real side effects)

**What the demo does NOT do (by design):**
- No multi-turn conversations
- No identity challenges
- No sensitive information spoken aloud
- No real password resets, tickets, or system changes

This is intentional and should be positioned as a **strength**, not a limitation.

---

## 3. Supported Demo Intents

The demo supports **four** deterministic intents:

1. **Password Reset**
2. **Guest Wi-Fi**
3. **Benefits / HR**
4. **Unknown / Fallback**

Each intent maps to a fixed spoken response.

---

## 4. High-Level Call Flow

```
Caller
  ↓
Twilio Voice Number
  ↓
n8n Webhook (Inbound Call)
  ↓
Intent Router (Keyword-Based)
  ↓
Intent Handler (Narrative Response)
  ↓
TwiML Voice Response
  ↓
Call Ends
```

**Important:**
- Each call is **single-turn**
- There is no session memory
- The entire flow is owned by n8n

---

## 5. Resources Used

### 5.1 Twilio

- **Purpose:** Phone number, call handling, voice playback
- **Key role:** Entry and exit point for the demo

Twilio is responsible only for:
- Receiving the call
- Playing the generated TwiML response

No business logic lives in Twilio.

---

### 5.2 n8n (Orchestration Layer)

- **Purpose:** Core logic, routing, and demo safety
- **Role:** Single source of truth for behavior

n8n handles:
- Inbound webhook from Twilio
- Intent detection (keyword-based)
- Optional lookup of known callers
- Selection of the correct spoken response
- Generation of TwiML

All demo behavior should be inspectable and explainable inside n8n.

---

### 5.3 n8n Tables (Data)

#### Table: `fv_known_callers`

Used as an *authoritative identity reference*.

**Columns:**
- phone_number (E.164)
- employee_id
- first_name
- last_name
- active
- notes

**Important demo rule:**
- In Crawl, identity lookup does **not** change conversational branching
- It is used only to demonstrate recognition language

---

## 6. Spoken Responses (Crawl)

### 6.1 Password Reset

**Recognized number:**
> “I can help with that. I recognize this phone number as {{first_name}} {{last_name}}. I’ll unlock your account and text you the next steps shortly.”

**Default:**
> “I can help with that. I’ll open a ticket and have someone from the service desk contact you shortly.”

---

### 6.2 Guest Wi-Fi

> “I’ll text you the guest Wi-Fi information now.”

(No network details are spoken aloud.)

---

### 6.3 Benefits / HR

> “I have detailed information available that is too long for voice. I’ll forward this conversation to Teams, where you can read it, ask additional questions, or submit a request to the HR service desk.”

---

### 6.4 Unknown / Fallback

> “I’m sorry — I didn’t catch a supported request. I’ll open a ticket and have someone follow up with you.”

---

## 7. How to Run the Demo (SE Checklist)

1. Confirm the Twilio demo number is active
2. Confirm n8n workflows are enabled
3. Call the demo number
4. Speak **one** supported request clearly
5. Let the call complete naturally

**Recommended demo phrases:**
- “I need to reset my password”
- “How do I get guest Wi-Fi?”
- “I have a benefits question”

---

## 8. How to Position This to Customers

**Key message:**
> “This is not a chatbot reading a script. It’s a governed voice interface designed to be safe on day one and powerful on day ninety.”

Emphasize:
- Stability of spoken language
- Deterministic behavior
- Clear path to real automation (Walk phase)

Avoid:
- Over-promising backend execution
- Describing future features as current

---

## 9. Known Limitations (Explicit and Intentional)

- Single-turn only
- No authentication challenges
- No live integrations
- No real tickets created

These are **guardrails**, not gaps.

---

## 10. Change Log

This section will be maintained as the demo evolves.

- Initial version created for Crawl demo rollout

---

**End of Living Document**

