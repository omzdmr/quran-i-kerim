import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';
import 'prayer_preferences_store.dart';

class PrayerResolvedLocation {
  const PrayerResolvedLocation({required this.location, required this.defaultMethod, required this.label});
  final PrayerLocation location;
  final PrayerCalculationMethod defaultMethod;
  final String label;
}

/// Resolves the exact saved prayer location without silently falling back to
/// Istanbul for special device/manual IDs. Notification and widget scheduling
/// should share this resolver so travel/manual-city state cannot drift.
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
    final city = prayerCityById(id);
    return PrayerResolvedLocation(location: city.location, defaultMethod: city.defaultMethod, label: city.label);
  }
}
