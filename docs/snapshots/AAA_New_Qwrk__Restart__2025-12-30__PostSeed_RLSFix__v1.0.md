# RESTART — New Qwrk Kernel v1 (Post-Seed, RLS Recursion Fix)

## Where we are
- Supabase project: new-qwrk-kernel
- Project ref: npymhacpmxdnkdgzxll
- Status: Kernel v1 schema executed (BUNDLE OK) + RLS applied (RLS OK) + KGB pack passed (KGB OK)
- Minimal seed + RLS read-path sanity check: PASS

## IDs (Known-Good)
- auth_user_id: 7097c16c-ed88-4e49-983f-1de80e5cfcea
- qxb_user.user_id: c52c7a57-74ad-433d-a07c-4dcac1778672
- workspace_id: be0d3a48-c764-44f9-90c8-e846d9dbbd0a
- workspace name: Master Joel Workspace
- role: owner

## RLS Fix (IMPORTANT)
Issue:
- Infinite recursion detected in policy for relation qxb_workspace_user
Fix applied:
- Dropped policy: qxb_workspace_user_select_member
- Added policy: qxb_workspace_user_select_self (self-only select)
- Updated workspace policy: qxb_workspace_select_via_self_membership

## Next step (start here next session)
1) Produce and save a versioned RLS policy patch artifact (v1.1) that matches the live DB policies.
2) Re-run a short KGB+ sanity (workspace + membership visible as authenticated).
3) Proceed to first artifact creation test (project artifact + qxb_artifact_project), then event log write.
