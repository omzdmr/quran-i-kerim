import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/prayer_models.dart';
import 'prayer_region_resolver.dart';

enum PrayerLocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class PrayerLocationException implements Exception {
  const PrayerLocationException(this.failure);

  final PrayerLocationFailure failure;
}

class PrayerDeviceLocationResult {
  const PrayerDeviceLocationResult({
    required this.location,
    required this.defaultMethod,
    required this.regionCode,
  });

  final PrayerLocation location;
  final PrayerCalculationMethod defaultMethod;
  final String regionCode;
}

class PrayerLocationService {
  PrayerLocationService._();

  static Future<PrayerDeviceLocationResult> current({
    bool preferCached = false,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const PrayerLocationException(PrayerLocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const PrayerLocationException(
        PrayerLocationFailure.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const PrayerLocationException(PrayerLocationFailure.permissionDenied);
    }

    Position? position;
    if (preferCached) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final age = DateTime.now().difference(last.timestamp);
        if (!age.isNegative && age <= const Duration(hours: 6)) {
          position = last;
        }
      }
    }

    try {
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 100,
        ),
      ).timeout(const Duration(seconds: 14));
    } catch (_) {
      throw const PrayerLocationException(PrayerLocationFailure.unavailable);
    }

    final timezone = await FlutterTimezone.getLocalTimezone();
    final region = resolvePrayerRegion(position.latitude, position.longitude);
    return PrayerDeviceLocationResult(
      location: PrayerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timeZoneId: timezone.identifier,
        label: 'GPS',
      ),
      defaultMethod: region.method,
      regionCode: region.regionCode,
    );
  }
}
