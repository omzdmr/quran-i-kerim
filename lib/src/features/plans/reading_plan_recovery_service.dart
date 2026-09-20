import 'reading_plan_recovery.dart';
import 'reading_plan_recovery_controller.dart';
import 'reading_plan_store.dart';

/// Coordinates user-controlled missed-day recovery without silently changing
/// reading completion. The selected strategy is persisted by [ReadingPlanStore]
/// and can be resolved again after process death/offline restore.
class ReadingPlanRecoveryService {
  const ReadingPlanRecoveryService({this.store = const ReadingPlanStore()});

  final ReadingPlanStore store;

  Future<ReadingPlanRecoverySession?> currentSession({DateTime? now}) async {
    final snapshot = await store.load();
    return resolveReadingPlanRecoverySession(
      snapshot: snapshot,
      now: now ?? DateTime.now(),
    );
  }

  /// Keeps normal catch-up semantics and clears a previously selected
  /// redistribution window. No completed day is changed.
  Future<ReadingPlanRecoverySession?> useCatchUp({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final snapshot = await store.clearRedistributionTargetEndDate();
    return resolveReadingPlanRecoverySession(snapshot: snapshot, now: at);
  }

  /// Persists an explicit target date and resolves today's redistributed work.
  ///
  /// The store validates that [targetEndDate] is not in the past. Completion
  /// remains an explicit, separate user action.
  Future<ReadingPlanRecoverySession?> redistributeUntil(
    DateTime targetEndDate, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final snapshot = await store.setRedistributionTargetEndDate(
      targetEndDate,
      now: at,
    );
    return resolveReadingPlanRecoverySession(snapshot: snapshot, now: at);
  }
}
