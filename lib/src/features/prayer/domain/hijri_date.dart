class PrayerHijriDate {
  const PrayerHijriDate({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final int month;
  final int day;

  static PrayerHijriDate fromGregorian(
    DateTime date, {
    int offsetDays = 0,
  }) {
    final adjusted = DateTime(date.year, date.month, date.day)
        .add(Duration(days: offsetDays));
    final a = (14 - adjusted.month) ~/ 12;
    final y = adjusted.year + 4800 - a;
    final m = adjusted.month + 12 * a - 3;
    final julianDay = adjusted.day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;

    var l = julianDay - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return PrayerHijriDate(year: year, month: month, day: day);
  }

  String monthName(String languageCode) {
    const names = <String, List<String>>{
      'tr': <String>[
        'Muharrem',
        'Safer',
        'Rebiülevvel',
        'Rebiülahir',
        'Cemaziyelevvel',
        'Cemaziyelahir',
        'Recep',
        'Şaban',
        'Ramazan',
        'Şevval',
        'Zilkade',
        'Zilhicce',
      ],
      'en': <String>[
        'Muharram',
        'Safar',
        'Rabi al-Awwal',
        'Rabi al-Thani',
        'Jumada al-Awwal',
        'Jumada al-Thani',
        'Rajab',
        'Sha’ban',
        'Ramadan',
        'Shawwal',
        'Dhu al-Qadah',
        'Dhu al-Hijjah',
      ],
      'ar': <String>[
        'محرم',
        'صفر',
        'ربيع الأول',
        'ربيع الآخر',
        'جمادى الأولى',
        'جمادى الآخرة',
        'رجب',
        'شعبان',
        'رمضان',
        'شوال',
        'ذو القعدة',
        'ذو الحجة',
      ],
      'az': <String>[
        'Məhərrəm',
        'Səfər',
        'Rəbiüləvvəl',
        'Rəbiülaxır',
        'Cəmadiyələvvəl',
        'Cəmadiyəlaxır',
        'Rəcəb',
        'Şaban',
        'Ramazan',
        'Şəvval',
        'Zilqədə',
        'Zilhiccə',
      ],
      'ru': <String>[
        'Мухаррам',
        'Сафар',
        'Раби аль-авваль',
        'Раби ас-сани',
        'Джумада аль-уля',
        'Джумада ас-сания',
        'Раджаб',
        'Шаабан',
        'Рамадан',
        'Шавваль',
        'Зуль-када',
        'Зуль-хиджа',
      ],
    };
    final list = names[languageCode] ?? names['en']!;
    return list[(month - 1).clamp(0, 11)];
  }

  String format(String languageCode) =>
      '$day ${monthName(languageCode)} $year';
}
