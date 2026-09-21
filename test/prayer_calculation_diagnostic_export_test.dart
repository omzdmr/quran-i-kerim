import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calculation_diagnostic_export.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_calculation_explanation.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

void main() {
  test('plain-text diagnostic is useful but excludes precise coordinates', () {
    final explanation = PrayerCalculationExplanation.from(
      defaultMethod: PrayerCalculationMethod.turkiye,
      methodOverride: null,
      asrMethod: PrayerAsrMethod.hanafi,
      highLatitudeMethod: PrayerHighLatitudeMethod.recommended,
      adjustments: const PrayerMinuteAdjustments(asr: 3),
      location: const PrayerLocation(
        latitude: 39.9334,
        longitude: 32.8597,
        timeZoneId: 'Europe/Istanbul',
        label: 'Ankara',
      ),
      localDate: DateTime(2026, 9, 21),
      sourceVersion: 'adhan-dart/local',
    );

    final text = PrayerCalculationDiagnosticExport.asText(
      explanation,
      prayerId: 'asr',
    );

    expect(text, startsWith('Prayer time diagnostic'));
    expect(text, contains('place: Ankara'));
    expect(text, contains('localDate: 2026-09-21'));
    expect(text, contains('timezone: Europe/Istanbul'));
    expect(text, contains('prayer: asr'));
    expect(text, contains('method: turkiye'));
    expect(text, contains('asr: hanafi'));
    expect(text, contains('manualOffsetMinutes: 3'));
    expect(text, isNot(contains('39.9334')));
    expect(text, isNot(contains('32.8597')));
    expect(text.toLowerCase(), isNot(contains('latitude')));
    expect(text.toLowerCase(), isNot(contains('longitude')));
  });
}
