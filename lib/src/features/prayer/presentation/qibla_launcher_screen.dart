import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../application/prayer_calculator.dart';
import '../application/prayer_location_service.dart';
import '../application/prayer_preferences_store.dart';
import '../application/prayer_region_resolver.dart';
import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';
import 'prayer_city_picker.dart';
import 'prayer_screen.dart';

class QiblaLauncherScreen extends StatefulWidget {
  const QiblaLauncherScreen({super.key});

  @override
  State<QiblaLauncherScreen> createState() => _QiblaLauncherScreenState();
}

class _QiblaLauncherScreenState extends State<QiblaLauncherScreen> {
  final PrayerCalculator _calculator = PrayerCalculator();
  PrayerCity? _city;
  PrayerLocationFailure? _failure;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
  }

  Future<void> _useCurrentLocation() async {
    if (_loading && _city != null) return;
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final result = await PrayerLocationService.current(preferCached: true);
      final saved = PrayerDeviceLocationSnapshot(
        location: result.location,
        defaultMethod: result.defaultMethod,
        regionCode: result.regionCode,
      );
      await PrayerPreferencesStore.saveDeviceLocation(saved);
      if (!mounted) return;
      setState(() {
        _city = _cityFromDevice(saved);
        _loading = false;
      });
      HapticFeedback.selectionClick();
    } on PrayerLocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = error.failure;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failure = PrayerLocationFailure.unavailable;
        _loading = false;
      });
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

  Future<void> _pickManual() async {
    final picked = await showModalBottomSheet<PrayerCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => PrayerCityPicker(
        selectedCityId: _city?.id,
        onUseCurrentLocation: _useCurrentLocation,
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
      _failure = null;
      _loading = false;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final city = _city;
    if (city != null) {
      final schedule = _calculator.calculate(
        location: city.location,
        date: DateTime.now(),
        preferences: PrayerPreferences(
          calculationMethod: city.defaultMethod,
        ),
      );
      return QiblaInfoScreen(
        city: city,
        qiblaDegrees: schedule.qiblaDegrees,
      );
    }

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('qibla'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _loading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 18),
                    Text(
                      l10n.text('qiblaLocationPrompt'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.explore_rounded,
                      size: 62,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.text('qiblaLocationPrompt'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _failureMessage(context, _failure),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: const Icon(Icons.my_location_rounded),
                        label: Text(l10n.text('useCurrentLocation')),
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickManual,
                        icon: const Icon(Icons.location_on_outlined),
                        label: Text(l10n.text('chooseManually')),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _failureMessage(
    BuildContext context,
    PrayerLocationFailure? failure,
  ) {
    final l10n = context.l10n;
    return switch (failure) {
      PrayerLocationFailure.serviceDisabled =>
        l10n.text('locationServicesDisabled'),
      PrayerLocationFailure.permissionDenied ||
      PrayerLocationFailure.permissionDeniedForever =>
        l10n.text('locationPermissionDenied'),
      PrayerLocationFailure.unavailable => l10n.text('locationFailed'),
      null => l10n.text('qiblaLocationPromptBody'),
    };
  }
}
