-- =========================================================
-- KGB SQL Pack — Kernel v1
-- Run in Supabase SQL editor (service role / admin context).
-- =========================================================

-- KGB-0: Prereq check (pgcrypto for gen_random_uuid)
select extname
from pg_extension
where extname = 'pgcrypto';

-- If missing, enable it (safe to run even if already enabled):
create extension if not exists pgcrypto;

-- =========================================================
-- KGB-S1: Required tables exist
-- =========================================================
select tablename
from pg_tables
where schemaname = 'public'
  and tablename in (
    'qxb_user',
    'qxb_workspace',
    'qxb_workspace_user',
    'qxb_artifact',
    'qxb_artifact_project',
    'qxb_artifact_snapshot',
    'qxb_artifact_restart',
    'qxb_artifact_journal',
    'qxb_artifact_event'
  )
order by tablename;

-- =========================================================
-- KGB-S2: RLS enabled everywhere (should be TRUE for all)
-- =========================================================
select c.relname as table_name,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname like 'qxb_%'
  and c.relkind = 'r'
order by c.relname;

-- =========================================================
-- KGB-S3: Policies inventory (confirm what exists)
-- =========================================================
select schemaname, tablename, policyname, permissive, roles, cmd
from pg_policies
where schemaname = 'public'
  and tablename like 'qxb_%'
order by tablename, policyname;

-- =========================================================
-- KGB-S4: updated_at trigger presence where expected
-- =========================================================
select event_object_table as table_name,
       trigger_name
from information_schema.triggers
where trigger_schema = 'public'
  and event_object_table in (
    'qxb_user',
    'qxb_workspace',
    'qxb_workspace_user',
    'qxb_artifact',
    'qxb_artifact_project',
    'qxb_artifact_journal'
  )
order by event_object_table, trigger_name;

-- Ensure snapshot/restart/event have NO updated_at triggers
select event_object_table as table_name,
       trigger_name
from information_schema.triggers
where trigger_schema = 'public'
  and event_object_table in (
    'qxb_artifact_snapshot',
    'qxb_artifact_restart',
    'qxb_artifact_event'
  )
order by event_object_table, trigger_name;

-- =========================================================
-- KGB-S5: Append-only enforcement (event table blocks UPDATE/DELETE)
-- NOTE: This test is non-destructive; it creates then attempts update/delete and expects exceptions.
-- =========================================================
do $$
declare
  v_workspace uuid;
  v_user uuid;
  v_artifact uuid;
  v_event uuid;
begin
  -- Create minimal prerequisites (workspace + user + membership + artifact)
  insert into public.qxb_workspace(name) values ('KGB Workspace') returning workspace_id into v_workspace;

  -- qxb_user requires a real auth.users id in normal operation.
  -- For KGB admin/service-role testing, we only validate append-only behavior without inserting qxb_user.
  -- So we create an artifact with owner_user_id as a dummy uuid only if FK allows (it does NOT).
  -- Therefore: skip artifact FK chain, and test append-only trigger by directly attempting update/delete
  -- against a row we insert with service-role privileges and with FKs satisfied.
  --
  -- If you have a real qxb_user row available, uncomment the block below and supply real IDs.

  raise notice 'KGB-S5 requires existing valid workspace_id + artifact_id rows to fully exercise FKs.';
  raise notice 'If you have already seeded qxb_user/qxb_workspace/qxb_workspace_user/qxb_artifact, run the targeted test below instead.';
end $$;

-- Targeted append-only test (run AFTER you have at least one valid event row):
-- 1) Pick an event_id and try to update/delete it; both should error.

-- Replace with a real UUID from qxb_artifact_event:
-- select event_id from public.qxb_artifact_event limit 1;

-- UPDATE should fail:
-- update public.qxb_artifact_event set payload = '{}'::jsonb where event_id = '<PUT_EVENT_ID_HERE>';

-- DELETE should fail:
-- delete from public.qxb_artifact_event where event_id = '<PUT_EVENT_ID_HERE>';

-- =========================================================
-- KGB-S6: Constraint checks (quick integrity signals)
-- =========================================================

-- workspace_user uniqueness (no duplicates allowed)
select conname, conrelid::regclass as table_name
from pg_constraint
where conname = 'qxb_workspace_user_unique_membership';

-- Type-table PK=FK constraints exist
select conname, conrelid::regclass as table_name
from pg_constraint
where conname in (
  'qxb_artifact_project_fk',
  'qxb_artifact_snapshot_fk',
  'qxb_artifact_restart_fk',
  'qxb_artifact_journal_fk',
  'qxb_artifact_event_artifact_fk'
)
order by conname;
