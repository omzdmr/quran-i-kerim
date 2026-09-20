import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

class AppLocaleResolver {
  const AppLocaleResolver._();

  static const _localeKey = 'app_locale';

  static Locale resolve({
    String? storedLanguageCode,
    List<Locale>? deviceLocales,
  }) {
    final stored = storedLanguageCode?.trim();
    if (stored != null && stored.isNotEmpty && stored != 'system') {
      for (final supported in AppLocalizations.supportedLocales) {
        if (supported.languageCode == stored) return supported;
      }
    }

    final candidates = deviceLocales ?? ui.PlatformDispatcher.instance.locales;
    for (final deviceLocale in candidates) {
      for (final supported in AppLocalizations.supportedLocales) {
        if (supported.languageCode == deviceLocale.languageCode) {
          return supported;
        }
      }
    }
    return const Locale('en');
  }

  static Future<Locale> currentLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return resolve(storedLanguageCode: prefs.getString(_localeKey));
  }
}
