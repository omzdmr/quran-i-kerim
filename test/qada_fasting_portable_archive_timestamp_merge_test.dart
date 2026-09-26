import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_portable_archive.dart';

void main() {
  const archive = QadaFastingPortableArchive();

  test('same immutable qada event can merge across differing createdAt metadata', () {
    final local = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      note: 'local note wins',
      id: 'cross-device-event',
    );
    final remote = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 20),
      sourceRamadanYear: 1447,
      note: 'remote note',
      id: 'cross-device-event',
    );
    final source = archive.export(remote, includePrivateNotes: true);

    final preview = archive.preview(source, current: local);
    expect(preview.duplicateEntries, 1);
    expect(preview.conflictingEntries, 0);
    expect(preview.canMerge, isTrue);

    final merged = archive.import(source, current: local);
    expect(merged.entries, hasLength(1));
    expect(merged.entries.single.note, 'local note wins');
    expect(merged.entries.single.createdAt, DateTime.utc(2026, 9, 21));
  });
}
