import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reloadFromStorage refreshes restored values and notifies listeners', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_mode': 'light',
      'last_surah': 2,
      'last_ayah': 5,
      'quran_source_user_selected_v1': true,
      'selected_quran_source': 'tr.rwwad',
    });

    final settings = AppSettings();
    await settings.load();
    expect(settings.themeMode, ThemeMode.light);
    expect(settings.lastSurah, 2);
    expect(settings.lastAyah, 5);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', 'dark');
    await prefs.setInt('last_surah', 36);
    await prefs.setInt('last_ayah', 58);

    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.reloadFromStorage();

    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.lastSurah, 36);
    expect(settings.lastAyah, 58);
    expect(notifications, 1);
  });
}
