import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atlas_core/core/logging/AppLogger.dart';
import 'package:atlas_core/core/user/UserProfileStore.dart';

class AuthService {
  static SharedPreferences? _prefs;

  /// False when the stored session was rejected by Supabase (its refresh token
  /// is expired/revoked) and the account genuinely has to sign in again.
  /// Network failures never set this — being offline must not log anyone out.
  static bool _sessionRestorable = true;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Restores the session from Supabase SDK's internal storage.
  /// This is lazy and doesn't run a background service.
  ///
  /// The SDK restores the session without a round trip, so an access token
  /// that expired while the app was closed is restored as-is. We refresh it
  /// here (the refresh token lasts far longer than the access token) so the
  /// user is not bounced back to the sign-in screen after a day away, and we
  /// mirror the identity into [UserProfileStore] so the UI has something to
  /// show before the first network call completes.
  static Future<void> restoreSession() async {
    final auth = Supabase.instance.client.auth;
    final session = auth.currentSession;
    if (session == null) {
      _sessionRestorable = true;
      AppLogger.info('[AuthService] No session found to restore.');
      return;
    }

    _sessionRestorable = true;

    if (session.isExpired) {
      try {
        await auth.refreshSession();
        AppLogger.info('[AuthService] Session refreshed for: ${session.user.email}');
      } on AuthException catch (e) {
        // The refresh token itself is invalid/revoked — this session is dead,
        // so drop it and let the app start at the welcome screen.
        AppLogger.warn('[AuthService] Session no longer valid: ${e.message}');
        _sessionRestorable = false;
        await clearSession();
        return;
      } catch (e) {
        // Offline or a transient server error: keep the session. The SDK
        // retries the refresh automatically once the app is back online.
        AppLogger.warn('[AuthService] Deferred session refresh (offline?): $e');
      }
    } else {
      AppLogger.info('[AuthService] Session restored for: ${session.user.email}');
    }

    await UserProfileStore.saveIdentity(
      userId: session.user.id,
      email: session.user.email,
    );
  }

  /// Whether the device holds a usable Supabase session.
  ///
  /// Deliberately independent of the access token's expiry: the SDK refreshes
  /// it in the background, so treating an expired-but-refreshable token as
  /// "logged out" would send users back to the sign-in screen on every cold
  /// start. [restoreSession] only flips this off for a session that Supabase
  /// actually rejected.
  static bool get isLoggedIn {
    if (!_sessionRestorable) return false;
    return Supabase.instance.client.auth.currentSession != null;
  }

  static String? get token {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  static String? get userId {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  static String? get userEmail {
    return Supabase.instance.client.auth.currentUser?.email;
  }

  /// Saves session data. The Supabase SDK already persists the session itself
  /// (and refreshing it here would overwrite the freshly-issued tokens with a
  /// re-derived pair), so this only records which account the device is on.
  static Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    int? expiresAt,
    String? userId,
    String? userEmail,
  }) async {
    await UserProfileStore.saveIdentity(userId: userId, email: userEmail);
  }

  /// Signs out of Supabase and Google, and wipes the account's cached profile
  /// so the next user to sign in on this device never sees stale data.
  static Future<void> clearSession() async {
    await UserProfileStore.clear();

    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      // Google Sign-In may not be initialized yet (e.g. the user never tapped
      // the Google button) — nothing to clear in that case.
      AppLogger.debug('[AuthService] Google sign-out skipped: $e');
    }

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      AppLogger.error('[AuthService] Logout error: $e');
    }
  }
}
