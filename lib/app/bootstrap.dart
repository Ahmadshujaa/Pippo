import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/atlas_ui.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';

import 'app.dart';
import 'permissions.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> bootstrap() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure the permissions they need are granted/prepared from the very start.
  await requestStartupPermissions();

  try {
    await dotenv.load(fileName: '.env');
    AppLogger.info('[Bootstrap] Loaded .env file');
  } catch (e) {
    AppLogger.warn('[Bootstrap] Warning: could not load .env file: $e');
  }

  // The anon (publishable) key must be the exact value from Supabase ->
  // Project Settings -> API keys. Its JWT payload has to carry the role
  // claim (anon); a copy that lost that claim while keeping the original
  // signature is rejected by every Supabase endpoint with
  // '"message":"Invalid API key"', which silently broke Google sign-in,
  // email sign-in and the profile reads at the same time. A valid key
  // answers a password grant with 'Invalid login credentials' instead.
  await Supabase.initialize(
    url: 'https://hfnfmtyiblxmifuzbmze.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmbmZtdHlpYmx4bWlmdXpibXplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3MzcyMDIsImV4cCI6MjA4NDMxMzIwMn0.T0cAtNMcaOdajte6d3d1kkQY1vzq_JR73uEeOYTPByg',
  );

  await AuthService.init();
  // On-device account cache (display name + plan). Loaded before the first
  // frame so the home screen already knows who is signed in when it builds.
  await UserProfileStore.init();
  // Local-only daily streak: opening the app is the daily check-in (no
  // network, no account needed). Done before the first frame so the home
  // screen reads the already-updated count.
  await StreakService.registerToday();
  await ThemeService.init();
  await LocaleService.init();
  await UserPuzzleStorageService.init();
  await DownloadedPuzzlesService.init();
  await BackgroundPuzzleService.instance.init();
  unawaited(MongoService.init());
  // Refreshes an expired access token and mirrors the account identity into
  // the local cache, so a returning user lands straight on the home screen.
  await AuthService.restoreSession();
  // A restored session alone is not enough to land on the home screen: an
  // account whose display name never reached Supabase is sent to the name
  // prompt, and a device with no session starts at the welcome screen. Resolved
  // here rather than with `AuthService.isLoggedIn ? '/home' : '/'` so a missing
  // display name is caught on every launch, not only right after signing in.
  final initialRoute = await AuthApiService.startupRoute();
  // The first connected app launch on a new local day advances the shared
  // MongoDB usage marker and removes yesterday's user_data documents. It is a
  // shared write, so a device with no account skips it entirely.
  unawaited(DailyUsageService.resetIfNewDay());

  // Global internet-connection monitor — screens subscribe to it to show the
  // offline banner and to offer/disable online features.
  ConnectivityService.startMonitoring();

  runApp(TacticsApp(initialRoute: initialRoute));

  // Warm the board's piece + classification caches on the first idle moment so
  // the first board screen the user opens is already smooth (no SVG parse /
  // PNG decode stall on the UI thread).
  final WidgetsBinding binding = WidgetsBinding.instance;
  binding.addPostFrameCallback((_) {
    try {
      ChessBoard.warmUpAssets();
    } catch (e) {
      debugPrint('[Bootstrap] Board asset warm-up skipped: $e');
    }

    // Load Pippo's ONNX model lazily a moment later so the first frame and the
    // very first navigation are not delayed by the synchronous session build.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      PippoEngineService.instance.loadModel().catchError((Object e) {
        debugPrint('[Bootstrap] Pippo model preload skipped: $e');
      });
    });
  });
}
