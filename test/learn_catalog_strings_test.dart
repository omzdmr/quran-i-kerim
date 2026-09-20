import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/learn_catalog_strings.dart';

void main() {
  test('Learn catalog progress strings keep locale and placeholder parity', () {
    final reference = learnCatalogStrings['tr']!.keys.toSet();
    for (final locale in <String>['tr', 'en', 'ar', 'az', 'ru', 'fr']) {
      final values = learnCatalogStrings[locale];
      expect(
        values,
        isNotNull,
        reason: 'Missing Learn catalog strings for $locale',
      );
      expect(
        values!.keys.toSet(),
        reference,
        reason: 'Learn catalog key mismatch for $locale',
      );
      for (final value in values.values) {
        expect(value.trim(), isNotEmpty);
        expect(value, contains('{completed}'));
        expect(value, contains('{total}'));
      }
    }
  });
}
