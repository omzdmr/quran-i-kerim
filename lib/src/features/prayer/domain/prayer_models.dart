enum PrayerCalculationMethod {
  turkiye,
  muslimWorldLeague,
  ummAlQura,
  egyptian,
  karachi,
  northAmerica,
  moonsightingCommittee,
}

enum PrayerAsrMethod { standard, hanafi }

enum PrayerHighLatitudeMethod {
  recommended,
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
}

class PrayerLocation {
  const PrayerLocation({
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
    this.label,
  });

  final double latitude;
  final double longitude;
  final String timeZoneId;
  final String? label;
}

class PrayerMinuteAdjustments {
  const PrayerMinuteAdjustments({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });

  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;
}

class PrayerPreferences {
  const PrayerPreferences({
    this.calculationMethod = PrayerCalculationMethod.turkiye,
    this.asrMethod = PrayerAsrMethod.standard,
    this.highLatitudeMethod = PrayerHighLatitudeMethod.recommended,
    this.adjustments = const PrayerMinuteAdjustments(),
  });

  final PrayerCalculationMethod calculationMethod;
  final PrayerAsrMethod asrMethod;
  final PrayerHighLatitudeMethod highLatitudeMethod;
  final PrayerMinuteAdjustments adjustments;
}

class PrayerDaySchedule {
  const PrayerDaySchedule({
    required this.localDate,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.qiblaDegrees,
  });

  final DateTime localDate;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final double qiblaDegrees;

  List<({String id, String label, DateTime time})> get rows => [
        (id: 'fajr', label: 'İmsak', time: fajr),
        (id: 'sunrise', label: 'Güneş', time: sunrise),
        (id: 'dhuhr', label: 'Öğle', time: dhuhr),
        (id: 'asr', label: 'İkindi', time: asr),
        (id: 'maghrib', label: 'Akşam', time: maghrib),
        (id: 'isha', label: 'Yatsı', time: isha),
      ];
}
