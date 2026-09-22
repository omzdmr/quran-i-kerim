import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';

void main() {
  const parser = BackupPreviewParser();

  BackupPreview preview(int version, Map<String, Object?> data) => parser.parse(<String, Object?>{
        'version': version,
        'createdAt': '2026-09-22T00:00:00Z',
        'data': data,
      });

  test('current-schema backup with unknown section is blocked', () {
    final result = preview(BackupManifest.schemaVersion, <String, Object?>{
      'reading': <String, Object?>{'last_surah': 2},
      'futureUserData': <String, Object?>{'important': 'keep me'},
    });
    expect(result.canRestore, isFalse);
    expect(result.issues, contains(BackupPreviewIssue.unsupportedData));
    expect(result.recordCounts, isNot(contains('futureUserData')));
  });

  test('unknown key inside a known current section is blocked', () {
    final result = preview(BackupManifest.schemaVersion, <String, Object?>{
      'preferences': <String, Object?>{
        'app_locale': 'tr',
        'future_private_preference': 'must not be discarded',
      },
    });
    expect(result.canRestore, isFalse);
    expect(result.issues, contains(BackupPreviewIssue.unsupportedData));
  });

  test('older schema cannot smuggle a section introduced later', () {
    final result = preview(3, <String, Object?>{
      'reading': <String, Object?>{'last_surah': 2},
      'readingPlans': <String, Object?>{'reading_plan_state_v1': '{}'},
    });
    expect(result.canRestore, isFalse);
    expect(result.issues, contains(BackupPreviewIssue.unsupportedData));
  });

  test('older schema cannot smuggle a preference key introduced later', () {
    final result = preview(4, <String, Object?>{
      'preferences': <String, Object?>{
        'app_locale': 'tr',
        'home_quick_actions_v1': <String>['reader'],
      },
    });
    expect(result.canRestore, isFalse);
    expect(result.issues, contains(BackupPreviewIssue.unsupportedData));
  });

  test('dynamic learning keys are accepted only from schema v2 onward', () {
    final v1 = preview(1, <String, Object?>{
      'learning': <String, Object?>{'learn_progress_v1:lesson': '{}'},
    });
    final v2 = preview(2, <String, Object?>{
      'learning': <String, Object?>{'learn_progress_v1:lesson': '{}'},
    });
    expect(v1.canRestore, isFalse);
    expect(v1.issues, contains(BackupPreviewIssue.unsupportedData));
    expect(v2.canRestore, isTrue);
  });

  test('every declared empty section set remains preview-compatible for its schema', () {
    for (var version = 1; version <= BackupManifest.schemaVersion; version++) {
      final data = <String, Object?>{
        for (final section in BackupManifest.sectionsForVersion(version)) section: <String, Object?>{},
      };
      final result = preview(version, data);
      expect(result.canRestore, isTrue, reason: 'schema v$version');
      expect(result.issues, isEmpty, reason: 'schema v$version');
    }
  });
}
