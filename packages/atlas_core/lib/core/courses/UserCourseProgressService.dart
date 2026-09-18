import 'package:mongo_dart/mongo_dart.dart';

import 'package:atlas_core/core/auth/AuthService.dart';
import 'package:atlas_core/core/integrations/MongoService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';
import 'package:atlas_core/core/user/DailyUsageService.dart';
import 'package:atlas_core/core/user/UserProfileStore.dart';

DateTime? _courseProgressDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

/// A completed variation. Incomplete variations are kept in the chapter's
/// `active_variations` array and are promoted here only after the main line
/// and every branch are complete.
class CompletedCourseVariation {
  final int index;
  final String name;
  final DateTime? startedAt;
  final DateTime? mainLineCompletedAt;
  final DateTime? branchesCompletedAt;
  final DateTime? completedAt;

  const CompletedCourseVariation({
    required this.index,
    required this.name,
    this.startedAt,
    this.mainLineCompletedAt,
    this.branchesCompletedAt,
    this.completedAt,
  });

  factory CompletedCourseVariation.fromJson(Map<String, dynamic> json) =>
      CompletedCourseVariation(
        index: (json['variation_index'] as num?)?.toInt() ?? 0,
        name: json['variation_name']?.toString() ?? '',
        startedAt: _courseProgressDate(json['started_at']),
        mainLineCompletedAt: _courseProgressDate(json['main_line_completed_at']),
        branchesCompletedAt: _courseProgressDate(json['branches_completed_at']),
        completedAt: _courseProgressDate(json['completed_at']),
      );
}

class UserChapterProgress {
  final int index;
  final String name;
  final DateTime? startedAt;
  final String status;
  final DateTime? testCompletedAt;
  final List<CompletedCourseVariation> variations;

  const UserChapterProgress({
    required this.index,
    required this.name,
    required this.startedAt,
    required this.status,
    required this.testCompletedAt,
    required this.variations,
  });

  bool get isCompleted => status == 'completed';
  int get completedVariationCount => variations.length;

  factory UserChapterProgress.fromJson(Map<String, dynamic> json) =>
      UserChapterProgress(
        index: (json['chapter_index'] as num?)?.toInt() ?? 0,
        name: json['chapter_name']?.toString() ?? '',
        startedAt: _courseProgressDate(json['started_at']),
        status: json['status']?.toString() ?? 'not_completed',
        testCompletedAt: _courseProgressDate(json['test_completed_at']),
        variations: (json['variations'] as List? ?? [])
            .whereType<Map>()
            .map((v) => CompletedCourseVariation.fromJson(
                  Map<String, dynamic>.from(v),
                ))
            .toList(),
      );
}

class UserCourseProgress {
  final String slug;
  final String name;
  final DateTime? startedAt;
  final List<UserChapterProgress> chapters;

  const UserCourseProgress({
    required this.slug,
    required this.name,
    required this.startedAt,
    required this.chapters,
  });

  int get completedVariationCount =>
      chapters.fold(0, (total, chapter) => total + chapter.completedVariationCount);

  bool get hasStarted => chapters.isNotEmpty;

  factory UserCourseProgress.fromJson(Map<String, dynamic> json) =>
      UserCourseProgress(
        slug: json['course_slug']?.toString() ?? '',
        name: json['course_name']?.toString() ?? '',
        startedAt: _courseProgressDate(json['started_at']),
        chapters: (json['chapters'] as List? ?? [])
            .whereType<Map>()
            .map((c) => UserChapterProgress.fromJson(
                  Map<String, dynamic>.from(c),
                ))
            .toList(),
      );
}

class UserCourseProgressSnapshot {
  final List<UserCourseProgress> courses;
  final DateTime? lastChapterUnlockAt;

  const UserCourseProgressSnapshot({
    required this.courses,
    this.lastChapterUnlockAt,
  });

  UserCourseProgress? forCourse(String slug) {
    for (final course in courses) {
      if (course.slug == slug) return course;
    }
    return null;
  }
}

/// Persists one compact progress document per account in `user_course`.
///
/// Completed progress is intentionally compact:
/// `courses[] -> chapters[] -> variations[]`. A chapter also has a short-lived
/// `active_variations[]` section for interrupted work. Once its main line and
/// every branch are done, that entry is moved into `variations[]` with the
/// exact completion timestamps. Test completion is independent and controls
/// the chapter's status.
class UserCourseProgressService {
  static const String collectionName = 'user_course';

  static Future<UserCourseProgressSnapshot> getProgress() async {
    final email = await _email();
    if (email == null) return const UserCourseProgressSnapshot(courses: []);

    try {
      final doc = await MongoService.withRetry(() async {
        final coll = await MongoService.collection(collectionName);
        return coll.findOne(where.eq('email', email));
      });
      if (doc == null) return const UserCourseProgressSnapshot(courses: []);
      return _snapshot(doc);
    } catch (e) {
      AppLogger.warn('[UserCourseProgressService] Progress read failed: $e');
      return const UserCourseProgressSnapshot(courses: []);
    }
  }

  /// Starts a chapter if it has not been started before. Existing chapters
  /// are always resumable and do not consume another daily unlock.
  static Future<bool> startChapter({
    required String courseSlug,
    required String courseName,
    required int chapterIndex,
    required String chapterName,
  }) async {
    final email = await _email();
    if (email == null) return false;

    try {
      final raw = await _read(email);
      final courses = _courses(raw);
      final course = _findCourse(courses, courseSlug);
      final existingChapter = course == null
          ? null
          : _findChapter(_chapters(course), chapterIndex);
      if (existingChapter != null) return true;

      final plan = await DailyUsageService.currentPlanStatus();
      final startedIndexes = course == null
          ? <int>[]
          : _chapters(course)
              .map((chapter) => (chapter['chapter_index'] as num?)?.toInt() ?? 0)
              .toList();
      final highestStarted = startedIndexes.isEmpty
          ? -1
          : startedIndexes.reduce((a, b) => a > b ? a : b);

      // Free users may only unlock the next sequential chapter. Pro/admin
      // users can start any chapter and still get the same progress record.
      if (!plan.isPro && chapterIndex > highestStarted + 1) return false;

      final now = DateTime.now();
      final lastUnlock = _date(raw['last_chapter_unlock_at']);
      if (!plan.isPro &&
          lastUnlock != null &&
          _dayStamp(lastUnlock.toLocal()) == _dayStamp(now)) {
        return false;
      }

      final courseDoc = course ?? <String, dynamic>{
        'course_slug': courseSlug,
        'course_name': courseName,
        'started_at': now.toUtc().toIso8601String(),
        'chapters': <Map<String, dynamic>>[],
      };
      final chapterDoc = <String, dynamic>{
        'chapter_index': chapterIndex,
        'chapter_name': chapterName,
        'started_at': now.toUtc().toIso8601String(),
        'status': 'not_completed',
        'variations': <Map<String, dynamic>>[],
        'active_variations': <Map<String, dynamic>>[],
      };
      final chapterList = _chapters(courseDoc);
      chapterList.add(chapterDoc);
      courseDoc['chapters'] = chapterList;
      if (course == null) courses.add(courseDoc);
      raw['courses'] = courses;
      // Keep the exact timestamp for every plan. The free-user rule is the
      // only code path that reads it as a restriction.
      raw['last_chapter_unlock_at'] = now.toUtc().toIso8601String();
      await _write(email, raw);
      return true;
    } catch (e) {
      AppLogger.warn('[UserCourseProgressService] Chapter start failed: $e');
      return false;
    }
  }

  static Future<void> startVariation({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
    required String variationName,
  }) async {
    await _mutateChapter(courseSlug, chapterIndex, (course, chapter) {
      final active = _activeVariations(chapter);
      final existing = active.any((v) =>
          (v['variation_index'] as num?)?.toInt() == variationIndex);
      if (!existing) {
        active.add({
          'variation_index': variationIndex,
          'variation_name': variationName,
          'started_at': DateTime.now().toUtc().toIso8601String(),
          'main_line_completed_at': null,
          'completed_branch_indices': <int>[],
        });
      }
      chapter['active_variations'] = active;
    });
  }

  static Future<void> markVariationMainLineCompleted({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
  }) async {
    await _mutateChapter(courseSlug, chapterIndex, (course, chapter) {
      final active = _activeVariations(chapter);
      final entry = active.firstWhere(
        (v) => (v['variation_index'] as num?)?.toInt() == variationIndex,
        orElse: () => <String, dynamic>{},
      );
      if (entry.isNotEmpty) {
        entry['main_line_completed_at'] ??=
            DateTime.now().toUtc().toIso8601String();
      }
      chapter['active_variations'] = active;
    });
  }

  static Future<void> markVariationBranchCompleted({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
    required int branchIndex,
  }) async {
    await _mutateChapter(courseSlug, chapterIndex, (course, chapter) {
      final active = _activeVariations(chapter);
      final entry = active.firstWhere(
        (v) => (v['variation_index'] as num?)?.toInt() == variationIndex,
        orElse: () => <String, dynamic>{},
      );
      if (entry.isNotEmpty) {
        final branches = ((entry['completed_branch_indices'] as List?) ?? [])
            .map((value) => (value as num).toInt())
            .toSet();
        branches.add(branchIndex);
        entry['completed_branch_indices'] = branches.toList();
      }
      chapter['active_variations'] = active;
    });
  }

  /// Promotes an active variation into the completed `variations` array only
  /// when the main line and all branches have been completed.
  static Future<void> completeVariation({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
    required int branchCount,
  }) async {
    await _mutateChapter(courseSlug, chapterIndex, (course, chapter) {
      final active = _activeVariations(chapter);
      final entry = active.firstWhere(
        (v) => (v['variation_index'] as num?)?.toInt() == variationIndex,
        orElse: () => <String, dynamic>{},
      );
      if (entry.isEmpty || entry['main_line_completed_at'] == null) return;
      final completedBranches = ((entry['completed_branch_indices'] as List?) ?? [])
          .length;
      if (completedBranches < branchCount) return;

      final now = DateTime.now().toUtc().toIso8601String();
      final completed = <String, dynamic>{
        'variation_index': variationIndex,
        'variation_name': entry['variation_name'] ?? '',
        'started_at': entry['started_at'],
        'main_line_completed_at': entry['main_line_completed_at'],
        'branches_completed_at': now,
        'completed_at': now,
      };
      final variations = _listOfMaps(chapter['variations']);
      if (!variations.any((v) =>
          (v['variation_index'] as num?)?.toInt() == variationIndex)) {
        variations.add(completed);
      }
      active.remove(entry);
      chapter['variations'] = variations;
      chapter['active_variations'] = active;
    });
  }

  /// A passed test completes the chapter independently of variation progress.
  static Future<void> markChapterTestCompleted({
    required String courseSlug,
    required int chapterIndex,
  }) async {
    await _mutateChapter(courseSlug, chapterIndex, (course, chapter) {
      final now = DateTime.now().toUtc().toIso8601String();
      chapter['status'] = 'completed';
      chapter['test_completed_at'] = now;
    });
  }

  static Future<void> _mutateChapter(
    String courseSlug,
    int chapterIndex,
    void Function(Map<String, dynamic> course, Map<String, dynamic> chapter)
        mutate,
  ) async {
    final email = await _email();
    if (email == null) return;
    try {
      final raw = await _read(email);
      final courses = _courses(raw);
      final course = _findCourse(courses, courseSlug);
      if (course == null) return;
      final chapters = _chapters(course);
      final chapter = _findChapter(chapters, chapterIndex);
      if (chapter == null) return;
      mutate(course, chapter);
      course['chapters'] = chapters;
      raw['courses'] = courses;
      await _write(email, raw);
    } catch (e) {
      AppLogger.warn('[UserCourseProgressService] Progress update failed: $e');
    }
  }

  static Future<Map<String, dynamic>> _read(String email) async {
    final id = _documentId(email);
    final doc = await MongoService.withRetry(() async {
      final coll = await MongoService.collection(collectionName);
      return coll.findOne(where.eq('_id', id));
    });
    return doc == null
        ? <String, dynamic>{'_id': id, 'email': email, 'courses': <Map<String, dynamic>>[]}
        : Map<String, dynamic>.from(doc);
  }

  static Future<void> _write(String email, Map<String, dynamic> raw) async {
    final id = _documentId(email);
    // `withSignedInRetry`: account progress is a shared-collection write, so a
    // device with no session must never create or update it, even if a stale
    // cached email let the caller through.
    await MongoService.withSignedInRetry(() async {
      final coll = await MongoService.collection(collectionName);
      await coll.updateOne(
        where.eq('_id', id),
        <String, dynamic>{
          r'$set': {
            'email': email,
            'courses': raw['courses'] ?? <Map<String, dynamic>>[],
            if (raw['last_chapter_unlock_at'] != null)
              'last_chapter_unlock_at': raw['last_chapter_unlock_at'],
          },
          r'$setOnInsert': {'_id': id},
        },
        upsert: true,
      );
    });
  }

  static UserCourseProgressSnapshot _snapshot(Map<String, dynamic> raw) =>
      UserCourseProgressSnapshot(
        lastChapterUnlockAt: _date(raw['last_chapter_unlock_at']),
        courses: _courses(raw)
            .map((course) => UserCourseProgress.fromJson(course))
            .toList(),
      );

  static List<Map<String, dynamic>> _courses(Map<String, dynamic> raw) =>
      _listOfMaps(raw['courses']);

  static List<Map<String, dynamic>> _chapters(Map<String, dynamic> course) =>
      _listOfMaps(course['chapters']);

  static List<Map<String, dynamic>> _activeVariations(
          Map<String, dynamic> chapter) =>
      _listOfMaps(chapter['active_variations']);

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) =>
      (value as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  static Map<String, dynamic>? _findCourse(
      List<Map<String, dynamic>> courses, String slug) {
    for (final course in courses) {
      if (course['course_slug']?.toString() == slug) return course;
    }
    return null;
  }

  static Map<String, dynamic>? _findChapter(
      List<Map<String, dynamic>> chapters, int index) {
    for (final chapter in chapters) {
      if ((chapter['chapter_index'] as num?)?.toInt() == index) return chapter;
    }
    return null;
  }

  static Future<String?> _email() async {
    final direct = AuthService.userEmail?.trim().toLowerCase();
    if (direct != null && direct.isNotEmpty) return direct;
    final cached = await UserProfileStore.load(userId: AuthService.userId);
    final email = cached?.email?.trim().toLowerCase();
    return email == null || email.isEmpty ? null : email;
  }

  static String _documentId(String email) => 'course_progress:$email';

  static DateTime? _date(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static String _dayStamp(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
