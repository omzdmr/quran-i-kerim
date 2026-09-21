import 'memorization_review_coverage.dart';

/// A local-only review session derived from the user's memorized-page coverage.
///
/// This deliberately does not replace HIFZ_SYSTEM scheduling. It turns the
/// coverage ledger into a small, bounded action queue so an overdue backlog
/// never becomes an intimidating all-or-nothing task.
class MemorizationReviewSession {
  const MemorizationReviewSession({
    required this.pages,
    required this.totalAttentionPages,
  });

  final List<int> pages;
  final int totalAttentionPages;

  bool get isEmpty => pages.isEmpty;
  int get sessionSize => pages.length;
  int get deferredCount => (totalAttentionPages - pages.length).clamp(0, 1000000);
}

MemorizationReviewSession buildMemorizationReviewSession({
  required MemorizationReviewCoverage coverage,
  int maxPages = 5,
}) {
  if (maxPages < 1) {
    throw ArgumentError.value(maxPages, 'maxPages', 'Must be positive.');
  }

  final attention = coverage.items
      .where((item) => item.needsAttention)
      .map((item) => item.page)
      .toList(growable: false);

  return MemorizationReviewSession(
    pages: List<int>.unmodifiable(attention.take(maxPages)),
    totalAttentionPages: attention.length,
  );
}
