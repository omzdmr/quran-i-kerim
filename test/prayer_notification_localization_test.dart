import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_locale_resolver.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';

void main() {
  test('notification copy resolves through every supported app locale', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = AppLocalizations(locale);
      expect(l10n.prayerNotificationTitle('fajr'), isNotEmpty);
      expect(l10n.prayerNotificationBody('fajr'), isNotEmpty);
      expect(l10n.prayerNotificationTitle('fajr'), isNot(contains('{prayer}')));
      expect(l10n.prayerNotificationBody('fajr'), isNot(contains('{prayer}')));
      expect(l10n.prayerNotificationChannel, isNotEmpty);
      expect(l10n.prayerNotificationChannelDescription, isNotEmpty);
    }

    expect(
      AppLocalizations(const Locale('ru')).prayerNotificationTitle('fajr'),
      'Время: Фаджр',
    );
    expect(
      AppLocalizations(const Locale('az')).prayerNotificationBody('isha'),
      'İşa vaxtı daxil oldu.',
    );
  });

  test('stored app locale wins over the device locale', () {
    expect(
      AppLocaleResolver.resolve(
        storedLanguageCode: 'ru',
        deviceLocales: const <Locale>[Locale('en')],
      ),
      const Locale('ru'),
    );
  });

  test('system locale follows supported device locale and falls back to English', () {
    expect(
      AppLocaleResolver.resolve(
        storedLanguageCode: 'system',
        deviceLocales: const <Locale>[Locale('az')],
      ),
      const Locale('az'),
    );
    expect(
      AppLocaleResolver.resolve(
        storedLanguageCode: 'system',
        deviceLocales: const <Locale>[Locale('nl')],
      ),
      const Locale('en'),
    );
  });
}
