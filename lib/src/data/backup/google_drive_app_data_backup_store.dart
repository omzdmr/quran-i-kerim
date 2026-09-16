import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;

import 'backup_cloud_store.dart';

/// Google Drive implementation that stores one JSON backup in appDataFolder.
///
/// Authentication is intentionally injected through [driveApi]. This keeps
/// Google account/OAuth concerns out of the backup domain layer and lets the
/// app request only [drive.DriveApi.driveAppdataScope] when wiring sign-in.
class GoogleDriveAppDataBackupStore implements BackupCloudStore {
  GoogleDriveAppDataBackupStore(
    this.driveApi, {
    this.fileName = 'quran-i-kerim-backup.json',
  });

  static const String mimeType = 'application/json';

  final drive.DriveApi driveApi;
  final String fileName;

  @override
  Future<BackupCloudObject?> read() async {
    final metadata = await _findCurrent();
    if (metadata == null) return null;

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

  @override
  Future<BackupCloudObject> write({
    required String content,
    required String? expectedRevision,
  }) async {
    final current = await _findCurrent();

    if (current == null) {
      if (expectedRevision != null) {
        throw const BackupCloudConflictException();
      }
      final created = await driveApi.files.create(
        drive.File(
          name: fileName,
          mimeType: mimeType,
          parents: const <String>['appDataFolder'],
          appProperties: const <String, String?>{
            'quranBackup': 'canonical-v1',
          },
        ),
        uploadMedia: _media(content),
        $fields: 'id,name,modifiedTime,version',
      );
      return _metadataToObject(created, content);
    }

    if (expectedRevision == null || _revision(current) != expectedRevision) {
      throw const BackupCloudConflictException();
    }

    final id = current.id;
    if (id == null || id.isEmpty) {
      throw const FormatException('Google Drive backup is missing a file id.');
    }

    final updated = await driveApi.files.update(
      drive.File(mimeType: mimeType),
      id,
      uploadMedia: _media(content),
      $fields: 'id,name,modifiedTime,version',
    );
    return _metadataToObject(updated, content);
  }

  Future<drive.File?> _findCurrent() async {
    final escapedName = fileName.replaceAll("'", "\\'");
    final result = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$escapedName' and trashed = false",
      orderBy: 'modifiedTime desc',
      pageSize: 10,
      $fields: 'files(id,name,modifiedTime,version)',
    );
    final files = result.files ?? const <drive.File>[];
    if (files.isEmpty) return null;

    // Duplicate names are possible in Drive. Using the most recently modified
    // object keeps legacy/raced duplicates from making selection ambiguous.
    return files.reduce((a, b) {
      final aTime = a.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.isAfter(aTime) ? b : a;
    });
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
    final version = file.version?.trim();
    if (version != null && version.isNotEmpty) return version;
    final modified = file.modifiedTime;
    if (modified != null) return modified.toUtc().toIso8601String();
    final id = file.id?.trim();
    if (id != null && id.isNotEmpty) return 'id:$id';
    throw const FormatException('Google Drive backup has no usable revision.');
  }
}
