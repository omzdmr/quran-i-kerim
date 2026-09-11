import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';

void main() {
  test('generated app title preserves all supported locale values', () async {
    const expected = <String, String>{
      'tr': 'Kur’an-ı Kerim',
      'en': 'Quran',
      'ar': 'القرآن الكريم',
      'az': 'Qurani-Kərim',
      'ru': 'Коран',
    };

    for (final entry in expected.entries) {
      final copy = await GeneratedAppLocalizations.delegate.load(
        Locale(entry.key),
      );
      expect(copy.appTitle, entry.value, reason: entry.key);
    }
  });
}
