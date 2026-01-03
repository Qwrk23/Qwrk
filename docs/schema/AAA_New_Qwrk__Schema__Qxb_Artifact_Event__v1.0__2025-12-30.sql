-- =========================================================
-- public.qxb_artifact_event
-- Append-only event log for explainability / audit (Kernel v1)
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
  'Append-only event log for artifacts (explainability/audit). Stores who did what, when, and a jsonb payload. RLS enabled; policies added later (deny-by-default).';

comment on column public.qxb_artifact_event.event_id is
  'Event identifier (PK).';
comment on column public.qxb_artifact_event.workspace_id is
  'Workspace scope for the event.';
comment on column public.qxb_artifact_event.artifact_id is
  'Artifact this event is about.';
comment on column public.qxb_artifact_event.actor_user_id is
  'Qwrk user who caused the event (nullable for system actions).';
comment on column public.qxb_artifact_event.event_type is
  'Event name (kept flexible; allow-list enforced at Gateway/contract layer).';
comment on column public.qxb_artifact_event.event_ts is
  'Event timestamp (business time).';
comment on column public.qxb_artifact_event.payload is
  'Event payload (jsonb).';
comment on column public.qxb_artifact_event.created_at is
  'DB-managed insert timestamp.';

alter table public.qxb_artifact_event enable row level security;

-- Prevent updates/deletes (append-only intent)
create or replace function public.qxb_block_update_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Updates/deletes are not allowed on append-only tables';
end;
$$;

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
