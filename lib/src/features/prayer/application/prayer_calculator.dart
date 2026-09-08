import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/prayer_models.dart';

class PrayerCalculator {
  PrayerCalculator() {
    _ensureTimeZonesInitialized();
  }

  static bool _timeZonesInitialized = false;

  static void _ensureTimeZonesInitialized() {
    if (_timeZonesInitialized) return;
    tz_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }

  PrayerDaySchedule calculate({
    required PrayerLocation location,
    required DateTime date,
    PrayerPreferences preferences = const PrayerPreferences(),
  }) {
    final coordinates = Coordinates(location.latitude, location.longitude);
    final zone = tz.getLocation(location.timeZoneId);
    final localDate = tz.TZDateTime(zone, date.year, date.month, date.day);
    final parameters = _parametersFor(preferences.calculationMethod)
      ..madhab = preferences.asrMethod == PrayerAsrMethod.hanafi
          ? Madhab.hanafi
          : Madhab.shafi
      ..highLatitudeRule = _highLatitudeRule(
        preferences.highLatitudeMethod,
        coordinates,
      );

    final adjustments = preferences.adjustments;
    parameters.adjustments[Prayer.fajr] = adjustments.fajr;
    parameters.adjustments[Prayer.sunrise] = adjustments.sunrise;
    parameters.adjustments[Prayer.dhuhr] = adjustments.dhuhr;
    parameters.adjustments[Prayer.asr] = adjustments.asr;
    parameters.adjustments[Prayer.maghrib] = adjustments.maghrib;
    parameters.adjustments[Prayer.isha] = adjustments.isha;

    final times = PrayerTimes(
      coordinates: coordinates,
      date: localDate,
      calculationParameters: parameters,
      precision: false,
    );

    return PrayerDaySchedule(
      localDate: DateTime(localDate.year, localDate.month, localDate.day),
      fajr: tz.TZDateTime.from(times.fajr, zone),
      sunrise: tz.TZDateTime.from(times.sunrise, zone),
      dhuhr: tz.TZDateTime.from(times.dhuhr, zone),
      asr: tz.TZDateTime.from(times.asr, zone),
      maghrib: tz.TZDateTime.from(times.maghrib, zone),
      isha: tz.TZDateTime.from(times.isha, zone),
      qiblaDegrees: Qibla.qibla(coordinates),
    );
  }

  CalculationParameters _parametersFor(PrayerCalculationMethod method) {
    return switch (method) {
      PrayerCalculationMethod.turkiye => CalculationMethodParameters.turkiye(),
      PrayerCalculationMethod.muslimWorldLeague =>
        CalculationMethodParameters.muslimWorldLeague(),
      PrayerCalculationMethod.ummAlQura => CalculationMethodParameters.ummAlQura(),
      PrayerCalculationMethod.egyptian => CalculationMethodParameters.egyptian(),
      PrayerCalculationMethod.karachi => CalculationMethodParameters.karachi(),
      PrayerCalculationMethod.northAmerica =>
        CalculationMethodParameters.northAmerica(),
      PrayerCalculationMethod.moonsightingCommittee =>
        CalculationMethodParameters.moonsightingCommittee(),
    };
  }

  HighLatitudeRule _highLatitudeRule(
    PrayerHighLatitudeMethod method,
    Coordinates coordinates,
  ) {
    return switch (method) {
      PrayerHighLatitudeMethod.recommended =>
        HighLatitudeRule.recommended(coordinates),
      PrayerHighLatitudeMethod.middleOfTheNight =>
        HighLatitudeRule.middleOfTheNight,
      PrayerHighLatitudeMethod.seventhOfTheNight =>
        HighLatitudeRule.seventhOfTheNight,
      PrayerHighLatitudeMethod.twilightAngle => HighLatitudeRule.twilightAngle,
    };
  }
}
