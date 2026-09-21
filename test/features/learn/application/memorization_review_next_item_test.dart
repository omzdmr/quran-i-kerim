import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_progress_store.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_review_coverage.dart';

void main() {
  test('next attention item matches age-prioritized queue head', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {4, 5},
        practiceDays: const {},
        pageProgress: {
          4: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 8, 1),
            lastReviewedAt: DateTime(2026, 9, 1),
          ),
          5: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 9, 20),
          ),
        },
      ),
      now: DateTime(2026, 9, 22),
    );

    expect(coverage.nextAttentionItem?.page, 4);
  });

  test('next attention item is null when no review debt is due', () {
    final coverage = buildMemorizationReviewCoverage(
      progress: MemorizationProgressSnapshot(
        memorizedPages: const {6},
        practiceDays: const {},
        pageProgress: {
          6: MemorizationPageProgress(
            memorizedAt: DateTime(2026, 9, 1),
            lastReviewedAt: DateTime(2026, 9, 22),
          ),
        },
      ),
      now: DateTime(2026, 9, 22),
    );

    expect(coverage.nextAttentionItem, isNull);
  });
}
