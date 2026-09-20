import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;

import 'backup_cloud_store.dart';

/// Google Drive implementation backed by small append-only snapshots in the
/// private appDataFolder.
///
/// Authentication is injected through [driveApi], keeping OAuth concerns out
/// of the backup domain layer. Writes create a new snapshot instead of
/// destructively replacing the previous blob. This matters because Drive v3
/// exposes a monotonically increasing file version but does not expose that
/// version as an atomic files.update precondition. Concurrent devices can
/// therefore leave two snapshots, but neither silently destroys the other.
class GoogleDriveAppDataBackupStore implements BackupCloudStore {
  GoogleDriveAppDataBackupStore(
    this.driveApi, {
    this.fileName = 'quran-i-kerim-backup.json',
    this.retainedSnapshots = 10,
  }) : assert(retainedSnapshots > 0);

  static const String mimeType = 'application/json';

  final drive.DriveApi driveApi;
  final String fileName;
  final int retainedSnapshots;

  @override
  Future<BackupCloudObject?> read() async {
    final snapshots = await _listSnapshots();
    if (snapshots.isEmpty) return null;
    return _download(snapshots.first);
  }

  @override
  Future<BackupCloudObject> write({
    required String content,
    required String? expectedRevision,
  }) async {
    final snapshots = await _listSnapshots();
    final current = snapshots.isEmpty ? null : snapshots.first;

    if (current == null) {
      if (expectedRevision != null) {
        throw const BackupCloudConflictException();
      }
    } else if (expectedRevision == null ||
        _revision(current) != expectedRevision) {
      throw const BackupCloudConflictException();
    }

    final created = await driveApi.files.create(
      drive.File(
        name: fileName,
        mimeType: mimeType,
        parents: const <String>['appDataFolder'],
        appProperties: <String, String?>{
          'quranBackup': 'snapshot-v1',
          if (expectedRevision != null) 'previousRevision': expectedRevision,
        },
      ),
      uploadMedia: _media(content),
      $fields: 'id,name,modifiedTime,version',
    );
    final result = _metadataToObject(created, content);

    // New snapshot is retained plus the newest N-1 snapshots observed before
    // the upload. Cleanup is best-effort: a failed delete must never turn a
    // successfully uploaded backup into an apparent failure.
    final stale = snapshots.skip(retainedSnapshots - 1).toList(growable: false);
    for (final file in stale) {
      final id = file.id;
      if (id == null || id.isEmpty) continue;
      try {
        await driveApi.files.delete(id);
      } catch (_) {
        // Keeping an extra tiny backup is safer than reporting the upload as
        // failed after its new snapshot already exists remotely.
      }
    }

    return result;
  }

  Future<BackupCloudObject> _download(drive.File metadata) async {
    final id = metadata.id;
    if (id == null || id.isEmpty) {
      throw const FormatException('Google Drive backup is missing a file id.');
    }

    final result = await driveApi.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    if (result is! drive.Media) {
      throw const FormatException('Google Drive backup content is unavailable.');
    }

    final bytes = <int>[];
    await for (final chunk in result.stream) {
      bytes.addAll(chunk);
    }

    return BackupCloudObject(
      content: utf8.decode(bytes),
      revision: _revision(metadata),
      updatedAt: (metadata.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0))
          .toUtc(),
    );
  }

  Future<List<drive.File>> _listSnapshots() async {
    final escapedName = fileName.replaceAll("'", "\\'");
    final result = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$escapedName' and trashed = false",
      orderBy: 'modifiedTime desc',
      pageSize: 100,
      $fields: 'files(id,name,modifiedTime,version)',
    );
    final files = List<drive.File>.from(
      result.files ?? const <drive.File>[],
      growable: false,
    );
    files.sort((a, b) {
      final aTime = a.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final byTime = bTime.compareTo(aTime);
      if (byTime != 0) return byTime;
      return (b.id ?? '').compareTo(a.id ?? '');
    });
    return files;
  }

  drive.Media _media(String content) {
    final bytes = utf8.encode(content);
    return drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: mimeType,
    );
  }

  BackupCloudObject _metadataToObject(drive.File file, String content) {
    return BackupCloudObject(
      content: content,
      revision: _revision(file),
      updatedAt: (file.modifiedTime ?? DateTime.now()).toUtc(),
    );
  }

  String _revision(drive.File file) {
    final id = file.id?.trim();
    if (id == null || id.isEmpty) {
      throw const FormatException('Google Drive backup has no usable file id.');
    }
    final version = file.version?.trim();
    if (version != null && version.isNotEmpty) return '$id@$version';
    final modified = file.modifiedTime;
    if (modified != null) return '$id@${modified.toUtc().toIso8601String()}';
    return 'id:$id';
  }
}
