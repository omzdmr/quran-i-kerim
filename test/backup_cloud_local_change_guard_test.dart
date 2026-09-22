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
  test('cloud restore refuses a preview after local data changes underneath it', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 2, 'last_ayah': 255});
    final root = await Directory.systemTemp.createTemp('quran_cloud_local_guard_');
    addTearDown(() async { if (await root.exists()) await root.delete(recursive: true); });
    final store = _Store(BackupCloudObject(
      content: jsonEncode(<String, Object?>{
        'version': 3,
        'createdAt': '2026-09-22T00:00:00Z',
        'data': <String, Object?>{'reading': <String, Object?>{'last_surah': 36}},
      }),
      revision: 'r1',
      updatedAt: DateTime.parse('2026-09-22T00:00:00Z'),
    ));
    final controller = BackupCloudController(
      connector: _Connector(store),
      coordinatorFactory: (cloudStore) => BackupCloudCoordinator(
        store: cloudStore,
        restoreFileService: BackupFileService(directoryProvider: () async => root),
      ),
    );
    addTearDown(controller.dispose);
    await controller.connect();
    final preparation = await controller.prepareRemoteRestore();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_ayah', 286); // local state no longer matches preview

    await expectLater(
      controller.restoreRemote(preparation: preparation!),
      throwsA(isA<BackupCloudConflictException>()),
    );
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getInt('last_ayah'), 286);
    expect(await Directory('${root.path}${Platform.pathSeparator}quran_backups').exists(), isFalse);
  });
}

class _Connector implements BackupCloudConnector {
  _Connector(this.store);
  final BackupCloudStore store;
  @override
  Future<BackupCloudConnection> connect({bool interactive = true}) async => BackupCloudConnection(accountLabel: 'test', store: store, close: () {});
  @override
  Future<void> signOut() async {}
}
class _Store implements BackupCloudStore {
  _Store(this.object);
  final BackupCloudObject object;
  @override
  Future<BackupCloudObject?> read() async => object;
  @override
  Future<BackupCloudObject> write({required String content, required String? expectedRevision}) => throw UnimplementedError();
}
