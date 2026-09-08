import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../prayer/application/prayer_calculator.dart';
import '../prayer/application/prayer_preferences_store.dart';
import '../prayer/domain/prayer_city_catalog.dart';
import '../prayer/domain/prayer_models.dart';
import '../prayer/presentation/prayer_screen.dart';

class HomePrayerCard extends StatefulWidget {
  const HomePrayerCard({super.key});

  @override
  State<HomePrayerCard> createState() => _HomePrayerCardState();
}

class _HomePrayerCardState extends State<HomePrayerCard> {
  final PrayerCalculator _calculator = PrayerCalculator();
  Timer? _timer;
  PrayerCity? _city;
  PrayerSettingsSnapshot _settings = const PrayerSettingsSnapshot();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _city != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final cityId = await PrayerPreferencesStore.loadCityId();
    final settings = await PrayerPreferencesStore.load();
    if (!mounted) return;
    setState(() {
      _city = prayerCityById(cityId);
      _settings = settings;
    });
  }

  PrayerDaySchedule _scheduleFor(PrayerCity city, DateTime date) {
    return _calculator.calculate(
      location: city.location,
      date: date,
      preferences: _settings.preferencesFor(city.defaultMethod),
    );
  }

  ({String label, DateTime time}) _nextPrayer(PrayerCity city) {
    final zone = tz.getLocation(city.location.timeZoneId);
    final now = tz.TZDateTime.now(zone);
    final today = _scheduleFor(city, now);
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
    final tomorrow = _scheduleFor(city, now.add(const Duration(days: 1)));
    return (label: 'İmsak', time: tomorrow.fajr);
  }

  @override
  Widget build(BuildContext context) {
    final city = _city;
    if (city == null) {
      return const SizedBox(
        height: 112,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final zone = tz.getLocation(city.location.timeZoneId);
    final now = tz.TZDateTime.now(zone);
    final next = _nextPrayer(city);
    final remaining = next.time.difference(now);

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const PrayerScreen()),
          );
          if (mounted) _load();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sıradaki · ${next.label}',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_clock(next.time)} · ${_remaining(remaining)} kaldı',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${city.label} · Namaz vakitlerini aç',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

String _clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _remaining(Duration raw) {
  final duration = raw.isNegative ? Duration.zero : raw;
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours <= 0) return '$minutes dk';
  return '$hours sa ${minutes.toString().padLeft(2, '0')} dk';
}
