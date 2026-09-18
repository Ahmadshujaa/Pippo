import 'package:atlas_core/core/auth/AuthService.dart';
import 'package:atlas_core/core/integrations/MongoService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';
import 'package:atlas_core/core/user/UserProfileService.dart';
import 'package:atlas_core/models/CourseModels.dart';
import 'package:mongo_dart/mongo_dart.dart';

class CourseApiService {
  static const String _interactiveCoursesColl = 'interactive_courses';

  // =========================================================================
  // ADMIN-ONLY EDIT AUTHORIZATION
  //
  // `interactive_courses` is read by every account but written by the pencil
  // editors, so those writes are an admin-only feature. The check is
  // fail-closed: a device that cannot prove the signed-in account is an admin
  // is never allowed to write, so a signed-out, guest, offline or non-admin
  // session can only read. The UI also hides the pencil icons; this is the
  // enforcement.
  // =========================================================================

  /// Whether the signed-in account is verified as an admin.
  ///
  /// Two gates must both pass:
  ///   1. the signed-in email is on the ADMIN_EMAILS allow-list, and
  ///   2. the account's own profile row confirms the admin plan.
  ///
  /// A profile read that fails (offline, error) returns null and therefore
  /// denies the write — an unverifiable session must never mutate shared data.
  static Future<bool> isVerifiedAdmin() async {
    final userId = AuthService.userId;
    final email = AuthService.userEmail;

    if (userId == null || userId.isEmpty) return false;
    if (!UserProfileService.isAdminEmail(email)) return false;

    final plan = await UserProfileService.readPlanStatus(userId, email);
    return plan?.isAdmin ?? false;
  }

  /// Refuses a course-content edit unless the account is a verified admin.
  /// Logged with [operation] so the device console names the blocked call.
  static Future<bool> _ensureAdminEdit(String operation) async {
    if (await isVerifiedAdmin()) return true;
    AppLogger.warn('[CourseApiService] $operation blocked: the signed-in account is '
        'not a verified admin.');
    return false;
  }

  static String _slugify(String name) {
    return name.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+$'), '')
        .replaceAll(RegExp(r'^-+'), '');
  }

  /// Builds the RegExp used to find a course document by its display name.
  ///
  /// A slug only keeps alphanumerics, while the stored `opening_name` may carry
  /// extra separators such as parentheses (e.g. `Sicilian Defense (as Black)`),
  /// so every run of whitespace becomes `[^a-z0-9]+` and a trailing run is
  /// allowed. The query itself stays case-insensitive.
  static String _namePattern(String name) {
    final words = name.replaceAll(RegExp(r'\s+'), '[^a-z0-9]+');
    return '^$words[^a-z0-9]*\$';
  }

  static Future<List<CourseModel>> getAllCourses() async {
    try {
      AppLogger.debug('[CourseApiService] Fetching all courses...');
      final courses = await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);
        return coll.find().toList();
      });
      AppLogger.debug('[CourseApiService] Found ${courses.length} courses in MongoDB.');

      final List<CourseModel> result = [];
      for (var c in courses) {
        try {
          final openingName = c['opening_name'] ?? '';
          final slug = _slugify(openingName);
          
          final chaptersData = (c['chapters'] as List? ?? []);
          int totalVariations = 0;
          for (var ch in chaptersData) {
            totalVariations += (ch['variations'] as List? ?? []).length;
          }

          result.add(CourseModel(
            openingName: openingName,
            slug: slug,
            description: c['description'] ?? '',
            playfulDescription: c['playful_description'] ?? '',
            side: (c['side'] ?? 'white').toString().toLowerCase(),
            mainCategory: c['main_category'] ?? '',
            subCategory: c['sub_category'] ?? '',
            ecoCode: c['eco_code'] ?? '',
            chapterCount: chaptersData.length,
            variationCount: totalVariations,
            chapters: chaptersData.map((ch) => CourseChapterModel.fromJson(Map<String, dynamic>.from(ch))).toList(),
            isLocked: false,
          ));
        } catch (e) {
          AppLogger.warn('[CourseApiService] Skipping course due to mapping error: $e');
        }
      }

      AppLogger.debug('[CourseApiService] Successfully mapped ${result.length} courses.');

      result.sort((a, b) => a.chapterCount.compareTo(b.chapterCount));

      return result;
    } catch (e) {
      AppLogger.error('[CourseApiService] Error fetching courses: $e');
      return [];
    }
  }

  static Future<CourseModel?> getCourseDetails(String slug) async {
    try {
      AppLogger.debug('[CourseApiService] Fetching course details for slug: $slug');
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);

        final baseName = slug.replaceAll('-', ' ');
        final searchPattern = _namePattern(baseName);

        var courseData = await coll.findOne(
          where.match('opening_name', searchPattern, caseInsensitive: true),
        );

        if (courseData == null) {
          final alt = baseName.contains('center')
              ? baseName.replaceAll('center', 'centre')
              : baseName.replaceAll('centre', 'center');
          final altPattern = _namePattern(alt);
          courseData = await coll.findOne(
            where.match('opening_name', altPattern, caseInsensitive: true),
          );
        }

        if (courseData == null) return null;

        return CourseModel.fromJson(
          Map<String, dynamic>.from(courseData)
            ..addAll({'slug': slug, 'isLocked': false}),
        );
      });
    } catch (e) {
      AppLogger.error('[CourseApiService] Error fetching course details ($slug): $e');
      return null;
    }
  }

  // =========================================================================
  // EXPLANATION EDITING
  //
  // Explanations live inside the nested `chapters` array of a single course
  // document. Updates are positional: the document is matched by slug + the
  // chapter's index within `chapters`, then the new text is written to
  // `chapters.{i}.<target>` with the arrayFilters-free positional projection
  // of a one-element path (chapterIndex is the position itself).
  // =========================================================================

  /// Resolves the same selector used by [getCourseDetails] so updates always
  /// hit the exact document the user is studying. Returns the ObjectId of the
  /// course document, or null if not found / on error.
  static Future<ObjectId?> _findCourseIdBySlug(String slug) async {
    try {
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);
        final baseName = slug.replaceAll('-', ' ');
        final searchPattern = _namePattern(baseName);

        var courseData = await coll.findOne(
          where.match('opening_name', searchPattern, caseInsensitive: true),
        );

        if (courseData == null) {
          final alt = baseName.contains('center')
              ? baseName.replaceAll('center', 'centre')
              : baseName.replaceAll('centre', 'center');
          final altPattern = _namePattern(alt);
          courseData = await coll.findOne(
            where.match('opening_name', altPattern, caseInsensitive: true),
          );
        }

        if (courseData == null) return null;
        final id = courseData['_id'];
        if (id is ObjectId) return id;
        if (id != null) return ObjectId.fromHexString(id.toString());
        return null;
      });
    } catch (e) {
      AppLogger.error('[CourseApiService] Error resolving course id for slug ($slug): $e');
      return null;
    }
  }

  /// Persists an edited variation theory text to MongoDB.
  ///
  /// Updates
  /// `chapters.<chapterIndex>.variations.<variationIndex>.theory`
  /// on exactly one course document. Returns true when the update is confirmed
  /// by the server.
  static Future<bool> updateVariationTheory({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
    required String theory,
  }) async {
    if (!await _ensureAdminEdit('updateVariationTheory')) return false;
    final courseId = await _findCourseIdBySlug(courseSlug);
    if (courseId == null) {
      AppLogger.warn('[CourseApiService] updateVariationTheory: course not found ($courseSlug)');
      return false;
    }

    try {
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);
        final result = await coll.updateOne(
          where.eq('_id', courseId),
          modify.set(
            'chapters.$chapterIndex.variations.$variationIndex.theory',
            theory,
          ),
        );
        final ok = result.nMatched == 1 && !result.hasWriteErrors;
        AppLogger.debug('[CourseApiService] updateVariationTheory: matched=${result.nMatched} '
            'modified=${result.nModified} ok=$ok');
        return ok;
      });
    } catch (e) {
      AppLogger.error('[CourseApiService] Error updating variation theory: $e');
      return false;
    }
  }

  /// Persists an edited move explanation to MongoDB.
  ///
  /// Updates
  /// `chapters.<chapterIndex>.variations.<variationIndex>.plies.<plyIndex>.explanation`
  /// on exactly one course document. Returns true when the update is confirmed
  /// by the server.
  static Future<bool> updateMoveExplanation({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
    required int plyIndex,
    required String explanation,
  }) async {
    if (!await _ensureAdminEdit('updateMoveExplanation')) return false;
    final courseId = await _findCourseIdBySlug(courseSlug);
    if (courseId == null) {
      AppLogger.warn('[CourseApiService] updateMoveExplanation: course not found ($courseSlug)');
      return false;
    }

    try {
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);
        final result = await coll.updateOne(
          where.eq('_id', courseId),
          modify.set(
            'chapters.$chapterIndex.variations.$variationIndex.plies.$plyIndex.explanation',
            explanation,
          ),
        );
        final ok = result.nMatched == 1 && !result.hasWriteErrors;
        AppLogger.debug('[CourseApiService] updateMoveExplanation: matched=${result.nMatched} '
            'modified=${result.nModified} ok=$ok');
        return ok;
      });
    } catch (e) {
      AppLogger.error('[CourseApiService] Error updating move explanation: $e');
      return false;
    }
  }

  /// Persists an edited move hint to MongoDB.
  ///
  /// Updates
  /// `chapters.<chapterIndex>.variations.<variationIndex>.plies.<plyIndex>.hint`
  /// on exactly one course document. Returns true when the update is confirmed
  /// by the server.
  static Future<bool> updateMoveHint({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
    required int plyIndex,
    required String hint,
  }) async {
    if (!await _ensureAdminEdit('updateMoveHint')) return false;
    final courseId = await _findCourseIdBySlug(courseSlug);
    if (courseId == null) {
      AppLogger.warn('[CourseApiService] updateMoveHint: course not found ($courseSlug)');
      return false;
    }

    try {
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);
        final result = await coll.updateOne(
          where.eq('_id', courseId),
          modify.set(
            'chapters.$chapterIndex.variations.$variationIndex.plies.$plyIndex.hint',
            hint,
          ),
        );
        final ok = result.nMatched == 1 && !result.hasWriteErrors;
        AppLogger.debug('[CourseApiService] updateMoveHint: matched=${result.nMatched} '
            'modified=${result.nModified} ok=$ok');
        return ok;
      });
    } catch (e) {
      AppLogger.error('[CourseApiService] Error updating move hint: $e');
      return false;
    }
  }

  /// Persists an edited branch explanation to MongoDB.
  ///
  /// Updates
  /// `chapters.<chapterIndex>.variations.<variationIndex>.branches.<branchIndex>.explanation`
  /// on exactly one course document. Returns true when the update is confirmed
  /// by the server.
  static Future<bool> updateBranchExplanation({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
    required int branchIndex,
    required String explanation,
  }) async {
    if (!await _ensureAdminEdit('updateBranchExplanation')) return false;
    final courseId = await _findCourseIdBySlug(courseSlug);
    if (courseId == null) {
      AppLogger.warn('[CourseApiService] updateBranchExplanation: course not found ($courseSlug)');
      return false;
    }
    try {
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);
        final result = await coll.updateOne(
          where.eq('_id', courseId),
          modify.set(
            'chapters.$chapterIndex.variations.$variationIndex.branches.$branchIndex.explanation',
            explanation,
          ),
        );
        final ok = result.nMatched == 1 && !result.hasWriteErrors;
        AppLogger.debug('[CourseApiService] updateBranchExplanation: matched=${result.nMatched} '
            'modified=${result.nModified} ok=$ok');
        return ok;
      });
    } catch (e) {
      AppLogger.error('[CourseApiService] Error updating branch explanation: $e');
      return false;
    }
  }

  /// Persists an edited move explanation that lives inside a branch line.
  ///
  /// Updates
  /// `chapters.<chapterIndex>.variations.<variationIndex>.branches.<branchIndex>.plies.<plyIndex>.explanation`
  /// on exactly one course document. Returns true when the update reaches
  /// exactly one document.
  static Future<bool> updateBranchMoveExplanation({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
    required int branchIndex,
    required int plyIndex,
    required String explanation,
  }) async {
    if (!await _ensureAdminEdit('updateBranchMoveExplanation')) return false;
    final courseId = await _findCourseIdBySlug(courseSlug);
    if (courseId == null) {
      AppLogger.warn('[CourseApiService] updateBranchMoveExplanation: course not found ($courseSlug)');
      return false;
    }

    try {
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);
        final result = await coll.updateOne(
          where.eq('_id', courseId),
          modify.set(
            'chapters.$chapterIndex.variations.$variationIndex.branches.$branchIndex.plies.$plyIndex.explanation',
            explanation,
          ),
        );
        final ok = result.nMatched == 1 && !result.hasWriteErrors;
        AppLogger.debug('[CourseApiService] updateBranchMoveExplanation: matched=${result.nMatched} '
            'modified=${result.nModified} ok=$ok');
        return ok;
      });
    } catch (e) {
      AppLogger.error('[CourseApiService] Error updating branch move explanation: $e');
      return false;
    }
  }

  /// Persists an edited chapter description to MongoDB.
  ///
  /// Updates `chapters.<chapterIndex>.description` on exactly one course
  /// document. Returns true when the update reaches exactly one document.
  static Future<bool> updateChapterDescription({
    required String courseSlug,
    required int chapterIndex,
    required String description,
  }) async {
    if (!await _ensureAdminEdit('updateChapterDescription')) return false;
    final courseId = await _findCourseIdBySlug(courseSlug);
    if (courseId == null) {
      AppLogger.warn('[CourseApiService] updateChapterDescription: course not found ($courseSlug)');
      return false;
    }

    try {
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);
        final result = await coll.updateOne(
          where.eq('_id', courseId),
          modify.set('chapters.$chapterIndex.description', description),
        );
        final ok = result.nMatched == 1 && !result.hasWriteErrors;
        AppLogger.debug('[CourseApiService] updateChapterDescription: matched=${result.nMatched} '
            'modified=${result.nModified} ok=$ok');
        return ok;
      });
    } catch (e) {
      AppLogger.error('[CourseApiService] Error updating chapter description: $e');
      return false;
    }
  }

  /// Persists an edited variation description to MongoDB.
  ///
  /// Updates
  /// `chapters.<chapterIndex>.variations.<variationIndex>.description`
  /// on exactly one course document. Returns true when the update reaches
  /// exactly one document.
  static Future<bool> updateVariationDescription({
    required String courseSlug,
    required int chapterIndex,
    required int variationIndex,
    required String description,
  }) async {
    if (!await _ensureAdminEdit('updateVariationDescription')) return false;
    final courseId = await _findCourseIdBySlug(courseSlug);
    if (courseId == null) {
      AppLogger.warn('[CourseApiService] updateVariationDescription: course not found ($courseSlug)');
      return false;
    }

    try {
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(_interactiveCoursesColl);
        final result = await coll.updateOne(
          where.eq('_id', courseId),
          modify.set(
            'chapters.$chapterIndex.variations.$variationIndex.description',
            description,
          ),
        );
        final ok = result.nMatched == 1 && !result.hasWriteErrors;
        AppLogger.debug('[CourseApiService] updateVariationDescription: matched=${result.nMatched} '
            'modified=${result.nModified} ok=$ok');
        return ok;
      });
    } catch (e) {
      AppLogger.error('[CourseApiService] Error updating variation description: $e');
      return false;
    }
  }
}
