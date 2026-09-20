import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/reader_navigation_strings.dart';

void main() {
  const locales = <String>['tr', 'en', 'ar', 'az', 'ru', 'fr'];
  const requiredKeys = <String>{
    'readerGo',
    'readerSurah',
    'readerSurahSubtitle',
    'readerJuz',
    'readerJuzSubtitle',
    'readerPage',
    'readerPageSubtitle',
    'readerGoToJuz',
    'readerGoToPage',
    'readerReturnToCurrentVerse',
  };

  test('reader navigation copy keeps core-locale key parity', () {
    for (final locale in locales) {
      final values = readerNavigationStrings[locale];
      expect(values, isNotNull, reason: 'Missing reader locale $locale');
      expect(
        values!.keys.toSet(),
        requiredKeys,
        reason: 'Reader navigation key drift for $locale',
      );
      for (final key in requiredKeys) {
        expect(values[key]!.trim(), isNotEmpty, reason: '$locale:$key is empty');
      }
    }
  });

  test('reader navigation copy resolves through AppLocalizations', () {
    expect(AppLocalizations(const Locale('tr')).text('readerGo'), 'Git');
    expect(AppLocalizations(const Locale('en')).text('readerGo'), 'Go');
    expect(AppLocalizations(const Locale('ar')).text('readerSurah'), 'سورة');
    expect(AppLocalizations(const Locale('az')).text('readerPage'), 'Səhifə');
    expect(AppLocalizations(const Locale('ru')).text('readerJuz'), 'Джуз');
    expect(AppLocalizations(const Locale('fr')).text('readerGo'), 'Aller');
  });
}
