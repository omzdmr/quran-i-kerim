import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'prayer_preferences_store.dart';
import 'prayer_saved_location_resolver.dart';

/// Builds a stable local identity for inputs that materially affect prayer
/// times and notification delivery. Only the SHA-256 digest is persisted, so
/// diagnostics do not become a second store of raw coordinates/preferences.
class PrayerScheduleConfiguration {
  const PrayerScheduleConfiguration._();

  static String fingerprint({
    required PrayerResolvedLocation resolved,
    required PrayerSettingsSnapshot settings,
  }) {
    final preferences = settings.preferencesFor(resolved.defaultMethod);
    final enabledPrayerIds = settings.notificationPrayerIds.toList()..sort();
    final a = preferences.adjustments;
    final canonical = <String>[
      'v2',
      resolved.label,
      resolved.location.latitude.toStringAsFixed(5),
      resolved.location.longitude.toStringAsFixed(5),
      resolved.location.timeZoneId,
      preferences.calculationMethod.name,
      preferences.asrMethod.name,
      preferences.highLatitudeMethod.name,
      '${a.fajr},${a.sunrise},${a.dhuhr},${a.asr},${a.maghrib},${a.isha}',
      settings.notificationProfile.name,
      enabledPrayerIds.join(','),
    ].join('|');
    return 'v2-${sha256.convert(utf8.encode(canonical))}';
  }
}
