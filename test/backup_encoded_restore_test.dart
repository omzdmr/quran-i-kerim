import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
    });
    tempRoot = await Directory.systemTemp.createTemp('quran_encoded_restore_');
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  String payload({String? note}) => jsonEncode(<String, Object?>{
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-22T00:00:00Z',
        'data': <String, Object?>{
          'reading': <String, Object?>{'last_surah': 36},
          if (note != null) 'preferences': <String, Object?>{'test_note': note},
        },
      });

  test('encoded restore uses the same safety snapshot and undo path as file restore', () async {
    final service = BackupFileService(directoryProvider: () async => tempRoot);
    final receipt = await service.restoreEncoded(
      payload(),
      mode: BackupRestoreMode.replace,
      now: DateTime.parse('2026-09-22T02:00:00Z'),
    );

    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.containsKey('last_ayah'), isFalse);
    expect(await receipt.safetySnapshot.exists(), isTrue);

    await service.undoRestore(receipt);
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getInt('last_ayah'), 255);
  });

  test('encoded restore enforces UTF-8 bytes rather than Dart character count', () async {
    final encoded = payload(note: 'éééééééééé');
    final charLength = encoded.length;
    final byteLength = utf8.encode(encoded).length;
    expect(byteLength, greaterThan(charLength));

    final service = BackupFileService(
      directoryProvider: () async => tempRoot,
      maxImportBytes: charLength,
    );
    await expectLater(service.restoreEncoded(encoded), throwsFormatException);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(await service.listBackupFiles(), isEmpty,
        reason: 'Oversized payload must be rejected before a safety snapshot is written.');
  });
}