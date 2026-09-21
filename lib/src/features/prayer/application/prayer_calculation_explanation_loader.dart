import 'package:timezone/timezone.dart' as tz;

import '../domain/prayer_calculation_explanation.dart';
import '../domain/prayer_city_catalog.dart';
import 'prayer_calculation_explanation_service.dart';
import 'prayer_preferences_store.dart';

/// Reconstructs explainability state from the same local persistence used by
/// PrayerScreen. No network/backend is involved.
class PrayerCalculationExplanationLoader {
  const PrayerCalculationExplanationLoader._();

  static Future<PrayerCalculationExplanation> load() async {
    final settings = await PrayerPreferencesStore.loadSettings();
    final cityId = await PrayerPreferencesStore.loadCityId();
    final city = await _resolveCity(cityId);
    final zone = tz.getLocation(city.location.timeZoneId);
    final now = tz.TZDateTime.now(zone);

    return PrayerCalculationExplanationService.fromSettings(
      cityDefault: city.defaultMethod,
      settings: settings,
      location: city.location,
      localDate: DateTime(now.year, now.month, now.day),
      sourceVersion: 'adhan_dart/local',
    );
  }

  static Future<PrayerCity> _resolveCity(String? cityId) async {
    if (cityId == PrayerPreferencesStore.deviceLocationId) {
      final device = await PrayerPreferencesStore.loadDeviceLocation();
      if (device != null) {
        return PrayerCity(
          id: PrayerPreferencesStore.deviceLocationId,
          label: device.location.label ?? 'GPS',
          country: '',
          group: device.regionCode,
          location: device.location,
          defaultMethod: device.defaultMethod,
        );
      }
    }

    if (cityId == PrayerPreferencesStore.manualLocationId) {
      final manual = await PrayerPreferencesStore.loadManualLocation();
      if (manual != null) {
        return PrayerCity(
          id: manual.sourceId,
          label: manual.label,
          country: manual.country,
          group: manual.regionCode,
          location: manual.location,
          defaultMethod: manual.defaultMethod,
        );
      }
    }

    if (cityId != null) {
      for (final city in prayerCities) {
        if (city.id == cityId) return city;
      }
    }
    return prayerCities.first;
  }
}
