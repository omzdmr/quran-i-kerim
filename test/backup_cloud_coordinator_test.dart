import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_coordinator.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_store.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'bookmarks': <String>['2:255'],
    });
  });

  test('reports an empty remote and creates the first cloud backup', () async {
    final store = _FakeCloudStore();
    final coordinator = BackupCloudCoordinator(store: store);

    final inspection = await coordinator.inspect(
      now: DateTime.parse('2026-09-16T12:00:00Z'),
    );

    expect(inspection.state, BackupCloudState.remoteEmpty);
    final uploaded = await coordinator.uploadLocal(inspection);
    expect(uploaded.revision, 'r1');
    expect(store.lastExpectedRevision, isNull);
    expect(store.object, isNotNull);
  });

  test('ignores envelope timestamps when backup data is unchanged', () async {
    final service = const LocalBackupService();
    final remoteJson = await service.exportJson(
      now: DateTime.parse('2026-09-15T08:00:00Z'),
    );
    final store = _FakeCloudStore(
      object: BackupCloudObject(
        content: remoteJson,
        revision: 'remote-1',
        updatedAt: DateTime.parse('2026-09-15T08:00:00Z'),
      ),
    );
    final coordinator = BackupCloudCoordinator(store: store);

    final inspection = await coordinator.inspect(
      now: DateTime.parse('2026-09-16T12:00:00Z'),
    );

    expect(inspection.state, BackupCloudState.upToDate);
    final result = await coordinator.uploadLocal(inspection);
    expect(result.revision, 'remote-1');
    expect(store.writeCount, 0);
  });

  test('canonicalizes map order before comparing data', () async {
    final service = const LocalBackupService();
    final local = jsonDecode(
      await service.exportJson(now: DateTime.parse('2026-09-16T12:00:00Z')),
    ) as Map<String, dynamic>;
    final data = local['data'] as Map<String, dynamic>;
    final reversed = <String, Object?>{
      for (final key in data.keys.toList().reversed) key: data[key],
    };
    final remoteJson = jsonEncode(<String, Object?>{
      'version': local['version'],
      'createdAt': '2026-09-01T00:00:00Z',
      'data': reversed,
    });
    final coordinator = BackupCloudCoordinator(
      store: _FakeCloudStore(
        object: BackupCloudObject(
          content: remoteJson,
          revision: 'r7',
          updatedAt: DateTime.parse('2026-09-01T00:00:00Z'),
        ),
      ),
    );

    final inspection = await coordinator.inspect();

    expect(inspection.state, BackupCloudState.upToDate);
  });

  test('requires an explicit choice before overwriting diverged remote data', () async {
    final remoteJson = jsonEncode(<String, Object?>{
      'version': 3,
      'createdAt': '2026-09-15T08:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36, 'last_ayah': 58},
      },
    });
    final store = _FakeCloudStore(
      object: BackupCloudObject(
        content: remoteJson,
        revision: 'remote-9',
        updatedAt: DateTime.parse('2026-09-15T08:00:00Z'),
      ),
    );
    final coordinator = BackupCloudCoordinator(store: store);
    final inspection = await coordinator.inspect();

    expect(inspection.state, BackupCloudState.diverged);
    await expectLater(
      coordinator.uploadLocal(inspection),
      throwsStateError,
    );

    final uploaded = await coordinator.uploadLocal(
      inspection,
      allowOverwrite: true,
    );
    expect(uploaded.revision, 'r1');
    expect(store.lastExpectedRevision, 'remote-9');
    expect(store.writeCount, 1);
  });

  test('marks invalid remote content and refuses to restore it', () async {
    final coordinator = BackupCloudCoordinator(
      store: _FakeCloudStore(
        object: BackupCloudObject(
          content: '{not-json',
          revision: 'broken',
          updatedAt: DateTime.parse('2026-09-15T08:00:00Z'),
        ),
      ),
    );

    final inspection = await coordinator.inspect();

    expect(inspection.state, BackupCloudState.invalidRemote);
    expect(inspection.canRestoreRemote, isFalse);
    await expectLater(
      coordinator.restoreRemote(inspection),
      throwsFormatException,
    );
  });

  test('restores valid remote data without silently uploading local state', () async {
    final remoteJson = jsonEncode(<String, Object?>{
      'version': 3,
      'createdAt': '2026-09-15T08:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36, 'last_ayah': 58},
        'bookmarks': <String, Object?>{'bookmarks': <String>['36:58']},
      },
    });
    final store = _FakeCloudStore(
      object: BackupCloudObject(
        content: remoteJson,
        revision: 'remote-2',
        updatedAt: DateTime.parse('2026-09-15T08:00:00Z'),
      ),
    );
    final coordinator = BackupCloudCoordinator(store: store);
    final inspection = await coordinator.inspect();

    await coordinator.restoreRemote(inspection);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getInt('last_ayah'), 58);
    expect(store.writeCount, 0);
  });
}

class _FakeCloudStore implements BackupCloudStore {
  _FakeCloudStore({this.object});

  BackupCloudObject? object;
  int writeCount = 0;
  String? lastExpectedRevision;

  @override
  Future<BackupCloudObject?> read() async => object;

  @override
  Future<BackupCloudObject> write({
    required String content,
    required String? expectedRevision,
  }) async {
    final current = object;
    if (current == null) {
      if (expectedRevision != null) {
        throw const BackupCloudConflictException();
      }
    } else if (current.revision != expectedRevision) {
      throw const BackupCloudConflictException();
    }

    writeCount += 1;
    lastExpectedRevision = expectedRevision;
    final next = BackupCloudObject(
      content: content,
      revision: 'r$writeCount',
      updatedAt: DateTime.parse('2026-09-16T12:00:00Z'),
    );
    object = next;
    return next;
  }
}
