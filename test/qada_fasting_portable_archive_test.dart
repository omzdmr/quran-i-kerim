import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_portable_archive.dart';

void main() {
  const archive = QadaFastingPortableArchive();

  QadaFastingLedger sample() => QadaFastingLedger()
      .addDebt(
        days: 4,
        occurredOn: DateTime(2026, 3, 1),
        createdAt: DateTime.utc(2026, 9, 21, 10),
        sourceRamadanYear: 1447,
        note: 'private reason',
        id: 'debt-1447',
      )
      .complete(
        occurredOn: DateTime(2026, 9, 22),
        createdAt: DateTime.utc(2026, 9, 22, 10),
        sourceRamadanYear: 1447,
        note: 'private completion note',
        id: 'done-1447-1',
      );

  test('portable export excludes private notes by default', () {
    final source = archive.export(
      sample(),
      createdAt: DateTime.utc(2026, 9, 22),
    );
    final raw = jsonDecode(source) as Map<String, dynamic>;
    final privacy = raw['privacy'] as Map<String, dynamic>;
    final ledger = raw['ledger'] as Map<String, dynamic>;
    final entries = ledger['entries'] as List<dynamic>;

    expect(privacy['privateNotesIncluded'], isFalse);
    expect(entries.every((entry) => (entry as Map)['note'] == null), isTrue);
    final preview = archive.preview(source);
    expect(preview.incomingEntries, 2);
    expect(preview.remainingDays, 3);
    expect(preview.containsPrivateNotes, isFalse);
  });

  test('portable export includes private notes only after explicit opt-in', () {
    final source = archive.export(sample(), includePrivateNotes: true);
    final preview = archive.preview(source);

    expect(preview.containsPrivateNotes, isTrue);
    expect(preview.ledger.entries.first.note, 'private reason');
  });

  test('merge keeps local-only records and de-duplicates identical ids', () {
    final incoming = sample();
    final current = incoming.addDebt(
      days: 2,
      occurredOn: DateTime(2025, 3, 1),
      createdAt: DateTime.utc(2026, 9, 23),
      sourceRamadanYear: 1446,
      id: 'local-only',
    );
    final source = archive.export(incoming, includePrivateNotes: true);

    final preview = archive.preview(source, current: current);
    expect(preview.newEntries, 0);
    expect(preview.duplicateEntries, 2);

    final merged = archive.import(source, current: current);
    expect(merged.entries, hasLength(3));
    expect(merged.entries.map((entry) => entry.id), contains('local-only'));
    expect(merged.remainingDays, 5);
  });

  test('merge adds archive-only records without erasing local history', () {
    final current = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2025, 3, 1),
      createdAt: DateTime.utc(2026, 9, 20),
      sourceRamadanYear: 1446,
      id: 'local-only',
    );
    final source = archive.export(sample(), includePrivateNotes: true);

    final preview = archive.preview(source, current: current);
    expect(preview.newEntries, 2);
    expect(preview.duplicateEntries, 0);

    final merged = archive.import(source, current: current);
    expect(merged.entries, hasLength(3));
    expect(merged.remainingDays, 5);
  });

  test('same record id with different content is rejected instead of guessed', () {
    final current = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      id: 'shared-id',
    );
    final incoming = QadaFastingLedger().addDebt(
      days: 3,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      id: 'shared-id',
    );

    expect(
      () => archive.import(archive.export(incoming), current: current),
      throwsFormatException,
    );
  });

  test('replace intentionally replaces the local ledger', () {
    final current = QadaFastingLedger().addDebt(
      days: 9,
      occurredOn: DateTime(2025, 1, 1),
      createdAt: DateTime.utc(2025),
      id: 'old',
    );
    final source = archive.export(sample(), includePrivateNotes: true);

    final replaced = archive.import(
      source,
      current: current,
      mode: QadaArchiveImportMode.replace,
    );
    expect(replaced.entries, hasLength(2));
    expect(replaced.entries.any((entry) => entry.id == 'old'), isFalse);
    expect(replaced.remainingDays, 3);
  });

  test('malformed or incoherent archive is rejected, not silently salvaged', () {
    final malformed = jsonEncode(<String, Object?>{
      'format': QadaFastingPortableArchive.format,
      'formatVersion': QadaFastingPortableArchive.formatVersion,
      'ledger': <String, Object?>{
        'formatVersion': QadaFastingLedger.formatVersion,
        'entries': <Object?>[
          <String, Object?>{
            'id': 'completion-without-debt',
            'kind': 'completion',
            'days': 1,
            'occurredOn': '2026-09-22T00:00:00.000',
            'createdAt': '2026-09-22T00:00:00.000Z',
          },
        ],
      },
    });

    expect(() => archive.preview(malformed), throwsFormatException);
  });
}
