import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_i_kerim/src/features/learn/application/memorization_hint_quiz.dart';

void main() {
  test('returns no hint question when nothing is memorized', () {
    expect(pickMemorizationHintQuestion(<int>{}), isNull);
  });

  test('hint candidates stay inside memorized pages', () {
    final candidates = buildMemorizationHintCandidates(<int>{1});

    expect(candidates, isNotEmpty);
    for (final question in candidates) {
      expect(quran.getPageNumber(question.surah, question.ayah), 1);
      expect(question.hintArabic, isNotEmpty);
      expect(question.answerArabic, isNotEmpty);
      expect(question.answerArabic.startsWith(question.hintArabic), isTrue);
      expect(question.answerArabic, isNot(question.hintArabic));
    }
  });

  test('default hint exposes exactly the first two words', () {
    final question = buildMemorizationHintCandidates(<int>{1}).first;
    final words = question.answerArabic.trim().split(RegExp(r'\s+'));

    expect(question.hintWordCount, 2);
    expect(question.hintArabic, words.take(2).join(' '));
  });

  test('picker avoids immediately repeating the same hint when possible', () {
    final candidates = buildMemorizationHintCandidates(<int>{1});
    expect(candidates.length, greaterThan(1));

    final first = candidates.first;
    final next = pickMemorizationHintQuestion(
      <int>{1},
      random: Random(7),
      previousId: first.id,
    );

    expect(next, isNotNull);
    expect(next!.id, isNot(first.id));
  });

  test('picker prioritizes weak verses when available', () {
    final candidates = buildMemorizationHintCandidates(<int>{1});
    expect(candidates.length, greaterThan(1));
    final weak = candidates.last;

    final picked = pickMemorizationHintQuestion(
      <int>{1},
      random: Random(2),
      preferredIds: <String>{weak.id},
    );

    expect(picked?.id, weak.id);
  });

  test('rejects non-positive hint length', () {
    expect(
      () => buildMemorizationHintCandidates(<int>{1}, hintWordCount: 0),
      throwsArgumentError,
    );
  });
}
