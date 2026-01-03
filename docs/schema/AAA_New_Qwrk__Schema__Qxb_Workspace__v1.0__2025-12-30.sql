-- =========================================================
-- public.qxb_workspace
-- =========================================================

create table if not exists public.qxb_workspace (
  workspace_id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.qxb_workspace is
  'Kernel v1 workspace table. System is workspace-first; every artifact requires workspace_id. RLS enabled; policies added later (deny-by-default).';

comment on column public.qxb_workspace.workspace_id is
  'Workspace identifier (PK).';
comment on column public.qxb_workspace.name is
  'Workspace display name.';
comment on column public.qxb_workspace.created_at is
  'DB-managed creation timestamp.';
comment on column public.qxb_workspace.updated_at is
  'DB-managed last update timestamp.';

alter table public.qxb_workspace enable row level security;

-- Shared updated_at trigger function (pattern)
create or replace function public.qxb_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists qxb_workspace_set_updated_at on public.qxb_workspace;

create trigger qxb_workspace_set_updated_at
before update on public.qxb_workspace
for each row
execute function public.qxb_set_updated_at();
