import 'prayer_notification_schedule_health_refresher.dart';
import 'prayer_notification_schedule_health_store.dart';

/// Repairs stale prayer notification schedules when the app becomes active.
///
/// This is deliberately local-only: it compares the saved schedule evidence
/// with the current saved prayer configuration and reschedules only when the
/// evidence is missing, expired or belongs to different inputs. It does not
/// need a backend and does not create worship history.
class PrayerScheduleAutoRepair {
  const PrayerScheduleAutoRepair({
    this.refresher = const PrayerNotificationScheduleHealthRefresher(),
    this.store = const PrayerNotificationScheduleHealthStore(),
  });

  final PrayerNotificationScheduleHealthRefresher refresher;
  final PrayerNotificationScheduleHealthStore store;

  Future<PrayerScheduleRepairResult> repairIfNeeded({DateTime? now}) async {
    final fingerprint = await refresher.currentConfigurationFingerprint();
    if (fingerprint == null) return PrayerScheduleRepairResult.notApplicable;

    final health = await store.load();
    final current = now ?? DateTime.now();
    if (health != null &&
        health.isFreshAt(
          current,
          expectedConfigurationFingerprint: fingerprint,
        )) {
      return PrayerScheduleRepairResult.alreadyFresh;
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
