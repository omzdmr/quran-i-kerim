import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calculation_change_detector.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calculation_change_log.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_preferences_store.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

void main() {
  final changedAt = DateTime.utc(2026, 9, 21, 12);

  test('detects automatic-to-manual method choice even if effective method matches', () {
    const before = PrayerSettingsSnapshot();
    const after = PrayerSettingsSnapshot(
      methodOverride: PrayerCalculationMethod.turkiye,
    );

    final change = PrayerCalculationChangeDetector.detectSettingsChange(
      before: before,
      after: after,
      cityDefault: PrayerCalculationMethod.turkiye,
      changedAt: changedAt,
    );

    expect(change!.kind, PrayerCalculationChangeKind.calculationMethod);
    expect(change.previousValue, 'automatic:turkiye');
    expect(change.currentValue, 'manual:turkiye');
  });

  test('detects Asr school change', () {
    const before = PrayerSettingsSnapshot();
    const after = PrayerSettingsSnapshot(asrMethod: PrayerAsrMethod.hanafi);

    final change = PrayerCalculationChangeDetector.detectSettingsChange(
      before: before,
      after: after,
      cityDefault: PrayerCalculationMethod.turkiye,
      changedAt: changedAt,
    );

    expect(change!.kind, PrayerCalculationChangeKind.asrSchool);
    expect(change.previousValue, 'standard');
    expect(change.currentValue, 'hanafi');
  });

  test('detects first changed per-prayer manual offset', () {
    const before = PrayerSettingsSnapshot();
    const after = PrayerSettingsSnapshot(
      adjustments: PrayerMinuteAdjustments(maghrib: 2),
    );

    final change = PrayerCalculationChangeDetector.detectSettingsChange(
      before: before,
      after: after,
      cityDefault: PrayerCalculationMethod.turkiye,
      changedAt: changedAt,
    );

    expect(change!.kind, PrayerCalculationChangeKind.manualOffset);
    expect(change.prayerId, 'maghrib');
    expect(change.previousValue, '0');
    expect(change.currentValue, '2');
  });

  test('ignores notification-only changes because they do not alter prayer time', () {
    const before = PrayerSettingsSnapshot();
    const after = PrayerSettingsSnapshot(notificationsEnabled: true);

    final change = PrayerCalculationChangeDetector.detectSettingsChange(
      before: before,
      after: after,
      cityDefault: PrayerCalculationMethod.turkiye,
      changedAt: changedAt,
    );

    expect(change, isNull);
  });

  test('detects place before timezone to keep user-visible reason specific', () {
    final change = PrayerCalculationChangeDetector.detectPlaceChange(
      beforeLabel: 'Ankara',
      beforeTimeZone: 'Europe/Istanbul',
      afterLabel: 'Shanghai',
      afterTimeZone: 'Asia/Shanghai',
      changedAt: changedAt,
    );

    expect(change!.kind, PrayerCalculationChangeKind.place);
    expect(change.previousValue, 'Ankara');
    expect(change.currentValue, 'Shanghai');
  });
}
