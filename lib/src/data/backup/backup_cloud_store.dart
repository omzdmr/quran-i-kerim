/// Provider-neutral representation of the single backup object stored in a
/// user-owned cloud location such as Google Drive appDataFolder.
class BackupCloudObject {
  const BackupCloudObject({
    required this.content,
    required this.revision,
    required this.updatedAt,
  });

  final String content;

  /// Opaque provider revision/etag. The sync layer never interprets it; it is
  /// only sent back on writes for optimistic concurrency control.
  final String revision;
  final DateTime updatedAt;
}

/// Minimal contract implemented by concrete cloud providers.
///
/// A provider should keep one canonical app backup object. [expectedRevision]
/// is null when creating the object for the first time. When it is non-null,
/// the provider must reject the write if the remote revision changed since it
/// was read.
abstract interface class BackupCloudStore {
  Future<BackupCloudObject?> read();

  Future<BackupCloudObject> write({
    required String content,
    required String? expectedRevision,
  });
}

/// Raised by a provider when another device updated the remote backup between
/// read and write. The caller should inspect again instead of overwriting it.
class BackupCloudConflictException implements Exception {
  const BackupCloudConflictException();

  @override
  String toString() => 'The remote backup changed before the write completed.';
}
