import '../domain/prayer_models.dart';

class PrayerRegionResolution {
  const PrayerRegionResolution({
    required this.method,
    required this.regionCode,
  });

  final PrayerCalculationMethod method;
  final String regionCode;
}

/// Chooses a sensible calculation method from coarse geographic regions.
///
/// This deliberately uses no reverse-geocoding or web API. The ranges are
/// broad recommendations only; users can always override the method in Prayer
/// Settings when their local authority uses a different convention.
PrayerRegionResolution resolvePrayerRegion(double latitude, double longitude) {
  bool inside(double south, double north, double west, double east) =>
      latitude >= south &&
      latitude <= north &&
      longitude >= west &&
      longitude <= east;

  if (inside(35.5, 42.6, 25.4, 45.1)) {
    return const PrayerRegionResolution(
      method: PrayerCalculationMethod.turkiye,
      regionCode: 'turkiye',
    );
  }

  if (inside(15.0, 33.6, 34.0, 56.8)) {
    return const PrayerRegionResolution(
      method: PrayerCalculationMethod.ummAlQura,
      regionCode: 'hejaz',
    );
  }

  if (inside(21.0, 32.0, 24.0, 37.5)) {
    return const PrayerRegionResolution(
      method: PrayerCalculationMethod.egyptian,
      regionCode: 'egypt',
    );
  }

  final southAsia = inside(5.0, 39.5, 60.0, 98.0);
  if (southAsia) {
    return const PrayerRegionResolution(
      method: PrayerCalculationMethod.karachi,
      regionCode: 'southAsia',
    );
  }

  final northAmerica = inside(24.0, 72.0, -170.0, -50.0);
  if (northAmerica) {
    return const PrayerRegionResolution(
      method: PrayerCalculationMethod.northAmerica,
      regionCode: 'northAmerica',
    );
  }

  return const PrayerRegionResolution(
    method: PrayerCalculationMethod.muslimWorldLeague,
    regionCode: 'world',
  );
}
