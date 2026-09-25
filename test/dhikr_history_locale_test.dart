import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/dhikr_history_strings.dart';

void main() {
  test('dhikr history copy has exact six-locale key parity', () {
    const locales = <String>{'tr', 'en', 'fr', 'ar', 'az', 'ru'};
    expect(dhikrHistoryStrings.keys.toSet(), locales);
    final expected = dhikrHistoryStrings['en']!.keys.toSet();
    for (final locale in locales) {
      expect(
        dhikrHistoryStrings[locale]!.keys.toSet(),
        expected,
        reason: 'dhikr history keys differ for $locale',
      );
      for (final value in dhikrHistoryStrings[locale]!.values) {
        expect(value.trim(), isNotEmpty);
      }
    }
  });
}
