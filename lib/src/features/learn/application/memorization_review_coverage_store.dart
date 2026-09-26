import 'memorization_practice_history_store.dart';
import 'memorization_progress_store.dart';
import 'memorization_review_coverage.dart';

/// Local-only read model for the Hifz review coverage surface.
///
/// Keeping the join here prevents UI code from accidentally computing coverage
/// from only one persistence source. Explicit recall reviews and ordinary
/// practice-history events both contribute to the same freshness picture.
class MemorizationReviewCoverageStore {
  const MemorizationReviewCoverageStore({
    this.progressStore = const MemorizationProgressStore(),
    this.practiceStore = const MemorizationPracticeHistoryStore(),
  });

  final MemorizationProgressStore progressStore;
  final MemorizationPracticeHistoryStore practiceStore;

  Future<MemorizationReviewCoverage> load({DateTime? now}) async {
    final progressFuture = progressStore.load();
    final practiceFuture = practiceStore.load();
    final progress = await progressFuture;
    final practice = await practiceFuture;
    return buildMemorizationReviewCoverage(
      progress: progress,
      practiceHistory: practice,
      now: now ?? DateTime.now(),
    );
  }
}
