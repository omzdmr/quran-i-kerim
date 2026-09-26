import 'memorization_practice_history_store.dart';
import 'memorization_progress_store.dart';

enum MemorizationReviewHistoryFilter { all, soloReview, prayer, recitedToSomeone }

class MemorizationReviewHistoryPage {
  const MemorizationReviewHistoryPage({
    required this.page,
    required this.totalReviews,
    required this.recentReviews,
    required this.latestReviewAt,
    required this.contexts,
    required this.selfAssessment,
    this.hasDetailedHistory = true,
  });

  final int page;
  final int totalReviews;
  final int recentReviews;
  final DateTime? latestReviewAt;
  final Set<MemorizationPracticeContext> contexts;
  final MemorizationSelfAssessment? selfAssessment;
  final bool hasDetailedHistory;
}

class MemorizationReviewHistorySummary {
  const MemorizationReviewHistorySummary({
    required this.pages,
    required this.totalEvents,
    required this.recentEvents,
    required this.reviewedPageCount,
  });

  final List<MemorizationReviewHistoryPage> pages;
  final int totalEvents;
  final int recentEvents;
  final int reviewedPageCount;

  bool get isEmpty => pages.isEmpty;
}

MemorizationReviewHistorySummary buildMemorizationReviewHistory({
  required MemorizationProgressSnapshot progress,
  required MemorizationPracticeHistorySnapshot history,
  required DateTime now,
  MemorizationReviewHistoryFilter filter = MemorizationReviewHistoryFilter.all,
  int recentWindowDays = 30,
}) {
  if (recentWindowDays < 1) {
    throw ArgumentError.value(recentWindowDays, 'recentWindowDays', 'must be >= 1');
  }

  final cutoff = now.subtract(Duration(days: recentWindowDays));
  bool accepts(MemorizationPracticeEvent event) => switch (filter) {
        MemorizationReviewHistoryFilter.all => true,
        MemorizationReviewHistoryFilter.soloReview =>
          event.context == MemorizationPracticeContext.soloReview,
        MemorizationReviewHistoryFilter.prayer =>
          event.context == MemorizationPracticeContext.prayer,
        MemorizationReviewHistoryFilter.recitedToSomeone =>
          event.context == MemorizationPracticeContext.recitedToSomeone,
      };

  final byPage = <int, List<MemorizationPracticeEvent>>{};
  var totalEvents = 0;
  var recentEvents = 0;
  for (final event in history.events) {
    if (!progress.memorizedPages.contains(event.page) || !accepts(event)) continue;
    totalEvents++;
    if (!event.occurredAt.isBefore(cutoff)) recentEvents++;
    byPage.putIfAbsent(event.page, () => <MemorizationPracticeEvent>[]).add(event);
  }

  final pages = <MemorizationReviewHistoryPage>[];
  for (final entry in byPage.entries) {
    final events = entry.value..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    pages.add(
      MemorizationReviewHistoryPage(
        page: entry.key,
        totalReviews: events.length,
        recentReviews: events.where((event) => !event.occurredAt.isBefore(cutoff)).length,
        latestReviewAt: events.first.occurredAt,
        contexts: Set<MemorizationPracticeContext>.unmodifiable(
          events.map((event) => event.context).toSet(),
        ),
        selfAssessment: progress.progressForPage(entry.key)?.selfAssessment,
      ),
    );
  }

  // Older app versions stored only lastReviewedAt. Keep that history visible
  // instead of making an existing user's review record appear to vanish after
  // upgrading. Context/count remain explicitly unknown until new events exist.
  if (filter == MemorizationReviewHistoryFilter.all) {
    for (final page in progress.memorizedPages) {
      if (byPage.containsKey(page)) continue;
      final pageProgress = progress.progressForPage(page);
      final reviewedAt = pageProgress?.lastReviewedAt;
      if (reviewedAt == null) continue;
      pages.add(
        MemorizationReviewHistoryPage(
          page: page,
          totalReviews: 0,
          recentReviews: 0,
          latestReviewAt: reviewedAt,
          contexts: const <MemorizationPracticeContext>{},
          selfAssessment: pageProgress?.selfAssessment,
          hasDetailedHistory: false,
        ),
      );
    }
  }

  pages.sort((a, b) {
    final aDate = a.latestReviewAt;
    final bDate = b.latestReviewAt;
    if (aDate == null && bDate == null) return a.page.compareTo(b.page);
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    final byDate = bDate.compareTo(aDate);
    return byDate != 0 ? byDate : a.page.compareTo(b.page);
  });

  return MemorizationReviewHistorySummary(
    pages: List<MemorizationReviewHistoryPage>.unmodifiable(pages),
    totalEvents: totalEvents,
    recentEvents: recentEvents,
    reviewedPageCount: pages.length,
  );
}
