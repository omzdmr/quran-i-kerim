import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReaderDisplayMode { arabic, arabicAndTranslation, translation }

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _lastSurahKey = 'last_surah';
  static const _lastAyahKey = 'last_ayah';
  static const _readerModeKey = 'reader_mode';
  static const _arabicFontSizeKey = 'arabic_font_size';
  static const _bookmarksKey = 'bookmarks';
  static const _notesKey = 'verse_notes';

  ThemeMode _themeMode = ThemeMode.system;
  int _lastSurah = 1;
  int _lastAyah = 1;
  ReaderDisplayMode _readerMode = ReaderDisplayMode.arabic;
  double _arabicFontSize = 29;
  Set<String> _bookmarks = <String>{};
  Map<String, String> _notes = <String, String>{};

  ThemeMode get themeMode => _themeMode;
  int get lastSurah => _lastSurah;
  int get lastAyah => _lastAyah;
  ReaderDisplayMode get readerMode => _readerMode;
  double get arabicFontSize => _arabicFontSize;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final savedSurah = prefs.getInt(_lastSurahKey) ?? 1;
    final savedAyah = prefs.getInt(_lastAyahKey) ?? 1;
    _lastSurah = savedSurah.clamp(1, 114).toInt();
    _lastAyah = savedAyah < 1 ? 1 : savedAyah;

    _readerMode = switch (prefs.getString(_readerModeKey)) {
      'arabic_translation' => ReaderDisplayMode.arabicAndTranslation,
      'translation' => ReaderDisplayMode.translation,
      _ => ReaderDisplayMode.arabic,
    };

    _arabicFontSize = (prefs.getDouble(_arabicFontSizeKey) ?? 29).clamp(22, 42);
    _bookmarks = (prefs.getStringList(_bookmarksKey) ?? const <String>[]).toSet();

    final notesJson = prefs.getString(_notesKey);
    if (notesJson != null && notesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(notesJson) as Map<String, dynamic>;
        _notes = decoded.map((key, value) => MapEntry(key, value.toString()));
      } catch (_) {
        _notes = <String, String>{};
      }
    }
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

  Future<void> setReaderMode(ReaderDisplayMode mode) async {
    if (_readerMode == mode) return;
    _readerMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _readerModeKey,
      switch (mode) {
        ReaderDisplayMode.arabic => 'arabic',
        ReaderDisplayMode.arabicAndTranslation => 'arabic_translation',
        ReaderDisplayMode.translation => 'translation',
      },
    );
  }

  Future<void> setArabicFontSize(double value) async {
    final safe = value.clamp(22, 42).toDouble();
    if ((_arabicFontSize - safe).abs() < .1) return;
    _arabicFontSize = safe;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_arabicFontSizeKey, safe);
  }

  Future<void> saveReadingPosition({
    required int surah,
    required int ayah,
  }) async {
    final safeSurah = surah.clamp(1, 114).toInt();
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

  String _verseKey(int surah, int ayah) => '$surah:$ayah';

  bool isBookmarked(int surah, int ayah) => _bookmarks.contains(_verseKey(surah, ayah));

  Future<void> toggleBookmark(int surah, int ayah) async {
    final key = _verseKey(surah, ayah);
    if (!_bookmarks.add(key)) _bookmarks.remove(key);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final sorted = _bookmarks.toList()..sort();
    await prefs.setStringList(_bookmarksKey, sorted);
  }

  String? noteFor(int surah, int ayah) => _notes[_verseKey(surah, ayah)];

  Future<void> setNote(int surah, int ayah, String text) async {
    final key = _verseKey(surah, ayah);
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _notes.remove(key);
    } else {
      _notes[key] = trimmed;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notesKey, jsonEncode(_notes));
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
