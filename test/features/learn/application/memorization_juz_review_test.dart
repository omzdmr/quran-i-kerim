import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_juz_review.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_page_catalog.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';

void main() {
  test('completedMemorizedJuz requires every page in the juz', () {
    final juzPages = memorizationPagesForJuz(30).map((page) => page.page).toSet();
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: juzPages,
      practiceDays: const <String>{},
    );

    expect(completedMemorizedJuz(snapshot), contains(30));

    final incomplete = MemorizationProgressSnapshot(
      memorizedPages: {...juzPages}..remove(juzPages.first),
      practiceDays: const <String>{},
    );
    expect(completedMemorizedJuz(incomplete), isNot(contains(30)));
  });

  test('juz review stays inside the completed juz and respects its limit', () {
    final juzPages = memorizationPagesForJuz(30).map((page) => page.page).toSet();
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: juzPages,
      practiceDays: const <String>{},
    );

    final questions = buildJuzReviewQuestions(
      snapshot,
      30,
      maxQuestions: 5,
      random: Random(7),
    );

    expect(questions, isNotEmpty);
    expect(questions.length, lessThanOrEqualTo(5));
    expect(
      questions.every((question) => juzPages.contains(question.page)),
      isTrue,
    );
    expect(
      questions.every((question) => juzPages.contains(question.answerPage)),
      isTrue,
    );
  });

  test('juz review is unavailable until the selected juz is complete', () {
    final juzPages = memorizationPagesForJuz(30).map((page) => page.page).toSet();
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: {...juzPages}..remove(juzPages.first),
      practiceDays: const <String>{},
    );

    expect(
      buildJuzReviewQuestions(snapshot, 30, random: Random(1)),
      isEmpty,
    );
  });

  test('juz review rejects invalid juz and question limits', () {
    const snapshot = MemorizationProgressSnapshot(
      memorizedPages: <int>{},
      practiceDays: <String>{},
    );

    expect(buildJuzReviewQuestions(snapshot, 0), isEmpty);
    expect(buildJuzReviewQuestions(snapshot, 31), isEmpty);
    expect(buildJuzReviewQuestions(snapshot, 30, maxQuestions: 0), isEmpty);
  });
}
