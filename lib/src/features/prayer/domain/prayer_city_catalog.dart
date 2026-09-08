import 'prayer_models.dart';

class PrayerCity {
  const PrayerCity({
    required this.id,
    required this.label,
    required this.country,
    required this.group,
    required this.location,
    required this.defaultMethod,
  });

  final String id;
  final String label;
  final String country;
  final String group;
  final PrayerLocation location;
  final PrayerCalculationMethod defaultMethod;

  String get searchText => '$label $country $group'.toLowerCase();
}

const prayerCities = <PrayerCity>[
  // Türkiye
  PrayerCity(
    id: 'istanbul',
    label: 'İstanbul',
    country: 'Türkiye',
    group: 'Türkiye',
    location: PrayerLocation(latitude: 41.0082, longitude: 28.9784, timeZoneId: 'Europe/Istanbul'),
    defaultMethod: PrayerCalculationMethod.turkiye,
  ),
  PrayerCity(
    id: 'ankara',
    label: 'Ankara',
    country: 'Türkiye',
    group: 'Türkiye',
    location: PrayerLocation(latitude: 39.9334, longitude: 32.8597, timeZoneId: 'Europe/Istanbul'),
    defaultMethod: PrayerCalculationMethod.turkiye,
  ),
  PrayerCity(
    id: 'izmir',
    label: 'İzmir',
    country: 'Türkiye',
    group: 'Türkiye',
    location: PrayerLocation(latitude: 38.4237, longitude: 27.1428, timeZoneId: 'Europe/Istanbul'),
    defaultMethod: PrayerCalculationMethod.turkiye,
  ),
  PrayerCity(
    id: 'konya',
    label: 'Konya',
    country: 'Türkiye',
    group: 'Türkiye',
    location: PrayerLocation(latitude: 37.8746, longitude: 32.4932, timeZoneId: 'Europe/Istanbul'),
    defaultMethod: PrayerCalculationMethod.turkiye,
  ),
  PrayerCity(
    id: 'diyarbakir',
    label: 'Diyarbakır',
    country: 'Türkiye',
    group: 'Türkiye',
    location: PrayerLocation(latitude: 37.9144, longitude: 40.2306, timeZoneId: 'Europe/Istanbul'),
    defaultMethod: PrayerCalculationMethod.turkiye,
  ),

  // Hicaz ve Körfez
  PrayerCity(
    id: 'makkah',
    label: 'Mekke',
    country: 'Suudi Arabistan',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 21.3891, longitude: 39.8579, timeZoneId: 'Asia/Riyadh'),
    defaultMethod: PrayerCalculationMethod.ummAlQura,
  ),
  PrayerCity(
    id: 'madinah',
    label: 'Medine',
    country: 'Suudi Arabistan',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 24.4672, longitude: 39.6111, timeZoneId: 'Asia/Riyadh'),
    defaultMethod: PrayerCalculationMethod.ummAlQura,
  ),
  PrayerCity(
    id: 'riyadh',
    label: 'Riyad',
    country: 'Suudi Arabistan',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 24.7136, longitude: 46.6753, timeZoneId: 'Asia/Riyadh'),
    defaultMethod: PrayerCalculationMethod.ummAlQura,
  ),
  PrayerCity(
    id: 'jeddah',
    label: 'Cidde',
    country: 'Suudi Arabistan',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 21.4858, longitude: 39.1925, timeZoneId: 'Asia/Riyadh'),
    defaultMethod: PrayerCalculationMethod.ummAlQura,
  ),
  PrayerCity(
    id: 'dubai',
    label: 'Dubai',
    country: 'Birleşik Arap Emirlikleri',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 25.2048, longitude: 55.2708, timeZoneId: 'Asia/Dubai'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'abu_dhabi',
    label: 'Abu Dabi',
    country: 'Birleşik Arap Emirlikleri',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 24.4539, longitude: 54.3773, timeZoneId: 'Asia/Dubai'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'doha',
    label: 'Doha',
    country: 'Katar',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 25.2854, longitude: 51.5310, timeZoneId: 'Asia/Qatar'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'kuwait_city',
    label: 'Kuveyt',
    country: 'Kuveyt',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 29.3759, longitude: 47.9774, timeZoneId: 'Asia/Kuwait'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'manama',
    label: 'Manama',
    country: 'Bahreyn',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 26.2235, longitude: 50.5876, timeZoneId: 'Asia/Bahrain'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'muscat',
    label: 'Maskat',
    country: 'Umman',
    group: 'Hicaz ve Körfez',
    location: PrayerLocation(latitude: 23.5880, longitude: 58.3829, timeZoneId: 'Asia/Muscat'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),

  // Orta Doğu
  PrayerCity(
    id: 'jerusalem',
    label: 'Kudüs',
    country: 'Filistin',
    group: 'Orta Doğu',
    location: PrayerLocation(latitude: 31.7683, longitude: 35.2137, timeZoneId: 'Asia/Jerusalem'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'amman',
    label: 'Amman',
    country: 'Ürdün',
    group: 'Orta Doğu',
    location: PrayerLocation(latitude: 31.9539, longitude: 35.9106, timeZoneId: 'Asia/Amman'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'damascus',
    label: 'Şam',
    country: 'Suriye',
    group: 'Orta Doğu',
    location: PrayerLocation(latitude: 33.5138, longitude: 36.2765, timeZoneId: 'Asia/Damascus'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'beirut',
    label: 'Beyrut',
    country: 'Lübnan',
    group: 'Orta Doğu',
    location: PrayerLocation(latitude: 33.8938, longitude: 35.5018, timeZoneId: 'Asia/Beirut'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'baghdad',
    label: 'Bağdat',
    country: 'Irak',
    group: 'Orta Doğu',
    location: PrayerLocation(latitude: 33.3152, longitude: 44.3661, timeZoneId: 'Asia/Baghdad'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'erbil',
    label: 'Erbil',
    country: 'Irak',
    group: 'Orta Doğu',
    location: PrayerLocation(latitude: 36.1911, longitude: 44.0092, timeZoneId: 'Asia/Baghdad'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'tehran',
    label: 'Tahran',
    country: 'İran',
    group: 'Orta Doğu',
    location: PrayerLocation(latitude: 35.6892, longitude: 51.3890, timeZoneId: 'Asia/Tehran'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),

  // Güney Asya
  PrayerCity(
    id: 'karachi',
    label: 'Karaçi',
    country: 'Pakistan',
    group: 'Güney Asya',
    location: PrayerLocation(latitude: 24.8607, longitude: 67.0011, timeZoneId: 'Asia/Karachi'),
    defaultMethod: PrayerCalculationMethod.karachi,
  ),
  PrayerCity(
    id: 'lahore',
    label: 'Lahor',
    country: 'Pakistan',
    group: 'Güney Asya',
    location: PrayerLocation(latitude: 31.5204, longitude: 74.3587, timeZoneId: 'Asia/Karachi'),
    defaultMethod: PrayerCalculationMethod.karachi,
  ),
  PrayerCity(
    id: 'islamabad',
    label: 'İslamabad',
    country: 'Pakistan',
    group: 'Güney Asya',
    location: PrayerLocation(latitude: 33.6844, longitude: 73.0479, timeZoneId: 'Asia/Karachi'),
    defaultMethod: PrayerCalculationMethod.karachi,
  ),
  PrayerCity(
    id: 'dhaka',
    label: 'Dakka',
    country: 'Bangladeş',
    group: 'Güney Asya',
    location: PrayerLocation(latitude: 23.8103, longitude: 90.4125, timeZoneId: 'Asia/Dhaka'),
    defaultMethod: PrayerCalculationMethod.karachi,
  ),
  PrayerCity(
    id: 'kabul',
    label: 'Kabil',
    country: 'Afganistan',
    group: 'Güney Asya',
    location: PrayerLocation(latitude: 34.5553, longitude: 69.2075, timeZoneId: 'Asia/Kabul'),
    defaultMethod: PrayerCalculationMethod.karachi,
  ),

  // Güneydoğu Asya
  PrayerCity(
    id: 'jakarta',
    label: 'Cakarta',
    country: 'Endonezya',
    group: 'Güneydoğu Asya',
    location: PrayerLocation(latitude: -6.2088, longitude: 106.8456, timeZoneId: 'Asia/Jakarta'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'surabaya',
    label: 'Surabaya',
    country: 'Endonezya',
    group: 'Güneydoğu Asya',
    location: PrayerLocation(latitude: -7.2575, longitude: 112.7521, timeZoneId: 'Asia/Jakarta'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'kuala_lumpur',
    label: 'Kuala Lumpur',
    country: 'Malezya',
    group: 'Güneydoğu Asya',
    location: PrayerLocation(latitude: 3.1390, longitude: 101.6869, timeZoneId: 'Asia/Kuala_Lumpur'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'bandar_seri_begawan',
    label: 'Bandar Seri Begawan',
    country: 'Brunei',
    group: 'Güneydoğu Asya',
    location: PrayerLocation(latitude: 4.9031, longitude: 114.9398, timeZoneId: 'Asia/Brunei'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),

  // Orta Asya ve Kafkasya
  PrayerCity(
    id: 'baku',
    label: 'Bakü',
    country: 'Azerbaycan',
    group: 'Orta Asya ve Kafkasya',
    location: PrayerLocation(latitude: 40.4093, longitude: 49.8671, timeZoneId: 'Asia/Baku'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'tashkent',
    label: 'Taşkent',
    country: 'Özbekistan',
    group: 'Orta Asya ve Kafkasya',
    location: PrayerLocation(latitude: 41.2995, longitude: 69.2401, timeZoneId: 'Asia/Tashkent'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'almaty',
    label: 'Almatı',
    country: 'Kazakistan',
    group: 'Orta Asya ve Kafkasya',
    location: PrayerLocation(latitude: 43.2389, longitude: 76.8897, timeZoneId: 'Asia/Almaty'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'bishkek',
    label: 'Bişkek',
    country: 'Kırgızistan',
    group: 'Orta Asya ve Kafkasya',
    location: PrayerLocation(latitude: 42.8746, longitude: 74.5698, timeZoneId: 'Asia/Bishkek'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'dushanbe',
    label: 'Duşanbe',
    country: 'Tacikistan',
    group: 'Orta Asya ve Kafkasya',
    location: PrayerLocation(latitude: 38.5598, longitude: 68.7870, timeZoneId: 'Asia/Dushanbe'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),

  // Doğu Asya. Müslüman kullanıcılar için sık ihtiyaç duyulan şehirler öne alındı.
  PrayerCity(
    id: 'urumqi',
    label: 'Urumçi',
    country: 'Çin',
    group: 'Doğu Asya',
    location: PrayerLocation(latitude: 43.8256, longitude: 87.6168, timeZoneId: 'Asia/Shanghai'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'kashgar',
    label: 'Kaşgar',
    country: 'Çin',
    group: 'Doğu Asya',
    location: PrayerLocation(latitude: 39.4704, longitude: 75.9898, timeZoneId: 'Asia/Shanghai'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'beijing',
    label: 'Pekin',
    country: 'Çin',
    group: 'Doğu Asya',
    location: PrayerLocation(latitude: 39.9042, longitude: 116.4074, timeZoneId: 'Asia/Shanghai'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'shanghai',
    label: 'Şanghay',
    country: 'Çin',
    group: 'Doğu Asya',
    location: PrayerLocation(latitude: 31.2304, longitude: 121.4737, timeZoneId: 'Asia/Shanghai'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'guangzhou',
    label: 'Guangzhou',
    country: 'Çin',
    group: 'Doğu Asya',
    location: PrayerLocation(latitude: 23.1291, longitude: 113.2644, timeZoneId: 'Asia/Shanghai'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'hong_kong',
    label: 'Hong Kong',
    country: 'Hong Kong',
    group: 'Doğu Asya',
    location: PrayerLocation(latitude: 22.3193, longitude: 114.1694, timeZoneId: 'Asia/Hong_Kong'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'seoul',
    label: 'Seul',
    country: 'Güney Kore',
    group: 'Doğu Asya',
    location: PrayerLocation(latitude: 37.5665, longitude: 126.9780, timeZoneId: 'Asia/Seoul'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
  PrayerCity(
    id: 'busan',
    label: 'Busan',
    country: 'Güney Kore',
    group: 'Doğu Asya',
    location: PrayerLocation(latitude: 35.1796, longitude: 129.0756, timeZoneId: 'Asia/Seoul'),
    defaultMethod: PrayerCalculationMethod.muslimWorldLeague,
  ),
];

PrayerCity prayerCityById(String? id) {
  if (id == null) return prayerCities.first;
  for (final city in prayerCities) {
    if (city.id == id) return city;
  }
  return prayerCities.first;
}
