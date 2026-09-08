import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/data/translation_catalog.dart';
import 'src/features/prayer/application/prayer_notification_service.dart';
import 'src/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();

  // One-time device-language default, similar to mature Bible readers: the app
  // UI and the first reading source start in the user's device language when a
  // bundled offline source exists. After this initialization, manual source
  // choices are respected and never overwritten on later launches.
  final prefs = await SharedPreferences.getInstance();
  const initializedKey = 'device_quran_source_initialized_v1';
  if (!(prefs.getBool(initializedKey) ?? false)) {
    final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
    final sourceId = defaultQuranSourceForLanguage(deviceLanguage);
    await settings.setSelectedQuranSource(sourceId);
    await prefs.setBool(initializedKey, true);
  }

  runApp(QuranModernApp(settings: settings));
  unawaited(
    PrayerNotificationService.initialize().then(
      (_) => PrayerNotificationService.refreshFromSaved(),
    ),
  );
}
