import '../domain/prayer_models.dart';
import 'prayer_calculation_change_log.dart';
import 'prayer_preferences_store.dart';

/// Converts before/after prayer settings into explicit audit events. The caller
/// can persist the returned event after a successful settings save.
class PrayerCalculationChangeDetector {
  const PrayerCalculationChangeDetector._();

  static PrayerCalculationMaterialChange? detectSettingsChange({
    required PrayerSettingsSnapshot before,
    required PrayerSettingsSnapshot after,
    required PrayerCalculationMethod cityDefault,
    required DateTime changedAt,
  }) {
    final beforeMethod = before.methodOverride ?? cityDefault;
    final afterMethod = after.methodOverride ?? cityDefault;
    if (beforeMethod != afterMethod ||
        (before.methodOverride == null) != (after.methodOverride == null)) {
      return PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.calculationMethod,
        changedAt: changedAt,
        previousValue: _methodValue(before.methodOverride, cityDefault),
        currentValue: _methodValue(after.methodOverride, cityDefault),
      );
    }
    if (before.asrMethod != after.asrMethod) {
      return PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.asrSchool,
        changedAt: changedAt,
        previousValue: before.asrMethod.name,
        currentValue: after.asrMethod.name,
      );
    }
    if (before.highLatitudeMethod != after.highLatitudeMethod) {
      return PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.highLatitudeRule,
        changedAt: changedAt,
        previousValue: before.highLatitudeMethod.name,
        currentValue: after.highLatitudeMethod.name,
      );
    }

    final beforeOffsets = _offsets(before.adjustments);
    final afterOffsets = _offsets(after.adjustments);
    for (final prayerId in beforeOffsets.keys) {
      if (beforeOffsets[prayerId] == afterOffsets[prayerId]) continue;
      return PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.manualOffset,
        changedAt: changedAt,
        prayerId: prayerId,
        previousValue: '${beforeOffsets[prayerId]}',
        currentValue: '${afterOffsets[prayerId]}',
      );
    }
    return null;
  }

  static PrayerCalculationMaterialChange? detectPlaceChange({
    required String beforeLabel,
    required String beforeTimeZone,
    required String afterLabel,
    required String afterTimeZone,
    required DateTime changedAt,
  }) {
    if (beforeLabel != afterLabel) {
      return PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.place,
        changedAt: changedAt,
        previousValue: beforeLabel,
        currentValue: afterLabel,
      );
    }
    if (beforeTimeZone != afterTimeZone) {
      return PrayerCalculationMaterialChange(
        kind: PrayerCalculationChangeKind.timezone,
        changedAt: changedAt,
        previousValue: beforeTimeZone,
        currentValue: afterTimeZone,
      );
    }
    return null;
  }

  static String _methodValue(
    PrayerCalculationMethod? override,
    PrayerCalculationMethod cityDefault,
  ) => override == null ? 'automatic:${cityDefault.name}' : 'manual:${override.name}';

  static Map<String, int> _offsets(PrayerMinuteAdjustments value) => {
    'fajr': value.fajr,
    'sunrise': value.sunrise,
    'dhuhr': value.dhuhr,
    'asr': value.asr,
    'maghrib': value.maghrib,
    'isha': value.isha,
  };
}
