-- ============================================================================
-- AtlasChess — AI key acquisition for on-device Gemini calls
--
-- The mobile Flutter app sends the Gemini request DIRECTLY from the device
-- (no hosted backend). It must obtain an ephemeral API key without storing
-- one on-device. `public.ai_keys` is service-role only (RLS zero policies),
-- so we expose the website's key-manager acquire/release logic as
-- `security definer` functions the app can call via `supabase.rpc(...)`.
--
-- A `security definer` function runs with its owner's privileges, so it can
-- read/update the secret-bearing table and hand back a key (and later its
-- status) WITHOUT giving clients direct table access or persisting secrets
-- on the device.
--
-- Concurrency: acquisition uses an atomic compare-and-set (`update ...
-- returning` with `for update skip locked`), so simultaneous app instances
-- never claim the same key. Deadlock recovery + exhausted/rate-limit
-- auto-recovery mirror the website's `key-manager.ts` exactly.
--
-- Run ONCE in: Supabase Dashboard → SQL Editor → paste → Run. Idempotent.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Next midnight Pacific Time as epoch ms (mirrors getNextMidnightPT).
-- ----------------------------------------------------------------------------
create or replace function public.next_midnight_pt()
returns bigint
language sql
stable
as $$
  select
    (extract(epoch from
      (date_trunc('day', (now() at time zone 'America/Los_Angeles') + interval '1 day')
       at time zone 'America/Los_Angeles')
    )::bigint * 1000)
$$;

-- ----------------------------------------------------------------------------
-- Atomically acquire an available key (mirrors acquireKey).
-- Returns { id, key } or null when no key is available.
-- ----------------------------------------------------------------------------
create or replace function public.acquire_ai_key()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  now_ms bigint := (extract(epoch from now())::bigint * 1000);
  next_midnight_ms bigint := public.next_midnight_pt();
  claimed record;
begin
  -- Deadlock Recovery: Free keys stuck in 'is_busy' too long (5 minute threshold)
  update public.ai_keys
     set is_busy = false
   where is_busy = true
     and last_used < now_ms - 300000;

  -- Auto-Recovery: Reactivate keys that have passed their cooldown/reset periods
  update public.ai_keys
     set status = 'active', daily_reset_at = next_midnight_ms
   where status = 'exhausted_daily'
     and daily_reset_at is not null
     and daily_reset_at < now_ms;

  update public.ai_keys
     set status = 'active'
   where status = 'rate_limited'
     and retry_after is not null
     and retry_after < now_ms;

  -- Atomic claim of the least-recently-used free active key.
  -- `for update skip locked` makes concurrent acquisitions safe.
  update public.ai_keys as k
     set is_busy = true,
         last_used = now_ms,
         daily_reset_at = coalesce(k.daily_reset_at, next_midnight_ms)
   where k.id = (
         select id
           from public.ai_keys
          where status = 'active' and is_busy = false
          order by last_used asc
          limit 1
            for update skip locked
       )
   returning k.id, k.key
   into claimed;

  if claimed is null or claimed.id is null then
    return null;
  end if;

  return jsonb_build_object('id', claimed.id, 'key', claimed.key);
end;
$$;

-- ----------------------------------------------------------------------------
-- Release a key back into the pool, applying quota handling
-- (mirrors releaseKey: 429 minute vs daily, 403 suspend, else busy=false).
-- ----------------------------------------------------------------------------
create or replace function public.release_ai_key(
  p_key_id text,
  p_success boolean,
  p_status integer default null,
  p_error jsonb default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  now_ms bigint := (extract(epoch from now())::bigint * 1000);
  violation jsonb;
  is_daily boolean := false;
begin
  -- Standard successful release.
  if p_success then
    update public.ai_keys set is_busy = false where id = p_key_id;
    return;
  end if;

  -- Quota Detection (Gemini prefers status 429 + type.googleapis.com/...QuotaFailure)
  if p_status = 429 and p_error is not null then
    select v
      into violation
      from jsonb_array_elements(coalesce(p_error -> 'error' -> 'details', '[]'::jsonb)) as q
      cross join lateral jsonb_array_elements(coalesce(q -> 'violations', '[]'::jsonb)) as v
     where q ->> '@type' = 'type.googleapis.com/google.rpc.QuotaFailure'
     limit 1;

    is_daily := violation is not null
        and violation ->> 'quotaId' like '%PerDay%';

    -- 5 minute backoff for any 429 (or daily exhaustion).
    if is_daily then
      update public.ai_keys
         set is_busy = false,
             status = 'exhausted_daily',
             retry_after = now_ms + 300000
       where id = p_key_id;
    else
      update public.ai_keys
         set is_busy = false,
             status = 'rate_limited',
             retry_after = now_ms + 300000
       where id = p_key_id;
    end if;
  elsif p_status = 403 then
    -- 403 Forbidden -> Suspend Key
    update public.ai_keys
       set is_busy = false,
           status = 'suspended'
     where id = p_key_id;
  else
    -- Any other failure: just free the busy lock.
    update public.ai_keys set is_busy = false where id = p_key_id;
  end if;
end;
$$;

-- Allow clients (signed-in or anonymous) to call the key functions.
grant execute on function public.next_midnight_pt() to anon, authenticated;
grant execute on function public.acquire_ai_key() to anon, authenticated;
grant execute on function public.release_ai_key(text, boolean, integer, jsonb)
  to anon, authenticated;

revoke all on function public.next_midnight_pt() from public;
revoke all on function public.acquire_ai_key() from public;
revoke all on function public.release_ai_key(text, boolean, integer, jsonb) from public;