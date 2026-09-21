import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_history.dart';

void main() {
  test('legacy lastReviewedAt stays visible before detailed events exist', () {
    final reviewedAt = DateTime(2026, 9, 10, 9);
    final summary = buildMemorizationReviewHistory(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {42},
        practiceDays: const {},
        pageProgress: {
          42: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 8, 1),
            lastReviewedAt: reviewedAt,
            selfAssessment: MemorizationSelfAssessment.assisted,
          ),
        },
      ),
      history: const MemorizationPracticeHistorySnapshot([]),
      now: DateTime(2026, 9, 21),
    );

    expect(summary.isEmpty, isFalse);
    expect(summary.totalEvents, 0);
    expect(summary.reviewedPageCount, 1);
    expect(summary.pages.single.page, 42);
    expect(summary.pages.single.latestReviewAt, reviewedAt);
    expect(summary.pages.single.hasDetailedHistory, isFalse);
    expect(summary.pages.single.contexts, isEmpty);
  });

  test('legacy unknown context is hidden from context-specific filters', () {
    final progress = MemorizationProgressSnapshot(
      memorizedPages: const {42},
      practiceDays: const {},
      pageProgress: {
        42: MemorizationPageProgress(lastReviewedAt: DateTime(2026, 9, 10)),
      },
    );

    final prayerOnly = buildMemorizationReviewHistory(
      progress: progress,
      history: const MemorizationPracticeHistorySnapshot([]),
      now: DateTime(2026, 9, 21),
      filter: MemorizationReviewHistoryFilter.prayer,
    );

    expect(prayerOnly.pages, isEmpty);
  });
}
