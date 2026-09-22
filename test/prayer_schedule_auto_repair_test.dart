import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_refresher.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_store.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_pending_schedule_probe.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_auto_repair.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRefresher extends PrayerNotificationScheduleHealthRefresher {
  _FakeRefresher({required this.fingerprint, this.repairResult});

  final String? fingerprint;
  final PrayerNotificationScheduleHealth? repairResult;
  int resyncCalls = 0;

  @override
  Future<String?> currentConfigurationFingerprint() async => fingerprint;

  @override
  Future<PrayerNotificationScheduleHealth?> resync({DateTime? now}) async {
    resyncCalls++;
    return repairResult;
  }
}

class _FakePendingProbe implements PrayerPendingScheduleProbe {
  const _FakePendingProbe(this.value);
  final int? value;
  @override
  Future<int?> pendingCount() async => value;
}

PrayerNotificationScheduleHealth health({
  String fingerprint = 'v2-current',
  DateTime? scheduledAt,
  DateTime? next,
}) => PrayerNotificationScheduleHealth(
      scheduledAt: scheduledAt ?? DateTime.utc(2026, 9, 22, 2),
      nextPrayerId: 'dhuhr',
      nextScheduledAt: next ?? DateTime.utc(2026, 9, 22, 4, 30),
      timeZoneId: 'Asia/Shanghai',
      locationLabel: 'Shanghai',
      calculationMethodId: 'muslimWorldLeague',
      pendingCount: 10,
      configurationFingerprint: fingerprint,
    );

void main() {
  const store = PrayerNotificationScheduleHealthStore();
  final now = DateTime.utc(2026, 9, 22, 3);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('does nothing when notifications have no applicable configuration', () async {
    final refresher = _FakeRefresher(fingerprint: null);
    final repair = PrayerScheduleAutoRepair(refresher: refresher, store: store, pendingProbe: const _FakePendingProbe(0));
    expect(await repair.repairIfNeeded(now: now), PrayerScheduleRepairResult.notApplicable);
    expect(refresher.resyncCalls, 0);
  });

  test('does not churn a fresh matching schedule that still exists in OS', () async {
    await store.save(health());
    final refresher = _FakeRefresher(fingerprint: 'v2-current');
    final repair = PrayerScheduleAutoRepair(refresher: refresher, store: store, pendingProbe: const _FakePendingProbe(8));
    expect(await repair.repairIfNeeded(now: now), PrayerScheduleRepairResult.alreadyFresh);
    expect(refresher.resyncCalls, 0);
  });

  test('unknown platform probe does not cause resume reschedule churn', () async {
    await store.save(health());
    final refresher = _FakeRefresher(fingerprint: 'v2-current');
    final repair = PrayerScheduleAutoRepair(refresher: refresher, store: store, pendingProbe: const _FakePendingProbe(null));
    expect(await repair.repairIfNeeded(now: now), PrayerScheduleRepairResult.alreadyFresh);
    expect(refresher.resyncCalls, 0);
  });

  test('repairs fresh-looking evidence when OS lost every pending reminder', () async {
    await store.save(health());
    final refresher = _FakeRefresher(fingerprint: 'v2-current', repairResult: health());
    final repair = PrayerScheduleAutoRepair(refresher: refresher, store: store, pendingProbe: const _FakePendingProbe(0));
    expect(await repair.repairIfNeeded(now: now), PrayerScheduleRepairResult.repaired);
    expect(refresher.resyncCalls, 1);
  });

  test('repairs immediately after travel or prayer-setting drift', () async {
    await store.save(health(fingerprint: 'v2-before-travel'));
    final refreshed = health(fingerprint: 'v2-after-travel');
    final refresher = _FakeRefresher(fingerprint: 'v2-after-travel', repairResult: refreshed);
    final repair = PrayerScheduleAutoRepair(refresher: refresher, store: store, pendingProbe: const _FakePendingProbe(8));
    expect(await repair.repairIfNeeded(now: now), PrayerScheduleRepairResult.repaired);
    expect(refresher.resyncCalls, 1);
  });

  test('repairs expired evidence even when configuration did not change', () async {
    await store.save(health(scheduledAt: DateTime.utc(2026, 9, 20), next: DateTime.utc(2026, 9, 23)));
    final refresher = _FakeRefresher(fingerprint: 'v2-current', repairResult: health());
    final repair = PrayerScheduleAutoRepair(refresher: refresher, store: store, pendingProbe: const _FakePendingProbe(8));
    expect(await repair.repairIfNeeded(now: now), PrayerScheduleRepairResult.repaired);
    expect(refresher.resyncCalls, 1);
  });

  test('reports failed repair without inventing healthy evidence', () async {
    final refresher = _FakeRefresher(fingerprint: 'v2-current', repairResult: null);
    final repair = PrayerScheduleAutoRepair(refresher: refresher, store: store, pendingProbe: const _FakePendingProbe(0));
    expect(await repair.repairIfNeeded(now: now), PrayerScheduleRepairResult.failed);
    expect(refresher.resyncCalls, 1);
    expect(await store.load(), isNull);
  });
}
