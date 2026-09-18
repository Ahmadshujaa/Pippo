# AtlasChess Mobile

This directory is the runnable Flutter application for AtlasChess. It contains
the app shell, the local Pippo engine, shared application logic, UI package,
Supabase migrations, and Android support files. No Node.js server is required.

## Structure

```text
Mobile/
├── android/              # Android host and native engine libraries
├── assets/               # Assets owned by the application shell
├── lib/                  # App entrypoint, bootstrap, theme, and routes
├── packages/
│   ├── ui/               # atlas_ui: screens, widgets, and UI assets
│   └── atlas_core/       # atlas_core: local logic, models, and services
├── scripts/              # Local Android/device helpers
├── supabase/             # Database migrations
└── test/                 # Application tests
```

`atlas_ui` depends on the public API of `atlas_core`. The core package never
depends on UI widgets; the root app composes both packages through their barrel
exports.

## Commands

Run these from this directory:

```bash
flutter pub get
flutter analyze
flutter analyze packages/ui
flutter analyze packages/atlas_core
flutter test
flutter test packages/ui
flutter test packages/atlas_core
flutter build apk --debug
```

The app loads `.env` for optional local integrations and initializes Supabase,
authentication, the local Pippo puzzle pipeline, and the local analysis engine
during bootstrap.

## Daily Puzzle

One hard puzzle per local calendar day, shared by the players who are in that
day. `DailyPuzzleService` resolves it in this order:

1. the device's own cache for today's date (`shared_preferences`);
2. the `daily_puzzles` document for today in MongoDB;
3. otherwise (this device is the first one to open the app on a new day, or
   Mongo is unreachable) the puzzle is picked from the high-rated end of the
   Turso mirror and published to `daily_puzzles` for everybody else.

The Turso pick is deterministic for a date — the day's index into the
id-ordered set of puzzles at or above the rating floors 2200 / 2000 / 1800 — so
two devices racing to publish the same day still land on the same puzzle, and a
device that cannot reach Mongo at all still gets the shared puzzle.

Only one document per day is expected. Creating a unique index keeps it that
way under a race (optional: the deterministic pick already makes duplicates
harmless, since every writer stores the same puzzle):

```js
db.daily_puzzles.createIndex({ day: 1 }, { unique: true })
```

## Google sign-in on Android

Sign-in runs in one step: the system Google account sheet (`google_sign_in`)
returns an ID token, which `AuthApiService.signInWithGoogle` exchanges for a
Supabase session with `signInWithIdToken`. There is no browser or OAuth-redirect
fallback any more.

Two external things have to be right, and neither is visible from the code:

1. **The project key in `lib/app/bootstrap.dart`.** It must be the exact
   *anon / publishable* key from Supabase -> Project Settings -> API keys. Its
   JWT payload has to carry the `role` claim (`anon`); a copy that lost that
   claim while keeping the original signature is rejected by *every* endpoint
   with `Invalid API key`, which breaks Google sign-in, email sign-in and the
   profile reads at once. A valid key answers a password grant with
   `Invalid login credentials` instead.
2. **An *Android* OAuth client** in the Google Cloud project that owns the web
   client `896693022240-rpkip34tsdv59ippdae1quv1tn8k5e30`. Supabase's Google
   provider settings (web client ID + secret) do not cover it:

   * Package name: `com.example.tactics` (`applicationId` in
     `android/app/build.gradle.kts`)
   * Fingerprint of the key the installed build is signed with, taken from the
     debug keystore for a normal `flutter run`:

     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```

   Google reports a missing or mismatched Android client as a cancellation
   *after* an account is picked. `_isConfigurationCancel` in
   `AuthApiService.dart` detects that status message and shows the
   configuration error instead of pretending the user cancelled.
