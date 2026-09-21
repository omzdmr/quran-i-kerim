import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';

void main() {
  test('orders never reviewed and oldest overdue pages first', () {
    final now = DateTime(2026, 9, 22, 12);
    final progress = MemorizationProgressSnapshot(
      memorizedPages: const {1, 2, 3, 4},
      practiceDays: const {},
      pageProgress: {
        1: MemorizationPageProgress(memorizedAt: DateTime(2026, 8, 1)),
        2: MemorizationPageProgress(
          memorizedAt: DateTime(2026, 8, 1),
          lastReviewedAt: DateTime(2026, 8, 20),
        ),
        3: MemorizationPageProgress(
          memorizedAt: DateTime(2026, 8, 1),
          lastReviewedAt: DateTime(2026, 9, 12),
        ),
        4: MemorizationPageProgress(
          memorizedAt: DateTime(2026, 8, 1),
          lastReviewedAt: DateTime(2026, 9, 21),
        ),
      },
    );

    final coverage = buildMemorizationReviewCoverage(progress: progress, now: now);

    expect(coverage.items.map((item) => item.page), [1, 2, 3, 4]);
    expect(coverage.neverReviewedCount, 1);
    expect(coverage.overdueCount, 1);
    expect(coverage.agingCount, 1);
    expect(coverage.freshCount, 1);
    expect(coverage.needsAttentionCount, 2);
    expect(coverage.coveredFraction, .75);
  });

  test('future timestamps are treated as fresh instead of negative age', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {9},
        practiceDays: const {},
        pageProgress: {
          9: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 9, 1),
            lastReviewedAt: DateTime(2026, 9, 23),
          ),
        },
      ),
      now: DateTime(2026, 9, 22),
    );

    expect(coverage.items.single.ageDays, 0);
    expect(coverage.items.single.freshness, MemorizationReviewFreshness.fresh);
  });

  test('rejects invalid age thresholds', () {
    expect(
      () => buildMemorizationReviewCoverage(
        progress: const MemorizationProgressSnapshot(
          memorizedPages: {},
          practiceDays: {},
        ),
        now: DateTime(2026, 9, 22),
        agingAfterDays: 14,
        overdueAfterDays: 7,
      ),
      throwsArgumentError,
    );
  });
}
