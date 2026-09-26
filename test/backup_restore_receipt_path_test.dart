import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('managed-prefix path with parent traversal is not accepted as an undo snapshot', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 2});
    final root = await Directory.systemTemp.createTemp('quran_receipt_path_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final managed = Directory('${root.path}${Platform.pathSeparator}quran_backups');
    final outside = Directory('${root.path}${Platform.pathSeparator}outside');
    await managed.create();
    await outside.create();
    final outsideFile = File('${outside.path}${Platform.pathSeparator}quran-safety-before-restore-forged.json');
    await outsideFile.writeAsString('{}');
    final traversingPath = File(
      '${managed.path}${Platform.pathSeparator}..${Platform.pathSeparator}outside${Platform.pathSeparator}quran-safety-before-restore-forged.json',
    );
    final receipt = BackupRestoreReceipt(
      mode: BackupRestoreMode.replace,
      safetySnapshot: traversingPath,
      restoredAt: DateTime.parse('2026-09-22T00:00:00Z'),
    );
    final service = BackupFileService(directoryProvider: () async => root);

    await expectLater(service.undoRestore(receipt), throwsFormatException);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
  });
}