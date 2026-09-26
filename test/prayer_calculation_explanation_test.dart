import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_calculation_explanation.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

void main() {
  group('PrayerCalculationExplanation', () {
    test('uses regional default when method override is absent', () {
      final explanation = PrayerCalculationExplanation.from(
        defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
        methodOverride: null,
        asrMethod: PrayerAsrMethod.standard,
        highLatitudeMethod: PrayerHighLatitudeMethod.recommended,
        adjustments: const PrayerMinuteAdjustments(),
      );

      expect(
        explanation.effectiveMethod,
        PrayerCalculationMethod.muslimWorldLeague,
      );
      expect(explanation.methodIsAutomatic, isTrue);
      expect(explanation.hasManualAdjustments, isFalse);
      expect(explanation.activeAdjustments, isEmpty);
    });

    test('explicit method override is reported as manual', () {
      final explanation = PrayerCalculationExplanation.from(
        defaultMethod: PrayerCalculationMethod.turkiye,
        methodOverride: PrayerCalculationMethod.ummAlQura,
        asrMethod: PrayerAsrMethod.hanafi,
        highLatitudeMethod: PrayerHighLatitudeMethod.middleOfTheNight,
        adjustments: const PrayerMinuteAdjustments(),
      );

      expect(explanation.effectiveMethod, PrayerCalculationMethod.ummAlQura);
      expect(explanation.methodIsAutomatic, isFalse);
      expect(explanation.asrMethod, PrayerAsrMethod.hanafi);
      expect(
        explanation.highLatitudeMethod,
        PrayerHighLatitudeMethod.middleOfTheNight,
      );
    });

    test('keeps only non-zero minute adjustments in active summary', () {
      final explanation = PrayerCalculationExplanation.from(
        defaultMethod: PrayerCalculationMethod.turkiye,
        methodOverride: null,
        asrMethod: PrayerAsrMethod.standard,
        highLatitudeMethod: PrayerHighLatitudeMethod.recommended,
        adjustments: const PrayerMinuteAdjustments(
          fajr: -2,
          dhuhr: 3,
          isha: 5,
        ),
      );

      expect(explanation.hasManualAdjustments, isTrue);
      expect(
        explanation.activeAdjustments.map((entry) => entry.prayerId),
        ['fajr', 'dhuhr', 'isha'],
      );
      expect(
        explanation.activeAdjustments.map((entry) => entry.signedMinutes),
        ['-2', '+3', '+5'],
      );
    });

    test('exposes all six configurable prayer rows in stable order', () {
      final explanation = PrayerCalculationExplanation.from(
        defaultMethod: PrayerCalculationMethod.turkiye,
        methodOverride: null,
        asrMethod: PrayerAsrMethod.standard,
        highLatitudeMethod: PrayerHighLatitudeMethod.recommended,
        adjustments: const PrayerMinuteAdjustments(),
      );

      expect(
        explanation.adjustmentEntries.map((entry) => entry.prayerId),
        ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'],
      );
    });
  });
}
