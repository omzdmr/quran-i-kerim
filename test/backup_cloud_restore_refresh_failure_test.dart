import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_connector.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_controller.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_coordinator.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_store.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('successful cloud restore keeps its undo receipt when follow-up remote refresh fails', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
    });
    final tempRoot = await Directory.systemTemp.createTemp('quran_cloud_refresh_failure_');
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });

    final store = _FailThirdReadStore(
      BackupCloudObject(
        content: jsonEncode(<String, Object?>{
          'version': 3,
          'createdAt': '2026-09-22T00:00:00Z',
          'data': <String, Object?>{
            'reading': <String, Object?>{'last_surah': 36, 'last_ayah': 58},
          },
        }),
        revision: 'remote-1',
        updatedAt: DateTime.parse('2026-09-22T00:00:00Z'),
      ),
    );
    final restoreService = BackupFileService(
      directoryProvider: () async => tempRoot,
    );
    final controller = BackupCloudController(
      connector: _Connector(store),
      coordinatorFactory: (cloudStore) => BackupCloudCoordinator(
        store: cloudStore,
        restoreFileService: restoreService,
      ),
    );
    addTearDown(controller.dispose);

    await controller.connect(); // read #1
    final receipt = await controller.restoreRemote(); // read #2, restore, read #3 fails

    expect(receipt, isNotNull);
    expect(await receipt!.safetySnapshot.exists(), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getInt('last_ayah'), 58);
    expect(controller.lastError, isNull,
        reason: 'A post-commit status refresh is not a restore failure.');

    await restoreService.undoRestore(receipt);
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getInt('last_ayah'), 255);
  });
}

class _Connector implements BackupCloudConnector {
  _Connector(this.store);
  final BackupCloudStore store;

  @override
  Future<BackupCloudConnection> connect({bool interactive = true}) async =>
      BackupCloudConnection(accountLabel: 'test', store: store, close: () {});

  @override
  Future<void> signOut() async {}
}

class _FailThirdReadStore implements BackupCloudStore {
  _FailThirdReadStore(this.object);
  final BackupCloudObject object;
  int reads = 0;

  @override
  Future<BackupCloudObject?> read() async {
    reads += 1;
    if (reads == 3) throw StateError('simulated transient remote refresh failure');
    return object;
  }

  @override
  Future<BackupCloudObject> write({required String content, required String? expectedRevision}) =>
      throw UnimplementedError();
}