import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_store.dart';
import 'package:quran_i_kerim/src/data/backup/google_drive_app_data_backup_store.dart';

void main() {
  test('reads the newest backup snapshot from Drive appDataFolder', () async {
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
                'id': 'older',
                'name': 'quran-i-kerim-backup.json',
                'modifiedTime': '2026-09-16T10:01:00Z',
                'version': '4',
              },
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
    expect(remote.revision, 'file-1@7');
    expect(remote.updatedAt, DateTime.parse('2026-09-16T10:02:00Z'));
    expect(listCalls, 1);
    expect(mediaCalls, 1);
  });

  test('creates the first appDataFolder snapshot when remote is empty', () async {
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
        expect(_decodeMultipartMedia(body), backupJson);
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

    expect(created.revision, 'created-1@1');
    expect(created.content, backupJson);
    expect(uploadCalls, 1);
  });

  test('refuses an upload when the latest Drive snapshot changed', () async {
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
      store.write(content: '{}', expectedRevision: 'file-1@8'),
      throwsA(isA<BackupCloudConflictException>()),
    );
    expect(uploadCalls, 0);
  });

  test('appends a new snapshot instead of overwriting the previous blob', () async {
    const backupJson =
        '{"version":3,"createdAt":"2026-09-16T11:00:00Z","data":{}}';
    var createCalls = 0;
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
      if (request.method == 'POST' &&
          request.url.path == '/upload/drive/v3/files') {
        createCalls++;
        final body = utf8.decode(request.bodyBytes);
        expect(_decodeMultipartMedia(body), backupJson);
        expect(body, contains('previousRevision'));
        expect(body, contains('file-1@9'));
        return http.Response(
          jsonEncode(<String, Object?>{
            'id': 'file-2',
            'name': 'quran-i-kerim-backup.json',
            'modifiedTime': '2026-09-16T11:01:00Z',
            'version': '1',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.method == 'PATCH') patchCalls++;
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    });
    addTearDown(client.close);
    final store = GoogleDriveAppDataBackupStore(drive.DriveApi(client));

    final updated = await store.write(
      content: backupJson,
      expectedRevision: 'file-1@9',
    );

    expect(updated.revision, 'file-2@1');
    expect(createCalls, 1);
    expect(patchCalls, 0);
  });

  test('prunes old snapshots only after a new backup was created', () async {
    final files = <Object?>[
      for (var index = 0; index < 10; index++)
        <String, Object?>{
          'id': 'old-$index',
          'name': 'quran-i-kerim-backup.json',
          'modifiedTime': '2026-09-${(15 - index).toString().padLeft(2, '0')}T10:00:00Z',
          'version': '${20 - index}',
        },
    ];
    final deleted = <String>[];
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/drive/v3/files') {
        return http.Response(
          jsonEncode(<String, Object?>{'files': files}),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' &&
          request.url.path == '/upload/drive/v3/files') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'id': 'new-1',
            'name': 'quran-i-kerim-backup.json',
            'modifiedTime': '2026-09-16T11:01:00Z',
            'version': '1',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.method == 'DELETE' &&
          request.url.path.startsWith('/drive/v3/files/')) {
        deleted.add(request.url.pathSegments.last);
        return http.Response('', 204);
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    });
    addTearDown(client.close);
    final store = GoogleDriveAppDataBackupStore(drive.DriveApi(client));

    final created = await store.write(
      content: '{}',
      expectedRevision: 'old-0@20',
    );

    expect(created.revision, 'new-1@1');
    expect(deleted, <String>['old-9']);
  });
}

String _decodeMultipartMedia(String body) {
  const marker = 'Content-Transfer-Encoding: base64\r\n\r\n';
  final markerIndex = body.indexOf(marker);
  if (markerIndex < 0) {
    throw StateError('Multipart media part is missing its base64 header.');
  }
  final encodedStart = markerIndex + marker.length;
  final encodedEnd = body.indexOf('\r\n--', encodedStart);
  if (encodedEnd < 0) {
    throw StateError('Multipart media part has no closing boundary.');
  }
  final encoded = body.substring(encodedStart, encodedEnd).trim();
  return utf8.decode(base64.decode(encoded));
}
