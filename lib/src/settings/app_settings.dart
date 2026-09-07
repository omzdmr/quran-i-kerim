import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _lastSurahKey = 'last_surah';
  static const _lastAyahKey = 'last_ayah';

  ThemeMode _themeMode = ThemeMode.system;
  int _lastSurah = 1;
  int _lastAyah = 1;

  ThemeMode get themeMode => _themeMode;
  int get lastSurah => _lastSurah;
  int get lastAyah => _lastAyah;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final savedSurah = prefs.getInt(_lastSurahKey) ?? 1;
    final savedAyah = prefs.getInt(_lastAyahKey) ?? 1;
    _lastSurah = savedSurah.clamp(1, 114);
    _lastAyah = savedAyah < 1 ? 1 : savedAyah;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  Future<void> saveReadingPosition({
    required int surah,
    required int ayah,
  }) async {
    final safeSurah = surah.clamp(1, 114);
    final safeAyah = ayah < 1 ? 1 : ayah;
    if (_lastSurah == safeSurah && _lastAyah == safeAyah) return;

    _lastSurah = safeSurah;
    _lastAyah = safeAyah;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_lastSurahKey, safeSurah),
      prefs.setInt(_lastAyahKey, safeAyah),
    ]);
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    required AppSettings settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope bulunamadı.');
    return scope!.notifier!;
  }
}
