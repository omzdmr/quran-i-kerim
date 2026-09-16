import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'backup_preview.dart';
import 'local_backup_service.dart';

typedef BackupDirectoryProvider = Future<Directory> Function();

/// Stores user-owned backup JSON files without involving a backend.
///
/// Export uses an atomic temp-file rename so an interrupted write does not
/// leave a half-written backup at the final path. Import is size-limited before
/// JSON parsing to avoid loading an unexpectedly large file into memory.
class BackupFileService {
  BackupFileService({
    this.backupService = const LocalBackupService(),
    BackupDirectoryProvider? directoryProvider,
    this.maxImportBytes = 8 * 1024 * 1024,
  }) : _directoryProvider =
           directoryProvider ?? getApplicationDocumentsDirectory;

  final LocalBackupService backupService;
  final BackupDirectoryProvider _directoryProvider;
  final int maxImportBytes;

  Future<File> exportToFile({DateTime? now}) async {
    final createdAt = (now ?? DateTime.now()).toUtc();
    final encoded = await backupService.exportJson(now: createdAt);
    final root = await _directoryProvider();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}quran_backups',
    );
    await directory.create(recursive: true);

    final stamp = createdAt
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll('.', '');
    final target = File(
      '${directory.path}${Platform.pathSeparator}quran-backup-$stamp.json',
    );
    final temporary = File(
      '${target.path}.tmp-${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      await temporary.writeAsString(encoded, flush: true);
      return await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<BackupPreview> previewFile(File file) async {
    final encoded = await _readImport(file);
    return backupService.previewJson(encoded);
  }

  Future<void> restoreFile(File file) async {
    final encoded = await _readImport(file);
    await backupService.restoreJson(encoded);
  }

  Future<String> _readImport(File file) async {
    if (maxImportBytes <= 0) {
      throw ArgumentError.value(maxImportBytes, 'maxImportBytes', 'must be > 0');
    }
    if (!await file.exists()) {
      throw FileSystemException('Backup file does not exist.', file.path);
    }
    final length = await file.length();
    if (length > maxImportBytes) {
      throw FormatException(
        'Backup file exceeds the $maxImportBytes byte import limit.',
      );
    }
    return file.readAsString();
  }
}
