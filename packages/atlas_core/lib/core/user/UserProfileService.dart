import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atlas_core/core/logging/AppLogger.dart';

/// Result wrapper for display-name lookups.
class DisplayNameResult {
  final String? displayName;
  final String? error;

  const DisplayNameResult({this.displayName, this.error});
  bool get success => error == null;
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;
}

/// The user's plan status as shown in the app UI.
class PlanStatus {
  final String plan;
  final bool isAdmin;
  final bool isPro;

  const PlanStatus({
    required this.plan,
    required this.isAdmin,
    required this.isPro,
  });

  static const PlanStatus guest = PlanStatus(
    plan: 'free',
    isAdmin: false,
    isPro: false,
  );

  /// A signed-in account with no premium entitlement.
  static const PlanStatus free = PlanStatus(
    plan: 'free',
    isAdmin: false,
    isPro: false,
  );
}

/// User profile storage on Supabase Postgres (public.profiles), migrated
/// from the MongoDB `users` collection.
///
/// Security model:
/// - RLS: each account can only read/write its OWN row.
/// - Column grants: clients can update only email/name/xp/current_streak/
///   puzzle_rating/last_seen. The plan/billing columns reject client writes at
///   the database level; only the service-role key (website) may change them.
class UserProfileService {
  /// Same domain whitelist the website enforces at signup.
  static const List<String> allowedEmailDomains = [
    '@gmail.com',
    '@googlemail.com',
    '@users.noreply.github.com',
  ];

  /// Premium plan tiers mirrored from the website's plans config.
  static const Set<String> premiumPlans = {'pro', 'referral', 'lifetime'};

  static bool isAllowedEmailDomain(String emailLower) =>
      allowedEmailDomains.any((d) => emailLower.endsWith(d));

  static bool isStrongEnoughPassword(String password) =>
      password.length >= 8 &&
      password.contains(RegExp(r'[A-Z]')) &&
      password.contains(RegExp(r'[a-z]')) &&
      password.contains(RegExp(r'[0-9]'));

  static List<String> get _adminEmails => (dotenv.env['ADMIN_EMAILS'] ?? '')
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  static bool isAdminEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return _adminEmails.contains(email.toLowerCase());
  }

  static SupabaseClient get _client => Supabase.instance.client;

  static String get _nowIso => DateTime.now().toUtc().toIso8601String();

  /// Applies a safe column update to the user's own profile row.
  /// Returns false when the row does not exist yet.
  static Future<bool> _applyOwnUpdate(
    String userId,
    Map<String, dynamic> values,
  ) async {
    try {
      final rows = await _client
          .from('profiles')
          .update({...values, 'updated_at': _nowIso})
          .eq('id', userId)
          .select('id');
      return rows.isNotEmpty;
    } catch (e) {
      AppLogger.error('[UserProfileService] update error: $e');
      rethrow;
    }
  }

  /// Port of the website's `ensureUserDocument`.
  /// The Supabase trigger `on_auth_user_created` normally creates the row
  /// automatically at signup; this refreshes email/last_seen and creates
  /// the row as a fallback (e.g. accounts that predate the trigger).
  static Future<void> ensureUserDocument(String userId, String email) async {
    if (userId.isEmpty || userId.startsWith('guest_')) return;

    final emailLower = email.toLowerCase().trim();
    if (!isAllowedEmailDomain(emailLower)) return;

    try {
      final updated = await _applyOwnUpdate(userId, {
        'email': emailLower,
        'last_seen': _nowIso,
      });
      if (!updated) {
        await _client.from('profiles').insert({
          'id': userId,
          'email': emailLower,
        });
      }
    } catch (e) {
      AppLogger.error('[UserProfileService] ensureUserDocument error: $e');
    }
  }

  /// Updates last_seen on an existing sign-in (port of signin upsert).
  static Future<void> touchLastSeen(String userId, String emailLower) async {
    try {
      final updated = await _applyOwnUpdate(userId, {'last_seen': _nowIso});
      if (!updated) {
        await _client.from('profiles').insert({
          'id': userId,
          'email': emailLower,
        });
      }
    } catch (e) {
      AppLogger.error('[UserProfileService] touchLastSeen error: $e');
    }
  }

  /// Port of GET /api/user/display-name.
  static Future<DisplayNameResult> getDisplayName(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      return DisplayNameResult(displayName: row?['name'] as String?);
    } catch (e) {
      AppLogger.error('[UserProfileService] getDisplayName error: $e');
      return const DisplayNameResult(
        error: 'Could not load your AtlasChess profile.',
      );
    }
  }

  /// Port of POST /api/user/display-name. Returns null on success or an
  /// error message mirroring the website's validation rules.
  static Future<String?> setDisplayName(
    String userId,
    String name, {
    String? email,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Invalid name';
    if (trimmed.length > 10) {
      return 'Name must be 10 characters or less';
    }

    try {
      final updated = await _applyOwnUpdate(userId, {'name': trimmed});
      if (!updated) {
        await _client.from('profiles').insert({
          'id': userId,
          'name': trimmed,
          if (email != null && email.isNotEmpty) 'email': email.toLowerCase(),
        });
      }
      return null;
    } catch (e) {
      AppLogger.error('[UserProfileService] setDisplayName error: $e');
      return 'Could not save your name.';
    }
  }

  /// Reads the account's mirrored puzzle rating (`profiles.puzzle_rating`).
  /// Returns null when there is no usable server value — the column is still
  /// 0 (never synced), the row is missing, or the request failed — so callers
  /// keep the device-local rating.
  static Future<int?> getPuzzleRating(String userId) async {
    if (userId.isEmpty || userId.startsWith('guest_')) return null;

    try {
      final row = await _client
          .from('profiles')
          .select('puzzle_rating')
          .eq('id', userId)
          .maybeSingle();
      final value = (row?['puzzle_rating'] as num?)?.toInt();
      if (value == null || value <= 0) return null;
      return value;
    } catch (e) {
      AppLogger.error('[UserProfileService] getPuzzleRating error: $e');
      return null;
    }
  }

  /// Mirrors [rating] onto the user's own profile row. Best-effort: the device
  /// copy stays authoritative and play never waits on the network, so failures
  /// are logged and swallowed.
  static Future<void> setPuzzleRating(String userId, int rating) async {
    if (userId.isEmpty || userId.startsWith('guest_')) return;

    try {
      await _applyOwnUpdate(userId, {'puzzle_rating': rating});
    } catch (e) {
      AppLogger.error('[UserProfileService] setPuzzleRating error: $e');
    }
  }

  /// Resolves the effective plan for the badge. Expired premium plans are
  /// downgraded at READ time — the write-side downgrade belongs to the
  /// website's service-role logic, since clients cannot edit `plan`.
  ///
  /// Never fails: an unreadable row is reported as FREE. Callers that need to
  /// tell "free" apart from "could not read" should use [readPlanStatus].
  static Future<PlanStatus> getPlanStatus(String userId, String? email) async {
    return await readPlanStatus(userId, email) ??
        (isAdminEmail(email)
            ? const PlanStatus(plan: 'admin', isAdmin: true, isPro: true)
            : PlanStatus.free);
  }

  /// Like [getPlanStatus] but returns null when the profile could not be read
  /// at all (offline, request failed), so callers can fall back to the
  /// on-device copy instead of silently downgrading a paying account.
  static Future<PlanStatus?> readPlanStatus(
    String userId,
    String? email,
  ) async {
    final admin = isAdminEmail(email);
    var plan = 'free';

    try {
      final row = await _client
          .from('profiles')
          .select('plan, pro_expires')
          .eq('id', userId)
          .maybeSingle();

      if (row != null) {
        plan = (row['plan'] as String?) ?? 'free';
        final proExpiresRaw = row['pro_expires'];
        DateTime? proExpires;
        if (proExpiresRaw is String && proExpiresRaw.isNotEmpty) {
          proExpires = DateTime.tryParse(proExpiresRaw);
        }
        final isPremium = premiumPlans.contains(plan);
        final isActivePremium = isPremium &&
            (proExpires == null || proExpires.isAfter(DateTime.now()));

        plan = isActivePremium ? plan : 'free';
      }
    } catch (e) {
      AppLogger.error('[UserProfileService] readPlanStatus error: $e');
      return null;
    }

    if (admin) plan = 'admin';
    final isPro = admin || premiumPlans.contains(plan);

    return PlanStatus(plan: plan, isAdmin: admin, isPro: isPro);
  }
}
