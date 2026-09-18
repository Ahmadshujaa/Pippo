import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/AtlasCard.dart';
import 'package:atlas_ui/shared/widgets/OfflineBanner.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:atlas_core/atlas_core.dart';

class CourseDetails extends StatefulWidget {
  final String slug;

  const CourseDetails({super.key, required this.slug});

  @override
  State<CourseDetails> createState() => _CourseDetailsState();
}

class _CourseDetailsState extends State<CourseDetails> {
  CourseModel? _course;
  UserCourseProgress? _progress;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
  }

  Future<void> _fetchCourseDetails() async {
    final course = await CourseApiService.getCourseDetails(widget.slug);
    final progress = await UserCourseProgressService.getProgress();
    if (mounted) {
      setState(() {
        _course = course;
        _progress = progress.forCourse(widget.slug);
        _isLoading = false;
        if (course == null) {
          _error = 'Failed to load course details';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(_course?.openingName ?? l10n.courseDetailsTitle),
        backgroundColor: AppColors.backgroundOf(context),
        foregroundColor: AppColors.textPrimaryOf(context),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OfflineBanner(),
                      const SizedBox(height: 18),
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildDescription(),
                      const SizedBox(height: 32),
                      Text(
                        l10n.chaptersTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildChaptersList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    final isWhite = _course?.side.toLowerCase() == 'white';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n.playAsSide(isWhite ? l10n.sideWhite : l10n.sideBlack),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (_course?.ecoCode.isNotEmpty ?? false)
          Text(
            l10n.ecoCodeLabel(_course!.ecoCode),
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _course?.description ?? '',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondaryOf(context),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersList() {
    if (_course?.chapters.isEmpty ?? true) {
      return Text(AppLocalizations.of(context).noChaptersAvailable);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _course!.chapters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final chapter = _course!.chapters[index];
        UserChapterProgress? chapterProgress;
        for (final candidate in (_progress?.chapters ?? <UserChapterProgress>[])) {
          if (candidate.index == index) {
            chapterProgress = candidate;
            break;
          }
        }
        final hasVariations = chapter.variations.isNotEmpty;
        return AtlasCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    if (chapterProgress?.isCompleted == true) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 17),
                          const SizedBox(width: 5),
                          Text(AppLocalizations.of(context).chapterCompletedBadge, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      hasVariations
                          ? AppLocalizations.of(context).variationCountLabel(chapter.variationCount)
                          : AppLocalizations.of(context).noVariationsAvailable,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: hasVariations
                        ? () {
                            if (_course != null) {
                              Navigator.pushNamed(
                                context,
                                '/chapter-study',
                                arguments: {
                                  'course': _course!,
                                  'chapterIndex': index,
                                },
                              );
                            }
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context).noVariationsForChapterYet),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasVariations ? AppColors.primary : AppColors.textSecondaryOf(context).withValues(alpha: 0.2),
                      foregroundColor: hasVariations ? Colors.white : AppColors.textSecondaryOf(context),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      AppLocalizations.of(context).learnButton,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: hasVariations
                        ? () {
                            if (_course != null) {
                              Navigator.pushNamed(
                                context,
                                '/chapter-test',
                                arguments: {
                                  'course': _course!,
                                  'chapterIndex': index,
                                },
                              );
                            }
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context).noVariationsForChapterYet),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textSecondaryOf(context).withValues(alpha: 0.2),
                      foregroundColor: AppColors.textSecondaryOf(context),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      AppLocalizations.of(context).testButton,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}




