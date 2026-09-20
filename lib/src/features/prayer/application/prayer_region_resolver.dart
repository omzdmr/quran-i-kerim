import '../domain/prayer_models.dart';

class PrayerRegionResolution {
  const PrayerRegionResolution({
    required this.method,
    required this.regionCode,
  });

  final PrayerCalculationMethod method;
  final String regionCode;
}

bool _insidePolygon(
  double latitude,
  double longitude,
  List<(double latitude, double longitude)> polygon,
) {
  var inside = false;
  var previous = polygon.length - 1;
  for (var current = 0; current < polygon.length; current++) {
    final currentPoint = polygon[current];
    final previousPoint = polygon[previous];
    final currentLat = currentPoint.$1;
    final currentLon = currentPoint.$2;
    final previousLat = previousPoint.$1;
    final previousLon = previousPoint.$2;

    final crossesLatitude =
        (currentLat > latitude) != (previousLat > latitude);
    if (crossesLatitude) {
      final boundaryLongitude =
          (previousLon - currentLon) *
              (latitude - currentLat) /
              (previousLat - currentLat) +
          currentLon;
      if (longitude < boundaryLongitude) inside = !inside;
    }
    previous = current;
  }
  return inside;
}

/// Coarse outline used only to separate Egypt, including Sinai, from the broad
/// Red Sea / Arabian Peninsula recommendation envelope below. It intentionally
/// avoids pretending to be a legal national-border dataset; users can still
/// override the resulting calculation method in Prayer Settings.
const _egyptApproximateOutline = <(double, double)>[
  (31.7, 24.7),
  (31.7, 34.5),
  (31.2, 34.2),
  (29.5, 34.9),
  (27.7, 34.3),
  (22.0, 36.9),
  (22.0, 24.7),
];

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

  // Egypt and Sinai overlap the old broad Hejaz rectangle around the Gulf of
  // Aqaba. Resolve the Egyptian outline first, then let the remaining Red Sea
  // / Arabian Peninsula envelope use Umm al-Qura. This fixes Sinai without
  // simply reversing two overlapping rectangles and misclassifying Saudi
  // cities such as Tabuk.
  if (_insidePolygon(latitude, longitude, _egyptApproximateOutline)) {
    return const PrayerRegionResolution(
      method: PrayerCalculationMethod.egyptian,
      regionCode: 'egypt',
    );
  }

  if (inside(15.0, 33.6, 34.0, 56.8)) {
    return const PrayerRegionResolution(
      method: PrayerCalculationMethod.ummAlQura,
      regionCode: 'hejaz',
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
