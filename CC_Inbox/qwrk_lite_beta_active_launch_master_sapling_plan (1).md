# Qwrk Lite — Beta Active Launch Program
## Master Sapling (Execution Plan — Full Leaf Definition)

---

## Objective

Take Qwrk from current state to:
- Users signed up
- Users provisioned
- Users onboarded
- Users complete first success loop (save → retrieve → clarity)
- System proves end-to-end reliability

Primary success driver:
> System proves it works end-to-end

---

## Execution Doctrine

- No new features
- No scope expansion
- All work must map to beta success
- Pre-vacation work must be tightly scoped
- Every leaf defined BEFORE execution

---

# 🌱 MASTER SAPLING STRUCTURE

## Branch A — Infrastructure Readiness
**Goal:** System works reliably (save + retrieve + stability)

### Leaves
- A1 — Gateway parity upgrade (v46 → v50+)
- A2 — Validate all Gateway actions (save, query, list, update, promote)
- A3 — Error visibility (ensure errors surface clearly, no silent failure)
- A4 — Logging baseline (basic request/response traceability)
- A5 — Hosting decision finalized
- A6 — Deploy Gateway to chosen hosting
- A7 — End-to-end save/retrieve validation (manual tests)
- A8 — Stability pass (repeat tests across sessions)

---

## Branch B — Operator Provisioning System
**Goal:** Create and provision users reliably

### Leaves
- B1 — Define provisioning checklist (manual SOP)
- B2 — Supabase auth user creation process
- B3 — qxb_user record creation
- B4 — Workspace creation process
- B5 — Workspace-user linkage validation
- B6 — Gateway ACL creation process
- B7 — Principal credential setup process
- B8 — Gateway resolver mapping update (n8n)
- B9 — Qx dynamic configuration design (no hardcoded profiles)
- B10 — Qx user configuration flow (per user)
- B11 — End-to-end provisioning dry run (single user)
- B12 — Repeat provisioning test (multiple users)
- B13 — Provisioning time optimization (target <10 min)
- B14 — Define concierge onboarding messaging

---

## Branch C — User Onboarding (First Success Loop)
**Goal:** User achieves save → retrieve → clarity

### Leaves
- C1 — Define onboarding script (system prompt behavior)
- C2 — First interaction guidance (what user should do first)
- C3 — Save action guidance (clear instruction)
- C4 — Retrieval action guidance
- C5 — Reinforcement messaging (explain what happened)
- C6 — Define "aha moment" explicitly
- C7 — Confusion reduction pass (remove ambiguity in prompts)
- C8 — Onboarding dry run (self-test)
- C9 — External user test (1 user)
- C10 — Refine onboarding based on confusion points

---

## Branch D — Acquisition + Entry Point
**Goal:** Users can discover and enter the system

### Leaves
- D1 — Define beta positioning (what Qwrk Lite is)
- D2 — Define expectation setting (what user should expect)
- D3 — Website minimal structure (landing page only)
- D4 — Signup capture mechanism (form or email)
- D5 — Signup → provisioning handoff process
- D6 — Access delivery instructions (how user gets in)
- D7 — First user acquisition (initial testers)
- D8 — Feedback capture method (simple, lightweight)

---

## Branch E — System Validation Loop (Cross-Branch)
**Goal:** Prove system works end-to-end repeatedly

### Leaves
- E1 — Full journey test (signup → provisioning → onboarding)
- E2 — Repeat test across multiple users
- E3 — Failure capture (document where things break)
- E4 — Fix critical blockers only (no feature expansion)
- E5 — Validate consistency across sessions
- E6 — Confirm user completes first success loop
- E7 — Confirm user returns for second use

---

# 🔗 CRITICAL PATH

A → B → C → D → E

Must be executed in order.

---

## Hard Blockers (Must Be Resolved Early)

- Gateway parity upgrade
- Hosting decision
- Qx dynamic configuration
- Provisioning workflow

---

## Definition of Done (Beta Ready)

- User can sign up
- User can be provisioned
- User completes onboarding
- User successfully saves and retrieves
- System performs consistently across users

---

## Execution Rule

DO NOT begin execution until:
- Plan is approved
- All leaves reviewed
- CC validation complete

---

## Notes

- Existing saplings must be linked, not rebuilt
- Focus on reliability over expansion
- Concierge onboarding is acceptable during beta

---

END OF PLAN

