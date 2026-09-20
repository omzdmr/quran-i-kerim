import 'reading_plan_recovery_destination.dart';
import 'reading_plan_recovery_service.dart';

/// UI-facing recovery coordinator.
///
/// Resolves persisted recovery strategy and returns a canonical Reader target
/// in one operation. Plans UI can use this without reimplementing catch-up,
/// redistribution, or page-to-ayah rules.
class ReadingPlanRecoveryCoordinator {
  const ReadingPlanRecoveryCoordinator({
    this.service = const ReadingPlanRecoveryService(),
  });

  final ReadingPlanRecoveryService service;

  Future<ReadingPlanRecoveryDestination?> currentDestination({
    DateTime? now,
  }) async {
    final session = await service.currentSession(now: now);
    return recoveryDestinationForSession(session);
  }

  Future<ReadingPlanRecoveryDestination?> useCatchUp({DateTime? now}) async {
    final session = await service.useCatchUp(now: now);
    return recoveryDestinationForSession(session);
  }

  Future<ReadingPlanRecoveryDestination?> redistributeUntil(
    DateTime targetEndDate, {
    DateTime? now,
  }) async {
    final session = await service.redistributeUntil(targetEndDate, now: now);
    return recoveryDestinationForSession(session);
  }
}
