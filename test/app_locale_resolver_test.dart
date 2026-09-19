import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_locale_resolver.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  test('supported interface locales stay at the six declared languages', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      orderedEquals(const <String>['tr', 'en', 'ar', 'az', 'ru', 'fr']),
    );
  });

  test('stored supported locale overrides device locale', () {
    final locale = AppLocaleResolver.resolve(
      storedLanguageCode: 'fr',
      deviceLocales: const <Locale>[Locale('tr')],
    );

    expect(locale.languageCode, 'fr');
  });

  test('system mode follows a supported device locale', () {
    final locale = AppLocaleResolver.resolve(
      storedLanguageCode: 'system',
      deviceLocales: const <Locale>[Locale('fr', 'CA'), Locale('az')],
    );

    expect(locale.languageCode, 'fr');
  });

  test('unsupported device locales fall back to English', () {
    final locale = AppLocaleResolver.resolve(
      deviceLocales: const <Locale>[Locale('de'), Locale('es')],
    );

    expect(locale.languageCode, 'en');
  });
}
