import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_locale_resolver.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  test('supported interface locales stay at the five declared languages', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      orderedEquals(const <String>['tr', 'en', 'ar', 'az', 'ru']),
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

  test('unsupported device locales fall back to English', () {
    final locale = AppLocaleResolver.resolve(
      deviceLocales: const <Locale>[Locale('de'), Locale('fr')],
    );

    expect(locale.languageCode, 'en');
  });
}
