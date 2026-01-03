# Design — Onboarding Walk Stage: Enhanced MVP v1

**Stage**: 🟡 Walk (Enhanced MVP - Design Only)
**Purpose**: Define clean upgrade path from Crawl MVP once proven
**Date**: 2026-01-03
**Owner**: Master Joel
**Status**: Design Only (NOT approved for build)

---

## Overview

**Walk Stage** builds on the proven Crawl MVP by adding:
- Automated email sequences
- Better NDA versioning visibility
- Beta candidate flagging
- Migration from Google Sheets to Qwrk artifacts

**Critical Constraint**: Does NOT introduce OAuth, multi-user permissions, or workspace assignment yet. Those belong to Run stage.

---

## What Changes from Crawl → Walk

### 1. Email Automation

**Crawl**: Sends 2 emails (signer receipt + admin notification)

**Walk**:
- **Welcome sequence** (automated drip):
  - Day 0: Immediate confirmation + NDA receipt (existing)
  - Day 3: "What to expect" email (status update)
  - Day 7: "Beta preview" email (if flagged as candidate)
- **Admin digest** (daily or weekly):
  - Replaces individual admin notifications
  - Summarizes new signups in single email
  - Includes quick-action links

**Implementation**:
- New n8n workflow: `Qxb_Onboarding_Email_Sequences_v1`
- Triggered by: time-based (cron) or webhook from signup workflow
- Data source: Google Sheets or Qwrk artifacts

---

### 2. NDA Versioning UI

**Crawl**: NDA version hardcoded (`nda_v1_2026-01-02`), hash computed

**Walk**:
- **Version selector** in workflow configuration
  - Admin can switch NDA version without editing workflow code
  - Form dynamically loads NDA text from version config
- **Version audit trail**
  - Track which users signed which NDA version
  - Display NDA version in admin dashboard
- **Migration path** for version updates
  - Notify users who signed old version
  - Optional: re-acknowledge new version

**Implementation**:
- Store NDA versions in: Google Sheets "NDA Versions" tab OR Qwrk artifact (type: `snapshot`)
- Workflow reads NDA text from version store
- Hash computed dynamically based on selected version

---

### 3. Beta Candidate Flagging

**Crawl**: All signups equal; manual review required

**Walk**:
- **Automated scoring/tagging**:
  - Email domain scoring (e.g., `@bigcompany.com` = high priority)
  - Referral source tracking (URL parameter: `?source=partner`)
  - Company field analysis (keywords: "enterprise", "agency", etc.)
- **Visual indicators in admin dashboard**:
  - Flag: 🟢 High priority | 🟡 Medium | ⚪ Standard
  - Notes: Auto-populated based on scoring rules
- **Filter/sort capability**:
  - Admin can filter by priority
  - Export high-priority candidates for outreach

**Implementation**:
- Add `priority` field to Google Sheets (computed column)
- Workflow logic: score based on rules, set priority
- Admin dashboard: Google Sheets with conditional formatting OR custom UI

---

### 4. Data Migration: Sheets → Qwrk Artifacts

**Crawl**: Google Sheets is source of truth

**Walk**:
- **Dual-write** (transition phase):
  - Workflow writes to BOTH Google Sheets AND Qwrk artifacts
  - Google Sheets remains operational for continuity
  - Qwrk artifacts become queryable via Gateway
- **Artifact type**: `journal` (Person Intake entries)
  - Schema aligns with existing Google Sheets structure
  - Owner: Joel (system)
  - Workspace: "Qwrk Admin" workspace
- **Gradual migration**:
  - Phase 1: Write new signups to artifacts
  - Phase 2: Backfill existing Sheets rows as artifacts
  - Phase 3: Deprecate Sheets (make read-only)

**Implementation**:
- New workflow node: Call `artifact.create` (Gateway)
- Payload maps Google Sheets structure to artifact fields
- Success: continues to Sheets insert (for redundancy)
- Failure: logs error, still inserts to Sheets (no data loss)

---

### 5. Admin Dashboard Enhancement

**Crawl**: Google Sheets with manual review

**Walk** (Option A - Low-Lift):
- **Enhanced Google Sheets**:
  - Formulas for scoring/priority
  - Conditional formatting for visual indicators
  - Filters and pivot tables for analysis
  - Chart: signups over time

**Walk** (Option B - Custom UI):
- **Simple web dashboard** (n8n Webhook + HTML):
  - Read from Google Sheets or query Qwrk artifacts
  - Display: table with filters, search, priority badges
  - Actions: Flag for beta, add notes, export CSV
  - Built with: n8n Webhook node returning HTML page

**Recommendation**: Start with Option A (enhanced Sheets), build Option B if needed.

---

## New Workflows (Walk Stage)

### Workflow 1: Email Sequences

**Name**: `Qxb_Onboarding_Email_Sequences_v1`

**Trigger**:
- Cron schedule (daily at 9am UTC)
- OR webhook from signup workflow (immediate trigger)

**Logic**:
1. Query Google Sheets for recent signups
2. Check `email_sent_day_3` flag (new column)
3. Send Day 3 email to users who signed up 3 days ago
4. Update flag in Sheets

**Email Templates**:
- Day 3: "What to Expect from Qwrk"
- Day 7: "Beta Preview" (conditional on priority flag)

**Deliverables**:
- n8n JSON workflow
- Email templates (Markdown or HTML)
- Documentation

---

### Workflow 2: Admin Digest

**Name**: `Qxb_Onboarding_Admin_Digest_v1`

**Trigger**: Cron schedule (daily or weekly)

**Logic**:
1. Query Google Sheets for signups since last digest
2. Aggregate:
   - Total new signups
   - High-priority candidates
   - Duplicate attempts
3. Send single email to admin with summary table

**Deliverables**:
- n8n JSON workflow
- Email template (HTML table)
- Documentation

---

### Workflow 3: Dual-Write to Artifacts (Optional)

**Name**: `Qxb_Onboarding_Signup_NDA_Clickwrap_v2`

**Changes from v1**:
- Add node: Call `artifact.create` for journal artifact
- Payload: Map form fields to artifact schema
- Error handling: Log but don't block Sheets insert

**Artifact Schema** (journal type):
```json
{
  "artifact_type": "journal",
  "title": "Person Intake: {email}",
  "extension": {
    "entry_text": "NDA signup from {email}",
    "payload": {
      "email": "...",
      "full_name": "...",
      "company": "...",
      "nda_version": "...",
      "nda_text_hash": "...",
      "status": "...",
      "priority": "...",
      "created_at_utc": "..."
    }
  }
}
```

**Deliverables**:
- Updated workflow (v2)
- Migration script for backfill (SQL or n8n)
- Documentation

---

## Schema Changes

### Google Sheets (New Columns)

Add to "Qwrk NDA Signups" sheet:

| Column | Type | Purpose |
|--------|------|---------|
| `priority` | Text | Auto-computed: high \| medium \| standard |
| `email_sent_day_3` | Boolean | Tracks Day 3 email sent |
| `email_sent_day_7` | Boolean | Tracks Day 7 email sent |
| `beta_candidate` | Boolean | Manually flagged for beta access |
| `last_contacted` | Date | Last email sent (for digest logic) |

**Migration**: Add columns to existing sheet; backfill with defaults.

---

### Qwrk Artifacts (New, if dual-write enabled)

**Artifact Type**: `journal`
**Owner**: Joel (system user)
**Workspace**: "Qwrk Admin" workspace

**Fields** (via `extension.payload`):
- All fields from Google Sheets schema
- Plus: `artifact_id` for future reference

**RLS**: Owner-only (Joel can read/write; no public access)

---

## Implementation Phases (Walk)

### Phase 1: Email Automation

**Duration**: 1-2 weeks (design + build + test)

**Deliverables**:
1. Email sequences workflow
2. Admin digest workflow
3. Test both with Crawl data
4. Document runbook for activation

---

### Phase 2: NDA Versioning

**Duration**: 1 week (design + build)

**Deliverables**:
1. NDA version store (Sheets tab or artifact)
2. Update signup workflow to read from version store
3. Test version switching
4. Document version management process

---

### Phase 3: Beta Candidate Flagging

**Duration**: 1 week (logic + UI)

**Deliverables**:
1. Scoring logic in signup workflow
2. Priority field in Google Sheets
3. Conditional formatting for visual indicators
4. Document scoring rules

---

### Phase 4: Dual-Write to Artifacts (Optional)

**Duration**: 2 weeks (Gateway integration + testing)

**Deliverables**:
1. Updated signup workflow (v2)
2. Test artifact creation
3. Backfill script for existing signups
4. Migration runbook

**Prerequisite**: Gateway v1.1 with `artifact.create` must be stable and tested.

---

## Success Criteria (Walk)

Walk stage is **COMPLETE** when:
1. ✅ Email sequences send automatically (Day 3, Day 7)
2. ✅ Admin digest replaces individual notifications
3. ✅ NDA version can be switched without code edits
4. ✅ Beta candidates are auto-flagged and visible in dashboard
5. ✅ (Optional) Signups also saved as Qwrk artifacts

**Not required for Walk**:
- OAuth / user accounts
- Workspace assignment
- Multi-user admin access
- Automated beta access granting

Those belong to **Run stage**.

---

## Risks & Mitigations

### Risk 1: Email Deliverability

**Risk**: Automated sequences flagged as spam

**Mitigation**:
- Use reputable SMTP provider (e.g., SendGrid, Mailgun)
- Include unsubscribe link
- Monitor bounce rates
- Start with small batch (test group)

---

### Risk 2: Scoring Logic Bias

**Risk**: Automated scoring excludes valid candidates

**Mitigation**:
- Scoring is advisory only (not blocking)
- Admin can manually override priority
- Document scoring rules transparently
- Review and adjust rules based on feedback

---

### Risk 3: Dual-Write Complexity

**Risk**: Artifacts and Sheets fall out of sync

**Mitigation**:
- Sheets remains authoritative during transition
- Artifacts are "best-effort" (failure doesn't block signup)
- Backfill script reconciles discrepancies
- Clear cutover plan to deprecate Sheets

---

## References

**Crawl Runbook**: `AAA_New_Qwrk/Runbooks/Runbook__Activate_MVP_Signup__Crawl_Stage__v1.md`
**Canonical Restart**: `a4b0bfd5-147a-4b5e-b43b-e3f220f4f681`
**Gateway Docs**: `new-qwrk-kernel/workflows/README.md`

---

**Version**: v1 (Design Only)
**Status**: Not approved for build
**Last Updated**: 2026-01-03
