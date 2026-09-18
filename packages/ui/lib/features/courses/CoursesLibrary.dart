import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/AtlasCard.dart';
import 'package:atlas_ui/shared/widgets/AppBottomNav.dart';
import 'package:atlas_ui/shared/widgets/OfflineBanner.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:atlas_core/atlas_core.dart';

/// Courses library screen — lists every available interactive opening course
/// fetched from the backend, and opens [CourseDetails] when one is tapped.
class CoursesLibrary extends StatefulWidget {
  const CoursesLibrary({super.key});

  @override
  State<CoursesLibrary> createState() => _CoursesLibraryState();
}

class _CoursesLibraryState extends State<CoursesLibrary> {
  List<CourseModel>? _courses;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    final courses = await CourseApiService.getAllCourses();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _isLoading = false;
      if (courses.isEmpty) {
        _error = 'No courses are available right now.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(
          // Tab screen: users switch via the bottom nav, so no back arrow.
          automaticallyImplyLeading: false,
          titleSpacing: 8,
          title: Text(
            l10n.coursesTitle,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryOf(context),
              letterSpacing: -0.3,
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.coursesTabOpenings),
              Tab(text: l10n.coursesTabMiddlegames),
              Tab(text: l10n.coursesTabEndgames),
            ],
          ),
          elevation: 0,
          backgroundColor: AppColors.backgroundOf(context),
          foregroundColor: AppColors.textPrimaryOf(context),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            setState(() => _isLoading = true);
            await _fetchCourses();
          },
          child: _buildBody(),
        ),
        bottomNavigationBar: const AppBottomNav(active: AppTab.courses),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return _buildCoursesList(_courses!);
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 48,
                    color: AppColors.textTertiaryOf(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noCoursesHereYet,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _fetchCourses();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.tryAgainButton),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(List<CourseModel> courses) {
    final buckets = _bucketCourses(courses);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
          child: OfflineBanner(),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _buildCategoryTab(context, buckets.openings),
              _buildCategoryTab(context, buckets.middlegame),
              _buildCategoryTab(context, buckets.endgames),
            ],
          ),
        ),
      ],
    );
  }

  /// One tab's panel: that category's course cards, or an empty hint. The
  /// category name lives in the tab bar itself (Openings / Middlegames /
  /// Endgames), so there's no repeated header and no "more courses coming
  /// soon" note cluttering each category.
  Widget _buildCategoryTab(BuildContext context, List<CourseModel> courses) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        if (courses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                AppLocalizations.of(context).noCoursesHereYet,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
            ),
          )
        else
          for (final course in courses) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCourseCard(context, course),
            ),
          ],
      ],
    );
  }

  /// Splits the fetched courses into the three library sections. Matching
  /// tolerates backend casing/spacing ('Middlegame', 'middle_game', ...);
  /// anything unrecognized (or empty) falls back to Openings, the main
  /// course type today.
  ({List<CourseModel> openings, List<CourseModel> middlegame, List<CourseModel> endgames})
      _bucketCourses(List<CourseModel> courses) {
    final openings = <CourseModel>[];
    final middlegame = <CourseModel>[];
    final endgames = <CourseModel>[];

    for (final course in courses) {
      final raw = course.mainCategory
          .toLowerCase()
          .replaceAll(RegExp(r'[\s_-]'), '');
      if (raw.contains('middle')) {
        middlegame.add(course);
      } else if (raw.contains('end')) {
        endgames.add(course);
      } else {
        openings.add(course);
      }
    }

    return (openings: openings, middlegame: middlegame, endgames: endgames);
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    final l10n = AppLocalizations.of(context);
    final isWhite = course.side.toLowerCase() == 'white';
    return AtlasCard(
      elevated: true,
      borderRadius: 22,
      onTap: () => Navigator.pushNamed(context, '/course-details', arguments: course.slug),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isWhite ? Icons.shield_rounded : Icons.emoji_events_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.openingName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.playAsSide(isWhite ? l10n.sideWhite : l10n.sideBlack),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            course.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          if (course.mainCategory.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetaChip(context, course.mainCategory),
                if (course.subCategory.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildMetaChip(context, course.subCategory),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: AppColors.textTertiaryOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.chapterCountLabel(course.chapterCount),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.timeline_rounded,
                size: 16,
                color: AppColors.textTertiaryOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.variationCountLabel(course.variationCount),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
      ),
    );
  }
}