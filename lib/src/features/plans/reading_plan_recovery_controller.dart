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
    } on ArgumentError {
      // A target can become stale after a long pause/offline period. Falling
      // back keeps the plan usable; UI may then ask the user for a new date.
    } on RangeError {
      // Same principle when today's date no longer belongs to the proposal.
    }
  }

  return ReadingPlanRecoverySession.catchUp(active: active, now: now);
}
