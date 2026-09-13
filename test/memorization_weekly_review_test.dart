import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_recall_quiz.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_weekly_review.dart';

void main() {
  test('weeklyMemorizedPages uses the last seven local calendar days', () {
    final now = DateTime(2026, 9, 13, 18, 30);
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: const {1, 2, 3, 4},
      practiceDays: const {},
      pageProgress: {
        1: MemorizationPageProgress(
          memorizedAt: now.subtract(const Duration(days: 1)),
        ),
        2: MemorizationPageProgress(
          memorizedAt: DateTime(2026, 9, 7, 0, 1),
        ),
        3: MemorizationPageProgress(
          memorizedAt: DateTime(2026, 9, 6, 23, 59),
        ),
        4: const MemorizationPageProgress(),
      },
    );

    expect(
      weeklyMemorizedPages(snapshot, now: now),
      equals(<int>{1, 2}),
    );
  });

  test('weekly questions only prompt from recently memorized pages', () {
    final now = DateTime(2026, 9, 13, 12);
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: const {1, 2},
      practiceDays: const {},
      pageProgress: {
        1: MemorizationPageProgress(
          memorizedAt: now.subtract(const Duration(days: 2)),
        ),
        2: MemorizationPageProgress(
          memorizedAt: now.subtract(const Duration(days: 20)),
        ),
      },
    );

    final questions = buildWeeklyReviewQuestions(
      snapshot,
      now: now,
      maxQuestions: 3,
      random: Random(2),
    );

    expect(questions, isNotEmpty);
    expect(questions.length, lessThanOrEqualTo(3));
    expect(questions.every((question) => question.page == 1), isTrue);
    expect(questions.map((question) => question.id).toSet().length, questions.length);
  });

  test('weekly questions prioritize known weak verse ids', () {
    final now = DateTime(2026, 9, 13, 12);
    final snapshot = MemorizationProgressSnapshot(
      memorizedPages: const {1, 2},
      practiceDays: const {},
      pageProgress: {
        1: MemorizationPageProgress(memorizedAt: now),
        2: MemorizationPageProgress(
          memorizedAt: now.subtract(const Duration(days: 20)),
        ),
      },
    );
    final preferred = buildMemorizationRecallCandidates(const {1, 2})
        .firstWhere((question) => question.page == 1);

    final questions = buildWeeklyReviewQuestions(
      snapshot,
      now: now,
      maxQuestions: 1,
      random: Random(4),
      preferredIds: {preferred.id},
    );

    expect(questions.single.id, preferred.id);
  });
}
