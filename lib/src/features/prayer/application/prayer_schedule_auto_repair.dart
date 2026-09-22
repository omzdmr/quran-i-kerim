import 'prayer_notification_schedule_health_refresher.dart';
import 'prayer_notification_schedule_health_store.dart';
import 'prayer_pending_schedule_probe.dart';

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
  });

  final PrayerNotificationScheduleHealthRefresher refresher;
  final PrayerNotificationScheduleHealthStore store;
  final PrayerPendingScheduleProbe pendingProbe;

  Future<PrayerScheduleRepairResult> repairIfNeeded({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final fingerprint = await refresher.currentConfigurationFingerprint();
    if (fingerprint == null) {
      // Disabled/empty notification selections and unresolved saved locations
      // must not leave an old OS schedule alive. The refresher owns the exact
      // cancellation/cleanup behavior for those states.
      await refresher.resync(now: current);
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
      if (pendingCount == null) {
        // Platform inspection can be unavailable on a device/OS version. Keep
        // recent matching evidence rather than rescheduling on every resume.
        return PrayerScheduleRepairResult.alreadyFresh;
      }
      if (pendingCount > 0) return PrayerScheduleRepairResult.alreadyFresh;
    }

    final repaired = await refresher.resync(now: current);
    return repaired == null
        ? PrayerScheduleRepairResult.failed
        : PrayerScheduleRepairResult.repaired;
  }
}

enum PrayerScheduleRepairResult {
  notApplicable,
  alreadyFresh,
  repaired,
  failed,
}
