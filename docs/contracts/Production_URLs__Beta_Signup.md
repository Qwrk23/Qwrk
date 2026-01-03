# Production URLs — Beta Signup

**Purpose**: Canonical reference for live beta signup endpoints and resources

**Last Updated**: 2026-01-03

---

## Beta Signup Form

**Live Form URL**: https://n8n.halosparkai.com/form/qwrk-nda-signup

**Status**: ✅ Active (as of 2026-01-03)

**What it does**:
- Captures beta registration with NDA clickwrap acceptance
- Validates email dedupe (prevents duplicate signups)
- Sends confirmation email to signer with NDA acceptance details
- Sends admin notification to joel@halosparkai.com
- Logs all signups to Google Sheets

**First signup**: 2026-01-03

---

## Related Resources

**NDA Full Text**: https://github.com/Qwrk23/Qwrk/blob/main/docs/contracts/NDA__Beta_Clickwrap__v1__2026-01-03.md

**Google Sheet (Admin Only)**: Qwrk NDA Signups
- Sheet ID: `1wYpb00qeY4_x6dSmPZUCJLnv9MaivVuHPgbF8uSXJZs`

**n8n Workflow**: `Qxb_Onboarding_Signup_NDA_Clickwrap_v1`

---

## Usage

**Sharing the Form**:
- Safe to share publicly
- Can be embedded in emails, social media, website
- Form includes link to full NDA terms on GitHub

**Example Message**:
```
Register for Qwrk beta updates and accept our NDA:
https://n8n.halosparkai.com/form/qwrk-nda-signup

Note: Registration does not guarantee beta access. We'll contact selected participants directly.
```

---

## CHANGELOG

### 2026-01-03
**What changed**: Initial production URL documentation

**Why**: Capture live form URL for easy reference and sharing

**Scope**: First production deployment of beta signup form

**First signup received**: 2026-01-03

---

**Version**: v1
**Status**: Production
