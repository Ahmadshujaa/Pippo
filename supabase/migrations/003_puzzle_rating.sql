-- ============================================================================
-- AtlasChess — account-level puzzle rating
--
-- The puzzle rating lives on-device (shared preferences) and stays there: it
-- is what offline play, guests and every existing caller read. This column is
-- the per-account mirror so the rating survives a reinstall and follows the
-- user to another device. The app keeps the HIGHER of the two values and
-- writes it back to both sides.
--
-- 0 means "not set yet" so the column default never inflates a rating the
-- device already knows better about (e.g. rows migrated from MongoDB).
--
-- Run ONCE in: Supabase Dashboard → SQL Editor → paste → Run. Idempotent.
-- ============================================================================

alter table public.profiles
  add column if not exists puzzle_rating integer not null default 0;

comment on column public.profiles.puzzle_rating is
  'Account-level mirror of the device-local puzzle rating. 0 = never synced. Clients keep max(local, puzzle_rating).';

-- The column grants in 001 are an allow-list, so the new column must be added
-- explicitly or every client write is rejected by Postgres.
grant update (puzzle_rating) on table public.profiles to authenticated;
