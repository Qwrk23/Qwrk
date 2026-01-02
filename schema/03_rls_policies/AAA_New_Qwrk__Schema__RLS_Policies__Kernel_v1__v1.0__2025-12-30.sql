-- =========================================================
-- Helper: map auth.uid() -> qxb_user.user_id
-- =========================================================
create or replace function public.qxb_current_user_id()
returns uuid
language sql
stable
as $$
  select u.user_id
  from public.qxb_user u
  where u.auth_user_id = auth.uid()
  limit 1
$$;

comment on function public.qxb_current_user_id is
  'Returns qxb_user.user_id for the current authenticated Supabase user (auth.uid()).';

-- =========================================================
-- qxb_user policies (self-only)
-- =========================================================
drop policy if exists qxb_user_select_self on public.qxb_user;
create policy qxb_user_select_self
on public.qxb_user
for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists qxb_user_update_self on public.qxb_user;
create policy qxb_user_update_self
on public.qxb_user
for update
to authenticated
using (auth_user_id = auth.uid())
with check (auth_user_id = auth.uid());

-- =========================================================
-- qxb_workspace_user policies (membership rows visible to member)
-- =========================================================
drop policy if exists qxb_workspace_user_select_member on public.qxb_workspace_user;
create policy qxb_workspace_user_select_member
on public.qxb_workspace_user
for select
to authenticated
using (
  exists (
    select 1
    from public.qxb_workspace_user wsu
    where wsu.workspace_id = qxb_workspace_user.workspace_id
      and wsu.user_id = public.qxb_current_user_id()
  )
);

-- allow a user to insert THEIR OWN membership row only when they are also the workspace creator/owner is not yet modeled here
-- (creation flow usually inserts owner membership via service role / admin channel)
-- keep inserts locked down for now
-- (we will open this intentionally later)

-- =========================================================
-- qxb_workspace policies (workspace visible to members)
-- =========================================================
drop policy if exists qxb_workspace_select_member on public.qxb_workspace;
create policy qxb_workspace_select_member
on public.qxb_workspace
for select
to authenticated
using (
  exists (
    select 1
    from public.qxb_workspace_user wsu
    where wsu.workspace_id = qxb_workspace.workspace_id
      and wsu.user_id = public.qxb_current_user_id()
  )
);

-- =========================================================
-- qxb_artifact policies
-- - default: workspace members can read
-- - journals: owner-private by default
-- =========================================================
drop policy if exists qxb_artifact_select_member on public.qxb_artifact;
create policy qxb_artifact_select_member
on public.qxb_artifact
for select
to authenticated
using (
  exists (
    select 1
    from public.qxb_workspace_user wsu
    where wsu.workspace_id = qxb_artifact.workspace_id
      and wsu.user_id = public.qxb_current_user_id()
  )
  and (
    qxb_artifact.artifact_type <> 'journal'
    or qxb_artifact.owner_user_id = public.qxb_current_user_id()
  )
);

drop policy if exists qxb_artifact_insert_owner on public.qxb_artifact;
create policy qxb_artifact_insert_owner
on public.qxb_artifact
for insert
to authenticated
with check (
  owner_user_id = public.qxb_current_user_id()
  and exists (
    select 1
    from public.qxb_workspace_user wsu
    where wsu.workspace_id = qxb_artifact.workspace_id
      and wsu.user_id = public.qxb_current_user_id()
  )
);

drop policy if exists qxb_artifact_update_owner_or_admin on public.qxb_artifact;
create policy qxb_artifact_update_owner_or_admin
on public.qxb_artifact
for update
to authenticated
using (
  qxb_artifact.owner_user_id = public.qxb_current_user_id()
  or exists (
    select 1
    from public.qxb_workspace_user wsu
    where wsu.workspace_id = qxb_artifact.workspace_id
      and wsu.user_id = public.qxb_current_user_id()
      and wsu.role in ('owner','admin')
  )
)
with check (
  qxb_artifact.owner_user_id = public.qxb_current_user_id()
  or exists (
    select 1
    from public.qxb_workspace_user wsu
    where wsu.workspace_id = qxb_artifact.workspace_id
      and wsu.user_id = public.qxb_current_user_id()
      and wsu.role in ('owner','admin')
  )
);

-- =========================================================
-- Type tables policies (delegate visibility to qxb_artifact)
-- =========================================================
-- PROJECT
drop policy if exists qxb_artifact_project_select_via_artifact on public.qxb_artifact_project;
create policy qxb_artifact_project_select_via_artifact
on public.qxb_artifact_project
for select
to authenticated
using (
  exists (
    select 1
    from public.qxb_artifact a
    where a.artifact_id = qxb_artifact_project.artifact_id
  )
);

drop policy if exists qxb_artifact_project_update_owner_or_admin on public.qxb_artifact_project;
create policy qxb_artifact_project_update_owner_or_admin
on public.qxb_artifact_project
for update
to authenticated
using (
  exists (
    select 1
    from public.qxb_artifact a
    where a.artifact_id = qxb_artifact_project.artifact_id
      and (
        a.owner_user_id = public.qxb_current_user_id()
        or exists (
          select 1
          from public.qxb_workspace_user wsu
          where wsu.workspace_id = a.workspace_id
            and wsu.user_id = public.qxb_current_user_id()
            and wsu.role in ('owner','admin')
        )
      )
  )
)
with check (
  exists (
    select 1
    from public.qxb_artifact a
    where a.artifact_id = qxb_artifact_project.artifact_id
      and (
        a.owner_user_id = public.qxb_current_user_id()
        or exists (
          select 1
          from public.qxb_workspace_user wsu
          where wsu.workspace_id = a.workspace_id
            and wsu.user_id = public.qxb_current_user_id()
            and wsu.role in ('owner','admin')
        )
      )
  )
);

-- SNAPSHOT (read via artifact; inserts allowed only to owner via artifact ownership)
drop policy if exists qxb_artifact_snapshot_select_via_artifact on public.qxb_artifact_snapshot;
create policy qxb_artifact_snapshot_select_via_artifact
on public.qxb_artifact_snapshot
for select
to authenticated
using (
  exists (select 1 from public.qxb_artifact a where a.artifact_id = qxb_artifact_snapshot.artifact_id)
);

drop policy if exists qxb_artifact_snapshot_insert_owner_via_artifact on public.qxb_artifact_snapshot;
create policy qxb_artifact_snapshot_insert_owner_via_artifact
on public.qxb_artifact_snapshot
for insert
to authenticated
with check (
  exists (
    select 1
    from public.qxb_artifact a
    where a.artifact_id = qxb_artifact_snapshot.artifact_id
      and a.owner_user_id = public.qxb_current_user_id()
  )
);

-- RESTART (read via artifact; inserts allowed only to owner via artifact ownership)
drop policy if exists qxb_artifact_restart_select_via_artifact on public.qxb_artifact_restart;
create policy qxb_artifact_restart_select_via_artifact
on public.qxb_artifact_restart
for select
to authenticated
using (
  exists (select 1 from public.qxb_artifact a where a.artifact_id = qxb_artifact_restart.artifact_id)
);

drop policy if exists qxb_artifact_restart_insert_owner_via_artifact on public.qxb_artifact_restart;
create policy qxb_artifact_restart_insert_owner_via_artifact
on public.qxb_artifact_restart
for insert
to authenticated
with check (
  exists (
    select 1
    from public.qxb_artifact a
    where a.artifact_id = qxb_artifact_restart.artifact_id
      and a.owner_user_id = public.qxb_current_user_id()
  )
);

-- JOURNAL (read/write owner-only; visibility already enforced on qxb_artifact)
drop policy if exists qxb_artifact_journal_select_owner_via_artifact on public.qxb_artifact_journal;
create policy qxb_artifact_journal_select_owner_via_artifact
on public.qxb_artifact_journal
for select
to authenticated
using (
  exists (
    select 1
    from public.qxb_artifact a
    where a.artifact_id = qxb_artifact_journal.artifact_id
      and a.owner_user_id = public.qxb_current_user_id()
  )
);

drop policy if exists qxb_artifact_journal_insert_owner_via_artifact on public.qxb_artifact_journal;
create policy qxb_artifact_journal_insert_owner_via_artifact
on public.qxb_artifact_journal
for insert
to authenticated
with check (
  exists (
    select 1
    from public.qxb_artifact a
    where a.artifact_id = qxb_artifact_journal.artifact_id
      and a.owner_user_id = public.qxb_current_user_id()
  )
);

drop policy if exists qxb_artifact_journal_update_owner_via_artifact on public.qxb_artifact_journal;
create policy qxb_artifact_journal_update_owner_via_artifact
on public.qxb_artifact_journal
for update
to authenticated
using (
  exists (
    select 1
    from public.qxb_artifact a
    where a.artifact_id = qxb_artifact_journal.artifact_id
      and a.owner_user_id = public.qxb_current_user_id()
  )
)
with check (
  exists (
    select 1
    from public.qxb_artifact a
    where a.artifact_id = qxb_artifact_journal.artifact_id
      and a.owner_user_id = public.qxb_current_user_id()
  )
);

-- EVENT LOG (read via workspace membership; insert via service/admin channel typically)
drop policy if exists qxb_artifact_event_select_member on public.qxb_artifact_event;
create policy qxb_artifact_event_select_member
on public.qxb_artifact_event
for select
to authenticated
using (
  exists (
    select 1
    from public.qxb_workspace_user wsu
    where wsu.workspace_id = qxb_artifact_event.workspace_id
      and wsu.user_id = public.qxb_current_user_id()
  )
);
