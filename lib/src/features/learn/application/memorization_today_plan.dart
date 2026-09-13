import 'memorization_adaptive_queue.dart';
import 'memorization_plan_store.dart';
import 'memorization_plan_timeline.dart';
import 'memorization_progress_store.dart';
import 'memorization_target_catalog.dart';

class MemorizationTodayPlan {
  const MemorizationTodayPlan({
    required this.elapsedPlanDayIndex,
    required this.effectivePlanDayIndex,
    required this.missedPlanDaysLast7,
    required this.weakRecallCount,
    required this.queue,
    required this.newPages,
  });

  final int elapsedPlanDayIndex;
  final int effectivePlanDayIndex;
  final int missedPlanDaysLast7;
  final int weakRecallCount;
  final MemorizationAdaptiveDailyQueue queue;
  final List<int> newPages;

  int get baseNewPageCount => queue.baseNewPageCount;
  int get newPageCount => newPages.length;
  bool get isNewLoadReduced => queue.isNewLoadReduced;
  bool get pausesNewMemorization => queue.pausesNewMemorization;

  List<int> get reviewPages {
    final pages = <int>{
      ...queue.recentReviewPages,
      ...queue.checkpointReviewPages,
      ...queue.oldReviewPages,
      ...queue.consolidationPages,
    }.toList()
      ..sort();
    return List<int>.unmodifiable(pages);
  }

  /// Concrete page order for the study flow.
  ///
  /// Review debt is intentionally placed before new memorization, matching the
  /// hifz product rule that old review and fragile recent material must not be
  /// sacrificed just to keep adding new pages. A page that appears in more
  /// than one review bucket is scheduled only once.
  List<int> get studyPages {
    final seen = <int>{};
    final pages = <int>[];

    void append(Iterable<int> values) {
      for (final page in values) {
        if (seen.add(page)) pages.add(page);
      }
    }

    append(queue.oldReviewPages);
    append(queue.recentReviewPages);
    append(queue.checkpointReviewPages);
    append(queue.consolidationPages);
    append(newPages);

    return List<int>.unmodifiable(pages);
  }

  /// First concrete page the existing memorization study surface should open.
  /// Returns null when today's plan has no review or new-memorization work.
  int? get firstStudyPage {
    final pages = studyPages;
    return pages.isEmpty ? null : pages.first;
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _missedPlanDaysInTrailingWeek({
  required Iterable<int> missedPlanDays,
  required int elapsedPlanDayIndex,
}) {
  final firstDay = elapsedPlanDayIndex >= 6 ? elapsedPlanDayIndex - 6 : 0;
  return missedPlanDays
      .where((day) => day >= firstDay && day <= elapsedPlanDayIndex)
      .toSet()
      .length;
}

/// Binds the persisted hifz plan, progress, active target and recall history
/// signals into the concrete work that should be shown for today.
///
/// The selected pace is always the ceiling. Missed days pause calendar
/// progression, while weak recall and review pressure may only reduce today's
/// new memorization. Existing review work is never discarded.
MemorizationTodayPlan? buildMemorizationTodayPlan({
  required MemorizationPlanSnapshot plan,
  required MemorizationProgressSnapshot progress,
  required MemorizationTargetId target,
  required int weakRecallCount,
  required DateTime now,
}) {
  if (!plan.hasPlan) return null;
  if (weakRecallCount < 0) {
    throw ArgumentError.value(
      weakRecallCount,
      'weakRecallCount',
      'must be >= 0',
    );
  }

  final startedAt = _dateOnly(plan.startedAt!);
  final today = _dateOnly(now);
  final elapsedDays = today.difference(startedAt).inDays;
  final elapsedPlanDayIndex = elapsedDays < 0 ? 0 : elapsedDays;
  final effectivePlanDayIndex = effectiveMemorizationPlanDayIndex(
    elapsedPlanDayIndex: elapsedPlanDayIndex,
    missedPlanDays: plan.missedPlanDays,
  );
  final missedPlanDaysLast7 = _missedPlanDaysInTrailingWeek(
    missedPlanDays: plan.missedPlanDays,
    elapsedPlanDayIndex: elapsedPlanDayIndex,
  );

  final memorizedAtByPage = <int, DateTime>{};
  final lastReviewedAtByPage = <int, DateTime>{};
  for (final page in progress.memorizedPages) {
    final pageProgress = progress.pageProgress[page];
    final memorizedAt = pageProgress?.memorizedAt;
    final lastReviewedAt = pageProgress?.lastReviewedAt;
    if (memorizedAt != null) memorizedAtByPage[page] = memorizedAt;
    if (lastReviewedAt != null) lastReviewedAtByPage[page] = lastReviewedAt;
  }

  final targetPages = memorizationPagesForTarget(target);
  final targetPageSet = targetPages.toSet();
  final queue = buildAdaptiveMemorizationDailyQueue(
    pace: plan.pace!,
    planDayIndex: effectivePlanDayIndex,
    now: today,
    memorizedAtByPage: memorizedAtByPage,
    lastReviewedAtByPage: lastReviewedAtByPage,
    eligiblePages: targetPageSet,
    weakRecallCount: weakRecallCount,
    missedPlanDaysLast7: missedPlanDaysLast7,
  );

  final newPages = targetPages
      .where((page) => !progress.memorizedPages.contains(page))
      .take(queue.newPageCount)
      .toList(growable: false);

  return MemorizationTodayPlan(
    elapsedPlanDayIndex: elapsedPlanDayIndex,
    effectivePlanDayIndex: effectivePlanDayIndex,
    missedPlanDaysLast7: missedPlanDaysLast7,
    weakRecallCount: weakRecallCount,
    queue: queue,
    newPages: List<int>.unmodifiable(newPages),
  );
}
