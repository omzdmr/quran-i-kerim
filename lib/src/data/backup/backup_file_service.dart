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
    this.postRestoreSignature,
  });

  final BackupRestoreMode mode;
  final File safetySnapshot;
  final DateTime restoredAt;
  final String? postRestoreSignature;
}

class BackupPreparedImport {
  const BackupPreparedImport._({
    required this.preview,
    required this.plan,
    required String encoded,
  }) : _encoded = encoded;

  final BackupPreview preview;
  final BackupImportPlan plan;
  final String _encoded;
}

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

  /// Reads a user-selected file once and binds its preview + import plan to the
  /// exact bytes that will later be restored. An external provider changing the
  /// file while the confirmation dialog is open can no longer make the app
  /// restore content different from what the user reviewed.
  Future<BackupPreparedImport> prepareFile(File file) async {
    final encoded = await _readImport(file);
    final preview = backupService.previewJson(encoded);
    if (!preview.canRestore) {
      throw const FormatException('Backup is not restorable.');
    }
    final plan = await backupService.planImportJson(encoded);
    return BackupPreparedImport._(
      preview: preview,
      plan: plan,
      encoded: encoded,
    );
  }

  Future<BackupRestoreReceipt> restorePrepared(
    BackupPreparedImport prepared, {
    BackupRestoreMode mode = BackupRestoreMode.replace,
    DateTime? now,
  }) => restoreEncoded(prepared._encoded, mode: mode, now: now);

  Future<BackupRestoreReceipt> restoreFile(
    File file, {
    BackupRestoreMode mode = BackupRestoreMode.replace,
    DateTime? now,
  }) async {
    final encoded = await _readImport(file);
    return restoreEncoded(encoded, mode: mode, now: now);
  }

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

    String? postRestoreSignature;
    try {
      final afterRestore = await backupService.exportJson(now: restoredAt);
      postRestoreSignature = _dataSignature(afterRestore);
    } catch (_) {
      // Restore already succeeded. Fingerprinting is an extra stale-undo guard,
      // never a reason to discard the safety snapshot or report false failure.
    }
    return BackupRestoreReceipt(
      mode: mode,
      safetySnapshot: safetySnapshot,
      restoredAt: restoredAt,
      postRestoreSignature: postRestoreSignature,
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

    final expected = receipt.postRestoreSignature;
    if (expected != null) {
      final current = await backupService.exportJson();
      if (_dataSignature(current) != expected) {
        throw StateError('User data changed after restore; automatic undo is stale.');
      }
    }

    final encoded = await _readImport(snapshot);
    final preview = backupService.previewJson(encoded);
    if (!preview.canRestore) {
      throw const FormatException('Safety snapshot is not restorable.');
    }
    await backupService.restoreJson(encoded, mode: BackupRestoreMode.replace);
  }

  String _dataSignature(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) return '';
    return jsonEncode(_canonicalize(decoded['data']));
  }

  Object? _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.whereType<String>().toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    if (value is List) {
      return <Object?>[for (final item in value) _canonicalize(item)];
    }
    return value;
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