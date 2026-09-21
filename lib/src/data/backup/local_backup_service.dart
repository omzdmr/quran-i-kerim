import 'dart:convert';

import 'backup_document.dart';
import 'backup_import_plan.dart';
import 'backup_manifest.dart';
import 'backup_preview.dart';
import 'backup_restore_coordinator.dart';
import 'shared_preferences_backup_adapter.dart';

enum BackupRestoreMode { merge, replace }

class LocalBackupService {
  const LocalBackupService({
    this.adapter = const SharedPreferencesBackupAdapter(),
    this.previewParser = const BackupPreviewParser(),
    this.importPlanner = const BackupImportPlanner(),
    this.restoreCoordinator = const BackupRestoreCoordinator(),
  });

  final SharedPreferencesBackupAdapter adapter;
  final BackupPreviewParser previewParser;
  final BackupImportPlanner importPlanner;
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

  Future<BackupImportPlan> planImportJson(String encoded) async {
    final decoded = jsonDecode(encoded);
    final incoming = _validatedSections(decoded);
    final current = await adapter.captureSections();
    return importPlanner.build(
      currentSections: current,
      incomingSections: incoming,
    );
  }

  Future<void> restoreJson(
    String encoded, {
    BackupRestoreMode mode = BackupRestoreMode.replace,
  }) async {
    final decoded = jsonDecode(encoded);
    await restoreDecoded(decoded, mode: mode);
  }

  Future<void> restoreDecoded(
    Object? decoded, {
    BackupRestoreMode mode = BackupRestoreMode.replace,
  }) async {
    Map<String, Object?>? normalizedData;
    int? normalizedVersion;

    await restoreCoordinator.restore(
      validate: () async {
        normalizedData = _validatedSections(decoded);
        normalizedVersion = previewParser.parse(decoded).version;
      },
      captureSnapshot: adapter.capture,
      applyRestore: () async {
        var dataToRestore = normalizedData!;
        if (mode == BackupRestoreMode.merge) {
          final current = await adapter.captureSections();
          dataToRestore = _mergeSections(current, normalizedData!);
        }
        await adapter.restoreSections(
          dataToRestore,
          schemaVersion: normalizedVersion!,
        );
      },
      rollback: (snapshot) async {
        if (snapshot is! Map) {
          throw const FormatException('Backup rollback snapshot is invalid.');
        }
        await adapter.restore(Map<String, Object?>.from(snapshot));
      },
    );
  }

  Map<String, Object?> _validatedSections(Object? decoded) {
    final preview = previewParser.parse(decoded);
    if (!preview.canRestore || decoded is! Map || preview.version == null) {
      throw const FormatException('Backup is not restorable.');
    }
    final rawData = decoded['data'];
    if (rawData is! Map) {
      throw const FormatException('Backup data is invalid.');
    }
    final selected = <String, Object?>{};
    for (final entry in rawData.entries) {
      if (entry.key is! String) {
        throw const FormatException('Backup section key is invalid.');
      }
      final section = entry.key as String;
      if (BackupManifest.sectionsForVersion(preview.version!).contains(section)) {
        selected[section] = entry.value;
      }
    }
    return Map<String, Object?>.unmodifiable(selected);
  }

  Map<String, Object?> _mergeSections(
    Map<String, Object?> current,
    Map<String, Object?> incoming,
  ) {
    final merged = <String, Object?>{};
    for (final section in BackupManifest.includedSections) {
      final currentSection = current[section];
      final incomingSection = incoming[section];
      if (currentSection is Map || incomingSection is Map) {
        merged[section] = <String, Object?>{
          if (currentSection is Map)
            for (final entry in currentSection.entries)
              if (entry.key is String) entry.key as String: entry.value,
          if (incomingSection is Map)
            for (final entry in incomingSection.entries)
              if (entry.key is String) entry.key as String: entry.value,
        };
      } else if (incoming.containsKey(section)) {
        merged[section] = incomingSection;
      } else if (current.containsKey(section)) {
        merged[section] = currentSection;
      }
    }
    return Map<String, Object?>.unmodifiable(merged);
  }
}
