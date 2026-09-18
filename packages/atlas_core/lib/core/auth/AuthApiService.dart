import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:atlas_core/core/user/UserProfileService.dart';
import 'package:atlas_core/core/user/UserProfileStore.dart';
import 'package:atlas_core/core/auth/AuthService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';

/// Result wrapper returned by all auth operations.
class AuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? session;
  final Map<String, dynamic>? user;
  final bool requiresVerification;
  final bool cancelled;

  const AuthResult({
    required this.success,
    this.error,
    this.session,
    this.user,
    this.requiresVerification = false,
    this.cancelled = false,
  });
}

/// Fully client-side auth service.
///
/// Every flow talks directly to Supabase (with the public publishable key)
/// and to MongoDB through [UserProfileService]. There is no hosted backend
/// involved anywhere: account documents are created/updated on-device.
class AuthApiService {
  /// The **web** OAuth client of the Google project that Supabase is configured
  /// with (it is the client whose ID appears in the `client_id` of the Google
  /// consent URL Supabase builds). It is intentionally not a secret.
  ///
  /// Android's native sign-in (Credential Manager) additionally needs an
  /// **Android** OAuth client in that *same* Google Cloud project, registered
  /// with this app's `applicationId` (`com.example.tactics`) and the SHA-1 of
  /// the key the APK is signed with. Without that credential Google reports
  /// the app as unregistered and the native picker always fails — no Dart code
  /// can substitute for it. `google_sign_in` reads the web client from here as
  /// `serverClientId`; `default_web_client_id` from `google-services.json` is
  /// not used by this project.
  static const String _googleWebClientId =
      '896693022240-rpkip34tsdv59ippdae1quv1tn8k5e30.apps.googleusercontent.com';

  static Future<void>? _googleInitialization;

  static SupabaseClient get _client => Supabase.instance.client;

  /// Initializes the native Google Sign-In plugin exactly once.
  ///
  /// A failed initialization is not cached: the plugin rejects being
  /// initialized twice, so keeping a rejected future around would break every
  /// later retry with the same error.
  static Future<void> _initializeGoogleSignIn() {
    return _googleInitialization ??= _initializeGoogleSignInInternal();
  }

  static Future<void> _initializeGoogleSignInInternal() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleWebClientId,
      );
    } catch (e) {
      _googleInitialization = null;
      AppLogger.warn('[AuthApiService] Google Sign-In init failed: $e');
      rethrow;
    }
  }

  // ===== Sign Up =====
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final emailLower = email.trim().toLowerCase();

      if (!UserProfileService.isAllowedEmailDomain(emailLower)) {
        return const AuthResult(
          success: false,
          error: 'Only Gmail or GitHub emails are allowed.',
        );
      }

      if (!UserProfileService.isStrongEnoughPassword(password)) {
        return const AuthResult(
          success: false,
          error:
              'Password must be at least 8 characters with uppercase, lowercase, and a number.',
        );
      }

      final response = await _client.auth.signUp(
        email: emailLower,
        password: password,
        data: {'full_name': fullName?.trim() ?? ''},
      );

      final user = response.user;

      // Supabase obfuscates already-registered emails by returning a fake
      // user without identities when email confirmation is enabled.
      if (user != null && (user.identities?.isEmpty ?? false)) {
        return const AuthResult(
          success: false,
          error: 'An account with this email already exists. Try signing in.',
        );
      }

      if (user != null) {
        await UserProfileService.ensureUserDocument(user.id, emailLower);
        await UserProfileStore.saveIdentity(
          userId: user.id,
          email: user.email ?? emailLower,
        );
      }

      final session = response.session;
      if (session != null) {
        await _saveSession(
          {
            'access_token': session.accessToken,
            'refresh_token': session.refreshToken,
            'expires_at': session.expiresAt,
          },
          {'id': user?.id, 'email': user?.email},
        );
      }

      return AuthResult(
        success: true,
        requiresVerification: session == null,
        user: {'id': user?.id, 'email': user?.email},
        session: session == null
            ? null
            : {
                'access_token': session.accessToken,
                'refresh_token': session.refreshToken,
                'expires_at': session.expiresAt,
              },
      );
    } on AuthApiException catch (e) {
      if (_isAlreadyRegistered(e)) {
        return const AuthResult(
          success: false,
          error: 'An account with this email already exists. Try signing in.',
        );
      }
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      AppLogger.error('[AuthApiService] signUp error: $e');
      return const AuthResult(
        success: false,
        error: 'Could not reach server. Check your connection.',
      );
    }
  }

  // ===== Sign In =====
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final emailLower = email.trim().toLowerCase();

      final response = await _client.auth.signInWithPassword(
        email: emailLower,
        password: password,
      );

      final session = response.session;
      final user = response.user;
      if (session == null || user == null) {
        return const AuthResult(
          success: false,
          error: 'Invalid email or password.',
        );
      }

      // Keep last_seen fresh on the profile row (no fingerprint/IP is recorded).
      await UserProfileService.touchLastSeen(user.id, emailLower);

      await _saveSession(
        {
          'access_token': session.accessToken,
          'refresh_token': session.refreshToken,
          'expires_at': session.expiresAt,
        },
        {'id': user.id, 'email': user.email},
      );

      return AuthResult(
        success: true,
        user: {'id': user.id, 'email': user.email},
        session: {
          'access_token': session.accessToken,
          'refresh_token': session.refreshToken,
          'expires_at': session.expiresAt,
        },
      );
    } on AuthApiException catch (e) {
      if (_isInvalidCredentials(e)) {
        return const AuthResult(
          success: false,
          error: 'Invalid email or password.',
        );
      }
      if (_isEmailNotConfirmed(e)) {
        return const AuthResult(
          success: false,
          error: 'Please verify your email before signing in.',
        );
      }
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      AppLogger.error('[AuthApiService] signIn error: $e');
      return const AuthResult(
        success: false,
        error: 'Could not reach server. Check your connection.',
      );
    }
  }

  // ===== Verify OTP (after sign up) =====
  static Future<AuthResult> verifyOtp({
    required String email,
    required String token,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();

    // Same fallback order as the website backend used to have.
    const types = [OtpType.signup, OtpType.email, OtpType.magiclink];

    for (final type in types) {
      try {
        final response = await _client.auth.verifyOTP(
          email: cleanEmail,
          token: cleanToken,
          type: type,
        );

        final session = response.session;
        final user = response.user;

        if (session != null && user != null) {
          await _saveSession(
            {
              'access_token': session.accessToken,
              'refresh_token': session.refreshToken,
              'expires_at': session.expiresAt,
            },
            {'id': user.id, 'email': user.email},
          );
          await UserProfileService.ensureUserDocument(user.id, cleanEmail);
          await UserProfileStore.saveIdentity(
            userId: user.id,
            email: user.email ?? cleanEmail,
          );

          return AuthResult(
            success: true,
            user: {'id': user.id, 'email': user.email},
            session: {
              'access_token': session.accessToken,
              'refresh_token': session.refreshToken,
              'expires_at': session.expiresAt,
            },
          );
        }
      } on AuthApiException catch (e) {
        final message = e.message.toLowerCase();
        if (!message.contains('invalid') && !message.contains('expired')) {
          return AuthResult(success: false, error: e.message);
        }
      } catch (e) {
        AppLogger.error('[AuthApiService] verifyOtp error ($type): $e');
      }
    }

    return const AuthResult(
      success: false,
      error: 'Invalid or expired code. Please request a new one.',
    );
  }

  // ===== Resend OTP =====
  static Future<AuthResult> resendOtp({required String email}) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
      );
      return const AuthResult(success: true);
    } on AuthApiException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      AppLogger.error('[AuthApiService] resendOtp error: $e');
      return const AuthResult(
        success: false,
        error: 'Could not reach server. Check your connection.',
      );
    }
  }

  // ===== Forgot Password =====
  /// Sends the recovery code email for [email].
  static Future<AuthResult> requestPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
      return const AuthResult(
        success: true,
      );
    } on AuthApiException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      AppLogger.error('[AuthApiService] requestPasswordReset error: $e');
      return const AuthResult(
        success: false,
        error: 'Could not reach server. Check your connection.',
      );
    }
  }

  /// Confirms the recovery code and sets [newPassword], leaving the user
  /// signed in afterwards.
  static Future<AuthResult> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    if (!UserProfileService.isStrongEnoughPassword(newPassword)) {
      return const AuthResult(
        success: false,
        error:
            'Password must be at least 8 characters with uppercase, lowercase, and a number.',
      );
    }

    try {
      final cleanEmail = email.trim().toLowerCase();

      final response = await _client.auth.verifyOTP(
        email: cleanEmail,
        token: token.trim(),
        type: OtpType.recovery,
      );

      final session = response.session;
      final user = response.user;
      if (session == null || user == null) {
        return const AuthResult(
          success: false,
          error: 'Invalid or expired code. Please request a new one.',
        );
      }

      await _client.auth.updateUser(UserAttributes(password: newPassword));
      await UserProfileService.ensureUserDocument(user.id, cleanEmail);
      await UserProfileStore.saveIdentity(
        userId: user.id,
        email: user.email ?? cleanEmail,
      );

      await _saveSession(
        {
          'access_token': session.accessToken,
          'refresh_token': session.refreshToken,
          'expires_at': session.expiresAt,
        },
        {'id': user.id, 'email': user.email},
      );

      return AuthResult(
        success: true,
        user: {'id': user.id, 'email': user.email},
        session: {
          'access_token': session.accessToken,
          'refresh_token': session.refreshToken,
          'expires_at': session.expiresAt,
        },
      );
    } on AuthApiException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('invalid') || message.contains('expired')) {
        return const AuthResult(
          success: false,
          error: 'Invalid or expired code. Please request a new one.',
        );
      }
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      AppLogger.error('[AuthApiService] confirmPasswordReset error: $e');
      return const AuthResult(
        success: false,
        error: 'Could not reach server. Check your connection.',
      );
    }
  }

  // ===== Google Sign-In =====
  ///
  /// One path only: the native account picker, whose Google ID token is
  /// exchanged for a Supabase session with `signInWithIdToken`. No browser and
  /// no OAuth redirect are involved, so the only external requirement is the
  /// Android OAuth client documented on [_googleWebClientId] — everything else
  /// is a plain call to Supabase.
  static Future<AuthResult> signInWithGoogle() async {
    // `supportsAuthenticate` goes through the platform interface, so it throws
    // where no implementation is registered instead of returning false.
    bool supported = false;
    try {
      supported = GoogleSignIn.instance.supportsAuthenticate();
    } catch (e) {
      AppLogger.warn('[AuthApiService] Google sign-in unsupported here: $e');
    }
    if (!supported) {
      return const AuthResult(
        success: false,
        error: 'Google sign-in is only available in the Android app.',
      );
    }

    final result = await _signInWithGoogleNatively();
    if (!result.success && !result.cancelled) {
      // Keep the exact reason in the logs: the banner is deliberately short and
      // the informative failures (unregistered SHA-1, rejected project key) are
      // otherwise invisible.
      AppLogger.error('[AuthApiService] Google sign-in failed: ${result.error}');
    }
    return result;
  }

  /// Native Google account picker, exchanged for a Supabase session via the
  /// ID token.
  static Future<AuthResult> _signInWithGoogleNatively() async {
    try {
      await _initializeGoogleSignIn();
      final googleAccount = await GoogleSignIn.instance.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const AuthResult(
          success: false,
          error: 'Google did not return an identity token. Please try again.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      final session = response.session;
      final user = response.user;
      if (session == null || user == null) {
        return const AuthResult(
          success: false,
          error: 'Google sign-in did not create a session. Please try again.',
        );
      }

      return await _finishGoogleSession(user, session);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // Android reports an app that is not registered for Google Sign-In
        // (missing Android OAuth client: wrong package name or signing SHA-1)
        // as a *cancellation* after the account has been picked, and
        // `google_sign_in` cannot tell that apart from the user dismissing the
        // sheet. A cancellation that carries a status message is therefore
        // reported as the configuration problem it is instead of silently
        // doing nothing.
        if (_isConfigurationCancel(e)) {
          AppLogger.warn(
            '[AuthApiService] Google Sign-In cancelled with status: '
            '${e.description}',
          );
          return const AuthResult(
            success: false,
            error: _googleConfigurationHint,
          );
        }
        return const AuthResult(success: false, cancelled: true);
      }
      AppLogger.error('[AuthApiService] Google Sign-In exception: $e');
      return AuthResult(success: false, error: _describeGoogleException(e));
    } on AuthApiException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      AppLogger.error('[AuthApiService] Google sign-in error: $e');
      return AuthResult(
        success: false,
        error: _googleConfigFailureDetected(e.toString())
            ? _googleConfigurationHint
            : 'Could not complete Google sign-in. Please try again.',
      );
    }
  }

  /// Persists the Google identity, refreshes the account documents and caches
  /// the profile for the next launch.
  static Future<AuthResult> _finishGoogleSession(
    User user,
    Session session,
  ) async {
    await _saveSession(
      {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken,
        'expires_at': session.expiresAt,
      },
      {'id': user.id, 'email': user.email},
    );

    // Create/refresh the profile row directly from the device. A hiccup here
    // must not void a session that Google and Supabase already created.
    try {
      await UserProfileService.ensureUserDocument(user.id, user.email ?? '');
    } catch (e) {
      AppLogger.warn('[AuthApiService] Profile setup after Google sign-in failed: $e');
    }

    return AuthResult(
      success: true,
      session: {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken,
        'expires_at': session.expiresAt,
      },
      user: {'id': user.id, 'email': user.email},
    );
  }

  /// True when a cancellation carries a Credential Manager status message.
  ///
  /// A user dismissal comes back with no status at all, while an unregistered
  /// app comes back with a message such as "Account reauth failed" (status 16),
  /// "Cannot find a matching credential" or a DEVELOPER_ERROR. Those are the
  /// signals that the Android OAuth client is missing for this build.
  static bool _isConfigurationCancel(GoogleSignInException e) {
    final description = (e.description ?? '').trim();
    final details = (e.details ?? '').toString().trim();
    if (description.isEmpty && details.isEmpty) return false;

    final lowerDescription = description.toLowerCase();
    final lowerDetails = details.toLowerCase();
    return _googleConfigFailureDetected(description) ||
        _googleConfigFailureDetected(details) ||
        lowerDescription.contains('reauth') ||
        lowerDetails.contains('reauth') ||
        lowerDescription.contains('matching credential') ||
        lowerDetails.contains('matching credential');
  }

  static bool _googleConfigFailureDetected(String message) {
    final lower = message.toLowerCase();
    return lower.contains('apiexception') ||
        lower.contains('developer_error') ||
        lower.contains('sign_in_failed') ||
        lower.contains(': 10') ||
        lower.contains('clientid') ||
        lower.contains('serverclientid') ||
        lower.contains('not configured');
  }

  /// Explains an actionable Google configuration problem instead of blaming the
  /// user's connection, which is what the previous generic message did.
  static String _describeGoogleException(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return _googleConfigurationHint;
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in needs the app in the foreground. Please try again.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google sign-in was interrupted. Please try again.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Please pick the same Google account you were using.';
      case GoogleSignInExceptionCode.unknownError:
        final description = e.description ?? '';
        if (_googleConfigFailureDetected(description)) {
          return _googleConfigurationHint;
        }
        if (description.toLowerCase().contains('no credential')) {
          return 'No Google account found on this device. Add one in Settings, or continue with email.';
        }
        return 'Could not complete Google sign-in. Please try again.';
      case GoogleSignInExceptionCode.canceled:
        return 'Google sign-in was cancelled.';
    }
  }

  /// Kept to one short sentence: the sign-in screens render errors inline and
  /// a wall of text would be clipped.
  static const String _googleConfigurationHint =
      'Google sign-in is not configured for this build yet. Use email, or ask '
      'the developer to register the signing SHA-1 in Google Cloud.';

  // ===== Display Name =====
  /// Reads the nickname of the currently authenticated user straight from
  /// Supabase, falling back to the copy stored on this device when the read
  /// fails (offline). Returns an error result when there is no active session.
  static Future<DisplayNameResult> fetchDisplayName() async {
    final userId = AuthService.userId;
    if (userId == null) {
      return const DisplayNameResult(error: 'Your session has expired.');
    }

    final result = await UserProfileService.getDisplayName(userId);
    if (result.success) {
      await UserProfileStore.saveDisplayName(result.displayName);
      return result;
    }

    // The request failed — serve the on-device copy so the home screen still
    // greets the user by name instead of showing a generic error.
    final cached = await UserProfileStore.load(userId: userId);
    if (cached != null) {
      return DisplayNameResult(displayName: cached.displayName);
    }
    return result;
  }

  /// Updates the nickname of the currently authenticated user directly in
  /// Supabase (same 10-character rule as the website) and mirrors it locally.
  static Future<AuthResult> updateDisplayName(String name) async {
    final userId = AuthService.userId;
    if (userId == null) {
      return const AuthResult(success: false, error: 'Your session has expired.');
    }

    final error = await UserProfileService.setDisplayName(
      userId,
      name,
      email: AuthService.userEmail,
    );
    if (error != null) {
      return AuthResult(success: false, error: error);
    }

    await UserProfileStore.saveDisplayName(name);
    return const AuthResult(success: true);
  }

  // ===== Account profile cache =====
  /// Persists which account the device is signed in as. Called after every
  /// successful authentication so the cache always belongs to the live session.
  static Future<void> rememberAccount({String? userId, String? email}) async {
    await UserProfileStore.saveIdentity(userId: userId, email: email);
  }

  /// Refreshes the on-device display name and plan from the server.
  ///
  /// Both values are cached, so the next cold start can render the greeting and
  /// the plan badge before any network call. Never throws: a failure leaves the
  /// previous cache in place.
  static Future<void> refreshProfileCache() async {
    if (AuthService.userId == null) return;
    await fetchDisplayName();
    await getPlanStatus();
  }

  // ===== Plan Status =====
  /// Resolves ADMIN/PRO/FREE for the top-bar badge. Returns guest status
  /// when nobody is signed in.
  ///
  /// Falls back to the plan last seen on this device when the profile cannot be
  /// read, so a paying user is never shown FREE just for being offline.
  static Future<PlanStatus> getPlanStatus() async {
    final userId = AuthService.userId;
    final email = AuthService.userEmail;
    if (userId == null) return PlanStatus.guest;

    final remote = await UserProfileService.readPlanStatus(userId, email);
    if (remote != null) {
      await UserProfileStore.savePlan(remote);
      return remote;
    }

    final cached = await UserProfileStore.load(userId: userId);
    if (cached != null) return cached.plan;

    return UserProfileService.isAdminEmail(email)
        ? const PlanStatus(plan: 'admin', isAdmin: true, isPro: true)
        : PlanStatus.free;
  }

  // ===== Routing helper =====
  /// The screen a freshly signed-in account belongs on: the name prompt while
  /// the account has no display name yet, otherwise the home screen.
  static Future<String> postAuthRoute() async {
    final profile = await fetchDisplayName();
    if (!profile.success) return '/home';
    return profile.hasDisplayName ? '/home' : '/onboarding';
  }

  /// True only when Supabase positively confirmed the account has no display
  /// name.
  ///
  /// Deliberately stricter than [fetchDisplayName], which falls back to the
  /// on-device copy when the read fails: an offline read must not be mistaken
  /// for "this account has no name", because the name prompt needs the network
  /// to save and would trap the user on it.
  static Future<bool> confirmedNoDisplayName() async {
    final userId = AuthService.userId;
    if (userId == null || userId.isEmpty) return false;

    final result = await UserProfileService.getDisplayName(userId);
    if (!result.success) return false;

    // Keep the cache in step with the value the server just confirmed.
    await UserProfileStore.saveDisplayName(result.displayName);
    return !result.hasDisplayName;
  }

  /// The screen a cold start belongs on.
  ///
  /// A restored session alone is not enough to land on the home screen: an
  /// account whose display name never reached Supabase (the sign-up prompt was
  /// never completed, or the write failed) still has to be asked for one, which
  /// is what [confirmedNoDisplayName] detects. An unverifiable read behaves
  /// exactly like before and goes home.
  static Future<String> startupRoute() async {
    if (!AuthService.isLoggedIn) return '/';
    return await confirmedNoDisplayName() ? '/onboarding' : '/home';
  }

  // ===== Helpers =====
  static Future<void> _saveSession(
    Map<String, dynamic> session,
    Map<String, dynamic>? user,
  ) async {
    await AuthService.saveSession(
      accessToken: session['access_token'],
      refreshToken: session['refresh_token'],
      expiresAt: session['expires_at'],
      userId: user?['id'],
      userEmail: user?['email'],
    );
  }

  static bool _isInvalidCredentials(AuthApiException e) =>
      (e.code?.toLowerCase() == 'invalid_credentials') ||
      e.message.toLowerCase().contains('invalid login credentials');

  static bool _isEmailNotConfirmed(AuthApiException e) =>
      (e.code?.toLowerCase() == 'email_not_confirmed') ||
      e.message.toLowerCase().contains('email not confirmed');

  static bool _isAlreadyRegistered(AuthApiException e) =>
      (e.code?.toLowerCase() == 'user_already_exists') ||
      e.message.toLowerCase().contains('already registered');
}
