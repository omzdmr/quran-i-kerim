import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_i_kerim/src/features/learn/application/memorization_juz_review.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_page_catalog.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_recall_quiz.dart';

void main() {
  Set<int> pagesForJuz(int juz) =>
      memorizationPagesForJuz(juz).map((page) => page.page).toSet();

  test('completedMemorizedJuz requires the full juz page set', () {
    final pages = pagesForJuz(1).toList()..sort();
    final incomplete = MemorizationProgressSnapshot(
      memorizedPages: pages.take(pages.length - 1).toSet(),
      practiceDays: const {},
    );
    final complete = MemorizationProgressSnapshot(
      memorizedPages: pages.toSet(),
      practiceDays: const {},
    );

    expect(completedMemorizedJuz(incomplete), isNot(contains(1)));
    expect(completedMemorizedJuz(complete), contains(1));
  });

  test('juz review only uses continuations inside the selected juz', () {
    final pages = pagesForJuz(1);
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: pages,
      practiceDays: const {},
    );

    final questions = buildJuzReviewQuestions(
      snapshot,
      1,
      maxQuestions: 10,
      random: Random(3),
    );

    expect(questions, isNotEmpty);
    expect(questions.length, lessThanOrEqualTo(10));
    expect(questions.map((question) => question.id).toSet().length, questions.length);
    expect(
      questions.every(
        (question) =>
            quran.getJuzNumber(question.surah, question.ayah) == 1 &&
            quran.getJuzNumber(question.surah, question.answerAyah) == 1,
      ),
      isTrue,
    );
  });

  test('juz review prioritizes weak verse ids', () {
    final pages = pagesForJuz(1);
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: pages,
      practiceDays: const {},
    );
    final preferred = buildMemorizationRecallCandidates(pages).firstWhere(
      (question) =>
          quran.getJuzNumber(question.surah, question.ayah) == 1 &&
          quran.getJuzNumber(question.surah, question.answerAyah) == 1,
    );

    final questions = buildJuzReviewQuestions(
      snapshot,
      1,
      maxQuestions: 1,
      random: Random(5),
      preferredIds: {preferred.id},
    );

    expect(questions.single.id, preferred.id);
  });

  test('juz review stays locked until that juz is complete', () {
    final pages = pagesForJuz(1).toList()..sort();
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: pages.take(pages.length - 1).toSet(),
      practiceDays: const {},
    );

    expect(buildJuzReviewQuestions(snapshot, 1), isEmpty);
  });
}
