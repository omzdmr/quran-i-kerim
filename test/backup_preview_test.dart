import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';

void main() {
  const parser = BackupPreviewParser();

  test('previews current compatible backup without mutating data', () {
    final preview = parser.parse(<String, Object?>{
      'version': 2,
      'createdAt': '2026-09-16T06:00:00Z',
      'data': <String, Object?>{
        'notes': <Object?>[1, 2],
        'bookmarks': <Object?>[1],
        'preferences': <String, Object?>{'locale': 'tr'},
        'highlights': <Object?>[],
        'learning': <String, Object?>{'learn_progress_v1:a': '{}'},
      },
    });

    expect(preview.canRestore, isTrue);
    expect(preview.createdAt, DateTime.utc(2026, 9, 16, 6));
    expect(preview.recordCounts['notes'], 2);
    expect(preview.recordCounts['bookmarks'], 1);
    expect(preview.recordCounts['preferences'], 1);
    expect(preview.recordCounts['highlights'], 0);
    expect(preview.recordCounts['learning'], 1);
    expect(preview.totalRecords, 5);
  });

  test('keeps version one backups restorable', () {
    final preview = parser.parse(<String, Object?>{
      'version': 1,
      'createdAt': '2026-09-16T06:00:00Z',
      'data': <String, Object?>{},
    });

    expect(preview.canRestore, isTrue);
    expect(preview.version, 1);
  });

  test('blocks unsupported backup versions', () {
    final preview = parser.parse(<String, Object?>{
      'version': 99,
      'createdAt': '2026-09-16T06:00:00Z',
      'data': <String, Object?>{},
    });

    expect(preview.canRestore, isFalse);
    expect(preview.issues, contains(BackupPreviewIssue.unsupportedVersion));
  });

  test('reports malformed metadata and payload', () {
    final preview = parser.parse(<String, Object?>{
      'version': 2,
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

  test('rejects missing backup version metadata', () {
    final preview = parser.parse(<String, Object?>{
      'createdAt': '2026-09-16T06:00:00Z',
      'data': <String, Object?>{},
    });

    expect(preview.canRestore, isFalse);
    expect(preview.version, isNull);
    expect(preview.issues, contains(BackupPreviewIssue.unsupportedVersion));
  });

  test('normalizes offset backup timestamp to UTC', () {
    final preview = parser.parse(<String, Object?>{
      'version': 2,
      'createdAt': '2026-09-16T14:00:00+08:00',
      'data': <String, Object?>{},
    });

    expect(preview.canRestore, isTrue);
    expect(preview.createdAt, DateTime.utc(2026, 9, 16, 6));
  });

  test('reports invalid map keys without counting them', () {
    final preview = parser.parse(<String, Object?>{
      'version': 2,
      'createdAt': '2026-09-16T06:00:00Z',
      'data': <Object?, Object?>{
        'notes': <Object?>[1],
        42: <Object?>[1, 2],
      },
    });

    expect(preview.canRestore, isFalse);
    expect(preview.recordCounts, <String, int>{'notes': 1});
    expect(preview.totalRecords, 1);
    expect(preview.issues, contains(BackupPreviewIssue.invalidData));
  });

  test('counts null sections as empty without rejecting backup', () {
    final preview = parser.parse(<String, Object?>{
      'version': 2,
      'createdAt': '2026-09-16T06:00:00Z',
      'data': <String, Object?>{
        'notes': null,
        'bookmarks': <Object?>[],
      },
    });

    expect(preview.canRestore, isTrue);
    expect(preview.recordCounts['notes'], 0);
    expect(preview.recordCounts['bookmarks'], 0);
    expect(preview.totalRecords, 0);
  });
}
