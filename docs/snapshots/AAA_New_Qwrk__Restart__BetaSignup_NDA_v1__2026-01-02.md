# Snapshot — Qwrk Beta Signup + NDA (Manual Tracking) — v1 (2026-01-02)

## Purpose
Stand up a **simple, n8n-driven intake** so a new beta user can:
1) submit contact info to receive Qwrk update emails, and  
2) receive an NDA for e‑signature (tracked manually for now),  
so we can start registering people soon (People artifact coming next).

This snapshot captures the **current intended functionality** and the **workflow spec** for Claude Code (CC) / Team Qwrk to build in n8n.

---

## North Star / Kernel alignment
- **Snapshots are lifecycle-only** (project transitions) and are not meant for ad-hoc documentation freezes.  
- This “freeze + next step” record fits **Restart** semantics: manual/ad-hoc, immutable, no lifecycle change.  
  (Kernel semantics: Restart is manual/ad-hoc and stores `frozen_payload` inline.)

So: **store this record as a `restart` artifact**, not a `snapshot` artifact.

---

## User experience (v1)
### Step 1 — Signup form
User lands on a simple n8n form and provides:
- name
- email
- optional: company / role
- checkbox consent: “Send me Qwrk update emails”
- checkbox: “I agree to sign the NDA to join beta” (acknowledges the next step)

### Step 2 — NDA delivery (e-sign, tracked manually)
After form submit:
- n8n sends an email to the user with:
  - a short welcome
  - a link to the NDA for e-sign (exact Google Drive / e-sign mechanism to be plugged in later)
  - instructions: “Sign, then reply ‘done’ to confirm” (or “use the e-sign completion email”)
- n8n sends an internal notification email to Master Joel with the submission details.

### Step 3 — Manual status tracking (temporary)
For now, Master Joel manually tracks:
- who signed
- date signed
- where the signed PDF lives (Drive path / link)

(We’ll upgrade this to a Qwrk “people” artifact + NDA status later.)

---

## Why not embed the full NDA inside the n8n form?
**Click-to-accept in a web form is usually not the same as a properly executed NDA.**
Common problems with “form-only NDA acceptance”:
- weak identity proof (who clicked?)
- weak audit trail + tamper concerns
- missing countersignature workflow (if needed)
- jurisdiction/enforceability uncertainty without a compliant e-sign record

So v1 keeps it simple: **form collects intent + contact info; NDA is signed via a dedicated e-sign flow**.

---

## n8n Workflow Spec (build target)
### Workflow name (suggested)
`Qwrk_BetaSignup_v1__Intake_And_NDA_Link`

### Trigger
- n8n Form Trigger (or Webhook + HTML form if preferred)

### Core nodes (minimal)
1. **Form/Webhook In**  
   Validate required fields; normalize email (trim/lowercase).

2. **Deduplicate check (optional but recommended)**  
   If using a lightweight store (Sheet/Data Table), check if email already exists.  
   - If exists: send “you’re already on the list” email; notify Joel; end.
   - If new: continue.

3. **Create/append record (optional for now)**  
   Store submission in a simple table (n8n Data Table or Google Sheet):
   - name, email, company/role, timestamp, nda_status='pending', source='beta_signup_form'

4. **Send email to user**
   - Welcome + expectations
   - NDA link (placeholder variable for now)
   - What happens after they sign

5. **Send notification to Master Joel**
   - Full submission payload
   - Reminder: manually track NDA completion
   - Link to the row (if we used a table/sheet)

6. **Respond**
   - Friendly success page / message

### Required environment variables / placeholders
- `NDA_LINK` (temporary hard-coded placeholder until Drive details are connected)
- `FROM_EMAIL` (Google Workspace / SMTP credential in n8n)
- `JOEL_NOTIFY_EMAIL`
- optional: `SHEET_ID` or `DATA_TABLE_NAME`

### Invariants (v1)
- Never lose an intake submission (always notify Joel even if storage fails).
- Email is normalized and validated.
- Duplicate emails don’t create duplicate rows (if dedupe enabled).
- NDA status defaults to `pending`.
- No People artifact writes yet (manual tracking until People is built).

### Failure modes + handling
- **Email send fails:** notify Joel immediately with the raw payload.
- **Storage fails (sheet/table):** still send user email + Joel notification; include a “storage failed” flag.
- **Duplicate detected:** do not re-add; still notify Joel.

### Test checklist (KGB-style)
- Submit valid new user → success response, user email, Joel email, record created (if enabled).
- Submit same email twice → duplicate path fires, no duplicate record, user gets “already registered” message.
- Submit invalid email → rejected with clear error.
- Simulate storage failure → Joel notified with `storage_failed=true`.

---

## Next step (after v1 works)
- Add **People artifact** (Qxb_Artifact_People / User profile) and have this workflow:
  - create a `person` record
  - create an `nda` record/status entry (or a People subfield)
- Add “NDA signed” capture via:
  - webhook callback from e-sign provider, or
  - mailbox watch parsing “completed” emails, or
  - Drive folder watcher for new signed PDFs

---

## Metadata
- Owner: Master Joel
- Date: 2026-01-02
- Status: v1 spec captured; ready for workflow build in n8n
