import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_core/core/user/UserProfileService.dart';

/// Snapshot of the signed-in account, as last seen on this device.
///
/// Everything the home screen needs to greet the user and to show the right
/// plan badge lives here, so a cold start can render correctly before (or
/// without) a single network call.
class CachedUserProfile {
  final String userId;
  final String? email;
  final String? displayName;
  final PlanStatus plan;

  const CachedUserProfile({
    required this.userId,
    this.email,
    this.displayName,
    required this.plan,
  });

  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  CachedUserProfile copyWith({
    String? email,
    String? displayName,
    PlanStatus? plan,
  }) {
    return CachedUserProfile(
      userId: userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      plan: plan ?? this.plan,
    );
  }
}

/// Device-local mirror of the signed-in account.
///
/// Supabase already persists the session (so the user is not asked to sign in
/// again), but the profile itself — display name and plan — otherwise costs a
/// network round trip on every launch. Keeping a copy in SharedPreferences
/// means:
///
///   * the home screen shows the real name and plan on the very first frame,
///   * the app still behaves correctly offline or on a flaky connection,
///   * a paying user is never downgraded to FREE just because a request failed.
///
/// The remote row stays authoritative: every successful read overwrites the
/// copy, and switching accounts wipes the previous account's data so one
/// user's name can never leak into another's session.
class UserProfileStore {
  static const String _kUserIdKey = 'account_user_id';
  static const String _kEmailKey = 'account_email';
  static const String _kDisplayNameKey = 'account_display_name';
  static const String _kPlanKey = 'account_plan';
  static const String _kPlanAdminKey = 'account_plan_is_admin';
  static const String _kPlanProKey = 'account_plan_is_pro';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Records which account the cached data belongs to. Called on every
  /// successful sign-in/sign-up so the cache can never be attributed to the
  /// wrong user; a different id drops the previous account's profile first.
  static Future<void> saveIdentity({String? userId, String? email}) async {
    if (userId == null || userId.isEmpty) return;
    await init();

    if (_prefs!.getString(_kUserIdKey) != userId) {
      await _prefs!.remove(_kDisplayNameKey);
      await _prefs!.remove(_kPlanKey);
      await _prefs!.remove(_kPlanAdminKey);
      await _prefs!.remove(_kPlanProKey);
    }

    await _prefs!.setString(_kUserIdKey, userId);
    if (email != null && email.isNotEmpty) {
      await _prefs!.setString(_kEmailKey, email);
    }
  }

  /// Mirrors the display name. A null/empty name clears the stored value, so
  /// clearing the name in the app also clears it here.
  static Future<void> saveDisplayName(String? name) async {
    await init();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) {
      await _prefs!.remove(_kDisplayNameKey);
      return;
    }
    await _prefs!.setString(_kDisplayNameKey, trimmed);
  }

  static Future<void> savePlan(PlanStatus plan) async {
    await init();
    await _prefs!.setString(_kPlanKey, plan.plan);
    await _prefs!.setBool(_kPlanAdminKey, plan.isAdmin);
    await _prefs!.setBool(_kPlanProKey, plan.isPro);
  }

  /// The cached profile, or null when the device has none.
  ///
  /// Pass [userId] to get it only when it belongs to that account — the guard
  /// the UI uses so a stale cache is never shown for a different session.
  static Future<CachedUserProfile?> load({String? userId}) async {
    await init();

    final storedUserId = _prefs!.getString(_kUserIdKey);
    if (storedUserId == null || storedUserId.isEmpty) return null;
    if (userId != null && userId.isNotEmpty && storedUserId != userId) {
      return null;
    }

    final planName = _prefs!.getString(_kPlanKey) ?? 'free';
    final isAdmin = _prefs!.getBool(_kPlanAdminKey) ?? false;
    final isPro = _prefs!.getBool(_kPlanProKey) ??
        (isAdmin || UserProfileService.premiumPlans.contains(planName));

    return CachedUserProfile(
      userId: storedUserId,
      email: _prefs!.getString(_kEmailKey),
      displayName: _prefs!.getString(_kDisplayNameKey),
      plan: PlanStatus(plan: planName, isAdmin: isAdmin, isPro: isPro),
    );
  }

  /// Wipes everything — used when signing out, or when Supabase rejects the
  /// stored session and the account has to sign in again.
  static Future<void> clear() async {
    await init();
    await _prefs!.remove(_kUserIdKey);
    await _prefs!.remove(_kEmailKey);
    await _prefs!.remove(_kDisplayNameKey);
    await _prefs!.remove(_kPlanKey);
    await _prefs!.remove(_kPlanAdminKey);
    await _prefs!.remove(_kPlanProKey);
  }
}
