import 'memorization_today_plan.dart';

enum MemorizationTodaySessionKind {
  oldReview,
  recentReview,
  checkpointReview,
  consolidation,
  newMemorization,
}

class MemorizationTodaySessionItem {
  const MemorizationTodaySessionItem({
    required this.page,
    required this.kind,
  });

  final int page;
  final MemorizationTodaySessionKind kind;

  bool get isReview => kind != MemorizationTodaySessionKind.newMemorization;
}

/// Converts today's adaptive hifz plan into one concrete, ordered study session.
///
/// The order mirrors [MemorizationTodayPlan.studyPages]: older review debt is
/// protected first, followed by fragile recent material, checkpoint review,
/// weekly consolidation and only then new memorization. Pages that appear in
/// multiple review buckets occur once, with the earliest/highest-priority kind.
List<MemorizationTodaySessionItem> buildMemorizationTodaySessionItems(
  MemorizationTodayPlan plan,
) {
  final oldPages = plan.queue.oldReviewPages.toSet();
  final recentPages = plan.queue.recentReviewPages.toSet();
  final checkpointPages = plan.queue.checkpointReviewPages.toSet();
  final consolidationPages = plan.queue.consolidationPages.toSet();
  final newPages = plan.newPages.toSet();

  final items = <MemorizationTodaySessionItem>[];
  for (final page in plan.studyPages) {
    if (page < 1 || page > 604) continue;

    final kind = oldPages.contains(page)
        ? MemorizationTodaySessionKind.oldReview
        : recentPages.contains(page)
            ? MemorizationTodaySessionKind.recentReview
            : checkpointPages.contains(page)
                ? MemorizationTodaySessionKind.checkpointReview
                : consolidationPages.contains(page)
                    ? MemorizationTodaySessionKind.consolidation
                    : newPages.contains(page)
                        ? MemorizationTodaySessionKind.newMemorization
                        : null;
    if (kind == null) continue;

    items.add(MemorizationTodaySessionItem(page: page, kind: kind));
  }

  return List<MemorizationTodaySessionItem>.unmodifiable(items);
}
