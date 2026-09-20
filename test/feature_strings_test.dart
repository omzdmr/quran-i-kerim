import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/feature_strings.dart';

void main() {
  test('general feature strings keep key parity in every core locale', () {
    const locales = <String>['tr', 'en', 'ar', 'az', 'ru', 'fr'];
    final expected = featureStrings['en']!.keys.toSet();

    expect(featureStrings.keys, containsAll(locales));

    for (final locale in locales) {
      final values = featureStrings[locale];
      expect(values, isNotNull, reason: 'Missing feature strings for $locale');
      expect(
        values!.keys.toSet(),
        expected,
        reason: 'Feature string key mismatch for $locale',
      );
      expect(
        values.values.every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: 'Feature strings contain an empty value for $locale',
      );
    }
  });
}
