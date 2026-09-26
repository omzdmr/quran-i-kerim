import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calculation_change_detector.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calculation_change_log.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_preferences_store.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

void main() {
  test('one settings save can expose every material calculation change', () {
    const before = PrayerSettingsSnapshot();
    const after = PrayerSettingsSnapshot(
      methodOverride: PrayerCalculationMethod.muslimWorldLeague,
      asrMethod: PrayerAsrMethod.hanafi,
      highLatitudeMethod: PrayerHighLatitudeMethod.middleOfTheNight,
      adjustments: PrayerMinuteAdjustments(fajr: -2, isha: 4),
      notificationsEnabled: true,
    );

    final changes = PrayerCalculationChangeDetector.detectSettingsChanges(
      before: before,
      after: after,
      cityDefault: PrayerCalculationMethod.turkiye,
      changedAt: DateTime.utc(2026, 9, 21, 12),
    );

    expect(
      changes.map((change) => change.kind),
      [
        PrayerCalculationChangeKind.calculationMethod,
        PrayerCalculationChangeKind.asrSchool,
        PrayerCalculationChangeKind.highLatitudeRule,
        PrayerCalculationChangeKind.manualOffset,
        PrayerCalculationChangeKind.manualOffset,
      ],
    );
    expect(
      changes
          .where((change) => change.kind == PrayerCalculationChangeKind.manualOffset)
          .map((change) => change.prayerId),
      ['fajr', 'isha'],
    );
    expect(
      changes.any((change) => change.currentValue == 'true'),
      isFalse,
      reason: 'notification-only state must not enter prayer-time audit data',
    );
  });
}
