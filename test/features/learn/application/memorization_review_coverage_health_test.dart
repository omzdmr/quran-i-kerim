import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';

void main() {
  test('same-day new work does not reduce otherwise healthy coverage', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {1, 2},
        practiceDays: const {},
        pageProgress: {
          1: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 9, 1),
            lastReviewedAt: DateTime(2026, 9, 22),
          ),
          2: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 9, 22, 10),
          ),
        },
      ),
      now: DateTime(2026, 9, 22, 20),
    );

    expect(coverage.freshCount, 1);
    expect(coverage.needsAttentionCount, 0);
    expect(coverage.coveredFraction, 1);
  });
}
