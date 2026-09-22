import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('old undo receipt cannot erase changes made after restore', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
    });
    final tempRoot = await Directory.systemTemp.createTemp('quran_stale_undo_');
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });
    final service = BackupFileService(directoryProvider: () async => tempRoot);
    final incoming = jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36, 'last_ayah': 58},
      },
    });

    final receipt = await service.restoreEncoded(incoming);
    expect(receipt.postRestoreSignature, isNotNull);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_surah', 18); // a real user change after restore

    await expectLater(service.undoRestore(receipt), throwsStateError);
    expect(prefs.getInt('last_surah'), 18);
    expect(prefs.getInt('last_ayah'), 58);
    expect(await receipt.safetySnapshot.exists(), isTrue,
        reason: 'Safety copy remains available for an explicit manual restore.');
  });

  test('immediate undo still succeeds when nothing changed after restore', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
    });
    final tempRoot = await Directory.systemTemp.createTemp('quran_fresh_undo_');
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });
    final service = BackupFileService(directoryProvider: () async => tempRoot);
    final incoming = jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36},
      },
    });

    final receipt = await service.restoreEncoded(incoming);
    await service.undoRestore(receipt);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getInt('last_ayah'), 255);
  });
}