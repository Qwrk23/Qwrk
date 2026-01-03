# Design — Onboarding Run Stage: Beta-Ready v1

**Stage**: 🟢 Run (Beta-Ready - Design Only)
**Purpose**: Full automation from signup to beta access
**Date**: 2026-01-03
**Owner**: Master Joel
**Status**: Design Only (NOT approved for build)

---

## Overview

**Run Stage** completes the onboarding journey by adding:
- OAuth user account creation
- Automatic workspace assignment
- Automated beta access granting
- Integration with Qwrk Gateway (user/workspace provisioning)
- Full self-service signup-to-access flow

**Critical Milestone**: At Run stage, signups can go from form submission to active Qwrk access without manual intervention.

---

## What Changes from Walk → Run

### 1. OAuth User Account Creation

**Walk**: Signups logged only; no user accounts created

**Run**:
- **Supabase Auth integration**:
  - Workflow calls Supabase Auth API to create user
  - User receives invitation email with password setup link
  - OAuth provider options (future): Google SSO, GitHub
- **qxb_user mapping**:
  - After Auth user created, insert into `qxb_user` table
  - Map `auth.uid()` to `qxb_user.user_id`
  - Populate profile fields from signup form
- **Email verification**:
  - Supabase sends verification email
  - User must verify before access granted

**Implementation**:
- New workflow: `Qxb_Onboarding_User_Provision_v1`
- Triggered by: signup workflow (after beta candidate approval)
- Calls: Supabase Auth API + Gateway user endpoint
- Error handling: log failures, notify admin, retry logic

---

### 2. Workspace Assignment

**Walk**: No workspace association

**Run**:
- **Workspace creation** (for owners):
  - High-priority signups flagged as "potential workspace owner"
  - Workflow creates new workspace via Gateway
  - User assigned as workspace owner
- **Workspace membership** (for members):
  - Standard signups assigned to "Beta Cohort" workspace
  - User assigned as workspace member (read-only)
  - Admin can later transfer to their own workspace
- **World assignment**:
  - All beta users assigned to "Beta World" (world_slug: `beta`)
  - System world membership for SELECT users only (manual)

**Implementation**:
- Gateway endpoints required:
  - `workspace.create` (creates workspace + assigns owner)
  - `workspace.add_member` (adds user to existing workspace)
  - `world.add_member` (adds user to world)
- Workflow logic: Score-based routing (high-priority → owner, standard → member)

---

### 3. Automated Beta Access Granting

**Walk**: Manual review for beta access

**Run**:
- **Auto-approval logic**:
  - High-priority signups: auto-approved
  - Medium-priority: manual approval queue
  - Standard: waitlist (notified when capacity available)
- **Access provisioning sequence**:
  1. Create Supabase Auth user
  2. Insert into `qxb_user`
  3. Create or assign workspace
  4. Add to Beta World
  5. Send welcome email with access instructions
- **Waitlist management**:
  - Standard signups added to waitlist
  - Admin dashboard: approve/reject from waitlist
  - Automated batch processing (e.g., approve top 10 weekly)

**Implementation**:
- New workflow: `Qxb_Onboarding_Access_Grant_v1`
- Admin dashboard: Waitlist approval UI (n8n Webhook + HTML)
- Email sequences: Approval notification, waitlist notification

---

### 4. Integration with Qwrk Gateway

**Walk**: Optional dual-write to artifacts

**Run**:
- **Gateway-first architecture**:
  - All user/workspace operations via Gateway
  - Google Sheets becomes read-only audit log
  - Artifacts as source of truth
- **New Gateway endpoints** (required):
  - `user.create` (provision user in qxb_user)
  - `workspace.create` (provision workspace)
  - `workspace.add_member` (assign user to workspace)
  - `world.add_member` (assign user to world)
- **Error handling**:
  - Transactional rollback on failure
  - Retry logic with exponential backoff
  - Admin notification on critical failures

**Implementation**:
- Gateway v2 endpoints (new workflows)
- Supabase RLS policies verified for user/workspace provisioning
- Test plan for end-to-end provisioning flow

---

### 5. Admin Dashboard (Full UI)

**Walk**: Enhanced Google Sheets or basic n8n HTML

**Run**:
- **Full admin web app** (n8n or standalone):
  - User management: view all signups, filter by status/priority
  - Approval queue: approve/reject beta candidates
  - Workspace management: create, assign, transfer
  - Waitlist management: batch approve, notify
  - Analytics: signups over time, conversion funnel
- **Actions**:
  - Approve beta access (triggers provisioning workflow)
  - Flag for priority review
  - Add notes / tags
  - Export data (CSV, JSON)
- **Built with**:
  - Option A: n8n Webhook + HTML/CSS/JS (simple)
  - Option B: Separate web app (React + Supabase client)
  - Option C: Retool/Budibase low-code admin panel

**Recommendation**: Start with Option A (n8n Webhook), migrate to B/C if needed.

---

## New Workflows (Run Stage)

### Workflow 1: User Provisioning

**Name**: `Qxb_Onboarding_User_Provision_v1`

**Trigger**: Webhook from signup workflow (after beta approval)

**Logic**:
1. Call Supabase Auth API: create user
2. Capture `auth.uid()`
3. Call Gateway `user.create`: insert into `qxb_user`
4. Send email verification
5. Update signup record with `user_id`

**Deliverables**:
- n8n JSON workflow
- Error handling nodes (retry logic)
- Documentation

---

### Workflow 2: Workspace Assignment

**Name**: `Qxb_Onboarding_Workspace_Assign_v1`

**Trigger**: Follows user provisioning (chained)

**Logic**:
1. Check priority flag (high → owner, standard → member)
2. **IF owner**:
   - Call Gateway `workspace.create`
   - Assign user as owner
3. **IF member**:
   - Call Gateway `workspace.add_member` (Beta Cohort workspace)
4. Call Gateway `world.add_member` (Beta World)
5. Update signup record with `workspace_id`

**Deliverables**:
- n8n JSON workflow
- Test plan (owner vs member paths)
- Documentation

---

### Workflow 3: Access Grant Orchestration

**Name**: `Qxb_Onboarding_Access_Grant_v1`

**Trigger**:
- Webhook from admin dashboard (manual approval)
- OR cron schedule (auto-approval for high-priority)

**Logic**:
1. Query signups with `status = pending_approval`
2. Filter by priority (auto-approve high, queue medium)
3. For each approved:
   - Call User Provisioning workflow
   - Call Workspace Assignment workflow
   - Send welcome email
   - Update status to `access_granted`
4. For waitlist:
   - Send waitlist notification email

**Deliverables**:
- n8n JSON workflow
- Email templates (approval, waitlist, welcome)
- Documentation

---

### Workflow 4: Admin Dashboard Backend

**Name**: `Qxb_Onboarding_Admin_Dashboard_v1`

**Trigger**: Webhook (URL for admin dashboard)

**Logic**:
1. Authenticate admin (via token or Supabase auth)
2. Query signups from Google Sheets or Gateway
3. Return HTML page with:
   - Table: all signups with filters
   - Actions: approve, reject, add notes
   - Charts: signups over time, funnel
4. POST actions trigger Access Grant workflow

**Deliverables**:
- n8n JSON workflow
- HTML/CSS/JS for dashboard UI
- Documentation

---

## Schema Changes (Run Stage)

### Google Sheets (New Columns)

Add to "Qwrk NDA Signups" sheet:

| Column | Type | Purpose |
|--------|------|---------|
| `user_id` | UUID | Supabase auth user ID (after provisioning) |
| `qxb_user_id` | UUID | qxb_user.user_id (after provisioning) |
| `workspace_id` | UUID | Assigned workspace ID |
| `world_id` | UUID | Assigned world ID (Beta World) |
| `access_status` | Text | pending_approval \| access_granted \| waitlisted \| rejected |
| `approved_at` | Timestamp | When beta access was granted |
| `approved_by` | Text | Admin who approved (manual) or "AUTO" |

**Migration**: Add columns, backfill with `NULL` for existing signups.

---

### Qwrk Database (New Tables)

**No new tables required** (use existing):
- `qxb_user` (provisioned via Gateway)
- `qxb_workspace` (provisioned via Gateway)
- `qxb_workspace_user` (membership via Gateway)
- `qxb_world_user` (world membership via Gateway)

**Prerequisite**: Gateway endpoints must exist for user/workspace/world provisioning.

---

## Implementation Phases (Run)

### Phase 1: Gateway Provisioning Endpoints

**Duration**: 2-3 weeks (design + build + test)

**Deliverables**:
1. `user.create` endpoint (Gateway workflow)
2. `workspace.create` endpoint (Gateway workflow)
3. `workspace.add_member` endpoint (Gateway workflow)
4. `world.add_member` endpoint (Gateway workflow)
5. Test plan for all endpoints
6. RLS policy validation

**Prerequisite**: Qwrk World Separation PRD must be implemented first.

---

### Phase 2: User Provisioning Workflow

**Duration**: 1-2 weeks (build + test)

**Deliverables**:
1. User provisioning workflow (Supabase Auth + Gateway)
2. Error handling and retry logic
3. Email templates (verification, welcome)
4. Test with manual trigger

---

### Phase 3: Workspace Assignment Workflow

**Duration**: 1 week (build + test)

**Deliverables**:
1. Workspace assignment workflow (owner vs member logic)
2. Test both paths (owner, member)
3. Documentation

---

### Phase 4: Access Grant Orchestration

**Duration**: 1-2 weeks (build + test)

**Deliverables**:
1. Access grant workflow (chained provisioning)
2. Auto-approval logic (priority-based)
3. Waitlist management
4. Test end-to-end flow

---

### Phase 5: Admin Dashboard

**Duration**: 2 weeks (UI build + integration)

**Deliverables**:
1. Admin dashboard workflow (Webhook backend)
2. HTML/CSS/JS frontend
3. Approval action integration
4. Test with live data

---

## Success Criteria (Run)

Run stage is **COMPLETE** when:
1. ✅ High-priority signups automatically provisioned (user + workspace + world)
2. ✅ Standard signups added to waitlist with notifications
3. ✅ Admin can approve/reject from dashboard
4. ✅ User receives welcome email with access instructions
5. ✅ User can log in to Qwrk and access assigned workspace
6. ✅ Google Sheets audit log reflects all provisioning actions

**NOT required for Run**:
- Multi-workspace access for users (belongs to future)
- Workspace transfer automation (manual for now)
- Advanced analytics / BI dashboards
- SSO providers beyond email/password

Those belong to **Post-Beta / Production stage**.

---

## Out of Scope (Run Stage)

**Explicitly NOT in Run**:
1. **Payment / billing**: Beta is free; billing comes later
2. **Advanced workspace features**: Templates, cloning, archiving
3. **User self-service workspace creation**: Admin-gated only
4. **Custom domain mapping**: Not needed for beta
5. **Advanced RLS**: Use existing Kernel v1 RLS policies only
6. **Multi-world user access**: Beta users in Beta World only
7. **SSO providers**: Google/GitHub OAuth deferred to production
8. **Mobile app integration**: Web-only for beta

---

## Risks & Mitigations

### Risk 1: Provisioning Failures

**Risk**: User provisioning fails mid-process (partial state)

**Mitigation**:
- Transactional workflow design (rollback on error)
- Idempotency keys for retry safety
- Admin notification on critical failures
- Manual recovery runbook

---

### Risk 2: Gateway Endpoint Delays

**Risk**: Gateway endpoints not ready when Run stage starts

**Mitigation**:
- Prioritize Gateway provisioning endpoints in roadmap
- Parallel development with Run workflows
- Mock endpoints for testing (stub responses)
- Clear dependency mapping

---

### Risk 3: Spam / Abuse

**Risk**: Automated signup abuse (fake accounts, spam)

**Mitigation**:
- Add CAPTCHA to signup form (hCaptcha or reCAPTCHA)
- Rate limiting on form submissions
- Email verification required before access
- Admin review queue for medium-priority signups

---

### Risk 4: Supabase Auth Quota

**Risk**: Exceed Supabase free tier auth limits

**Mitigation**:
- Monitor auth user count
- Set hard cap on auto-approvals (e.g., 50/week)
- Upgrade to paid tier when needed
- Waitlist throttles growth

---

## Architecture Notes (Run Stage)

### Gateway Integration Points

**Required Gateway Endpoints**:
1. `user.create` (maps to `qxb_user` insert)
2. `workspace.create` (creates workspace + owner membership)
3. `workspace.add_member` (adds user to workspace)
4. `world.add_member` (adds user to world)

**Response Format** (all endpoints):
```json
{
  "ok": true,
  "resource": {
    "user_id": "...",
    "workspace_id": "...",
    ...
  }
}
```

**Error Format**:
```json
{
  "ok": false,
  "error": {
    "code": "PROVISIONING_FAILED",
    "message": "...",
    "details": { ... }
  }
}
```

---

### Workflow Chaining Strategy

**Pattern**: Event-driven workflow chaining
1. Signup workflow → emits `beta_approved` event
2. User provisioning workflow → listens for event → provisions user
3. Workspace assignment workflow → listens for `user_provisioned` event → assigns workspace
4. Access grant workflow → listens for `workspace_assigned` event → sends welcome email

**Alternative**: Synchronous chaining (one workflow calls next via webhook)

**Recommendation**: Start with synchronous chaining (simpler), migrate to event-driven if needed.

---

### Data Flow (Run Stage)

```
Form Submission
  ↓
Signup Workflow (v2)
  ├─→ Validate NDA
  ├─→ Dedupe check
  ├─→ Score priority
  ├─→ Save to Sheets + Artifacts
  ├─→ IF high-priority:
  │     ↓
  │   Trigger User Provisioning
  │     ↓
  │   Supabase Auth (create user)
  │     ↓
  │   Gateway user.create
  │     ↓
  │   Trigger Workspace Assignment
  │     ↓
  │   Gateway workspace.create OR workspace.add_member
  │     ↓
  │   Gateway world.add_member
  │     ↓
  │   Send Welcome Email
  │     ↓
  │   Update Sheets (access_status = access_granted)
  │
  ├─→ IF medium-priority:
  │     ↓
  │   Add to approval queue
  │     ↓
  │   Admin Dashboard (manual approval)
  │     ↓
  │   (same flow as high-priority)
  │
  └─→ IF standard:
        ↓
      Add to waitlist
        ↓
      Send waitlist email
```

---

## References

**Walk Stage Design**: `Design__Onboarding_Walk_Stage__Enhanced_MVP__v1.md`
**Crawl Runbook**: `Runbook__Activate_MVP_Signup__Crawl_Stage__v1.md`
**Gateway Docs**: `new-qwrk-kernel/workflows/README.md`
**Qwrk World Separation PRD**: `PRD__Qwrk_World_Separation__Multi_World_Isolation__v1.md`

---

**Version**: v1 (Design Only)
**Status**: Not approved for build
**Last Updated**: 2026-01-03
