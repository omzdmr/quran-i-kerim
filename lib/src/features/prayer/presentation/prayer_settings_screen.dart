import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../application/prayer_notification_service.dart';
import '../application/prayer_preferences_store.dart';
import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({
    required this.city,
    required this.initial,
    super.key,
  });

  final PrayerCity city;
  final PrayerSettingsSnapshot initial;

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> {
  late PrayerCalculationMethod? _methodOverride;
  late PrayerAsrMethod _asrMethod;
  late PrayerHighLatitudeMethod _highLatitudeMethod;
  late PrayerMinuteAdjustments _adjustments;
  late bool _notificationsEnabled;
  late Set<String> _notificationPrayerIds;
  late int _hijriOffsetDays;
  bool _requestingNotificationPermission = false;

  @override
  void initState() {
    super.initState();
    _methodOverride = widget.initial.methodOverride;
    _asrMethod = widget.initial.asrMethod;
    _highLatitudeMethod = widget.initial.highLatitudeMethod;
    _adjustments = widget.initial.adjustments;
    _notificationsEnabled = widget.initial.notificationsEnabled;
    _notificationPrayerIds = {...widget.initial.notificationPrayerIds};
    _hijriOffsetDays = widget.initial.hijriOffsetDays;
  }

  PrayerSettingsSnapshot get _snapshot => PrayerSettingsSnapshot(
    methodOverride: _methodOverride,
    asrMethod: _asrMethod,
    highLatitudeMethod: _highLatitudeMethod,
    adjustments: _adjustments,
    notificationsEnabled: _notificationsEnabled,
    notificationPrayerIds: _notificationPrayerIds,
    hijriOffsetDays: _hijriOffsetDays,
  );

  Future<void> _save() async {
    final snapshot = _snapshot;
    await PrayerPreferencesStore.save(snapshot);
    if (snapshot.notificationsEnabled) {
      await PrayerNotificationService.reschedule(
        location: widget.city.location,
        defaultMethod: widget.city.defaultMethod,
        settings: snapshot,
      );
    } else {
      await PrayerNotificationService.cancelAll();
    }
    if (!mounted) return;
    HapticFeedback.lightImpact();
    Navigator.pop(context, snapshot);
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    if (!enabled) {
      setState(() => _notificationsEnabled = false);
      return;
    }
    if (_requestingNotificationPermission) return;
    setState(() => _requestingNotificationPermission = true);
    final granted = await PrayerNotificationService.requestPermissions();
    if (!mounted) return;
    setState(() {
      _requestingNotificationPermission = false;
      _notificationsEnabled = granted;
    });
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.text('notificationPermissionDenied')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('prayerSettings')),
        actions: [
          TextButton(onPressed: _save, child: Text(l10n.save)),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          _SectionCard(
            title: l10n.text('calculationMethod'),
            subtitle: l10n.text('calculationMethodInfo'),
            child: DropdownButtonFormField<PrayerCalculationMethod?>(
              initialValue: _methodOverride,
              decoration: InputDecoration(
                labelText: l10n.text('method'),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<PrayerCalculationMethod?>(
                  value: null,
                  child: Text(
                    '${l10n.text('automatic')} · ${_methodLabel(context, widget.city.defaultMethod)}',
                  ),
                ),
                for (final method in PrayerCalculationMethod.values)
                  DropdownMenuItem<PrayerCalculationMethod?>(
                    value: method,
                    child: Text(_methodLabel(context, method)),
                  ),
              ],
              onChanged: (value) {
                setState(() => _methodOverride = value);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.text('prayerNotifications'),
            subtitle: l10n.text('prayerNotificationsInfo'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.text('prayerNotifications'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  value: _notificationsEnabled,
                  onChanged: _requestingNotificationPermission
                      ? null
                      : _setNotificationsEnabled,
                  secondary: _requestingNotificationPermission
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.notifications_active_outlined),
                ),
                if (_notificationsEnabled) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in const [
                        'fajr',
                        'dhuhr',
                        'asr',
                        'maghrib',
                        'isha',
                      ])
                        FilterChip(
                          label: Text(_prayerLabel(context, id)),
                          selected: _notificationPrayerIds.contains(id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _notificationPrayerIds.add(id);
                              } else {
                                _notificationPrayerIds.remove(id);
                              }
                            });
                            HapticFeedback.selectionClick();
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.text('hijriDateOffset'),
            subtitle: l10n.text('hijriDateOffsetInfo'),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _hijriOffsetDays <= -2
                      ? null
                      : () {
                          setState(() => _hijriOffsetDays--);
                          HapticFeedback.selectionClick();
                        },
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    _hijriOffsetDays == 0
                        ? '0 ${l10n.text('daysUnit')}'
                        : '${_hijriOffsetDays > 0 ? '+' : ''}$_hijriOffsetDays ${l10n.text('daysUnit')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _hijriOffsetDays >= 2
                      ? null
                      : () {
                          setState(() => _hijriOffsetDays++);
                          HapticFeedback.selectionClick();
                        },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.text('asrCalculation'),
            subtitle: l10n.text('asrCalculationInfo'),
            child: SegmentedButton<PrayerAsrMethod>(
              segments: [
                ButtonSegment(
                  value: PrayerAsrMethod.standard,
                  label: Text(l10n.text('standard')),
                ),
                ButtonSegment(
                  value: PrayerAsrMethod.hanafi,
                  label: Text(l10n.text('hanafi')),
                ),
              ],
              selected: {_asrMethod},
              onSelectionChanged: (value) {
                setState(() => _asrMethod = value.first);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.text('highLatitude'),
            subtitle: l10n.text('highLatitudeInfo'),
            child: DropdownButtonFormField<PrayerHighLatitudeMethod>(
              initialValue: _highLatitudeMethod,
              decoration: InputDecoration(
                labelText: l10n.text('rule'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in PrayerHighLatitudeMethod.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_highLatitudeLabel(context, value)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _highLatitudeMethod = value);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.text('minuteAdjustments'),
            subtitle: l10n.text('minuteAdjustmentsInfo'),
            child: Column(
              children: [
                _AdjustmentRow(
                  label: l10n.text('fajr'),
                  value: _adjustments.fajr,
                  onChanged: (value) => _setAdjustment(fajr: value),
                ),
                _AdjustmentRow(
                  label: l10n.text('sunrise'),
                  value: _adjustments.sunrise,
                  onChanged: (value) => _setAdjustment(sunrise: value),
                ),
                _AdjustmentRow(
                  label: l10n.text('dhuhr'),
                  value: _adjustments.dhuhr,
                  onChanged: (value) => _setAdjustment(dhuhr: value),
                ),
                _AdjustmentRow(
                  label: l10n.text('asr'),
                  value: _adjustments.asr,
                  onChanged: (value) => _setAdjustment(asr: value),
                ),
                _AdjustmentRow(
                  label: l10n.text('maghrib'),
                  value: _adjustments.maghrib,
                  onChanged: (value) => _setAdjustment(maghrib: value),
                ),
                _AdjustmentRow(
                  label: l10n.text('isha'),
                  value: _adjustments.isha,
                  onChanged: (value) => _setAdjustment(isha: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.text('prayerSettingsInfo'),
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  void _setAdjustment({
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    setState(() {
      _adjustments = PrayerMinuteAdjustments(
        fajr: fajr ?? _adjustments.fajr,
        sunrise: sunrise ?? _adjustments.sunrise,
        dhuhr: dhuhr ?? _adjustments.dhuhr,
        asr: asr ?? _adjustments.asr,
        maghrib: maghrib ?? _adjustments.maghrib,
        isha: isha ?? _adjustments.isha,
      );
    });
    HapticFeedback.selectionClick();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  const _AdjustmentRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value <= -30 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_rounded),
          tooltip: l10n.text('decreaseMinute'),
        ),
        SizedBox(
          width: 62,
          child: Text(
            value == 0
                ? '0 ${l10n.text('minuteUnit')}'
                : '${value > 0 ? '+' : ''}$value ${l10n.text('minuteUnit')}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value >= 30 ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_rounded),
          tooltip: l10n.text('increaseMinute'),
        ),
      ],
    );
  }
}

String _prayerLabel(BuildContext context, String id) {
  final l10n = context.l10n;
  return switch (id) {
    'fajr' => l10n.text('fajr'),
    'dhuhr' => l10n.text('dhuhr'),
    'asr' => l10n.text('asr'),
    'maghrib' => l10n.text('maghrib'),
    'isha' => l10n.text('isha'),
    _ => id,
  };
}

String _methodLabel(BuildContext context, PrayerCalculationMethod method) {
  final l10n = context.l10n;
  return switch (method) {
    PrayerCalculationMethod.turkiye => l10n.text('turkiyeMethod'),
    PrayerCalculationMethod.muslimWorldLeague => l10n.text('mwlMethod'),
    PrayerCalculationMethod.ummAlQura => l10n.text('ummAlQuraMethod'),
    PrayerCalculationMethod.egyptian => l10n.text('egyptianMethod'),
    PrayerCalculationMethod.karachi => l10n.text('karachiMethod'),
    PrayerCalculationMethod.northAmerica => l10n.text('northAmericaMethod'),
    PrayerCalculationMethod.moonsightingCommittee => l10n.text(
      'moonsightingMethod',
    ),
  };
}

String _highLatitudeLabel(
  BuildContext context,
  PrayerHighLatitudeMethod value,
) {
  final l10n = context.l10n;
  return switch (value) {
    PrayerHighLatitudeMethod.recommended => l10n.text('recommended'),
    PrayerHighLatitudeMethod.middleOfTheNight => l10n.text('middleOfNight'),
    PrayerHighLatitudeMethod.seventhOfTheNight => l10n.text('seventhOfNight'),
    PrayerHighLatitudeMethod.twilightAngle => l10n.text('twilightAngle'),
  };
}
