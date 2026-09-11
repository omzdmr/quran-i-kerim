import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/home_verse_strings.dart';

void main() {
  test('home localization keeps TR EN AR AZ RU key parity', () {
    const locales = <String>['tr', 'en', 'ar', 'az', 'ru'];
    final expectedKeys = homeVerseStrings['tr']!.keys.toSet();

    expect(homeVerseStrings.keys.toSet(), locales.toSet());
    for (final locale in locales) {
      expect(
        homeVerseStrings[locale]!.keys.toSet(),
        expectedKeys,
        reason: 'Missing or extra home localization key for $locale',
      );
      expect(
        homeVerseStrings[locale]!.values.every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: 'Empty home localization value for $locale',
      );
    }
  });

  test('AppLocalizations resolves centralized home community copy', () {
    for (final locale in const <String>['tr', 'en', 'ar', 'az', 'ru']) {
      final l10n = AppLocalizations(Locale(locale));
      for (final key in const <String>[
        'homeCommunityTitle',
        'homeCommunityBody',
        'homeCommunityEmpty',
        'homeCommunityBookmark',
        'homeCommunityHighlight',
        'homeCommunityNote',
      ]) {
        expect(
          l10n.text(key),
          homeVerseStrings[locale]![key],
          reason: '$key should resolve through AppLocalizations for $locale',
        );
      }
    }
  });
}
