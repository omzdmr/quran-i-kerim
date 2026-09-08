import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;

import '../application/prayer_calculator.dart';
import '../application/prayer_preferences_store.dart';
import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';
import 'prayer_city_picker.dart';
import 'prayer_settings_screen.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final PrayerCalculator _calculator = PrayerCalculator();
  Timer? _timer;
  PrayerCity _city = prayerCities.first;
  PrayerSettingsSnapshot _prayerSettings = const PrayerSettingsSnapshot();
  bool _showTomorrow = false;

  @override
  void initState() {
    super.initState();
    _restoreState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _restoreState() async {
    final cityId = await PrayerPreferencesStore.loadCityId();
    final settings = await PrayerPreferencesStore.load();
    if (!mounted) return;
    setState(() {
      _city = prayerCityById(cityId);
      _prayerSettings = settings;
    });
  }

  PrayerDaySchedule _scheduleFor(DateTime localDate) {
    return _calculator.calculate(
      location: _city.location,
      date: localDate,
      preferences: _prayerSettings.preferencesFor(_city.defaultMethod),
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
    final picked = await showModalBottomSheet<PrayerCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => PrayerCityPicker(selectedCityId: _city.id),
    );

    if (picked == null || !mounted) return;
    await PrayerPreferencesStore.saveCityId(picked.id);
    if (!mounted) return;
    setState(() {
      _city = picked;
      _showTomorrow = false;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _openPrayerSettings() async {
    final updated = await Navigator.of(context).push<PrayerSettingsSnapshot>(
      MaterialPageRoute(
        builder: (_) => PrayerSettingsScreen(
          city: _city,
          initial: _prayerSettings,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _prayerSettings = updated);
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
            onPressed: _openPrayerSettings,
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Namaz ayarları',
          ),
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
                          _city.country,
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
                      builder: (_) => MonthlyPrayerTimesScreen(
                        city: _city,
                        settings: _prayerSettings,
                      ),
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
                    'Vakitler cihazda hesaplanır; günlük internet gerekmez. Hesaplama yöntemi, İkindi tercihi, yüksek enlem kuralı ve dakika düzeltmeleri ayarlardan değiştirilebilir.',
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
  const MonthlyPrayerTimesScreen({
    required this.city,
    required this.settings,
    super.key,
  });

  final PrayerCity city;
  final PrayerSettingsSnapshot settings;

  @override
  State<MonthlyPrayerTimesScreen> createState() => _MonthlyPrayerTimesScreenState();
}

class _MonthlyPrayerTimesScreenState extends State<MonthlyPrayerTimesScreen> {
  final PrayerCalculator _calculator = PrayerCalculator();
  late DateTime _month;
  String _filter = 'all';

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
          preferences: widget.settings.preferencesFor(
            widget.city.defaultMethod,
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
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: [
                for (final option in const [
                  ('all', 'Tümü'),
                  ('fajr', 'İmsak'),
                  ('sunrise', 'Güneş'),
                  ('dhuhr', 'Öğle'),
                  ('asr', 'İkindi'),
                  ('maghrib', 'Akşam'),
                  ('isha', 'Yatsı'),
                ]) ...[
                  ChoiceChip(
                    label: Text(option.$2),
                    selected: _filter == option.$1,
                    onSelected: (_) {
                      setState(() => _filter = option.$1);
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(width: 7),
                ],
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
                return _MonthlyDayCard(schedule: schedule, filter: _filter);
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

  final PrayerCity city;
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
  const _MonthlyDayCard({required this.schedule, required this.filter});

  final PrayerDaySchedule schedule;
  final String filter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = filter == 'all'
        ? schedule.rows
        : schedule.rows.where((row) => row.id == filter).toList();
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
