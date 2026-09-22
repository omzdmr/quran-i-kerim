import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_refresher.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_store.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_pending_schedule_probe.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_auto_repair.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Refresher extends PrayerNotificationScheduleHealthRefresher {
  _Refresher(this.fingerprint, this.result);
  final String? fingerprint;
  final PrayerNotificationScheduleHealth? result;
  @override
  Future<String?> currentConfigurationFingerprint() async => fingerprint;
  @override
  Future<PrayerNotificationScheduleHealth?> resync({DateTime? now}) async => result;
}

class _Probe implements PrayerPendingScheduleProbe {
  const _Probe(this.count);
  final int? count;
  @override
  Future<int?> pendingCount() async => count;
}

PrayerNotificationScheduleHealth _health(String fingerprint, {DateTime? scheduledAt}) => PrayerNotificationScheduleHealth(
  scheduledAt: scheduledAt ?? DateTime.utc(2026, 9, 22, 2),
  nextPrayerId: 'dhuhr',
  nextScheduledAt: DateTime.utc(2026, 9, 22, 8),
  timeZoneId: 'Asia/Shanghai',
  locationLabel: 'Shanghai',
  calculationMethodId: 'muslimWorldLeague',
  pendingCount: 8,
  configurationFingerprint: fingerprint,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const healthStore = PrayerNotificationScheduleHealthStore();
  const receiptStore = PrayerScheduleRepairReceiptStore();
  final now = DateTime.utc(2026, 9, 22, 3);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('classifies travel/settings fingerprint drift', () async {
    await healthStore.save(_health('before-travel'));
    final repair = PrayerScheduleAutoRepair(refresher: _Refresher('after-travel', _health('after-travel')), store: healthStore, pendingProbe: const _Probe(8));
    await repair.repairIfNeeded(now: now);
    expect((await receiptStore.load())?.trigger, PrayerScheduleRepairTrigger.configurationChanged);
  });

  test('classifies missing OS requests separately from stale evidence', () async {
    await healthStore.save(_health('same'));
    final repair = PrayerScheduleAutoRepair(refresher: _Refresher('same', _health('same')), store: healthStore, pendingProbe: const _Probe(0));
    await repair.repairIfNeeded(now: now);
    expect((await receiptStore.load())?.trigger, PrayerScheduleRepairTrigger.platformScheduleMissing);
  });

  test('classifies old schedule evidence', () async {
    await healthStore.save(_health('same', scheduledAt: DateTime.utc(2026, 9, 19)));
    final repair = PrayerScheduleAutoRepair(refresher: _Refresher('same', _health('same')), store: healthStore, pendingProbe: const _Probe(8));
    await repair.repairIfNeeded(now: now);
    expect((await receiptStore.load())?.trigger, PrayerScheduleRepairTrigger.staleEvidence);
  });

  test('classifies a verified fresh schedule without rescheduling it', () async {
    await healthStore.save(_health('same'));
    final repair = PrayerScheduleAutoRepair(refresher: _Refresher('same', null), store: healthStore, pendingProbe: const _Probe(4));
    expect(await repair.repairIfNeeded(now: now), PrayerScheduleRepairResult.alreadyFresh);
    expect((await receiptStore.load())?.trigger, PrayerScheduleRepairTrigger.verifiedFresh);
  });
}
