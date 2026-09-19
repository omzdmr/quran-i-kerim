import 'reading_plan.dart';

/// A non-mutating proposal for spreading all unfinished Mushaf pages across a
/// user-selected recovery window. Applying/completing work remains explicit;
/// this object never marks plan days complete on the user's behalf.
class ReadingPlanRedistributionProposal {
  const ReadingPlanRedistributionProposal({
    required this.startPage,
    required this.endPage,
    required this.startDate,
    required this.targetEndDate,
    required this.remainingPages,
    required this.availableDays,
    required this.basePagesPerDay,
    required this.extraPageDays,
  });

  final int startPage;
  final int endPage;
  final DateTime startDate;
  final DateTime targetEndDate;
  final int remainingPages;
  final int availableDays;

  /// Minimum pages assigned to every day in the recovery window.
  final int basePagesPerDay;

  /// Number of earliest days that receive one extra page so the distribution
  /// covers every remaining page exactly.
  final int extraPageDays;

  int pagesForDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= availableDays) {
      throw RangeError.range(dayIndex, 0, availableDays - 1, 'dayIndex');
    }
    return basePagesPerDay + (dayIndex < extraPageDays ? 1 : 0);
  }

  int startPageForDay(int dayIndex) {
    pagesForDay(dayIndex); // validates the index.
    var page = startPage;
    for (var index = 0; index < dayIndex; index++) {
      page += pagesForDay(index);
    }
    return page;
  }

  int endPageForDay(int dayIndex) {
    final start = startPageForDay(dayIndex);
    return start + pagesForDay(dayIndex) - 1;
  }
}

/// Builds a transparent, user-controlled missed-day redistribution proposal.
///
/// [targetEndDate] is chosen by the user/UI. The active plan is not modified,
/// completed days are not rewritten, and no religious/content data is touched.
/// The remaining work begins at the first page of the first unfinished plan
/// day and ends at page 604 of the Madinah Mushaf plan model.
ReadingPlanRedistributionProposal? proposeReadingPlanRedistribution({
  required ActiveReadingPlan active,
  required DateTime now,
  required DateTime targetEndDate,
}) {
  final next = active.nextDay;
  if (next == null) return null;

  final startDate = readingPlanDateOnly(now);
  final endDate = readingPlanDateOnly(targetEndDate);
  if (endDate.isBefore(startDate)) {
    throw ArgumentError.value(
      targetEndDate,
      'targetEndDate',
      'Target end date cannot be before today.',
    );
  }

  final remainingPages = madinahMushafPageCount - next.startPage + 1;
  final availableDays = endDate.difference(startDate).inDays + 1;
  final basePagesPerDay = remainingPages ~/ availableDays;
  final extraPageDays = remainingPages % availableDays;

  return ReadingPlanRedistributionProposal(
    startPage: next.startPage,
    endPage: madinahMushafPageCount,
    startDate: startDate,
    targetEndDate: endDate,
    remainingPages: remainingPages,
    availableDays: availableDays,
    basePagesPerDay: basePagesPerDay,
    extraPageDays: extraPageDays,
  );
}
