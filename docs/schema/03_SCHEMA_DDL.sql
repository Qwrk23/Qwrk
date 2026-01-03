-- Qxb_Artifact (Kernel v1 spine)
-- Notes:
-- - artifact_id has NO default because Gateway generates it (per Phase 3 lock).
-- - FK constraints to Qxb_Workspace / Qxb_User will be added once those tables are defined.
-- - RLS is enabled immediately (deny-by-default until explicit policies are added).

create table if not exists public.qxb_artifact (
  artifact_id uuid primary key,

  workspace_id uuid not null,
  owner_user_id uuid not null,

  artifact_type text not null,
  title text,
  summary text,

  priority int check (priority between 1 and 5),
  lifecycle_status text,
  tags jsonb not null default '{}'::jsonb,
  content jsonb not null default '{}'::jsonb,

  parent_artifact_id uuid null,
  version int not null default 1,

  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint qxb_artifact_type_chk
    check (artifact_type in ('project','snapshot','restart','journal')),

  constraint qxb_artifact_parent_fk
    foreign key (parent_artifact_id) references public.qxb_artifact(artifact_id)
);

alter table public.qxb_artifact enable row level security;

-- updated_at trigger (DB-managed timestamps)
create or replace function public.qxb_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists qxb_artifact_set_updated_at on public.qxb_artifact;
create trigger qxb_artifact_set_updated_at
before update on public.qxb_artifact
for each row
execute function public.qxb_set_updated_at();
