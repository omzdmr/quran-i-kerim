import 'memorization_progress_store.dart';

enum MemorizationReviewFreshness { neverReviewed, overdue, aging, fresh }

class MemorizationReviewCoverageItem {
  const MemorizationReviewCoverageItem({
    required this.page,
    required this.freshness,
    required this.ageDays,
    required this.lastReviewedAt,
    required this.selfAssessment,
  });

  final int page;
  final MemorizationReviewFreshness freshness;
  final int? ageDays;
  final DateTime? lastReviewedAt;
  final MemorizationSelfAssessment? selfAssessment;

  bool get needsAttention =>
      freshness == MemorizationReviewFreshness.neverReviewed ||
      freshness == MemorizationReviewFreshness.overdue;
}

class MemorizationReviewCoverage {
  const MemorizationReviewCoverage({
    required this.items,
    required this.neverReviewedCount,
    required this.overdueCount,
    required this.agingCount,
    required this.freshCount,
  });

  final List<MemorizationReviewCoverageItem> items;
  final int neverReviewedCount;
  final int overdueCount;
  final int agingCount;
  final int freshCount;

  int get total => items.length;
  int get needsAttentionCount => neverReviewedCount + overdueCount;
  double get coveredFraction => total == 0 ? 0 : (total - neverReviewedCount) / total;
}

MemorizationReviewCoverage buildMemorizationReviewCoverage({
  required MemorizationProgressSnapshot progress,
  required DateTime now,
  int agingAfterDays = 7,
  int overdueAfterDays = 14,
}) {
  if (agingAfterDays < 1 || overdueAfterDays <= agingAfterDays) {
    throw ArgumentError('Review age thresholds must be ordered and positive.');
  }

  final today = DateTime(now.year, now.month, now.day);
  final items = <MemorizationReviewCoverageItem>[];
  var neverReviewed = 0;
  var overdue = 0;
  var aging = 0;
  var fresh = 0;

  final pages = progress.memorizedPages.toList()..sort();
  for (final page in pages) {
    final pageProgress = progress.progressForPage(page);
    final reviewedAt = pageProgress?.lastReviewedAt;
    int? ageDays;
    late MemorizationReviewFreshness freshness;

    if (reviewedAt == null) {
      freshness = MemorizationReviewFreshness.neverReviewed;
      neverReviewed++;
    } else {
      final reviewedDay = DateTime(reviewedAt.year, reviewedAt.month, reviewedAt.day);
      ageDays = today.difference(reviewedDay).inDays.clamp(0, 1000000);
      if (ageDays >= overdueAfterDays) {
        freshness = MemorizationReviewFreshness.overdue;
        overdue++;
      } else if (ageDays >= agingAfterDays) {
        freshness = MemorizationReviewFreshness.aging;
        aging++;
      } else {
        freshness = MemorizationReviewFreshness.fresh;
        fresh++;
      }
    }

    items.add(MemorizationReviewCoverageItem(
      page: page,
      freshness: freshness,
      ageDays: ageDays,
      lastReviewedAt: reviewedAt,
      selfAssessment: pageProgress?.selfAssessment,
    ));
  }

  int rank(MemorizationReviewFreshness value) => switch (value) {
        MemorizationReviewFreshness.neverReviewed => 0,
        MemorizationReviewFreshness.overdue => 1,
        MemorizationReviewFreshness.aging => 2,
        MemorizationReviewFreshness.fresh => 3,
      };

  items.sort((a, b) {
    final freshness = rank(a.freshness).compareTo(rank(b.freshness));
    if (freshness != 0) return freshness;
    final age = (b.ageDays ?? 1000001).compareTo(a.ageDays ?? 1000001);
    if (age != 0) return age;
    return a.page.compareTo(b.page);
  });

  return MemorizationReviewCoverage(
    items: List.unmodifiable(items),
    neverReviewedCount: neverReviewed,
    overdueCount: overdue,
    agingCount: aging,
    freshCount: fresh,
  );
}
