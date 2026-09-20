import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/strings_ar.dart';
import 'package:quran_i_kerim/src/l10n/strings/strings_az.dart';
import 'package:quran_i_kerim/src/l10n/strings/strings_en.dart';
import 'package:quran_i_kerim/src/l10n/strings/strings_fr.dart';
import 'package:quran_i_kerim/src/l10n/strings/strings_ru.dart';
import 'package:quran_i_kerim/src/l10n/strings/strings_tr.dart';

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

  test('six interface languages including French are enabled', () {
    final codes = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();
    expect(codes, containsAll(<String>['tr', 'en', 'ar', 'az', 'ru', 'fr']));
  });

  test('core string dictionaries keep exact key parity including French', () {
    final expected = enStrings.keys.toSet();
    for (final entry in <String, Map<String, String>>{
      'tr': trStrings,
      'en': enStrings,
      'ar': arStrings,
      'az': azStrings,
      'ru': ruStrings,
      'fr': frStrings,
    }.entries) {
      expect(entry.value.keys.toSet(), expected, reason: entry.key);
      for (final value in entry.value.values) {
        expect(value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });

  test('French interface resolves French core navigation labels', () {
    final l10n = AppLocalizations(const Locale('fr'));
    expect(l10n.navHome, 'Accueil');
    expect(l10n.navDiscover, 'Découvrir');
    expect(l10n.settings, 'Réglages');
    expect(l10n.french, 'Français');
  });

  test('Arabic interface has an Arabic Quran title', () {
    final l10n = AppLocalizations(const Locale('ar'));
    expect(l10n.appTitle, contains('القرآن'));
  });

  test('primary legacy feature copy exists in every locale', () {
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
