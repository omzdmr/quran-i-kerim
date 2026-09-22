import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_preferences_store.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_saved_location_resolver.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const resolver = PrayerSavedLocationResolver();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('manual location resolves its exact coordinates instead of Istanbul fallback', () async {
    await PrayerPreferencesStore.saveManualLocation(const PrayerManualLocationSnapshot(
      sourceId: 'geonames:1796236', label: 'Shanghai', country: 'China',
      location: PrayerLocation(latitude: 31.2304, longitude: 121.4737, timeZoneId: 'Asia/Shanghai', label: 'Shanghai'),
      defaultMethod: PrayerCalculationMethod.muslimWorldLeague, regionCode: 'CN',
    ));
    final resolved = await resolver.resolve();
    expect(resolved, isNotNull);
    expect(resolved!.label, 'Shanghai');
    expect(resolved.location.latitude, closeTo(31.2304, 0.0001));
    expect(resolved.location.longitude, closeTo(121.4737, 0.0001));
    expect(resolved.location.timeZoneId, 'Asia/Shanghai');
    expect(resolved.defaultMethod, PrayerCalculationMethod.muslimWorldLeague);
  });

  test('device location remains exact and does not use catalog fallback', () async {
    await PrayerPreferencesStore.saveDeviceLocation(const PrayerDeviceLocationSnapshot(
      location: PrayerLocation(latitude: 35.6762, longitude: 139.6503, timeZoneId: 'Asia/Tokyo', label: 'GPS'),
      defaultMethod: PrayerCalculationMethod.muslimWorldLeague, regionCode: 'JP',
    ));
    final resolved = await resolver.resolve();
    expect(resolved!.location.latitude, closeTo(35.6762, 0.0001));
    expect(resolved.location.timeZoneId, 'Asia/Tokyo');
  });

  test('catalog city resolves normally', () async {
    await PrayerPreferencesStore.saveCityId('baku');
    final resolved = await resolver.resolve();
    expect(resolved!.label, 'Bakü');
    expect(resolved.location.timeZoneId, 'Asia/Baku');
  });

  test('missing special-location payload fails closed', () async {
    await PrayerPreferencesStore.saveCityId(PrayerPreferencesStore.manualLocationId);
    expect(await resolver.resolve(), isNull);
  });

  test('no saved location after privacy-safe restore does not become Istanbul', () async {
    expect(await resolver.resolve(), isNull);
  });

  test('unknown or obsolete catalog id does not become Istanbul', () async {
    await PrayerPreferencesStore.saveCityId('removed-city-id');
    expect(await resolver.resolve(), isNull);
  });
}
