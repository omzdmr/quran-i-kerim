import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_i_kerim/src/features/learn/application/memorization_hint_quiz.dart';

void main() {
  test('candidates stay inside memorized pages and hide the remaining verse', () {
    const page = 1;

    final candidates = buildMemorizationHintCandidates(
      const <int>{page},
      hintWordCount: 2,
    );

    expect(candidates, isNotEmpty);
    for (final question in candidates) {
      expect(question.page, page);
      expect(quran.getPageNumber(question.surah, question.ayah), page);
      expect(question.hintWordCount, 2);
      expect(question.answerArabic, startsWith(question.hintArabic));
      expect(question.answerArabic, isNot(question.hintArabic));
      expect(question.id, '${question.surah}:${question.ayah}');
    }
  });

  test('candidate builder rejects non-positive hint word counts', () {
    expect(
      () => buildMemorizationHintCandidates(const <int>{1}, hintWordCount: 0),
      throwsArgumentError,
    );
  });

  test('picker avoids the previous question when alternatives exist', () {
    final candidates = buildMemorizationHintCandidates(const <int>{1});
    expect(candidates.length, greaterThan(1));

    final previousId = candidates.first.id;
    final picked = pickMemorizationHintQuestion(
      const <int>{1},
      random: Random(7),
      previousId: previousId,
    );

    expect(picked, isNotNull);
    expect(picked!.id, isNot(previousId));
  });

  test('picker restricts selection to available preferred ids', () {
    final candidates = buildMemorizationHintCandidates(const <int>{1});
    expect(candidates.length, greaterThan(1));
    final preferredId = candidates.last.id;

    final picked = pickMemorizationHintQuestion(
      const <int>{1},
      random: Random(11),
      preferredIds: <String>{preferredId, '999:999'},
    );

    expect(picked?.id, preferredId);
  });

  test('picker returns null when no memorized pages are available', () {
    expect(
      pickMemorizationHintQuestion(const <int>{}, random: Random(1)),
      isNull,
    );
  });
}
