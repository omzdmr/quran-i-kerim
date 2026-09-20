import 'package:shared_preferences/shared_preferences.dart';

import 'backup_manifest.dart';

/// Explicit SharedPreferences adapter used by backup/restore.
///
/// Only keys listed here, or keys under an explicitly allowed dynamic prefix,
/// can leave the device. Unknown preferences, downloaded content, caches and
/// exact prayer-location coordinates are intentionally ignored.
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
    'memorization_target_v1',
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
    'home_quick_actions_v1',
  };

  static const Set<String> dhikrKeys = <String>{
    'dhikr_v2_selected',
    'dhikr_v2_counts',
    'dhikr_v2_targets',
    'dhikr_v2_custom',
    'dhikr_v2_daily_counts',
    'dhikr_v2_daily_date',
  };

  static const Set<String> readingPlanKeys = <String>{
    'reading_plan_state_v1',
  };

  /// Prayer behavior that is useful across devices but does not reveal an
  /// exact or manually selected location. City/GPS/manual-location storage is
  /// deliberately excluded because those records can contain coordinates.
  static const Set<String> prayerPreferenceKeys = <String>{
    'prayer_method_override',
    'prayer_asr_method',
    'prayer_high_latitude_method',
    'prayer_adjustment_fajr',
    'prayer_adjustment_sunrise',
    'prayer_adjustment_dhuhr',
    'prayer_adjustment_asr',
    'prayer_adjustment_maghrib',
    'prayer_adjustment_isha',
    'prayer_notifications_enabled',
    'prayer_notification_ids',
    'prayer_hijri_offset',
  };

  static const Set<String> excludedPrayerLocationKeys = <String>{
    'prayer_city_id',
    'prayer_device_latitude',
    'prayer_device_longitude',
    'prayer_device_timezone',
    'prayer_device_method',
    'prayer_device_region',
    'prayer_manual_source_id',
    'prayer_manual_label',
    'prayer_manual_country',
    'prayer_manual_latitude',
    'prayer_manual_longitude',
    'prayer_manual_timezone',
    'prayer_manual_method',
    'prayer_manual_region',
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
        'learning': <String>{},
        'dhikr': dhikrKeys,
        'prayerPreferences': prayerPreferenceKeys,
        'readingPlans': readingPlanKeys,
      };

  static const Map<String, Set<String>> dynamicPrefixesBySection =
      <String, Set<String>>{
        'learning': <String>{'learn_progress_v1:'},
      };

  static const Set<String> includedKeys = <String>{
    ...readingKeys,
    ...bookmarkKeys,
    ...noteKeys,
    ...highlightKeys,
    ...memorizationKeys,
    ...memorizationPracticeKeys,
    ...preferenceKeys,
    ...dhikrKeys,
    ...prayerPreferenceKeys,
    ...readingPlanKeys,
  };

  Future<Map<String, Object?>> capture() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, Object?>{
      for (final key in includedKeys)
        if (prefs.containsKey(key)) key: _copyValue(prefs.get(key)),
    };
    for (final key in prefs.getKeys()) {
      if (_matchesCurrentDynamicKey(key)) {
        result[key] = _copyValue(prefs.get(key));
      }
    }
    return Map<String, Object?>.unmodifiable(result);
  }

  Future<Map<String, Object?>> captureSections() async {
    final flat = await capture();
    final sections = <String, Object?>{};
    for (final section in BackupManifest.includedSections) {
      final fixedKeys = keysBySection[section] ?? const <String>{};
      final prefixes = dynamicPrefixesBySection[section] ?? const <String>{};
      sections[section] = Map<String, Object?>.unmodifiable(
        <String, Object?>{
          for (final entry in flat.entries)
            if (fixedKeys.contains(entry.key) ||
                prefixes.any((prefix) => entry.key.startsWith(prefix)))
              entry.key: entry.value,
        },
      );
    }
    return Map<String, Object?>.unmodifiable(sections);
  }

  Future<void> restore(Map<String, Object?> snapshot) async {
    await _restoreFlat(snapshot, schemaVersion: BackupManifest.schemaVersion);
  }

  Future<void> restoreSections(
    Map<String, Object?> sections, {
    int schemaVersion = BackupManifest.schemaVersion,
  }) async {
    if (!BackupManifest.isVersionSupported(schemaVersion)) {
      throw FormatException('Unsupported backup schema version: $schemaVersion');
    }

    final flat = <String, Object?>{};
    for (final section in BackupManifest.sectionsForVersion(schemaVersion)) {
      final rawSection = sections[section];
      if (rawSection == null) continue;
      if (rawSection is! Map) {
        throw FormatException('Invalid backup section: $section');
      }
      final fixedKeys = _fixedKeysForSection(section, schemaVersion);
      final prefixes = _dynamicPrefixesForSection(section, schemaVersion);
      for (final entry in rawSection.entries) {
        if (entry.key is! String) {
          throw FormatException('Invalid backup key in $section');
        }
        final key = entry.key as String;
        if (fixedKeys.contains(key) ||
            prefixes.any((prefix) => key.startsWith(prefix))) {
          flat[key] = entry.value;
        }
      }
    }
    await _restoreFlat(flat, schemaVersion: schemaVersion);
  }

  Future<void> _restoreFlat(
    Map<String, Object?> snapshot, {
    required int schemaVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final managedKeys = <String>{};
    for (final section in BackupManifest.sectionsForVersion(schemaVersion)) {
      final fixedKeys = _fixedKeysForSection(section, schemaVersion);
      final prefixes = _dynamicPrefixesForSection(section, schemaVersion);
      managedKeys.addAll(fixedKeys);
      if (prefixes.isNotEmpty) {
        managedKeys.addAll(
          prefs.getKeys().where(
            (key) => prefixes.any((prefix) => key.startsWith(prefix)),
          ),
        );
        managedKeys.addAll(
          snapshot.keys.where(
            (key) => prefixes.any((prefix) => key.startsWith(prefix)),
          ),
        );
      }
    }

    for (final key in managedKeys) {
      if (!snapshot.containsKey(key)) {
        await prefs.remove(key);
        continue;
      }
      await _writeValue(prefs, key, snapshot[key]);
    }
  }

  Set<String> _fixedKeysForSection(String section, int schemaVersion) {
    var keys = keysBySection[section] ?? const <String>{};
    if (schemaVersion == 1 && section == 'memorization') {
      keys = keys.where((key) => key != 'memorization_target_v1').toSet();
    }
    if (schemaVersion <= 4 && section == 'preferences') {
      keys = keys.where((key) => key != 'home_quick_actions_v1').toSet();
    }
    return keys;
  }

  Set<String> _dynamicPrefixesForSection(String section, int schemaVersion) {
    if (schemaVersion == 1) return const <String>{};
    return dynamicPrefixesBySection[section] ?? const <String>{};
  }

  bool _matchesCurrentDynamicKey(String key) {
    for (final prefixes in dynamicPrefixesBySection.values) {
      if (prefixes.any((prefix) => key.startsWith(prefix))) return true;
    }
    return false;
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
