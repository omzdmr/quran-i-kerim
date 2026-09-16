import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_store.dart';
import 'package:quran_i_kerim/src/data/backup/google_drive_app_data_backup_store.dart';

void main() {
  test('reads the canonical backup from Drive appDataFolder', () async {
    const backupJson =
        '{"version":3,"createdAt":"2026-09-16T10:00:00Z","data":{}}';
    var listCalls = 0;
    var mediaCalls = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/drive/v3/files' &&
          request.url.queryParameters['alt'] != 'media') {
        listCalls++;
        expect(request.url.queryParameters['spaces'], 'appDataFolder');
        expect(
          request.url.queryParameters['q'],
          contains("name = 'quran-i-kerim-backup.json'"),
        );
        return http.Response(
          jsonEncode(<String, Object?>{
            'files': <Object?>[
              <String, Object?>{
                'id': 'file-1',
                'name': 'quran-i-kerim-backup.json',
                'modifiedTime': '2026-09-16T10:02:00Z',
                'version': '7',
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.method == 'GET' &&
          request.url.path == '/drive/v3/files/file-1' &&
          request.url.queryParameters['alt'] == 'media') {
        mediaCalls++;
        return http.Response(
          backupJson,
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    });
    addTearDown(client.close);
    final store = GoogleDriveAppDataBackupStore(drive.DriveApi(client));

    final remote = await store.read();

    expect(remote, isNotNull);
    expect(remote!.content, backupJson);
    expect(remote.revision, '7');
    expect(remote.updatedAt, DateTime.parse('2026-09-16T10:02:00Z'));
    expect(listCalls, 1);
    expect(mediaCalls, 1);
  });

  test('creates the canonical appDataFolder file when remote is empty', () async {
    const backupJson =
        '{"version":3,"createdAt":"2026-09-16T10:00:00Z","data":{}}';
    var uploadCalls = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/drive/v3/files') {
        return http.Response(
          '{"files":[]}',
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' &&
          request.url.path == '/upload/drive/v3/files') {
        uploadCalls++;
        expect(request.url.queryParameters['uploadType'], 'multipart');
        final body = utf8.decode(request.bodyBytes);
        expect(body, contains('quran-i-kerim-backup.json'));
        expect(body, contains('appDataFolder'));
        expect(body, contains(backupJson));
        return http.Response(
          jsonEncode(<String, Object?>{
            'id': 'created-1',
            'name': 'quran-i-kerim-backup.json',
            'modifiedTime': '2026-09-16T10:03:00Z',
            'version': '1',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    });
    addTearDown(client.close);
    final store = GoogleDriveAppDataBackupStore(drive.DriveApi(client));

    final created = await store.write(
      content: backupJson,
      expectedRevision: null,
    );

    expect(created.revision, '1');
    expect(created.content, backupJson);
    expect(uploadCalls, 1);
  });

  test('refuses an upload when the Drive revision changed', () async {
    var uploadCalls = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/drive/v3/files') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'files': <Object?>[
              <String, Object?>{
                'id': 'file-1',
                'name': 'quran-i-kerim-backup.json',
                'modifiedTime': '2026-09-16T10:02:00Z',
                'version': '9',
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      uploadCalls++;
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    final store = GoogleDriveAppDataBackupStore(drive.DriveApi(client));

    await expectLater(
      store.write(content: '{}', expectedRevision: '8'),
      throwsA(isA<BackupCloudConflictException>()),
    );
    expect(uploadCalls, 0);
  });

  test('updates an existing backup only with the expected revision', () async {
    const backupJson =
        '{"version":3,"createdAt":"2026-09-16T11:00:00Z","data":{}}';
    var patchCalls = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/drive/v3/files') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'files': <Object?>[
              <String, Object?>{
                'id': 'file-1',
                'name': 'quran-i-kerim-backup.json',
                'modifiedTime': '2026-09-16T10:02:00Z',
                'version': '9',
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.method == 'PATCH' &&
          request.url.path == '/upload/drive/v3/files/file-1') {
        patchCalls++;
        expect(request.url.queryParameters['uploadType'], 'multipart');
        expect(utf8.decode(request.bodyBytes), contains(backupJson));
        return http.Response(
          jsonEncode(<String, Object?>{
            'id': 'file-1',
            'name': 'quran-i-kerim-backup.json',
            'modifiedTime': '2026-09-16T11:01:00Z',
            'version': '10',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    });
    addTearDown(client.close);
    final store = GoogleDriveAppDataBackupStore(drive.DriveApi(client));

    final updated = await store.write(
      content: backupJson,
      expectedRevision: '9',
    );

    expect(updated.revision, '10');
    expect(patchCalls, 1);
  });
}
