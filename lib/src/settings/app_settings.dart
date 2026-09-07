import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReaderDisplayMode { arabic, arabicAndTranslation, translation }

enum VerseHighlightColor { yellow, green, blue, orange, pink }

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'app_locale';
  static const _lastSurahKey = 'last_surah';
  static const _lastAyahKey = 'last_ayah';
  static const _readerModeKey = 'reader_mode';
  static const _arabicFontSizeKey = 'arabic_font_size';
  static const _bookmarksKey = 'bookmarks';
  static const _notesKey = 'verse_notes';
  static const _highlightsKey = 'verse_highlights';
  static const _readingDaysKey = 'reading_days';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  int _lastSurah = 1;
  int _lastAyah = 1;
  ReaderDisplayMode _readerMode = ReaderDisplayMode.arabicAndTranslation;
  double _arabicFontSize = 29;
  Set<String> _bookmarks = <String>{};
  Map<String, String> _notes = <String, String>{};
  Map<String, String> _highlights = <String, String>{};
  Set<String> _readingDays = <String>{};

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  int get lastSurah => _lastSurah;
  int get lastAyah => _lastAyah;
  ReaderDisplayMode get readerMode => _readerMode;
  double get arabicFontSize => _arabicFontSize;

  UnmodifiableSetView<String> get bookmarkKeys => UnmodifiableSetView(_bookmarks);
  UnmodifiableMapView<String, String> get noteEntries => UnmodifiableMapView(_notes);
  UnmodifiableMapView<String, String> get highlightEntries => UnmodifiableMapView(_highlights);
  UnmodifiableSetView<String> get readingDays => UnmodifiableSetView(_readingDays);

  int get readingStreak {
    if (_readingDays.isEmpty) return 0;
    var cursor = DateTime.now();
    var streak = 0;
    while (_readingDays.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get readingDaysThisYear {
    final prefix = '${DateTime.now().year}-';
    return _readingDays.where((day) => day.startsWith(prefix)).length;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final localeCode = prefs.getString(_localeKey);
    _locale = localeCode == null || localeCode == 'system'
        ? null
        : Locale(localeCode);

    final savedSurah = prefs.getInt(_lastSurahKey) ?? 1;
    final savedAyah = prefs.getInt(_lastAyahKey) ?? 1;
    _lastSurah = savedSurah.clamp(1, 114).toInt();
    _lastAyah = savedAyah < 1 ? 1 : savedAyah;

    _readerMode = switch (prefs.getString(_readerModeKey)) {
      'arabic' => ReaderDisplayMode.arabic,
      'translation' => ReaderDisplayMode.translation,
      _ => ReaderDisplayMode.arabicAndTranslation,
    };

    _arabicFontSize = (prefs.getDouble(_arabicFontSizeKey) ?? 29).clamp(22, 42);
    _bookmarks = (prefs.getStringList(_bookmarksKey) ?? const <String>[]).toSet();
    _notes = _decodeStringMap(prefs.getString(_notesKey));
    _highlights = _decodeStringMap(prefs.getString(_highlightsKey));
    _readingDays = (prefs.getStringList(_readingDaysKey) ?? const <String>[]).toSet();
  }

  Map<String, String> _decodeStringMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) return <String, String>{};
    try {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return <String, String>{};
    }
  }

  String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale?.languageCode ?? 'system');
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
    final today = _dayKey(DateTime.now());
    final newReadingDay = _readingDays.add(today);
    final positionChanged = _lastSurah != safeSurah || _lastAyah != safeAyah;

    if (!newReadingDay && !positionChanged) return;

    _lastSurah = safeSurah;
    _lastAyah = safeAyah;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final writes = <Future<bool>>[];
    if (positionChanged) {
      writes.add(prefs.setInt(_lastSurahKey, safeSurah));
      writes.add(prefs.setInt(_lastAyahKey, safeAyah));
    }
    if (newReadingDay) {
      final days = _readingDays.toList()..sort();
      writes.add(prefs.setStringList(_readingDaysKey, days));
    }
    await Future.wait(writes);
  }

  String verseKey(int surah, int ayah) => '$surah:$ayah';

  String selectionKey(int surah, Iterable<int> ayahs) {
    final sorted = ayahs.toSet().toList()..sort();
    if (sorted.isEmpty) return '$surah:1';
    if (sorted.length == 1) return verseKey(surah, sorted.single);

    var contiguous = true;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] != sorted[i - 1] + 1) {
        contiguous = false;
        break;
      }
    }
    return contiguous
        ? '$surah:${sorted.first}-${sorted.last}'
        : '$surah:${sorted.join(',')}';
  }

  bool isBookmarked(int surah, int ayah) => _bookmarks.contains(verseKey(surah, ayah));

  Future<void> toggleBookmark(int surah, int ayah) async {
    final key = verseKey(surah, ayah);
    if (!_bookmarks.add(key)) _bookmarks.remove(key);
    notifyListeners();
    await _persistBookmarks();
  }

  Future<void> bookmarkSelection(int surah, Iterable<int> ayahs) async {
    for (final ayah in ayahs) {
      _bookmarks.add(verseKey(surah, ayah));
    }
    notifyListeners();
    await _persistBookmarks();
  }

  Future<void> _persistBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = _bookmarks.toList()..sort();
    await prefs.setStringList(_bookmarksKey, sorted);
  }

  String? noteFor(int surah, int ayah) => _notes[verseKey(surah, ayah)];

  String? noteForSelection(int surah, Iterable<int> ayahs) =>
      _notes[selectionKey(surah, ayahs)];

  Future<void> setNote(int surah, int ayah, String text) =>
      setNoteForSelection(surah, <int>[ayah], text);

  Future<void> setNoteForSelection(
    int surah,
    Iterable<int> ayahs,
    String text,
  ) async {
    final key = selectionKey(surah, ayahs);
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

  VerseHighlightColor? highlightFor(int surah, int ayah) {
    final stored = _highlights[verseKey(surah, ayah)];
    if (stored == null) return null;
    for (final color in VerseHighlightColor.values) {
      if (color.name == stored) return color;
    }
    return null;
  }

  Future<void> setHighlight(
    int surah,
    int ayah,
    VerseHighlightColor? color,
  ) => setHighlightForSelection(surah, <int>[ayah], color);

  Future<void> setHighlightForSelection(
    int surah,
    Iterable<int> ayahs,
    VerseHighlightColor? color,
  ) async {
    for (final ayah in ayahs) {
      final key = verseKey(surah, ayah);
      if (color == null) {
        _highlights.remove(key);
      } else {
        _highlights[key] = color.name;
      }
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_highlightsKey, jsonEncode(_highlights));
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
