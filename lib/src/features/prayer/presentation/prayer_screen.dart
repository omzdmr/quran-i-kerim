import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../l10n/app_localizations.dart';
import '../application/prayer_calculator.dart';
import '../application/prayer_calendar_export.dart';
import '../application/prayer_location_service.dart';
import '../application/prayer_notification_service.dart';
import '../application/prayer_preferences_store.dart';
import '../application/prayer_region_resolver.dart';
import '../domain/hijri_date.dart';
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
  bool _usingDeviceLocation = false;
  bool _locating = false;

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

    if (cityId == PrayerPreferencesStore.deviceLocationId) {
      final savedDevice = await PrayerPreferencesStore.loadDeviceLocation();
      if (!mounted) return;
      if (savedDevice != null) {
        setState(() {
          _city = _cityFromDevice(savedDevice);
          _usingDeviceLocation = true;
          _prayerSettings = settings;
        });
        return;
      }
    }

    if (cityId == PrayerPreferencesStore.manualLocationId) {
      final savedManual = await PrayerPreferencesStore.loadManualLocation();
      if (!mounted) return;
      if (savedManual != null) {
        setState(() {
          _city = _cityFromManual(savedManual);
          _usingDeviceLocation = false;
          _prayerSettings = settings;
        });
        return;
      }
    }

    setState(() {
      _city = prayerCityById(cityId);
      _usingDeviceLocation = false;
      _prayerSettings = settings;
    });
    if (cityId == null) {
      unawaited(_useCurrentLocation(preferCached: true));
    }
  }

  PrayerCity _cityFromDevice(PrayerDeviceLocationSnapshot value) => PrayerCity(
    id: PrayerPreferencesStore.deviceLocationId,
    label: 'GPS',
    country: '',
    group: value.regionCode,
    location: value.location,
    defaultMethod: value.defaultMethod,
  );

  PrayerCity _cityFromManual(PrayerManualLocationSnapshot value) => PrayerCity(
    id: value.sourceId,
    label: value.label,
    country: value.country,
    group: value.regionCode,
    location: value.location,
    defaultMethod: value.defaultMethod,
  );

  Future<void> _useCurrentLocation({
    bool silent = false,
    bool preferCached = false,
  }) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final result = await PrayerLocationService.current(
        preferCached: preferCached,
      );
      final saved = PrayerDeviceLocationSnapshot(
        location: result.location,
        defaultMethod: result.defaultMethod,
        regionCode: result.regionCode,
      );
      await PrayerPreferencesStore.saveDeviceLocation(saved);
      if (!mounted) return;
      setState(() {
        _city = _cityFromDevice(saved);
        _usingDeviceLocation = true;
        _showTomorrow = false;
      });
      await _refreshNotificationsForCurrentLocation();
      if (!mounted) return;
      HapticFeedback.selectionClick();
    } on PrayerLocationException catch (error) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_locationFailureMessage(error.failure))),
      );
    } catch (_) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('locationFailed'))),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String _locationFailureMessage(PrayerLocationFailure failure) {
    final l10n = context.l10n;
    return switch (failure) {
      PrayerLocationFailure.serviceDisabled => l10n.text(
        'locationServicesDisabled',
      ),
      PrayerLocationFailure.permissionDenied ||
      PrayerLocationFailure.permissionDeniedForever => l10n.text(
        'locationPermissionDenied',
      ),
      PrayerLocationFailure.unavailable => l10n.text('locationFailed'),
    };
  }

  Future<void> _refreshNotificationsForCurrentLocation() async {
    if (!_prayerSettings.notificationsEnabled) return;
    await PrayerNotificationService.reschedule(
      location: _city.location,
      defaultMethod: _city.defaultMethod,
      settings: _prayerSettings,
    );
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

  ({String id, DateTime time}) _nextPrayer() {
    final now = _now;
    final today = _scheduleFor(now);
    final candidates = [
      (id: 'fajr', time: today.fajr),
      (id: 'dhuhr', time: today.dhuhr),
      (id: 'asr', time: today.asr),
      (id: 'maghrib', time: today.maghrib),
      (id: 'isha', time: today.isha),
    ];
    for (final candidate in candidates) {
      if (candidate.time.isAfter(now)) return candidate;
    }
    final tomorrow = _scheduleFor(now.add(const Duration(days: 1)));
    return (id: 'fajr', time: tomorrow.fajr);
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<PrayerCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => PrayerCityPicker(
        selectedCityId: _usingDeviceLocation ? null : _city.id,
        onUseCurrentLocation: () => _useCurrentLocation(preferCached: true),
      ),
    );

    if (picked == null || !mounted) return;
    final isPriority = prayerCities.any((city) => city.id == picked.id);
    if (isPriority) {
      await PrayerPreferencesStore.saveCityId(picked.id);
    } else {
      final region = resolvePrayerRegion(
        picked.location.latitude,
        picked.location.longitude,
      );
      await PrayerPreferencesStore.saveManualLocation(
        PrayerManualLocationSnapshot(
          sourceId: picked.id,
          label: picked.label,
          country: picked.country,
          location: picked.location,
          defaultMethod: picked.defaultMethod,
          regionCode: region.regionCode,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _city = picked;
      _usingDeviceLocation = false;
      _showTomorrow = false;
    });
    await _refreshNotificationsForCurrentLocation();
    if (!mounted) return;
    HapticFeedback.selectionClick();
  }

  Future<void> _openPrayerSettings() async {
    final updated = await Navigator.of(context).push<PrayerSettingsSnapshot>(
      MaterialPageRoute(
        builder: (_) =>
            PrayerSettingsScreen(city: _city, initial: _prayerSettings),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _prayerSettings = updated);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final schedule = _shownSchedule;
    final next = _nextPrayer();
    final remaining = next.time.difference(_now);
    final hijri = PrayerHijriDate.fromGregorian(
      _now,
      offsetDays: _prayerSettings.hijriOffsetDays,
    );
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.prayerTimes),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _locating ? null : () => _useCurrentLocation(),
            icon: _locating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.my_location_rounded),
            tooltip: l10n.text('useCurrentLocation'),
          ),
          IconButton(
            onPressed: _openPrayerSettings,
            icon: const Icon(Icons.tune_rounded),
            tooltip: l10n.text('prayerSettings'),
          ),
          IconButton(
            onPressed: _pickCity,
            icon: const Icon(Icons.location_on_outlined),
            tooltip: l10n.text('chooseCity'),
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
                          _usingDeviceLocation
                              ? l10n.text('currentLocation')
                              : _city.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _usingDeviceLocation
                              ? '${_city.location.latitude.toStringAsFixed(3)}, ${_city.location.longitude.toStringAsFixed(3)} · ${_city.location.timeZoneId}'
                              : _city.country,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                hijri.format(languageCode),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                l10n.text('hijriDate'),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  '${l10n.text('nextPrayer')} · ${_prayerLabel(context, next.id)}',
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
                  '${_countdown(remaining)} ${l10n.text('remaining')}',
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
                  title: l10n.text('qibla'),
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
                  title: l10n.text('monthlyTimes'),
                  subtitle: MaterialLocalizations.of(
                    context,
                  ).formatMonthYear(_now),
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
            segments: [
              ButtonSegment(value: false, label: Text(l10n.today)),
              ButtonSegment(value: true, label: Text(l10n.text('tomorrow'))),
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
              label: _prayerLabel(context, row.id),
              time: _clock(row.time),
              active: !_showTomorrow && row.id == next.id,
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
                    l10n.text('prayerOfflineInfo'),
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
  State<MonthlyPrayerTimesScreen> createState() =>
      _MonthlyPrayerTimesScreenState();
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

  List<PrayerDaySchedule> _schedulesForMonth() {
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    return [
      for (var day = 1; day <= days; day++)
        _calculator.calculate(
          location: widget.city.location,
          date: DateTime(_month.year, _month.month, day),
          preferences: widget.settings.preferencesFor(
            widget.city.defaultMethod,
          ),
        ),
    ];
  }

  Future<void> _exportMonth() async {
    final l10n = context.l10n;
    try {
      final file = await const PrayerCalendarExportFileService().createFile(
        schedules: _schedulesForMonth(),
        timeZoneId: widget.city.location.timeZoneId,
        calendarName:
            '${l10n.text('monthlyPrayerTimes')} · ${widget.city.label}',
        calendarId: widget.city.id,
        prayerLabel: (id) => _prayerLabel(context, id),
        month: _month,
      );
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'text/calendar')],
          title: l10n.text('exportPrayerCalendar'),
          text: l10n.text('prayerCalendarShareText'),
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.text('prayerCalendarExportFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schedules = _schedulesForMonth();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('monthlyPrayerTimes')),
        actions: [
          IconButton(
            onPressed: _exportMonth,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: l10n.text('exportPrayerCalendarHint'),
          ),
        ],
      ),
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
                        MaterialLocalizations.of(
                          context,
                        ).formatMonthYear(_month),
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
                  'all',
                  'fajr',
                  'sunrise',
                  'dhuhr',
                  'asr',
                  'maghrib',
                  'isha',
                ]) ...[
                  ChoiceChip(
                    label: Text(
                      option == 'all'
                          ? l10n.text('all')
                          : _prayerLabel(context, option),
                    ),
                    selected: _filter == option,
                    onSelected: (_) {
                      setState(() => _filter = option);
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

class QiblaInfoScreen extends StatefulWidget {
  const QiblaInfoScreen({
    required this.city,
    required this.qiblaDegrees,
    super.key,
  });

  final PrayerCity city;
  final double qiblaDegrees;

  @override
  State<QiblaInfoScreen> createState() => _QiblaInfoScreenState();
}

class _QiblaInfoScreenState extends State<QiblaInfoScreen> {
  bool _wasAligned = false;

  void _handleAlignment(bool aligned) {
    if (aligned && !_wasAligned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) HapticFeedback.mediumImpact();
      });
    }
    _wasAligned = aligned;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('qibla'))),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          final heading = snapshot.data?.heading;
          final rawDelta = heading == null
              ? widget.qiblaDegrees
              : (widget.qiblaDegrees - heading + 360) % 360;
          final signedDelta = rawDelta > 180 ? rawDelta - 360 : rawDelta;
          final aligned = heading != null && signedDelta.abs() <= 5;
          _handleAlignment(aligned);
          final angle = rawDelta * math.pi / 180;
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            children: [
              Text(
                widget.city.id == PrayerPreferencesStore.deviceLocationId
                    ? l10n.text('currentLocation')
                    : widget.city.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                heading == null
                    ? l10n.text('compassUnavailable')
                    : aligned
                    ? l10n.text('qiblaAligned')
                    : l10n.text('pointTopToKaaba'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: aligned ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Container(
                  width: 268,
                  height: 268,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainer,
                    border: Border.all(
                      color: aligned ? scheme.primary : scheme.outlineVariant,
                      width: aligned ? 2.4 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned(
                        top: 13,
                        child: Text(
                          'N',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Positioned(
                        top: 42,
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 34,
                          color: aligned ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                      Transform.rotate(
                        angle: angle,
                        child: SizedBox(
                          width: 232,
                          height: 232,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Transform.rotate(
                              angle: -angle,
                              child: const _KaabaMarker(),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                heading == null
                    ? '${widget.qiblaDegrees.round()}°'
                    : '${signedDelta.abs().round()}°',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                heading == null
                    ? l10n.text('qiblaNorthDescription')
                    : aligned
                    ? l10n.text('qiblaAligned')
                    : l10n.text('liveQibla'),
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
                child: Text(
                  l10n.text('qiblaCalibrationInfo'),
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KaabaMarker extends StatelessWidget {
  const _KaabaMarker();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFF171717),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: const Color(0xFFB99A45), width: 1.2),
      boxShadow: const [
        BoxShadow(
          blurRadius: 7,
          offset: Offset(0, 2),
          color: Color(0x33000000),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 10,
          child: Container(height: 5, color: const Color(0xFFC9A94E)),
        ),
        Positioned(
          right: 7,
          bottom: 5,
          child: Container(
            width: 8,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFFB68C32),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    ),
  );
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
            textDirection: TextDirection.ltr,
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
            MaterialLocalizations.of(
              context,
            ).formatMediumDate(schedule.localDate),
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
                        _prayerLabel(context, row.id),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _clock(row.time),
                        textDirection: TextDirection.ltr,
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

String _prayerLabel(BuildContext context, String id) {
  final l10n = context.l10n;
  return switch (id) {
    'fajr' => l10n.text('fajr'),
    'sunrise' => l10n.text('sunrise'),
    'dhuhr' => l10n.text('dhuhr'),
    'asr' => l10n.text('asr'),
    'maghrib' => l10n.text('maghrib'),
    'isha' => l10n.text('isha'),
    _ => id,
  };
}

String _clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _countdown(Duration raw) {
  final duration = raw.isNegative ? Duration.zero : raw;
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
