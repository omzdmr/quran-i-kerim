import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_portable_archive.dart';

void main() {
  const archive = QadaFastingPortableArchive();

  test('redacted backup remains mergeable with its noted local event', () {
    final local = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      note: 'private reason that must stay local',
      id: 'same-event',
    );
    final redacted = archive.export(local, includePrivateNotes: false);

    final preview = archive.preview(redacted, current: local);
    expect(preview.duplicateEntries, 1);
    expect(preview.conflictingEntries, 0);
    expect(preview.canMerge, isTrue);
    expect(preview.containsPrivateNotes, isFalse);

    final merged = archive.import(redacted, current: local);
    expect(merged.entries, hasLength(1));
    expect(merged.entries.single.note, 'private reason that must stay local');
  });

  test('merge may fill a missing local note from an opted-in archive', () {
    final local = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      id: 'same-event',
    );
    final noted = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      note: 'restored private note',
      id: 'same-event',
    );

    final merged = archive.import(
      archive.export(noted, includePrivateNotes: true),
      current: local,
    );
    expect(merged.entries.single.note, 'restored private note');
  });

  test('same id with changed worship event data is still a hard conflict', () {
    final local = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      note: 'local note',
      id: 'same-event',
    );
    final changed = QadaFastingLedger().addDebt(
      days: 3,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      note: 'other note',
      id: 'same-event',
    );

    final source = archive.export(changed, includePrivateNotes: false);
    final preview = archive.preview(source, current: local);
    expect(preview.conflictingEntries, 1);
    expect(preview.canMerge, isFalse);
    expect(
      () => archive.import(source, current: local),
      throwsFormatException,
    );
  });
}
