import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/translation_catalog.dart';

enum ReaderDisplayMode { arabic, arabicAndTranslation, translation }

enum ReaderLineSpacing { compact, normal, relaxed }

enum VerseHighlightColor { yellow, green, blue, orange, pink }

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'app_locale';
  static const _lastSurahKey = 'last_surah';
  static const _lastAyahKey = 'last_ayah';
  static const _readerModeKey = 'reader_mode';
  static const _selectedQuranSourceKey = 'selected_quran_source';
  static const _sourceUserSelectedKey = 'quran_source_user_selected_v1';
  static const _readerTextSizeKey = 'reader_text_size';

  static const _arabicFontSizeKey = 'arabic_font_size';
  static const _translationFontSizeKey = 'translation_font_size';

  static const _readerLineSpacingKey = 'reader_line_spacing';
  static const _bookmarksKey = 'bookmarks';
  static const _notesKey = 'verse_notes';
  static const _noteSourcesKey = 'verse_note_sources';
  static const _highlightsKey = 'verse_highlights';
  static const _archiveTimesKey = 'archive_times';
  static const _readingDaysKey = 'reading_days';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  int _lastSurah = 1;
  int _lastAyah = 1;
  String _selectedQuranSourceId = bundledTurkishTranslationId;
  bool _quranSourceWasUserSelected = false;
  ReaderLineSpacing _readerLineSpacing = ReaderLineSpacing.normal;
  double _readerTextSize = 25;
  Set<String> _bookmarks = <String>{};
  Map<String, String> _notes = <String, String>{};
  Map<String, String> _noteSources = <String, String>{};
  Map<String, String> _highlights = <String, String>{};
  Map<String, String> _archiveTimes = <String, String>{};
  Set<String> _readingDays = <String>{};

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  int get lastSurah => _lastSurah;
  int get lastAyah => _lastAyah;
  String get selectedQuranSourceId => _selectedQuranSourceId;
  bool get quranSourceWasUserSelected => _quranSourceWasUserSelected;
  bool get readerUsesArabic => _selectedQuranSourceId == arabicOriginalSourceId;

  ReaderDisplayMode get readerMode => readerUsesArabic
      ? ReaderDisplayMode.arabic
      : ReaderDisplayMode.translation;

  ReaderLineSpacing get readerLineSpacing => _readerLineSpacing;
  double get readerTextSize => _readerTextSize;
  double get arabicFontSize => _readerTextSize;
  double get translationFontSize => _readerTextSize;

  double get arabicLineHeight => switch (_readerLineSpacing) {
    ReaderLineSpacing.compact => 1.62,
    ReaderLineSpacing.normal => 1.82,
    ReaderLineSpacing.relaxed => 2.02,
  };

  double get translationLineHeight => switch (_readerLineSpacing) {
    ReaderLineSpacing.compact => 1.32,
    ReaderLineSpacing.normal => 1.48,
    ReaderLineSpacing.relaxed => 1.66,
  };

  UnmodifiableSetView<String> get bookmarkKeys =>
      UnmodifiableSetView(_bookmarks);
  UnmodifiableMapView<String, String> get noteEntries =>
      UnmodifiableMapView(_notes);
  UnmodifiableMapView<String, String> get noteSourceEntries =>
      UnmodifiableMapView(_noteSources);
  UnmodifiableMapView<String, String> get highlightEntries =>
      UnmodifiableMapView(_highlights);
  UnmodifiableSetView<String> get readingDays =>
      UnmodifiableSetView(_readingDays);

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

  String _deviceLanguage() {
    final locales = ui.PlatformDispatcher.instance.locales;
    return locales.isEmpty
        ? ui.PlatformDispatcher.instance.locale.languageCode
        : locales.first.languageCode;
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

    final savedSource = prefs.getString(_selectedQuranSourceKey)?.trim();
    _quranSourceWasUserSelected =
        prefs.getBool(_sourceUserSelectedKey) ?? false;

    if (savedSource != null &&
        savedSource.isNotEmpty &&
        _quranSourceWasUserSelected) {
      _selectedQuranSourceId = savedSource;
    } else {
      final legacyMode = prefs.getString(_readerModeKey);
      if (savedSource == null && legacyMode == 'arabic') {
        _selectedQuranSourceId = arabicOriginalSourceId;
      } else {
        _selectedQuranSourceId = defaultQuranSourceForLanguage(
          _deviceLanguage(),
        );
      }
      _quranSourceWasUserSelected = false;
      await Future.wait([
        prefs.setString(_selectedQuranSourceKey, _selectedQuranSourceId),
        prefs.setBool(_sourceUserSelectedKey, false),
      ]);
    }

    _readerLineSpacing = switch (prefs.getString(_readerLineSpacingKey)) {
      'compact' => ReaderLineSpacing.compact,
      'relaxed' => ReaderLineSpacing.relaxed,
      _ => ReaderLineSpacing.normal,
    };

    if (prefs.containsKey(_readerTextSizeKey)) {
      _readerTextSize = (prefs.getDouble(_readerTextSizeKey) ?? 25)
          .clamp(18, 40)
          .toDouble();
    } else {
      _readerTextSize = 25;
    }

    _bookmarks = (prefs.getStringList(_bookmarksKey) ?? const <String>[])
        .toSet();
    _notes = _decodeStringMap(prefs.getString(_notesKey));
    _noteSources = _decodeStringMap(prefs.getString(_noteSourcesKey));
    _highlights = _decodeStringMap(prefs.getString(_highlightsKey));
    _archiveTimes = _decodeStringMap(prefs.getString(_archiveTimesKey));
    _readingDays = (prefs.getStringList(_readingDaysKey) ?? const <String>[])
        .toSet();
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

  String _archiveKey(String kind, String selectionKey) => '$kind|$selectionKey';

  int archiveTimestamp(String kind, String selectionKey) {
    return int.tryParse(_archiveTimes[_archiveKey(kind, selectionKey)] ?? '') ??
        0;
  }

  void _touchArchive(String kind, String selectionKey) {
    _archiveTimes[_archiveKey(kind, selectionKey)] = DateTime.now()
        .millisecondsSinceEpoch
        .toString();
  }

  void _removeArchiveTime(String kind, String selectionKey) {
    _archiveTimes.remove(_archiveKey(kind, selectionKey));
  }

  Future<void> _persistArchiveTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_archiveTimesKey, jsonEncode(_archiveTimes));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale?.languageCode ?? 'system');
  }

  Future<void> setSelectedQuranSource(String sourceId) async {
    final safe = sourceId.trim();
    if (safe.isEmpty) return;
    final changed =
        _selectedQuranSourceId != safe || !_quranSourceWasUserSelected;
    _selectedQuranSourceId = safe;
    _quranSourceWasUserSelected = true;
    if (changed) notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_selectedQuranSourceKey, safe),
      prefs.setBool(_sourceUserSelectedKey, true),
      prefs.setString(
        _readerModeKey,
        safe == arabicOriginalSourceId ? 'arabic' : 'translation',
      ),
    ]);
  }

  Future<void> setReaderMode(ReaderDisplayMode mode) => setSelectedQuranSource(
    mode == ReaderDisplayMode.arabic
        ? arabicOriginalSourceId
        : bundledTurkishTranslationId,
  );

  Future<void> setReaderLineSpacing(ReaderLineSpacing spacing) async {
    if (_readerLineSpacing == spacing) return;
    _readerLineSpacing = spacing;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readerLineSpacingKey, switch (spacing) {
      ReaderLineSpacing.compact => 'compact',
      ReaderLineSpacing.normal => 'normal',
      ReaderLineSpacing.relaxed => 'relaxed',
    });
  }

  Future<void> setReaderTextSize(double value) async {
    final safe = value.clamp(18, 40).toDouble();
    if ((_readerTextSize - safe).abs() < .1) return;
    _readerTextSize = safe;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble(_readerTextSizeKey, safe),
      prefs.setDouble(_arabicFontSizeKey, safe),
      prefs.setDouble(_translationFontSizeKey, safe),
    ]);
  }

  Future<void> setArabicFontSize(double value) => setReaderTextSize(value);
  Future<void> setTranslationFontSize(double value) => setReaderTextSize(value);

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

  List<int>? selectionAyahs(String key, int expectedSurah) {
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

  bool selectionContains(String key, int surah, int ayah) =>
      selectionAyahs(key, surah)?.contains(ayah) ?? false;

  bool isBookmarked(int surah, int ayah) =>
      _bookmarks.any((key) => selectionContains(key, surah, ayah));

  Future<void> toggleBookmark(int surah, int ayah) async {
    final key = verseKey(surah, ayah);
    if (!_bookmarks.add(key)) {
      _bookmarks.remove(key);
      _removeArchiveTime('bookmark', key);
    } else {
      _touchArchive('bookmark', key);
    }
    notifyListeners();
    await Future.wait([_persistBookmarks(), _persistArchiveTimes()]);
  }

  Future<void> bookmarkSelection(int surah, Iterable<int> ayahs) async {
    final selected = ayahs.toSet().toList()..sort();
    if (selected.isEmpty) return;

    final removed = _bookmarks
        .where(
          (key) => selected.any((ayah) => selectionContains(key, surah, ayah)),
        )
        .toList(growable: false);
    for (final key in removed) {
      _bookmarks.remove(key);
      _removeArchiveTime('bookmark', key);
    }

    final key = selectionKey(surah, selected);
    _bookmarks.add(key);
    _touchArchive('bookmark', key);
    notifyListeners();
    await Future.wait([_persistBookmarks(), _persistArchiveTimes()]);
  }

  Future<void> _persistBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = _bookmarks.toList()..sort();
    await prefs.setStringList(_bookmarksKey, sorted);
  }

  String? noteKeyForAyah(int surah, int ayah) {
    for (final key in _notes.keys) {
      if (selectionContains(key, surah, ayah)) return key;
    }
    return null;
  }

  String? noteFor(int surah, int ayah) {
    final key = noteKeyForAyah(surah, ayah);
    return key == null ? null : _notes[key];
  }

  String? noteForSelection(int surah, Iterable<int> ayahs) =>
      _notes[selectionKey(surah, ayahs)];

  String noteSourceForKey(String key) => _noteSources[key] ?? 'RWD';

  String noteSourceForSelection(int surah, Iterable<int> ayahs) =>
      noteSourceForKey(selectionKey(surah, ayahs));

  Future<void> setNote(
    int surah,
    int ayah,
    String text, {
    String sourceCode = 'RWD',
  }) => setNoteForSelection(surah, <int>[ayah], text, sourceCode: sourceCode);

  Future<void> setNoteForSelection(
    int surah,
    Iterable<int> ayahs,
    String text, {
    String sourceCode = 'RWD',
  }) async {
    final key = selectionKey(surah, ayahs);
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _notes.remove(key);
      _noteSources.remove(key);
      _removeArchiveTime('note', key);
    } else {
      _notes[key] = trimmed;
      _noteSources[key] = sourceCode;
      _touchArchive('note', key);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_notesKey, jsonEncode(_notes)),
      prefs.setString(_noteSourcesKey, jsonEncode(_noteSources)),
      prefs.setString(_archiveTimesKey, jsonEncode(_archiveTimes)),
    ]);
  }

  VerseHighlightColor? highlightFor(int surah, int ayah) {
    String? stored;
    for (final entry in _highlights.entries) {
      if (selectionContains(entry.key, surah, ayah)) {
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

  Future<void> setHighlight(int surah, int ayah, VerseHighlightColor? color) =>
      setHighlightForSelection(surah, <int>[ayah], color);

  Future<void> setHighlightForSelection(
    int surah,
    Iterable<int> ayahs,
    VerseHighlightColor? color,
  ) async {
    final selected = ayahs.toSet().toList()..sort();
    if (selected.isEmpty) return;

    final removed = _highlights.keys
        .where(
          (key) => selected.any((ayah) => selectionContains(key, surah, ayah)),
        )
        .toList(growable: false);
    for (final key in removed) {
      _highlights.remove(key);
      _removeArchiveTime('highlight', key);
    }

    if (color != null) {
      final key = selectionKey(surah, selected);
      _highlights[key] = color.name;
      _touchArchive('highlight', key);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_highlightsKey, jsonEncode(_highlights)),
      prefs.setString(_archiveTimesKey, jsonEncode(_archiveTimes)),
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
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope bulunamadı.');
    return scope!.notifier!;
  }
}
