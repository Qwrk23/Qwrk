# Qxb_Onboarding_Signup_NDA_Clickwrap_v1 — Workflow Documentation

**n8n Form Trigger workflow for Qwrk signup with clickwrap NDA acceptance**

---

## Purpose

This workflow implements a signup form with inline NDA clickwrap that:
1. Collects user information (name, email, company)
2. Requires NDA acceptance via checkbox
3. Logs acceptances to Google Sheets tracker
4. Sends confirmation emails to both signer and admin
5. Deduplicates by email to prevent duplicate signups

---

## Canonical Restart

This workflow implements the specification frozen in the canonical Restart artifact:

**Artifact ID**: `a4b0bfd5-147a-4b5e-b43b-e3f220f4f681`
**Title**: Restart — People Intake: "Signup + NDA" (MVP) — 2026-01-02 (v1)
**Documentation**: `AAA_New_Qwrk/Snapshots/AAA_New_Qwrk__Restart__People_Intake_Signup_NDA_MVP__2026-01-02__v1.md`

**Semantic Governance**: This is a **Restart** artifact (ad-hoc freeze + next actions), not a Snapshot (lifecycle-only per Kernel v1).

**Supersedes**:
- Restart artifact `5708a92e-6448-4493-8ff0-f7f614ed7dca` (BetaSignup NDA v1) — marked as [SUPERSEDED]

---

## Workflow Details

**Workflow Name**: `Qxb_Onboarding_Signup_NDA_Clickwrap_v1`

**Trigger**: Form Trigger (n8n hosted form)

**Form URL**: Will be provided by n8n after activation (e.g., `https://your-n8n.app.n8n.cloud/form/qwrk-nda-signup`)

**Status**: MVP (placeholder NDA text, manual Google Sheets logging)

---

## Form Fields

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `full_name` | Text | Yes | Signer's full legal name |
| `email` | Email | Yes | Signer's email (used for dedupe) |
| `company` | Text | No | Signer's company/organization |
| `source` | Text | No | Hidden field for tracking referral source |

**NDA Acceptance**:
- Inline NDA text displayed in form description
- Checkbox: "I have read and agree to the Qwrk NDA above"
- Must be checked to proceed

---

## Data Model (Acceptance Record)

Each signup creates an acceptance record with these fields:

```json
{
  "created_at_utc": "2026-01-02T12:34:56.789Z",
  "full_name": "Joel Master",
  "email": "joel@example.com",
  "company": "Qwrk",
  "nda_accept": true,
  "nda_version": "nda_v1_2026-01-02",
  "nda_text_hash": "abc123...",
  "ip_address": "",
  "user_agent": "",
  "source": "",
  "status": "registered"
}
```

**Field Descriptions**:
- `created_at_utc`: ISO 8601 timestamp (UTC)
- `email`: Normalized (lowercase, trimmed)
- `nda_version`: Hardcoded version identifier
- `nda_text_hash`: SHA-256 hash of NDA text displayed in form
- `ip_address`: Best-effort from headers (empty if unavailable)
- `user_agent`: Best-effort from headers (empty if unavailable)
- `status`: `registered` or `duplicate_blocked`

---

## Workflow Logic

### 1. Form Submission

User fills form and submits.

### 2. Normalize & Validate

- Email normalized to lowercase and trimmed
- Company/source default to empty string if not provided
- NDA checkbox coerced to boolean

### 3. Validate NDA Acceptance

**IF nda_accept != true**:
- Return error response: "You must accept the NDA to register."
- Stop workflow

**IF nda_accept == true**:
- Continue to build acceptance record

### 4. Build Acceptance Record

- Generate `created_at_utc` timestamp
- Compute SHA-256 hash of NDA text
- Set `nda_version` to `nda_v1_2026-01-02`
- Set initial status to `pending`

### 5. Dedupe Check (Google Sheets Lookup)

Search "Qwrk NDA Signups" sheet for existing row where `email` matches.

**IF found (duplicate)**:
- Set `status = duplicate_blocked`
- Skip insert step
- Proceed to email notifications

**IF not found (new)**:
- Set `status = registered`
- Insert new row into Google Sheets
- Proceed to email notifications

### 6. Send Emails

**Email 1 - Signer Receipt**:
- To: Signer's email
- Subject: "Qwrk — NDA Acceptance Receipt"
- Body: Confirmation with receipt details + NDA text hash

**Email 2 - Admin Notification**:
- To: Admin email (placeholder: `ADMIN_EMAIL_PLACEHOLDER`)
- Subject: "Qwrk Signup + NDA — New Registration (status)"
- Body: Full details including status

### 7. Return Response

```json
{
  "ok": true,
  "status": "registered",
  "message": "Registration successful! Check your email for confirmation.",
  "created_at_utc": "2026-01-02T12:34:56.789Z"
}
```

OR (for duplicate):

```json
{
  "ok": true,
  "status": "duplicate_blocked",
  "message": "You are already registered.",
  "created_at_utc": "2026-01-02T12:34:56.789Z"
}
```

---

## Google Sheets Tracker

**Sheet Name**: `Qwrk NDA Signups`

**Headers** (must match exactly):
```
created_at_utc | email | full_name | company | nda_accept | nda_version | nda_text_hash | ip_address | user_agent | source | status | notes
```

**Insert Behavior**:
- Only inserts when `status = registered`
- Duplicates do NOT insert new rows

**Dedupe Lookup**:
- Searches by `email` column
- Exact match (case-insensitive via normalized email)

---

## Configuration Placeholders

The following values must be configured before activation:

### Google Sheets
- **Document ID**: Replace `GOOGLE_SHEET_ID_PLACEHOLDER` with actual Google Sheet ID
- **Sheet Name**: `Qwrk NDA Signups` (create this sheet with headers above)
- **Credentials**: Connect Google Sheets OAuth2 credential

### Email (SMTP)
- **From Email**: Replace `noreply@qwrk.example.com` with actual sender email
- **Admin Email**: Replace `ADMIN_EMAIL_PLACEHOLDER` with Joel's admin email
- **Credentials**: Connect SMTP credential (or Gmail credential)

### NDA Text
- **Current**: Placeholder NDA text in Form Trigger description
- **Future**: Replace with final versioned NDA text before production

---

## Node Structure

| Node | Type | Purpose |
|------|------|---------|
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_FormTrigger | Form Trigger | Hosted signup form |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_NormalizeAndValidate | Set | Normalize email, default values |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_ValidateNDAAccept | IF | Check nda_accept == true |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_ResponseNDAReject | Respond to Webhook | Error response if NDA not accepted |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_BuildAcceptanceRecord | Code | Build acceptance record + hash NDA text |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_SheetsLookupByEmail | Google Sheets | Search for existing email |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_DedupeSwitch | IF | Check if duplicate found |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_SetDuplicateStatus | Set | Set status = duplicate_blocked |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_SetRegisteredStatus | Set | Set status = registered |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_SheetsInsertRow | Google Sheets | Insert new row (registered only) |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_MergePaths | Merge | Merge duplicate and registered paths |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_SendSignerReceipt | Email Send | Confirmation to signer |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_SendAdminNotify | Email Send | Notification to admin |
| Qx_Onboarding_Signup_NDA_Clickwrap_v1_Response | Respond to Webhook | Success response |

---

## Failure Modes

| Failure | Handling |
|---------|----------|
| NDA not accepted | Return error response, stop workflow |
| Missing email | Form validation prevents submission |
| Google Sheets lookup fails | Workflow may error; needs error handling node |
| Google Sheets insert fails | Email still sent; admin notified of issue |
| Email send fails | Row still logged; response still returned |

**Future Enhancement**: Add error handling nodes to gracefully handle Google Sheets/email failures.

---

## Future Enhancements

### Phase 2 (Near-term)
1. **Add NDA PDF link**:
   - Upload final NDA PDF to Google Drive
   - Get shareable link
   - Add `nda_drive_url` field to acceptance record
   - Include PDF link in emails

2. **Improve IP/User-Agent capture**:
   - Extract from Form Trigger headers if available
   - Add to acceptance record for audit trail

3. **Add error handling**:
   - Catch Google Sheets credential failures
   - Catch email send failures
   - Return graceful errors while still attempting notifications

### Phase 3 (Later)
4. **Replace Google Sheets with Qwrk Gateway**:
   - Call `artifact.create` to save People artifact
   - Store acceptance record in Qwrk database
   - Deprecate Google Sheets tracker

5. **Add webhook notification**:
   - Notify external system of new signups
   - Integrate with CRM/marketing automation

---

## Test Plan

See: [Qxb_Onboarding_Signup_NDA_Clickwrap_v1__Test_Plan.md](Qxb_Onboarding_Signup_NDA_Clickwrap_v1__Test_Plan.md)

---

## Changelog

### v1 - 2026-01-02
- Initial MVP workflow
- Form Trigger with inline NDA text
- Google Sheets logging
- Dual email notifications (signer + admin)
- Email dedupe via Sheets lookup
- SHA-256 hash of NDA text for audit trail

---

## References

- [n8n Form Trigger Documentation](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.formtrigger/)
- [Google Sheets Node Documentation](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.googlesheets/)
- [Email Send Node Documentation](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.emailsend/)

---

**Version**: v1
**Status**: MVP (requires configuration before activation)
**Last Updated**: 2026-01-02
