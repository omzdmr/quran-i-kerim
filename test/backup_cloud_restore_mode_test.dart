import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_coordinator.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_store.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('quran_cloud_modes_');
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  Future<BackupCloudCoordinator> coordinator() async {
    final remote = BackupCloudObject(
      content: jsonEncode(<String, Object?>{
        'version': 3,
        'createdAt': '2026-09-22T00:00:00Z',
        'data': <String, Object?>{
          'reading': <String, Object?>{'last_surah': 36},
          'preferences': <String, Object?>{'app_locale': 'fr'},
        },
      }),
      revision: 'r1',
      updatedAt: DateTime.parse('2026-09-22T00:00:00Z'),
    );
    return BackupCloudCoordinator(
      store: _ReadOnlyStore(remote),
      restoreFileService: BackupFileService(
        directoryProvider: () async => tempRoot,
      ),
    );
  }

  test('merge keeps device-only values while applying cloud values', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'theme_mode': 'dark',
    });
    final value = await coordinator();
    final inspection = await value.inspect();

    await value.restoreRemote(inspection, mode: BackupRestoreMode.merge);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getInt('last_ayah'), 255);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('app_locale'), 'fr');
  });

  test('replace removes device-only values from included cloud sections', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'theme_mode': 'dark',
    });
    final value = await coordinator();
    final inspection = await value.inspect();

    await value.restoreRemote(inspection, mode: BackupRestoreMode.replace);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.containsKey('last_ayah'), isFalse);
    expect(prefs.containsKey('theme_mode'), isFalse);
    expect(prefs.getString('app_locale'), 'fr');
  });
}

class _ReadOnlyStore implements BackupCloudStore {
  _ReadOnlyStore(this.object);
  final BackupCloudObject object;

  @override
  Future<BackupCloudObject?> read() async => object;

  @override
  Future<BackupCloudObject> write({required String content, required String? expectedRevision}) =>
      throw UnimplementedError();
}