# Test Plan — Qxb_Onboarding_Signup_NDA_Clickwrap_v1

**Workflow**: Qwrk Signup + Clickwrap NDA (Form Trigger)

**Version**: v1 (MVP)

**Last Updated**: 2026-01-02

---

## Purpose

This test plan validates the core functionality of the Qwrk signup workflow with inline NDA clickwrap acceptance. It ensures proper data logging, email notifications, and duplicate prevention.

---

## Pre-Test Setup

### 1. Google Sheets Configuration

Create a Google Sheet named "Qwrk NDA Signups" with the following headers (exact match required):

```
created_at_utc | email | full_name | company | nda_accept | nda_version | nda_text_hash | ip_address | user_agent | source | status | notes
```

### 2. n8n Configuration

Update the workflow with actual values:

- **Google Sheets Node**: Replace `GOOGLE_SHEET_ID_PLACEHOLDER` with actual Sheet ID
- **Google Sheets Credential**: Connect OAuth2 credential for Google Sheets API
- **Email Send Nodes**: Replace `noreply@qwrk.example.com` with actual sender email
- **Admin Email**: Replace `ADMIN_EMAIL_PLACEHOLDER` with Joel's admin email address
- **SMTP Credential**: Connect SMTP or Gmail credential

### 3. Workflow Activation

Activate the workflow in n8n and obtain the Form Trigger URL (e.g., `https://your-n8n.app.n8n.cloud/form/qwrk-nda-signup`).

---

## Test Cases

### TC-01: New Signup (Happy Path)

**Objective**: Validate that a new signup inserts a row in Google Sheets and sends both confirmation emails.

**Test Steps**:

1. Navigate to the Form Trigger URL
2. Fill in the form with test data:
   - **Full Name**: `Joel Master`
   - **Email**: `joel+test1@example.com`
   - **Company**: `Qwrk`
   - **NDA Checkbox**: ✅ Checked
3. Submit the form

**Expected Results**:

✅ **Response**:
```json
{
  "ok": true,
  "status": "registered",
  "message": "Registration successful! Check your email for confirmation.",
  "created_at_utc": "2026-01-02T12:34:56.789Z"
}
```

✅ **Google Sheets**:
- New row inserted with:
  - `email`: `joel+test1@example.com`
  - `full_name`: `Joel Master`
  - `company`: `Qwrk`
  - `nda_accept`: `TRUE`
  - `nda_version`: `nda_v1_2026-01-02`
  - `nda_text_hash`: SHA-256 hash of NDA text (64-character hex string)
  - `status`: `registered`
  - `created_at_utc`: ISO 8601 timestamp (UTC)

✅ **Email 1 — Signer Receipt**:
- **To**: `joel+test1@example.com`
- **Subject**: `Qwrk — NDA Acceptance Receipt`
- **Body Contains**:
  - Full name: Joel Master
  - Email: joel+test1@example.com
  - Company: Qwrk
  - NDA Version: nda_v1_2026-01-02
  - NDA Text Hash: (64-character hash)
  - Timestamp

✅ **Email 2 — Admin Notification**:
- **To**: Admin email (configured placeholder)
- **Subject**: `Qwrk Signup + NDA — New Registration (registered)`
- **Body Contains**:
  - Full name: Joel Master
  - Email: joel+test1@example.com
  - Company: Qwrk
  - Status: registered
  - NDA Acceptance: true
  - Timestamp

**Notes**:
- Verify email normalization: Email should be stored in lowercase and trimmed
- Verify SHA-256 hash is consistent (same NDA text = same hash)
- Record the hash value for comparison in future tests

---

### TC-02: Duplicate Email (Dedupe Logic)

**Objective**: Validate that a duplicate email does NOT insert a new row and sends admin notification indicating duplicate status.

**Test Steps**:

1. Navigate to the Form Trigger URL
2. Fill in the form with the SAME email as TC-01:
   - **Full Name**: `Joel Master Duplicate`
   - **Email**: `joel+test1@example.com` (same as TC-01)
   - **Company**: `Qwrk Corp`
   - **NDA Checkbox**: ✅ Checked
3. Submit the form

**Expected Results**:

✅ **Response**:
```json
{
  "ok": true,
  "status": "duplicate_blocked",
  "message": "You are already registered.",
  "created_at_utc": "2026-01-02T12:45:00.123Z"
}
```

✅ **Google Sheets**:
- ❌ **NO new row inserted**
- Row count remains the same as after TC-01
- Original row (`joel+test1@example.com`) unchanged

✅ **Email 1 — Signer Receipt**:
- **To**: `joel+test1@example.com`
- **Subject**: `Qwrk — NDA Acceptance Receipt`
- **Body Should Indicate**: Already registered (duplicate detected)

✅ **Email 2 — Admin Notification**:
- **To**: Admin email
- **Subject**: `Qwrk Signup + NDA — New Registration (duplicate_blocked)`
- **Body Contains**:
  - Status: **duplicate_blocked**
  - Note that this email was already registered

**Notes**:
- Verify Google Sheets lookup by email is case-insensitive
- Test with variations: `JOEL+TEST1@EXAMPLE.COM` should also be detected as duplicate
- Verify no duplicate rows created even if user submits multiple times

---

### TC-03: NDA Not Accepted (Rejection Path)

**Objective**: Validate that unchecking the NDA checkbox fails submission with a clear error message and does NOT log data or send emails.

**Test Steps**:

1. Navigate to the Form Trigger URL
2. Fill in the form with valid data:
   - **Full Name**: `Joel Master Reject`
   - **Email**: `joel+reject@example.com`
   - **Company**: `Qwrk`
   - **NDA Checkbox**: ❌ **Unchecked**
3. Submit the form

**Expected Results**:

✅ **Response**:
```json
{
  "ok": false,
  "error": "You must accept the NDA to register."
}
```

OR (depending on n8n Form Trigger behavior):

Form validation may prevent submission if checkbox is required field. If so, user should see inline error message before submission.

✅ **Google Sheets**:
- ❌ **NO row inserted**
- Sheet remains unchanged

✅ **Emails**:
- ❌ **NO emails sent** (neither signer receipt nor admin notification)

**Notes**:
- Verify workflow stops at `ValidateNDAAccept` IF node
- Verify `ResponseNDAReject` node returns error message
- Workflow should NOT proceed to `BuildAcceptanceRecord` node

---

## Edge Cases (Optional Extended Testing)

### TC-04: Missing Optional Fields

**Test**: Submit form with only required fields (name, email, NDA checkbox)
- Company: Empty
- Source: Empty

**Expected**:
- ✅ Form accepts submission
- ✅ Row inserted with empty strings for company/source
- ✅ Emails sent successfully

---

### TC-05: Email Normalization

**Test**: Submit with uppercase/whitespace in email
- Email: `  JOEL+TEST2@EXAMPLE.COM  `

**Expected**:
- ✅ Email normalized to `joel+test2@example.com` (lowercase, trimmed)
- ✅ Dedupe lookup works correctly

---

### TC-06: Special Characters in Name/Company

**Test**: Submit with special characters
- Full Name: `O'Reilly, José María`
- Company: `Qwrk & Associates (Pty) Ltd.`

**Expected**:
- ✅ Form accepts submission
- ✅ Data stored correctly in Google Sheets
- ✅ Emails display special characters correctly

---

## Test Data Cleanup

After completing all tests:

1. **Delete test rows** from Google Sheets:
   - `joel+test1@example.com`
   - `joel+test2@example.com` (if TC-05 was run)

2. **Check spam folders** for test emails

3. **Deactivate workflow** if not ready for production use

---

## Success Criteria

All 3 core test cases (TC-01, TC-02, TC-03) must pass with ✅ results.

**Pass Criteria**:
- ✅ New signups create rows and send emails
- ✅ Duplicates are blocked from creating new rows
- ✅ Unchecked NDA checkbox prevents submission
- ✅ SHA-256 hash is consistent for identical NDA text
- ✅ Email normalization works correctly
- ✅ Admin receives notifications for both registered and duplicate statuses

**Fail Criteria**:
- ❌ Duplicate emails create new rows (dedupe broken)
- ❌ NDA rejection path allows signup (validation broken)
- ❌ Emails not sent or sent to wrong addresses
- ❌ Google Sheets insert fails
- ❌ Response messages are incorrect or misleading

---

## Known Limitations (MVP v1)

1. **IP Address / User Agent**: Currently empty (Form Trigger may not expose headers)
2. **NDA Text**: Placeholder text, needs final legal version
3. **Error Handling**: No graceful handling of Google Sheets or email failures
4. **NDA PDF Link**: Not yet implemented (Phase 2 enhancement)

---

## Future Enhancements

See [README — Future Enhancements](Qxb_Onboarding_Signup_NDA_Clickwrap_v1__README.md#future-enhancements) for Phase 2 and Phase 3 plans.

---

**Version**: v1 (MVP)
**Status**: Ready for Testing
**Last Updated**: 2026-01-02
