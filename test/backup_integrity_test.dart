import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_document.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';

void main() {
  const parser = BackupPreviewParser();

  test('new portable backup carries a verifiable sha256 checksum', () {
    final document = BackupDocument(
      version: BackupManifest.schemaVersion,
      createdAt: DateTime.utc(2026, 9, 21, 14),
      data: const <String, Object?>{
        'notes': <String, Object?>{'verse_notes': '{"2:255":"note"}'},
        'bookmarks': <String, Object?>{'bookmarks': <String>['2:255']},
      },
    );

    final decoded = jsonDecode(document.encode()) as Map<String, Object?>;
    final preview = parser.parse(decoded);

    expect(preview.canRestore, isTrue);
    expect(preview.integrityVerified, isTrue);
    expect(decoded['integrity'], isA<Map>());
  });

  test('changed payload is rejected before restore', () {
    final data = <String, Object?>{
      'notes': <String, Object?>{'verse_notes': '{"2:255":"original"}'},
    };
    final checksum = sha256.convert(utf8.encode(jsonEncode(data))).toString();
    final decoded = <String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-21T14:00:00Z',
      'integrity': <String, Object?>{
        'algorithm': 'sha256',
        'dataSha256': checksum,
      },
      'data': data,
    };

    (data['notes'] as Map<String, Object?>)['verse_notes'] =
        '{"2:255":"tampered"}';
    final preview = parser.parse(decoded);

    expect(preview.canRestore, isFalse);
    expect(preview.integrityVerified, isFalse);
    expect(preview.issues, contains(BackupPreviewIssue.checksumMismatch));
  });

  test('legacy backup without integrity metadata remains importable', () {
    final preview = parser.parse(<String, Object?>{
      'version': 4,
      'createdAt': '2026-09-16T06:00:00Z',
      'data': <String, Object?>{},
    });

    expect(preview.canRestore, isTrue);
    expect(preview.integrityVerified, isFalse);
  });

  test('unknown integrity algorithm is rejected instead of guessed', () {
    final preview = parser.parse(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-21T14:00:00Z',
      'integrity': <String, Object?>{
        'algorithm': 'sha999',
        'dataSha256': 'not-used',
      },
      'data': <String, Object?>{},
    });

    expect(preview.canRestore, isFalse);
    expect(preview.issues, contains(BackupPreviewIssue.unsupportedIntegrity));
  });
}
