-- :contentReference[oaicite:0]{index=0}

-- =========================================================
-- public.qxb_user
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

comment on column public.qxb_user.user_id is
  'Qwrk internal user identifier (PK).';
comment on column public.qxb_user.auth_user_id is
  'Supabase auth.users.id mapping (unique, required).';
comment on column public.qxb_user.status is
  'User status allow-list: active | disabled.';
comment on column public.qxb_user.display_name is
  'Optional display name.';
comment on column public.qxb_user.email is
  'Optional email (non-authoritative; may drift from auth provider).';
comment on column public.qxb_user.created_at is
  'DB-managed creation timestamp.';
comment on column public.qxb_user.updated_at is
  'DB-managed last update timestamp.';

alter table public.qxb_user enable row level security;

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

drop trigger if exists qxb_user_set_updated_at on public.qxb_user;

create trigger qxb_user_set_updated_at
before update on public.qxb_user
for each row
execute function public.qxb_set_updated_at();
