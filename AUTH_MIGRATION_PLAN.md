# AtlasChess App — Standalone Auth Migration Plan (FINAL: zero-hosting architecture)

> **UPDATE:** The `users` collection has been superseded by Supabase Postgres
> (`public.profiles`) and `ai_keys` now lives in a service-role-only
> `public.ai_keys` table. See `SUPABASE_MIGRATION.md` for the current state.

## Goal

Move **all sign-in / sign-up logic** out of the Website backend so the Flutter app never
talks to `atlaschess.me` for authentication — **and never needs any hosted backend at all.**
Every auth call is made on-device: directly to Supabase (official Flutter SDK) and directly
to MongoDB (`mongo_dart`). Accounts remain shared between web and app because both sides use
the same Supabase project and the same MongoDB database/collections.

An intermediate Express-based design was built and then **fully reverted** when the owner
confirmed no hosting is desired. The mobile workspace contains no Node.js runtime; all
local application logic lives in `packages/atlas_core`.

## Decisions (owner-confirmed)

| Topic | Decision |
|---|---|
| Hosting | None whatsoever — no Express, no server; logic runs inside the app |
| Databases | Same Supabase project + same MongoDB DB as the website (shared accounts) |
| Supabase access | Publishable anon key via `supabase_flutter` (designed to be embedded) |
| MongoDB access | Direct `mongo_dart` connection using creds in `.env` (pattern already in app) |
| Signup abuse limits | None — no fingerprint, no per-IP limits |
| Email domain whitelist / password rules | Kept as client-side validation |
| Fingerprint recording | Removed everywhere (FingerprintService deleted) |
| Referrals | Skipped for now |
| Forgot password | Implemented (new): recovery-code email → confirm code → set new password |
| Plan status | Ported: ADMIN/PRO/FREE badge on Home top bar (was hardcoded 'PRO') |

## Why this is secure

- The Supabase anon/publishable key is public by design; all protection (rate limiting,
  email confirmation, token issuance/refresh, password hashing) happens server-side at
  Supabase. The service-role key stays out of the app.
- MongoDB credentials embedded in any client are extractable in principle; damage is
  contained by scoping the DB user (see "Actions needed from you").
- Client-side validation mirrors the website's rules exactly.

## Implementation (all changes inside the Mobile folder)

### New / rewritten Dart files (`Mobile/packages/atlas_core/lib/core/…`)

| File | Contents |
|---|---|
| `core/user/UserProfileService.dart` (NEW) | Ports of website logic: `ensureUserDocument`, `touchLastSeen`, display-name get/set, and plan status handling. |
| `core/auth/AuthApiService.dart` (REWRITTEN) | Pure client-side Supabase and Google auth flows, OTP handling, password recovery, profile setup, and authenticated requests. |
| `config/ApiConfig.dart` (TRIMMED) | All auth URIs removed; retains website endpoints still used by non-auth features (stats, courses, puzzles). |
| `services/UserApiService.dart` (TRIMMED) | Only getStats remains; display-name moved to AuthApiService/Mongo. |
| `services/FingerprintService.dart` (DELETED) | No fingerprints anywhere in the app. |

### UI updates (`Mobile/packages/ui/lib/…`)

| File | Change |
|---|---|
| `auth/AuthScreen.dart`, `auth/AuthForm.dart`, `play/pippo_play_screen.dart`, `dashboard/HomeScreen.dart` | Switched from `UserApiService.getDisplayName()` to `AuthApiService.fetchDisplayName()` (direct Mongo read). |
| `AuthForm.dart` | Dead “Forgot Password?” button now opens a two-step bottom sheet: request recovery code → enter code + new password → auto-signed-in → routed to onboarding/home. |
| `HomeScreen.dart` | Top-bar badge now shows live plan from `getPlanStatus()`: `ADMIN` / `PRO` / `FREE`; hidden for guests. |

### Config

- `Mobile/.env`: added `ADMIN_EMAILS` (used only for the client-side admin badge).
- `Mobile/.env`: contains the local integration settings used by the app.

## Verification

- `flutter analyze`: 0 errors (remaining items are pre-existing style lints across untouched files).
- Manual test matrix (run with `flutter run`): gmail signup → OTP → name prompt → home badge FREE;
  sign-in with a web-created account; wrong-password error text; unverified-email error;
  resend OTP; Google button end-to-end; forgot-password full loop; badge reflects plan of
  free/pro/admin accounts.

## Actions needed from you (security hardening)

1. **Create a least-privilege MongoDB user for the app** (Atlas UI → Database Access):
   e.g. user `atlas_app_client` with role `{ role: "readWrite", db: "chess_openings" }`
   (optionally collection-scoped to `users` via custom role), then replace `MONGODB_URI`
   in `Mobile/.env` with that user's credentials. The current URI uses a personal/admin-level
   account — fine for dev, risky if an APK is unpacked.
2. **Check the Supabase email templates**: the reset flow expects the "Reset Password /
   Recovery" email to contain the OTP code (`{{ .Token }}`) rather than only a magic link —
   same style your signup confirmation evidently uses.
3. In Supabase Dashboard → Auth, keep **email confirmation enabled**, enable **leaked-password
   protection**, and review auth rate limits (defaults are sane).
4. Optional future hardening: move user profiles from Mongo into Supabase Postgres tables
   guarded by RLS policies keyed on `auth.uid()` — true per-user server-enforced security with
   zero hosting. Not done now to keep data shared with the website.

## Out of scope

- Website folder untouched; non-auth features (stats/courses/puzzles/explorer) still hit the
  website until separately migrated; referrals deferred.
