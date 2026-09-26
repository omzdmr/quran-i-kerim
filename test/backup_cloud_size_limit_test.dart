import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_coordinator.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_store.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('oversized remote is classified invalid before JSON preview/restore', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 2});
    final tempRoot = await Directory.systemTemp.createTemp('quran_cloud_size_');
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });
    final coordinator = BackupCloudCoordinator(
      store: _Store(
        BackupCloudObject(
          content: List<String>.filled(65, 'x').join(),
          revision: 'too-large',
          updatedAt: DateTime.parse('2026-09-22T00:00:00Z'),
        ),
      ),
      restoreFileService: BackupFileService(
        directoryProvider: () async => tempRoot,
        maxImportBytes: 64,
      ),
    );

    final inspection = await coordinator.inspect();

    expect(inspection.state, BackupCloudState.invalidRemote);
    expect(inspection.canRestoreRemote, isFalse);
    await expectLater(
      coordinator.prepareRemoteRestore(inspection),
      throwsFormatException,
    );
    expect(await Directory('${tempRoot.path}${Platform.pathSeparator}quran_backups').exists(), isFalse);
  });
}

class _Store implements BackupCloudStore {
  _Store(this.object);
  final BackupCloudObject object;

  @override
  Future<BackupCloudObject?> read() async => object;

  @override
  Future<BackupCloudObject> write({required String content, required String? expectedRevision}) =>
      throw UnimplementedError();
}