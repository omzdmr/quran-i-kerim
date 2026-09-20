import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../l10n/app_locale_resolver.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';
import 'prayer_calculator.dart';
import 'prayer_preferences_store.dart';

class PrayerNotificationDiagnostics {
  const PrayerNotificationDiagnostics({
    required this.systemPermissionGranted,
    required this.exactAlarmAvailable,
    required this.pendingCount,
  });

  final bool? systemPermissionGranted;
  final bool? exactAlarmAvailable;
  final int pendingCount;
}

class PrayerNotificationService {
  PrayerNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    var granted = true;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notificationGranted =
          await android?.requestNotificationsPermission() ?? true;
      granted = granted && notificationGranted;
      if (notificationGranted) {
        // Exact alarms are appropriate for prayer-time reminders. If the user
        // declines the system permission, scheduling transparently falls back
        // to inexact alarms instead of disabling reminders altogether.
        await android?.requestExactAlarmsPermission();
      }
    } else if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosGranted =
          await ios?.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          true;
      granted = granted && iosGranted;
    }
    return granted;
  }

  static Future<void> refreshFromSaved() async {
    await initialize();
    final settings = await PrayerPreferencesStore.load();
    if (!settings.notificationsEnabled) {
      await _plugin.cancelAllPendingNotifications();
      return;
    }

    final cityId = await PrayerPreferencesStore.loadCityId();
    if (cityId == PrayerPreferencesStore.deviceLocationId) {
      final device = await PrayerPreferencesStore.loadDeviceLocation();
      if (device == null) return;
      await reschedule(
        location: device.location,
        defaultMethod: device.defaultMethod,
        settings: settings,
      );
      return;
    }

    final city = prayerCityById(cityId);
    await reschedule(
      location: city.location,
      defaultMethod: city.defaultMethod,
      settings: settings,
    );
  }

  static Future<void> reschedule({
    required PrayerLocation location,
    required PrayerCalculationMethod defaultMethod,
    required PrayerSettingsSnapshot settings,
  }) async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
    if (!settings.notificationsEnabled ||
        settings.notificationPrayerIds.isEmpty) {
      return;
    }

    final zone = tz.getLocation(location.timeZoneId);
    final now = tz.TZDateTime.now(zone);
    final calculator = PrayerCalculator();
    final preferences = settings.preferencesFor(defaultMethod);
    final copy = AppLocalizations(await AppLocaleResolver.currentLocale());

    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      if (canExact) scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        settings.notificationProfile.channelId,
        copy.prayerNotificationChannel,
        channelDescription: copy.prayerNotificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        playSound: settings.notificationProfile.playSound,
        enableVibration: settings.notificationProfile.enableVibration,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: settings.notificationProfile.playSound,
      ),
    );

    // 12 days x 5 prayers = 60 requests, staying below iOS's common pending
    // notification limit while still refreshing automatically on each app open.
    for (var dayOffset = 0; dayOffset < 12; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final schedule = calculator.calculate(
        location: location,
        date: date,
        preferences: preferences,
      );
      final rows = <({String id, DateTime time})>[
        (id: 'fajr', time: schedule.fajr),
        (id: 'dhuhr', time: schedule.dhuhr),
        (id: 'asr', time: schedule.asr),
        (id: 'maghrib', time: schedule.maghrib),
        (id: 'isha', time: schedule.isha),
      ];
      for (var prayerIndex = 0; prayerIndex < rows.length; prayerIndex++) {
        final row = rows[prayerIndex];
        if (!settings.notificationPrayerIds.contains(row.id)) continue;
        final scheduledDate = tz.TZDateTime.from(row.time, zone);
        if (!scheduledDate.isAfter(now.add(const Duration(seconds: 30)))) {
          continue;
        }
        await _plugin.zonedSchedule(
          id: 700000 + dayOffset * 10 + prayerIndex,
          title: copy.prayerNotificationTitle(row.id),
          body: copy.prayerNotificationBody(row.id),
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: scheduleMode,
          payload: 'prayer:${row.id}',
        );
      }
    }
  }

  static Future<PrayerNotificationDiagnostics> diagnostics() async {
    await initialize();

    bool? permissionGranted;
    bool? exactAlarmAvailable;

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      permissionGranted = await android?.areNotificationsEnabled();
      exactAlarmAvailable = await android?.canScheduleExactNotifications();
    } else if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final permissions = await ios?.checkPermissions();
      permissionGranted = permissions?.isEnabled;
    }

    final pending = await _plugin.pendingNotificationRequests();
    final prayerPendingCount = pending
        .where((request) => request.payload?.startsWith('prayer:') ?? false)
        .length;
    return PrayerNotificationDiagnostics(
      systemPermissionGranted: permissionGranted,
      exactAlarmAvailable: exactAlarmAvailable,
      pendingCount: prayerPendingCount,
    );
  }

  static Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
  }
}
