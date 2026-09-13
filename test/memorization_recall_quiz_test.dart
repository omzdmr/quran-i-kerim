import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_i_kerim/src/features/learn/application/memorization_recall_quiz.dart';

void main() {
  test('returns no recall question when nothing is memorized', () {
    expect(pickMemorizationRecallQuestion(<int>{}), isNull);
  });

  test('recall candidates stay inside memorized pages and continue by one ayah', () {
    final candidates = buildMemorizationRecallCandidates(<int>{1});

    expect(candidates, isNotEmpty);
    for (final question in candidates) {
      expect(question.answerAyah, question.ayah + 1);
      expect(quran.getPageNumber(question.surah, question.ayah), 1);
      expect(quran.getPageNumber(question.surah, question.answerAyah), 1);
      expect(question.promptArabic, isNotEmpty);
      expect(question.answerArabic, isNotEmpty);
    }
  });

  test('picker avoids immediately repeating the same question when possible', () {
    final candidates = buildMemorizationRecallCandidates(<int>{1});
    expect(candidates.length, greaterThan(1));

    final first = candidates.first;
    final next = pickMemorizationRecallQuestion(
      <int>{1},
      random: Random(4),
      previousId: first.id,
    );

    expect(next, isNotNull);
    expect(next!.id, isNot(first.id));
  });

  test('picker prioritizes weak recall questions when available', () {
    final candidates = buildMemorizationRecallCandidates(<int>{1});
    expect(candidates.length, greaterThan(1));
    final weak = candidates.last;

    final picked = pickMemorizationRecallQuestion(
      <int>{1},
      random: Random(1),
      preferredIds: <String>{weak.id},
    );

    expect(picked?.id, weak.id);
  });
}
