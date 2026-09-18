# AtlasChess — MongoDB → Supabase Migration (users + ai_keys)

Status: **code complete** — awaiting two owner actions (SQL + script run).

## What moved

| MongoDB collection | Supabase table | Client access |
|---|---|---|
| `chess_openings.users` | `public.profiles` | Own-row only (RLS); billing columns client-immutable |
| `chess_openings.ai_keys` | `public.ai_keys` | **None** — service-role only |

Everything else (`user_course_progress`, `user_puzzles`, `kova_games`,
`interactive_courses`, …) intentionally **stays on MongoDB** behind a scoped
least-privilege DB user.

## Why this is secure

- `profiles`: Row Level Security keys every policy on `auth.uid()`. Column-level
  grants mean a phone (or anyone unpacking the APK for the anon key) can update
  only `email/name/xp/current_streak/last_seen` on their own row. `plan`,
  `pro_expires`, `billing_cycle`, `total_paid` reject client writes at the
  Postgres level — Pro can be granted only by the service-role key, which lives
  exclusively server-side (website/Vercel).
- `profiles` rows auto-create via the `on_auth_user_created` trigger
  (`handle_new_user`) for both password and Google signups.
- `ai_keys`: RLS enabled with **zero policies** plus explicit `REVOKE ALL`
  from `anon`/`authenticated`. No client key can even SELECT it. The website's
  key rotation continues against Mongo until its Phase-2 switch, then uses the
  service-role client.

## Mobile code changes

| File | Change |
|---|---|
| `packages/atlas_core/lib/core/user/UserProfileService.dart` | Rewritten from `mongo_dart` to Supabase `profiles`; same public API so auth/UI code is untouched. Expired-premium downgrade is now computed at read time (clients can't write `plan`). |
| `packages/atlas_core/lib/core/courses/CourseApiService.dart` | `_hasProAccess` delegates to `UserProfileService.getPlanStatus` (Supabase). Removed direct `users` reads and the hardcoded admin email. |
| `supabase/migrations/001_profiles_and_ai_keys.sql` | New schema + RLS + grants + signup trigger. |

## Runbook (owner actions)

1. **Create the tables**: open Supabase Dashboard → SQL Editor, paste all of
   `Mobile/supabase/migrations/001_profiles_and_ai_keys.sql`, Run. Re-running is safe.
2. Verify in Dashboard → Table Editor: `profiles` row count ≈ real accounts;
   `ai_keys` populated. Then confirm the app: sign-in → badge shows plan;
   set nickname; course pro-lock behaves.
3. **Do NOT drop the Mongo collections yet** — the website still reads
   `users`/`ai_keys` from Mongo everywhere. Phase 2 = repoint website routes,
   and only after that delete the collections (your pre-production step).
4. Still recommended regardless: create the scoped Atlas user
   (`readWrite` on `chess_openings` only) since courses/progress remain on Mongo.

## Phase 2 (later, website-side)

Repoint website reads of `users` (subscription/status/display-name/admin) to
`public.profiles` and `key-manager.ts` to `public.ai_keys` using the service-role
client, backfill any new signups missed since migration (re-run script), then
drop the Mongo collections.
