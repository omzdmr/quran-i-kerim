import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_practice_history_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';

void main() {
  test('coverage uses newest practice even if snapshot order is corrupted', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {60},
        practiceDays: const {},
        pageProgress: {
          60: MemorizationPageProgress(memorizedAt: DateTime(2026, 8, 1)),
        },
      ),
      practiceHistory: MemorizationPracticeHistorySnapshot([
        MemorizationPracticeEvent(
          id: 'old',
          page: 60,
          context: MemorizationPracticeContext.soloReview,
          occurredAt: DateTime(2026, 8, 10),
        ),
        MemorizationPracticeEvent(
          id: 'new',
          page: 60,
          context: MemorizationPracticeContext.prayer,
          occurredAt: DateTime(2026, 9, 21),
        ),
      ]),
      now: DateTime(2026, 9, 22),
    );

    expect(coverage.items.single.lastReviewedAt, DateTime(2026, 9, 21));
    expect(coverage.items.single.ageDays, 1);
    expect(coverage.items.single.freshness, MemorizationReviewFreshness.fresh);
  });
}
