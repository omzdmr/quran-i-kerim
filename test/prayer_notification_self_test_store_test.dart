import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_self_test_store.dart';

void main() {
  const store = PrayerNotificationSelfTestStore();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('user-confirmed notification result survives restart', () async {
    final when = DateTime(2026, 9, 22, 10, 30);
    await store.save(PrayerNotificationProbeOutcome.received, now: when);
    final loaded = await store.load();
    expect(loaded?.outcome, PrayerNotificationProbeOutcome.received);
    expect(loaded?.confirmedAt, when);
  });

  test('recent user verification is fresh but old success expires', () {
    final now = DateTime.utc(2026, 9, 22, 4);
    final recent = PrayerNotificationProbeRecord(outcome: PrayerNotificationProbeOutcome.received, confirmedAt: now.subtract(const Duration(days: 10)));
    final old = PrayerNotificationProbeRecord(outcome: PrayerNotificationProbeOutcome.received, confirmedAt: now.subtract(const Duration(days: 31)));
    expect(recent.isFreshAt(now), isTrue);
    expect(old.isFreshAt(now), isFalse);
  });

  test('future timestamp never becomes trusted verification', () {
    final now = DateTime.utc(2026, 9, 22, 4);
    final future = PrayerNotificationProbeRecord(outcome: PrayerNotificationProbeOutcome.received, confirmedAt: now.add(const Duration(minutes: 1)));
    expect(future.isFreshAt(now), isFalse);
  });

  test('freshness boundary is inclusive and can be overridden', () {
    final now = DateTime.utc(2026, 9, 22, 4);
    final record = PrayerNotificationProbeRecord(outcome: PrayerNotificationProbeOutcome.notReceived, confirmedAt: now.subtract(const Duration(days: 30)));
    expect(record.isFreshAt(now), isTrue);
    expect(record.isFreshAt(now, maxAge: const Duration(days: 7)), isFalse);
  });

  test('corrupt or unknown verification record fails closed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{PrayerNotificationSelfTestStore.storageKey: '{broken'});
    expect(await store.load(), isNull);
    SharedPreferences.setMockInitialValues(<String, Object>{PrayerNotificationSelfTestStore.storageKey: '{"outcome":"future-value","confirmedAt":"2026-09-22T00:00:00.000Z"}'});
    expect(await store.load(), isNull);
  });
}
