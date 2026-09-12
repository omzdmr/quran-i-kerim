import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';

void main() {
  test('reference-inspired Quran surfaces are localized in every supported locale', () async {
    for (final code in const ['tr', 'en', 'ar', 'az', 'ru']) {
      final copy = await GeneratedAppLocalizations.delegate.load(Locale(code));
      expect(copy.quranLearnFlowTitle, isNotEmpty, reason: '$code lesson flow');
      expect(copy.quranProgressReading, isNotEmpty, reason: '$code reading progress');
      expect(copy.quranProgressKhatm, isNotEmpty, reason: '$code khatm progress');
      expect(copy.memorizeTitle, isNotEmpty, reason: '$code memorize');
      expect(copy.memorizeMapTitle, isNotEmpty, reason: '$code memorize map');
    }
  });
}
