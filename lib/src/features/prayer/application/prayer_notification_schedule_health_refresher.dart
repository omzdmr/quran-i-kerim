import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'prayer_calculator.dart';
import 'prayer_notification_schedule_health_store.dart';
import 'prayer_notification_service.dart';
import 'prayer_preferences_store.dart';
import 'prayer_saved_location_resolver.dart';
import 'prayer_schedule_configuration.dart';

/// Rebuilds prayer notifications and then records independently inspectable
/// evidence about the schedule that was just produced.
class PrayerNotificationScheduleHealthRefresher {
  const PrayerNotificationScheduleHealthRefresher({
    this.resolver = const PrayerSavedLocationResolver(),
    this.store = const PrayerNotificationScheduleHealthStore(),
  });

  final PrayerSavedLocationResolver resolver;
  final PrayerNotificationScheduleHealthStore store;

  Future<String?> currentConfigurationFingerprint() async {
    final settings = await PrayerPreferencesStore.load();
    if (!settings.notificationsEnabled || settings.notificationPrayerIds.isEmpty) return null;
    final resolved = await resolver.resolve();
    if (resolved == null) return null;
    return PrayerScheduleConfiguration.fingerprint(resolved: resolved, settings: settings);
  }

  Future<PrayerNotificationScheduleHealth?> resync({DateTime? now}) async {
    final settings = await PrayerPreferencesStore.load();
    if (!settings.notificationsEnabled || settings.notificationPrayerIds.isEmpty) {
      await PrayerNotificationService.refreshFromSaved();
      await store.clear();
      return null;
    }
    final resolved = await resolver.resolve();
    if (resolved == null) {
      await store.clear();
      return null;
    }

    // Use the resolved object directly. Calling refreshFromSaved here would
    // currently send the special manual-location ID through the static city
    // catalog fallback, which can schedule Istanbul while the UI says another
    // travel city. This path therefore fixes the schedule as well as auditing it.
    await PrayerNotificationService.reschedule(
      location: resolved.location,
      defaultMethod: resolved.defaultMethod,
      settings: settings,
    );
    final diagnostics = await PrayerNotificationService.diagnostics();
    if (diagnostics.pendingCount < 1) {
      await store.clear();
      return null;
    }

    tz_data.initializeTimeZones();
    final zone = tz.getLocation(resolved.location.timeZoneId);
    final instant = now == null ? tz.TZDateTime.now(zone) : tz.TZDateTime.from(now, zone);
    final preferences = settings.preferencesFor(resolved.defaultMethod);
    final calculator = PrayerCalculator();
    ({String id, DateTime time})? next;

    for (var offset = 0; offset < 2 && next == null; offset++) {
      final date = instant.add(Duration(days: offset));
      final schedule = calculator.calculate(location: resolved.location, date: date, preferences: preferences);
      final rows = <({String id, DateTime time})>[
        (id: 'fajr', time: schedule.fajr),
        (id: 'dhuhr', time: schedule.dhuhr),
        (id: 'asr', time: schedule.asr),
        (id: 'maghrib', time: schedule.maghrib),
        (id: 'isha', time: schedule.isha),
      ];
      for (final row in rows) {
        if (!settings.notificationPrayerIds.contains(row.id)) continue;
        if (row.time.isAfter(instant)) {
          next = row;
          break;
        }
      }
    }
    if (next == null) {
      await store.clear();
      return null;
    }

    final health = PrayerNotificationScheduleHealth(
      scheduledAt: instant.toUtc(),
      nextPrayerId: next.id,
      nextScheduledAt: next.time.toUtc(),
      timeZoneId: resolved.location.timeZoneId,
      locationLabel: resolved.label,
      calculationMethodId: preferences.calculationMethod.name,
      pendingCount: diagnostics.pendingCount,
      configurationFingerprint: PrayerScheduleConfiguration.fingerprint(
        resolved: resolved,
        settings: settings,
      ),
    );
    await store.save(health);
    return health;
  }
}
