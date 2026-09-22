import '../domain/prayer_models.dart';
import 'prayer_preferences_store.dart';
import 'prayer_saved_location_resolver.dart';

/// Builds a stable local identity for the inputs that materially affect prayer
/// times and notification delivery. Raw coordinates are deliberately excluded
/// from persisted diagnostics; the saved source id + timezone identify a
/// location change without turning diagnostics into a location-history store.
class PrayerScheduleConfiguration {
  const PrayerScheduleConfiguration._();

  static String fingerprint({
    required PrayerResolvedLocation resolved,
    required PrayerSettingsSnapshot settings,
  }) {
    final preferences = settings.preferencesFor(resolved.defaultMethod);
    final enabledPrayerIds = settings.notificationPrayerIds.toList()..sort();
    final a = preferences.adjustments;
    return <String>[
      'v2',
      resolved.sourceId,
      resolved.location.timeZoneId,
      preferences.calculationMethod.name,
      preferences.asrMethod.name,
      preferences.highLatitudeMethod.name,
      '${a.fajr},${a.sunrise},${a.dhuhr},${a.asr},${a.maghrib},${a.isha}',
      settings.notificationProfile.name,
      enabledPrayerIds.join(','),
    ].join('|');
  }
}
