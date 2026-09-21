import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('merge keeps local keys absent from import and applies imported keys', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'last_ayah': 4,
      'theme_mode': 'dark',
      'unrelated': 'never managed by backup',
    });

    await service.restoreDecoded(
      <String, Object?>{
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-21T14:00:00Z',
        'data': <String, Object?>{
          'reading': <String, Object?>{'last_surah': 36},
          'preferences': <String, Object?>{},
        },
      },
      mode: BackupRestoreMode.merge,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getInt('last_ayah'), 4);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('unrelated'), 'never managed by backup');
  });

  test('replace removes managed keys that are absent from import', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'last_ayah': 4,
      'theme_mode': 'dark',
      'unrelated': 'never managed by backup',
    });

    await service.restoreDecoded(
      <String, Object?>{
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-21T14:00:00Z',
        'data': <String, Object?>{
          'reading': <String, Object?>{'last_surah': 36},
          'preferences': <String, Object?>{},
        },
      },
      mode: BackupRestoreMode.replace,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.containsKey('last_ayah'), isFalse);
    expect(prefs.containsKey('theme_mode'), isFalse);
    expect(prefs.getString('unrelated'), 'never managed by backup');
  });
}
