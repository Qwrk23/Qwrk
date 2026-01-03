# Snapshot (Restart Record) — People Intake: “Signup + NDA” (MVP) — 2026-01-02 (v1)

> **Semantic note:** Per Kernel v1 locks, **Snapshots are lifecycle-only** (no ad-hoc). This record is therefore intended to be saved as a **Restart** artifact (manual freeze + next step) to preserve meaning. (See: Kernel Semantics Lock + Gateway Contract locks.) fileciteturn0file0

## Date
2026-01-02

## Current objective
Stand up a simple **n8n-driven intake** that:
1) Collects **email** for Qwrk updates  
2) Captures **NDA acknowledgment / e-sign intent**  
…and creates a **People/Person artifact** foundation soon (manual tracking acceptable for now).

## What we decided (locked for this MVP)
- We can **track NDA + email manually** initially; the workflow should still capture the user’s submission in a structured way for later automation.
- The first-pass solution can present the NDA text directly in the intake flow (form/page) and capture an explicit acknowledgement (checkbox + typed name) rather than relying on a separate e-sign vendor for MVP.
- We will **add Google Drive integration after the workflow is built**, not as a dependency up front.

## MVP workflow behavior (n8n)
### Trigger / Entry
- Public-facing signup form (or lightweight landing + form) that collects:
  - email
  - full name (optional but recommended)
  - “I agree to the NDA terms” checkbox (required)
  - typed full name as signature (required)
  - timestamp (auto)
  - optional company/role

### Core steps
1. **Validate inputs**
   - email present + basic format
   - NDA checkbox must be true
   - typed name must be present
2. **Persist submission**
   - Store to Qwrk (later automated) or to interim table/log (for now)
3. **Confirmation response**
   - “You’re registered for updates.”
   - “Your NDA acknowledgement has been received.”

### Deferred integrations (explicitly NOT required for MVP)
- Google Drive: store a generated PDF or a copied NDA doc per user
- DocuSign / Adobe Sign / Google eSign equivalent (if needed later)
- Automated email confirmations (can be added later)

## Data we want captured (minimal schema)
- email
- name (typed signature)
- nda_acknowledged (true/false)
- nda_version (string, e.g. “NDA_v1_2026-01-02”)
- submitted_at (UTC timestamptz)
- source (e.g. “n8n_form_qwrk_updates”)
- notes (free text, optional)

## Risks / constraints
- This MVP is **not a legally-strong e-sign substitute** in all jurisdictions; it’s a pragmatic “capture intent + acknowledgement” until we formalize.
- Avoid storing any secrets/credentials in the artifact content.
- Preserve governance meaning: use **Restart** for ad-hoc capture; reserve **Snapshot** for lifecycle transitions only.

## Next actions (gated)
1) Build the n8n workflow (first, without Drive).  
2) Add a Qwrk “People/Person” artifact type and/or interim table when ready.  
3) Decide whether we need a formal e-sign provider for beta users.

## “Known-Good” test (manual)
- Submit the form with valid fields → expect ok confirmation + record stored.
- Submit without NDA checkbox → expect validation error.
- Submit with invalid email → expect validation error.
