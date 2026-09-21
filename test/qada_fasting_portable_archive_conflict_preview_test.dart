import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_portable_archive.dart';

void main() {
  const archive = QadaFastingPortableArchive();

  test('preview distinguishes identical duplicates from conflicting ids', () {
    final local = QadaFastingLedger()
        .addDebt(
          days: 2,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: DateTime.utc(2026, 9, 21),
          sourceRamadanYear: 1447,
          id: 'same',
        )
        .addDebt(
          days: 1,
          occurredOn: DateTime(2025, 3, 1),
          createdAt: DateTime.utc(2026, 9, 20),
          sourceRamadanYear: 1446,
          id: 'conflict',
        );
    final incoming = QadaFastingLedger()
        .addDebt(
          days: 2,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: DateTime.utc(2026, 9, 21),
          sourceRamadanYear: 1447,
          id: 'same',
        )
        .addDebt(
          days: 3,
          occurredOn: DateTime(2025, 3, 1),
          createdAt: DateTime.utc(2026, 9, 20),
          sourceRamadanYear: 1446,
          id: 'conflict',
        )
        .addDebt(
          days: 1,
          occurredOn: DateTime(2024, 3, 1),
          createdAt: DateTime.utc(2026, 9, 19),
          sourceRamadanYear: 1445,
          id: 'new',
        );

    final preview = archive.preview(
      archive.export(incoming),
      current: local,
    );

    expect(preview.incomingEntries, 3);
    expect(preview.duplicateEntries, 1);
    expect(preview.conflictingEntries, 1);
    expect(preview.newEntries, 1);
    expect(preview.canMerge, isFalse);
  });
}
