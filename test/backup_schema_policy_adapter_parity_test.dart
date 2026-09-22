import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_schema_key_policy.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const adapter = SharedPreferencesBackupAdapter();

  Future<bool> adapterAccepts(String section, String key, int version) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await adapter.restoreSections(
      <String, Object?>{
        section: <String, Object?>{key: 'probe'},
      },
      schemaVersion: version,
    );
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  test('versioned validator gates stay in lockstep with adapter migrations', () async {
    final cases = <(String, String, int)>[
      ('memorization', 'memorization_target_v1', 1),
      ('memorization', 'memorization_target_v1', 2),
      ('preferences', 'home_quick_actions_v1', 4),
      ('preferences', 'home_quick_actions_v1', 5),
      ('preferences', 'reader_experience_preset_v1', 5),
      ('preferences', 'reader_experience_preset_v1', 6),
      ('preferences', 'reader_auto_scroll_speed_v1', 6),
      ('preferences', 'reader_auto_scroll_speed_v1', 7),
      ('preferences', 'offline_audio_pack_intents_v1', 7),
      ('preferences', 'offline_audio_pack_intents_v1', 8),
    ];

    for (final (section, key, version) in cases) {
      expect(
        await adapterAccepts(section, key, version),
        BackupSchemaKeyPolicy.supportsKey(section, key, version),
        reason: 'schema v$version $section/$key',
      );
    }
  });

  test('dynamic learning prefix parity starts at schema v2', () async {
    const key = 'learn_progress_v1:contract-probe';
    for (final version in <int>[1, 2]) {
      expect(
        await adapterAccepts('learning', key, version),
        BackupSchemaKeyPolicy.supportsKey('learning', key, version),
        reason: 'schema v$version dynamic learning key',
      );
    }
  });
}
