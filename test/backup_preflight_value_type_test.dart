import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';

void main() {
  const parser = BackupPreviewParser();

  BackupPreview parse(Object? value) => parser.parse(<String, Object?>{
        'version': BackupManifest.schemaVersion,
        'createdAt': '2026-09-22T00:00:00Z',
        'data': <String, Object?>{
          'preferences': <String, Object?>{'app_locale': value},
        },
      });

  test('accepts every SharedPreferences-compatible JSON value shape', () {
    for (final value in <Object?>['tr', true, 2, 1.5, <String>['a', 'b'], null]) {
      expect(parse(value).canRestore, isTrue, reason: '$value');
    }
  });

  test('rejects nested objects before restore side effects begin', () {
    final preview = parse(<String, Object?>{'unexpected': true});
    expect(preview.canRestore, isFalse);
    expect(preview.issues, contains(BackupPreviewIssue.invalidData));
  });

  test('rejects mixed-type lists before SharedPreferences write', () {
    final preview = parse(<Object?>['tr', 42]);
    expect(preview.canRestore, isFalse);
    expect(preview.issues, contains(BackupPreviewIssue.invalidData));
  });
}
