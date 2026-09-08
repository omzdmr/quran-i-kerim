import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReaderDisplayMode { arabic, arabicAndTranslation, translation }

enum ReaderLineSpacing { compact, normal, relaxed }

enum VerseHighlightColor { yellow, green, blue, orange, pink }

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'app_locale';
  static const _lastSurahKey = 'last_surah';
  static const _lastAyahKey = 'last_ayah';
  static const _readerModeKey = 'reader_mode';
  static const _arabicFontSizeKey = 'arabic_font_size';
  static const _translationFontSizeKey = 'translation_font_size';
  static const _readerLineSpacingKey = 'reader_line_spacing';
  static const _bookmarksKey = 'bookmarks';
  static const _notesKey = 'verse_notes';
  static const _highlightsKey = 'verse_highlights';
  static const _readingDaysKey = 'reading_days';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  int _lastSurah = 1;
  int _lastAyah = 1;
  ReaderDisplayMode _readerMode = ReaderDisplayMode.translation;
  ReaderLineSpacing _readerLineSpacing = ReaderLineSpacing.normal;
  double _arabicFontSize = 29;
  double _translationFontSize = 17.5;
  Set<String> _bookmarks = <String>{};
  Map<String, String> _notes = <String, String>{};
  Map<String, String> _highlights = <String, String>{};
  Set<String> _readingDays = <String>{};

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  int get lastSurah => _lastSurah;
  int get lastAyah => _lastAyah;
  ReaderDisplayMode get readerMode => _readerMode;
  ReaderLineSpacing get readerLineSpacing => _readerLineSpacing;
  double get arabicFontSize => _arabicFontSize;
  double get translationFontSize => _translationFontSize;

  double get arabicLineHeight => switch (_readerLineSpacing) {
        ReaderLineSpacing.compact => 1.78,
        ReaderLineSpacing.normal => 2.02,
        ReaderLineSpacing.relaxed => 2.22,
      };

  double get translationLineHeight => switch (_readerLineSpacing) {
        ReaderLineSpacing.compact => 1.38,
        ReaderLineSpacing.normal => 1.58,
        ReaderLineSpacing.relaxed => 1.78,
      };

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
      'arabic_translation' => ReaderDisplayMode.arabicAndTranslation,
      'translation' => ReaderDisplayMode.translation,
      _ => ReaderDisplayMode.translation,
    };

    _readerLineSpacing = switch (prefs.getString(_readerLineSpacingKey)) {
      'compact' => ReaderLineSpacing.compact,
      'relaxed' => ReaderLineSpacing.relaxed,
      _ => ReaderLineSpacing.normal,
    };

    _arabicFontSize = (prefs.getDouble(_arabicFontSizeKey) ?? 29).clamp(22, 42);
    _translationFontSize =
        (prefs.getDouble(_translationFontSizeKey) ?? 17.5).clamp(14, 28);
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

  Future<void> setReaderLineSpacing(ReaderLineSpacing spacing) async {
    if (_readerLineSpacing == spacing) return;
    _readerLineSpacing = spacing;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _readerLineSpacingKey,
      switch (spacing) {
        ReaderLineSpacing.compact => 'compact',
        ReaderLineSpacing.normal => 'normal',
        ReaderLineSpacing.relaxed => 'relaxed',
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

  Future<void> setTranslationFontSize(double value) async {
    final safe = value.clamp(14, 28).toDouble();
    if ((_translationFontSize - safe).abs() < .1) return;
    _translationFontSize = safe;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_translationFontSizeKey, safe);
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

  List<int>? _selectionAyahs(String key, int expectedSurah) {
    final separator = key.indexOf(':');
    if (separator < 1 || separator == key.length - 1) return null;
    final surah = int.tryParse(key.substring(0, separator));
    if (surah != expectedSurah) return null;

    final part = key.substring(separator + 1);
    if (part.contains('-')) {
      final bounds = part.split('-');
      if (bounds.length != 2) return null;
      final start = int.tryParse(bounds.first);
      final end = int.tryParse(bounds.last);
      if (start == null || end == null || start < 1 || end < start) return null;
      return [for (var value = start; value <= end; value++) value];
    }
    if (part.contains(',')) {
      final result = <int>[];
      for (final raw in part.split(',')) {
        final value = int.tryParse(raw);
        if (value == null || value < 1) return null;
        result.add(value);
      }
      return result;
    }
    final single = int.tryParse(part);
    return single == null || single < 1 ? null : <int>[single];
  }

  bool _selectionContains(String key, int surah, int ayah) =>
      _selectionAyahs(key, surah)?.contains(ayah) ?? false;

  bool isBookmarked(int surah, int ayah) =>
      _bookmarks.any((key) => _selectionContains(key, surah, ayah));

  Future<void> toggleBookmark(int surah, int ayah) async {
    final key = verseKey(surah, ayah);
    if (!_bookmarks.add(key)) _bookmarks.remove(key);
    notifyListeners();
    await _persistBookmarks();
  }

  Future<void> bookmarkSelection(int surah, Iterable<int> ayahs) async {
    final selected = ayahs.toSet().toList()..sort();
    if (selected.isEmpty) return;
    _bookmarks.removeWhere(
      (key) => selected.any((ayah) => _selectionContains(key, surah, ayah)),
    );
    _bookmarks.add(selectionKey(surah, selected));
    notifyListeners();
    await _persistBookmarks();
  }

  Future<void> _persistBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = _bookmarks.toList()..sort();
    await prefs.setStringList(_bookmarksKey, sorted);
  }

  String? noteFor(int surah, int ayah) {
    for (final entry in _notes.entries) {
      if (_selectionContains(entry.key, surah, ayah)) return entry.value;
    }
    return null;
  }

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
    String? stored;
    for (final entry in _highlights.entries) {
      if (_selectionContains(entry.key, surah, ayah)) {
        stored = entry.value;
        break;
      }
    }
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
    final selected = ayahs.toSet().toList()..sort();
    if (selected.isEmpty) return;
    _highlights.removeWhere(
      (key, _) => selected.any((ayah) => _selectionContains(key, surah, ayah)),
    );
    if (color != null) {
      _highlights[selectionKey(surah, selected)] = color.name;
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
