-- =========================================================
-- public.qxb_artifact_restart
-- Restart type extension (Kernel v1)
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
  'Restart type table extending qxb_artifact. Manual, ad-hoc, immutable payload stored inline as jsonb. No lifecycle impact; enforced at Gateway. RLS enabled; policies added later (deny-by-default).';

comment on column public.qxb_artifact_restart.artifact_id is
  'PK=FK to qxb_artifact.artifact_id (class-table inheritance).';
comment on column public.qxb_artifact_restart.payload is
  'Frozen restart payload stored inline (jsonb).';
comment on column public.qxb_artifact_restart.created_at is
  'DB-managed creation timestamp (append-only intent).';

alter table public.qxb_artifact_restart enable row level security;
