import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../application/prayer_calculator.dart';
import '../domain/prayer_models.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  static const _cityKey = 'prayer_city_id';

  final PrayerCalculator _calculator = PrayerCalculator();
  Timer? _timer;
  _PrayerCity _city = _prayerCities.first;
  bool _showTomorrow = false;

  @override
  void initState() {
    super.initState();
    _restoreCity();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _restoreCity() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_cityKey);
    if (!mounted || saved == null) return;
    final matches = _prayerCities.where((city) => city.id == saved);
    if (matches.isEmpty) return;
    setState(() => _city = matches.first);
  }

  PrayerDaySchedule _scheduleFor(DateTime localDate) {
    return _calculator.calculate(
      location: _city.location,
      date: localDate,
      preferences: PrayerPreferences(calculationMethod: _city.method),
    );
  }

  tz.TZDateTime get _now {
    final zone = tz.getLocation(_city.location.timeZoneId);
    return tz.TZDateTime.now(zone);
  }

  PrayerDaySchedule get _shownSchedule {
    final now = _now;
    final date = _showTomorrow ? now.add(const Duration(days: 1)) : now;
    return _scheduleFor(date);
  }

  ({String label, DateTime time}) _nextPrayer() {
    final now = _now;
    final today = _scheduleFor(now);
    final candidates = [
      (label: 'İmsak', time: today.fajr),
      (label: 'Öğle', time: today.dhuhr),
      (label: 'İkindi', time: today.asr),
      (label: 'Akşam', time: today.maghrib),
      (label: 'Yatsı', time: today.isha),
    ];
    for (final candidate in candidates) {
      if (candidate.time.isAfter(now)) return candidate;
    }
    final tomorrow = _scheduleFor(now.add(const Duration(days: 1)));
    return (label: 'İmsak', time: tomorrow.fajr);
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<_PrayerCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .82,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Şehir seç',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  itemCount: _prayerCities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final city = _prayerCities[index];
                    final selected = city.id == _city.id;
                    return Material(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        onTap: () => Navigator.pop(sheetContext, city),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        leading: Icon(
                          selected
                              ? Icons.location_on_rounded
                              : Icons.location_on_outlined,
                        ),
                        title: Text(
                          city.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(city.region),
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded)
                            : const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, picked.id);
    if (!mounted) return;
    setState(() {
      _city = picked;
      _showTomorrow = false;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final schedule = _shownSchedule;
    final next = _nextPrayer();
    final remaining = next.time.difference(_now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Vakitleri'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _pickCity,
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Şehir seç',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          InkWell(
            onTap: _pickCity,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.near_me_outlined, color: scheme.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _city.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _city.region,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sıradaki · ${next.label}',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _clock(next.time),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_countdown(remaining)} kaldı',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PrayerShortcut(
                  icon: Icons.explore_outlined,
                  title: 'Kıble',
                  subtitle: '${schedule.qiblaDegrees.round()}°',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QiblaInfoScreen(
                        city: _city,
                        qiblaDegrees: schedule.qiblaDegrees,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrayerShortcut(
                  icon: Icons.calendar_month_outlined,
                  title: 'Aylık vakitler',
                  subtitle: _monthYear(_now),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MonthlyPrayerTimesScreen(city: _city),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Bugün')),
              ButtonSegment(value: true, label: Text('Yarın')),
            ],
            selected: {_showTomorrow},
            onSelectionChanged: (value) {
              setState(() => _showTomorrow = value.first);
              HapticFeedback.selectionClick();
            },
          ),
          const SizedBox(height: 14),
          for (final row in schedule.rows)
            _PrayerTimeRow(
              label: row.label,
              time: _clock(row.time),
              active: !_showTomorrow && row.label == next.label,
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vakitler cihazda hesaplanır; günlük internet bağlantısı gerekmez. Şehir ve hesaplama yöntemi sonraki ayarlarda daha ayrıntılı özelleştirilecek.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyPrayerTimesScreen extends StatefulWidget {
  const MonthlyPrayerTimesScreen({required this.city, super.key});

  final _PrayerCity city;

  @override
  State<MonthlyPrayerTimesScreen> createState() => _MonthlyPrayerTimesScreenState();
}

class _MonthlyPrayerTimesScreenState extends State<MonthlyPrayerTimesScreen> {
  final PrayerCalculator _calculator = PrayerCalculator();
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final zone = tz.getLocation(widget.city.location.timeZoneId);
    final now = tz.TZDateTime.now(zone);
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final schedules = [
      for (var day = 1; day <= days; day++)
        _calculator.calculate(
          location: widget.city.location,
          date: DateTime(_month.year, _month.month, day),
          preferences: PrayerPreferences(
            calculationMethod: widget.city.method,
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Aylık Namaz Vakitleri')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month - 1);
                  }),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _monthYear(_month),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        widget.city.label,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month + 1);
                  }),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
              itemCount: schedules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return _MonthlyDayCard(schedule: schedule);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QiblaInfoScreen extends StatelessWidget {
  const QiblaInfoScreen({
    required this.city,
    required this.qiblaDegrees,
    super.key,
  });

  final _PrayerCity city;
  final double qiblaDegrees;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final angle = qiblaDegrees * math.pi / 180;
    return Scaffold(
      appBar: AppBar(title: const Text('Kıble')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
        children: [
          Text(
            city.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 26),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainer,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(top: 15, child: Text('K', style: TextStyle(fontWeight: FontWeight.w900))),
                  Transform.rotate(
                    angle: angle,
                    child: Icon(
                      Icons.navigation_rounded,
                      size: 118,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${qiblaDegrees.round()}°',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
          ),
          Text(
            'Kuzeye göre Kıble yönü',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'Telefonu düz tutun. Pusulayı kullanmadan önce cihazı 8 şekli çizerek kalibre etmek faydalıdır. Mıknatıslı kılıflar, metal yüzeyler ve elektronik cihazlar pusulayı etkileyebilir. Canlı sensör hizalaması sonraki adımda eklenecek.',
              style: TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerTimeRow extends StatelessWidget {
  const _PrayerTimeRow({
    required this.label,
    required this.time,
    required this.active,
  });

  final String label;
  final String time;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          if (active) ...[
            Icon(Icons.brightness_1_rounded, size: 9, color: scheme.primary),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PrayerShortcut extends StatelessWidget {
  const _PrayerShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyDayCard extends StatelessWidget {
  const _MonthlyDayCard({required this.schedule});

  final PrayerDaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = schedule.rows;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${schedule.localDate.day} ${_months[schedule.localDate.month - 1]}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final row in rows)
                SizedBox(
                  width: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _clock(row.time),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerCity {
  const _PrayerCity({
    required this.id,
    required this.label,
    required this.region,
    required this.location,
    required this.method,
  });

  final String id;
  final String label;
  final String region;
  final PrayerLocation location;
  final PrayerCalculationMethod method;
}

const _prayerCities = <_PrayerCity>[
  _PrayerCity(
    id: 'istanbul',
    label: 'İstanbul',
    region: 'Türkiye',
    location: PrayerLocation(
      latitude: 41.0082,
      longitude: 28.9784,
      timeZoneId: 'Europe/Istanbul',
    ),
    method: PrayerCalculationMethod.turkiye,
  ),
  _PrayerCity(
    id: 'ankara',
    label: 'Ankara',
    region: 'Türkiye',
    location: PrayerLocation(
      latitude: 39.9334,
      longitude: 32.8597,
      timeZoneId: 'Europe/Istanbul',
    ),
    method: PrayerCalculationMethod.turkiye,
  ),
  _PrayerCity(
    id: 'izmir',
    label: 'İzmir',
    region: 'Türkiye',
    location: PrayerLocation(
      latitude: 38.4237,
      longitude: 27.1428,
      timeZoneId: 'Europe/Istanbul',
    ),
    method: PrayerCalculationMethod.turkiye,
  ),
  _PrayerCity(
    id: 'beijing',
    label: 'Pekin',
    region: 'Çin',
    location: PrayerLocation(
      latitude: 39.9042,
      longitude: 116.4074,
      timeZoneId: 'Asia/Shanghai',
    ),
    method: PrayerCalculationMethod.muslimWorldLeague,
  ),
  _PrayerCity(
    id: 'shanghai',
    label: 'Şanghay',
    region: 'Çin',
    location: PrayerLocation(
      latitude: 31.2304,
      longitude: 121.4737,
      timeZoneId: 'Asia/Shanghai',
    ),
    method: PrayerCalculationMethod.muslimWorldLeague,
  ),
  _PrayerCity(
    id: 'guangzhou',
    label: 'Guangzhou',
    region: 'Çin',
    location: PrayerLocation(
      latitude: 23.1291,
      longitude: 113.2644,
      timeZoneId: 'Asia/Shanghai',
    ),
    method: PrayerCalculationMethod.muslimWorldLeague,
  ),
  _PrayerCity(
    id: 'hong_kong',
    label: 'Hong Kong',
    region: 'Hong Kong',
    location: PrayerLocation(
      latitude: 22.3193,
      longitude: 114.1694,
      timeZoneId: 'Asia/Hong_Kong',
    ),
    method: PrayerCalculationMethod.muslimWorldLeague,
  ),
  _PrayerCity(
    id: 'seoul',
    label: 'Seul',
    region: 'Güney Kore',
    location: PrayerLocation(
      latitude: 37.5665,
      longitude: 126.9780,
      timeZoneId: 'Asia/Seoul',
    ),
    method: PrayerCalculationMethod.muslimWorldLeague,
  ),
  _PrayerCity(
    id: 'busan',
    label: 'Busan',
    region: 'Güney Kore',
    location: PrayerLocation(
      latitude: 35.1796,
      longitude: 129.0756,
      timeZoneId: 'Asia/Seoul',
    ),
    method: PrayerCalculationMethod.muslimWorldLeague,
  ),
];

const _months = <String>[
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String _clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _monthYear(DateTime date) => '${_months[date.month - 1]} ${date.year}';

String _countdown(Duration raw) {
  final duration = raw.isNegative ? Duration.zero : raw;
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
