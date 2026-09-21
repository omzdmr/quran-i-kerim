import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/qada_fasting_archive_strings.dart';

void main() {
  test('qada backup flow has exact key parity across six app languages', () {
    const languages = <String>['tr', 'en', 'fr', 'ar', 'az', 'ru'];
    final englishKeys = qadaFastingArchiveStrings['en']!.keys.toSet();
    expect(englishKeys, isNotEmpty);

    for (final language in languages) {
      final values = qadaFastingArchiveStrings[language];
      expect(values, isNotNull, reason: 'missing locale $language');
      expect(
        values!.keys.toSet(),
        englishKeys,
        reason: 'key mismatch for $language',
      );
      expect(
        values.values.every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: 'blank qada backup string for $language',
      );
    }
  });

  test('known locales do not silently fall back to English', () {
    expect(qadaFastingArchiveText('ar', 'merge'), 'دمج');
    expect(qadaFastingArchiveText('az', 'merge'), 'Birləşdir');
    expect(qadaFastingArchiveText('ru', 'merge'), 'Объединить');
    expect(qadaFastingArchiveText('fr', 'merge'), 'Fusionner');
  });

  test('unknown locale safely falls back to English', () {
    expect(qadaFastingArchiveText('xx', 'merge'), 'Merge');
  });
}
