import 'dart:convert';

import 'backup_cloud_store.dart';
import 'backup_document.dart';
import 'backup_file_service.dart';
import 'backup_import_plan.dart';
import 'backup_preview.dart';
import 'local_backup_service.dart';

enum BackupCloudState {
  remoteEmpty,
  upToDate,
  diverged,
  invalidRemote,
}

class BackupCloudInspection {
  const BackupCloudInspection({
    required this.state,
    required this.localDocument,
    required this.localJson,
    required this.remote,
  });

  final BackupCloudState state;
  final BackupDocument localDocument;
  final String localJson;
  final BackupCloudObject? remote;

  bool get canRestoreRemote =>
      remote != null && state != BackupCloudState.invalidRemote;
}

class BackupCloudRestorePreparation {
  const BackupCloudRestorePreparation({
    required this.remoteRevision,
    required this.preview,
    required this.plan,
  });

  final String remoteRevision;
  final BackupPreview preview;
  final BackupImportPlan plan;
}

/// Coordinates cloud backup without silently choosing a winner.
class BackupCloudCoordinator {
  BackupCloudCoordinator({
    required this.store,
    LocalBackupService localBackupService = const LocalBackupService(),
    BackupFileService? restoreFileService,
  })  : localBackupService = localBackupService,
        restoreFileService = restoreFileService ??
            BackupFileService(backupService: localBackupService);

  final BackupCloudStore store;
  final LocalBackupService localBackupService;
  final BackupFileService restoreFileService;

  Future<BackupCloudInspection> inspect({DateTime? now}) async {
    final localDocument = await localBackupService.createDocument(now: now);
    final localJson = localDocument.encode();
    final localSignature = _dataSignature(localDocument.toJson());
    final remote = await store.read();

    if (remote == null) {
      return BackupCloudInspection(
        state: BackupCloudState.remoteEmpty,
        localDocument: localDocument,
        localJson: localJson,
        remote: null,
      );
    }

    if (!_payloadWithinLimit(remote.content)) {
      return BackupCloudInspection(
        state: BackupCloudState.invalidRemote,
        localDocument: localDocument,
        localJson: localJson,
        remote: remote,
      );
    }

    final remotePreview = localBackupService.previewJson(remote.content);
    if (!remotePreview.canRestore) {
      return BackupCloudInspection(
        state: BackupCloudState.invalidRemote,
        localDocument: localDocument,
        localJson: localJson,
        remote: remote,
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(remote.content);
    } on FormatException {
      return BackupCloudInspection(
        state: BackupCloudState.invalidRemote,
        localDocument: localDocument,
        localJson: localJson,
        remote: remote,
      );
    }

    final remoteSignature = _dataSignature(decoded);
    final state = remoteSignature == localSignature
        ? BackupCloudState.upToDate
        : BackupCloudState.diverged;

    return BackupCloudInspection(
      state: state,
      localDocument: localDocument,
      localJson: localJson,
      remote: remote,
    );
  }

  Future<BackupCloudRestorePreparation> prepareRemoteRestore(
    BackupCloudInspection inspection,
  ) async {
    final remote = inspection.remote;
    if (remote == null) {
      throw StateError('There is no remote backup to restore.');
    }
    if (!_payloadWithinLimit(remote.content)) {
      throw const FormatException('Remote backup exceeds the import size limit.');
    }
    final preview = localBackupService.previewJson(remote.content);
    if (!inspection.canRestoreRemote || !preview.canRestore) {
      throw const FormatException('Remote backup is not restorable.');
    }
    final plan = await localBackupService.planImportJson(remote.content);
    return BackupCloudRestorePreparation(
      remoteRevision: remote.revision,
      preview: preview,
      plan: plan,
    );
  }

  Future<BackupCloudObject> uploadLocal(
    BackupCloudInspection inspection, {
    bool allowOverwrite = false,
  }) async {
    if (inspection.state == BackupCloudState.upToDate) {
      return inspection.remote!;
    }
    if ((inspection.state == BackupCloudState.diverged ||
            inspection.state == BackupCloudState.invalidRemote) &&
        !allowOverwrite) {
      throw StateError(
        'Remote backup differs. Explicit overwrite permission is required.',
      );
    }

    return store.write(
      content: inspection.localJson,
      expectedRevision: inspection.remote?.revision,
    );
  }

  Future<BackupRestoreReceipt> restoreRemote(
    BackupCloudInspection inspection, {
    BackupRestoreMode mode = BackupRestoreMode.replace,
  }) async {
    final remote = inspection.remote;
    if (remote == null) {
      throw StateError('There is no remote backup to restore.');
    }
    if (!inspection.canRestoreRemote) {
      throw const FormatException('Remote backup is not restorable.');
    }
    return restoreFileService.restoreEncoded(remote.content, mode: mode);
  }

  bool _payloadWithinLimit(String content) =>
      restoreFileService.maxImportBytes > 0 &&
      utf8.encode(content).length <= restoreFileService.maxImportBytes;

  String _dataSignature(Object? decoded) {
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
      return <Object?>[
        for (final item in value) _canonicalize(item),
      ];
    }
    return value;
  }
}