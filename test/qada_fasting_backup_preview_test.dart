import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';

void main() {
  const parser = BackupPreviewParser();

  test('backup preview reports qada events instead of one opaque preference', () {
    final ledger = QadaFastingLedger()
        .addDebt(
          days: 2,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: DateTime.utc(2026, 9, 21, 8),
          sourceRamadanYear: 1447,
          id: 'debt',
        )
        .complete(
          occurredOn: DateTime(2026, 9, 21),
          createdAt: DateTime.utc(2026, 9, 21, 8, 1),
          id: 'done',
        );

    final preview = parser.parse(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-21T08:02:00Z',
      'data': <String, Object?>{
        'fasting': <String, Object?>{
          QadaFastingStore.preferenceKey: ledger.encode(),
        },
      },
    });

    expect(preview.canRestore, isTrue);
    expect(preview.recordCounts['fasting'], 2);
    expect(preview.totalRecords, 2);
  });

  test('malformed qada payload remains visible without crashing preview', () {
    final preview = parser.parse(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-21T08:02:00Z',
      'data': <String, Object?>{
        'fasting': <String, Object?>{
          QadaFastingStore.preferenceKey: '{broken',
        },
      },
    });

    expect(preview.canRestore, isTrue);
    expect(preview.recordCounts['fasting'], 1);
  });

  test('empty qada ledger reports zero worship-history events', () {
    final preview = parser.parse(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-21T08:02:00Z',
      'data': <String, Object?>{
        'fasting': <String, Object?>{
          QadaFastingStore.preferenceKey: QadaFastingLedger().encode(),
        },
      },
    });

    expect(preview.recordCounts['fasting'], 0);
  });
}
