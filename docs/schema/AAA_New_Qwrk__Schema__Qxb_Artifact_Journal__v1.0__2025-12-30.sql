-- =========================================================
-- public.qxb_artifact_journal
-- Journal type extension (Kernel v1)
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
  'Journal type table extending qxb_artifact. Owner-private by default (RLS policy later). Text entry plus optional jsonb payload. RLS enabled; policies added later (deny-by-default).';

comment on column public.qxb_artifact_journal.artifact_id is
  'PK=FK to qxb_artifact.artifact_id (class-table inheritance).';
comment on column public.qxb_artifact_journal.entry_text is
  'Optional human-readable journal entry text.';
comment on column public.qxb_artifact_journal.payload is
  'Optional structured journal payload (jsonb).';
comment on column public.qxb_artifact_journal.created_at is
  'DB-managed creation timestamp.';
comment on column public.qxb_artifact_journal.updated_at is
  'DB-managed last update timestamp.';

alter table public.qxb_artifact_journal enable row level security;

drop trigger if exists qxb_artifact_journal_set_updated_at on public.qxb_artifact_journal;

create trigger qxb_artifact_journal_set_updated_at
before update on public.qxb_artifact_journal
for each row
execute function public.qxb_set_updated_at();
