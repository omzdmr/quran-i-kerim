import 'package:flutter/foundation.dart';

import 'backup_cloud_connector.dart';
import 'backup_cloud_coordinator.dart';
import 'backup_cloud_store.dart';
import 'backup_file_service.dart';

typedef BackupCloudCoordinatorFactory = BackupCloudCoordinator Function(
  BackupCloudStore store,
);

class BackupCloudController extends ChangeNotifier {
  BackupCloudController({
    required this.connector,
    BackupCloudCoordinatorFactory? coordinatorFactory,
  }) : _coordinatorFactory = coordinatorFactory ??
           ((store) => BackupCloudCoordinator(store: store));

  final BackupCloudConnector connector;
  final BackupCloudCoordinatorFactory _coordinatorFactory;
  BackupCloudConnection? _connection;
  BackupCloudCoordinator? _coordinator;
  BackupCloudInspection? _inspection;
  bool _busy = false;
  Object? _lastError;

  bool get busy => _busy;
  bool get connected => _connection != null;
  String? get accountLabel => _connection?.accountLabel;
  BackupCloudInspection? get inspection => _inspection;
  BackupCloudState? get state => _inspection?.state;
  Object? get lastError => _lastError;

  Future<void> connect({bool interactive = true}) async {
    if (_busy) return;
    await _run(() async {
      _replaceConnection(await connector.connect(interactive: interactive));
      await _refreshInspection();
    });
  }

  Future<void> refresh() async {
    if (_busy || _coordinator == null) return;
    await _run(_refreshInspection);
  }

  Future<void> uploadLocal({bool allowOverwrite = false}) async {
    if (_busy) return;
    final coordinator = _requireCoordinator();
    await _run(() async {
      final fresh = await coordinator.inspect();
      _inspection = fresh;
      notifyListeners();
      await coordinator.uploadLocal(fresh, allowOverwrite: allowOverwrite);
      await _refreshInspection();
    });
  }

  Future<BackupCloudRestorePreparation?> prepareRemoteRestore() async {
    if (_busy) return null;
    final coordinator = _requireCoordinator();
    BackupCloudRestorePreparation? preparation;
    await _run(() async {
      final fresh = await coordinator.inspect();
      _inspection = fresh;
      notifyListeners();
      preparation = await coordinator.prepareRemoteRestore(fresh);
    });
    return preparation;
  }

  Future<BackupRestoreReceipt?> restoreRemote({
    required BackupCloudRestorePreparation preparation,
    BackupRestoreMode mode = BackupRestoreMode.replace,
  }) async {
    if (_busy) return null;
    final coordinator = _requireCoordinator();
    BackupRestoreReceipt? receipt;
    await _run(() async {
      final fresh = await coordinator.inspect();
      _inspection = fresh;
      notifyListeners();
      if (fresh.remote?.revision != preparation.remoteRevision ||
          fresh.localDataSignature != preparation.localDataSignature) {
        throw const BackupCloudConflictException();
      }
      receipt = await coordinator.restoreRemote(fresh, mode: mode);
      try {
        await _refreshInspection();
      } catch (_) {}
    });
    return receipt;
  }

  Future<void> signOut() async {
    if (_busy) return;
    await _run(() async {
      _clearConnection();
      await connector.signOut();
    });
  }

  BackupCloudCoordinator _requireCoordinator() {
    final coordinator = _coordinator;
    if (coordinator == null) throw StateError('Cloud backup is not connected.');
    return coordinator;
  }

  Future<void> _refreshInspection() async {
    final coordinator = _requireCoordinator();
    _inspection = await coordinator.inspect();
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _lastError = error;
      notifyListeners();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _replaceConnection(BackupCloudConnection connection) {
    _connection?.close();
    _connection = connection;
    _coordinator = _coordinatorFactory(connection.store);
    _inspection = null;
  }

  void _clearConnection() {
    _connection?.close();
    _connection = null;
    _coordinator = null;
    _inspection = null;
  }

  @override
  void dispose() {
    _clearConnection();
    super.dispose();
  }
}
