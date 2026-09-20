import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_region_resolver.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

void main() {
  test('resolves common regions without network lookups', () {
    expect(
      resolvePrayerRegion(41.0082, 28.9784).method,
      PrayerCalculationMethod.turkiye,
    );
    expect(
      resolvePrayerRegion(21.3891, 39.8579).method,
      PrayerCalculationMethod.ummAlQura,
    );
    expect(
      resolvePrayerRegion(30.0444, 31.2357).method,
      PrayerCalculationMethod.egyptian,
    );
    expect(
      resolvePrayerRegion(24.8607, 67.0011).method,
      PrayerCalculationMethod.karachi,
    );
    expect(
      resolvePrayerRegion(40.7128, -74.0060).method,
      PrayerCalculationMethod.northAmerica,
    );
    expect(
      resolvePrayerRegion(35.6762, 139.6503).method,
      PrayerCalculationMethod.muslimWorldLeague,
    );
  });

  test('Sinai stays Egyptian inside the former Hejaz overlap', () {
    final sharmElSheikh = resolvePrayerRegion(27.9158, 34.3299);
    final marsaAlam = resolvePrayerRegion(25.0676, 34.8790);

    expect(sharmElSheikh.regionCode, 'egypt');
    expect(sharmElSheikh.method, PrayerCalculationMethod.egyptian);
    expect(marsaAlam.regionCode, 'egypt');
    expect(marsaAlam.method, PrayerCalculationMethod.egyptian);
  });

  test('Saudi cities are not swallowed by the Egypt outline', () {
    for (final location in <(double, double)>[
      (21.3891, 39.8579), // Makkah
      (24.4672, 39.6111), // Madinah
      (28.3838, 36.5662), // Tabuk
    ]) {
      final resolved = resolvePrayerRegion(location.$1, location.$2);
      expect(resolved.regionCode, 'hejaz');
      expect(resolved.method, PrayerCalculationMethod.ummAlQura);
    }
  });
}
