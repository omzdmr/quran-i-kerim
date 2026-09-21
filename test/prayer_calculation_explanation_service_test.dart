import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calculation_explanation_service.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_preferences_store.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

void main() {
  test('explanation uses the same effective settings as calculator preferences', () {
    const settings = PrayerSettingsSnapshot(
      methodOverride: PrayerCalculationMethod.ummAlQura,
      asrMethod: PrayerAsrMethod.hanafi,
      highLatitudeMethod: PrayerHighLatitudeMethod.seventhOfTheNight,
      adjustments: PrayerMinuteAdjustments(asr: 4, isha: -3),
    );

    final preferences = settings.preferencesFor(
      PrayerCalculationMethod.muslimWorldLeague,
    );
    final explanation = PrayerCalculationExplanationService.fromSettings(
      cityDefault: PrayerCalculationMethod.muslimWorldLeague,
      settings: settings,
    );

    expect(explanation.effectiveMethod, preferences.calculationMethod);
    expect(explanation.asrMethod, preferences.asrMethod);
    expect(explanation.highLatitudeMethod, preferences.highLatitudeMethod);
    expect(explanation.adjustments.asr, preferences.adjustments.asr);
    expect(explanation.adjustments.isha, preferences.adjustments.isha);
    expect(explanation.methodIsAutomatic, isFalse);
  });

  test('automatic explanation follows a changed city default', () {
    const settings = PrayerSettingsSnapshot();

    final first = PrayerCalculationExplanationService.fromSettings(
      cityDefault: PrayerCalculationMethod.turkiye,
      settings: settings,
    );
    final second = PrayerCalculationExplanationService.fromSettings(
      cityDefault: PrayerCalculationMethod.northAmerica,
      settings: settings,
    );

    expect(first.methodIsAutomatic, isTrue);
    expect(second.methodIsAutomatic, isTrue);
    expect(first.effectiveMethod, PrayerCalculationMethod.turkiye);
    expect(second.effectiveMethod, PrayerCalculationMethod.northAmerica);
  });
}
