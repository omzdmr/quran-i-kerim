import 'prayer_notification_schedule_health_refresher.dart';
import 'prayer_notification_schedule_health_store.dart';
import 'prayer_pending_schedule_probe.dart';
import 'prayer_schedule_repair_receipt_store.dart';

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
    String fingerprint = '';
    var trigger = PrayerScheduleRepairTrigger.unknown;
    try {
      final currentFingerprint = await refresher.currentConfigurationFingerprint();
      fingerprint = currentFingerprint ?? '';
      if (currentFingerprint == null) {
        trigger = PrayerScheduleRepairTrigger.noSchedulableConfiguration;
        await refresher.resync(now: current);
        await _record(current, PrayerScheduleRepairOutcome.notApplicable, trigger: trigger);
        return PrayerScheduleRepairResult.notApplicable;
      }

      final health = await store.load();
      final fingerprintChanged = health != null &&
          health.configurationFingerprint.isNotEmpty &&
          health.configurationFingerprint != currentFingerprint;
      final evidenceFresh = health != null &&
          health.isFreshAt(current, expectedConfigurationFingerprint: currentFingerprint);

      if (evidenceFresh) {
        final pendingCount = await pendingProbe.pendingCount();
        if (pendingCount == null || pendingCount > 0) {
          trigger = PrayerScheduleRepairTrigger.verifiedFresh;
          await _record(current, PrayerScheduleRepairOutcome.alreadyFresh,
              trigger: trigger, fingerprint: currentFingerprint);
          return PrayerScheduleRepairResult.alreadyFresh;
        }
        trigger = PrayerScheduleRepairTrigger.platformScheduleMissing;
      } else if (fingerprintChanged) {
        trigger = PrayerScheduleRepairTrigger.configurationChanged;
      } else {
        trigger = PrayerScheduleRepairTrigger.staleEvidence;
      }

      final repaired = await refresher.resync(now: current);
      if (repaired == null) {
        await _record(current, PrayerScheduleRepairOutcome.failed,
            trigger: trigger, fingerprint: currentFingerprint);
        return PrayerScheduleRepairResult.failed;
      }
      await _record(current, PrayerScheduleRepairOutcome.repaired,
          trigger: trigger, fingerprint: repaired.configurationFingerprint);
      return PrayerScheduleRepairResult.repaired;
    } catch (_) {
      await _record(current, PrayerScheduleRepairOutcome.failed,
          trigger: trigger, fingerprint: fingerprint);
      rethrow;
    }
  }

  Future<void> _record(DateTime attemptedAt, PrayerScheduleRepairOutcome outcome,
          {PrayerScheduleRepairTrigger trigger = PrayerScheduleRepairTrigger.unknown,
          String fingerprint = ''}) =>
      receiptStore.save(PrayerScheduleRepairReceipt(
        attemptedAt: attemptedAt,
        outcome: outcome,
        trigger: trigger,
        configurationFingerprint: fingerprint,
      ));
}

enum PrayerScheduleRepairResult { notApplicable, alreadyFresh, repaired, failed }
