# Restart — People Intake: "Signup + NDA" (MVP) — 2026-01-02 (v1)

> **Canonical Restart Artifact**
> **Artifact ID**: `a4b0bfd5-147a-4b5e-b43b-e3f220f4f681`
> **Title**: Restart — People Intake: "Signup + NDA" (MVP) — 2026-01-02 (v1)
> **Status**: Active (canonical)

> **Semantic note:** Per Kernel v1 locks, **Snapshots are lifecycle-only** (no ad-hoc). This record is saved as a **Restart** artifact (manual freeze + next step) to preserve correct semantics. (See: Kernel Semantics Lock + Gateway Contract locks.)

## Date
2026-01-02

## Current objective
Stand up a simple **n8n-driven intake** that:
1) Collects **email** for Qwrk updates
2) Captures **NDA acknowledgment / e-sign intent**
…and creates a **People/Person artifact** foundation soon (manual tracking acceptable for now).

## What we decided (locked for this MVP)
- We can **track NDA + email manually** initially; the workflow should still capture the user's submission in a structured way for later automation.
- The first-pass solution can present the NDA text directly in the intake flow (form/page) and capture an explicit acknowledgement (checkbox + typed name) rather than relying on a separate e-sign vendor for MVP.
- We will **add Google Drive integration after the workflow is built**, not as a dependency up front.

## MVP workflow behavior (n8n)
### Trigger / Entry
- Public-facing signup form (or lightweight landing + form) that collects:
  - email (required)
  - full name (required for typed signature)
  - "I agree to the NDA terms" checkbox (required)
  - timestamp (auto)
  - optional company/role

### Core steps
1. **Validate inputs**
   - email present + basic format
   - NDA checkbox must be true
   - typed name must be present
2. **Persist submission**
   - Store to Google Sheets (interim log for MVP)
   - Later: create Qwrk People artifact
3. **Confirmation response**
   - "You're registered for updates."
   - "Your NDA acknowledgement has been received."

### Deferred integrations (explicitly NOT required for MVP)
- Google Drive: store a generated PDF or a copied NDA doc per user
- DocuSign / Adobe Sign / Google eSign equivalent (if needed later)
- Automated email confirmations (MVP sends dual emails: signer receipt + admin notification)

## Data we want captured (minimal schema)
- email (normalized: lowercase, trimmed)
- full_name (typed signature)
- nda_accept (true/false)
- nda_version (string, e.g. "nda_v1_2026-01-02")
- nda_text_hash (SHA-256 hash for audit trail)
- created_at_utc (ISO 8601 timestamptz)
- source (e.g. "n8n_form_qwrk_updates")
- company (optional)
- status (registered | duplicate_blocked)

## Risks / constraints
- This MVP is **not a legally-strong e-sign substitute** in all jurisdictions; it's a pragmatic "capture intent + acknowledgement" until we formalize.
- Avoid storing any secrets/credentials in the artifact content.
- Preserve governance meaning: use **Restart** for ad-hoc capture; reserve **Snapshot** for lifecycle transitions only.

## Next actions (gated)
1) Build the n8n workflow (first, without Drive).
2) Add a Qwrk "People/Person" artifact type and/or interim table when ready.
3) Decide whether we need a formal e-sign provider for beta users.

## "Known-Good" test (manual)
- Submit the form with valid fields → expect ok confirmation + record stored.
- Submit without NDA checkbox → expect validation error.
- Submit with invalid email → expect validation error.
- Submit duplicate email → expect duplicate_blocked status.

## Implemented Workflow
**Workflow**: `Qxb_Onboarding_Signup_NDA_Clickwrap_v1`
**Location**: `new-qwrk-kernel/workflows/Qxb_Onboarding_Signup_NDA_Clickwrap_v1.json`
**Documentation**: `new-qwrk-kernel/workflows/changelogs/Qxb_Onboarding_Signup_NDA_Clickwrap_v1__README.md`
**Test Plan**: `new-qwrk-kernel/workflows/changelogs/Qxb_Onboarding_Signup_NDA_Clickwrap_v1__Test_Plan.md`

## CHANGELOG

### v1 - 2026-01-02
**What changed:**
- Created canonical Restart artifact in Qwrk database
- Corrected semantic type from Snapshot to Restart
- Added artifact ID reference: `a4b0bfd5-147a-4b5e-b43b-e3f220f4f681`
- Aligned with built n8n workflow (Qxb_Onboarding_Signup_NDA_Clickwrap_v1)
- Updated data schema to match implemented workflow
- Added SHA-256 hash for NDA text audit trail
- Added status field (registered | duplicate_blocked)

**Why:**
- Enforce correct Kernel v1 semantics (Snapshot = lifecycle-only; Restart = ad-hoc freeze)
- Establish single canonical source of truth for People Intake workflow
- Align documentation with implemented n8n workflow

**Scope of impact:**
- Supersedes: `AAA_New_Qwrk__Restart__BetaSignup_NDA_v1__2026-01-02.md` (artifact: 5708a92e-6448-4493-8ff0-f7f614ed7dca)
- References implemented workflow in new-qwrk-kernel/workflows/

**How to validate:**
- Verify artifact ID `a4b0bfd5-147a-4b5e-b43b-e3f220f4f681` exists in Qwrk database
- Confirm data schema matches Qxb_Onboarding_Signup_NDA_Clickwrap_v1 workflow
- Review implemented workflow documentation for alignment
