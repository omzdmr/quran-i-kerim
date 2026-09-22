import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_refresher.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_store.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_pending_schedule_probe.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_auto_repair.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Refresher extends PrayerNotificationScheduleHealthRefresher {
  _Refresher(this.fingerprint);
  final String fingerprint;
  int resyncCalls = 0;
  @override
  Future<String?> currentConfigurationFingerprint() async => fingerprint;
  @override
  Future<PrayerNotificationScheduleHealth?> resync({DateTime? now}) async { resyncCalls++; return null; }
}

class _Probe implements PrayerPendingScheduleProbe {
  const _Probe();
  @override
  Future<int?> pendingCount() async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const receiptStore = PrayerScheduleRepairReceiptStore();
  final now = DateTime.utc(2026, 9, 22, 4);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('recent failure for same configuration defers automatic retry', () async {
    await receiptStore.save(PrayerScheduleRepairReceipt(attemptedAt: now.subtract(const Duration(minutes: 2)), outcome: PrayerScheduleRepairOutcome.failed, trigger: PrayerScheduleRepairTrigger.platformScheduleMissing, configurationFingerprint: 'same'));
    final refresher = _Refresher('same');
    final result = await PrayerScheduleAutoRepair(refresher: refresher, pendingProbe: const _Probe()).repairIfNeeded(now: now);
    expect(result, PrayerScheduleRepairResult.deferredAfterFailure);
    expect(refresher.resyncCalls, 0);
  });

  test('configuration change bypasses backoff immediately', () async {
    await receiptStore.save(PrayerScheduleRepairReceipt(attemptedAt: now.subtract(const Duration(minutes: 2)), outcome: PrayerScheduleRepairOutcome.failed, configurationFingerprint: 'old-location'));
    final refresher = _Refresher('new-location');
    final result = await PrayerScheduleAutoRepair(refresher: refresher, pendingProbe: const _Probe()).repairIfNeeded(now: now);
    expect(result, PrayerScheduleRepairResult.failed);
    expect(refresher.resyncCalls, 1);
  });

  test('retry resumes after cooldown expires', () async {
    await receiptStore.save(PrayerScheduleRepairReceipt(attemptedAt: now.subtract(const Duration(minutes: 6)), outcome: PrayerScheduleRepairOutcome.failed, configurationFingerprint: 'same'));
    final refresher = _Refresher('same');
    final result = await PrayerScheduleAutoRepair(refresher: refresher, pendingProbe: const _Probe()).repairIfNeeded(now: now);
    expect(result, PrayerScheduleRepairResult.failed);
    expect(refresher.resyncCalls, 1);
  });

  test('explicit zero retry delay disables backoff for deterministic callers', () async {
    await receiptStore.save(PrayerScheduleRepairReceipt(attemptedAt: now, outcome: PrayerScheduleRepairOutcome.failed, configurationFingerprint: 'same'));
    final refresher = _Refresher('same');
    final result = await PrayerScheduleAutoRepair(refresher: refresher, pendingProbe: const _Probe(), failureRetryDelay: Duration.zero).repairIfNeeded(now: now);
    expect(result, PrayerScheduleRepairResult.failed);
    expect(refresher.resyncCalls, 1);
  });
}
