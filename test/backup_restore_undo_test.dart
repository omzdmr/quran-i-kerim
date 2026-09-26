import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tempRoot = await Directory.systemTemp.createTemp('quran_restore_undo_');
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  BackupFileService service() => BackupFileService(
        directoryProvider: () async => tempRoot,
      );

  Future<File> importFile(Map<String, Object?> data) async {
    final file = File('${tempRoot.path}${Platform.pathSeparator}incoming.json');
    await file.writeAsString(jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': data,
    }));
    return file;
  }

  test('undo restore returns exact pre-restore preferences without creating a snapshot chain', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'theme_mode': 'dark',
    });
    final fileService = service();
    final incoming = await importFile(<String, Object?>{
      'reading': <String, Object?>{'last_surah': 36},
      'preferences': <String, Object?>{'theme_mode': 'light'},
    });

    final receipt = await fileService.restoreFile(
      incoming,
      mode: BackupRestoreMode.replace,
      now: DateTime.parse('2026-09-22T01:00:00Z'),
    );
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.containsKey('last_ayah'), isFalse);
    expect(prefs.getString('theme_mode'), 'light');
    expect(await fileService.listBackupFiles(), hasLength(1));

    await fileService.undoRestore(receipt);
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getInt('last_ayah'), 255);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(await fileService.listBackupFiles(), hasLength(1));
  });

  test('undo works after a merge restore and removes incoming-only state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'theme_mode': 'dark',
    });
    final fileService = service();
    final incoming = await importFile(<String, Object?>{
      'reading': <String, Object?>{'last_surah': 18},
      'preferences': <String, Object?>{'app_locale': 'fr'},
    });

    final receipt = await fileService.restoreFile(incoming, mode: BackupRestoreMode.merge);
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 18);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('app_locale'), 'fr');

    await fileService.undoRestore(receipt);
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.containsKey('app_locale'), isFalse);
  });

  test('undo rejects a receipt that points outside the managed backup directory', () async {
    final outside = File('${tempRoot.path}${Platform.pathSeparator}quran-safety-before-restore-forged.json');
    await outside.writeAsString('{}');
    final receipt = BackupRestoreReceipt(
      mode: BackupRestoreMode.replace,
      safetySnapshot: outside,
      restoredAt: DateTime.parse('2026-09-22T01:00:00Z'),
    );

    await expectLater(service().undoRestore(receipt), throwsFormatException);
  });

  test('undo rejects a deleted safety snapshot without changing current state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 2});
    final fileService = service();
    final incoming = await importFile(<String, Object?>{
      'reading': <String, Object?>{'last_surah': 36},
    });
    final receipt = await fileService.restoreFile(incoming);
    await receipt.safetySnapshot.delete();

    await expectLater(fileService.undoRestore(receipt), throwsA(isA<FileSystemException>()));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
  });
}
