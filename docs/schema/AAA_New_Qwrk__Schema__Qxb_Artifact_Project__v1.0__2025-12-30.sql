-- =========================================================
-- public.qxb_artifact_project
-- Project type extension (Kernel v1)
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
  'Project type table extending qxb_artifact. Enforces project lifecycle and operational state semantics. Immutable transitions enforced at Gateway layer. RLS enabled; policies added later (deny-by-default).';

comment on column public.qxb_artifact_project.artifact_id is
  'PK=FK to qxb_artifact.artifact_id (class-table inheritance).';
comment on column public.qxb_artifact_project.lifecycle_stage is
  'Project lifecycle: seed → sapling → tree → retired.';
comment on column public.qxb_artifact_project.operational_state is
  'Operational state: active | paused | blocked | waiting.';
comment on column public.qxb_artifact_project.state_reason is
  'Required context when operational_state is blocked or waiting.';
comment on column public.qxb_artifact_project.created_at is
  'DB-managed creation timestamp.';
comment on column public.qxb_artifact_project.updated_at is
  'DB-managed last update timestamp.';

alter table public.qxb_artifact_project enable row level security;

drop trigger if exists qxb_artifact_project_set_updated_at on public.qxb_artifact_project;

create trigger qxb_artifact_project_set_updated_at
before update on public.qxb_artifact_project
for each row
execute function public.qxb_set_updated_at();
