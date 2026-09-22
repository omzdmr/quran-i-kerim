import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';

void main() {
  const parser = BackupPreviewParser();

  test('current-schema backup with unknown section is blocked', () {
    final preview = parser.parse(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 2},
        'futureUserData': <String, Object?>{'important': 'keep me'},
      },
    });
    expect(preview.canRestore, isFalse);
    expect(preview.issues, contains(BackupPreviewIssue.unsupportedData));
    expect(preview.recordCounts, isNot(contains('futureUserData')));
  });

  test('older schema cannot smuggle a section introduced by a later schema', () {
    final preview = parser.parse(<String, Object?>{
      'version': 3,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 2},
        'readingPlans': <String, Object?>{'reading_plan_state_v1': '{}'},
      },
    });
    expect(preview.canRestore, isFalse);
    expect(preview.issues, contains(BackupPreviewIssue.unsupportedData));
  });

  test('every declared section set remains preview-compatible for its schema', () {
    for (var version = 1; version <= BackupManifest.schemaVersion; version++) {
      final data = <String, Object?>{
        for (final section in BackupManifest.sectionsForVersion(version))
          section: <String, Object?>{},
      };
      final preview = parser.parse(<String, Object?>{
        'version': version,
        'createdAt': '2026-09-22T00:00:00Z',
        'data': data,
      });
      expect(preview.canRestore, isTrue, reason: 'schema v$version');
      expect(preview.issues, isEmpty, reason: 'schema v$version');
    }
  });
}
