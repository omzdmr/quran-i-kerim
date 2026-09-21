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

  test('corrupt or unknown verification record fails closed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrayerNotificationSelfTestStore.storageKey: '{broken',
    });
    expect(await store.load(), isNull);

    SharedPreferences.setMockInitialValues(<String, Object>{
      PrayerNotificationSelfTestStore.storageKey:
          '{"outcome":"future-value","confirmedAt":"2026-09-22T00:00:00.000Z"}',
    });
    expect(await store.load(), isNull);
  });
}