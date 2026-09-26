import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/data/translation_catalog.dart';
import 'src/data/translation_repository.dart';
import 'src/features/reader/reader_media_session.dart';
import 'src/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore the last successful QuranEnc catalogue snapshot before settings are
  // resolved. No network is required for this path, and dynamically discovered
  // sources remain usable after an app restart.
  await TranslationRepository.instance.loadCachedCatalog();

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

  await ReaderMediaSession.initialize();

  runApp(QuranModernApp(settings: settings));

  // Catalogue refresh is deliberately best-effort and infrequent (once per
  // week). It never blocks launch or Quran reading, and it costs one small
  // metadata request instead of a backend of our own.
  unawaited(
    TranslationRepository.instance.refreshCatalogIfStale(
      localization: PlatformDispatcher.instance.locale.languageCode,
    ),
  );

  // Prayer scheduling is repaired by QuranModernApp after the first frame and
  // on resume. Keeping one owner avoids cancelling/recreating the same 12-day
  // schedule twice at startup and lets the freshness/configuration contract
  // decide whether any platform work is actually needed.
}
