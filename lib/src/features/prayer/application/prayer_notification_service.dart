import 'dart:io';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/prayer_city_catalog.dart';
import '../domain/prayer_models.dart';
import 'prayer_calculator.dart';
import 'prayer_preferences_store.dart';

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
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
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
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await ios?.requestPermissions(
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
    final copy = _PrayerNotificationCopy(
      PlatformDispatcher.instance.locale.languageCode,
    );

    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      if (canExact) scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_times',
        'Prayer times',
        channelDescription: 'Prayer time reminders',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
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
          title: copy.title(row.id),
          body: copy.body(row.id),
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: scheduleMode,
          payload: 'prayer:${row.id}',
        );
      }
    }
  }

  static Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
  }
}

class _PrayerNotificationCopy {
  const _PrayerNotificationCopy(this.languageCode);

  final String languageCode;

  String _prayer(String id) {
    final values = switch (languageCode) {
      'tr' => const {
          'fajr': 'İmsak',
          'dhuhr': 'Öğle',
          'asr': 'İkindi',
          'maghrib': 'Akşam',
          'isha': 'Yatsı',
        },
      'ar' => const {
          'fajr': 'الفجر',
          'dhuhr': 'الظهر',
          'asr': 'العصر',
          'maghrib': 'المغرب',
          'isha': 'العشاء',
        },
      'az' => const {
          'fajr': 'Sübh',
          'dhuhr': 'Zöhr',
          'asr': 'Əsr',
          'maghrib': 'Məğrib',
          'isha': 'İşa',
        },
      'ru' => const {
          'fajr': 'Фаджр',
          'dhuhr': 'Зухр',
          'asr': 'Аср',
          'maghrib': 'Магриб',
          'isha': 'Иша',
        },
      _ => const {
          'fajr': 'Fajr',
          'dhuhr': 'Dhuhr',
          'asr': 'Asr',
          'maghrib': 'Maghrib',
          'isha': 'Isha',
        },
    };
    return values[id] ?? id;
  }

  String title(String id) => switch (languageCode) {
        'tr' => '${_prayer(id)} vakti',
        'ar' => 'وقت ${_prayer(id)}',
        'az' => '${_prayer(id)} vaxtı',
        'ru' => 'Время: ${_prayer(id)}',
        _ => '${_prayer(id)} time',
      };

  String body(String id) => switch (languageCode) {
        'tr' => '${_prayer(id)} vakti girdi.',
        'ar' => 'حان الآن وقت ${_prayer(id)}.',
        'az' => '${_prayer(id)} vaxtı daxil oldu.',
        'ru' => 'Наступило время молитвы ${_prayer(id)}.',
        _ => 'It is time for ${_prayer(id)}.',
      };
}
