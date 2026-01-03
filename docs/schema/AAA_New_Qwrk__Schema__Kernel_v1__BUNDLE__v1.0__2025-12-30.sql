-- =========================================================
-- New Qwrk (Qwrk V2) — Kernel v1 Schema Bundle (STAGED)
-- Safe execution order + shared functions consolidated
-- =========================================================

-- 0) Prereq (uuid generator)
create extension if not exists pgcrypto;

-- =========================================================
-- Shared functions
-- =========================================================

-- updated_at trigger helper
create or replace function public.qxb_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.qxb_set_updated_at is
  'Shared updated_at trigger setter for Kernel tables.';

-- append-only guard (event log)
create or replace function public.qxb_block_update_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Updates/deletes are not allowed on append-only tables';
end;
$$;

comment on function public.qxb_block_update_delete is
  'Blocks UPDATE/DELETE on append-only tables (Kernel event log).';

-- =========================================================
-- 1) public.qxb_user
-- =========================================================
create table if not exists public.qxb_user (
  user_id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique,
  status text not null default 'active' check (status in ('active','disabled')),
  display_name text null,
  email text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint qxb_user_auth_user_fk
    foreign key (auth_user_id) references auth.users (id)
);

comment on table public.qxb_user is
  'Kernel v1 identity table. Maps Supabase auth.users to Qwrk user identity. RLS is enabled; policies added later (deny-by-default).';

alter table public.qxb_user enable row level security;

drop trigger if exists qxb_user_set_updated_at on public.qxb_user;
create trigger qxb_user_set_updated_at
before update on public.qxb_user
for each row
execute function public.qxb_set_updated_at();

-- =========================================================
-- 2) public.qxb_workspace
-- =========================================================
create table if not exists public.qxb_workspace (
  workspace_id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.qxb_workspace is
  'Kernel v1 workspace table. System is workspace-first; every artifact requires workspace_id. RLS enabled; policies added later (deny-by-default).';

alter table public.qxb_workspace enable row level security;

drop trigger if exists qxb_workspace_set_updated_at on public.qxb_workspace;
create trigger qxb_workspace_set_updated_at
before update on public.qxb_workspace
for each row
execute function public.qxb_set_updated_at();

-- =========================================================
-- 3) public.qxb_workspace_user
-- =========================================================
create table if not exists public.qxb_workspace_user (
  workspace_user_id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null,
  user_id uuid not null,
  role text not null default 'member' check (role in ('owner','admin','member')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint qxb_workspace_user_workspace_fk
    foreign key (workspace_id) references public.qxb_workspace (workspace_id),
  constraint qxb_workspace_user_user_fk
    foreign key (user_id) references public.qxb_user (user_id),
  constraint qxb_workspace_user_unique_membership
    unique (workspace_id, user_id)
);

comment on table public.qxb_workspace_user is
  'Kernel v1 workspace membership table. Maps users to workspaces with role-based access. RLS enabled; policies added later (deny-by-default).';

alter table public.qxb_workspace_user enable row level security;

drop trigger if exists qxb_workspace_user_set_updated_at on public.qxb_workspace_user;
create trigger qxb_workspace_user_set_updated_at
before update on public.qxb_workspace_user
for each row
execute function public.qxb_set_updated_at();

-- =========================================================
-- 4) public.qxb_artifact (canonical spine)
-- =========================================================
create table if not exists public.qxb_artifact (
  artifact_id uuid primary key default gen_random_uuid(),

  workspace_id uuid not null,
  owner_user_id uuid not null,

  artifact_type text not null check (artifact_type in ('project','snapshot','restart','journal')),

  title text not null,
  summary text null,

  priority int null check (priority between 1 and 5),

  lifecycle_status text null,

  tags jsonb null,
  content jsonb null,

  parent_artifact_id uuid null,

  version int not null default 1,

  deleted_at timestamptz null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint qxb_artifact_workspace_fk
    foreign key (workspace_id) references public.qxb_workspace (workspace_id),

  constraint qxb_artifact_owner_user_fk
    foreign key (owner_user_id) references public.qxb_user (user_id),

  constraint qxb_artifact_parent_fk
    foreign key (parent_artifact_id) references public.qxb_artifact (artifact_id)
);

comment on table public.qxb_artifact is
  'Kernel v1 canonical spine. All record types spawn from this table and extend via PK=FK class-table inheritance. RLS enabled; policies added later (deny-by-default).';

alter table public.qxb_artifact enable row level security;

drop trigger if exists qxb_artifact_set_updated_at on public.qxb_artifact;
create trigger qxb_artifact_set_updated_at
before update on public.qxb_artifact
for each row
execute function public.qxb_set_updated_at();

-- =========================================================
-- 5) public.qxb_artifact_project
-- =========================================================
create table if not exists public.qxb_artifact_project (
  artifact_id uuid primary key,

  lifecycle_stage text not null
    check (lifecycle_stage in ('seed','sapling','tree','retired')),

  operational_state text not null default 'active'
    check (operational_state in ('active','paused','blocked','waiting')),

  state_reason text null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint qxb_artifact_project_fk
    foreign key (artifact_id)
    references public.qxb_artifact (artifact_id)
    on delete cascade
);

comment on table public.qxb_artifact_project is
  'Project type table extending qxb_artifact. Enforces lifecycle + operational state. Transitions enforced at Gateway layer. RLS enabled; policies added later (deny-by-default).';

alter table public.qxb_artifact_project enable row level security;

drop trigger if exists qxb_artifact_project_set_updated_at on public.qxb_artifact_project;
create trigger qxb_artifact_project_set_updated_at
before update on public.qxb_artifact_project
for each row
execute function public.qxb_set_updated_at();

-- =========================================================
-- 6) public.qxb_artifact_snapshot (immutable payload)
-- =========================================================
create table if not exists public.qxb_artifact_snapshot (
  artifact_id uuid primary key,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  constraint qxb_artifact_snapshot_fk
    foreign key (artifact_id)
    references public.qxb_artifact (artifact_id)
    on delete cascade
);

comment on table public.qxb_artifact_snapshot is
  'Snapshot type table extending qxb_artifact. Immutable lifecycle-only snapshot payload stored inline as jsonb. RLS enabled; policies added later (deny-by-default).';

alter table public.qxb_artifact_snapshot enable row level security;

-- =========================================================
-- 7) public.qxb_artifact_restart (immutable payload)
-- =========================================================
create table if not exists public.qxb_artifact_restart (
  artifact_id uuid primary key,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  constraint qxb_artifact_restart_fk
    foreign key (artifact_id)
    references public.qxb_artifact (artifact_id)
    on delete cascade
);

comment on table public.qxb_artifact_restart is
  'Restart type table extending qxb_artifact. Manual, ad-hoc, immutable payload stored inline as jsonb. RLS enabled; policies added later (deny-by-default).';

alter table public.qxb_artifact_restart enable row level security;

-- =========================================================
-- 8) public.qxb_artifact_journal (owner-private by default via RLS policy later)
-- =========================================================
create table if not exists public.qxb_artifact_journal (
  artifact_id uuid primary key,

  entry_text text null,
  payload jsonb null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint qxb_artifact_journal_fk
    foreign key (artifact_id)
    references public.qxb_artifact (artifact_id)
    on delete cascade
);

comment on table public.qxb_artifact_journal is
  'Journal type table extending qxb_artifact. Owner-private by default (policy later). RLS enabled; policies added later (deny-by-default).';

alter table public.qxb_artifact_journal enable row level security;

drop trigger if exists qxb_artifact_journal_set_updated_at on public.qxb_artifact_journal;
create trigger qxb_artifact_journal_set_updated_at
before update on public.qxb_artifact_journal
for each row
execute function public.qxb_set_updated_at();

-- =========================================================
-- 9) public.qxb_artifact_event (append-only event log)
-- =========================================================
create table if not exists public.qxb_artifact_event (
  event_id uuid primary key default gen_random_uuid(),

  workspace_id uuid not null,
  artifact_id uuid not null,

  actor_user_id uuid null,

  event_type text not null,
  event_ts timestamptz not null default now(),

  payload jsonb null,

  created_at timestamptz not null default now(),

  constraint qxb_artifact_event_workspace_fk
    foreign key (workspace_id) references public.qxb_workspace (workspace_id),

  constraint qxb_artifact_event_artifact_fk
    foreign key (artifact_id) references public.qxb_artifact (artifact_id)
    on delete cascade,

  constraint qxb_artifact_event_actor_fk
    foreign key (actor_user_id) references public.qxb_user (user_id)
);

comment on table public.qxb_artifact_event is
  'Append-only event log for artifacts (explainability/audit). RLS enabled; policies added later (deny-by-default).';

alter table public.qxb_artifact_event enable row level security;

drop trigger if exists qxb_artifact_event_block_update on public.qxb_artifact_event;
create trigger qxb_artifact_event_block_update
before update on public.qxb_artifact_event
for each row
execute function public.qxb_block_update_delete();

drop trigger if exists qxb_artifact_event_block_delete on public.qxb_artifact_event;
create trigger qxb_artifact_event_block_delete
before delete on public.qxb_artifact_event
for each row
execute function public.qxb_block_update_delete();
