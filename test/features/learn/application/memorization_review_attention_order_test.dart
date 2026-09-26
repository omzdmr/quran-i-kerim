import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';

void main() {
  test('old overdue review outranks a recently untouched page', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {100, 200},
        practiceDays: const {},
        pageProgress: {
          100: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 9, 20),
          ),
          200: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 1, 1),
            lastReviewedAt: DateTime(2026, 6, 1),
          ),
        },
      ),
      now: DateTime(2026, 9, 22),
    );

    expect(coverage.items.map((item) => item.page), [200, 100]);
    expect(coverage.items.first.freshness, MemorizationReviewFreshness.overdue);
    expect(coverage.items.last.freshness, MemorizationReviewFreshness.neverReviewed);
    expect(coverage.items.every((item) => item.needsAttention), isTrue);
  });

  test('same-day new page stays behind current reviewed pages', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {1, 2},
        practiceDays: const {},
        pageProgress: {
          1: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 9, 22, 8),
          ),
          2: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 9, 1),
            lastReviewedAt: DateTime(2026, 9, 21),
          ),
        },
      ),
      now: DateTime(2026, 9, 22, 20),
    );

    expect(coverage.items.map((item) => item.page), [2, 1]);
    expect(coverage.items.last.needsAttention, isFalse);
  });
}
