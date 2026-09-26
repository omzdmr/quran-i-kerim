import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/qada_fasting_strings.dart';

void main() {
  test('all supported qada fasting locales have exact non-empty key parity', () {
    const locales = <String>{'tr', 'en', 'ar', 'az', 'ru', 'fr'};
    expect(qadaFastingStrings.keys.toSet(), locales);

    final referenceKeys = qadaFastingStrings['en']!.keys.toSet();
    for (final locale in locales) {
      final values = qadaFastingStrings[locale]!;
      expect(values.keys.toSet(), referenceKeys, reason: locale);
      expect(
        values.values.every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: locale,
      );
    }
  });

  test('unknown locale and key use deterministic fallback behavior', () {
    expect(qadaFastingText('de', 'title'), qadaFastingStrings['en']!['title']);
    expect(qadaFastingText('en', 'missing-key'), 'missing-key');
  });
}
