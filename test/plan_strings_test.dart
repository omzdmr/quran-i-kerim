import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/plan_strings.dart';

void main() {
  test('plan strings keep the same non-empty key set in every locale', () {
    final expected = planStrings['tr']!.keys.toSet();
    expect(planStrings.keys, containsAll(<String>['tr', 'en', 'ar', 'az', 'ru']));

    for (final entry in planStrings.entries) {
      expect(entry.value.keys.toSet(), expected, reason: entry.key);
      for (final value in entry.value.values) {
        expect(value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });
}
