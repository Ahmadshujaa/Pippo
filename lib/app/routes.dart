import 'package:flutter/material.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/atlas_ui.dart';

Map<String, WidgetBuilder> buildAppRoutes() {
  return {
    '/': (context) => const Welcome(),
    '/auth': (context) => const AuthForm(),
    '/verify-otp': (context) {
      final email = ModalRoute.of(context)!.settings.arguments as String;
      return OtpVerify(email: email);
    },
    '/onboarding': (context) => const NamePrompt(),
    '/home': (context) => const Home(),
    '/play': (context) => const PippoPlayScreen(),
    '/courses': (context) => const CoursesLibrary(),
    '/course-details': (context) {
      final slug = ModalRoute.of(context)!.settings.arguments as String;
      return CourseDetails(slug: slug);
    },
    '/chapter-study': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return ChapterStudy(
        course: args['course'] as CourseModel,
        chapterIndex: args['chapterIndex'] as int,
      );
    },
    '/chapter-test': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return ChapterTest(
        course: args['course'] as CourseModel,
        chapterIndex: args['chapterIndex'] as int,
      );
    },
    '/puzzles': (context) => const PuzzleSelectionScreen(),
    '/my-puzzles': (context) => const MyPuzzlesPlayerScreen(),
    '/themes': (context) => const AllThemesScreen(),
    '/mixed-puzzles': (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      return MixedPuzzlePlayScreen(theme: args is String ? args : null);
    },
    '/downloaded-puzzles': (context) => const MixedPuzzlePlayScreen(isDownloaded: true),
    '/daily-puzzle': (context) => const MixedPuzzlePlayScreen(daily: true),
    '/puzzle-player': (context) {
      final puzzles = ModalRoute.of(context)!.settings.arguments as List<PuzzleDocModel>;
      return PuzzlePlayerScreen(puzzleDocs: puzzles);
    },
    '/profile-settings': (context) => const ProfileSettings(),
    '/chessboard-test': (context) => const ChessboardTest(),
    '/classification-test': (context) => const MoveClassificationTestScreen(),
    '/download-model': (context) => const DownloadModelScreen(),
    '/analysis': (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      return AnalysisScreen(
        initialSavedGame: args is SavedGame ? args : null,
      );
    },
    '/pricing': (context) => const PricingScreen(),
    '/contact-support': (context) => const ContactSupportScreen(),
  };
}
