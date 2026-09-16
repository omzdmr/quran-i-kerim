import 'backup_cloud_store.dart';

class BackupCloudConnection {
  BackupCloudConnection({
    required this.accountLabel,
    required this.store,
    required void Function() close,
  }) : _close = close;

  final String accountLabel;
  final BackupCloudStore store;
  final void Function() _close;

  void close() => _close();
}

abstract interface class BackupCloudConnector {
  Future<BackupCloudConnection> connect({bool interactive = true});

  Future<void> signOut();
}
