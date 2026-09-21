import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';

void main() {
  test('newly memorized page is tracked but not immediate review debt', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {7},
        practiceDays: const {},
        pageProgress: {
          7: MemorizationPageProgress(memorizedAt: DateTime(2026, 9, 22, 8)),
        },
      ),
      now: DateTime(2026, 9, 22, 20),
    );

    expect(coverage.neverReviewedCount, 1);
    expect(coverage.needsAttentionCount, 0);
    expect(coverage.items.single.needsAttention, isFalse);
    expect(coverage.items.single.ageDays, 0);
  });

  test('untouched page enters attention queue the following day', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {7},
        practiceDays: const {},
        pageProgress: {
          7: MemorizationPageProgress(memorizedAt: DateTime(2026, 9, 22, 8)),
        },
      ),
      now: DateTime(2026, 9, 23, 8),
    );

    expect(coverage.needsAttentionCount, 1);
    expect(coverage.items.single.needsAttention, isTrue);
    expect(coverage.items.single.ageDays, 1);
  });
}
