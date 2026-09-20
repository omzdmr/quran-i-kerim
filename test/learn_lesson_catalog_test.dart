import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_i_kerim/src/features/learn/application/learn_lesson_catalog.dart';

void main() {
  test('curated Learn lesson catalog has unique valid Quran references', () {
    expect(curatedLearnLessons, isNotEmpty);

    final ids = <String>{};
    final quizCorrectPositions = <int>{};
    for (final lesson in curatedLearnLessons) {
      expect(lesson.id.trim(), isNotEmpty);
      expect(ids.add(lesson.id), isTrue, reason: 'Duplicate lesson id: ${lesson.id}');
      expect(lesson.surah, inInclusiveRange(1, 114));
      expect(lesson.ayahs, isNotEmpty);

      final verseCount = quran.getVerseCount(lesson.surah);
      final seenAyahs = <int>{};
      for (final ayah in lesson.ayahs) {
        expect(ayah, inInclusiveRange(1, verseCount));
        expect(
          seenAyahs.add(ayah),
          isTrue,
          reason: 'Duplicate ayah ${lesson.surah}:$ayah in ${lesson.id}',
        );
      }

      final seenDistractors = <int>{};
      for (final distractor in lesson.quizDistractorSurahs) {
        expect(distractor, inInclusiveRange(1, 114));
        expect(distractor, isNot(lesson.surah));
        expect(
          seenDistractors.add(distractor),
          isTrue,
          reason: 'Duplicate quiz distractor $distractor in ${lesson.id}',
        );
      }
      expect(
        lesson.quizCorrectOptionIndex,
        inInclusiveRange(0, lesson.quizDistractorSurahs.length),
        reason: 'Invalid quiz answer position in ${lesson.id}',
      );
      quizCorrectPositions.add(lesson.quizCorrectOptionIndex);
    }

    expect(
      quizCorrectPositions.length,
      greaterThan(1),
      reason: 'Curated lessons should not train users to pick one fixed option.',
    );
  });
}
