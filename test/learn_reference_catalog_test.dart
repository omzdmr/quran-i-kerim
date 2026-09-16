import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/learn_reference_catalog.dart';
import 'package:quran_i_kerim/src/l10n/strings/learn_reference_strings.dart';

void main() {
  test('Learn reference catalog has unique ids and safe source URLs', () {
    expect(curatedLearnReferences, isNotEmpty);
    final ids = <String>{};
    for (final reference in curatedLearnReferences) {
      expect(reference.id.trim(), isNotEmpty);
      expect(
        ids.add(reference.id),
        isTrue,
        reason: 'Duplicate Learn reference id: ${reference.id}',
      );
      final rawUrl = reference.sourceUrl;
      if (rawUrl != null) {
        final uri = Uri.tryParse(rawUrl);
        expect(uri, isNotNull, reason: 'Invalid source URL for ${reference.id}');
        expect(uri!.scheme, 'https');
        expect(uri.host, isNotEmpty);
      }
    }
  });

  test('Learn reference strings cover every catalog item in every locale', () {
    final referenceKeys = learnReferenceStrings['tr']!.keys.toSet();
    for (final locale in <String>['tr', 'en', 'ar', 'az', 'ru']) {
      final values = learnReferenceStrings[locale];
      expect(values, isNotNull, reason: 'Missing Learn reference strings for $locale');
      expect(
        values!.keys.toSet(),
        referenceKeys,
        reason: 'Learn reference key mismatch for $locale',
      );
      for (final item in curatedLearnReferences) {
        for (final key in <String>[
          item.titleKey,
          item.summaryKey,
          item.bodyKey,
        ]) {
          expect(
            values[key]?.trim(),
            isNotEmpty,
            reason: 'Missing $key for $locale (${item.id})',
          );
        }
      }
    }
  });
}
