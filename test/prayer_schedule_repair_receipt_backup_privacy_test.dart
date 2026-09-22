import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('automatic repair receipt remains device-local and out of portable backup', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const PrayerScheduleRepairReceiptStore().save(
      PrayerScheduleRepairReceipt(
        attemptedAt: DateTime.utc(2026, 9, 22, 4),
        outcome: PrayerScheduleRepairOutcome.repaired,
        configurationFingerprint: 'device-schedule-fingerprint',
      ),
    );

    final exported = await const SharedPreferencesBackupAdapter().exportSections();
    expect(exported.toString(), isNot(contains('prayer_schedule_repair_receipt_v1')));
    expect(exported.toString(), isNot(contains('device-schedule-fingerprint')));
  });
}
