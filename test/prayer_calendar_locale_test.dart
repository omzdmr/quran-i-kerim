import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/prayer_calendar_strings.dart';

void main() {
  test('prayer calendar export copy has six-locale key parity', () {
    const locales = <String>{'tr', 'en', 'fr', 'ar', 'az', 'ru'};
    expect(prayerCalendarStrings.keys.toSet(), locales);
    final expected = prayerCalendarStrings['en']!.keys.toSet();
    for (final locale in locales) {
      expect(prayerCalendarStrings[locale]!.keys.toSet(), expected);
      expect(
        prayerCalendarStrings[locale]!.values.every((value) => value.trim().isNotEmpty),
        isTrue,
      );
    }
  });
}
