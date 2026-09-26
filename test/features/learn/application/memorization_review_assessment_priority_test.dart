import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';

void main() {
  test('struggled page wins when review age is tied', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {40, 41, 42},
        practiceDays: const {},
        pageProgress: {
          40: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 8, 1),
            lastReviewedAt: DateTime(2026, 8, 20),
            selfAssessment: MemorizationSelfAssessment.independent,
          ),
          41: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 8, 1),
            lastReviewedAt: DateTime(2026, 8, 20),
            selfAssessment: MemorizationSelfAssessment.struggled,
          ),
          42: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 8, 1),
            lastReviewedAt: DateTime(2026, 8, 20),
            selfAssessment: MemorizationSelfAssessment.assisted,
          ),
        },
      ),
      now: DateTime(2026, 9, 22),
    );

    expect(coverage.items.map((item) => item.page), [41, 42, 40]);
    expect(coverage.nextAttentionItem?.page, 41);
  });
}
