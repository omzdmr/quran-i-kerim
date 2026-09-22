import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'backup_import_plan.dart';
import 'backup_preview.dart';
import 'local_backup_service.dart';
export 'local_backup_service.dart' show BackupRestoreMode;

typedef BackupDirectoryProvider = Future<Directory> Function();

class BackupRestoreReceipt {
  const BackupRestoreReceipt({
    required this.mode,
    required this.safetySnapshot,
    required this.restoredAt,
  });

  final BackupRestoreMode mode;
  final File safetySnapshot;
  final DateTime restoredAt;
}

/// Stores user-owned backup JSON files without involving a backend.
///
/// Export uses an atomic temp-file rename so an interrupted write does not
/// leave a half-written backup at the final path. Import is size-limited before
/// JSON parsing to avoid loading an unexpectedly large file into memory.
/// Every user-triggered restore also writes a pre-restore safety snapshot so a
/// successful but unwanted restore can be reversed without a server/account.
class BackupFileService {
  BackupFileService({
    this.backupService = const LocalBackupService(),
    BackupDirectoryProvider? directoryProvider,
    this.maxImportBytes = 8 * 1024 * 1024,
  }) : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  final LocalBackupService backupService;
  final BackupDirectoryProvider _directoryProvider;
  final int maxImportBytes;

  Future<File> exportToFile({DateTime? now}) async {
    final createdAt = (now ?? DateTime.now()).toUtc();
    final encoded = await backupService.exportJson(now: createdAt);
    return _writeBackup(encoded, createdAt: createdAt, prefix: 'quran-backup');
  }

  Future<List<File>> listBackupFiles() async {
    final directory = await _backupDirectory(create: false);
    if (!await directory.exists()) return const <File>[];

    final files = await directory
        .list(followLinks: false)
        .where((entry) => entry is File && _isManagedBackup(entry.path))
        .cast<File>()
        .toList();
    files.sort((a, b) => _fileName(b.path).compareTo(_fileName(a.path)));
    return List<File>.unmodifiable(files);
  }

  Future<BackupPreview> previewFile(File file) async {
    final encoded = await _readImport(file);
    return backupService.previewJson(encoded);
  }

  Future<BackupImportPlan> planImportFile(File file) async {
    final encoded = await _readImport(file);
    return backupService.planImportJson(encoded);
  }

  Future<BackupRestoreReceipt> restoreFile(
    File file, {
    BackupRestoreMode mode = BackupRestoreMode.replace,
    DateTime? now,
  }) async {
    final encoded = await _readImport(file);
    return restoreEncoded(encoded, mode: mode, now: now);
  }

  /// Restores a validated backup payload that came from a trusted app-owned
  /// transport such as the user's private cloud file. The same pre-restore
  /// safety snapshot and rollback contract as file import is applied, so cloud
  /// restore is not a less-safe path than local file restore.
  Future<BackupRestoreReceipt> restoreEncoded(
    String encoded, {
    BackupRestoreMode mode = BackupRestoreMode.replace,
    DateTime? now,
  }) async {
    if (maxImportBytes <= 0) {
      throw ArgumentError.value(maxImportBytes, 'maxImportBytes', 'must be > 0');
    }
    if (utf8.encode(encoded).length > maxImportBytes) {
      throw FormatException('Backup payload exceeds the $maxImportBytes byte import limit.');
    }
    final preview = backupService.previewJson(encoded);
    if (!preview.canRestore) {
      throw const FormatException('Backup is not restorable.');
    }

    final restoredAt = (now ?? DateTime.now()).toUtc();
    final beforeRestore = await backupService.exportJson(now: restoredAt);
    final safetySnapshot = await _writeBackup(
      beforeRestore,
      createdAt: restoredAt,
      prefix: 'quran-safety-before-restore',
    );

    try {
      await backupService.restoreJson(encoded, mode: mode);
    } catch (_) {
      if (await safetySnapshot.exists()) await safetySnapshot.delete();
      rethrow;
    }

    return BackupRestoreReceipt(
      mode: mode,
      safetySnapshot: safetySnapshot,
      restoredAt: restoredAt,
    );
  }

  Future<void> undoRestore(BackupRestoreReceipt receipt) async {
    final snapshot = receipt.safetySnapshot;
    final managedDirectory = await _backupDirectory(create: false);
    final managedPath = managedDirectory.absolute.path;
    final snapshotPath = snapshot.absolute.path;
    final separator = Platform.pathSeparator;
    if (!snapshotPath.startsWith('$managedPath$separator') ||
        !_fileName(snapshotPath).startsWith('quran-safety-before-restore-')) {
      throw const FormatException('Restore receipt does not reference a managed safety snapshot.');
    }

    final encoded = await _readImport(snapshot);
    final preview = backupService.previewJson(encoded);
    if (!preview.canRestore) {
      throw const FormatException('Safety snapshot is not restorable.');
    }

    await backupService.restoreJson(encoded, mode: BackupRestoreMode.replace);
  }

  Future<Directory> _backupDirectory({required bool create}) async {
    final root = await _directoryProvider();
    final directory = Directory('${root.path}${Platform.pathSeparator}quran_backups');
    if (create) await directory.create(recursive: true);
    return directory;
  }

  Future<File> _writeBackup(
    String encoded, {
    required DateTime createdAt,
    required String prefix,
  }) async {
    final directory = await _backupDirectory(create: true);
    final stamp = createdAt
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll('.', '');
    final target = File('${directory.path}${Platform.pathSeparator}$prefix-$stamp.json');
    final temporary = File('${target.path}.tmp-${DateTime.now().microsecondsSinceEpoch}');
    try {
      await temporary.writeAsString(encoded, flush: true);
      return await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
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
      throw FormatException('Backup file exceeds the $maxImportBytes byte import limit.');
    }
    return file.readAsString();
  }

  bool _isManagedBackup(String path) {
    final name = _fileName(path);
    return name.endsWith('.json') &&
        (name.startsWith('quran-backup-') || name.startsWith('quran-safety-before-restore-'));
  }

  String _fileName(String path) => path.split(Platform.pathSeparator).last;
}