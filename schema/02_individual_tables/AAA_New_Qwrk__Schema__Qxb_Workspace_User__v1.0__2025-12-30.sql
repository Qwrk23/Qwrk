-- =========================================================
-- public.qxb_workspace_user
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

comment on column public.qxb_workspace_user.workspace_user_id is
  'Workspace membership identifier (PK).';
comment on column public.qxb_workspace_user.workspace_id is
  'Associated workspace.';
comment on column public.qxb_workspace_user.user_id is
  'Associated Qwrk user.';
comment on column public.qxb_workspace_user.role is
  'Workspace role allow-list: owner | admin | member.';
comment on column public.qxb_workspace_user.created_at is
  'DB-managed creation timestamp.';
comment on column public.qxb_workspace_user.updated_at is
  'DB-managed last update timestamp.';

alter table public.qxb_workspace_user enable row level security;

drop trigger if exists qxb_workspace_user_set_updated_at on public.qxb_workspace_user;

create trigger qxb_workspace_user_set_updated_at
before update on public.qxb_workspace_user
for each row
execute function public.qxb_set_updated_at();
