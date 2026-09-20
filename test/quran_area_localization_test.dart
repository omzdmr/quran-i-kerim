import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';

void main() {
  test('Quran area navigation labels are localized for supported locales', () async {
    const expected = <String, ({String read, String learn, String progress})>{
      'tr': (read: 'Oku', learn: 'Öğren', progress: 'İlerlemem'),
      'en': (read: 'Read', learn: 'Learn', progress: 'Progress'),
      'ar': (read: 'اقرأ', learn: 'تعلّم', progress: 'التقدّم'),
      'az': (read: 'Oxu', learn: 'Öyrən', progress: 'İrəliləyişim'),
      'ru': (read: 'Читать', learn: 'Изучать', progress: 'Прогресс'),
    };

    for (final entry in expected.entries) {
      final copy = await GeneratedAppLocalizations.delegate.load(
        Locale(entry.key),
      );
      expect(copy.quranTabRead, entry.value.read, reason: '${entry.key} read');
      expect(copy.quranTabLearn, entry.value.learn, reason: '${entry.key} learn');
      expect(
        copy.quranTabProgress,
        entry.value.progress,
        reason: '${entry.key} progress',
      );
    }
  });
}
