-- ============================================================================
-- AtlasChess — MongoDB → Supabase migration (mobile-side, zero hosting)
-- Collections migrated: users → public.profiles, ai_keys → public.ai_keys
--
-- Run ONCE in: Supabase Dashboard → SQL Editor → paste → Run.
-- Safe to re-run (idempotent).
-- ============================================================================

-- ============================================================================
-- 1) PROFILES  (from MongoDB `users`)
--    Each user can read/write ONLY their own row.
--    Billing columns (plan, pro_expires, billing_cycle, total_paid) are
--    IMMUTABLE for clients — only the service_role key (website on Vercel)
--    can change them. This is enforced by Postgres column grants below.
-- ============================================================================

create table if not exists public.profiles (
  id             uuid primary key,
  -- NOTE: no FK to auth.users on purpose. The Mongo `users` collection holds
  -- legacy UUIDs that predate (or never had) a Supabase auth account; an FK
  -- would block migrating them and force data loss. RLS below still restricts
  -- every row to its own auth.uid(), so rows without an auth account are
  -- unreachable by clients but preserved intact.
  email          text,
  name           text,
  xp             integer      not null default 0,
  current_streak integer      not null default 0,
  plan           text         not null default 'free',
  pro_expires    timestamptz,
  billing_cycle  text,
  total_paid     numeric(12,2) not null default 0,
  created_at     timestamptz  not null default now(),
  last_seen      timestamptz  not null default now(),
  updated_at     timestamptz  not null default now()
);

comment on table public.profiles is
  'Migrated from MongoDB chess_openings.users. RLS: owner-only rows; plan/billing columns are service-role only.';

alter table public.profiles enable row level security;

-- Owner can read their own row
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select to authenticated
  using (id = auth.uid());

-- Owner can create their own row, but it must start as a free plan
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert to authenticated
  with check (id = auth.uid() and plan = 'free');

-- Owner can update their own row...
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- ...but ONLY these columns. Attempts to SET plan / pro_expires /
-- billing_cycle / total_paid from any client key are rejected by Postgres.
revoke update on table public.profiles from authenticated;
grant update (email, name, xp, current_streak, last_seen, updated_at)
  on table public.profiles to authenticated;

-- Auto-create a profile whenever someone signs up (password OR Google).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, lower(new.email))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create index if not exists profiles_email_idx on public.profiles (lower(email));

-- ============================================================================
-- 2) AI KEYS  (from MongoDB `ai_keys`)
--    Server-only third-party API secrets. NO client access whatsoever:
--    RLS enabled with zero policies + explicit revokes. Only the
--    service_role key can ever touch this table.
-- ============================================================================

create table if not exists public.ai_keys (
  id             text primary key,          -- hex of former Mongo _id
  key            text not null,
  status         text not null default 'active', -- active|rate_limited|exhausted_daily|suspended
  is_busy        boolean not null default false,
  last_used      bigint  not null default 0,   -- epoch ms (PT-rotation clock)
  daily_reset_at bigint,                        -- epoch ms
  retry_after    bigint                         -- epoch ms
);

comment on table public.ai_keys is
  'Migrated from MongoDB chess_openings.ai_keys. Service-role ONLY — no client policies exist.';

alter table public.ai_keys enable row level security;

revoke all on table public.ai_keys from anon;
revoke all on table public.ai_keys from authenticated;
