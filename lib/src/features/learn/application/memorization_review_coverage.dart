import 'memorization_practice_history_store.dart';
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
      freshness == MemorizationReviewFreshness.overdue ||
      (freshness == MemorizationReviewFreshness.neverReviewed &&
          (ageDays == null || ageDays! >= 1));
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
  int get needsAttentionCount =>
      items.where((item) => item.needsAttention).length;

  MemorizationReviewCoverageItem? get nextAttentionItem {
    for (final item in items) {
      if (item.needsAttention) return item;
    }
    return null;
  }

  double get coveredFraction {
    final notDueNewPages = items
        .where(
          (item) =>
              item.freshness == MemorizationReviewFreshness.neverReviewed &&
              !item.needsAttention,
        )
        .length;
    final dueTotal = total - notDueNewPages;
    return dueTotal == 0 ? 1 : (agingCount + freshCount) / dueTotal;
  }
}

DateTime? _latest(DateTime? left, DateTime? right) {
  if (left == null) return right;
  if (right == null) return left;
  return left.isAfter(right) ? left : right;
}

int _ageInDays(DateTime nowDay, DateTime value) {
  final valueDay = DateTime(value.year, value.month, value.day);
  return nowDay.difference(valueDay).inDays.clamp(0, 1000000).toInt();
}

int _assessmentPriority(MemorizationSelfAssessment? value) => switch (value) {
      MemorizationSelfAssessment.struggled => 0,
      MemorizationSelfAssessment.assisted => 1,
      MemorizationSelfAssessment.independent => 2,
      null => 3,
    };

Map<int, DateTime> _latestPracticeByPage(
  MemorizationPracticeHistorySnapshot? history,
) {
  final latest = <int, DateTime>{};
  if (history == null) return latest;
  for (final event in history.events) {
    final previous = latest[event.page];
    if (previous == null || event.occurredAt.isAfter(previous)) {
      latest[event.page] = event.occurredAt;
    }
  }
  return latest;
}

MemorizationReviewCoverage buildMemorizationReviewCoverage({
  required MemorizationProgressSnapshot progress,
  required DateTime now,
  MemorizationPracticeHistorySnapshot? practiceHistory,
  int agingAfterDays = 7,
  int overdueAfterDays = 14,
}) {
  if (agingAfterDays < 1 || overdueAfterDays <= agingAfterDays) {
    throw ArgumentError('Review age thresholds must be ordered and positive.');
  }

  final today = DateTime(now.year, now.month, now.day);
  final latestPracticeAt = _latestPracticeByPage(practiceHistory);
  final items = <MemorizationReviewCoverageItem>[];
  var neverReviewed = 0;
  var overdue = 0;
  var aging = 0;
  var fresh = 0;

  final pages = progress.memorizedPages.toList()..sort();
  for (final page in pages) {
    final pageProgress = progress.progressForPage(page);
    final reviewedAt = _latest(
      pageProgress?.lastReviewedAt,
      latestPracticeAt[page],
    );
    int? ageDays;
    late MemorizationReviewFreshness freshness;

    if (reviewedAt == null) {
      freshness = MemorizationReviewFreshness.neverReviewed;
      final memorizedAt = pageProgress?.memorizedAt;
      if (memorizedAt != null) ageDays = _ageInDays(today, memorizedAt);
      neverReviewed++;
    } else {
      ageDays = _ageInDays(today, reviewedAt);
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

    items.add(
      MemorizationReviewCoverageItem(
        page: page,
        freshness: freshness,
        ageDays: ageDays,
        lastReviewedAt: reviewedAt,
        selfAssessment: pageProgress?.selfAssessment,
      ),
    );
  }

  int rank(MemorizationReviewCoverageItem item) {
    if (item.needsAttention) return 0;
    return switch (item.freshness) {
      MemorizationReviewFreshness.aging => 1,
      MemorizationReviewFreshness.fresh => 2,
      MemorizationReviewFreshness.neverReviewed => 3,
      MemorizationReviewFreshness.overdue => 0,
    };
  }

  items.sort((a, b) {
    final priority = rank(a).compareTo(rank(b));
    if (priority != 0) return priority;
    final age = (b.ageDays ?? -1).compareTo(a.ageDays ?? -1);
    if (age != 0) return age;
    final assessment = _assessmentPriority(
      a.selfAssessment,
    ).compareTo(_assessmentPriority(b.selfAssessment));
    if (assessment != 0) return assessment;
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
