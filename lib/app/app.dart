import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/atlas_ui.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

import 'routes.dart';

class TacticsApp extends StatelessWidget {
  /// The screen the app opens on.
  ///
  /// Resolved during bootstrap by `AuthApiService.startupRoute()` because a
  /// restored session may still be missing its display name, in which case the
  /// user has to be asked for one instead of landing on the home screen as
  /// "Player".
  final String initialRoute;

  const TacticsApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, mode, child) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleService.locale,
          builder: (context, appLocale, child) {
            return MaterialApp(
              // Localized per-locale via onGenerateTitle (its context sits
              // below the Localizations widget, unlike `title`).
              onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Derived from `LocaleService.supportedLanguages` — the one list
              // the settings picker also reads — so MaterialApp can never offer
              // a language the picker does not, or vice versa.
              //
              // Deliberately NOT `AppLocalizations.supportedLocales`: the
              // generator emits that sorted alphabetically, which would put
              // `ar` first. `en` must stay first, because Flutter's locale
              // fallback picks the first entry for an unsupported system
              // locale. `localization_test.dart` asserts the two agree.
              supportedLocales: [
                for (final language in LocaleService.supportedLanguages)
                  language.locale,
              ],
              // null → follow the system language.
              locale: appLocale,
              // Publishes the locale MaterialApp actually resolved so the
              // non-widget layers (`atlas_core` services, which have no
              // BuildContext) can read the on-screen language — most visibly,
              // so the AI coach knows which language to answer in. This context
              // sits below `Localizations`, so `localeOf` returns the real
              // resolved locale rather than the `null` "follow system" request.
              builder: (context, child) {
                LocaleService.publishResolved(Localizations.localeOf(context));
                return child ?? const SizedBox.shrink();
              },
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Brightness.light,
                  surface: AppColors.background,
                  onSurface: AppColors.textPrimary,
                  secondary: AppColors.secondary,
                ),
                scaffoldBackgroundColor: AppColors.background,
                cardColor: AppColors.surface,
                dividerColor: AppColors.border,
                appBarTheme: const AppBarTheme(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  centerTitle: false,
                  titleTextStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Brightness.dark,
                  surface: AppColors.surfaceDark,
                  onSurface: AppColors.textPrimaryDark,
                  secondary: AppColors.secondary,
                ),
                scaffoldBackgroundColor: AppColors.backgroundDark,
                cardColor: AppColors.surfaceDark,
                dividerColor: AppColors.borderDark,
                appBarTheme: const AppBarTheme(
                  backgroundColor: AppColors.backgroundDark,
                  foregroundColor: AppColors.textPrimaryDark,
                  elevation: 0,
                  centerTitle: false,
                  titleTextStyle: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              initialRoute: initialRoute,
              routes: buildAppRoutes(),
            );
          },
        );
      },
    );
  }
}
