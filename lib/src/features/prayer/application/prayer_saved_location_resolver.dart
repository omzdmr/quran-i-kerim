import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';
import 'prayer_preferences_store.dart';

class PrayerResolvedLocation {
  const PrayerResolvedLocation({required this.location, required this.defaultMethod, required this.label});
  final PrayerLocation location;
  final PrayerCalculationMethod defaultMethod;
  final String label;
}

/// Resolves only an explicitly saved prayer location. Special device/manual
/// IDs keep their exact coordinates, while missing or unknown catalog IDs fail
/// closed instead of silently turning into Istanbul after restore/travel.
class PrayerSavedLocationResolver {
  const PrayerSavedLocationResolver();

  Future<PrayerResolvedLocation?> resolve() async {
    final id = await PrayerPreferencesStore.loadCityId();
    if (id == PrayerPreferencesStore.deviceLocationId) {
      final saved = await PrayerPreferencesStore.loadDeviceLocation();
      if (saved == null) return null;
      return PrayerResolvedLocation(location: saved.location, defaultMethod: saved.defaultMethod, label: saved.location.label ?? 'GPS');
    }
    if (id == PrayerPreferencesStore.manualLocationId) {
      final saved = await PrayerPreferencesStore.loadManualLocation();
      if (saved == null) return null;
      return PrayerResolvedLocation(location: saved.location, defaultMethod: saved.defaultMethod, label: saved.label);
    }
    if (id == null || id.trim().isEmpty) return null;
    for (final city in prayerCities) {
      if (city.id == id) {
        return PrayerResolvedLocation(location: city.location, defaultMethod: city.defaultMethod, label: city.label);
      }
    }
    return null;
  }
}
