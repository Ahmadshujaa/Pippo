import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the three places that have to agree for a language to actually work:
///
///   1. `LocaleService.supportedLanguages`   — what the settings picker offers;
///   2. `lib/l10n/app_<code>.arb`            — the translations themselves;
///   3. `AppLocalizations.supportedLocales`  — what MaterialApp accepts.
///
/// Getting any one of them out of step fails silently at runtime rather than
/// loudly: the picker offers a language that quietly keeps showing English, or
/// an ARB file sits in the repo being unreachable. These tests make that a
/// build failure instead.
const String _templateLocale = 'en';

late Directory _arbDir;

/// Finds `lib/l10n` from the package itself rather than from the working
/// directory, so the test behaves the same whether it is invoked from
/// `packages/ui` or from the app root.
Future<Directory> _findArbDirectory() async {
  try {
    final uri = await Isolate.resolvePackageUri(
      Uri.parse('package:atlas_ui/atlas_ui.dart'),
    );
    if (uri != null) {
      // .../packages/ui/lib/atlas_ui.dart -> .../packages/ui
      final resolved =
          Directory('${File.fromUri(uri).parent.parent.path}/lib/l10n');
      if (resolved.existsSync()) return resolved;
    }
  } catch (_) {
    // Fall through to the working-directory guesses.
  }

  for (final candidate in const ['lib/l10n', 'packages/ui/lib/l10n']) {
    final dir = Directory(candidate);
    if (dir.existsSync()) return dir;
  }

  throw StateError(
    'Could not locate the ARB directory. Looked for lib/l10n relative to '
    '${Directory.current.path}.',
  );
}

/// Message keys of one locale's ARB file, excluding generation metadata.
Set<String> _messageKeys(String locale) {
  final decoded = jsonDecode(
    File('${_arbDir.path}/app_$locale.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  // `@@locale` marks the locale and `@key` entries describe a message; neither
  // is a translatable string, so neither belongs in the comparison.
  return decoded.keys.where((key) => !key.startsWith('@')).toSet();
}

/// Every `app_<code>.arb` on disk.
List<String> _availableLocales() => _arbDir
    .listSync()
    .map((entity) => RegExp(r'app_([a-z]{2})\.arb$').firstMatch(entity.path))
    .whereType<RegExpMatch>()
    .map((match) => match.group(1)!)
    .toList()
  ..sort();

void main() {
  setUpAll(() async {
    _arbDir = await _findArbDirectory();
  });

  test('the template locale has an ARB file', () {
    expect(_availableLocales(), contains(_templateLocale));
  });

  test('every language the picker offers ships an ARB file', () {
    final locales = _availableLocales();
    for (final language in LocaleService.supportedLanguages) {
      expect(
        locales,
        contains(language.code),
        reason: 'LocaleService offers "${language.code}" in the settings picker '
            'but there is no app_${language.code}.arb, so choosing it would '
            'quietly keep showing English.',
      );
    }
  });

  test('no ARB file ships without the picker offering it', () {
    final offered = LocaleService.supportedLanguages.map((l) => l.code).toSet();
    for (final locale in _availableLocales()) {
      expect(
        offered,
        contains(locale),
        reason: 'app_$locale.arb exists but LocaleService never offers '
            '"$locale", so those translations are unreachable.',
      );
    }
  });

  test('MaterialApp accepts exactly the languages the picker offers', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      LocaleService.supportedLanguages.map((l) => l.code).toSet(),
    );
  });

  test('English is first, because it is the unknown-system-locale fallback', () {
    // `app.dart` derives `supportedLocales` from this list in order, and
    // Flutter picks the FIRST entry for a system locale the app does not
    // support. Demoting English would open the app in an arbitrary language
    // for phones set to something the app does not ship.
    expect(LocaleService.supportedLanguages.first.code, _templateLocale);
  });

  test('every locale translates every message in the template', () {
    final expected = _messageKeys(_templateLocale);
    expect(expected, isNotEmpty);

    for (final locale
        in _availableLocales().where((l) => l != _templateLocale)) {
      expect(
        _messageKeys(locale),
        equals(expected),
        reason: 'app_$locale.arb and app_$_templateLocale.arb disagree about '
            'which messages exist. A key missing on the left falls back to '
            'English with no warning; an extra key on the right is dead weight '
            'no screen can read.',
      );
    }
  });
}
