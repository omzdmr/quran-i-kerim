import 'dart:convert';

import 'backup_document.dart';
import 'backup_manifest.dart';
import 'backup_preview.dart';
import 'backup_restore_coordinator.dart';
import 'shared_preferences_backup_adapter.dart';

class LocalBackupService {
  const LocalBackupService({
    this.adapter = const SharedPreferencesBackupAdapter(),
    this.previewParser = const BackupPreviewParser(),
    this.restoreCoordinator = const BackupRestoreCoordinator(),
  });

  final SharedPreferencesBackupAdapter adapter;
  final BackupPreviewParser previewParser;
  final BackupRestoreCoordinator restoreCoordinator;

  Future<BackupDocument> createDocument({DateTime? now}) async {
    final sections = await adapter.captureSections();
    return BackupDocument(
      version: BackupManifest.schemaVersion,
      createdAt: (now ?? DateTime.now()).toUtc(),
      data: BackupManifest.selectBackupData(sections),
    );
  }

  Future<String> exportJson({DateTime? now}) async {
    return (await createDocument(now: now)).encode();
  }

  BackupPreview previewDecoded(Object? decoded) => previewParser.parse(decoded);

  BackupPreview previewJson(String encoded) {
    try {
      return previewParser.parse(jsonDecode(encoded));
    } on FormatException {
      return previewParser.parse(null);
    }
  }

  Future<void> restoreJson(String encoded) async {
    final decoded = jsonDecode(encoded);
    await restoreDecoded(decoded);
  }

  Future<void> restoreDecoded(Object? decoded) async {
    Map<String, Object?>? normalizedData;
    int? normalizedVersion;

    await restoreCoordinator.restore(
      validate: () async {
        final preview = previewParser.parse(decoded);
        if (!preview.canRestore || decoded is! Map || preview.version == null) {
          throw const FormatException('Backup is not restorable.');
        }
        final rawData = decoded['data'];
        if (rawData is! Map) {
          throw const FormatException('Backup data is invalid.');
        }
        normalizedVersion = preview.version;
        final selected = <String, Object?>{};
        for (final entry in rawData.entries) {
          if (entry.key is! String) {
            throw const FormatException('Backup section key is invalid.');
          }
          final section = entry.key as String;
          if (BackupManifest.sectionsForVersion(normalizedVersion!).contains(section)) {
            selected[section] = entry.value;
          }
        }
        normalizedData = Map<String, Object?>.unmodifiable(selected);
      },
      captureSnapshot: adapter.capture,
      applyRestore: () => adapter.restoreSections(
        normalizedData!,
        schemaVersion: normalizedVersion!,
      ),
      rollback: (snapshot) async {
        if (snapshot is! Map) {
          throw const FormatException('Backup rollback snapshot is invalid.');
        }
        await adapter.restore(Map<String, Object?>.from(snapshot));
      },
    );
  }
}
