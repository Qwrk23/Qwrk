-- =========================================================
-- public.qxb_artifact
-- Canonical spine table (Kernel v1)
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

comment on column public.qxb_artifact.artifact_id is
  'Primary key for the artifact (stable for life).';
comment on column public.qxb_artifact.workspace_id is
  'Required. FK to qxb_workspace. Enforces tenancy boundaries.';
comment on column public.qxb_artifact.owner_user_id is
  'Required. FK to qxb_user. Canonical ownership.';
comment on column public.qxb_artifact.artifact_type is
  'Allow-listed type identifier (Kernel v1: project | snapshot | restart | journal).';
comment on column public.qxb_artifact.title is
  'Human-readable title.';
comment on column public.qxb_artifact.summary is
  'Short description for list views and scanning.';
comment on column public.qxb_artifact.priority is
  '1–5 canonical mapping (1=Critical, 5=Plan).';
comment on column public.qxb_artifact.lifecycle_status is
  'Canonical lifecycle stage for the artifact (project lifecycle defined at the type layer).';
comment on column public.qxb_artifact.tags is
  'Tag set for filtering and organization.';
comment on column public.qxb_artifact.content is
  'Flexible payload (kept minimal; type tables hold structured fields).';
comment on column public.qxb_artifact.parent_artifact_id is
  'Optional FK to qxb_artifact. Used for lineage/spawn relationships.';
comment on column public.qxb_artifact.version is
  'Starts at 1; increments on every update.';
comment on column public.qxb_artifact.deleted_at is
  'Soft delete timestamp (null means active).';
comment on column public.qxb_artifact.created_at is
  'DB-managed creation timestamp.';
comment on column public.qxb_artifact.updated_at is
  'DB-managed last update timestamp.';

alter table public.qxb_artifact enable row level security;

drop trigger if exists qxb_artifact_set_updated_at on public.qxb_artifact;

create trigger qxb_artifact_set_updated_at
before update on public.qxb_artifact
for each row
execute function public.qxb_set_updated_at();
