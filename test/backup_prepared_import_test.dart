import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restorePrepared applies exactly the bytes that produced the preview', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
    });
    final tempRoot = await Directory.systemTemp.createTemp('quran_prepared_import_');
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });
    final service = BackupFileService(directoryProvider: () async => tempRoot);
    final selected = File('${tempRoot.path}${Platform.pathSeparator}selected.json');
    await selected.writeAsString(_backup(surah: 36));

    final prepared = await service.prepareFile(selected);
    expect(prepared.preview.canRestore, isTrue);

    // Simulate an external Files/cloud provider replacing the selected path
    // while the confirmation dialog is open.
    await selected.writeAsString(_backup(surah: 18));
    await service.restorePrepared(prepared, mode: BackupRestoreMode.replace);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36,
        reason: 'Restore must match the content the user actually previewed.');
    expect(prefs.containsKey('last_ayah'), isFalse);
  });

  test('invalid selected file cannot create a prepared restore', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 2});
    final tempRoot = await Directory.systemTemp.createTemp('quran_prepared_invalid_');
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });
    final selected = File('${tempRoot.path}${Platform.pathSeparator}broken.json');
    await selected.writeAsString('{broken');
    final service = BackupFileService(directoryProvider: () async => tempRoot);

    await expectLater(service.prepareFile(selected), throwsFormatException);
    expect(await service.listBackupFiles(), isEmpty);
  });
}

String _backup({required int surah}) => jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': surah},
      },
    });