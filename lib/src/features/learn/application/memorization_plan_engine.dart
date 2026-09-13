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

class MemorizationDailyQueue {
  const MemorizationDailyQueue({
    required this.newPageCount,
    required this.recentReviewPages,
    required this.checkpointReviewPages,
    required this.oldReviewPages,
    required this.consolidationPages,
    required this.isConsolidationDay,
  });

  final int newPageCount;
  final List<int> recentReviewPages;
  final List<int> checkpointReviewPages;
  final List<int> oldReviewPages;
  final List<int> consolidationPages;
  final bool isConsolidationDay;
}

DateTime _memorizationDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _memorizationAgeInDays(DateTime memorizedAt, DateTime now) =>
    _memorizationDay(now).difference(_memorizationDay(memorizedAt)).inDays;

/// Builds a local-first page queue from persisted memorization timestamps.
///
/// Recent pages stay in daily review for the configured seven-day window.
/// Day 14/30 checkpoints are kept separate from the rotating older-review
/// bucket so a page is not scheduled twice for the same day. Older pages are
/// selected by least-recent review first, which gives the rotation a stable
/// priority without requiring a server-side cursor.
MemorizationDailyQueue buildMemorizationDailyQueue({
  required MemorizationPlanPace pace,
  required int planDayIndex,
  required DateTime now,
  required Map<int, DateTime> memorizedAtByPage,
  Map<int, DateTime> lastReviewedAtByPage = const <int, DateTime>{},
}) {
  if (planDayIndex < 0) {
    throw ArgumentError.value(planDayIndex, 'planDayIndex', 'must be >= 0');
  }

  final preset = memorizationPlanPresets[pace]!;
  final recentReviewPages = <int>[];
  final checkpointReviewPages = <int>[];
  final olderPages = <int>[];
  final consolidationPages = <int>[];
  final currentWeekDay = planDayIndex % preset.weeklyNewPagePattern.length;

  for (final entry in memorizedAtByPage.entries) {
    final page = entry.key;
    if (page < 1 || page > 604) continue;

    final age = _memorizationAgeInDays(entry.value, now);
    if (age < 0) continue;

    if (age < preset.recentReviewDays) {
      recentReviewPages.add(page);
    } else if (preset.checkpointDays.contains(age)) {
      checkpointReviewPages.add(page);
    } else {
      olderPages.add(page);
    }

    if (preset.isConsolidationDay(planDayIndex) &&
        age >= 0 &&
        age <= currentWeekDay) {
      consolidationPages.add(page);
    }
  }

  recentReviewPages.sort();
  checkpointReviewPages.sort();
  consolidationPages.sort();
  olderPages.sort((a, b) {
    final aReviewed = lastReviewedAtByPage[a];
    final bReviewed = lastReviewedAtByPage[b];
    if (aReviewed == null && bReviewed != null) return -1;
    if (aReviewed != null && bReviewed == null) return 1;
    if (aReviewed != null && bReviewed != null) {
      final comparison = aReviewed.compareTo(bReviewed);
      if (comparison != 0) return comparison;
    }
    return a.compareTo(b);
  });

  final load = buildMemorizationDailyLoad(
    pace: pace,
    planDayIndex: planDayIndex,
    olderMemorizedPages: olderPages.length,
  );
  final oldReviewPages = olderPages.take(load.oldReviewPages).toList();

  return MemorizationDailyQueue(
    newPageCount: load.newPages,
    recentReviewPages: List<int>.unmodifiable(recentReviewPages),
    checkpointReviewPages: List<int>.unmodifiable(checkpointReviewPages),
    oldReviewPages: List<int>.unmodifiable(oldReviewPages),
    consolidationPages: List<int>.unmodifiable(consolidationPages),
    isConsolidationDay: load.isConsolidationDay,
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
