enum MemorizationAdaptiveLoadReason {
  normal,
  reviewPressure,
  recovery,
  consolidation,
}

class MemorizationAdaptiveLoadDecision {
  const MemorizationAdaptiveLoadDecision({
    required this.baseNewPageCount,
    required this.newPageCount,
    required this.reason,
    required this.pressureSignals,
  });

  final int baseNewPageCount;
  final int newPageCount;
  final MemorizationAdaptiveLoadReason reason;
  final int pressureSignals;

  bool get isReduced => newPageCount < baseNewPageCount;
  bool get pausesNewMemorization => baseNewPageCount > 0 && newPageCount == 0;
}

/// Conservative product heuristic for protecting review before adding new work.
///
/// This is intentionally not presented as a religious rule or a universal hifz
/// prescription. The selected pace remains the ceiling. Review pressure can
/// only lower today's new-page load; it can never increase it above the plan.
MemorizationAdaptiveLoadDecision adaptMemorizationNewPageLoad({
  required int baseNewPageCount,
  required bool isConsolidationDay,
  required int recentReviewPageCount,
  required int checkpointReviewPageCount,
  required int weakRecallCount,
  required int missedPlanDaysLast7,
}) {
  final values = <String, int>{
    'baseNewPageCount': baseNewPageCount,
    'recentReviewPageCount': recentReviewPageCount,
    'checkpointReviewPageCount': checkpointReviewPageCount,
    'weakRecallCount': weakRecallCount,
    'missedPlanDaysLast7': missedPlanDaysLast7,
  };
  for (final entry in values.entries) {
    if (entry.value < 0) {
      throw ArgumentError.value(entry.value, entry.key, 'must be >= 0');
    }
  }

  if (isConsolidationDay || baseNewPageCount == 0) {
    return MemorizationAdaptiveLoadDecision(
      baseNewPageCount: baseNewPageCount,
      newPageCount: 0,
      reason: MemorizationAdaptiveLoadReason.consolidation,
      pressureSignals: 0,
    );
  }

  // Strong recovery signals pause new memorization for the day. The learner
  // first clears fragile/recent material instead of allowing review debt to
  // grow while the calendar keeps adding pages.
  final requiresRecovery = missedPlanDaysLast7 >= 2 ||
      weakRecallCount >= 5 ||
      recentReviewPageCount >= 8 ||
      checkpointReviewPageCount >= 4;
  if (requiresRecovery) {
    return MemorizationAdaptiveLoadDecision(
      baseNewPageCount: baseNewPageCount,
      newPageCount: 0,
      reason: MemorizationAdaptiveLoadReason.recovery,
      pressureSignals: 1,
    );
  }

  final pressureSignals = <bool>[
    missedPlanDaysLast7 >= 1,
    weakRecallCount >= 2,
    recentReviewPageCount >= 5,
    checkpointReviewPageCount >= 2,
  ].where((value) => value).length;

  if (pressureSignals == 0) {
    return MemorizationAdaptiveLoadDecision(
      baseNewPageCount: baseNewPageCount,
      newPageCount: baseNewPageCount,
      reason: MemorizationAdaptiveLoadReason.normal,
      pressureSignals: 0,
    );
  }

  // Two-page plans have room to step down to one page under moderate review
  // pressure. A one-page plan is already conservative, so one mild signal does
  // not stop progress; two simultaneous signals do.
  final adjusted = baseNewPageCount > 1
      ? baseNewPageCount - 1
      : pressureSignals >= 2
          ? 0
          : baseNewPageCount;

  return MemorizationAdaptiveLoadDecision(
    baseNewPageCount: baseNewPageCount,
    newPageCount: adjusted,
    reason: adjusted == 0
        ? MemorizationAdaptiveLoadReason.recovery
        : MemorizationAdaptiveLoadReason.reviewPressure,
    pressureSignals: pressureSignals,
  );
}
