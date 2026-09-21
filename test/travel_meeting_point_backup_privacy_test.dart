import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_store.dart';

void main() {
  test('private travel meeting point is not captured by automatic backup', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const TravelMeetingPointStore().save(TravelMeetingPoint(
      name: 'Private hotel',
      address: 'Private address',
      note: 'Room-side entrance',
      updatedAt: DateTime(2026, 9, 22),
    ));

    final backup = await const SharedPreferencesBackupAdapter().capture();
    expect(backup.containsKey(TravelMeetingPointStore.storageKey), isFalse);
  });
}