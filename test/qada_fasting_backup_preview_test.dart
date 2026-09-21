import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  const parser = BackupPreviewParser();
  BackupPreview previewFor(String encoded) => parser.parse(<String, Object?>{'version': BackupManifest.schemaVersion, 'createdAt': '2026-09-21T08:02:00Z', 'data': <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: encoded}}});

  test('backup preview reports qada events instead of one opaque preference', () {
    final ledger = QadaFastingLedger().addDebt(days: 2, occurredOn: DateTime(2026, 3, 1), createdAt: DateTime.utc(2026, 9, 21, 8), sourceRamadanYear: 1447, id: 'debt').complete(occurredOn: DateTime(2026, 9, 21), createdAt: DateTime.utc(2026, 9, 21, 8, 1), id: 'done');
    final preview = previewFor(ledger.encode());
    expect(preview.canRestore, isTrue); expect(preview.recordCounts['fasting'], 2); expect(preview.totalRecords, 2);
  });

  test('malformed qada payload is visible as invalid before restore', () {
    final preview = previewFor('{broken');
    expect(preview.canRestore, isFalse); expect(preview.issues, contains(BackupPreviewIssue.invalidData)); expect(preview.recordCounts['fasting'], 0);
  });

  test('duplicate qada event ids are rejected in preview', () {
    const duplicate = '{"formatVersion":1,"entries":['
        '{"id":"same","kind":"debt","days":1,"occurredOn":"2026-03-01","createdAt":"2026-09-21T08:00:00Z"},'
        '{"id":"same","kind":"debt","days":1,"occurredOn":"2026-03-02","createdAt":"2026-09-21T08:01:00Z"}'
        ']}';
    final preview = previewFor(duplicate);
    expect(preview.canRestore, isFalse); expect(preview.issues, contains(BackupPreviewIssue.invalidData));
  });

  test('overdrawn qada history is rejected in preview before restore', () {
    const overdrawn = '{"formatVersion":1,"entries":['
        '{"id":"debt","kind":"debt","days":1,"occurredOn":"2026-03-01","createdAt":"2026-09-21T08:00:00Z","sourceRamadanYear":1447},'
        '{"id":"done","kind":"completion","days":2,"occurredOn":"2026-09-01","createdAt":"2026-09-21T08:01:00Z","sourceRamadanYear":1447}'
        ']}';
    final preview = previewFor(overdrawn);
    expect(preview.canRestore, isFalse); expect(preview.issues, contains(BackupPreviewIssue.invalidData)); expect(preview.recordCounts['fasting'], 0);
  });

  test('empty qada ledger reports zero worship-history events', () {
    final preview = previewFor(QadaFastingLedger().encode());
    expect(preview.recordCounts['fasting'], 0);
  });
}
