import 'memorization_adaptive_load.dart';
import 'memorization_plan_engine.dart';

class MemorizationAdaptiveDailyQueue {
  const MemorizationAdaptiveDailyQueue({
    required this.baseQueue,
    required this.loadDecision,
  });

  final MemorizationDailyQueue baseQueue;
  final MemorizationAdaptiveLoadDecision loadDecision;

  int get newPageCount => loadDecision.newPageCount;
  int get baseNewPageCount => loadDecision.baseNewPageCount;
  bool get isNewLoadReduced => loadDecision.isReduced;
  bool get pausesNewMemorization => loadDecision.pausesNewMemorization;

  List<int> get recentReviewPages => baseQueue.recentReviewPages;
  List<int> get checkpointReviewPages => baseQueue.checkpointReviewPages;
  List<int> get oldReviewPages => baseQueue.oldReviewPages;
  List<int> get consolidationPages => baseQueue.consolidationPages;
  bool get isConsolidationDay => baseQueue.isConsolidationDay;
}

/// Builds the normal evidence-informed queue first, then applies a conservative
/// local adaptation to the new-memorization allowance.
///
/// Review work is never removed by this layer. Only today's new-page count may
/// be reduced, keeping recent, checkpoint, old and consolidation review intact.
MemorizationAdaptiveDailyQueue buildAdaptiveMemorizationDailyQueue({
  required MemorizationPlanPace pace,
  required int planDayIndex,
  required DateTime now,
  required Map<int, DateTime> memorizedAtByPage,
  Map<int, DateTime> lastReviewedAtByPage = const <int, DateTime>{},
  Set<int>? eligiblePages,
  int weakRecallCount = 0,
  int missedPlanDaysLast7 = 0,
}) {
  final baseQueue = buildMemorizationDailyQueue(
    pace: pace,
    planDayIndex: planDayIndex,
    now: now,
    memorizedAtByPage: memorizedAtByPage,
    lastReviewedAtByPage: lastReviewedAtByPage,
    eligiblePages: eligiblePages,
  );

  final decision = adaptMemorizationNewPageLoad(
    baseNewPageCount: baseQueue.newPageCount,
    isConsolidationDay: baseQueue.isConsolidationDay,
    recentReviewPageCount: baseQueue.recentReviewPages.length,
    checkpointReviewPageCount: baseQueue.checkpointReviewPages.length,
    weakRecallCount: weakRecallCount,
    missedPlanDaysLast7: missedPlanDaysLast7,
  );

  return MemorizationAdaptiveDailyQueue(
    baseQueue: baseQueue,
    loadDecision: decision,
  );
}
