import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_self_test_store.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_schedule_health_store.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('device prayer diagnostics remain out of user portable backup', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const PrayerScheduleRepairReceiptStore().save(PrayerScheduleRepairReceipt(attemptedAt: DateTime.utc(2026, 9, 22, 4), outcome: PrayerScheduleRepairOutcome.repaired, configurationFingerprint: 'device-schedule-fingerprint'));
    await const PrayerNotificationSelfTestStore().save(PrayerNotificationProbeOutcome.received, now: DateTime.utc(2026, 9, 22, 4));
    await const PrayerNotificationScheduleHealthStore().save(PrayerNotificationScheduleHealth(
      scheduledAt: DateTime.utc(2026, 9, 22, 4), nextPrayerId: 'dhuhr', nextScheduledAt: DateTime.utc(2026, 9, 22, 5),
      timeZoneId: 'Asia/Shanghai', locationLabel: 'Shanghai', calculationMethodId: 'muslimWorldLeague', pendingCount: 8, configurationFingerprint: 'device-health-fingerprint',
    ));

    final portable = (await const SharedPreferencesBackupAdapter().captureSections()).toString();
    expect(portable, isNot(contains('prayer_schedule_repair_receipt_v1')));
    expect(portable, isNot(contains(PrayerNotificationSelfTestStore.storageKey)));
    expect(portable, isNot(contains('device-schedule-fingerprint')));
    expect(portable, isNot(contains('device-health-fingerprint')));
    expect(portable, isNot(contains('Shanghai')));
  });
}
