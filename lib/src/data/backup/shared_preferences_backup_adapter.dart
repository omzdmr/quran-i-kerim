import 'package:shared_preferences/shared_preferences.dart';

/// Explicit SharedPreferences adapter used by backup/restore.
///
/// Only keys listed here can leave the device. Unknown preferences, downloaded
/// content and caches are intentionally ignored.
class SharedPreferencesBackupAdapter {
  const SharedPreferencesBackupAdapter();

  static const Set<String> readingKeys = <String>{
    'last_surah',
    'last_ayah',
    'reading_days',
    'reader_history_v1',
    'archive_times',
  };

  static const Set<String> bookmarkKeys = <String>{'bookmarks'};

  static const Set<String> noteKeys = <String>{
    'verse_notes',
    'verse_note_sources',
  };

  static const Set<String> highlightKeys = <String>{'verse_highlights'};

  static const Set<String> memorizationKeys = <String>{
    'memorized_pages_v1',
    'memorization_practice_days_v1',
    'memorization_page_progress_v1',
    'memorization_plan_pace_v1',
    'memorization_plan_started_at_v1',
    'memorization_plan_missed_days_v1',
    'memorization_recall_history_v1',
  };

  static const Set<String> memorizationPracticeKeys = <String>{
    'memorization_practice_history_v1',
  };

  static const Set<String> preferenceKeys = <String>{
    'theme_mode',
    'app_locale',
    'selected_quran_source',
    'quran_source_user_selected_v1',
    'reader_line_spacing',
    'reader_text_size',
    'selected_audio_by_source_v1',
    'selected_audio_bitrate_v1',
    'audio_download_wifi_only_v1',
    'audio_download_ask_mobile_v1',
    'audio_after_surah_v1',
  };

  static const Map<String, Set<String>> keysBySection =
      <String, Set<String>>{
        'reading': readingKeys,
        'bookmarks': bookmarkKeys,
        'notes': noteKeys,
        'highlights': highlightKeys,
        'memorization': memorizationKeys,
        'memorizationPractice': memorizationPracticeKeys,
        'preferences': preferenceKeys,
      };

  static const Set<String> includedKeys = <String>{
    ...readingKeys,
    ...bookmarkKeys,
    ...noteKeys,
    ...highlightKeys,
    ...memorizationKeys,
    ...memorizationPracticeKeys,
    ...preferenceKeys,
  };

  Future<Map<String, Object?>> capture() async {
    final prefs = await SharedPreferences.getInstance();
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final key in includedKeys)
        if (prefs.containsKey(key)) key: _copyValue(prefs.get(key)),
    });
  }

  Future<Map<String, Object?>> captureSections() async {
    final flat = await capture();
    final sections = <String, Object?>{};
    for (final section in keysBySection.entries) {
      sections[section.key] = Map<String, Object?>.unmodifiable(
        <String, Object?>{
          for (final key in section.value)
            if (flat.containsKey(key)) key: flat[key],
        },
      );
    }
    return Map<String, Object?>.unmodifiable(sections);
  }

  Future<void> restore(Map<String, Object?> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in includedKeys) {
      if (!snapshot.containsKey(key)) {
        await prefs.remove(key);
        continue;
      }
      await _writeValue(prefs, key, snapshot[key]);
    }
  }

  Future<void> restoreSections(Map<String, Object?> sections) async {
    final flat = <String, Object?>{};
    for (final section in keysBySection.entries) {
      final rawSection = sections[section.key];
      if (rawSection == null) continue;
      if (rawSection is! Map) {
        throw FormatException('Invalid backup section: ${section.key}');
      }
      for (final entry in rawSection.entries) {
        if (entry.key is! String) {
          throw FormatException('Invalid backup key in ${section.key}');
        }
        final key = entry.key as String;
        if (section.value.contains(key)) {
          flat[key] = entry.value;
        }
      }
    }
    await restore(flat);
  }

  Object? _copyValue(Object? value) {
    if (value is List<String>) return List<String>.unmodifiable(value);
    return value;
  }

  Future<void> _writeValue(
    SharedPreferences prefs,
    String key,
    Object? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is List && value.every((item) => item is String)) {
      await prefs.setStringList(key, value.cast<String>());
    } else {
      throw FormatException('Unsupported backup preference type for $key');
    }
  }
}
