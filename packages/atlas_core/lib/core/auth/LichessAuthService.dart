import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Lichess OAuth2 (Authorization Code + PKCE) — fully client-side.
///
/// Lichess supports public clients: `client_id` is just an arbitrary
/// identifier (no secret needed) and custom schemes like
/// `com.atlaschess.app://` are allowed as redirect URIs.
/// See https://lichess.org/api#tag/OAuth
///
/// The opening explorer API accepts any valid Lichess token, so no OAuth
/// scopes are requested. Tokens last ~1 year; they are persisted on the
/// device (SharedPreferences) so the user only signs in once.
class LichessAuthService {
  LichessAuthService._();

  static final LichessAuthService instance = LichessAuthService._();

  static const String _authorizeUrl = 'https://lichess.org/oauth';
  static const String _tokenUrl = 'https://lichess.org/api/token';

  /// Arbitrary unique identifier for this application (public client).
  static const String clientId = 'atlaschess.app';

  /// Custom scheme redirect URI — must contain a dot (Lichess requirement)
  /// and must be registered in the Android manifest intent filter.
  static const String redirectUri = 'com.atlaschess.app://oauth';
  static const String callbackScheme = 'com.atlaschess.app';

  static const String _prefsTokenKey = 'lichess_oauth_token';
  static const String _prefsExpiryKey = 'lichess_oauth_expires_at';

  String? _token;
  DateTime? _expiresAt;

  /// Whether a valid (non-expired) token is stored on this device.
  bool get isSignedIn =>
      _token != null &&
      _token!.isNotEmpty &&
      _expiresAt != null &&
      DateTime.now().isBefore(_expiresAt!);

  /// The current bearer token, or null when signed out/expired.
  String? get token => isSignedIn ? _token : null;

  /// Load the persisted token from SharedPreferences.
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_prefsTokenKey);
    final expiryMillis = prefs.getInt(_prefsExpiryKey);
    _expiresAt = expiryMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(expiryMillis)
        : null;
  }

  /// Runs the full OAuth flow (browser → authorize → redirect → token
  /// exchange) and persists the token on the device.
  ///
  /// Throws on cancellation or failure; returns true on success.
  Future<bool> signIn() async {
    final verifier = _generateVerifier();
    final state = _generateState();
    final challenge = _codeChallenge(verifier);

    final url = Uri.parse(_authorizeUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_challenge_method': 'S256',
        'code_challenge': challenge,
        'state': state,
      },
    );

    // Opens the Lichess sign-in page in a browser tab; returns the full
    // redirect URL (e.g. com.atlaschess.app://oauth?code=...&state=...).
    final result = await FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackScheme,
    );

    final callbackUri = Uri.parse(result);

    // CSRF check: state must match what we sent.
    if (callbackUri.queryParameters['state'] != state) {
      throw Exception('OAuth state mismatch');
    }

    final error = callbackUri.queryParameters['error'];
    if (error != null) {
      throw Exception('Lichess authorization failed: $error');
    }

    final code = callbackUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw Exception('No authorization code returned');
    }

    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {'Accept': 'application/json'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': verifier,
        'redirect_uri': redirectUri,
        'client_id': clientId,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Token exchange failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = json['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Token exchange returned no access token');
    }
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 31536000;
    _token = accessToken;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTokenKey, _token!);
    await prefs.setInt(_prefsExpiryKey, _expiresAt!.millisecondsSinceEpoch);
    return true;
  }

  /// Revokes the token on Lichess (best effort) and clears local storage.
  Future<void> signOut() async {
    final current = _token;
    _token = null;
    _expiresAt = null;
    if (current != null) {
      try {
        await http.delete(
          Uri.parse(_tokenUrl),
          headers: {'Authorization': 'Bearer $current'},
        );
      } catch (_) {
        // Revocation is best effort — ignore failures.
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsExpiryKey);
  }

  // --- PKCE helpers ---

  static const String _verifierChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  String _generateVerifier() {
    final random = Random.secure();
    return List.generate(
      64,
      (_) => _verifierChars[random.nextInt(_verifierChars.length)],
    ).join();
  }

  String _generateState() {
    final random = Random.secure();
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(32, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// BASE64URL(SHA256(verifier)) without padding.
  String _codeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier)).bytes;
    return base64UrlEncode(digest).replaceAll('=', '');
  }
}
