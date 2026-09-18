import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A language the app ships translations for.
class AppLanguage {
  final String code;

  /// The language's own name. Language pickers always show each option in its
  /// own language, so this is deliberately never translated.
  final String nativeName;

  /// The language's name in English — what we hand to the AI coach, which
  /// understands "Portuguese (Brazil)" far more reliably than a bare `pt`.
  final String promptName;

  const AppLanguage(this.code, this.nativeName, this.promptName);

  Locale get locale => Locale(code);
}

/// Mirrors [ThemeService], but for the app display language.
///
/// A `null` locale means "follow the system language" — the default for
/// fresh installs. MaterialApp resolves `null` through its own locale
/// list, which is exactly the behavior we want.
class LocaleService {
  static const String _localeKey = 'user_locale';

  static SharedPreferences? _prefs;

  /// `null` = follow the system language.
  static final ValueNotifier<Locale?> locale = ValueNotifier(null);

  /// The locale MaterialApp actually resolved — the explicit choice when the
  /// user made one, otherwise the system language it matched.
  ///
  /// [locale] is `null` while following the system, so on its own it can never
  /// answer "which language is on screen right now?". Non-widget layers — the
  /// services in `atlas_core`, which have no `BuildContext` — read this
  /// instead: the AI coach picks its answer language from it, and it is the
  /// locale to format numbers and dates with.
  ///
  /// Kept in sync by the app shell (see `TacticsApp`), which publishes from
  /// below the `Localizations` widget, so this is always a locale the app
  /// really ships.
  static Locale _resolved = const Locale('en');
  static Locale get resolved => _resolved;

  /// Called by the app shell whenever MaterialApp resolves a new locale.
  static void publishResolved(Locale value) => _resolved = value;

  /// Languages offered in the settings picker, in display order.
  ///
  /// Every entry here must also have an `app_<code>.arb` in `atlas_ui`
  /// (`packages/ui/lib/l10n/`), otherwise the picker would offer a language
  /// whose translations do not exist and the UI would fall back to English.
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage('en', 'English', 'English'),
    AppLanguage('es', 'Español', 'Spanish'),
    AppLanguage('pt', 'Português', 'Portuguese (Brazil)'),
    AppLanguage('fr', 'Français', 'French'),
    AppLanguage('hi', 'हिन्दी', 'Hindi'),
    AppLanguage('ar', 'العربية', 'Arabic'),
  ];

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString(_localeKey);
    if (saved != null) {
      locale.value = _parseLocale(saved);
    }
  }

  /// `null` restores the system default.
  static Future<void> setLocale(Locale? newLocale) async {
    locale.value = newLocale;
    if (newLocale == null) {
      await _prefs?.remove(_localeKey);
    } else {
      await _prefs?.setString(_localeKey, newLocale.languageCode);
    }
  }

  /// The language name to instruct the AI coach in, for [locale].
  ///
  /// Falls back to the bare language code for a locale we ship no translation
  /// for, which is still a better hint than nothing.
  static String promptNameFor(Locale locale) {
    for (final lang in supportedLanguages) {
      if (lang.code == locale.languageCode) return lang.promptName;
    }
    return locale.languageCode;
  }

  /// The locale for "System Default" rows, or null when following system.
  static Locale? _parseLocale(String value) {
    for (final lang in supportedLanguages) {
      if (lang.code == value) return lang.locale;
    }
    return null; // Unknown stored value → fall back to system.
  }
}
