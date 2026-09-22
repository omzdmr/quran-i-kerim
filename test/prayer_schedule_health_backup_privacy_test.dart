import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('schedule health fingerprint and location label stay device-local', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_notification_schedule_health_v1':
          '{"schemaVersion":2,"locationLabel":"Private hotel","configurationFingerprint":"v2-secret-local"}',
      'prayer_notifications_enabled': true,
    });

    final adapter = SharedPreferencesBackupAdapter();
    final exported = await adapter.exportSections();
    final encoded = exported.toString();

    expect(encoded, isNot(contains('prayer_notification_schedule_health_v1')));
    expect(encoded, isNot(contains('Private hotel')));
    expect(encoded, isNot(contains('v2-secret-local')));
    expect(encoded, contains('prayer_notifications_enabled'));
  });
}
