import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  test('all declared UI locales resolve core navigation labels', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = AppLocalizations(locale);
      expect(l10n.appTitle, isNotEmpty);
      expect(l10n.navHome, isNotEmpty);
      expect(l10n.navQuran, isNotEmpty);
      expect(l10n.navPlans, isNotEmpty);
      expect(l10n.navDiscover, isNotEmpty);
      expect(l10n.navProfile, isNotEmpty);
      expect(l10n.language, isNotEmpty);
      expect(l10n.quranLanguage, isNotEmpty);
    }
  });

  test('five initial interface languages are enabled', () {
    final codes = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();
    expect(codes, containsAll(<String>['tr', 'en', 'ar', 'az', 'ru']));
  });

  test('Arabic interface has an Arabic Quran title', () {
    final l10n = AppLocalizations(const Locale('ar'));
    expect(l10n.appTitle, contains('القرآن'));
  });

  test('primary feature copy exists in every locale', () {
    const keys = <String>[
      'today',
      'dailyVerse',
      'continueReading',
      'discoverTitle',
      'prayerTimes',
      'dhikrCounter',
      'readingPlans',
      'findPlans',
      'start',
      'readerAppearance',
      'quranSearchTitle',
      'compareTexts',
      'prayerSettings',
      'chooseCity',
      'worldCitySearchInfo',
      'searchOnline',
      'qiblaLocationPrompt',
      'pointTopToKaaba',
      'monthlyPrayerTimes',
      'fajr',
      'isha',
      'calculationMethod',
      'translationSearchHint',
      'downloadReady',
      'translationInstalled',
    ];

    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = AppLocalizations(locale);
      for (final key in keys) {
        final value = l10n.text(key);
        expect(value, isNotEmpty, reason: '${locale.languageCode}: $key');
        expect(value, isNot(key), reason: '${locale.languageCode}: $key');
      }
    }
  });
}
