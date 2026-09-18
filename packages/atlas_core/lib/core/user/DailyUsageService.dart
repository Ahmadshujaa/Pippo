import 'package:mongo_dart/mongo_dart.dart';

import 'package:atlas_core/core/auth/AuthService.dart';
import 'package:atlas_core/core/integrations/MongoService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';
import 'package:atlas_core/core/user/UserProfileService.dart';
import 'package:atlas_core/core/user/UserProfileStore.dart';

/// The limits that apply to the daily activity counters.
class DailyUsageLimits {
  static const int freePuzzles = 5;
  static const int freeGameReviews = 1;
  static const int proGameReviews = 10;
}

/// A user's counters for the current local calendar day.
class DailyUsage {
  final String email;
  final String day;
  final int puzzlesDone;
  final int gameReviewsDone;

  const DailyUsage({
    required this.email,
    required this.day,
    required this.puzzlesDone,
    required this.gameReviewsDone,
  });

  static DailyUsage empty(String email, String day) => DailyUsage(
        email: email,
        day: day,
        puzzlesDone: 0,
        gameReviewsDone: 0,
      );
}

/// MongoDB-backed daily usage and entitlement helpers.
///
/// Supabase remains authoritative for the plan. Only the usage counters live
/// here, so no daily activity is written to `profiles`.
class DailyUsageService {
  static const String collectionName = 'user_data';
  static const String _resetMarkerId = '__daily_usage_reset__';

  static Future<void>? _resetAttempt;
  static String? _preparedDay;

  /// Runs the global reset used by the app-start day hook. The marker is
  /// advanced before stale user documents are removed, so two devices racing
  /// to open the app on a new day cannot delete documents from the new day.
  static Future<void> resetIfNewDay() async {
    // The reset advances a shared marker and prunes other days' counters, so it
    // writes shared data. A device with no account must not write anything to
    // MongoDB at all: it skips the reset and the next signed-in launch runs it.
    if (!MongoService.canWrite) {
      AppLogger.debug('[DailyUsageService] Daily reset skipped: no signed-in user.');
      return;
    }

    final today = _today;
    if (_preparedDay == today) return;

    final active = _resetAttempt;
    if (active != null) {
      await active;
      return;
    }

    final attempt = _reset(today);
    _resetAttempt = attempt;
    try {
      await attempt;
      _preparedDay = today;
    } finally {
      if (identical(_resetAttempt, attempt)) _resetAttempt = null;
    }
  }

  static Future<void> _reset(String today) async {
    try {
      // `withSignedInRetry`: the marker upsert and the stale-document delete are
      // shared writes, so a signed-out device is refused here as well.
      await MongoService.withSignedInRetry(() async {
        final coll = await MongoService.collection(collectionName);
        final marker = await coll.findOne(where.eq('_id', _resetMarkerId));
        if (marker?['day'] == today) {
          // Retry cleanup if a previous launch advanced the marker but lost
          // its connection before the stale-document delete completed.
          await coll.remove(where.ne('day', today));
          return;
        }

        await coll.updateOne(
          where.eq('_id', _resetMarkerId),
          <String, dynamic>{
            r'$set': {
              'email': _resetMarkerId,
              'day': today,
              'puzzles_done': 0,
              'game_reviews_done': 0,
              'is_reset_marker': true,
            },
          },
          upsert: true,
        );

        // The marker now has today's day, so this cannot remove current-day
        // documents even if another device performs the same reset in parallel.
        await coll.remove(where.ne('day', today));
      });
    } catch (e) {
      // Feature operations retry through MongoService themselves. A failed
      // startup reset must not stop the app from opening while offline.
      AppLogger.warn('[DailyUsageService] Daily reset skipped: $e');
      rethrow;
    }
  }

  /// Resolves the current plan, retaining the cached entitlement when the
  /// profile request is temporarily unavailable.
  static Future<PlanStatus> currentPlanStatus() async {
    final userId = AuthService.userId;
    final email = AuthService.userEmail;

    if (userId != null && userId.isNotEmpty) {
      final remote = await UserProfileService.readPlanStatus(userId, email);
      if (remote != null) {
        await UserProfileStore.savePlan(remote);
        return remote;
      }

      final cached = await UserProfileStore.load(userId: userId);
      if (cached != null) return cached.plan;
    }

    return UserProfileService.isAdminEmail(email)
        ? const PlanStatus(plan: 'admin', isAdmin: true, isPro: true)
        : PlanStatus.free;
  }

  /// Returns the current user's usage. Null means there is no signed-in email
  /// or MongoDB could not be reached.
  static Future<DailyUsage?> getUsage() async {
    final email = await _currentEmail();
    if (email == null) return null;

    try {
      await resetIfNewDay();
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(collectionName);
        final doc = await coll.findOne(
          where.eq('email', email).eq('day', _today),
        );
        if (doc == null) return DailyUsage.empty(email, _today);
        return _fromDocument(email, _today, doc);
      });
    } catch (e) {
      AppLogger.warn('[DailyUsageService] Usage read failed: $e');
      return null;
    }
  }

  /// Returns whether a review may start. This is only a preflight check;
  /// [recordGameReview] is called after the review result is successfully
  /// received, so abandoned or failed reviews do not consume usage.
  static Future<bool> canStartGameReview() async {
    final email = await _currentEmail();
    if (email == null) return false;

    final plan = await currentPlanStatus();
    final usage = await getUsage();
    if (usage == null) return false;
    if (plan.isAdmin) return true;
    final limit = plan.isPro
        ? DailyUsageLimits.proGameReviews
        : DailyUsageLimits.freeGameReviews;
    return usage.gameReviewsDone < limit;
  }

  /// Atomically records one successfully received game review. The limit is
  /// checked again in the update itself so a second device cannot increment a
  /// free/pro account beyond its allowance.
  static Future<bool> recordGameReview() async {
    final email = await _currentEmail();
    if (email == null) return false;

    final plan = await currentPlanStatus();
    final limit = plan.isAdmin
        ? null
        : (plan.isPro
            ? DailyUsageLimits.proGameReviews
            : DailyUsageLimits.freeGameReviews);

    try {
      await _ensureUserDocument(email);
      // A signed-out device never writes a counter, even if it somehow reaches
      // this path (the email lookup above already requires an account).
      return await MongoService.withSignedInRetry(
            () async {
              final coll = await MongoService.collection(collectionName);
              final selector = where.eq('email', email).eq('day', _today);
              final limitedSelector = limit == null
                  ? selector
                  : selector.lt('game_reviews_done', limit);
              final result = await coll.updateOne(
                limitedSelector,
                modify.inc('game_reviews_done', 1),
              );
              return result.nMatched > 0 && result.nModified > 0;
            },
            label: 'recordGameReview',
          ) ??
          false;
    } catch (e) {
      AppLogger.warn('[DailyUsageService] Game-review record failed: $e');
      return false;
    }
  }

  /// Checks whether a free user can start a puzzle. Pro and admin users are
  /// unlimited and do not need a counter read to start.
  static Future<bool> canStartPuzzle(PlanStatus plan) async {
    if (plan.isPro) return true;
    final usage = await getUsage();
    return usage != null && usage.puzzlesDone < DailyUsageLimits.freePuzzles;
  }

  /// Records a successfully completed puzzle. For free users the increment is
  /// conditional, so the counter can never exceed five due to a race.
  static Future<bool> recordPuzzleSolved(PlanStatus plan) async {
    final email = await _currentEmail();
    if (email == null) return false;

    try {
      await _ensureUserDocument(email);
      // A signed-out device never writes a counter, even if it somehow reaches
      // this path (the email lookup above already requires an account).
      return await MongoService.withSignedInRetry(
            () async {
              final coll = await MongoService.collection(collectionName);
              final selector = where.eq('email', email).eq('day', _today);
              final limitedSelector = plan.isPro
                  ? selector
                  : selector.lt('puzzles_done', DailyUsageLimits.freePuzzles);
              final result = await coll.updateOne(
                limitedSelector,
                modify.inc('puzzles_done', 1),
              );
              return result.nMatched > 0 && result.nModified > 0;
            },
            label: 'recordPuzzleSolved',
          ) ??
          false;
    } catch (e) {
      AppLogger.warn('[DailyUsageService] Puzzle counter update failed: $e');
      return false;
    }
  }

  /// Computes how many new Turso puzzles may be fetched for a free user.
  /// [unsolvedLocalCount] must include all unique unsolved Turso puzzles held
  /// by the app, across mixed and every themed batch.
  static Future<int> tursoFetchCount({
    required PlanStatus plan,
    required int requested,
    required int unsolvedLocalCount,
  }) async {
    if (plan.isPro) return requested;
    final usage = await getUsage();
    if (usage == null) return 0;
    final remaining = DailyUsageLimits.freePuzzles - usage.puzzlesDone;
    return (remaining - unsolvedLocalCount).clamp(0, requested).toInt();
  }

  static Future<void> _ensureUserDocument(String email) async {
    await resetIfNewDay();
    final documentId = 'user:${email}_$_today';
    await MongoService.withSignedInRetry(() async {
      final coll = await MongoService.collection(collectionName);
      await coll.updateOne(
        where.eq('_id', documentId),
        <String, dynamic>{
          r'$setOnInsert': {
            '_id': documentId,
            'email': email,
            'day': _today,
            'puzzles_done': 0,
            'game_reviews_done': 0,
          },
        },
        upsert: true,
      );
    });
  }

  static Future<String?> _currentEmail() async {
    final direct = AuthService.userEmail?.trim().toLowerCase();
    if (direct != null && direct.isNotEmpty) return direct;

    final cached = await UserProfileStore.load(userId: AuthService.userId);
    final email = cached?.email?.trim().toLowerCase();
    return email == null || email.isEmpty ? null : email;
  }

  static DailyUsage _fromDocument(
    String email,
    String day,
    Map<String, dynamic> doc,
  ) {
    int value(String key) => (doc[key] as num?)?.toInt() ?? 0;
    return DailyUsage(
      email: email,
      day: day,
      puzzlesDone: value('puzzles_done'),
      gameReviewsDone: value('game_reviews_done'),
    );
  }

  static String get _today {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
