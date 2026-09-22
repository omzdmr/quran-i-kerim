import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';
import 'prayer_preferences_store.dart';

class PrayerResolvedLocation {
  const PrayerResolvedLocation({required this.location, required this.defaultMethod, required this.label});
  final PrayerLocation location;
  final PrayerCalculationMethod defaultMethod;
  final String label;
}

/// Resolves saved prayer locations without silently falling back for broken
/// special/obsolete IDs. A null ID retains the product's existing first-run
/// default city behavior until the settings flow gains an explicit location-
/// confirmation state.
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
    if (id == null || id.trim().isEmpty) {
      final city = prayerCities.first;
      return PrayerResolvedLocation(location: city.location, defaultMethod: city.defaultMethod, label: city.label);
    }
    for (final city in prayerCities) {
      if (city.id == id) {
        return PrayerResolvedLocation(location: city.location, defaultMethod: city.defaultMethod, label: city.label);
      }
    }
    return null;
  }
}
