-- =========================================================
-- public.qxb_artifact_snapshot
-- Snapshot type extension (Kernel v1)
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
  'Snapshot type table extending qxb_artifact. Immutable lifecycle-only snapshot payload stored inline as jsonb. No updates expected; enforced at Gateway. RLS enabled; policies added later (deny-by-default).';

comment on column public.qxb_artifact_snapshot.artifact_id is
  'PK=FK to qxb_artifact.artifact_id (class-table inheritance).';
comment on column public.qxb_artifact_snapshot.payload is
  'Frozen snapshot payload stored inline (jsonb).';
comment on column public.qxb_artifact_snapshot.created_at is
  'DB-managed creation timestamp (append-only intent).';

alter table public.qxb_artifact_snapshot enable row level security;
