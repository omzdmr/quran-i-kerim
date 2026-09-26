import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_calculation_explanation.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

void main() {
  test('diagnostic snapshot keeps place context but never exports coordinates', () {
    final explanation = PrayerCalculationExplanation.from(
      defaultMethod: PrayerCalculationMethod.turkiye,
      methodOverride: null,
      asrMethod: PrayerAsrMethod.standard,
      highLatitudeMethod: PrayerHighLatitudeMethod.recommended,
      adjustments: const PrayerMinuteAdjustments(fajr: -2),
      location: const PrayerLocation(
        latitude: 41.0082,
        longitude: 28.9784,
        timeZoneId: 'Europe/Istanbul',
        label: 'Istanbul',
      ),
      localDate: DateTime(2026, 9, 21),
      sourceVersion: 'adhan-dart/local',
    );

    final snapshot = explanation.diagnosticSnapshot(prayerId: 'fajr');

    expect(snapshot['place'], 'Istanbul');
    expect(snapshot['timezone'], 'Europe/Istanbul');
    expect(snapshot['localDate'], '2026-09-21');
    expect(snapshot['source'], 'calculated');
    expect(snapshot['method'], 'turkiye');
    expect(snapshot['methodSelection'], 'automatic');
    expect(snapshot['prayer'], 'fajr');
    expect(snapshot['manualOffsetMinutes'], '-2');
    expect(snapshot.keys, isNot(contains('latitude')));
    expect(snapshot.keys, isNot(contains('longitude')));
    expect(snapshot.values.join(' '), isNot(contains('41.0082')));
    expect(snapshot.values.join(' '), isNot(contains('28.9784')));
  });

  test('diagnostic snapshot distinguishes timetable source kinds', () {
    final explanation = PrayerCalculationExplanation.from(
      defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
      methodOverride: PrayerCalculationMethod.muslimWorldLeague,
      asrMethod: PrayerAsrMethod.hanafi,
      highLatitudeMethod: PrayerHighLatitudeMethod.seventhOfTheNight,
      adjustments: const PrayerMinuteAdjustments(),
      sourceKind: PrayerTimeSourceKind.authorizedTimetable,
      sourceVersion: 'mosque-feed-2026-09',
    );

    final snapshot = explanation.diagnosticSnapshot();
    expect(snapshot['source'], 'authorizedTimetable');
    expect(snapshot['sourceVersion'], 'mosque-feed-2026-09');
    expect(snapshot['methodSelection'], 'manual');
  });
}
