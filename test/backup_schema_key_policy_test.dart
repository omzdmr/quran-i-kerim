import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/backup_schema_key_policy.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';

void main() {
  test('current schema accepts every fixed key exported by the adapter', () {
    for (final section in SharedPreferencesBackupAdapter.keysBySection.entries) {
      for (final key in section.value) {
        expect(
          BackupSchemaKeyPolicy.supportsKey(section.key, key, BackupManifest.schemaVersion),
          isTrue,
          reason: '${section.key}/$key',
        );
      }
    }
  });

  test('current schema accepts every exported dynamic prefix', () {
    for (final section in SharedPreferencesBackupAdapter.dynamicPrefixesBySection.entries) {
      for (final prefix in section.value) {
        expect(
          BackupSchemaKeyPolicy.supportsKey(section.key, '${prefix}sample', BackupManifest.schemaVersion),
          isTrue,
          reason: '${section.key}/$prefix',
        );
      }
    }
  });

  test('legacy version gates match known schema migrations', () {
    expect(BackupSchemaKeyPolicy.supportsKey('memorization', 'memorization_target_v1', 1), isFalse);
    expect(BackupSchemaKeyPolicy.supportsKey('memorization', 'memorization_target_v1', 2), isTrue);
    expect(BackupSchemaKeyPolicy.supportsKey('preferences', 'home_quick_actions_v1', 4), isFalse);
    expect(BackupSchemaKeyPolicy.supportsKey('preferences', 'home_quick_actions_v1', 5), isTrue);
    expect(BackupSchemaKeyPolicy.supportsKey('preferences', 'reader_experience_preset_v1', 5), isFalse);
    expect(BackupSchemaKeyPolicy.supportsKey('preferences', 'reader_experience_preset_v1', 6), isTrue);
    expect(BackupSchemaKeyPolicy.supportsKey('preferences', 'reader_auto_scroll_speed_v1', 6), isFalse);
    expect(BackupSchemaKeyPolicy.supportsKey('preferences', 'reader_auto_scroll_speed_v1', 7), isTrue);
    expect(BackupSchemaKeyPolicy.supportsKey('preferences', 'offline_audio_pack_intents_v1', 7), isFalse);
    expect(BackupSchemaKeyPolicy.supportsKey('preferences', 'offline_audio_pack_intents_v1', 8), isTrue);
  });
}
