import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_connector.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_controller.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_coordinator.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
    });
  });

  test('connect exposes account and inspects an empty remote', () async {
    final store = _MemoryCloudStore();
    final connector = _FakeConnector(store);
    final controller = BackupCloudController(connector: connector);
    addTearDown(controller.dispose);

    await controller.connect();

    expect(controller.connected, isTrue);
    expect(controller.accountLabel, 'reader@example.com');
    expect(controller.state, BackupCloudState.remoteEmpty);
    expect(controller.busy, isFalse);
    expect(connector.connectCalls, 1);
  });

  test('upload re-inspects local data immediately before writing', () async {
    final store = _MemoryCloudStore();
    final controller = BackupCloudController(
      connector: _FakeConnector(store),
    );
    addTearDown(controller.dispose);
    await controller.connect();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_surah', 36);
    await prefs.setInt('last_ayah', 58);

    await controller.uploadLocal();

    final decoded = jsonDecode(store.object!.content) as Map<String, dynamic>;
    final reading = (decoded['data'] as Map<String, dynamic>)['reading']
        as Map<String, dynamic>;
    expect(reading['last_surah'], 36);
    expect(reading['last_ayah'], 58);
    expect(controller.state, BackupCloudState.upToDate);
  });

  test('diverged remote is not overwritten without explicit permission', () async {
    final remoteJson = jsonEncode(<String, Object?>{
      'version': 3,
      'createdAt': '2026-09-16T10:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 18, 'last_ayah': 10},
      },
    });
    final store = _MemoryCloudStore(
      object: BackupCloudObject(
        content: remoteJson,
        revision: 'r1',
        updatedAt: DateTime.parse('2026-09-16T10:00:00Z'),
      ),
    );
    final controller = BackupCloudController(
      connector: _FakeConnector(store),
    );
    addTearDown(controller.dispose);
    await controller.connect();
    expect(controller.state, BackupCloudState.diverged);

    await expectLater(controller.uploadLocal(), throwsStateError);
    expect(store.writeCount, 0);
    expect(controller.lastError, isA<StateError>());

    await controller.uploadLocal(allowOverwrite: true);
    expect(store.writeCount, 1);
    expect(controller.state, BackupCloudState.upToDate);
  });

  test('restore re-reads remote and applies its latest content', () async {
    final first = _backupJson(surah: 18, ayah: 10);
    final store = _MemoryCloudStore(
      object: BackupCloudObject(
        content: first,
        revision: 'r1',
        updatedAt: DateTime.parse('2026-09-16T10:00:00Z'),
      ),
    );
    final controller = BackupCloudController(
      connector: _FakeConnector(store),
    );
    addTearDown(controller.dispose);
    await controller.connect();

    store.object = BackupCloudObject(
      content: _backupJson(surah: 36, ayah: 58),
      revision: 'r2',
      updatedAt: DateTime.parse('2026-09-16T11:00:00Z'),
    );

    await controller.restoreRemote();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getInt('last_ayah'), 58);
    expect(controller.state, BackupCloudState.upToDate);
  });

  test('sign out closes the active connection and clears state', () async {
    final connector = _FakeConnector(_MemoryCloudStore());
    final controller = BackupCloudController(connector: connector);
    addTearDown(controller.dispose);
    await controller.connect();

    await controller.signOut();

    expect(controller.connected, isFalse);
    expect(controller.inspection, isNull);
    expect(connector.closeCalls, 1);
    expect(connector.signOutCalls, 1);
  });
}

String _backupJson({required int surah, required int ayah}) {
  return jsonEncode(<String, Object?>{
    'version': 3,
    'createdAt': '2026-09-16T10:00:00Z',
    'data': <String, Object?>{
      'reading': <String, Object?>{
        'last_surah': surah,
        'last_ayah': ayah,
      },
    },
  });
}

class _FakeConnector implements BackupCloudConnector {
  _FakeConnector(this.store);

  final BackupCloudStore store;
  int connectCalls = 0;
  int signOutCalls = 0;
  int closeCalls = 0;

  @override
  Future<BackupCloudConnection> connect({bool interactive = true}) async {
    connectCalls += 1;
    return BackupCloudConnection(
      accountLabel: 'reader@example.com',
      store: store,
      close: () => closeCalls += 1,
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}

class _MemoryCloudStore implements BackupCloudStore {
  _MemoryCloudStore({this.object});

  BackupCloudObject? object;
  int writeCount = 0;

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
    final next = BackupCloudObject(
      content: content,
      revision: 'r${writeCount + 1}',
      updatedAt: DateTime.parse('2026-09-16T12:00:00Z'),
    );
    object = next;
    return next;
  }
}
