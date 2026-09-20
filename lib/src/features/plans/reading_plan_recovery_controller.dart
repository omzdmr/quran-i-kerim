import 'reading_plan_recovery.dart';
import 'reading_plan_store.dart';

/// Resolves the Reader work range for the current plan without mutating plan
/// progress. A persisted redistribution target takes precedence; otherwise the
/// normal missed-day catch-up range is used.
ReadingPlanRecoverySession? resolveReadingPlanRecoverySession({
  required ReadingPlanSnapshot snapshot,
  required DateTime now,
}) {
  final active = snapshot.active;
  if (active == null || active.nextDay == null) return null;

  final redistributionTarget = snapshot.redistributionTargetEndDate;
  if (redistributionTarget != null) {
    try {
      return ReadingPlanRecoverySession.redistributed(
        active: active,
        now: now,
        targetEndDate: redistributionTarget,
      );
    } on RangeError {
      // Today's date can fall outside an old redistribution proposal.
      // Falling back keeps the plan usable and lets the UI ask for a new date.
    } on ArgumentError {
      // A target can become stale after a long pause/offline period.
      // Fall back to normal catch-up rather than blocking the plan.
    }
  }

  return ReadingPlanRecoverySession.catchUp(active: active, now: now);
}
