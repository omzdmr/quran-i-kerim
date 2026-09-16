import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';

void main() {
  const parser = BackupPreviewParser();

  test('previews compatible backup without mutating data', () {
    final preview = parser.parse(<String, Object?>{
      'version': 1,
      'createdAt': '2026-09-16T06:00:00Z',
      'data': <String, Object?>{
        'notes': <Object?>[1, 2],
        'bookmarks': <Object?>[1],
        'preferences': <String, Object?>{'locale': 'tr'},
        'highlights': <Object?>[],
      },
    });

    expect(preview.canRestore, isTrue);
    expect(preview.createdAt, DateTime.utc(2026, 9, 16, 6));
    expect(preview.recordCounts['notes'], 2);
    expect(preview.recordCounts['bookmarks'], 1);
    expect(preview.recordCounts['preferences'], 1);
    expect(preview.recordCounts['highlights'], 0);
    expect(preview.totalRecords, 4);
  });

  test('blocks unsupported backup versions', () {
    final preview = parser.parse(<String, Object?>{
      'version': 99,
      'createdAt': '2026-09-16T06:00:00Z',
      'data': <String, Object?>{},
    });

    expect(preview.canRestore, isFalse);
    expect(
      preview.issues,
      contains(BackupPreviewIssue.unsupportedVersion),
    );
  });

  test('reports malformed metadata and payload', () {
    final preview = parser.parse(<String, Object?>{
      'version': 1,
      'createdAt': 'not-a-date',
      'data': <String, Object?>{'notes': 'invalid'},
    });

    expect(preview.canRestore, isFalse);
    expect(preview.issues, contains(BackupPreviewIssue.invalidCreatedAt));
    expect(preview.issues, contains(BackupPreviewIssue.invalidData));
  });

  test('rejects non-object backup roots', () {
    final preview = parser.parse(<Object?>[]);

    expect(preview.canRestore, isFalse);
    expect(preview.issues, <BackupPreviewIssue>{BackupPreviewIssue.invalidRoot});
  });
}
