import 'prayer_notification_schedule_health_refresher.dart';
import 'prayer_notification_schedule_health_store.dart';
import 'prayer_pending_schedule_probe.dart';
import 'prayer_schedule_repair_receipt_store.dart';

/// Repairs stale prayer notification schedules when the app becomes active.
///
/// This is deliberately local-only: it compares the saved schedule evidence
/// with the current saved prayer configuration and, when platform diagnostics
/// are available, verifies the OS still has pending reminders. It does not need
/// a backend and does not create worship history.
class PrayerScheduleAutoRepair {
  const PrayerScheduleAutoRepair({
    this.refresher = const PrayerNotificationScheduleHealthRefresher(),
    this.store = const PrayerNotificationScheduleHealthStore(),
    this.pendingProbe = const SystemPrayerPendingScheduleProbe(),
    this.receiptStore = const PrayerScheduleRepairReceiptStore(),
  });

  final PrayerNotificationScheduleHealthRefresher refresher;
  final PrayerNotificationScheduleHealthStore store;
  final PrayerPendingScheduleProbe pendingProbe;
  final PrayerScheduleRepairReceiptStore receiptStore;

  Future<PrayerScheduleRepairResult> repairIfNeeded({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final fingerprint = await refresher.currentConfigurationFingerprint();
    if (fingerprint == null) {
      await refresher.resync(now: current);
      await _record(current, PrayerScheduleRepairOutcome.notApplicable);
      return PrayerScheduleRepairResult.notApplicable;
    }

    final health = await store.load();
    final evidenceFresh = health != null &&
        health.isFreshAt(
          current,
          expectedConfigurationFingerprint: fingerprint,
        );

    if (evidenceFresh) {
      final pendingCount = await pendingProbe.pendingCount();
      if (pendingCount == null || pendingCount > 0) {
        await _record(
          current,
          PrayerScheduleRepairOutcome.alreadyFresh,
          fingerprint: fingerprint,
        );
        return PrayerScheduleRepairResult.alreadyFresh;
      }
    }

    try {
      final repaired = await refresher.resync(now: current);
      if (repaired == null) {
        await _record(current, PrayerScheduleRepairOutcome.failed, fingerprint: fingerprint);
        return PrayerScheduleRepairResult.failed;
      }
      await _record(
        current,
        PrayerScheduleRepairOutcome.repaired,
        fingerprint: repaired.configurationFingerprint,
      );
      return PrayerScheduleRepairResult.repaired;
    } catch (_) {
      await _record(current, PrayerScheduleRepairOutcome.failed, fingerprint: fingerprint);
      rethrow;
    }
  }

  Future<void> _record(
    DateTime attemptedAt,
    PrayerScheduleRepairOutcome outcome, {
    String fingerprint = '',
  }) =>
      receiptStore.save(
        PrayerScheduleRepairReceipt(
          attemptedAt: attemptedAt,
          outcome: outcome,
          configurationFingerprint: fingerprint,
        ),
      );
}

enum PrayerScheduleRepairResult {
  notApplicable,
  alreadyFresh,
  repaired,
  failed,
}
