import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 9, 'last_ayah': 5, 'bookmarks': <String>['2:255']});
  });

  Future<void> expectReadingUntouched() async {
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 9);
    expect(prefs.getInt('last_ayah'), 5);
    expect(prefs.getStringList('bookmarks'), <String>['2:255']);
  }

  test('unknown section aborts replace without touching supported local data', () async {
    final encoded = jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36, 'last_ayah': 1},
        'futureUserData': <String, Object?>{'important': 'must not be dropped'},
      },
    });
    await expectLater(service.restoreJson(encoded, mode: BackupRestoreMode.replace), throwsA(isA<FormatException>()));
    await expectReadingUntouched();
  });

  test('unknown key aborts replace instead of silently dropping user data', () async {
    final encoded = jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{
          'last_surah': 36,
          'future_reader_state': 'must not be dropped',
        },
      },
    });
    await expectLater(service.restoreJson(encoded, mode: BackupRestoreMode.replace), throwsA(isA<FormatException>()));
    await expectReadingUntouched();
  });

  test('section list shape aborts merge without touching local data', () async {
    final encoded = jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{'reading': <Object?>[36, 1]},
    });
    await expectLater(service.restoreJson(encoded, mode: BackupRestoreMode.merge), throwsA(isA<FormatException>()));
    await expectReadingUntouched();
  });
}
