import 'prayer_preferences_store.dart';
import 'prayer_saved_location_resolver.dart';

/// Builds a stable local identity for inputs that materially affect prayer
/// times and notification delivery. The persisted value is a compact hash, so
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
    return 'v2-${_fnv1a64(canonical)}';
  }

  static String _fnv1a64(String input) {
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    const mask = 0xffffffffffffffff;
    for (final byte in input.codeUnits) {
      hash ^= byte;
      hash = (hash * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
