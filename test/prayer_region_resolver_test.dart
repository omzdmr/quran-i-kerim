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
}
