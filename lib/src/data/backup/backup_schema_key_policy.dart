import 'shared_preferences_backup_adapter.dart';

/// Read-only schema policy used to validate portable backup keys before a
/// restore can mutate local state. It mirrors the adapter's migration gates so
/// data from a newer schema is never silently discarded under an older one.
class BackupSchemaKeyPolicy {
  const BackupSchemaKeyPolicy._();

  static Set<String> fixedKeysForSection(String section, int schemaVersion) {
    var keys = SharedPreferencesBackupAdapter.keysBySection[section] ?? const <String>{};
    if (schemaVersion == 1 && section == 'memorization') {
      keys = keys.where((key) => key != 'memorization_target_v1').toSet();
    }
    if (schemaVersion <= 4 && section == 'preferences') {
      keys = keys.where((key) => key != 'home_quick_actions_v1').toSet();
    }
    if (schemaVersion <= 5 && section == 'preferences') {
      keys = keys.where((key) => key != 'reader_experience_preset_v1').toSet();
    }
    if (schemaVersion <= 6 && section == 'preferences') {
      keys = keys.where((key) => key != 'reader_auto_scroll_speed_v1').toSet();
    }
    if (schemaVersion <= 7 && section == 'preferences') {
      keys = keys.where((key) => key != 'offline_audio_pack_intents_v1').toSet();
    }
    return keys;
  }

  static Set<String> dynamicPrefixesForSection(String section, int schemaVersion) {
    if (schemaVersion == 1) return const <String>{};
    return SharedPreferencesBackupAdapter.dynamicPrefixesBySection[section] ?? const <String>{};
  }

  static bool supportsKey(String section, String key, int schemaVersion) {
    if (fixedKeysForSection(section, schemaVersion).contains(key)) return true;
    return dynamicPrefixesForSection(section, schemaVersion)
        .any((prefix) => key.startsWith(prefix));
  }
}
