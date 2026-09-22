import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = PrayerNotificationScheduleHealthStore();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  PrayerNotificationScheduleHealth sample({DateTime? scheduledAt, DateTime? next, String fingerprint = 'v2-current'}) =>
      PrayerNotificationScheduleHealth(
        scheduledAt: scheduledAt ?? DateTime.utc(2026, 9, 22, 2),
        nextPrayerId: 'dhuhr',
        nextScheduledAt: next ?? DateTime.utc(2026, 9, 22, 4, 30),
        timeZoneId: 'Asia/Shanghai',
        locationLabel: 'Shanghai',
        calculationMethodId: 'muslimWorldLeague',
        pendingCount: 42,
        configurationFingerprint: fingerprint,
      );

  test('round trips schedule provenance locally', () async {
    await store.save(sample());
    final restored = await store.load();
    expect(restored, isNotNull);
    expect(restored!.nextPrayerId, 'dhuhr');
    expect(restored.timeZoneId, 'Asia/Shanghai');
    expect(restored.locationLabel, 'Shanghai');
    expect(restored.calculationMethodId, 'muslimWorldLeague');
    expect(restored.pendingCount, 42);
    expect(restored.configurationFingerprint, 'v2-current');
    expect(restored.schemaVersion, 2);
  });

  test('freshness requires a future prayer and recent scheduling evidence', () {
    final now = DateTime.utc(2026, 9, 22, 3);
    expect(sample().isFreshAt(now), isTrue);
    expect(sample(scheduledAt: DateTime.utc(2026, 9, 20), next: DateTime.utc(2026, 9, 23)).isFreshAt(now), isFalse);
    expect(sample(next: DateTime.utc(2026, 9, 22, 2, 59)).isFreshAt(now), isFalse);
  });

  test('fresh-looking schedule is stale after configuration changes', () {
    final now = DateTime.utc(2026, 9, 22, 3);
    expect(sample().isFreshAt(now, expectedConfigurationFingerprint: 'v2-current'), isTrue);
    expect(sample().isFreshAt(now, expectedConfigurationFingerprint: 'v2-after-travel'), isFalse);
  });

  test('legacy evidence remains readable but cannot satisfy a v2 configuration check', () {
    final now = DateTime.utc(2026, 9, 22, 3);
    final legacy = sample(fingerprint: '');
    expect(legacy.isFreshAt(now), isTrue);
    expect(legacy.isFreshAt(now, expectedConfigurationFingerprint: 'v2-current'), isFalse);
  });

  test('future clock skew is rejected', () {
    final now = DateTime.utc(2026, 9, 22, 3);
    expect(sample(scheduledAt: DateTime.utc(2026, 9, 22, 3, 10)).isFreshAt(now), isFalse);
  });

  test('corrupt or unknown prayer payload fails closed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_notification_schedule_health_v1': '{"scheduledAt":"2026-09-22T02:00:00Z","nextPrayerId":"futurePrayer","nextScheduledAt":"2026-09-22T04:00:00Z","timeZoneId":"Asia/Shanghai","locationLabel":"Shanghai","calculationMethodId":"mwl","pendingCount":1}',
    });
    expect(await store.load(), isNull);
  });

  test('clear removes stale scheduling evidence when notifications are disabled', () async {
    await store.save(sample());
    await store.clear();
    expect(await store.load(), isNull);
  });
}
