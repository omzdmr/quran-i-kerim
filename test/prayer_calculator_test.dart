import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calculator.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

void main() {
  const istanbul = PrayerLocation(
    latitude: 41.0082,
    longitude: 28.9784,
    timeZoneId: 'Europe/Istanbul',
    label: 'İstanbul',
  );

  test('prayer times stay in chronological order', () {
    final schedule = PrayerCalculator().calculate(
      location: istanbul,
      date: DateTime(2026, 9, 8),
    );

    expect(schedule.fajr.isBefore(schedule.sunrise), isTrue);
    expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue);
    expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
    expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
    expect(schedule.maghrib.isBefore(schedule.isha), isTrue);
    expect(schedule.qiblaDegrees, inInclusiveRange(0, 360));
  });

  test('hanafi asr is later than standard asr', () {
    final calculator = PrayerCalculator();
    final standard = calculator.calculate(
      location: istanbul,
      date: DateTime(2026, 9, 8),
      preferences: const PrayerPreferences(asrMethod: PrayerAsrMethod.standard),
    );
    final hanafi = calculator.calculate(
      location: istanbul,
      date: DateTime(2026, 9, 8),
      preferences: const PrayerPreferences(asrMethod: PrayerAsrMethod.hanafi),
    );

    expect(hanafi.asr.isAfter(standard.asr), isTrue);
  });

  test('manual minute adjustments are applied', () {
    final calculator = PrayerCalculator();
    final base = calculator.calculate(
      location: istanbul,
      date: DateTime(2026, 9, 8),
    );
    final adjusted = calculator.calculate(
      location: istanbul,
      date: DateTime(2026, 9, 8),
      preferences: const PrayerPreferences(
        adjustments: PrayerMinuteAdjustments(fajr: 2, isha: -3),
      ),
    );

    expect(adjusted.fajr.difference(base.fajr).inMinutes, 2);
    expect(adjusted.isha.difference(base.isha).inMinutes, -3);
  });
}
