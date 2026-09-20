import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_locale_resolver.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  test('supported interface locales include the six declared languages', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      orderedEquals(const <String>['tr', 'en', 'ar', 'az', 'ru', 'fr']),
    );
  });

  test('stored supported locale overrides device locale', () {
    final locale = AppLocaleResolver.resolve(
      storedLanguageCode: 'ru',
      deviceLocales: const <Locale>[Locale('tr')],
    );

    expect(locale.languageCode, 'ru');
  });

  test('system mode follows a supported device locale', () {
    final locale = AppLocaleResolver.resolve(
      storedLanguageCode: 'system',
      deviceLocales: const <Locale>[Locale('az')],
    );

    expect(locale.languageCode, 'az');
  });

  test('stored French locale overrides device locale', () {
    final locale = AppLocaleResolver.resolve(
      storedLanguageCode: 'fr',
      deviceLocales: const <Locale>[Locale('tr')],
    );

    expect(locale.languageCode, 'fr');
  });

  test('system mode follows French device locale', () {
    final locale = AppLocaleResolver.resolve(
      storedLanguageCode: 'system',
      deviceLocales: const <Locale>[Locale('fr'), Locale('de')],
    );

    expect(locale.languageCode, 'fr');
  });

  test('unsupported device locales fall back to English', () {
    final locale = AppLocaleResolver.resolve(
      deviceLocales: const <Locale>[Locale('de'), Locale('it')],
    );

    expect(locale.languageCode, 'en');
  });
}
