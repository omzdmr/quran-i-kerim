/// Coordinates a restore so a partially-applied backup never becomes the
/// final local state. Concrete stores remain responsible for snapshot/apply.
class BackupRestoreCoordinator {
  const BackupRestoreCoordinator();

  Future<void> restore({
    required Future<void> Function() validate,
    required Future<Object?> Function() captureSnapshot,
    required Future<void> Function() applyRestore,
    required Future<void> Function(Object? snapshot) rollback,
  }) async {
    await validate();
    final snapshot = await captureSnapshot();

    try {
      await applyRestore();
    } catch (error, stackTrace) {
      try {
        await rollback(snapshot);
      } catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          BackupRestoreRollbackException(
            restoreError: error,
            rollbackError: rollbackError,
          ),
          rollbackStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class BackupRestoreRollbackException implements Exception {
  const BackupRestoreRollbackException({
    required this.restoreError,
    required this.rollbackError,
  });

  final Object restoreError;
  final Object rollbackError;

  @override
  String toString() =>
      'Backup restore failed and rollback also failed: '
      'restore=$restoreError, rollback=$rollbackError';
}
