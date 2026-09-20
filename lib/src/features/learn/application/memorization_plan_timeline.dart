/// Converts elapsed calendar days into the plan day that should actually be
/// worked after missed days are taken into account.
///
/// A missed day pauses plan progression instead of stacking extra new pages on
/// a later day. This keeps catch-up conservative: the plan takes longer, while
/// the per-day new memorization load stays within the selected pace.
int effectiveMemorizationPlanDayIndex({
  required int elapsedPlanDayIndex,
  required Iterable<int> missedPlanDays,
}) {
  if (elapsedPlanDayIndex < 0) {
    throw ArgumentError.value(
      elapsedPlanDayIndex,
      'elapsedPlanDayIndex',
      'must be >= 0',
    );
  }

  final missedBeforeToday = <int>{};
  for (final day in missedPlanDays) {
    if (day < 0) {
      throw ArgumentError.value(day, 'missedPlanDays', 'must be >= 0');
    }
    if (day < elapsedPlanDayIndex) {
      missedBeforeToday.add(day);
    }
  }

  final effective = elapsedPlanDayIndex - missedBeforeToday.length;
  return effective < 0 ? 0 : effective;
}
