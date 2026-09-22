import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_preferences_store.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_saved_location_resolver.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adapter = SharedPreferencesBackupAdapter();
  const resolver = PrayerSavedLocationResolver();

  test('portable restore keeps prayer preferences but never invents a location', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PrayerPreferencesStore.save(const PrayerSettingsSnapshot(
      notificationsEnabled: true,
      notificationPrayerIds: {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'},
      notificationProfile: PrayerNotificationProfile.discreet,
    ));
    await PrayerPreferencesStore.saveManualLocation(const PrayerManualLocationSnapshot(
      sourceId: 'manual:hotel',
      label: 'Private hotel',
      country: 'China',
      location: PrayerLocation(
        latitude: 31.2304,
        longitude: 121.4737,
        timeZoneId: 'Asia/Shanghai',
        label: 'Private hotel',
      ),
      defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
      regionCode: 'CN',
    ));

    final portable = await adapter.captureSections();
    expect(portable.toString(), isNot(contains('Private hotel')));
    expect(portable.toString(), isNot(contains('31.2304')));

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(portable);

    final restoredSettings = await PrayerPreferencesStore.load();
    expect(restoredSettings.notificationsEnabled, isTrue);
    expect(restoredSettings.notificationProfile, PrayerNotificationProfile.discreet);
    expect(await PrayerPreferencesStore.loadCityId(), isNull);
    expect(await resolver.resolve(), isNull);
  });
}
