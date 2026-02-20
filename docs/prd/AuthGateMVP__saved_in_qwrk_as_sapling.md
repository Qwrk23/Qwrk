markdown
# PRD — AuthGate MVP
**OAuth + Stripe Subscription Gating via Custom GPT Actions**

## 1. Purpose
Validate that a product can be monetized *before* building a bespoke front-end by using:
- A Custom GPT as the user interface
- OAuth for identity
- Stripe for subscription billing
- A backend API that gates capabilities based on subscription status

This MVP is a proof-of-life experiment intended to inform whether Qwrk can be monetized using the same pattern.

---

## 2. Problem Statement
Custom GPTs do not natively support:
- User login
- Stripe subscriptions
- Per-user entitlement enforcement

However, they *do* support **GPT Actions with OAuth**, which allows the GPT to act as a UI for a paid backend service. This MVP proves that pattern end-to-end.

---

## 3. Goals & Success Criteria

### Goals
- Identify the user inside a GPT session
- Enforce subscription status on backend operations
- Observe different GPT behavior for paid vs unpaid users

### Success Criteria
- A user triggers an Action in ChatGPT
- ChatGPT prompts the user to log in via browser (OAuth redirect)
- Backend receives a token identifying the user
- Backend returns:
  - **DENY** when subscription is inactive
  - **ALLOW** when subscription is active
- Toggling Stripe subscription status changes GPT results without changing user identity

---

## 4. Non-Goals
- No bespoke front-end UI
- No complex permissions model
- No team/multi-seat support
- No deep Qwrk integration (this is pre-Qwrk)

---

## 5. System Architecture (Minimal)

### Components

#### 5.1 Custom GPT
- Acts as the primary UI
- Exposes **one GPT Action**: “Check my access”
- Uses OAuth authentication
- Calls backend API endpoint

#### 5.2 OAuth Server (Your App)
- Endpoints:
  - `/authorize`
  - `/token`
- Login methods:
  - Magic-link email
  - Email + password
- Issues access token containing:
  - `sub` = internal `user_id`

#### 5.3 Backend API
- Protected endpoint:
  - `GET /me/status`
- Responsibilities:
  - Validate OAuth token
  - Extract `sub` (user_id)
  - Check entitlement status
  - Return structured response

Example response:
```json
{
  "user_id": "uuid",
  "is_active": true,
  "reason": "active_subscription"
}
````

#### 5.4 Billing (Stripe)

* Stripe Subscriptions (monthly)
* Stripe Webhooks update entitlement state
* Backend maintains:

  * `is_active` boolean per user

---

## 6. Identity & Access Model

### Identity

* Identity is established **via OAuth**
* User never enters credentials into ChatGPT
* Login happens in a browser window hosted by your app
* ChatGPT only receives an access token

### Access Control

* GPT itself is not paywalled
* **All valuable actions are gated in the backend**
* Backend is the source of truth

### Important Clarification

* “Invite-only” GPT access is **not** identity
* It does not provide billing enforcement
* OAuth token subject (`sub`) is the canonical user identifier

---

## 7. User Flows

### Flow A — Unpaid User

1. User opens Custom GPT
2. User runs “Check my access”
3. OAuth login triggered
4. Backend returns `DENY`
5. GPT explains access is limited

### Flow B — Paid User

1. User completes Stripe checkout
2. Stripe webhook activates entitlement
3. User runs “Check my access”
4. Backend returns `ALLOW`
5. GPT confirms access

### Flow C — Canceled Subscription

1. Subscription canceled in Stripe
2. Webhook deactivates entitlement
3. Same user runs action again
4. Backend returns `DENY`

---

## 8. Test Plan

| Test ID | Scenario | Expected Result |
| ------- | -------------------------------- | --------------- |
| T1 | First-time user, no subscription | DENY |
| T2 | Same user after subscribing | ALLOW |
| T3 | Subscription canceled | DENY |
| T4 | Repeat calls | Stable identity |

---

## 9. Risks & Mitigations

### Risk: GPT access without payment

* Mitigation: GPT can talk, but backend enforces all value

### Risk: OAuth complexity

* Mitigation: Start with simplest OAuth + magic link

### Risk: Platform changes by OpenAI

* Mitigation: Pattern relies on standard OAuth + API calls

---

## 10. Future Extensions (Post-MVP)

* Map user_id → Qwrk workspace
* Gate specific actions (save/update/promote)
* Add role-based entitlements
* Replace GPT UI with bespoke front-end later

---

## 11. Outcome This MVP Decides

If users are willing to:

* Subscribe
* Authenticate
* Use a GPT-first workflow

…then Qwrk can be monetized **before** building a custom UI, using the same architecture.

---

**Status:** Ready for implementation
**Confidence:** High
**UI Required:** None (ChatGPT is the UI)