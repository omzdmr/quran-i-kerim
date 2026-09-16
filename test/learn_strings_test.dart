import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/learn_strings.dart';

void main() {
  test('Learn lesson strings keep key parity across supported locales', () {
    final reference = learnStrings['tr']!.keys.toSet();
    for (final locale in <String>['tr', 'en', 'ar', 'az', 'ru']) {
      final values = learnStrings[locale];
      expect(values, isNotNull, reason: 'Missing Learn strings for $locale');
      expect(values!.keys.toSet(), reference, reason: 'Learn key mismatch for $locale');
      expect(
        values.values.every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: 'Learn contains an empty value for $locale',
      );
    }
  });
}
