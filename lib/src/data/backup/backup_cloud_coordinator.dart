import 'dart:convert';

import 'backup_cloud_store.dart';
import 'backup_document.dart';
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

/// Coordinates cloud backup without silently choosing a winner.
///
/// The local and remote payloads are compared using only their `data` section;
/// `createdAt` is intentionally ignored so a freshly generated local envelope
/// does not look newer when the underlying user data is unchanged. If data
/// differs, the coordinator reports [BackupCloudState.diverged] and requires
/// the caller to make an explicit choice before overwriting either side.
class BackupCloudCoordinator {
  const BackupCloudCoordinator({
    required this.store,
    this.localBackupService = const LocalBackupService(),
  });

  final BackupCloudStore store;
  final LocalBackupService localBackupService;

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

  Future<void> restoreRemote(BackupCloudInspection inspection) async {
    final remote = inspection.remote;
    if (remote == null) {
      throw StateError('There is no remote backup to restore.');
    }
    if (!inspection.canRestoreRemote) {
      throw const FormatException('Remote backup is not restorable.');
    }
    await localBackupService.restoreJson(remote.content);
  }

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
