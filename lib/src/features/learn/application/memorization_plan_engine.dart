enum MemorizationPlanPace {
  intensive12Months,
  steady18Months,
  balanced24Months,
}

class MemorizationPlanPreset {
  const MemorizationPlanPreset({
    required this.pace,
    required this.targetMonths,
    required this.weeklyNewPagePattern,
    required this.recentReviewDays,
    required this.checkpointDays,
    required this.oldReviewCycleDays,
    required this.maxOldReviewPagesPerDay,
  });

  final MemorizationPlanPace pace;
  final int targetMonths;

  /// Seven-day pattern. A zero marks the weekly consolidation day.
  final List<int> weeklyNewPagePattern;

  /// Fresh memorization stays in the recent-review bucket for this many days.
  final int recentReviewDays;

  /// Extra recall checkpoints after the daily recent-review window.
  final List<int> checkpointDays;

  /// Desired upper bound for one complete rotation of older memorization.
  final int oldReviewCycleDays;

  /// Prevents a mature memorization set from creating an unreasonable daily
  /// review spike. The real cycle may become slightly longer because of this.
  final int maxOldReviewPagesPerDay;

  int get weeklyNewPageCapacity => weeklyNewPagePattern.fold(0, (a, b) => a + b);

  int newPagesForPlanDay(int zeroBasedPlanDay) {
    final index = zeroBasedPlanDay % weeklyNewPagePattern.length;
    return weeklyNewPagePattern[index];
  }

  bool isConsolidationDay(int zeroBasedPlanDay) =>
      newPagesForPlanDay(zeroBasedPlanDay) == 0;
}

const memorizationPlanPresets = <MemorizationPlanPace, MemorizationPlanPreset>{
  MemorizationPlanPace.intensive12Months: MemorizationPlanPreset(
    pace: MemorizationPlanPace.intensive12Months,
    targetMonths: 12,
    weeklyNewPagePattern: <int>[2, 2, 2, 2, 2, 2, 0],
    recentReviewDays: 7,
    checkpointDays: <int>[14, 30],
    oldReviewCycleDays: 60,
    maxOldReviewPagesPerDay: 10,
  ),
  MemorizationPlanPace.steady18Months: MemorizationPlanPreset(
    pace: MemorizationPlanPace.steady18Months,
    targetMonths: 18,
    weeklyNewPagePattern: <int>[2, 1, 1, 2, 1, 1, 0],
    recentReviewDays: 7,
    checkpointDays: <int>[14, 30],
    oldReviewCycleDays: 90,
    maxOldReviewPagesPerDay: 8,
  ),
  MemorizationPlanPace.balanced24Months: MemorizationPlanPreset(
    pace: MemorizationPlanPace.balanced24Months,
    targetMonths: 24,
    weeklyNewPagePattern: <int>[1, 1, 1, 1, 1, 1, 0],
    recentReviewDays: 7,
    checkpointDays: <int>[14, 30],
    oldReviewCycleDays: 120,
    maxOldReviewPagesPerDay: 6,
  ),
};

class MemorizationDailyLoad {
  const MemorizationDailyLoad({
    required this.planDayIndex,
    required this.newPages,
    required this.recentReviewDays,
    required this.checkpointDays,
    required this.oldReviewPages,
    required this.isConsolidationDay,
  });

  final int planDayIndex;
  final int newPages;
  final int recentReviewDays;
  final List<int> checkpointDays;
  final int oldReviewPages;
  final bool isConsolidationDay;
}

MemorizationDailyLoad buildMemorizationDailyLoad({
  required MemorizationPlanPace pace,
  required int planDayIndex,
  required int olderMemorizedPages,
}) {
  if (planDayIndex < 0) {
    throw ArgumentError.value(planDayIndex, 'planDayIndex', 'must be >= 0');
  }
  if (olderMemorizedPages < 0) {
    throw ArgumentError.value(
      olderMemorizedPages,
      'olderMemorizedPages',
      'must be >= 0',
    );
  }

  final preset = memorizationPlanPresets[pace]!;
  final calculatedOldReview = olderMemorizedPages == 0
      ? 0
      : (olderMemorizedPages + preset.oldReviewCycleDays - 1) ~/
          preset.oldReviewCycleDays;
  final oldReviewPages = calculatedOldReview > preset.maxOldReviewPagesPerDay
      ? preset.maxOldReviewPagesPerDay
      : calculatedOldReview;

  return MemorizationDailyLoad(
    planDayIndex: planDayIndex,
    newPages: preset.newPagesForPlanDay(planDayIndex),
    recentReviewDays: preset.recentReviewDays,
    checkpointDays: preset.checkpointDays,
    oldReviewPages: oldReviewPages,
    isConsolidationDay: preset.isConsolidationDay(planDayIndex),
  );
}

class MemorizationPracticeRange {
  const MemorizationPracticeRange(this.min, this.max)
      : assert(min >= 0),
        assert(max >= min);

  final int min;
  final int max;
}

class MemorizationLearningProtocol {
  const MemorizationLearningProtocol({
    required this.readWhileLooking,
    required this.listenRepeats,
    required this.cleanRecallTarget,
    required this.chunkLongPassages,
    required this.connectToPrevious,
    required this.teacherCheckRecommended,
    required this.automaticSpeechScoringEnabled,
  });

  final MemorizationPracticeRange readWhileLooking;
  final MemorizationPracticeRange listenRepeats;
  final int cleanRecallTarget;
  final bool chunkLongPassages;
  final bool connectToPrevious;
  final bool teacherCheckRecommended;
  final bool automaticSpeechScoringEnabled;
}

/// Evidence-informed defaults, not a religious rule or a universal prescription.
/// Callers may adapt repetitions to verse length and learner performance.
const defaultMemorizationLearningProtocol = MemorizationLearningProtocol(
  readWhileLooking: MemorizationPracticeRange(5, 10),
  listenRepeats: MemorizationPracticeRange(3, 5),
  cleanRecallTarget: 3,
  chunkLongPassages: true,
  connectToPrevious: true,
  teacherCheckRecommended: true,
  automaticSpeechScoringEnabled: false,
);
