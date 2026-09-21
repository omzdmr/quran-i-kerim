import '../domain/prayer_calculation_explanation.dart';
import '../domain/prayer_models.dart';
import 'prayer_preferences_store.dart';

/// Keeps the explanation surface wired to the exact same persisted settings
/// that the calculator uses, preventing a second set of display-only defaults.
class PrayerCalculationExplanationService {
  const PrayerCalculationExplanationService._();

  static PrayerCalculationExplanation fromSettings({
    required PrayerCalculationMethod cityDefault,
    required PrayerSettingsSnapshot settings,
  }) => PrayerCalculationExplanation.from(
    defaultMethod: cityDefault,
    methodOverride: settings.methodOverride,
    asrMethod: settings.asrMethod,
    highLatitudeMethod: settings.highLatitudeMethod,
    adjustments: settings.adjustments,
  );
}
