import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_notification_self_test_store.dart';

void main() {
  test('device-specific notification verification is not portable backup data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const PrayerNotificationSelfTestStore().save(
      PrayerNotificationProbeOutcome.received,
      now: DateTime(2026, 9, 22),
    );
    final backup = await const SharedPreferencesBackupAdapter().capture();
    expect(backup.containsKey(PrayerNotificationSelfTestStore.storageKey), isFalse);
  });
}