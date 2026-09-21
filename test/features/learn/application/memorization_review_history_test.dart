import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_history.dart';

void main() {
  final now = DateTime(2026, 9, 21, 12);

  MemorizationPracticeEvent event(
    String id,
    int page,
    MemorizationPracticeContext context,
    int daysAgo,
  ) => MemorizationPracticeEvent(
        id: id,
        page: page,
        context: context,
        occurredAt: now.subtract(Duration(days: daysAgo)),
      );

  test('summarizes recent review frequency and context diversity', () {
    final progress = MemorizationProgressSnapshot(
      memorizedPages: const {1, 2, 3},
      practiceDays: const {},
      pageProgress: {
        1: MemorizationPageProgress(
          selfAssessment: MemorizationSelfAssessment.independent,
        ),
      },
    );
    final history = MemorizationPracticeHistorySnapshot([
      event('a', 1, MemorizationPracticeContext.soloReview, 1),
      event('b', 1, MemorizationPracticeContext.prayer, 10),
      event('c', 1, MemorizationPracticeContext.recitedToSomeone, 40),
      event('d', 2, MemorizationPracticeContext.soloReview, 5),
      event('ignored-unmemorized', 99, MemorizationPracticeContext.soloReview, 1),
    ]);

    final result = buildMemorizationReviewHistory(
      progress: progress,
      history: history,
      now: now,
    );

    expect(result.totalEvents, 4);
    expect(result.recentEvents, 3);
    expect(result.reviewedPageCount, 2);
    expect(result.pages.map((item) => item.page), [1, 2]);
    expect(result.pages.first.totalReviews, 3);
    expect(result.pages.first.recentReviews, 2);
    expect(result.pages.first.contexts.length, 3);
    expect(
      result.pages.first.selfAssessment,
      MemorizationSelfAssessment.independent,
    );
  });

  test('filters history without mutating the underlying ledger', () {
    final progress = MemorizationProgressSnapshot(
      memorizedPages: const {1},
      practiceDays: const {},
    );
    final history = MemorizationPracticeHistorySnapshot([
      event('a', 1, MemorizationPracticeContext.soloReview, 1),
      event('b', 1, MemorizationPracticeContext.prayer, 2),
    ]);

    final prayerOnly = buildMemorizationReviewHistory(
      progress: progress,
      history: history,
      now: now,
      filter: MemorizationReviewHistoryFilter.prayer,
    );

    expect(prayerOnly.totalEvents, 1);
    expect(prayerOnly.pages.single.contexts, {
      MemorizationPracticeContext.prayer,
    });
    expect(history.events.length, 2);
  });

  test('rejects invalid recent window', () {
    expect(
      () => buildMemorizationReviewHistory(
        progress: const MemorizationProgressSnapshot(
          memorizedPages: {},
          practiceDays: {},
        ),
        history: const MemorizationPracticeHistorySnapshot([]),
        now: now,
        recentWindowDays: 0,
      ),
      throwsArgumentError,
    );
  });
}
