import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tempRoot = await Directory.systemTemp.createTemp('quran_backup_test_');
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  BackupFileService service({int maxImportBytes = 8 * 1024 * 1024}) {
    return BackupFileService(
      directoryProvider: () async => tempRoot,
      maxImportBytes: maxImportBytes,
    );
  }

  test('exports an atomic current-schema JSON file', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'dhikr_v2_selected': 'subhanallah',
    });

    final file = await service().exportToFile(
      now: DateTime.parse('2026-09-16T18:00:00+08:00'),
    );

    expect(await file.exists(), isTrue);
    expect(file.path, contains('quran_backups'));
    expect(file.path, endsWith('.json'));
    final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(decoded['version'], 3);
    expect(decoded['createdAt'], '2026-09-16T10:00:00.000Z');
    expect(file.parent.listSync().whereType<File>(), hasLength(1));
    expect(file.parent.listSync().any((entry) => entry.path.contains('.tmp-')), isFalse);
  });

  test('lists only local backup files newest first', () async {
    final fileService = service();
    final older = await fileService.exportToFile(
      now: DateTime.parse('2026-09-15T10:00:00Z'),
    );
    final newer = await fileService.exportToFile(
      now: DateTime.parse('2026-09-16T10:00:00Z'),
    );
    await File(
      '${newer.parent.path}${Platform.pathSeparator}unrelated.json',
    ).writeAsString('{}');
    await File(
      '${newer.parent.path}${Platform.pathSeparator}quran-backup-ignore.tmp',
    ).writeAsString('{}');

    final files = await fileService.listBackupFiles();

    expect(files.map((file) => file.path), <String>[newer.path, older.path]);
  });

  test('previews and restores a selected local backup file', () async {
    final input = File('${tempRoot.path}${Platform.pathSeparator}import.json');
    await input.writeAsString(jsonEncode(<String, Object?>{
      'version': 3,
      'createdAt': '2026-09-16T10:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36, 'last_ayah': 58},
        'dhikr': <String, Object?>{'dhikr_v2_selected': 'alhamdulillah'},
      },
    }));

    final fileService = service();
    final preview = await fileService.previewFile(input);
    expect(preview.canRestore, isTrue);
    expect(preview.recordCounts['reading'], 2);

    await fileService.restoreFile(input);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getInt('last_ayah'), 58);
    expect(prefs.getString('dhikr_v2_selected'), 'alhamdulillah');
  });

  test('rejects oversized imports before parsing JSON', () async {
    final input = File('${tempRoot.path}${Platform.pathSeparator}large.json');
    await input.writeAsString(List<String>.filled(33, 'x').join());

    await expectLater(
      service(maxImportBytes: 32).previewFile(input),
      throwsFormatException,
    );
  });

  test('rejects missing import files without touching preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 9});
    final missing = File('${tempRoot.path}${Platform.pathSeparator}missing.json');

    await expectLater(
      service().restoreFile(missing),
      throwsA(isA<FileSystemException>()),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 9);
  });
}
