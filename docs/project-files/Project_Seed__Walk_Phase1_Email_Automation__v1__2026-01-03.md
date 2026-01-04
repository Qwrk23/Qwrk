# Project Seed — Walk Phase 1: Email Automation

**Project Name**: Onboarding Email Automation (Walk Phase 1)
**Lifecycle Stage**: 🌱 Seed
**Owner**: Master Joel
**Date Created**: 2026-01-03
**Prerequisite**: Crawl stage complete ✅

---

## Seed Overview

Build automated email sequences and admin digest workflows to enhance the Crawl MVP signup experience. This is the first "leaf" of Walk stage implementation.

**Core Goal**: Nurture new signups with automated follow-up emails and reduce admin notification noise with digest summaries.

---

## What We're Building

### 1. Email Sequences Workflow
**Workflow**: `Qxb_Onboarding_Email_Sequences_v1`

**Functionality**:
- Day 3: "What to Expect from Qwrk" email (all signups)
- Day 7: "Beta Preview" email (high-priority candidates only)
- Automated tracking to prevent duplicate sends
- Cron-triggered (daily 9am UTC) OR webhook-triggered

**Data Source**: Google Sheets "Qwrk NDA Signups"

### 2. Admin Digest Workflow
**Workflow**: `Qxb_Onboarding_Admin_Digest_v1`

**Functionality**:
- Daily OR weekly summary email to admin
- Aggregates: total signups, high-priority candidates, duplicates
- Replaces individual per-signup notifications
- Includes quick-action links and summary table

---

## Schema Changes Required

**Google Sheets**: Add new columns to "Qwrk NDA Signups" sheet:

| Column | Type | Purpose |
|--------|------|---------|
| `email_sent_day_3` | Boolean | Tracks Day 3 email sent |
| `email_sent_day_7` | Boolean | Tracks Day 7 email sent |
| `priority` | Text | Auto-computed: high \| medium \| standard |
| `last_contacted` | Date | Last email sent timestamp |

**Migration**: Add columns to existing sheet; backfill with defaults (FALSE for booleans, "standard" for priority)

---

## Deliverables

1. **n8n Workflows** (2):
   - `Qxb_Onboarding_Email_Sequences_v1.json`
   - `Qxb_Onboarding_Admin_Digest_v1.json`

2. **Email Templates** (3):
   - Day 3: "What to Expect from Qwrk"
   - Day 7: "Beta Preview" (conditional)
   - Admin Digest: Daily/Weekly summary

3. **Documentation**:
   - Runbook for activation
   - Test plan (minimum 3 test cases per workflow)
   - Email template guidelines

4. **Schema Migration**:
   - Google Sheets column additions
   - Backfill script (if needed)

---

## Success Criteria

✅ Email sequences send automatically based on signup date
✅ Day 3 and Day 7 flags prevent duplicate sends
✅ Admin digest aggregates all signups since last run
✅ Emails render correctly (HTML + plain text fallback)
✅ All workflows tested with Crawl production data
✅ Runbook validated and approved

---

## Constraints & Boundaries

**In Scope**:
- Automated email sequences (Day 3, Day 7)
- Admin digest (daily/weekly)
- Google Sheets schema extensions
- Email tracking flags

**Out of Scope** (deferred to later phases):
- NDA versioning system (Phase 2)
- Beta candidate scoring (Phase 3)
- Dual-write to Qwrk artifacts (Phase 4)
- Unsubscribe management (future enhancement)
- Email deliverability monitoring (future enhancement)

---

## Risks & Mitigations

**Risk**: Email deliverability (flagged as spam)
**Mitigation**: Use Gmail OAuth2 (existing), monitor bounce rates, include clear unsubscribe link

**Risk**: Timing logic errors (duplicate sends)
**Mitigation**: Thorough testing with mock data, flag-based idempotency, dry-run mode

**Risk**: Admin digest too noisy (defeats purpose)
**Mitigation**: Make frequency configurable (daily vs weekly), test with real signup volume

---

## Timeline Estimate

**Duration**: 1-2 weeks (design + build + test)

**Phases**:
- **Days 1-2**: Design email templates, finalize workflow logic
- **Days 3-5**: Build n8n workflows, add Google Sheets columns
- **Days 6-8**: Test with Crawl production data, iterate on templates
- **Days 9-10**: Document runbook, create test plan
- **Day 11+**: Activation and monitoring

---

## Dependencies

**Prerequisites**:
- ✅ Crawl stage complete (2026-01-03)
- ✅ Google Sheets "Qwrk NDA Signups" operational
- ✅ Gmail OAuth2 credentials configured in n8n
- ✅ Production signup form active

**Blockers**: None identified

---

## Next Actions

1. Draft email templates (Day 3, Day 7, Admin Digest)
2. Design n8n workflow logic (both workflows)
3. Add tracking columns to Google Sheets
4. Build and test email sequences workflow
5. Build and test admin digest workflow
6. Create runbook and test plan
7. Activate workflows in production

---

## References

**Design Document**: `docs/design/Design__Onboarding_Walk_Stage__Enhanced_MVP.md` (v1.2)
**Crawl Runbook**: `docs/runbooks/Runbook__Activate_MVP_Signup__Crawl_Stage.md` (v1.3 COMPLETE)
**Production Form**: https://n8n.halosparkai.com/form/qwrk-nda-signup
**Google Sheet ID**: `1wYpb00qeY4_x6dSmPZUCJLnv9MaivVuHPgbF8uSXJZs`

---

## CHANGELOG

### v1 - 2026-01-03
**What changed**: Initial project seed creation

**Why**: Document Walk Phase 1 scope and deliverables for next build session

**Scope**: Email automation workflows (first leaf of Walk stage)

**How to validate**: Review against Walk design doc Phase 1 section

---

**Version**: v1
**Lifecycle Stage**: 🌱 Seed
**Status**: Ready to activate
**Owner**: Master Joel
**Last Updated**: 2026-01-03
