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
  late Directory tempRoot;
  late _MutableStore store;
  late BackupCloudController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'theme_mode': 'dark',
    });
    tempRoot = await Directory.systemTemp.createTemp('quran_cloud_prepare_');
    store = _MutableStore(_object('r1', surah: 36, locale: 'fr'));
    final restoreService = BackupFileService(directoryProvider: () async => tempRoot);
    controller = BackupCloudController(
      connector: _Connector(store),
      coordinatorFactory: (cloudStore) => BackupCloudCoordinator(
        store: cloudStore,
        restoreFileService: restoreService,
      ),
    );
    await controller.connect();
  });

  tearDown(() async {
    controller.dispose();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('preparation exposes the same conflict plan used by local restore UI', () async {
    final preparation = await controller.prepareRemoteRestore();

    expect(preparation, isNotNull);
    expect(preparation!.remoteRevision, 'r1');
    expect(preparation.preview.canRestore, isTrue);
    expect(preparation.plan.conflictingRecords, greaterThanOrEqualTo(1));
    expect(preparation.plan.incomingOnlyRecords, greaterThanOrEqualTo(1));
  });

  test('reviewed cloud revision cannot be silently replaced by another device', () async {
    final preparation = await controller.prepareRemoteRestore();
    expect(preparation, isNotNull);

    store.object = _object('r2', surah: 18, locale: 'az');

    await expectLater(
      controller.restoreRemote(
        preparation: preparation,
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<BackupCloudConflictException>()),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2,
        reason: 'No data may change after the preview becomes stale.');
    expect(prefs.getInt('last_ayah'), 255);
    expect(prefs.getString('theme_mode'), 'dark');
    final backupDir = Directory('${tempRoot.path}${Platform.pathSeparator}quran_backups');
    expect(await backupDir.exists(), isFalse,
        reason: 'Conflict is rejected before restore/safety-snapshot side effects.');
  });
}

BackupCloudObject _object(String revision, {required int surah, required String locale}) =>
    BackupCloudObject(
      content: jsonEncode(<String, Object?>{
        'version': 3,
        'createdAt': '2026-09-22T00:00:00Z',
        'data': <String, Object?>{
          'reading': <String, Object?>{'last_surah': surah},
          'preferences': <String, Object?>{'app_locale': locale},
        },
      }),
      revision: revision,
      updatedAt: DateTime.parse('2026-09-22T00:00:00Z'),
    );

class _Connector implements BackupCloudConnector {
  _Connector(this.store);
  final BackupCloudStore store;

  @override
  Future<BackupCloudConnection> connect({bool interactive = true}) async =>
      BackupCloudConnection(accountLabel: 'test', store: store, close: () {});

  @override
  Future<void> signOut() async {}
}

class _MutableStore implements BackupCloudStore {
  _MutableStore(this.object);
  BackupCloudObject object;

  @override
  Future<BackupCloudObject?> read() async => object;

  @override
  Future<BackupCloudObject> write({required String content, required String? expectedRevision}) =>
      throw UnimplementedError();
}