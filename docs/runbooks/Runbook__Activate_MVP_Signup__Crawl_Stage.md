# Runbook — Activate MVP Signup (Crawl Stage) v1.1

**Stage**: 🟢 Crawl (MVP) — ✅ COMPLETE
**Purpose**: Get Qwrk NDA + Email signup live with minimal surface area
**Date**: 2026-01-03
**Completion Date**: 2026-01-03
**Owner**: Master Joel

---

## Overview

This runbook activates the **existing** n8n workflow for Qwrk signup + NDA clickwrap. No code changes required—configuration only.

**Workflow**: `Qxb_Onboarding_Signup_NDA_Clickwrap_v1`
**Canonical Restart**: `a4b0bfd5-147a-4b5e-b43b-e3f220f4f681`

---

## Feature Metadata

**Feature Name**: NDA Clickwrap Signup (Crawl MVP)

**Stage**: 🟢 Crawl

**Status**: ✅ LIVE IN PRODUCTION (activated 2026-01-03)

**Capabilities** (what is supported):
- NDA acceptance with SHA-256 audit trail
- Email dedupe (prevent duplicate signups by email address)
- Dual email notifications (signer receipt + admin notification)
- Google Sheets logging (all signups tracked)
- Typed signature (full name field)
- Manual review workflow for beta candidate selection

**Non-capabilities** (explicitly not supported):
- No user account creation (no Supabase Auth integration)
- No workspace assignment
- No automated email sequences beyond immediate receipt
- No beta access granting (manual review only)
- No PDF storage or Drive integration
- No formal e-signature provider integration

**User-facing summary**:
Qwrk's signup form allows prospective users to register their interest and accept the NDA. Upon submission, users receive a confirmation email with an NDA acceptance receipt including a cryptographic hash of the NDA text they agreed to. The admin is notified of each signup. Duplicate email addresses are automatically prevented. This is a manual-review system—signing up does NOT grant immediate access to Qwrk. The admin reviews signups in Google Sheets and will contact promising beta candidates individually.

**Demo safety**: Demo-safe
- Can be demonstrated publicly without restrictions
- No sensitive data exposed in signup form
- Works with test email addresses
- Form URL can be shared openly
- Google Sheets backend is admin-only (not exposed to users)

---

## Pre-Requisites

✅ **Already Complete**:
- n8n workflow built and documented
- Test plan exists with 3 core + 3 edge case tests
- Canonical Restart artifact saved in Qwrk

❌ **Required Before Activation**:
- Google Sheet created with correct headers
- SMTP/Gmail credential configured in n8n
- Placeholders replaced with actual values

---

## Step 1: Create Google Sheet

### 1.1 Create New Sheet

1. Go to Google Sheets
2. Create new sheet named: **"Qwrk NDA Signups"**
3. Add headers (EXACT match required):

```
created_at_utc | email | full_name | company | nda_accept | nda_version | nda_text_hash | ip_address | user_agent | source | status | notes
```

### 1.2 Get Sheet ID

From URL: `https://docs.google.com/spreadsheets/d/{SHEET_ID}/edit`

Copy the `{SHEET_ID}` portion.

### 1.3 Set Permissions

- Ensure n8n service account has **Editor** access
- Or: Use OAuth2 with Joel's Google account

---

## Step 2: Configure n8n Workflow

### 2.1 Import Workflow (If Not Already Imported)

1. Open n8n
2. Import: `new-qwrk-kernel/workflows/Qxb_Onboarding_Signup_NDA_Clickwrap_v1.json`

### 2.2 Update Placeholders

**Google Sheets Nodes** (2 nodes: Lookup + Insert):
- Find: `GOOGLE_SHEET_ID_PLACEHOLDER`
- Replace with: `{SHEET_ID from Step 1.2}`

**Email Send Nodes** (2 nodes: Signer Receipt + Admin Notification):
- Find: `noreply@qwrk.example.com`
- Replace with: Actual sender email (e.g., `noreply@qwrk.ai`)

**Admin Email Node**:
- Find: `ADMIN_EMAIL_PLACEHOLDER`
- Replace with: Joel's admin email

### 2.3 Configure Credentials

**Google Sheets Credential**:
1. Create new OAuth2 credential
2. Authorize with Google account that has access to sheet
3. Assign to both Google Sheets nodes

**SMTP/Gmail Credential**:
1. Create SMTP credential OR Gmail OAuth2 credential
2. Assign to both Email Send nodes

---

## Step 3: Test Workflow

### 3.1 Manual Execution Test

1. Click "Execute Workflow" in n8n
2. Use pinned test data (if available)
3. Verify:
   - ✅ No errors in execution log
   - ✅ Google Sheets row inserted
   - ✅ Email sent (check inbox)

### 3.2 Run Test Plan

Execute test cases from:
`new-qwrk-kernel/workflows/changelogs/Qxb_Onboarding_Signup_NDA_Clickwrap_v1__Test_Plan.md`

**Minimum Tests** (before activation):
- ✅ TC-01: New signup (happy path)
- ✅ TC-02: Duplicate email (dedupe logic)
- ✅ TC-03: NDA not accepted (rejection path)

---

## Step 4: Activate Workflow

### 4.1 Activate in n8n

1. Toggle "Active" on workflow
2. Obtain Form Trigger URL
3. Test form submission via URL

### 4.2 Document Form URL

**Production Form URL**: https://n8n.halosparkai.com/form/qwrk-nda-signup

**Status**: ✅ LIVE (activated 2026-01-03)

**Documentation**: See `docs/contracts/Production_URLs__Beta_Signup.md` for canonical URL reference

---

## Step 5: Post-Activation Validation

### 5.1 Live Test Signup

1. Navigate to Form URL
2. Submit test signup with real email
3. Verify:
   - ✅ Form response: "Registration successful!"
   - ✅ Signer receipt email received
   - ✅ Admin notification received
   - ✅ Google Sheets row created
   - ✅ SHA-256 hash populated

### 5.2 Live Test Duplicate

1. Submit same email again
2. Verify:
   - ✅ Form response: "You are already registered."
   - ✅ Status: `duplicate_blocked`
   - ✅ NO new row in Google Sheets
   - ✅ Admin notification indicates duplicate

---

## Step 6: Distribute Form URL

### 6.1 Update Marketing Materials

Add Form URL to:
- Qwrk website (if applicable)
- Email footer
- Social media bio

### 6.2 Announce to Beta Candidates

Send email with:
- Form URL
- What they're signing up for (email updates + NDA acknowledgment)
- What happens next (manual review, future access)

---

## Manual Operations (Ongoing)

**Owner Actions** (per signup):

1. **Review Admin Email**
   - Check for new signup notifications
   - Note status: `registered` or `duplicate_blocked`

2. **Review Google Sheet**
   - Periodically check "Qwrk NDA Signups" sheet
   - Review all new entries
   - Add notes in `notes` column as needed

3. **Track Beta Candidates**
   - Identify promising signups for SELECT beta access (future)
   - No automated granting—manual review only

---

## Known Limitations (Crawl MVP)

❌ **Does NOT**:
- Create Qwrk user accounts
- Assign workspaces
- Grant system access
- Integrate with Drive (no PDF storage)
- Integrate with formal e-sign provider
- Automatically send onboarding sequences

✅ **Does**:
- Capture NDA intent with SHA-256 audit trail
- Log all signups to Google Sheets
- Prevent duplicate signups
- Notify owner of all activity
- Provide typed signature (full name)

**Rationale**: Minimal viable signup to get live quickly. Automation and integration come in Walk/Run stages.

---

## Rollback Plan

### If Issues Arise

**Immediate**:
1. Deactivate workflow in n8n (toggle "Active" OFF)
2. Form URL returns "Workflow not active" message

**Data Preservation**:
- Google Sheets retains all submissions
- No data loss from deactivation

**Re-Activation**:
- Fix issue in workflow
- Re-test with test plan
- Toggle "Active" ON

---

## Next Steps (Walk Stage)

**NOT part of Crawl MVP** (deferred to Walk):
- Automated email confirmation sequences
- NDA versioning UI
- Beta candidate flagging system
- Better admin dashboard (replace Sheets with Qwrk artifacts)

See: `Design__Onboarding_Walk_Stage__Enhanced_MVP__v1.1__2026-01-03.md`

---

## Success Criteria

Crawl MVP is **LIVE** when:
1. ✅ Form URL is publicly accessible
2. ✅ Test Plan TC-01, TC-02, TC-03 pass with live workflow
3. ✅ Admin receives notifications for all signups
4. ✅ Google Sheet populates correctly
5. ✅ Duplicate prevention works

**Status**: ✅ **CRAWL STAGE COMPLETE** (2026-01-03)

All success criteria validated with first production signup on 2026-01-03.

---

## Completion Summary

**Completion Date**: 2026-01-03
**First Production Signup**: 2026-01-03
**Production URL**: https://n8n.halosparkai.com/form/qwrk-nda-signup

**Achievements**:
- NDA clickwrap with SHA-256 audit trail deployed
- Email dedupe working correctly
- Dual email notifications (signer + admin) functioning
- Google Sheets logging operational
- All test cases passing in production

**Next Stage**: Walk — Phase 1 (Email Automation) ready for next build session

---

## References

**Canonical Restart**: `AAA_New_Qwrk/Snapshots/AAA_New_Qwrk__Restart__People_Intake_Signup_NDA_MVP__2026-01-02__v1.md`
**Workflow Documentation**: `new-qwrk-kernel/workflows/changelogs/Qxb_Onboarding_Signup_NDA_Clickwrap_v1__README.md`
**Test Plan**: `new-qwrk-kernel/workflows/changelogs/Qxb_Onboarding_Signup_NDA_Clickwrap_v1__Test_Plan.md`

---

## CHANGELOG

### v1.3 - 2026-01-03
**What changed**: Crawl stage marked COMPLETE

**Why**: All success criteria validated with first production signup; Crawl MVP fully operational

**Scope of impact**:
- Stage status: LIVE IN PRODUCTION → COMPLETE
- Added completion date and summary section
- Documented all achievements and next stage transition
- Phase 1 of Walk stage ready for next build session

**How to validate**: Review Completion Summary section for achievements and verification

### v1.2 - 2026-01-03
**What changed**: Production activation complete - updated status and documented live form URL

**Why**: Workflow is now live in production with first signup received

**Scope of impact**:
- Status updated to "LIVE IN PRODUCTION"
- Production form URL documented: https://n8n.halosparkai.com/form/qwrk-nda-signup
- Cross-reference to Production_URLs__Beta_Signup.md added
- First beta signup received 2026-01-03

**How to validate**: Form URL is publicly accessible and processing signups correctly

### v1.1 - 2026-01-03
**What changed**: Added Feature Metadata section (CLAUDE.md Section 7.5 compliance)

**Why**: Per governance requirements, all canonical documentation must include metadata for derivation: capabilities, non-capabilities, user-facing summary, and demo safety classification

**Scope of impact**: Documentation only; no changes to runbook execution steps

**How to validate**: Review Feature Metadata section for completeness per CLAUDE.md lines 286-298

### v1 - 2026-01-03
**What changed**: Initial runbook creation

**Why**: Document activation steps for Crawl MVP (configuration-only, no code changes)

**Scope of impact**: New runbook for activating existing n8n workflow

---

**Version**: v1.3
**Status**: ✅ COMPLETE
**Production URL**: https://n8n.halosparkai.com/form/qwrk-nda-signup
**Activation Date**: 2026-01-03
**Completion Date**: 2026-01-03
**Last Updated**: 2026-01-03
