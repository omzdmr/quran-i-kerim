/// Provider-neutral representation of the logical current backup stored in a
/// user-owned cloud location such as Google Drive appDataFolder.
class BackupCloudObject {
  const BackupCloudObject({
    required this.content,
    required this.revision,
    required this.updatedAt,
  });

  final String content;

  /// Opaque provider revision identity. The sync layer never interprets it; it
  /// is only sent back on writes for conflict detection.
  final String revision;
  final DateTime updatedAt;
}

/// Minimal contract implemented by concrete cloud providers.
///
/// [read] returns the provider's logical current backup. Implementations may
/// keep one object or a short immutable snapshot history. [expectedRevision] is
/// null for the first write. When it is non-null, the provider must detect a
/// changed current revision before writing. Providers without an atomic remote
/// precondition should avoid destructive overwrites so a narrow concurrent
/// write race cannot erase the other device's backup.
abstract interface class BackupCloudStore {
  Future<BackupCloudObject?> read();

  Future<BackupCloudObject> write({
    required String content,
    required String? expectedRevision,
  });
}

/// Raised when another device changed the logical current backup after it was
/// inspected. The caller should inspect again instead of choosing a winner.
class BackupCloudConflictException implements Exception {
  const BackupCloudConflictException();

  @override
  String toString() => 'The remote backup changed before the write completed.';
}
